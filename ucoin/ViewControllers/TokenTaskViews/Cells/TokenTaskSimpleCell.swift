//
//  TokenTaskSimpleCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/2.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

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

final class TokenTaskSimpleCell: UITableViewCell, Reusable {
    
    private var images: [String]?
    private let titleLabel = UILabel()
    private let dateRangeLabel = UILabel()
    private let bonusLabel = UILabel()
    private let amountLabel = UILabel()
    private let stackView = UIStackView()
    private let imageGridView = FTImageGridView(frame: CGRect.zero)
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        titleLabel.font = MainFont.medium.with(size: 17)
        containerView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.top.equalToSuperview().offset(8)
        }
        
        dateRangeLabel.font = MainFont.light.with(size: 12)
        dateRangeLabel.textColor = UIColor.lightGray
        containerView.addSubview(dateRangeLabel)
        dateRangeLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        let bonusView = UIView()
        bonusLabel.font = MainFont.bold.with(size: 15)
        bonusLabel.tintColor = UIColor.primaryBlue
        bonusLabel.textAlignment = .center
        bonusView.addSubview(bonusLabel)
        bonusLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        let bonusTitleLabel = UILabel()
        bonusTitleLabel.font = MainFont.light.with(size: 12)
        bonusTitleLabel.text = "奖励代币"
        bonusTitleLabel.textAlignment = .center
        bonusView.addSubview(bonusTitleLabel)
        
        bonusTitleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(bonusLabel.snp.bottom).offset(5)
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
        amountTitleLabel.text = "人数限制"
        amountTitleLabel.textAlignment = .center
        amountView.addSubview(amountTitleLabel)
        
        amountTitleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(amountLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(-5)
        }
        
        stackView.addArrangedSubview(bonusView)
        stackView.addArrangedSubview(amountView)
        
        containerView.addSubview(stackView)
        
        
        stackView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalTo(dateRangeLabel.snp.bottom).offset(8)
        }
        
        containerView.addSubview(imageGridView)
        
        self.contentView.addSubview(containerView)
        
        containerView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        
        return containerView
    }()
    
    public func fill(_ task: APITokenTask!) {
        self.containerView.needsUpdateConstraints()
        
        titleLabel.text = task.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: task.startDate!)
        let endDate = dateFormatter.string(from: task.endDate!)
        dateRangeLabel.text = "有效期: \(startDate) - \(endDate)"
        
        if let bonus = task.bonus {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.minimumFractionDigits = 1
            numberFormatter.maximumFractionDigits = 4
            numberFormatter.alwaysShowsDecimalSeparator = true
            var val = Double(bonus)
            if let decimals = task.token?.decimals {
                val = val / pow(10, Double(decimals))
            }
            bonusLabel.text = val.formate(formatter: numberFormatter)
        } else {
            bonusLabel.text = "0"
        }
        
        if task.amount ?? 0 > 0 {
            amountLabel.text = "\(task.amount ?? 0)"
        } else {
            amountLabel.text = "不限"
        }
        
        self.images = task.images
        
        if task.images?.count ?? 0 > 0 {
            let gridWidth = UIScreen.main.bounds.width - 32
            let gridHeight = FTImageGridView.getHeightWithWidth(gridWidth, imgCount: task.images!.count)
            imageGridView.frame = CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight)
            
            imageGridView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(8)
                maker.trailing.equalToSuperview().offset(-8)
                maker.top.equalTo(stackView.snp.bottom).offset(16)
                maker.height.equalTo(gridHeight)
                maker.bottom.equalToSuperview().offset(-8)
            }
            
            var resources : [FTImageResource] = []
            for img in task.images! {
                let resource : FTImageResource = FTImageResource(image: nil, imageURLString:img)
                resources.append(resource)
            }
            
            imageGridView.showWithImageArray(resources) { (buttonsArray, buttonIndex) in
                FTImageViewer.showImages(task.images!, atIndex: buttonIndex, fromSenderArray: buttonsArray)
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
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
    }
}

extension TokenTaskSimpleCell: FSPagerViewDataSource {
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

