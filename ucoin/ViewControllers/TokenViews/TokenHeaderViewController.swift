//
//  TokenHeaderViewController.swift
//  ucoin
//
//  Created by Syd on 2018/6/15.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import moa
import Toucan
import SnapKit
import Reusable
import ShadowView

fileprivate let DefaultLogoWidth = 60.0
fileprivate let DefaultButtonWidth = 30.0
fileprivate let DefaultBgMaxHeight = 300.0
fileprivate let DefaultBgHeight = 100.0
fileprivate let DefaultLogoImage = UIImage(color: .darkGray)

class TokenHeaderViewController: UIViewController, Reusable {
    
    private var user: APIUser? {
        get {
            if let userInfo: DefaultsUser = Defaults[.user] {
                return APIUser.init(user: userInfo)
            }
            return nil
        }
    }
    weak private var token: APIToken?
    weak public var delegate: TokenViewDelegate?
    
    private var bgImageView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: Double(UIScreen.main.bounds.width), height: DefaultBgMaxHeight))
    private var logoView = UIImageView(frame: CGRect(x: 0, y: 0, width: DefaultLogoWidth, height: DefaultLogoWidth))
    private var nameLabel = UILabel(frame: CGRect.zero)
    private var symbolLabel = UILabel(frame: CGRect.zero)
    
    private let logoDownloader = Moa()
    
    public func setToken(_ token: APIToken?) {
        self.token = token
        if self.token != nil {
            if let logoImage = self.token?.logoImage {
                self.logoView.image = Toucan(image: logoImage).resize(CGSize(width: DefaultLogoWidth, height: DefaultLogoWidth), fitMode: Toucan.Resize.FitMode.scale).image
                logoImage.getColors { [weak self] colors in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.updateBgView(colors)
                }
            } else if let logoURL = self.token?.logo {
                logoDownloader.onSuccess = {[weak self] image in
                    guard let weakSelf = self else {
                        return image
                    }
                    let outputImage = Toucan(image: image).resize(CGSize(width: DefaultLogoWidth, height: DefaultLogoWidth), fitMode: Toucan.Resize.FitMode.scale).image
                    
                    weakSelf.logoView.image = outputImage
                    image.getColors {[weak weakSelf] colors in
                        guard let weakSelfSub = weakSelf else {
                            return
                        }
                        weakSelfSub.updateBgView(colors)
                    }
                    
                    return outputImage
                }
                logoDownloader.url = logoURL
            } else {
                self.logoView.image = DefaultLogoImage
                self.bgImageView.backgroundColor = UIColor.darkGray
            }
            self.nameLabel.text = self.token?.name
            self.symbolLabel.text = self.token?.symbol
        } else {
            self.logoView.image = DefaultLogoImage
            self.nameLabel.text = nil
            self.symbolLabel.text = nil
            self.bgImageView.backgroundColor = UIColor.darkGray
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
        self.setupBgImageView()
        self.setupLogoView()
        self.setupNameLabel()
        self.setupSymbolLabel()
    }
    
}

extension TokenHeaderViewController {
    
    fileprivate func setupBgImageView() {
        self.view.addSubview(self.bgImageView)
        self.bgImageView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(DefaultBgHeight - DefaultBgMaxHeight)
            maker.height.equalTo(DefaultBgMaxHeight)
        }
    }
    
    fileprivate func setupLogoView() {
        self.logoView.layer.borderColor = UIColor.white.cgColor
        self.logoView.layer.borderWidth = 1.5
        self.logoView.layer.cornerRadius = CGFloat(DefaultLogoWidth / 2.0)
        
        self.logoView.shadowRadius = 5
        self.logoView.shadowOffset = CGSize.zero
        self.logoView.shadowColor = UIColor.black
        self.logoView.shadowOpacity = 0.3
        
        self.logoView.clipsToBounds = true
        self.logoView.contentMode = .scaleAspectFill
        
        if self.logoView.image == nil {
            self.logoView.image = DefaultLogoImage
        }
        self.view.addSubview(self.logoView)
        
        self.logoView.snp.remakeConstraints { [unowned self] (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.width.equalTo(DefaultLogoWidth)
            maker.height.equalTo(DefaultLogoWidth)
            maker.top.equalTo(self.bgImageView.snp.bottom).offset(-1 * DefaultLogoWidth / 2.0)
        }
    }
    
    fileprivate func setupNameLabel() {
        self.nameLabel.font = MainFont.bold.with(size: 17)
        self.nameLabel.textAlignment = NSTextAlignment.center
        self.nameLabel.textColor = UIColor.darkText
        self.view.addSubview(self.nameLabel)
        self.nameLabel.snp.remakeConstraints {[unowned self] (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.height.equalTo(20)
            maker.top.equalTo(self.logoView.snp.bottom).offset(16)
        }
    }
    
    fileprivate func setupSymbolLabel() {
        self.symbolLabel.font = MainFont.light.with(size: 14)
        self.symbolLabel.textAlignment = NSTextAlignment.center
        self.symbolLabel.textColor = UIColor.darkSubText
        self.view.addSubview(self.symbolLabel)
        self.symbolLabel.snp.remakeConstraints { [unowned self] (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(-8)
        }
    }
    
    private func updateBgView(_ colors: UIImageColors) {
        self.bgImageView.backgroundColor = colors.primary
        self.bgImageView.clipsToBounds = true
        for subview in self.bgImageView.subviews {
            subview.removeFromSuperview()
        }
        let verticesConfig = VerticesGenerator.Configuration(size: self.bgImageView.bounds.size)
        let vertices = VerticesGenerator.generate(configuration: verticesConfig)
        let triangles = Delaunay.triangulate(vertices)
        let style = TSStyle(colorsX: [colors.primary, colors.secondary, colors.detail, colors.background], colorsY: [colors.background, colors.detail, colors.secondary, colors.primary], fillColorClosure: nil, strokeColorClosure: nil, strokeLineWidth: 0)
        for triangle in triangles {
            let triangleView = TriangleView(triangle:triangle, style: style)
            self.bgImageView.addSubview(triangleView)
        }
        if let delegate = self.delegate {
            delegate.updatedImageColors(colors)
        }
    }
}
