//
//  ScanViewDelegate.swift
//  ucoin
//
//  Created by Syd on 2018/7/19.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation

protocol ScanViewDelegate: NSObjectProtocol {
    func collectHandler(_ qrcode: APIQRCollect)
}
