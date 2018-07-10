//
//  TokenTaskInfoTableCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/9.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable

fileprivate let DefaultLogoHeight = 50.0
fileprivate let DefaultSymbolWidth = 50.0

final class TokenTaskInfoTableCell: UITableViewCell, Reusable {
    weak public var delegate: TokenTaskViewDelegate?
    
    private let symbolLabel = UILabelPadding()
    private let titleView = UIView()
    private var titleLabel = UILabel()
    private let dateRangeLabel = UILabel()
    private let bonusLabel = UILabel()
    private let bonusTitleLabel = UILabel()
    private let amountLabel = UILabel()
    private let stackView = UIStackView()
    
    private let submitEvidenceButton = TransitionButton()
    
    private let tokenLogo = UIButton(frame: CGRect(x: 0, y: 0, width: DefaultLogoHeight, height: DefaultLogoHeight))
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        tokenLogo.layer.borderWidth = 0
        tokenLogo.layer.cornerRadius = CGFloat(DefaultLogoHeight / 2.0)
        tokenLogo.contentMode = .scaleAspectFill
        tokenLogo.clipsToBounds = true
        tokenLogo.addTarget(self, action: #selector(gotoToken), for: .touchUpInside)
        titleView.addSubview(tokenLogo)
        tokenLogo.snp.remakeConstraints { (maker) -> Void in
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
            maker.leading.equalToSuperview()
            maker.width.equalTo(DefaultLogoHeight)
            maker.height.equalTo(DefaultLogoHeight)
        }
        
        titleLabel.font = MainFont.medium.with(size: 17)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 8.0 / titleLabel.font.pointSize
        titleView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(tokenLogo.snp.trailing).offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(8)
        }
        
        
        dateRangeLabel.font = MainFont.light.with(size: 12)
        dateRangeLabel.textColor = UIColor.lightGray
        dateRangeLabel.adjustsFontSizeToFitWidth = true
        dateRangeLabel.numberOfLines = 1
        dateRangeLabel.minimumScaleFactor = 8.0 / dateRangeLabel.font.pointSize
        titleView.addSubview(dateRangeLabel)
        dateRangeLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalTo(titleLabel.snp.leading)
            maker.trailing.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        
        containerView.addSubview(titleView)
        titleView.snp.remakeConstraints { (maker) -> Void in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
        }
        
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        let bonusView = UIView()
        bonusLabel.font = MainFont.bold.with(size: 15)
        bonusLabel.tintColor = UIColor.primaryBlue
        bonusLabel.textAlignment = .center
        bonusLabel.adjustsFontSizeToFitWidth = true
        bonusLabel.numberOfLines = 1
        bonusLabel.minimumScaleFactor = 8.0 / bonusLabel.font.pointSize
        bonusView.addSubview(bonusLabel)
        bonusLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        
        bonusTitleLabel.font = MainFont.light.with(size: 12)
        bonusTitleLabel.text = "奖励代币"
        bonusTitleLabel.textAlignment = .center
        bonusTitleLabel.adjustsFontSizeToFitWidth = true
        bonusTitleLabel.numberOfLines = 1
        bonusTitleLabel.minimumScaleFactor = 8.0 / bonusTitleLabel.font.pointSize
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
        amountTitleLabel.text = "人数限制"
        amountTitleLabel.textAlignment = .center
        amountTitleLabel.adjustsFontSizeToFitWidth = true
        amountTitleLabel.numberOfLines = 1
        amountTitleLabel.minimumScaleFactor = 8.0 / amountTitleLabel.font.pointSize
        amountView.addSubview(amountTitleLabel)
        
        amountTitleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(amountLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(-5)
        }
        
