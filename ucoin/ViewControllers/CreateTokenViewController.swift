//
//  CreateTokenViewController.swift
//  ucoin
//
//  Created by Syd on 2018/6/10.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import ImageRow
import SnapKit
import Eureka
import Toucan
import Moya
import Qiniu

fileprivate let DefaultLogoWidth = 180

class CreateTokenViewController: FormViewController {
    weak public var delegate: CreateTokenViewDelegate?
    
    fileprivate var submitting: Bool = false
    
    private var tokenServiceProvider = MoyaProvider<UCTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var qiniuServiceProvider = MoyaProvider<UCQiniuService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    fileprivate let spinner = LoaderModal(backgroundColor: UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.6))!
    
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationItem.largeTitleDisplayMode = .automatic;
        }
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.navigationItem.title = "造币"
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(createToken))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.view.addSubview(spinner)
        
        TextRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        IntRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            }
        }
        
        form +++
            
            Section(header: "填写代币信息", footer: "如: Ethereum, BtcCoin")
            <<< TextRow() {
                $0.tag = "name"
                $0.title = "名称"
                $0.placeholder = ""
                $0.add(rule: RuleRequired())
                $0.add(rule: RuleMinLength(minLength: 2))
                $0.add(rule: RuleMaxLength(maxLength: 16))
                $0.add(rule: RuleRegExp(regExpr: "^[_A-Za-z0-9-+\\.\\s]+$"))
                $0.validationOptions = .validatesOnChange
            }
            
            +++ Section(footer: "如: ETH, BTC")
            <<< TextRow() {
                $0.tag = "symbol"
                $0.title = "缩写"
                $0.placeholder = ""
                $0.add(rule: RuleRequired())
                $0.add(rule: RuleMinLength(minLength: 2))
                $0.add(rule: RuleMaxLength(maxLength: 8))
                $0.add(rule: RuleRegExp(regExpr: "^[A-Za-z0-9]+$"))
                $0.validationOptions = .validatesOnChange
            }.onChange{ row in
                row.value = (row.value ?? "").uppercased()
                row.updateCell()
            }
            
            +++ Section()
            <<< IntRow(){
                $0.tag = "totalSupply"
                $0.title = "发行量"
                $0.value = 1000000000
                let formatter = NumberFormatter()
                formatter.locale = .current
                formatter.numberStyle = .scientific
                $0.formatter = formatter
                $0.add(rule: RuleGreaterOrEqualThan(min: 10))
                $0.add(rule: RuleSmallerOrEqualThan(max: 1000000000))
                $0.validationOptions = .validatesOnChange
            }
            
            <<< IntRow() {
                $0.tag = "decimals"
                $0.title = "小数位"
                $0.value = 9
                $0.add(rule: RuleGreaterOrEqualThan(min: 2))
                $0.add(rule: RuleSmallerOrEqualThan(max: 9))
                $0.validationOptions = .validatesOnChange
            }
            
            +++ Section()
            <<< ImageRow(){
                $0.tag = "logo"
                $0.title = "图标"
                $0.sourceTypes = .PhotoLibrary
                $0.useEditedImage = true
                $0.allowEditor = true
            }.onChange{ row in
                if let image = row.value {
                    if image != row.placeholderImage {
                        let newImage = Toucan(image: image).resize(CGSize(width: DefaultLogoWidth, height: DefaultLogoWidth), fitMode: Toucan.Resize.FitMode.scale).image
                        row.placeholderImage = newImage
                        row.value = newImage
                    }
                } else {
                    row.placeholderImage = nil
                }
                row.updateCell()
            }.cellUpdate { cell, row in
                cell.accessoryView?.layer.cornerRadius = 17
                cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
            }
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    static func instantiate() -> CreateTokenViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateTokenViewController") as! CreateTokenViewController
    }
    
    @objc public func createToken() {
        if self.submitting {
            return
        }
        if self.form.validate().count > 0 {
            return
        }
        let values = self.form.values()
        guard let token = APIToken(form: values) else {
            return
        }
        
        self.submitting = true
        self.spinner.start()
        if let logo = token.logoImage {
            UCQiniuService.getTokenLogo(
                token.address,
                provider: self.qiniuServiceProvider,
                success: {[weak self] upToken in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.uploadImage(upToken, image: logo, success: { [weak weakSelf] (upToken) -> Void in
                        guard let weakSelfSub = weakSelf else {
                            return
                        }
                        token.logo = upToken.link
                        weakSelfSub.doCreateToken(token)
                    })
                },
                failed: {error in
                    DispatchQueue.main.async {
                        UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.description, closeBtn: "关闭")
                    }
                },complete: {[weak self] in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.submitting = false
                    weakSelf.spinner.stop()
            })
        } else {
            self.doCreateToken(token)
        }
    }
    
    private func doCreateToken(_ token: APIToken) {
        self.submitting = true
        
        UCTokenService.createToken(
            token,
            provider: self.tokenServiceProvider,
            success: {[weak self] token in
                guard let weakSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    weakSelf.delegate?.tokenCreated(token: token)
                    weakSelf.navigationController?.popViewController(animated: true)
                }
            },
            failed: {error in
                DispatchQueue.main.async {
                    UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.description, closeBtn: "关闭")
                }
            },
            complete: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.submitting = false
                weakSelf.spinner.stop()
        })
    }
    
    private func uploadImage(_ upToken: APIQiniu, image: UIImage, success:@escaping (_ upToken: APIQiniu)->Void) {
        let magager = QiniuManager.sharedInstance
        magager.uploader.put(
            image.data(),
            key: upToken.key,
            token: upToken.upToken,
            complete: { (info: QNResponseInfo?, key: String?, resp: [AnyHashable : Any]?) -> Void in
                if info!.isOK {
                    upToken.uploaded = true
                    success(upToken)
                }
            }, option: nil)
    }
}

public protocol CreateTokenViewDelegate: NSObjectProtocol {
    func tokenCreated(token: APIToken)
}
