//
//  TokenTaskInfoTableCell.swift
//  ucoin
//
//  Created by Syd on 2018/7/2.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import FSPagerView
import Reusable
import SnapKit
import SwiftyMarkdown

fileprivate let DefaultImageHeight = 80.0

final class TokenTaskInfoTableCell: UITableViewCell, Reusable {
    
    weak public var textViewDelegate: UITextViewDelegate?
    private var images: [String]?
    private var textView  = UITextView()
    private let imageGridView = FTImageGridView(frame: CGRect.zero)
    
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
        
        if let description = task?.desc {
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
        
        self.images = task.images
        
        if task.images?.count ?? 0 > 0 {
            let gridWidth = UIScreen.main.bounds.width - 32
            let gridHeight = FTImageGridView.getHeightWithWidth(gridWidth, imgCount: task.images!.count)
            imageGridView.frame = CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight)
            
            imageGridView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(8)
                maker.trailing.equalToSuperview().offset(-8)
                maker.top.equalTo(textView.snp.bottom).offset(16)
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
                maker.top.equalTo(textView.snp.bottom).offset(16)
                maker.height.equalTo(0)
                maker.bottom.equalToSuperview().offset(-8)
            }
        }
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
    }
}

extension TokenTaskInfoTableCell: FSPagerViewDataSource {
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
