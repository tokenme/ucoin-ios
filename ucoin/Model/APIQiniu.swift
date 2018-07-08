//
//  APIQiniu.swift
//  ucoin
//
//  Created by Syd on 2018/6/25.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIQiniu: APIResponse {
    var upToken: String?
    var key: String?
    var index: Int?
    var link: String?
    var uploaded: Bool = false
    
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
        upToken <- map["uptoken"]
        key <- map["key"]
        index <- map["index"]
        link <- map["link"]
    }
}
