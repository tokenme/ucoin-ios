//
//  TokenProductOrderSimpleCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/6.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable

fileprivate let DefaultIndicatorHeight = 5.0

final class TokenProductOrderSimpleCell: UITableViewCell, Reusable {
    
    private let idLabel = UILabel()
    private let txLabel = UILabel()
    private let dateLabel = UILabel()
    private let indicator = LinearActivityIndicatorView()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        idLabel.font = MainFont.medium.with(size: 17)
        idLabel.adjustsFontSizeToFitWidth = true
        idLabel.numberOfLines = 1
        idLabel.minimumScaleFactor = 8.0 / txLabel.font.pointSize
        containerView.addSubview(idLabel)
        idLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(8)
        }
        
        txLabel.font = MainFont.medium.with(size: 10)
        txLabel.adjustsFontSizeToFitWidth = true
        txLabel.numberOfLines = 1
        txLabel.minimumScaleFactor = 8.0 / txLabel.font.pointSize
        containerView.addSubview(txLabel)
        txLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(idLabel.snp.bottom).offset(8)
        }
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: Double(UIScreen.main.bounds.width), height: DefaultIndicatorHeight)
        containerView.addSubview(indicator)
        indicator.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(txLabel.snp.bottom).offset(8)
            maker.height.equalTo(DefaultIndicatorHeight)
        }
        
        dateLabel.font = MainFont.light.with(size: 12)
        dateLabel.textColor = UIColor.lightGray
        dateLabel.textAlignment = .right
        containerView.addSubview(dateLabel)
        dateLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(indicator.snp.bottom).offset(8)
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
        if let tokenId = order.tokenId {
            idLabel.text = "ID: \(tokenId)"
        }
        
        if let tx = order.tx {
            txLabel.text = tx
        }
        
        if order.productTxStatus == 1 {
            DispatchQueue.main.async {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.indicator.stopAnimating()
                weakSelf.indicator.snp.remakeConstraints {[weak weakSelf] (maker) -> Void in
                    guard let weakSelf2 = weakSelf else {
                        return
                    }
                    maker.leading.equalToSuperview().offset(16)
                    maker.trailing.equalToSuperview().offset(-16)
                    maker.top.equalTo(weakSelf2.txLabel.snp.bottom).offset(8)
                    maker.height.equalTo(0)
                }
            }
        } else {
            DispatchQueue.main.async {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.indicator.startAnimating()
                weakSelf.indicator.snp.remakeConstraints {[weak weakSelf] (maker) -> Void in
                    guard let weakSelf2 = weakSelf else {
                        return
                    }
                    maker.leading.equalToSuperview().offset(16)
                    maker.trailing.equalToSuperview().offset(-16)
                    maker.top.equalTo(weakSelf2.txLabel.snp.bottom).offset(8)
                    maker.height.equalTo(DefaultIndicatorHeight)
                }
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd H:m:s"
        let insertDate = dateFormatter.string(from: order.insertedTime!)
        dateLabel.text = "成交日期: \(insertDate)"
    }
}

