//
//  TokenTaskEvidencesViewDelegate.swift
//  ucoin
//
//  Created by Syd on 2018/7/10.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation

protocol TokenTaskEvidencesViewDelegate: NSObjectProtocol {
    func segmentChanged(_ index: Int)
    func approveEvidence(_ evidenceId: UInt64, approveStatus: Int8)
}
