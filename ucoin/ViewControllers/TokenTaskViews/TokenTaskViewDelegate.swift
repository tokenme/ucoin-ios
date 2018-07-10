//
//  TokenTaskViewDelegate.swift
//  ucoin
//
//  Created by Syd on 2018/7/9.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation

protocol TokenTaskViewDelegate: NSObjectProtocol {
    func gotoToken(_ tokenAddress: String?)
    func showSubmitEvidence()
    func gotoTokenTaskEvidences()
}
