//
//  TokenTaskInfoHeaderCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/2.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import TTSegmentedControl

final class TokenTaskInfoHeaderCell: UIView, Reusable {
    
    static let height: CGFloat = 110
    
    private var titleLabel = UILabel()
    private let dateRangeLabel = UILabel()
    private let bonusLabel = UILabel()
    private let amountLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = MainFont.medium.with(size: 17)
        self.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(8)
        }
        
        dateRangeLabel.font = MainFont.light.with(size: 12)
        dateRangeLabel.textColor = UIColor.lightGray
        self.addSubview(dateRangeLabel)
        dateRangeLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
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
        
        self.addSubview(stackView)
        
        
        stackView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalTo(dateRangeLabel.snp.bottom).offset(8)
        }
        
        self.backgroundColor = UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func setTask(_ task: APITokenTask!) {
        self.titleLabel.text = task.title
        
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
    }
}
