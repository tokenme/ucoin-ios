//
//  OrderInfoTableCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/6.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable

fileprivate let DefaultLogoHeight = 50.0
fileprivate let DefaultSymbolWidth = 50.0

final class OrderInfoTableCell: UITableViewCell, Reusable {
    weak public var delegate: OrderViewDelegate?
    
    private let titleLabel = UILabel()
    private let dateRangeLabel = UILabel()
    private let stackView = UIStackView()
    private let idLabel = UILabel()
    private let createDateLabel = UILabel()
    
    private let tokenLogo = UIButton(frame: CGRect(x: 0, y: 0, width: DefaultLogoHeight, height: DefaultLogoHeight))
    private let symbolLabel = UILabelPadding()
    private let priceTitleLabel = UILabel()
    private let priceLabel = UILabel()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        let titleView = UIView()
        tokenLogo.layer.borderWidth = 0
        tokenLogo.layer.cornerRadius = CGFloat(DefaultLogoHeight / 2.0)
        tokenLogo.contentMode = .scaleAspectFill
        tokenLogo.clipsToBounds = true
        tokenLogo.addTarget(self, action: #selector(gotoToken), for: .touchUpInside)
        titleView.addSubview(tokenLogo)
        tokenLogo.snp.remakeConstraints { (maker) -> Void in
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
            maker.leading.equalToSuperview()
            maker.width.equalTo(DefaultLogoHeight)
            maker.height.equalTo(DefaultLogoHeight)
        }
        
        titleLabel.font = MainFont.medium.with(size: 17)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 8.0 / titleLabel.font.pointSize
        titleView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(tokenLogo.snp.trailing).offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(8)
        }
        
        
        dateRangeLabel.font = MainFont.light.with(size: 12)
        dateRangeLabel.textColor = UIColor.lightGray
        dateRangeLabel.adjustsFontSizeToFitWidth = true
        dateRangeLabel.numberOfLines = 1
        dateRangeLabel.minimumScaleFactor = 8.0 / dateRangeLabel.font.pointSize
        titleView.addSubview(dateRangeLabel)
        dateRangeLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(titleLabel.snp.leading)
            maker.trailing.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        
        containerView.addSubview(titleView)
        titleView.snp.remakeConstraints { (maker) -> Void in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
        }
        
        symbolLabel.layer.borderWidth = 0
        symbolLabel.layer.cornerRadius = 5.0
        symbolLabel.clipsToBounds = true
        symbolLabel.backgroundColor = UIColor.primaryBlue
        symbolLabel.paddingTop = 3.0
        symbolLabel.paddingLeft = 5.0
        symbolLabel.paddingRight = 5.0
        symbolLabel.paddingBottom = 3.0
        symbolLabel.textColor = .white
        symbolLabel.font = MainFont.medium.with(size: 10)
        symbolLabel.adjustsFontSizeToFitWidth = true
        symbolLabel.numberOfLines = 1
        symbolLabel.minimumScaleFactor = 8.0 / symbolLabel.font.pointSize
        containerView.addSubview(symbolLabel)
        symbolLabel.snp.remakeConstraints { (maker) -> Void in
            maker.top.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.width.lessThanOrEqualTo(DefaultSymbolWidth)
        }
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        let idView = UIView()
        
        idLabel.font = MainFont.bold.with(size: 15)
        idLabel.tintColor = UIColor.primaryBlue
        idLabel.textAlignment = .center
        idLabel.adjustsFontSizeToFitWidth = true
        idLabel.numberOfLines = 1
        idLabel.minimumScaleFactor = 8.0 / idLabel.font.pointSize
        idView.addSubview(idLabel)
        idLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        let idTitleLabel = UILabel()
        idTitleLabel.font = MainFont.light.with(size: 12)
        idTitleLabel.text = "ID"
        idTitleLabel.textAlignment = .center
        idView.addSubview(idTitleLabel)
        
        idTitleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(idLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(-5)
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
        priceTitleLabel.text = "花费"
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
        
        let createDateView = UIView()
        createDateLabel.font = MainFont.bold.with(size: 15)
        createDateLabel.tintColor = UIColor.primaryBlue
        createDateLabel.textAlignment = .center
        createDateLabel.adjustsFontSizeToFitWidth = true
        createDateLabel.numberOfLines = 1
        createDateLabel.minimumScaleFactor = 8.0 / createDateLabel.font.pointSize
        createDateView.addSubview(createDateLabel)
        createDateLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        let createDateTitleLabel = UILabel()
        createDateTitleLabel.font = MainFont.light.with(size: 12)
        createDateTitleLabel.text = "购买日期"
        createDateTitleLabel.textAlignment = .center
        createDateView.addSubview(createDateTitleLabel)
        
        createDateTitleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(createDateLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(-5)
        }
        
        stackView.addArrangedSubview(idView)
        stackView.addArrangedSubview(priceView)
        stackView.addArrangedSubview(createDateView)
        
        containerView.addSubview(stackView)
        
        stackView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalTo(titleView.snp.bottom).offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        
        self.contentView.addSubview(containerView)
        
        containerView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        
        return containerView
    }()
    
    public func fill(_ order: APIOrder!) {
        self.containerView.needsUpdateConstraints()
        guard let product = order.product else {
            return
        }
        titleLabel.text = product.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: product.startDate!)
        let endDate = dateFormatter.string(from: product.endDate!)
        dateRangeLabel.text = "有效期: \(startDate) - \(endDate)"
        
        idLabel.text = "\(order.tokenId!)"
        
        guard let token = product.token else {
            return
        }
        if let logoImage = token.logoImage {
            tokenLogo.setImage(logoImage, for: .normal)
        } else if let logo = token.logo {
            self.tokenLogo.kf.setImage(with: URL(string: logo), for: .normal)
        }
        
        if let tokenSymbol = token.symbol {
            priceTitleLabel.text = "花费\(tokenSymbol)"
            symbolLabel.text = tokenSymbol
        }
        if let price = order.price {
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
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd H:m:s"
        let createTime = dateFormatter2.string(from: order.insertedTime!)
        createDateLabel.text = createTime
    }
}

extension OrderInfoTableCell {
    @objc private func gotoToken() {
        if let delegate = self.delegate {
            delegate.gotoToken(nil)
        }
    }
}
