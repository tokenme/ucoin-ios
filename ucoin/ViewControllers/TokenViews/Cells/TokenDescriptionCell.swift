//
//  TokenDescriptionCell.swift
//  ucoin
//
//  Created by Syd on 2018/6/19.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit
import SwiftyMarkdown

fileprivate let DefaultTextViewHeight: CGFloat = 160.0
fileprivate let DefaultTextViewMaxHeight: CGFloat  = 200.0

final class TokenDescriptionCell: UITableViewCell, Reusable {
    weak public var delegate: TokenViewDelegate?
    
    fileprivate let textView = UITextView()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        textView.isEditable = false
        textView.isSelectable = false
        
        containerView.addSubview(textView)
        
        textView.snp.remakeConstraints({ (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
        })
        
        textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(descriptionSelected)))
        self.addSubview(containerView)
        
        return containerView
    }()
    
    func fill(_ desc: String) {
        let attributedString = SwiftyMarkdown(string: desc).attributedString()
        self.textView.attributedText = attributedString
        let textHeight = attributedString.heightWithConstrainedWidth(width: UIScreen.main.bounds.width - 56)
        containerView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalToSuperview().offset(10)
            maker.bottom.equalToSuperview().offset(-10)
            maker.height.equalTo(textHeight + 30)
        }
    }
}

extension TokenDescriptionCell {
    @objc private func descriptionSelected() {
        if let delegate = self.delegate {
            delegate.descriptionSelected()
        }
    }
}
