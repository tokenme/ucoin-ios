//
//  APIQROrder.swift
//  ucoin
//
//  Created by Syd on 2018/7/12.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIQROrder: APIQrcode {
    var tokenId: UInt64?
    var product: String?
    
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
        tokenId <- map["token_id"]
        product <- map["product"]
    }
}
