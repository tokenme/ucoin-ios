//
//  UserHeaderViewController.swift
//  ucoin
//
//  Created by Syd on 2018/6/7.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import moa
import Toucan
import SnapKit
import NVActivityIndicatorView
import Reusable
import ShadowView

fileprivate let DefaultAvatarWidth = 60.0
fileprivate let DefaultLoginButtonWidth = 50
fileprivate let DefaultLoginButtonHeight = 20
fileprivate let DefaultSettingButtonWidth = 32

fileprivate let DefaultAvatarImage = Toucan(image: UIImage(color: UIColor.darkGray)!).resize(CGSize(width: DefaultAvatarWidth, height: DefaultAvatarWidth), fitMode: Toucan.Resize.FitMode.scale).maskWithEllipse(borderWidth: 1.5, borderColor: .white).image


class UserHeaderViewController: UIViewController, Reusable {
    
    private var userInfo: APIUser?
    
    private let avatarLoadingView = NVActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: DefaultAvatarWidth, height: DefaultAvatarWidth), type: NVActivityIndicatorType.ballScaleMultiple, color: UIColor.primaryBlue)
    private let avatarView = UIImageView(frame: CGRect(x: 0, y: 0, width: DefaultAvatarWidth, height: DefaultAvatarWidth))
    private let nickLabel = UILabel()
    private let loginButton = UIButton.init(type: .roundedRect)
    private let settingButton = UIButton.init(type: .custom)
    
    private let loadingViewContainer = UIView()
    
    private let avatarDownloader = Moa()
    weak public var delegate: UserHeaderViewDelegate?
    
    public func setUser(_ user: APIUser?) {
        if let userInfo = user {
            self.userInfo = userInfo
            if let avatarURL = self.userInfo?.avatar {
                avatarDownloader.onSuccess = {[weak self] image in
                    guard let weakSelf = self else {
                        return image
                    }
                    let outputImage = Toucan(image: image).resize(CGSize(width: DefaultAvatarWidth, height: DefaultAvatarWidth), fitMode: Toucan.Resize.FitMode.scale).maskWithEllipse(borderWidth: 1.5, borderColor: UIColor.white).image
                    
                    weakSelf.avatarView.image = outputImage
                    
                    return outputImage
                }
                avatarDownloader.url = avatarURL
            } else {
                self.avatarView.image = DefaultAvatarImage
            }
            self.settingButton.isHidden = false
            self.loginButton.isHidden = true
            self.nickLabel.isHidden = false
            self.nickLabel.text = userInfo.showName
        } else {
            self.userInfo = nil
            self.avatarView.image = DefaultAvatarImage
            self.loginButton.isHidden = false
            self.nickLabel.text = nil
            self.nickLabel.isHidden = true
            self.settingButton.isHidden = true
        }
    }
    
    //=============
    // MARK: - denit
    //=============
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAvatarView()
        self.setupLoginButton()
        self.setupNickLabel()
        self.setupSettingButton()
        self.setupAvatarLoadingView()
    }
}

extension UserHeaderViewController {
    
    public func loadingUserInfo() {
        DispatchQueue.main.async {
            self.loadingViewContainer.isHidden = false
            self.avatarLoadingView.startAnimating()
        }
    }
    
    public func stopLoadingUserInfo() {
        DispatchQueue.main.async {
            self.loadingViewContainer.isHidden = true
            self.avatarLoadingView.stopAnimating()
        }
    }
    
    fileprivate func setupAvatarLoadingView() {
        self.loadingViewContainer.backgroundColor = UIColor.white
        self.loadingViewContainer.addSubview(self.avatarLoadingView)
        
        self.avatarLoadingView.snp.remakeConstraints { (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.width.equalTo(DefaultAvatarWidth)
            maker.height.equalTo(DefaultAvatarWidth)
        }
        
        self.loadingViewContainer.isHidden = true
        
        self.view.addSubview(self.loadingViewContainer)
        
        self.loadingViewContainer.snp.remakeConstraints { (maker) -> Void in
            maker.edges.equalToSuperview()
        }
    }
    
    fileprivate func setupAvatarView() {
        self.avatarView.image = DefaultAvatarImage
        //self.avatarView.layer.borderColor = UIColor.darkGray.cgColor
        self.avatarView.layer.borderWidth = 0
        self.avatarView.layer.cornerRadius = CGFloat(DefaultAvatarWidth / 2.0)
        
        self.avatarView.shadowRadius = 2
        self.avatarView.shadowOffset = CGSize.zero
        self.avatarView.shadowColor = UIColor.black
        self.avatarView.shadowOpacity = 0.3
        
        self.view.addSubview(self.avatarView)
        
        self.avatarView.snp.remakeConstraints { (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.width.equalTo(DefaultAvatarWidth)
            maker.height.equalTo(DefaultAvatarWidth)
            maker.top.equalToSuperview().offset(40)
        }
    }
    
    fileprivate func setupLoginButton() {
        self.loginButton.titleLabel?.font = MainFont.light.with(size: 10)
        self.loginButton.layer.borderWidth = 1
        self.loginButton.layer.borderColor = UIColor.primaryBlue.cgColor
        self.loginButton.layer.cornerRadius = 5
        self.loginButton.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        self.loginButton.setTitle("登录", for: .normal)
        self.view.addSubview(self.loginButton)
        
        self.loginButton.snp.remakeConstraints {[unowned self] (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.width.equalTo(DefaultLoginButtonWidth)
            maker.height.equalTo(DefaultLoginButtonHeight)
            maker.top.equalTo(self.avatarView.snp.bottom).offset(10)
            maker.bottom.equalToSuperview().offset(-10)
        }
    }
    
    fileprivate func setupNickLabel() {
        self.nickLabel.font = MainFont.bold.with(size: 15)
        self.nickLabel.textAlignment = NSTextAlignment.center
        self.nickLabel.textColor = UIColor.darkText
        self.view.addSubview(self.nickLabel)
        self.nickLabel.snp.remakeConstraints {[unowned self] (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalTo(self.avatarView.snp.bottom).offset(10)
            maker.bottom.equalToSuperview().offset(-10)
        }
    }
    
    fileprivate func setupSettingButton() {
        let img = UIImage(named: "Setting")?.withRenderingMode(.alwaysTemplate)
        let settingButton = UIButton(frame: CGRect(x: 0, y: 0, width: DefaultSettingButtonWidth, height: DefaultSettingButtonWidth))
        settingButton.clipsToBounds = true
        settingButton.contentMode = .scaleAspectFit
        settingButton.setImage(img, for: .normal)
        settingButton.tintColor = UIColor.primaryBlue
        settingButton.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        self.view.addSubview(settingButton)
        
        settingButton.snp.remakeConstraints { (maker) -> Void in
            maker.width.equalTo(DefaultSettingButtonWidth)
            maker.height.equalTo(DefaultSettingButtonWidth)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(16)
        }
    }
    
    @objc func onClick() {
        if self.userInfo == nil {
            self.delegate?.showLogin()
        } else {
            Defaults.removeAll()
            self.delegate?.logoutSucceeded()
        }
    }
}

public protocol UserHeaderViewDelegate: NSObjectProtocol {
    /// Called when the user selects a country from the list.
    func logoutSucceeded()
    func showLogin()
}
