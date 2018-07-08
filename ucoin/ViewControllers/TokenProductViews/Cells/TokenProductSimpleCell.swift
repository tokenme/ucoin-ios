//
//  TokenProductSimpleCell.swift
//  ucoin
//
//  Created by Syd on 2018/6/26.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import FSPagerView
import Reusable
import SnapKit

fileprivate let DefaultImageHeight = 80.0

final class TokenProductSimpleCell: UITableViewCell, Reusable {
    
    private var images: [String]?
    private let titleLabel = UILabel()
    private let dateRangeLabel = UILabel()
    private let stackView = UIStackView()
    private let priceLabel = UILabel()
    private let totalSupplyLabel = UILabel()
    private let amountLabel = UILabel()
    private let imageGridView = FTImageGridView()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        titleLabel.font = MainFont.medium.with(size: 17)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 8.0 / titleLabel.font.pointSize
        containerView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.top.equalToSuperview().offset(8)
        }
        
        
        dateRangeLabel.font = MainFont.light.with(size: 12)
        dateRangeLabel.textColor = UIColor.lightGray
        dateRangeLabel.adjustsFontSizeToFitWidth = true
        dateRangeLabel.numberOfLines = 1
        dateRangeLabel.minimumScaleFactor = 8.0 / dateRangeLabel.font.pointSize
        containerView.addSubview(dateRangeLabel)
        dateRangeLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        let priceView = UIView()
        
        priceLabel.font = MainFont.bold.with(size: 15)
        priceLabel.tintColor = UIColor.primaryBlue
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
        let priceTitleLabel = UILabel()
        priceTitleLabel.font = MainFont.light.with(size: 12)
        priceTitleLabel.text = "消耗代币"
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
        
        let amountView = UIView()
        amountLabel.font = MainFont.bold.with(size: 15)
        amountLabel.tintColor = UIColor.primaryBlue
        amountLabel.textAlignment = .center
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.numberOfLines = 1
        amountLabel.minimumScaleFactor = 8.0 / amountLabel.font.pointSize
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
        
        let totalSupplyView = UIView()
        
        totalSupplyLabel.font = MainFont.bold.with(size: 15)
        totalSupplyLabel.tintColor = UIColor.primaryBlue
        totalSupplyLabel.textAlignment = .center
        totalSupplyLabel.adjustsFontSizeToFitWidth = true
        totalSupplyLabel.numberOfLines = 1
        totalSupplyLabel.minimumScaleFactor = 8.0 / totalSupplyLabel.font.pointSize
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
        
        stackView.addArrangedSubview(priceView)
        stackView.addArrangedSubview(amountView)
        stackView.addArrangedSubview(totalSupplyView)
        
        containerView.addSubview(imageGridView)
        
        containerView.addSubview(stackView)
        
        stackView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalTo(dateRangeLabel.snp.bottom).offset(8)
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
    
    public func fill(_ product: APITokenProduct) {
        self.containerView.needsUpdateConstraints()
        
        titleLabel.text = product.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: product.startDate!)
        let endDate = dateFormatter.string(from: product.endDate!)
        dateRangeLabel.text = "有效期: \(startDate) - \(endDate)"
        
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
        
        if product.amount ?? 0 > 0 {
            amountLabel.text = "\(product.amount ?? 0)"
        } else {
            amountLabel.text = "不限"
        }
        
        totalSupplyLabel.text = "\(product.totalSupply ?? 0)"
        
        self.images = product.images
        
        if product.images?.count ?? 0 > 0 {
            let gridWidth = UIScreen.main.bounds.width - 32
            let gridHeight = FTImageGridView.getHeightWithWidth(gridWidth, imgCount: product.images!.count)
            imageGridView.frame = CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight)
            
            imageGridView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(8)
                maker.trailing.equalToSuperview().offset(-8)
                maker.top.equalTo(stackView.snp.bottom).offset(16)
                maker.height.equalTo(gridHeight)
                maker.bottom.equalToSuperview().offset(-8)
            }
            
            var resources : [FTImageResource] = []
            for img in product.images! {
                let resource : FTImageResource = FTImageResource(image: nil, imageURLString:img)
                resources.append(resource)
            }
            
            imageGridView.showWithImageArray(resources) { (buttonsArray, buttonIndex) in
                FTImageViewer.showImages(product.images!, atIndex: buttonIndex, fromSenderArray: buttonsArray)
            }
            
            imageGridView.setNeedsLayout()
            imageGridView.layoutIfNeeded()
        } else {
            for subView in imageGridView.subviews {
                subView.removeFromSuperview()
            }
            imageGridView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(8)
                maker.trailing.equalToSuperview().offset(-8)
                maker.top.equalTo(stackView.snp.bottom).offset(16)
                maker.height.equalTo(0)
                maker.bottom.equalToSuperview().offset(-8)
            }
        }
        self.containerView.setNeedsLayout()
        self.containerView.layoutIfNeeded()
    }
}

extension TokenProductSimpleCell: FSPagerViewDataSource {
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        if let images = self.images {
            return images.count
        }
        return 0
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        guard let images = self.images else {
            return cell
        }
        cell.imageView?.kf.setImage(with: URL(string: images[index])!)
        return cell
    }
}
