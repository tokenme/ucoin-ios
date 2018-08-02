//
//  UCAPIGateway.swift
//  ucoin
//
//  Created by Syd on 2018/6/15.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

enum UCAPIResponseType: Int {
    case badRequest = 400
    case internalError = 500
    case notFound = 404
    case unauthorized = 401
    case invalidPassword = 409
    case duplicateUser = 202
    case unactivatedUser = 502
    case notEnoughToken = 600
    case notEnoughTokenProduct = 601
    case notEnoughTokenTask = 700
    case duplicateEvidence = 701
    case tokenUnderConstruction = 800
    case productUnderConstruction = 801
}

enum UCAPIError: Error, CustomStringConvertible {
    case badRequest(msg: String)
    case internalError(msg: String)
    case notFound
    case unauthorized
    case invalidPassword
    case duplicateUser
    case unactivatedUser
    case notEnoughToken
    case notEnoughTokenProduct
    case notEnoughTokenTask
    case duplicateEvidence
    case tokenUnderConstruction
    case productUnderConstruction
    case unknown(msg: String)
    case ignore
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .badRequest(let msg): return msg
        case .internalError(let msg): return msg
        case .notFound: return "请求不存在"
        case .unauthorized: return "用户未授权"
        case .invalidPassword: return "密码错误"
        case .duplicateUser: return "用户已经注册"
        case .unactivatedUser: return "用户未激活"
        case .notEnoughToken: return "钱包代币不足"
        case .notEnoughTokenProduct: return "已售罄"
        case .notEnoughTokenTask: return "超过参与人数上限"
        case .duplicateEvidence: return "请勿重复提交证明"
        case .tokenUnderConstruction: return "代币未创建完成，请等待"
        case .productUnderConstruction: return "代币权益未创建完成，请等待"
        case .unknown(let msg): return msg
        case .ignore: return "ignore"
        }
    }
}

extension UCAPIError {
    static func error(code: Int, msg: String) -> UCAPIError {
        if let errorType = UCAPIResponseType(rawValue: code) {
            switch errorType {
            case .badRequest:
                return UCAPIError.badRequest(msg: msg)
            case .internalError:
                return UCAPIError.internalError(msg: msg)
            case .notFound:
                return UCAPIError.notFound
            case .unauthorized:
                return UCAPIError.unauthorized
            case .invalidPassword:
                return UCAPIError.invalidPassword
            case .duplicateUser:
                return UCAPIError.duplicateUser
            case .unactivatedUser:
                return UCAPIError.unactivatedUser
            case .notEnoughToken:
                return UCAPIError.notEnoughToken
            case .notEnoughTokenProduct:
                return UCAPIError.notEnoughTokenProduct
            case .notEnoughTokenTask:
                return UCAPIError.notEnoughTokenTask
            case .duplicateEvidence:
                return UCAPIError.duplicateEvidence
            case .tokenUnderConstruction:
                return UCAPIError.tokenUnderConstruction
            case .productUnderConstruction:
                return UCAPIError.productUnderConstruction
            }
        }
        return UCAPIError.unknown(msg: msg)
    }
}
