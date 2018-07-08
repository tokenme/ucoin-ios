//
//  OrderQrcodeTableCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/6.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import swiftScan

fileprivate let DefaultQrcodeWidth = 600.0

final class OrderQrcodeTableCell: UITableViewCell, Reusable {
    
    private let txLabel = UILabel()
    private let qrcodeView = UIImageView()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        txLabel.font = MainFont.medium.with(size: 12)
        txLabel.adjustsFontSizeToFitWidth = true
        txLabel.numberOfLines = 1
        txLabel.minimumScaleFactor = 8.0 / txLabel.font.pointSize
        containerView.addSubview(txLabel)
        txLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(28)
        }
        
        qrcodeView.contentMode = .scaleAspectFit
        containerView.addSubview(qrcodeView)
        qrcodeView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(txLabel.snp.bottom).offset(8)
            maker.height.equalTo(qrcodeView.snp.width)
            maker.bottom.equalToSuperview().offset(-28)
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
        
        txLabel.text = order.tx
        
        guard let qrcode = order.qrcode?.toJSONString() else {
            return
        }
        
        let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator",codeString:qrcode, size:
            CGSize(width: DefaultQrcodeWidth, height: DefaultQrcodeWidth), qrColor: UIColor.black, bkColor: UIColor.white)
        
        qrcodeView.image = qrImg
    }
}
