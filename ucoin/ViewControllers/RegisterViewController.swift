//
//  RegisterViewController.swift
//  ucoin
//
//  Created by Syd on 2018/5/31.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import PhoneNumberKit
import CountryPickerView
import Moya
import SwiftEntryKit

class RegisterViewController: UIViewController {
    
    //=================
    // MARK: - Variables
    //=================
    
    //===============
    // MARK: Outlets
    //===============
    @IBOutlet private weak var telephoneTextField: TweeAttributedTextField!
    @IBOutlet private weak var verifyCodeTextField: TweeAttributedTextField!
    @IBOutlet private weak var passwordTextfield: TweeAttributedTextField!
    @IBOutlet private weak var repasswordTextfield: TweeAttributedTextField!
    @IBOutlet private weak var countdownButton: RNCountdownButton!
    @IBOutlet private weak var registerButton: TransitionButton!
    
    private var authServiceProvider = MoyaProvider<UCAuthService>(plugins: [networkActivityPlugin])
    private var userServiceProvider = MoyaProvider<UCUserService>(plugins: [networkActivityPlugin])
    
    private var countryCode: String = "+86"
    private let phoneNumberKit = PhoneNumberKit()
    
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
        self.setupCountDownButton()
        self.setupTelephoneTextField()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupCountDownButton() {
        self.countdownButton.titleColorForEnable = UIColor.init(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        self.countdownButton.titleColorForDisable = UIColor.lightGray
        self.countdownButton.titleColorForCountingDisable = UIColor.lightGray
        self.countdownButton.borderColorForEnable = UIColor.white
        self.countdownButton.borderColorForDisable = UIColor.white
        self.countdownButton.isEnabled = false
        self.countdownButton.delegate = self
    }
    
    private func setupTelephoneTextField() {
        let cpv = CountryPickerView(frame: CGRect(x: 0, y: 0, width: 125, height: 20))
        cpv.setCountryByPhoneCode(self.countryCode)
        cpv.delegate = self
        cpv.dataSource = self
        self.telephoneTextField.leftView = cpv
        self.telephoneTextField.leftViewMode = .always
    }
    
    //================
    // MARK: IBActions
    //================
    @IBAction private func sendVerifyCode() {
        let country = UInt(self.countryCode.trimmingCharacters(in: CharacterSet(charactersIn: "+")))
        self.authServiceProvider.request(
            .sendCode(
                country:country!,
                mobile: self.telephoneTextField.text!
            )
        ){[weak self] result in
            guard let weakSelf = self else {
                return
            }
            switch result {
            case let .success(response):
                do {
                    let resp = try response.mapObject(APIResponse.self)
                    if resp.code ?? 0 > 0 {
                        DispatchQueue.main.async {
                            UCAlert.showAlert(imageName: "Error", title: "错误", desc: resp.message ?? "Unknown Error", closeBtn: "关闭")
                        }
                        return
                    }
                } catch {
                    DispatchQueue.main.async {
                        UCAlert.showAlert(imageName: "Error", title: "错误", desc: "解析错误", closeBtn: "关闭")
                    }
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.errorDescription!, closeBtn: "关闭")
                    weakSelf.countdownButton.stop()
                    weakSelf.countdownButton.showFetchAgain()
                    weakSelf.countdownButton.isEnabled = true
                }
            }
        }
        DispatchQueue.main.async {
            self.countdownButton.start()
        }
    }
    
