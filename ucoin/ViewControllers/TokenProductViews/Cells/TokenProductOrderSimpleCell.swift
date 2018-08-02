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
fileprivate let DefaultAvatarWidth = 35.0

final class TokenProductOrderSimpleCell: UITableViewCell, Reusable {
    
    private let avatarView = UIImageView(frame: CGRect(x: 0, y: 0, width: DefaultAvatarWidth, height: DefaultAvatarWidth))
    private let nickLabel = UILabel()
    private let idLabel = UILabel()
    private let txLabel = UILabel()
    private let dateLabel = UILabel()
    private let indicator = LinearActivityIndicatorView()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        let userView = UIView()
        avatarView.clipsToBounds = true
        avatarView.layer.borderWidth = 0
        avatarView.layer.cornerRadius = CGFloat(DefaultAvatarWidth / 2.0)
        userView.addSubview(avatarView)
        avatarView.snp.remakeConstraints { (maker) -> Void in
            maker.centerY.equalToSuperview()
            maker.width.equalTo(DefaultAvatarWidth)
            maker.height.equalTo(DefaultAvatarWidth)
            maker.leading.equalToSuperview()
        }
        idLabel.font = MainFont.medium.with(size: 17)
        idLabel.adjustsFontSizeToFitWidth = true
        idLabel.numberOfLines = 1
        idLabel.minimumScaleFactor = 8.0 / idLabel.font.pointSize
        userView.addSubview(idLabel)
        idLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(avatarView.snp.trailing).offset(16)
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(8)
        }
        
        nickLabel.font = MainFont.thin.with(size: 11)
        nickLabel.adjustsFontSizeToFitWidth = true
        nickLabel.numberOfLines = 1
        nickLabel.minimumScaleFactor = 8.0 / nickLabel.font.pointSize
        userView.addSubview(nickLabel)
        nickLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(idLabel.snp.leading)
            maker.trailing.equalToSuperview()
            maker.top.equalTo(idLabel.snp.bottom).offset(4)
            maker.bottom.equalToSuperview().offset(-8)
        }
        
        containerView.addSubview(userView)
        userView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(16)
        }
        
        
        txLabel.font = MainFont.light.with(size: 10)
        txLabel.adjustsFontSizeToFitWidth = true
        txLabel.numberOfLines = 1
        txLabel.minimumScaleFactor = 8.0 / txLabel.font.pointSize
        containerView.addSubview(txLabel)
        txLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(userView.snp.leading)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(userView.snp.bottom).offset(8)
        }
        
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: Double(UIScreen.main.bounds.width), height: DefaultIndicatorHeight)
        containerView.addSubview(indicator)
        indicator.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(idLabel.snp.leading)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(txLabel.snp.bottom).offset(8)
            maker.height.equalTo(DefaultIndicatorHeight)
        }
        
        dateLabel.font = MainFont.light.with(size: 12)
        dateLabel.textColor = UIColor.lightGray
        dateLabel.textAlignment = .right
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.numberOfLines = 1
        dateLabel.minimumScaleFactor = 8.0 / dateLabel.font.pointSize
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
        
        if let buyer = order.buyer {
            if let avatar = buyer.avatar {
                avatarView.kf.setImage(with: URL(string: avatar))
            }
            nickLabel.text = buyer.showName
        }
        
        if order.productTxStatus == 1 {
            DispatchQueue.main.async {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.indicator.stopAnimating()
                weakSelf.indicator.isHidden = true
                weakSelf.indicator.snp.removeConstraints()
                weakSelf.dateLabel.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview().offset(16)
                    maker.trailing.equalToSuperview().offset(-16)
                    maker.top.equalTo(weakSelf.txLabel.snp.bottom).offset(8)
                    maker.bottom.equalToSuperview().offset(-8)
                }
            }
        } else {
            DispatchQueue.main.async {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.indicator.startAnimating()
                weakSelf.indicator.isHidden = false
                weakSelf.dateLabel.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview().offset(16)
                    maker.trailing.equalToSuperview().offset(-16)
                    maker.top.equalTo(weakSelf.indicator.snp.bottom).offset(8)
                    maker.bottom.equalToSuperview().offset(-8)
                }
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd H:m:s"
        let insertDate = dateFormatter.string(from: order.insertedTime!)
        dateLabel.text = "成交日期: \(insertDate)"
    }
}

