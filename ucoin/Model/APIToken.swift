//
//  APIToken.swift
//  ucoin
//
//  Created by Syd on 2018/6/12.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIToken: APIResponse {
    var address: String?
    var name: String?
    var symbol: String?
    var owner: String?
    var decimals: UInt?
    var initialSupply: UInt64?
    var totalSupply: UInt64?
    var circulatingSupply: UInt64?
    var totalHolders: UInt64?
    var totalTransfers: UInt64?
    var txStatus: UInt?
    var balance: UInt64?
    var desc: String?
    var logo: String?
    var cover: String?
    var logoImage: UIImage?
    var coverImage: UIImage?
    
    // MARK: JSON
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    convenience init?() {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
    }
    
    convenience init?(name: String, symbol: String, totalSupply: UInt64, decimals: UInt) {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
        self.name = name
        self.symbol = symbol
        self.totalSupply = totalSupply
        self.decimals = decimals
    }
    
    convenience init?(form: [String: Any?]) {
        self.init(map: Map.init(mappingType: MappingType.fromJSON, JSON: [:]))
        switch form["name"] {
        case let value as String:
            self.name = value
        case .none: break
        case .some(_):break
        }
        
        switch form["symbol"] {
        case let value as String:
            self.symbol = value
        case .none: break
        case .some(_):break
        }
        
        switch form["totalSupply"] {
        case let value as Int:
            self.totalSupply = UInt64(value)
        case let value as UInt:
            self.totalSupply = UInt64(value)
        case let value as UInt64:
            self.totalSupply = value
        case let value as Int64:
            self.totalSupply = UInt64(value)
        case let value as String:
            self.totalSupply = UInt64(value)
        case let value as Int32:
            self.totalSupply = UInt64(value)
        case let value as UInt32:
            self.totalSupply = UInt64(value)
        case let value as UInt16:
            self.totalSupply = UInt64(value)
        case let value as Int16:
            self.totalSupply = UInt64(value)
        case let value as String:
            self.totalSupply = UInt64(value)
        case .none: break
        case .some(_):break
        }
        
        switch form["decimals"] {
        case let value as Int:
            self.decimals = UInt(value)
        case let value as UInt:
            self.decimals = value
        case let value as UInt64:
            self.decimals = UInt(value)
        case let value as Int64:
            self.decimals = UInt(value)
        case let value as String:
            self.decimals = UInt(value)
        case let value as Int32:
            self.decimals = UInt(value)
        case let value as UInt32:
            self.decimals = UInt(value)
        case let value as UInt16:
            self.decimals = UInt(value)
        case let value as Int16:
            self.decimals = UInt(value)
        case let value as String:
            self.decimals = UInt(value)
        case .none: break
        case .some(_):break
        }
        
        switch form["logo"] {
        case let image as UIImage:
            self.logoImage = image
        case .none: break
        case .some(_):break
        }
    }
    
    // Mappable
    override public func mapping(map: Map) {
        super.mapping(map: map)
        address <- map["address"]
        name <- map["name"]
        symbol <- map["symbol"]
        owner <- map["owner"]
        decimals <- map["decimals"]
        initialSupply <- map["initial_supply"]
        totalSupply <- map["total_supply"]
        circulatingSupply <- map["circulating_supply"]
        totalHolders <- map["total_holders"]
        totalTransfers <- map["total_transfers"]
        txStatus <- map["tx_status"]
        balance <- map["balance"]
        desc <- map["desc"]
        logo <- map["logo"]
        cover <- map["cover"]
    }
    
    public func isOwnedByUser(wallet: String?) -> Bool {
        if self.owner == nil || wallet == nil {
            return false
        }
        return self.owner == wallet
    }
}
