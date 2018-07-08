//
//  EmptyTokenOwnedDescriptionCell.swift
//  ucoin
//
//  Created by Syd on 2018/6/20.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

final class EmptyTokenOwnedDescriptionCell: UITableViewCell, Reusable {
    
    weak public var delegate: TokenViewDelegate?
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        let descLabel = UILabel()
        descLabel.text = "您还没有添加代币描述"
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
        createButton.setTitle("去添加", for: .normal)
        createButton.titleLabel?.font = MainFont.light.with(size: 10)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = UIColor.primaryBlue
        createButton.layer.cornerRadius = 5
        
        createButton.addTarget(self, action: #selector(showEditDescription), for: .touchUpInside)
        
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
        
        return containerView
    }()
    
    func fill() {
        self.containerView.needsUpdateConstraints()
    }
}

// Actions Section
extension EmptyTokenOwnedDescriptionCell {
    
    @objc private func showEditDescription() {
        if let delegate = self.delegate {
            delegate.showEditDescription()
        }
    }
    
}
