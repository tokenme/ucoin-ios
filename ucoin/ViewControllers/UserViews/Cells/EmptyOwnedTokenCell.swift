//
//  EmptyOwnedTokenCell.swift
//  ucoin
//
//  Created by Syd on 2018/6/14.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

final class EmptyOwnedTokenCell: UITableViewCell, Reusable {
    
    weak public var delegate: UserActionsTableCellDelegate?
    private let spinner = LoaderModal(backgroundColor: UIColor.white)!
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        let descLabel = UILabel()
        descLabel.text = "您还没有创建代币"
        descLabel.font = MainFont.light.with(size: 15)
        descLabel.textAlignment = NSTextAlignment.center
        descLabel.textColor = UIColor.lightGray
        
        containerView.addSubview(descLabel)
        
        descLabel.snp.remakeConstraints({ (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
        })
        
        let createButton = UIButton(type: UIButtonType.roundedRect)
        createButton.setTitle("去创建", for: .normal)
        createButton.titleLabel?.font = MainFont.light.with(size: 10)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = UIColor.primaryBlue
        createButton.layer.cornerRadius = 5
        
        createButton.addTarget(self, action: #selector(showCreateToken), for: .touchUpInside)
        
        containerView.addSubview(createButton)
        createButton.snp.remakeConstraints({ (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(descLabel.snp.bottom).offset(10)
            maker.bottom.equalToSuperview()
            maker.width.equalTo(60)
        })
        
        self.contentView.addSubview(containerView)
        
        containerView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalToSuperview().offset(40)
            maker.bottom.equalToSuperview().offset(-40)
        }
        
        self.contentView.addSubview(spinner)
        
        return containerView
    }()
    
    func fill(_ isLoading: Bool) {
        self.containerView.needsUpdateConstraints()
        
        if isLoading {
            spinner.isHidden = false
            spinner.start()
        } else {
            spinner.isHidden = true
            spinner.stop()
        }
    }
}

// Actions Section
extension EmptyOwnedTokenCell {
    
    @objc private func showCreateToken() {
        self.delegate?.showCreateToken()
    }
    
}
