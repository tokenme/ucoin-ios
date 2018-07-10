//
//  APITokenTaskEvidence.swift
//  ucoin
//
//  Created by Syd on 2018/7/9.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APITokenTaskEvidence: APIResponse {
    var id: UInt64?
    var user: APIUser?
    var task: APITokenTask?
    var bonus: UInt64?
    var desc: String?
    var images: [String]?
    var UIImages: [UIImage]?
    var tx: String?
    var txStatus: UInt8?
    var approveStatus: Int8?
    var createTime: Date?
    var updateTime: Date?
    
    // MARK: JSON
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    convenience init?() {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
    }
    
    convenience init?(form: [String: Any?], task: APITokenTask, images: [UIImage]?) {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
        
        guard let token = task.token else {
            return
        }
        
        self.task = task
        
        switch form["desc"] {
        case let value as String:
            self.desc = value
        case .none: break
        case .some(_):break
        }
        
        switch form["bonus"] {
        case let value as Float:
            self.bonus = UInt64(Double(value) * pow(10, Double(token.decimals ?? 0)))
        case let value as Double:
            self.bonus = UInt64(Double(value) * pow(10, Double(token.decimals ?? 0)))
        case .none: break
        case .some(_):break
        }
        if let imgs = images {
            self.UIImages = []
            for img in imgs {
                self.UIImages?.append(img)
            }
        }
    }
    
    // Mappable
    override public func mapping(map: Map) {
        super.mapping(map: map)
        id <- map["id"]
        user <- map["user"]
        task <- map["task"]
        bonus <- map["bonus"]
        desc <- map["desc"]
        images <- map["images"]
        tx <- map["tx"]
        txStatus <- map["tx_status"]
        approveStatus <- map["approve_status"]
        createTime <- (map["create_time"], dateTimeTransform)
        updateTime <- (map["update_time"], dateTimeTransform)
    }
    
    public func isOwnedByUser(wallet: String?) -> Bool {
        guard let user = self.user else {
            return false
        }
        if wallet == nil {
            return false
        }
        return user.wallet == wallet
    }
}
