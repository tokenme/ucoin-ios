//
//  OwnedTokenCell.swift
//  ucoin
//
//  Created by Syd on 2018/6/14.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import moa
import Toucan

fileprivate let DefaultLogoWidth = 40.0
final class OwnedTokenCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var symbolLabel: UILabel!
    @IBOutlet private weak var totalTansfersLabel: UILabel!
    @IBOutlet private weak var totalHoldersLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    
    private let logoDownloader = Moa()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.logoImageView.layer.borderWidth = 0
        self.logoImageView.layer.cornerRadius = CGFloat(DefaultLogoWidth / 2.0)
        self.logoImageView.contentMode = .scaleAspectFill
        self.logoImageView.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func fill(_ token: APIToken) {
        nameLabel.text = token.name
        symbolLabel.text = token.symbol
        totalTansfersLabel.text = "交易量: \(token.totalTransfers ?? 0)"
        totalHoldersLabel.text = "持有人: \((token.totalHolders ?? 0) + 1)"
        var balance: Double = 0
        if let decimals = token.decimals {
            if decimals > 0 {
                balance = Double(token.balance ?? 0) / pow(10, Double(decimals))
            }
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 4
        numberFormatter.alwaysShowsDecimalSeparator = true
        balanceLabel.text = balance.formate(formatter: numberFormatter)
        
        if let image = token.logoImage {
            logoImageView.image = Toucan(image: image).resize(CGSize(width: DefaultLogoWidth, height: DefaultLogoWidth), fitMode: Toucan.Resize.FitMode.scale).image
        } else if let imageURL = token.logo {
            if imageURL != "" {
                logoDownloader.onSuccess = {[weak self] image in
                    guard let weakSelf = self else {
                        return image
                    }
                    let outputImage = Toucan(image: image).resize(CGSize(width: DefaultLogoWidth, height: DefaultLogoWidth), fitMode: Toucan.Resize.FitMode.scale).maskWithEllipse(borderWidth: 0, borderColor: UIColor.clear).image
                    
                    weakSelf.logoImageView.image = outputImage
                    token.logoImage = outputImage
                    return outputImage
                }
                logoDownloader.url = imageURL
            }
        }
    }
}
