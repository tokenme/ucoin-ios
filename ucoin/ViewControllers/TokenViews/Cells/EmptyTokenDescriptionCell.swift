//
//  EmptyTokenDescriptionCell.swift
//  ucoin
//
//  Created by Syd on 2018/6/19.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

final class EmptyTokenDescriptionCell: UITableViewCell, Reusable {
    
    weak public var delegate: TokenViewDelegate?
    private let descLabel = UILabel()
    private let spinner = LoaderModal(backgroundColor: UIColor.white)!
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        descLabel.font = MainFont.light.with(size: 15)
        descLabel.textAlignment = NSTextAlignment.center
        descLabel.textColor = UIColor.lightGray
        
        containerView.addSubview(descLabel)
        
        descLabel.snp.remakeConstraints({ (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
        })
        
        self.contentView.addSubview(containerView)
        
        containerView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalToSuperview().offset(60)
            maker.bottom.equalToSuperview().offset(-60)
        }
        
        self.contentView.addSubview(spinner)
        
        return containerView
    }()
    
    func fill(_ text: String, isLoading: Bool) {
        descLabel.text = text
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
