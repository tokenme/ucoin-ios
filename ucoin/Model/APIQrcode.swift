//
//  APIQrcode.swift
//  ucoin
//
//  Created by Syd on 2018/7/6.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIQrcode: APIResponse {
    var method: String?
    var data: String?
    
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
        method <- map["method"]
        data <- map["data"]
    }
}
