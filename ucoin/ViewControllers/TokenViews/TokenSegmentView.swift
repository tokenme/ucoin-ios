//
//  TokenSegmentView.swift
//  ucoin
//
//  Created by Syd on 2018/6/20.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable
import TTSegmentedControl

final class TokenSegmentView: UIView, Reusable {
    weak public var delegate: TokenViewDelegate?
    
    static let height: CGFloat = 60
    
    private var segmentControl = TTSegmentedControl()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.segmentControl.allowChangeThumbWidth = false
        self.segmentControl.hasBounceAnimation = true
        self.segmentControl.itemTitles = ["代币介绍", "代币权益", "获取代币"]
        self.segmentControl.hasBounceAnimation = true
        self.segmentControl.containerBackgroundColor = UIColor.clear
        self.segmentControl.defaultTextColor = UIColor.darkText
        self.segmentControl.selectedTextColor = UIColor.white
        self.segmentControl.thumbGradientColors = nil
        self.segmentControl.thumbColor = UIColor.darkText
        self.segmentControl.padding = CGSize(width: 5, height: 10)
        self.segmentControl.didSelectItemWith = { (index, title) -> () in
            if let delegate = self.delegate {
                delegate.segmentChanged(index)
            }
        }
        self.addSubview(self.segmentControl)
        self.segmentControl.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(28)
            maker.trailing.equalToSuperview().offset(-28)
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        self.backgroundColor = UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func selectItemAt(_ index: Int) {
        segmentControl.selectItemAt(index: index, animated: true)
    }
}
