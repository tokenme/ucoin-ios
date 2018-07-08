//
//  LoginViewController.swift
//  ucoin
//
//  Created by Syd on 2018/5/30.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import PhoneNumberKit
import CountryPickerView
import Moya
import SwiftyUserDefaults

class LoginViewController: CustomTransitionViewController {
    
    //=================
    // MARK: - Variables
    //=================
    
    //===============
    // MARK: Outlets
    //===============
    @IBOutlet private weak var telephoneTextField: TweeAttributedTextField!
    @IBOutlet private weak var passwordTextfield: TweeAttributedTextField!
    @IBOutlet private weak var loginButton: TransitionButton!
    
    weak public var delegate: LoginViewDelegate?
    
    private var countryCode: String = "+86"
    private let phoneNumberKit = PhoneNumberKit()
    
    private var authServiceProvider = MoyaProvider<UCAuthService>(plugins: [networkActivityPlugin])
    
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        let cpv = CountryPickerView(frame: CGRect(x: 0, y: 0, width: 125, height: 20))
        cpv.setCountryByPhoneCode(self.countryCode)
        cpv.delegate = self
        cpv.dataSource = self
        telephoneTextField.leftView = cpv
        telephoneTextField.leftViewMode = .always
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    static func instantiate() -> LoginViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
    }
    
    //================
    // MARK: IBActions
    //================
    @IBAction private func login() {
        var valid: Bool = true
        valid = self.verifyTelephone()
        if !self.verifyPassword() {
            valid = false
        }
        if !valid {
            return
        }
        let country = UInt(self.countryCode.trimmingCharacters(in: CharacterSet(charactersIn: "+")))
        let mobile = self.telephoneTextField.text!
        let passwd = self.passwordTextfield.text!
        self.loginButton.startAnimation()
        self.authServiceProvider.request(
            .login(
                country:country!,
                mobile: mobile,
                password: passwd
            )
        ){ [weak self] result in
            guard let weakSelf = self else {
                return
            }
            switch result {
            case let .success(response):
                do {
                    let token = try response.mapObject(APIAccessToken.self)
                    if token.code ?? 0 > 0 {
                        DispatchQueue.main.async {
                            weakSelf.loginButton.stopAnimation(animationStyle: .shake, completion: {})
                            UCAlert.showAlert(imageName: "Error", title: "错误", desc: token.message ?? "Unknown Error", closeBtn: "关闭")
                        }
                        return
                    }
                    Defaults[.accessToken] = DefaultsAccessToken.init(token: token.token!, expire: token.expire!)
                    Defaults.synchronize()
                    DispatchQueue.main.async {
                        weakSelf.loginButton.stopAnimation(animationStyle: .expand, completion: {
                            weakSelf.delegate?.loginSucceeded(token: token)
                            weakSelf.navigationController?.popViewController(animated: true)
                        })
                    }
                } catch {
                    DispatchQueue.main.async {
                        weakSelf.loginButton.stopAnimation(animationStyle: .shake, completion: {})
                        UCAlert.showAlert(imageName: "Error", title: "错误", desc: "解析错误", closeBtn: "关闭")
                    }
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    weakSelf.loginButton.stopAnimation(animationStyle: .shake, completion: {})
                    UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.errorDescription!, closeBtn: "关闭")
                }
            }
        }
    }
}

extension LoginViewController {
    fileprivate func verifyTelephone() -> Bool {
        do {
            let phone = self.countryCode + (self.telephoneTextField.text ?? "")
            _ = try phoneNumberKit.parse(phone)
            return true
        }
        catch {
            self.telephoneTextField.showInfo("电话号码不正确")
        }
        return false
    }
    
    fileprivate func verifyPassword() -> Bool {
        if (self.passwordTextfield.text == "") {
            self.passwordTextfield.showInfo("密码不能为空")
            return false
        }
        return true
    }
}

extension LoginViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            self.telephoneTextField.hideInfo()
        } else if textField.tag == 1 {
            self.passwordTextfield.hideInfo()
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 0 && self.verifyTelephone() {
            self.passwordTextfield.becomeFirstResponder()
        } else if textField.tag == 1 && self.verifyPassword() {
            textField.resignFirstResponder()
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = self.verifyTelephone()
        _ = self.verifyPassword()
        textField.resignFirstResponder()
        return true
    }
}

extension LoginViewController: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        self.countryCode = country.phoneCode
    }
}

extension LoginViewController: CountryPickerViewDataSource {
    func preferredCountries(in countryPickerView: CountryPickerView) -> [Country] {
        var countries = [Country]()
        ["CN", "US", "JP"].forEach { code in
            if let country = countryPickerView.getCountryByCode(code) {
                countries.append(country)
            }
        }
        return countries
    }
    
    func sectionTitleForPreferredCountries(in countryPickerView: CountryPickerView) -> String? {
        return "建议选项"
    }
    
    func showOnlyPreferredSection(in countryPickerView: CountryPickerView) -> Bool {
        return false
    }
    
    func navigationTitle(in countryPickerView: CountryPickerView) -> String? {
        return "选择国家"
    }
    
    func searchBarPosition(in countryPickerView: CountryPickerView) -> SearchBarPosition {
        return .tableViewHeader
    }
    
    func showPhoneCodeInList(in countryPickerView: CountryPickerView) -> Bool {
        return true
    }
}

public protocol LoginViewDelegate: NSObjectProtocol {
    /// Called when the user selects a country from the list.
    func loginSucceeded(token: APIAccessToken)
}

