//
//  TokenProductContentHeaderView.swift
//  ucoin
//
//  Created by Syd on 2018/7/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable

fileprivate let DefaultLogoHeight = 40.0
fileprivate let DefaultPriceWidth = 80

final class TokenProductContentHeaderView: UIView, Reusable {
    weak public var delegate: TokenProductViewDelegate?
    
    static let height: CGFloat = 55
    
    private let tokenLogo = UIButton(frame: CGRect(x: 0, y: 0, width: DefaultLogoHeight, height: DefaultLogoHeight))
    private let priceTitleLabel = UILabel()
    private let priceLabel = UILabel()
    private let buyButton = TransitionButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tokenLogo.layer.borderWidth = 0
        tokenLogo.layer.cornerRadius = CGFloat(DefaultLogoHeight / 2)
        tokenLogo.contentMode = .scaleAspectFill
        tokenLogo.clipsToBounds = true
        tokenLogo.addTarget(self, action: #selector(gotoToken), for: .touchUpInside)
        self.addSubview(tokenLogo)
        tokenLogo.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(DefaultLogoHeight)
            maker.width.equalTo(DefaultLogoHeight)
        }
        
        let priceView = UIView()
        priceLabel.font = MainFont.bold.with(size: 15)
        priceLabel.textColor = UIColor.primaryBlue
        priceLabel.textAlignment = .center
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.numberOfLines = 1
        priceLabel.minimumScaleFactor = 8.0 / priceLabel.font.pointSize
        priceView.addSubview(priceLabel)
        priceLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        
        priceTitleLabel.font = MainFont.light.with(size: 12)
        priceTitleLabel.text = "需消耗代币"
        priceTitleLabel.textColor = UIColor.primaryBlue
        priceTitleLabel.textAlignment = .center
        priceTitleLabel.adjustsFontSizeToFitWidth = true
        priceTitleLabel.numberOfLines = 1
        priceTitleLabel.minimumScaleFactor = 8.0 / priceTitleLabel.font.pointSize
        priceView.addSubview(priceTitleLabel)
        
        priceTitleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(priceLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(-5)
        }
        
        self.addSubview(priceView)
        priceView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(tokenLogo.snp.trailing).offset(5)
            maker.centerY.equalToSuperview()
            maker.width.equalTo(DefaultPriceWidth)
        }
        
        buyButton.setTitle("下单", for: .normal)
        buyButton.backgroundColor = UIColor.primaryBlue
        buyButton.cornerRadius = 10
        buyButton.addTarget(self, action: #selector(buy), for: .touchUpInside)
        self.addSubview(buyButton)
        buyButton.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(priceView.snp.trailing).offset(25)
            maker.trailing.equalToSuperview().offset(-16)
            maker.centerY.equalToSuperview()
        }
        self.backgroundColor = UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func failedBuy() {
        DispatchQueue.main.async {
            self.buyButton.stopAnimation(animationStyle: .shake, completion: {})
        }
    }
    
    public func setProduct(_ product: APITokenProduct!) {
        guard let token = product.token else {
            return
        }
        
        if let logoImage = token.logoImage {
            tokenLogo.setImage(logoImage, for: .normal)
        } else if let logo = token.logo {
            self.tokenLogo.kf.setImage(with: URL(string: logo), for: .normal)
        }
        
        if let tokenSymbol = token.symbol {
            priceTitleLabel.text = "需要\(tokenSymbol)"
        }
        if let price = product.price {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.minimumFractionDigits = 1
            numberFormatter.maximumFractionDigits = 4
            numberFormatter.alwaysShowsDecimalSeparator = true
            var val = Double(price)
            if let decimals = product.token!.decimals {
                val = val / pow(10, Double(decimals))
            }
            priceLabel.text = val.formate(formatter: numberFormatter)
        } else {
            priceLabel.text = "0"
        }
    }
}

extension TokenProductContentHeaderView {
    @objc private func gotoToken() {
        if let delegate = self.delegate {
            delegate.gotoToken(nil)
        }
    }
    @objc private func buy() {
        if let delegate = self.delegate {
            self.buyButton.startAnimation()
            delegate.buy(nil)
        }
    }
}
