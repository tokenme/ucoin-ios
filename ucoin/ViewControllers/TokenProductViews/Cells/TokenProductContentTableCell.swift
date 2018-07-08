//
//  TokenProductContentTableCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/2.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit
import SwiftyMarkdown
import moa

fileprivate let DefaultImageHeight = 80.0

final class TokenProductContentTableCell: UITableViewCell, Reusable {
    
    weak public var textViewDelegate: UITextViewDelegate?
    private var images: [String]?
    private var textView  = UITextView()
    private let imagesContainer = UIView()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.dataDetectorTypes = .all
        textView.delegate = textViewDelegate
        containerView.addSubview(textView)
        textView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(8)
        }
        
        containerView.addSubview(imagesContainer)
        imagesContainer.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.top.equalTo(textView.snp.bottom).offset(8)
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
    
    public func fill(_ tokenProduct: APITokenProduct?) {
        self.containerView.needsUpdateConstraints()
        guard let product = tokenProduct else {
            return
        }
        if let description = product.desc {
            let attributedString = SwiftyMarkdown(string: description).attributedString()
            let textHeight = attributedString.heightWithConstrainedWidth(width: UIScreen.main.bounds.width - 32)
            textView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(16)
                maker.trailing.equalToSuperview().offset(-16)
                maker.top.equalToSuperview().offset(8)
                maker.height.equalTo(textHeight + 16)
            }
            textView.attributedText = attributedString
        }
        
        for subView in imagesContainer.subviews {
            subView.removeFromSuperview()
        }
        
        self.images = product.images
        let imageCount = product.images?.count ?? 0
        let imagesWrapperHeight = Int(UIScreen.main.bounds.width - 32) * imageCount
        if imageCount > 0 {
            var idx = 0
            for img in product.images! {
                let imageView = UIImageView()
                imageView.tag = idx
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imagesContainer.addSubview(imageView)
                imageView.download(url: img, complete: {[weak self] imageView, image in
                    guard let weakSelf = self else {
                        return
                    }
                    let ratio = image.size.height / image.size.width
                    let tag = imageView.tag
                    if tag == 0 {
                        imageView.snp.remakeConstraints { (maker) -> Void in
                            maker.leading.equalToSuperview()
                            maker.trailing.equalToSuperview()
                            maker.top.equalToSuperview()
                            maker.height.equalTo(weakSelf.imagesContainer.snp.width).multipliedBy(ratio)
                        }
                    } else if tag == imageCount - 1 {
                        let preImageView = weakSelf.imagesContainer.subviews[tag - 1]
                        imageView.snp.makeConstraints { (maker) -> Void in
                            maker.leading.equalTo(preImageView.snp.leading)
                            maker.trailing.equalTo(preImageView.snp.trailing)
                            maker.top.equalTo(preImageView.snp.bottom)
                            maker.height.equalTo(weakSelf.imagesContainer.snp.width).multipliedBy(ratio)
                        }
                    } else {
                        let preImageView = weakSelf.imagesContainer.subviews[tag - 1]
                        imageView.snp.makeConstraints { (maker) -> Void in
                            maker.leading.equalTo(preImageView.snp.leading)
                            maker.trailing.equalTo(preImageView.snp.trailing)
                            maker.top.equalTo(preImageView.snp.bottom)
                            maker.height.equalTo(weakSelf.imagesContainer.snp.width).multipliedBy(ratio)
                        }
                    }
                })
                idx += 1
            }
        }
        imagesContainer.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(8)
            maker.trailing.equalToSuperview().offset(-8)
            maker.top.equalTo(textView.snp.bottom).offset(8)
            maker.bottom.equalToSuperview().offset(-8)
            maker.height.equalTo(imagesWrapperHeight)
        }
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
    }
}
