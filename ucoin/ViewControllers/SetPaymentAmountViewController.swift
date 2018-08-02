//
//  SetPaymentAmountViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/12.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import Moya

class SetPaymentAmountViewController: UIViewController {
    weak public var delegate: PaymentDelegate?
    
    weak public var tokenInfo: APIToken?
    public var amount: UInt64?
    public var collectCode: APIQRCollect?
    
    private var isTransfering: Bool = false
    
    @IBOutlet private weak var logoView: UIImageView!
    @IBOutlet private weak var tokenLabel: UILabel!
    @IBOutlet private weak var symbolLabel: UILabel!
    @IBOutlet private weak var amountTextField: UITextField!
    
    private var tokenServiceProvider = MoyaProvider<UCTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
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
        guard let token = self.tokenInfo else {
            return
        }
        var amountDouble: Double = 0
        if token.decimals ?? 0 > 0  {
            amountDouble = Double(amount ?? 0) / pow(10, Double(token.decimals!))
        }
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 4
        numberFormatter.alwaysShowsDecimalSeparator = true
        amountTextField.text = numberFormatter.string(from: NSNumber(value: amountDouble))
        
        if collectCode != nil {
            amountTextField.isUserInteractionEnabled = false
        } else {
            amountTextField.becomeFirstResponder()
        }
        tokenLabel.text = token.name
        symbolLabel.text = token.symbol
        if let logo = token.logo {
            logoView.kf.setImage(with: URL(string: logo))
            logoView.layer.cornerRadius = logoView.bounds.width / 2
            logoView.clipsToBounds = true
        }
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
    
    static func instantiate() -> SetPaymentAmountViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SetPaymentAmountViewController") as! SetPaymentAmountViewController
    }
    
    @IBAction private func confirm() {
        if isTransfering {
            return
        }
        if let collectCode = self.collectCode {
            let vc = SettingPaymentPasswdViewController.instantiate()
            vc.collectCode = collectCode
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
            return
        }
    }
}

extension SetPaymentAmountViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
}

extension SetPaymentAmountViewController: PaymentDelegate {
    func paymentSuccess() {}
    
    func passwordSet(_ passwd: String?) {
        guard let token = tokenInfo else {
            return
        }
        guard let qrcode = self.collectCode else {
            return
        }
        guard let password = passwd else {
            return
        }
        guard let tokenAddress = token.address else {
            return
        }
        guard let wallet = qrcode.wallet else {
            return
        }
        guard let amount = qrcode.amount else {
            return
        }
        self.transfer(tokenAddress, wallet: wallet, amount: amount, passwd: password)
    }
    
}

extension SetPaymentAmountViewController {
    private func transfer(_ tokenAddress: String, wallet: String, amount:UInt64, passwd: String) {
        if isTransfering {
            return
        }
        isTransfering = true
        UCTokenService.transferToken(
            tokenAddress,
            wallet: wallet,
            amount: amount,
            passwd: passwd,
            provider: self.tokenServiceProvider)
            .then(in: .main, {[weak self] qrcode in
                guard let weakSelf = self else {
                    return
                }
                if let delegate = weakSelf.delegate {
                    delegate.paymentSuccess()
                }
            }).catch(in: .main,  { error in
                UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
            }).always(in: .main, body: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.isTransfering = false
            })
    }
}
