//
//  UserActionsTableCell.swift
//  ucoin
//
//  Created by Syd on 2018/6/11.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

fileprivate let DefaultActionButtonWidth = 15

final class UserActionsTableCell: UITableViewCell, Reusable {
    weak public var delegate: UserActionsTableCellDelegate?
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        
        let createTokenButton = setupGeneralButton(imageName: "Gear", title: "造币")
        createTokenButton.addTarget(self, action: #selector(showCreateToken), for: .touchUpInside)
        
        let scanButton = setupGeneralButton(imageName: "Scan", title: "扫码")
        scanButton.addTarget(self, action: #selector(showScan), for: .touchUpInside)
        
        let collectButton = setupGeneralButton(imageName: "Collect", title: "收币码")
        collectButton.addTarget(self, action: #selector(showCollect), for: .touchUpInside)
        
        let walletButton = setupGeneralButton(imageName: "Wallet", title: "资产")
        walletButton.addTarget(self, action: #selector(showScan), for: .touchUpInside)
        
        stackView.addArrangedSubview(createTokenButton)
        stackView.addArrangedSubview(scanButton)
        stackView.addArrangedSubview(collectButton)
        stackView.addArrangedSubview(walletButton)
        
        self.contentView.addSubview(stackView)
        
        stackView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalToSuperview().offset(28)
            maker.bottom.equalToSuperview().offset(-28)
        }
        
        return stackView
    }()
    
    func fill() {
        self.stackView.needsUpdateConstraints()
    }
    
    fileprivate func setupGeneralButton(imageName: String, title: String) -> UIButton {
        let img = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: DefaultActionButtonWidth, height: DefaultActionButtonWidth))
        button.clipsToBounds = true
        button.contentMode = .scaleAspectFit
        button.setImage(img, for: .normal)
        button.tintColor = UIColor.primaryBlue
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.darkText, for: .normal)
        button.setTitleColor(UIColor.darkSubText, for: .highlighted)
        button.titleLabel?.font = MainFont.light.with(size: 10)
        button.alignVertical()
        return button
    }
}

// Actions Section
extension UserActionsTableCell {
    
    @objc private func showCreateToken() {
        self.delegate?.showCreateToken()
    }
    
    @objc private func showScan() {
        self.delegate?.showScan()
    }
    
    @objc private func showCollect() {
        self.delegate?.showCollect()
    }
}

public protocol UserActionsTableCellDelegate: NSObjectProtocol {
    /// Called when the user selects a country from the list.
    func showCreateToken()
    func showScan()
    func showCollect()
}