        symbolLabel.layer.borderWidth = 0
        symbolLabel.layer.cornerRadius = 5.0
        symbolLabel.clipsToBounds = true
        symbolLabel.backgroundColor = UIColor.primaryBlue
        symbolLabel.paddingTop = 3.0
        symbolLabel.paddingLeft = 5.0
        symbolLabel.paddingRight = 5.0
        symbolLabel.paddingBottom = 3.0
        symbolLabel.textColor = .white
        symbolLabel.font = MainFont.medium.with(size: 10)
        symbolLabel.adjustsFontSizeToFitWidth = true
        symbolLabel.numberOfLines = 1
        symbolLabel.minimumScaleFactor = 8.0 / symbolLabel.font.pointSize
        containerView.addSubview(symbolLabel)
        symbolLabel.snp.remakeConstraints { (maker) -> Void in
            maker.top.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.width.lessThanOrEqualTo(DefaultSymbolWidth)
        }
        
        stackView.addArrangedSubview(bonusView)
        stackView.addArrangedSubview(amountView)
        
        containerView.addSubview(stackView)
        
        stackView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalTo(titleView.snp.bottom).offset(8)
        }
        
        submitEvidenceButton.setTitle("任务已完成", for: .normal)
        submitEvidenceButton.backgroundColor = UIColor.greenGrass
        submitEvidenceButton.cornerRadius = 15
        containerView.addSubview(submitEvidenceButton)
        submitEvidenceButton.snp.remakeConstraints { (maker) -> Void in
            maker.top.equalTo(stackView.snp.bottom).offset(8)
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
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
    
    public func fill(_ task: APITokenTask!, user: APIUser?) {
        self.containerView.needsUpdateConstraints()
        
        if task.needEvidence == 1 {
            if task.isOwnedByUser(wallet: user?.wallet) {
                submitEvidenceButton.setTitle("查看证明列表并打币", for: .normal)
                submitEvidenceButton.addTarget(self, action: #selector(gotoTokenTaskEvidences), for: .touchUpInside)
            } else {
                submitEvidenceButton.setTitle("任务已完成，提交证明", for: .normal)
                submitEvidenceButton.addTarget(self, action: #selector(showSubmitEvidence), for: .touchUpInside)
            }
            submitEvidenceButton.isHidden = false
            submitEvidenceButton.snp.remakeConstraints {[weak self] (maker) -> Void in
                guard let weakSelf = self else {
                    return
                }
                maker.top.equalTo(weakSelf.stackView.snp.bottom).offset(8)
                maker.leading.equalToSuperview().offset(28)
                maker.trailing.equalToSuperview().offset(-28)
                maker.bottom.equalToSuperview().offset(-8)
            }
            stackView.snp.remakeConstraints {[weak self] (maker) -> Void in
                guard let weakSelf = self else {
                    return
                }
                maker.leading.equalToSuperview().offset(28)
                maker.trailing.equalToSuperview().offset(-28)
                maker.top.equalTo(weakSelf.titleView.snp.bottom).offset(8)
            }
        } else {
            submitEvidenceButton.isHidden = true
            submitEvidenceButton.snp.removeConstraints()
            stackView.snp.remakeConstraints {[weak self] (maker) -> Void in
                guard let weakSelf = self else {
                    return
                }
                maker.leading.equalToSuperview().offset(28)
                maker.trailing.equalToSuperview().offset(-28)
                maker.top.equalTo(weakSelf.titleView.snp.bottom).offset(8)
                maker.bottom.equalToSuperview().offset(-8)
            }
        }
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
        
        guard let token = task.token else {
            return
        }
        bonusTitleLabel.text = "奖励\(token.symbol!)"
        symbolLabel.text = token.symbol
        
        if let logoImage = token.logoImage {
            tokenLogo.setImage(logoImage, for: .normal)
        } else if let logo = token.logo {
            self.tokenLogo.kf.setImage(with: URL(string: logo), for: .normal)
        }
        
    }
}

extension TokenTaskInfoTableCell {
    @objc private func gotoToken() {
        if let delegate = self.delegate {
            delegate.gotoToken(nil)
        }
    }
    
    @objc private func showSubmitEvidence() {
        if let delegate = self.delegate {
            delegate.showSubmitEvidence()
        }
    }
    
    @objc private func gotoTokenTaskEvidences() {
        if let delegate = self.delegate {
            delegate.gotoTokenTaskEvidences()
        }
    }
}