    @IBAction private func register() {
        var valid: Bool = true
        valid = self.verifyTelephone()
        if !self.verifyVerifyCode() {
            valid = false
        }
        if !self.verifyPassword() {
            valid = false
        }
        if !verifyRepassword() {
            valid = false
        }
        if !valid {
            return
        }
        let country = UInt(self.countryCode.trimmingCharacters(in: CharacterSet(charactersIn: "+")))
        let mobile = self.telephoneTextField.text!
        let verifyCode = self.verifyCodeTextField.text!
        let passwd = self.passwordTextfield.text!
        let repasswd = self.repasswordTextfield.text!
        self.registerButton.startAnimation()
        self.userServiceProvider.request(
            .create(
                country: country!,
                mobile: mobile,
                verifyCode: verifyCode,
                password: passwd,
                repassword: repasswd
            )
        ){[weak self] result in
            guard let weakSelf = self else {
                return
            }
            switch result {
            case let .success(response):
                do {
                    let resp = try response.mapObject(APIResponse.self)
                    if resp.code ?? 0 > 0 {
                        DispatchQueue.main.async {
                            weakSelf.registerButton.stopAnimation(animationStyle: .shake, completion: {})
                            UCAlert.showAlert(imageName: "Error", title: "错误", desc: resp.message ?? "Unknown Error", closeBtn: "关闭")
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        weakSelf.registerButton.stopAnimation(animationStyle: .normal, completion: { [unowned weakSelf] in
                            weakSelf.navigationController?.popViewController(animated: true)
                        })
                    }
                } catch {
                    DispatchQueue.main.async {
                        UCAlert.showAlert(imageName: "Error", title: "错误", desc: "解析错误", closeBtn: "关闭")
                    }
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    weakSelf.registerButton.stopAnimation(animationStyle: .shake, completion: {})
                    UCAlert.showAlert(imageName: "Error", title: "错误", desc: error.errorDescription!, closeBtn: "关闭")
                }
            }
        }
    }
}

extension RegisterViewController {
    fileprivate func verifyTelephone() -> Bool {
        do {
            let phone = self.countryCode + (self.telephoneTextField.text ?? "")
            _ = try phoneNumberKit.parse(phone)
            if (!self.countdownButton.isCounting) {
                self.countdownButton.isEnabled = true
            }
            self.verifyCodeTextField.isEnabled = true
            return true
        }
        catch {
            self.telephoneTextField.showInfo("电话号码不正确")
            if (self.countdownButton.isCounting) {
                self.countdownButton.stop()
                self.countdownButton.showFetchAgain()
            }
            self.countdownButton.isEnabled = false
            self.verifyCodeTextField.isEnabled = false
        }
        return false
    }
    
    fileprivate func verifyVerifyCode() -> Bool {
        if (self.verifyCodeTextField.text == "") {
            self.verifyCodeTextField.showInfo("验证码不能为空")
            return false
        }
        return true
    }
    
    fileprivate func verifyPassword() -> Bool {
        if (self.passwordTextfield.text == "") {
            self.passwordTextfield.showInfo("密码不能为空")
            return false
        }
        return true
    }
    
    fileprivate func verifyRepassword() -> Bool {
        if self.repasswordTextfield.text == "" {
            self.repasswordTextfield.showInfo("重复密码不能为空")
            return false
        } else if (self.repasswordTextfield.text != self.passwordTextfield.text) {
            self.repasswordTextfield.showInfo("重复密码不相同")
            return false
        }
        return true
    }
}

extension RegisterViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 0 {
            self.telephoneTextField.hideInfo()
        } else if textField.tag == 1 {
            self.verifyCodeTextField.hideInfo()
        } else if textField.tag == 2 {
            self.passwordTextfield.hideInfo()
        } else if textField.tag == 3 {
            self.repasswordTextfield.hideInfo()
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 0 && self.verifyTelephone() {
            self.verifyCodeTextField.becomeFirstResponder()
        } else if textField.tag == 1 && self.verifyVerifyCode() {
            self.passwordTextfield.becomeFirstResponder()
        } else if textField.tag == 2 && self.verifyPassword() {
            self.repasswordTextfield.becomeFirstResponder()
        } else if textField.tag == 3 && self.verifyRepassword() {
            textField.resignFirstResponder()
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = self.verifyTelephone()
        _ = self.verifyVerifyCode()
        _ = self.verifyPassword()
        _ = self.verifyRepassword()
        textField.resignFirstResponder()
        return true
    }
}

extension RegisterViewController: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        self.countryCode = country.phoneCode
    }
}

extension RegisterViewController: CountryPickerViewDataSource {
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

extension RegisterViewController: RNCountdownButtonDelegate {
    func countdownButtonDidBeganCounting(countdownButton: RNCountdownButton) {
    }
    
    func countdownButtonDidEndCounting(countdownButton: RNCountdownButton) {
    }
    
    func countdownButton(countdownButton: RNCountdownButton, didUpdatedWith seconds: Int) {
    }
}
