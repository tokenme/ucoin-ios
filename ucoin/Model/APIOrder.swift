//
//  APIOrder.swift
//  ucoin
//
//  Created by Syd on 2018/7/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation
import ObjectMapper

public class APIOrder: APIResponse {
    var tokenId: UInt64?
    var buyer: APIUser?
    var seller: APIUser?
    var product: APITokenProduct?
    var price: UInt64?
    var tx: String?
    var tokenTxStatus: UInt?
    var productTxStatus: UInt?
    var insertedTime: Date?
    var updatedTime: Date?
    var qrcode: String?
    
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
        buyer <- map["buyer"]
        seller <- map["seller"]
        product <- map["product"]
        price <- map["price"]
        insertedTime <- (map["inserted_at"], dateTimeTransform)
        updatedTime <- (map["updated_at"], dateTimeTransform)
        tx <- map["tx"]
        tokenTxStatus <- map["token_tx_status"]
        productTxStatus <- map["product_tx_status"]
        qrcode <- map["qrcode"]
    }
    
    public func isOwnedByUser(wallet: String?) -> Bool {
        guard let buyer = self.buyer else {
            return false
        }
        if wallet == nil {
            return false
        }
        return buyer.wallet == wallet
    }
    
    public func isSelledByUser(wallet: String?) -> Bool {
        guard let seller = self.seller else {
            return false
        }
        if wallet == nil {
            return false
        }
        return seller.wallet == wallet
    }
}
