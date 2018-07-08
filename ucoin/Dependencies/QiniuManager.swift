//
//  QiniuManager.swift
//  ucoin
//
//  Created by Syd on 2018/6/25.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import Qiniu

class QiniuManager: NSObject {
    
    static let sharedInstance = QiniuManager()
    
    public let uploader: QNUploadManager = QNUploadManager()
    
}
