//
//  APITokenProduct.swift
//  ucoin
//
//  Created by Syd on 2018/6/22.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APITokenProduct: APIResponse {
    var address: String?
    var title: String?
    var token: APIToken?
    var price: UInt64?
    var amount: UInt?
    var totalSupply: UInt64?
    var startDate: Date?
    var endDate: Date?
    var txStatus: Int?
    var desc: String?
    var tags: [String]?
    var images: [String]?
    var UIImages: [UIImage]?
    var onlineStatus: Int8?
    
    // MARK: JSON
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    convenience init?() {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
    }
    
    convenience init?(form: [String: Any?], token: APIToken, tags:[String]?, images: [UIImage]?) {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
        
        self.token = token
        
        switch form["title"] {
        case let value as String:
            self.title = value
        case .none: break
        case .some(_):break
        }
        
        switch form["startDate"] {
        case let value as Date:
            self.startDate = value
        case .none: break
        case .some(_):break
        }
        
        switch form["endDate"] {
        case let value as Date:
            self.endDate = value
        case .none: break
        case .some(_):break
        }
        
        switch form["desc"] {
        case let value as String:
            self.desc = value
        case .none: break
        case .some(_):break
        }
        
        switch form["price"] {
        case let value as Float:
            self.price = UInt64(Double(value) * pow(10, Double(token.decimals ?? 0)))
        case let value as Double:
            self.price = UInt64(Double(value) * pow(10, Double(token.decimals ?? 0)))
        case .none: break
        case .some(_):break
        }
        
        switch form["amount"] {
        case let value as Int:
            self.amount = UInt(value)
        case let value as UInt:
            self.amount = value
        case let value as UInt64:
            self.amount = UInt(value)
        case let value as Int64:
            self.amount = UInt(value)
        case let value as String:
            self.amount = UInt(value)
        case let value as Int32:
            self.amount = UInt(value)
        case let value as UInt32:
            self.amount = UInt(value)
        case let value as UInt16:
            self.amount = UInt(value)
        case let value as Int16:
            self.amount = UInt(value)
        case let value as String:
            self.amount = UInt(value)
        case .none: break
        case .some(_):break
        }
        
        switch form["onlineStatus"] {
        case let value as Bool:
            self.onlineStatus = value ? 1 : -1
        case .none: break
        case .some(_):break
        }
        
        if let tags = tags {
            self.tags = []
            for tag in tags {
                self.tags?.append(tag)
            }
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
        address <- map["address"]
        title <- map["title"]
        token <- map["token"]
        price <- map["price"]
        totalSupply <- map["total_supply"]
        amount <- map["amount"]
        startDate <- (map["start_date"], dateTimeTransform)
        endDate <- (map["end_date"], dateTimeTransform)
        txStatus <- map["tx_status"]
        desc <- map["desc"]
        tags <- map["tags"]
        images <- map["images"]
        onlineStatus <- map["online_status"]
    }
    
    public func isOwnedByUser(wallet: String?) -> Bool {
        guard let token = self.token else {
            return false
        }
        if token.owner == nil || wallet == nil {
            return false
        }
        return token.owner == wallet
    }
}
