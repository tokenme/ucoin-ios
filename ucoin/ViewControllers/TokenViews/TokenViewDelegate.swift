//
//  TokenViewDelegate.swift
//  ucoin
//
//  Created by Syd on 2018/6/19.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation

protocol TokenViewDelegate: NSObjectProtocol {
    func showEditDescription()
    func shouldReload()
    func descriptionSelected()
    func updatedTokenDescription(_ desc: String)
    func segmentChanged(_ index: Int)
    func showCreateTokenProduct()
    func showCreateTokenTask()
    func updatedImageColors(_ colors: UIImageColors?)
}
