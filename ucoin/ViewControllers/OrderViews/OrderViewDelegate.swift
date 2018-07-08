//
//  OrderViewDelegate.swift
//  ucoin
//
//  Created by Syd on 2018/7/6.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation

protocol OrderViewDelegate: NSObjectProtocol {
    func gotoToken(_ tokenAddress: String?)
    func gotoProduct(_ productAddress: String?)
}
