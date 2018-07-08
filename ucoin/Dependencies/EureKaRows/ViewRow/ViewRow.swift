//
//  ViewRow.swift
//  ucoin
//
//  Created by Syd on 2018/6/22.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import Eureka
import SnapKit

public enum ViewRowHeight {
    case fixed(cellHeight: CGFloat)
    case dynamic(initialHeight: CGFloat)
}

public class ViewCell<ViewType : UIView> : Cell<String>, CellType {
    
    public var view : ViewType?
    
    public var rowHeight = ViewRowHeight.dynamic(initialHeight: 110)
    
    required public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.white
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func setup() {
        super.setup()
        
        switch rowHeight {
        case .dynamic(_):
            height = { UITableViewAutomaticDimension }
        case .fixed(let cellHeight):
            height = { cellHeight }
        }
        
        selectionStyle = .none
        
        setNeedsUpdateConstraints()
    }
    
    open override func didSelect() {
    }
    
    open override func update() {
        super.update()
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
    }
    
}

// MARK: ViewRow

open class _ViewRow<ViewType : UIView>: Row<ViewCell<ViewType> > {
    
    override open func updateCell() {
        //  NOTE: super.updateCell() deliberatly not called.
        
        //  Deal with the case where the caller did not add their custom view to the containerView in a
        //  backwards compatible manner.
        if let view = cell.view,
            view.superview != cell.contentView {
            view.removeFromSuperview()
            cell.contentView.addSubview(view)
            view.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview()
                maker.trailing.equalToSuperview()
                maker.top.equalToSuperview()
                maker.bottom.equalToSuperview()
            }
        }
    }
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
    }
}

public final class ViewRow<ViewType : UIView>: _ViewRow<ViewType>, RowType {
    
    public var view: ViewType? { // provide a convience accessor for the view
        return cell.view
    }
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
    
}
