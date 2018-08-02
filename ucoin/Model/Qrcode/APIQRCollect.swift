//
//  APIQRCollect.swift
//  ucoin
//
//  Created by Syd on 2018/7/12.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIQRCollect: APIQrcode {
    var wallet: String?
    var token: APIToken?
    var amount: UInt64?
    
    // MARK: JSON
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    convenience init?() {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
    }
    
    // Mappable
    override public func mapping(map: Map) {
        super.mapping(map: map)
        wallet <- map["wallet"]
        token <- map["token"]
        amount <- map["amount"]
    }
}
