//
//  QRCodeCollectViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/11.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation

import UIKit
import Moya
import swiftScan
import SnapKit

fileprivate let DefaultQrcodeWidth = 600.0

class QRCodeCollectViewController: UIViewController {
    weak public var tokenInfo: APIToken?
    
    @IBOutlet private weak var qrcodeView: UIImageView!
    @IBOutlet private weak var tokenLabel: UILabel!
    @IBOutlet private weak var amountButton: UIButton!
    @IBOutlet private weak var resetButton: UIButton!
    @IBOutlet private weak var amountLabel: UILabel!
    
    private var amount: UInt64? {
        didSet {
            guard let decimals = self.tokenInfo?.decimals else {
                return
            }
            if amount ?? 0 > 0 {
                self.getCollectCode(self.tokenInfo?.address, amount: amount)
                self.amountButton.snp.removeConstraints()
                self.amountButton.isHidden = true
                self.amountLabel.snp.remakeConstraints {[unowned self] (maker) -> Void in
                    maker.leading.equalToSuperview()
                    maker.trailing.equalToSuperview()
                    maker.top.equalTo(self.qrcodeView.snp.bottom).offset(10)
                }
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                numberFormatter.minimumFractionDigits = 1
                numberFormatter.maximumFractionDigits = 4
                numberFormatter.alwaysShowsDecimalSeparator = true
                let amountDouble = Double(amount ?? 0) / pow(10, Double(decimals))
                let amountTxt = amountDouble.formate(formatter: numberFormatter)
                self.amountLabel.text = "\(amountTxt) \(self.tokenInfo?.symbol ?? "")"
                self.amountLabel.isHidden = false
                self.resetButton.snp.remakeConstraints {[unowned self] (maker) -> Void in
                    maker.centerX.equalToSuperview()
                    maker.top.equalTo(self.amountLabel.snp.bottom).offset(10)
                    maker.bottom.equalToSuperview().offset(-10)
                }
                self.resetButton.isHidden = false
            } else {
                self.getCollectCode(self.tokenInfo?.address, amount: 0)
                self.amountLabel.isHidden = true
                self.amountLabel.snp.removeConstraints()
                self.resetButton.isHidden = true
                self.resetButton.snp.removeConstraints()
                self.amountButton.isHidden = false
                self.amountButton.snp.remakeConstraints {[unowned self] (maker) -> Void in
                    maker.centerX.equalToSuperview()
                    maker.top.equalTo(self.qrcodeView.snp.bottom).offset(10)
                    maker.bottom.equalToSuperview().offset(-10)
                }
            }
        }
    }
    private let spinner = LoaderModal(backgroundColor: UIColor.clear)!
    
    private var isGettingCode: Bool = false
    
    private var qrcodeServiceProvider = MoyaProvider<UCQrcodeService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self
        
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
        }
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        self.view.addSubview(spinner)
        
        if let name = self.tokenInfo?.name {
            self.tokenLabel.text = "请用UCoin扫码转给我\(name)"
            self.amountButton.isHidden = false
        } else {
            self.tokenLabel.text = "请用UCoin扫码转给我"
            self.amountButton.isHidden = true
        }
        self.getCollectCode(self.tokenInfo?.address, amount: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            
            navigationController.navigationBar.isTranslucent = true
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> QRCodeCollectViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QRCodeCollectViewController") as! QRCodeCollectViewController
    }
}

extension QRCodeCollectViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension QRCodeCollectViewController {
    @IBAction private func showInputAmountView() {
        let vc = SetCollectAmountViewController.instantiate()
        vc.tokenInfo = self.tokenInfo
        vc.amount = self.amount
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction private func reset() {
        self.amount = 0
    }
}

extension QRCodeCollectViewController {
    private func getCollectCode(_ token: String? , amount: UInt64?) {
        if isGettingCode {
            return
        }
        isGettingCode = true
        self.spinner.start()
        UCQrcodeService.getCollectCode(
            token,
            amount: amount,
            provider: self.qrcodeServiceProvider)
        .then(in: .main, {[weak self] qrcode in
            guard let weakSelf = self else {
                return
            }
            let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator",codeString:qrcode, size:
                CGSize(width: DefaultQrcodeWidth, height: DefaultQrcodeWidth), qrColor: UIColor.black, bkColor: UIColor.white)
            
            weakSelf.qrcodeView.image = qrImg
        }).catch(in: .main, { error in
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
        }).always(in: .main, body: { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.isGettingCode = false
            weakSelf.spinner.stop()
        })
    }
}

extension QRCodeCollectViewController: SetCollectAmountViewControllerDelegate {
    func setAmount(_ amount: UInt64) {
        self.amount = amount
    }
}
