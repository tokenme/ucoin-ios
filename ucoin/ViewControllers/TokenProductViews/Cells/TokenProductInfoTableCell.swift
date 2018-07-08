//
//  TokenProductInfoTableCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/2.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable

final class TokenProductInfoTableCell: UITableViewCell, Reusable {
    
    private let titleLabel = UILabel()
    private let dateRangeLabel = UILabel()
    private let stackView = UIStackView()
    private let totalSupplyLabel = UILabel()
    private let amountLabel = UILabel()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        titleLabel.font = MainFont.medium.with(size: 17)
        containerView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(8)
        }
        
        
        dateRangeLabel.font = MainFont.light.with(size: 12)
        dateRangeLabel.textColor = UIColor.lightGray
        containerView.addSubview(dateRangeLabel)
        dateRangeLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        let totalSupplyView = UIView()
        
        totalSupplyLabel.font = MainFont.bold.with(size: 15)
        totalSupplyLabel.tintColor = UIColor.primaryBlue
        totalSupplyLabel.textAlignment = .center
        totalSupplyView.addSubview(totalSupplyLabel)
        totalSupplyLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        let totalSupplyTitleLabel = UILabel()
        totalSupplyTitleLabel.font = MainFont.light.with(size: 12)
        totalSupplyTitleLabel.text = "销量"
        totalSupplyTitleLabel.textAlignment = .center
        totalSupplyView.addSubview(totalSupplyTitleLabel)
        
        totalSupplyTitleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(totalSupplyLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(-5)
        }
        
        let amountView = UIView()
        amountLabel.font = MainFont.bold.with(size: 15)
        amountLabel.tintColor = UIColor.primaryBlue
        amountLabel.textAlignment = .center
        amountView.addSubview(amountLabel)
        amountLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        let amountTitleLabel = UILabel()
        amountTitleLabel.font = MainFont.light.with(size: 12)
        amountTitleLabel.text = "限制人数"
        amountTitleLabel.textAlignment = .center
        amountView.addSubview(amountTitleLabel)
        
        amountTitleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(amountLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(-5)
        }
        
        stackView.addArrangedSubview(totalSupplyView)
        stackView.addArrangedSubview(amountView)
        
        containerView.addSubview(stackView)
        
        stackView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalTo(dateRangeLabel.snp.bottom).offset(8)
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
    
    public func fill(_ tokenProduct: APITokenProduct?) {
        self.containerView.needsUpdateConstraints()
        guard let product = tokenProduct else {
            return
        }
        titleLabel.text = product.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: product.startDate!)
        let endDate = dateFormatter.string(from: product.endDate!)
        dateRangeLabel.text = "有效期: \(startDate) - \(endDate)"
        
        totalSupplyLabel.text = "\(product.totalSupply ?? 0)"
        
        if product.amount ?? 0 > 0 {
            amountLabel.text = "\(product.amount ?? 0)"
        } else {
            amountLabel.text = "不限"
        }
    }
}
