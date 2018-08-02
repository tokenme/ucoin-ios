//
//  PaymentDelegate.swift
//  ucoin
//
//  Created by Syd on 2018/7/11.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation

protocol PaymentDelegate: NSObjectProtocol {
    func passwordSet(_ passwd: String?)
    func paymentSuccess()
}
