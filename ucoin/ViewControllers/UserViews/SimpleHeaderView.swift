//
//  OwnedTokensHeaderView.swift
//  ucoin
//
//  Created by Syd on 2018/6/14.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Reusable

final class SimpleHeaderView: UIView, NibOwnerLoadable {
    
    static let height: CGFloat = 50
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func fill(_ text: String) {
        titleLabel.text = text
    }
}
