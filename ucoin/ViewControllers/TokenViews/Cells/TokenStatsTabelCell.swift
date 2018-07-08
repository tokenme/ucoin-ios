//
//  TokenStatsTabelCell.swift
//  ucoin
//
//  Created by Syd on 2018/6/19.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

final class TokenStatsTableCell: UITableViewCell, Reusable {
    private let totalSupplyNumberLabel = UILabel()
    private let totalTransfersNumberLabel = UILabel()
    private let totalHoldersNumberLabel = UILabel()
    private let circulatingSupplyNumberLabel = UILabel()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        let totalSupplyView = UIView()
        totalSupplyNumberLabel.font = MainFont.bold.with(size: 17)
        totalSupplyNumberLabel.tintColor = UIColor.primaryBlue
        totalSupplyNumberLabel.textAlignment = .center
        totalSupplyView.addSubview(totalSupplyNumberLabel)
        totalSupplyNumberLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        let totalSupplyLabel = UILabel()
        totalSupplyLabel.font = MainFont.light.with(size: 12)
        totalSupplyLabel.text = "发行量"
        totalSupplyLabel.textAlignment = .center
        totalSupplyView.addSubview(totalSupplyLabel)
        
        totalSupplyLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(totalSupplyNumberLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(5)
        }
        
        let totalTransfersView = UIView()
        totalTransfersNumberLabel.font = MainFont.bold.with(size: 17)
        totalTransfersNumberLabel.tintColor = UIColor.primaryBlue
        totalTransfersNumberLabel.textAlignment = .center
        totalTransfersView.addSubview(totalTransfersNumberLabel)
        totalTransfersNumberLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        let totalTransfersLabel = UILabel()
        totalTransfersLabel.font = MainFont.light.with(size: 12)
        totalTransfersLabel.text = "交易量"
        totalTransfersLabel.textAlignment = .center
        totalTransfersView.addSubview(totalTransfersLabel)
        
        totalTransfersLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(totalTransfersNumberLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(5)
        }
        
        let totalHoldersView = UIView()
        totalHoldersNumberLabel.font = MainFont.bold.with(size: 17)
        totalHoldersNumberLabel.tintColor = UIColor.primaryBlue
        totalHoldersNumberLabel.textAlignment = .center
        totalHoldersView.addSubview(totalHoldersNumberLabel)
        totalHoldersNumberLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        let totalHoldersLabel = UILabel()
        totalHoldersLabel.font = MainFont.light.with(size: 12)
        totalHoldersLabel.text = "持有人"
        totalHoldersLabel.textAlignment = .center
        totalHoldersView.addSubview(totalHoldersLabel)
        
        totalHoldersLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(totalHoldersNumberLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(5)
        }
        
        let circulatingSupplyView = UIView()
        circulatingSupplyNumberLabel.font = MainFont.bold.with(size: 17)
        circulatingSupplyNumberLabel.tintColor = UIColor.primaryBlue
        circulatingSupplyNumberLabel.textAlignment = .center
        circulatingSupplyView.addSubview(circulatingSupplyNumberLabel)
        circulatingSupplyNumberLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalToSuperview().offset(5)
        }
        let circulatingSupplyLabel = UILabel()
        circulatingSupplyLabel.font = MainFont.light.with(size: 12)
        circulatingSupplyLabel.text = "流通量"
        circulatingSupplyLabel.textAlignment = .center
        circulatingSupplyView.addSubview(circulatingSupplyLabel)
        
        circulatingSupplyLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(5)
            maker.trailing.equalToSuperview().offset(-5)
            maker.top.equalTo(circulatingSupplyNumberLabel.snp.bottom).offset(5)
            maker.bottom.equalToSuperview().offset(5)
        }
        
        stackView.addArrangedSubview(totalSupplyView)
        stackView.addArrangedSubview(totalTransfersView)
        stackView.addArrangedSubview(totalHoldersView)
        stackView.addArrangedSubview(circulatingSupplyView)
        
        self.contentView.addSubview(stackView)
        
        stackView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalToSuperview().offset(28)
            maker.bottom.equalToSuperview().offset(-28)
        }
        
        return stackView
    }()
    
    func fill(_ token: APIToken?) {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 4
        numberFormatter.alwaysShowsDecimalSeparator = true
        if let totalSupply = token?.totalSupply {
            var val = Double(totalSupply)
            if let decimals = token?.decimals {
                val = val / pow(10, Double(decimals))
            }
            self.totalSupplyNumberLabel.text = val.formate(formatter: numberFormatter)
        } else {
            self.totalSupplyNumberLabel.text = "0"
        }
        if let circulatingSupply = token?.circulatingSupply {
            var val = Double(circulatingSupply)
            if let decimals = token?.decimals {
                val = val / pow(10, Double(decimals))
            }
            self.circulatingSupplyNumberLabel.text = val.formate(formatter: numberFormatter)
        } else {
            self.circulatingSupplyNumberLabel.text = "0"
        }
        self.totalTransfersNumberLabel.text = "\(token?.totalTransfers ?? 0)"
        self.totalHoldersNumberLabel.text = "\(token?.totalHolders ?? 0)"
        self.stackView.needsUpdateConstraints()
    }

}
