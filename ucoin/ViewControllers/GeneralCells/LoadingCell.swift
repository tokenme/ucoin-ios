//
//  LoadingCell.swift
//  ucoin
//
//  Created by Syd on 2018/6/14.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit
import NVActivityIndicatorView

final class LoadingCell: UITableViewCell, Reusable {
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        let loadingView = NVActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50), type: NVActivityIndicatorType.ballScaleMultiple, color: UIColor.primaryBlue)
        
        containerView.addSubview(loadingView)
        
        loadingView.snp.remakeConstraints { (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.width.equalTo(50)
            maker.height.equalTo(50)
        }
        
        self.contentView.addSubview(containerView)
        
        containerView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(60)
            maker.bottom.equalToSuperview().offset(-60)
        }
        
        loadingView.startAnimating()
        return containerView
    }()
    
    func fill() {
        self.containerView.needsUpdateConstraints()
    }
}
