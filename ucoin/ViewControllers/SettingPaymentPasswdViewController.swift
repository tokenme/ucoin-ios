//
//  SettingPaymentPasswdViewController.swift
//  ucoin
//
//  Created by Syd on 2018/7/10.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import CBPinEntryView
import Moya
import Hydra

class SettingPaymentPasswdViewController: UIViewController {
    weak public var delegate: PaymentDelegate?
    
    weak public var collectCode: APIQRCollect?
    private var submitting: Bool = false
    private var loadingUserInfo: Bool = false
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var reinputLabel: UILabel!
    
    @IBOutlet private weak var pinEntryView: CBPinEntryView! {
        didSet {
            pinEntryView.delegate = self
        }
    }
    
    private var passwd: String?
    private var repasswd: String?
    
    private var userServiceProvider = MoyaProvider<UCUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    fileprivate let spinner = LoaderModal(backgroundColor: UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.6))!
    
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            
            let size = navigationController.navigationBar.frame.size
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            let context = UIGraphicsGetCurrentContext()
            UIColor.dimmedLightBackground.setFill()
            context?.addRect(CGRect(x: 0, y: 0, width: size.width, height: 1))
            context?.drawPath(using: .fill)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            navigationController.navigationBar.shadowImage = image
        }
        if self.collectCode == nil {
            self.navigationItem.title = "设置支付密码"
            self.titleLabel.text = "设置支付密码"
        } else {
            self.navigationItem.title = "支付密码"
            self.titleLabel.text = "支付密码"
        }
        self.reinputLabel.isHidden = true
        self.view.addSubview(spinner)
        
        self.pinEntryView.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            navigationController.navigationBar.isTranslucent = false
            
            let size = navigationController.navigationBar.frame.size
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            let context = UIGraphicsGetCurrentContext()
            UIColor.dimmedLightBackground.setFill()
            context?.addRect(CGRect(x: 0, y: 0, width: size.width, height: 1))
            context?.drawPath(using: .fill)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            navigationController.navigationBar.shadowImage = image
            
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    static func instantiate() -> SettingPaymentPasswdViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingPaymentPasswdViewController") as! SettingPaymentPasswdViewController
    }
}

extension SettingPaymentPasswdViewController: CBPinEntryViewDelegate {
    func entryChanged(_ completed: Bool) {
        if completed && !submitting {
            if passwd == nil {
                passwd = pinEntryView.getPinAsString()
                if self.collectCode != nil {
                    if let delegate = self.delegate {
                        delegate.passwordSet(passwd)
                        self.dismiss(animated: true, completion: nil)
                    }
                    return
                }
                pinEntryView.clear()
                self.reinputLabel.isHidden = false
                //pinEntryView.becomeFirstResponder()
            } else if self.collectCode == nil {
                repasswd = pinEntryView.getPinAsString()
                if passwd != repasswd {
                    passwd = nil
                    repasswd = nil
                    DispatchQueue.main.async {[weak self] in
                        guard let weakSelf = self else {
                            return
                        }
                        UCAlert.showAlert(imageName: "Error", title: "错误", desc: "重复密码不一致，请重新设置", closeBtn: "关闭")
                        weakSelf.pinEntryView.clear()
                        weakSelf.reinputLabel.isHidden = true
                    }
                    return
                }
                savePaymentPasswd(passwd!)
                pinEntryView.resignFirstResponder()
            }
        }
    }
}

extension SettingPaymentPasswdViewController {
    private func savePaymentPasswd(_ passwd: String) {
        if self.submitting {
            return
        }
        self.submitting = true
        self.spinner.start()
        guard let userInfo = APIUser.init() else {
            return
        }
        userInfo.paymentPasswd = passwd
        async({[weak self] _ in
            guard let weakSelf = self else {
                return
            }
            let _ = try! ..UCUserService.updateUserInfo(
                userInfo,
                provider: weakSelf.userServiceProvider)
            let _ = try! ..weakSelf.getUserInfo()
        }).then(in: .main, {[weak self] user in
            guard let weakSelf = self else {
                return
            }
            weakSelf.dismiss(animated: true, completion: {[weak weakSelf] in
                UCAlert.showAlert(imageName: "Success", title: "Great!", desc: "支付密码设置成功", closeBtn: "关闭")
                guard let weakSelfSub = weakSelf else {
                    return
                }
                if let delegate = weakSelfSub.delegate {
                    delegate.passwordSet(userInfo.paymentPasswd)
                }
            })
        }).catch(in: .main, { error in
            UCAlert.showAlert(imageName: "Error", title: "错误", desc: (error as! UCAPIError).description, closeBtn: "关闭")
        }).always(in: .main, body: {[weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.spinner.stop()
            weakSelf.submitting = false
            weakSelf.loadingUserInfo = false
        })
        
    }
    
    private func getUserInfo() -> Promise<APIUser>{
        return Promise<APIUser> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(UCAPIError.ignore)
                return
            }
            if weakSelf.loadingUserInfo {
                reject(UCAPIError.ignore)
                return
            }
            weakSelf.loadingUserInfo = true
            UCUserService.getUserInfo(
                true,
                provider: weakSelf.userServiceProvider)
            .then(in: .background, { user in
                resolve(user)
            }).catch(in: .background, { error in
                reject(error)
            })
        })
    }
}
