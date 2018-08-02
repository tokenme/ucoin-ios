//
//  ScanViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/11.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import swiftScan
import Moya
import SwiftyUserDefaults

class ScanViewController: LBXScanViewController {
    weak public var delegate: ScanViewDelegate?
    
    private var userInfo: APIUser? {
        get {
            if let userInfo: DefaultsUser = Defaults[.user] {
                if CheckValidAccessToken() {
                    return APIUser.init(user: userInfo)
                }
                return nil
            }
            return nil
        }
    }
    
    private var isParsingCode: Bool = false
    private var qrcodeServiceProvider = MoyaProvider<UCQrcodeService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    /**
     @brief  扫码区域上方提示文字
     */
    var topTitle:UILabel?
    
    /**
     @brief  闪关灯开启状态
     */
    var isOpenedFlash:Bool = false
    
    // MARK: - 底部几个功能：开启闪光灯、相册、我的二维码
    
    //底部显示的功能项
    var bottomItemsView:UIView?
    
    //相册
    var btnPhoto:UIButton = UIButton()
    
    //闪光灯
    var btnFlash:UIButton = UIButton()
    
    var btnClose:UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //需要识别后的图像
        setNeedCodeImage(needCodeImg: true)
        
        //框向上移动10个像素
        scanStyle?.centerUpOffset += 10
        scanStyle?.anmiationStyle = LBXScanViewAnimationStyle.NetGrid
        scanStyle?.animationImage = UIImage(named: "CodeScan.bundle/qrcode_scan_part_net")
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        drawBottomItems()
    }
    
    
    
    override func handleCodeResult(arrayResult: [LBXScanResult]) {
        
        for result:LBXScanResult in arrayResult
        {
            if let str = result.strScanned {
                print(str)
            }
        }
        
        let result:LBXScanResult = arrayResult[0]
        self.parseCode(result.strScanned ?? "")
    }
    
    func drawBottomItems()
    {
        if (bottomItemsView != nil) {
            
            return;
        }
        
        let yMax = self.view.frame.maxY - self.view.frame.minY
        
        bottomItemsView = UIView(frame:CGRect(x: 0.0, y: yMax-100,width: self.view.frame.size.width, height: 100 ) )
        
        
        bottomItemsView!.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6)
        
        self.view.addSubview(bottomItemsView!)
        
        
        let size = CGSize(width: 65, height: 87);
        
        self.btnClose = UIButton()
        btnClose.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        btnClose.center = CGPoint(x: bottomItemsView!.frame.width / 2, y: bottomItemsView!.frame.height/2)
        let closeImg = UIImage(named: "Cancel")?.withRenderingMode(.alwaysTemplate)
        btnClose.contentMode = .scaleAspectFill
        btnClose.clipsToBounds = true
        btnClose.setImage(closeImg, for: UIControlState.normal)
        btnClose.tintColor = UIColor.white
        btnClose.addTarget(self, action: #selector(ScanViewController.close), for: UIControlEvents.touchUpInside)
        
        self.btnFlash = UIButton()
        btnFlash.bounds = btnClose.bounds
        btnFlash.center = CGPoint(x: bottomItemsView!.frame.width / 4, y: bottomItemsView!.frame.height/2)
        btnFlash.setImage(UIImage(named: "CodeScan.bundle/qrcode_scan_btn_flash_nor"), for:UIControlState.normal)
        btnFlash.addTarget(self, action: #selector(ScanViewController.openOrCloseFlash), for: UIControlEvents.touchUpInside)
        
        
        self.btnPhoto = UIButton()
        btnPhoto.bounds = btnClose.bounds
        btnPhoto.center = CGPoint(x: bottomItemsView!.frame.width * 3/4, y: bottomItemsView!.frame.height/2)
        btnPhoto.setImage(UIImage(named: "CodeScan.bundle/qrcode_scan_btn_photo_nor"), for: UIControlState.normal)
        btnPhoto.setImage(UIImage(named: "CodeScan.bundle/qrcode_scan_btn_photo_down"), for: UIControlState.highlighted)
        btnPhoto.addTarget(self, action: #selector(ScanViewController.showPhotoAlbum), for: UIControlEvents.touchUpInside)
        
        bottomItemsView?.addSubview(btnFlash)
        bottomItemsView?.addSubview(btnPhoto)
        bottomItemsView?.addSubview(btnClose)
        
        self.view .addSubview(bottomItemsView!)
        
    }
    
    
    //开关闪光灯
    @objc func openOrCloseFlash()
    {
        scanObj?.changeTorch();
        
        isOpenedFlash = !isOpenedFlash
        
        if isOpenedFlash
        {
            btnFlash.setImage(UIImage(named: "CodeScan.bundle/qrcode_scan_btn_flash_down"), for:UIControlState.normal)
        }
        else
        {
            btnFlash.setImage(UIImage(named: "CodeScan.bundle/qrcode_scan_btn_flash_nor"), for:UIControlState.normal)
        }
    }
    
    @objc func showPhotoAlbum() {
        self.openPhotoAlbum()
    }
    
    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ScanViewController {
    private func parseCode(_ uri: String) {
        if isParsingCode {
            return
        }
        isParsingCode = true
        UCQrcodeService.parseCode(
            uri,
            provider: self.qrcodeServiceProvider)
        .then(in: .main, {[weak self] qrcode in
            guard let weakSelf = self else {
                return
            }
            if qrcode is APIQRCollect {
                if let delegate = weakSelf.delegate {
                    weakSelf.dismiss(animated: true, completion: {
                        delegate.collectHandler(qrcode as! APIQRCollect)
                    })
                }
            } else if qrcode is APIQROrder {
                UCAlert.showAlert(imageName: "Success", title: "Result", desc: (qrcode as! APIQROrder).toJSONString() ?? "null", closeBtn: "关闭")
            }
            
            //weakSelf.startScan()
        }).catch(in: .main,  {[weak self] error in
            guard let weakSelf = self else {
                return
            }
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
            weakSelf.startScan()
        }).always(in: .main, body: { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.isParsingCode = false
        })
    }
}
