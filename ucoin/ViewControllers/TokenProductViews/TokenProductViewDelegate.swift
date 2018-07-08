//
//  TokenProductViewDelegate.swift
//  ucoin
//
//  Created by Syd on 2018/7/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation

protocol TokenProductViewDelegate: NSObjectProtocol {
    func gotoToken(_ tokenAddress: String?)
    func buy(_ product: APITokenProduct?)
    func segmentChanged(_ index: Int)
}
