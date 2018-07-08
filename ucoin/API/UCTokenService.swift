//
//  UCTokenService.swift
//  ucoin
//
//  Created by Syd on 2018/6/12.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya

enum UCTokenService {
    case create(token: APIToken)
    case update(token: APIToken)
    case info(tokenAddress: String)
    case ownedList()
}

// MARK: - TargetType Protocol Implementation
extension UCTokenService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/token")! }
    var path: String {
        switch self {
        case .create(_):
            return "/create"
        case .update(_):
            return "/update"
        case let .info(tokenAddress):
            return "/info/" + tokenAddress
        case .ownedList():
            return "/owned/list"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .create, .update:
            return .post
        case .info, .ownedList:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .create(token):
            if let logoImage = token.logoImage {
                if let imageData = logoImage.data() {
                    let logoData = MultipartFormData(provider: .data(imageData), name: "logo", fileName: "tokenlogo."+logoImage.fileExtension(), mimeType: logoImage.mime())
                    
                    var multipartData = [logoData]
                    if let name = token.name {
                        let nameData = MultipartFormData(provider: .data(name.data(using: .utf8)!), name: "name")
                        multipartData.append(nameData)
                    }
                    if let symbol = token.symbol {
                        let symbolData = MultipartFormData(provider: .data(symbol.data(using: .utf8)!), name: "symbol")
                        multipartData.append(symbolData)
                    }
                    
                    if let totalSupply = token.totalSupply {
                        let totalSupplyData = MultipartFormData(provider: .data(String(totalSupply).data(using: .utf8)!), name: "total_supply")
                        multipartData.append(totalSupplyData)
                    }
                    
                    if let decimals = token.decimals {
                        let decimalsData = MultipartFormData(provider: .data(String(decimals).data(using: .utf8)!), name: "decimals")
                        multipartData.append(decimalsData)
                    }
                    
                    return .uploadMultipart(multipartData)
                }
            }
            
            return .requestParameters(parameters: ["name": token.name!, "symbol": token.symbol!, "total_supply": token.totalSupply!, "decimals": token.decimals!], encoding: JSONEncoding.default)
        case let .update(token):
            var multipartData: [MultipartFormData] = []
            if let logoImage = token.logoImage {
                if let imageData = logoImage.data() {
                    let logoData = MultipartFormData(provider: .data(imageData), name: "logo", fileName: "tokenlogo."+logoImage.fileExtension(), mimeType: logoImage.mime())
                    
                    multipartData.append(logoData)
                }
            }
            if let coverImage = token.coverImage {
                if let imageData = coverImage.data() {
                    let coverData = MultipartFormData(provider: .data(imageData), name: "cover", fileName: "tokenCover."+coverImage.fileExtension(), mimeType: coverImage.mime())
                    
                    multipartData.append(coverData)
                }
            }
            if let description = token.desc {
                let descData = MultipartFormData(provider: .data(description.data(using: .utf8)!), name: "description")
                multipartData.append(descData)
            }
            
            if let address = token.address {
                let addressData = MultipartFormData(provider: .data(address.data(using: .utf8)!), name: "address")
                multipartData.append(addressData)
            }
            
            return .uploadMultipart(multipartData)
        case .info(_):
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case .ownedList():
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .create(_):
            return "{}".utf8Encoded
        case .update(_):
            return "{}".utf8Encoded
        case .info(_):
            return "{}".utf8Encoded
        case .ownedList():
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension UCTokenService {
    static func createToken(
        _ tokenInfo: APIToken,
        provider: MoyaProvider<UCTokenService>,
        success: ((_ token: APIToken) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)?) {
        provider.request(
            .create(token: tokenInfo)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let token = try response.mapObject(APIToken.self)
                    if let errorCode = token.code {
                        failed?(UCAPIError.error(code: errorCode, msg: token.message ?? "未知错误"))
                    } else {
                        success?(token)
                    }
                } catch {
                    failed?(UCAPIError.error(code: response.statusCode, msg: response.description))
                }
            case let .failure(error):
                failed?(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
            }
            complete?()
        }
    }
    
    static func getOwnedTokens(
        provider: MoyaProvider<UCTokenService>,
        success: ((_ tokens: [APIToken]) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)?) {
        provider.request(
            .ownedList()
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let tokens: [APIToken] = try response.mapArray(APIToken.self)
                    success?(tokens)
                } catch {
                    do {
                        let err = try response.mapObject(APIResponse.self)
                        if let errorCode = err.code {
                            failed?(UCAPIError.error(code: errorCode, msg: err.message ?? "未知错误"))
                        } else {
                            failed?(UCAPIError.error(code: 0, msg: "未知错误"))
                        }
                    } catch {
                        if response.statusCode == 200 {
                            success?([])
                        } else {
                            failed?(UCAPIError.error(code: response.statusCode, msg: response.description))
                        }
                    }
                }
            case let .failure(error):
                failed?(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
            }
            complete?()
        }
    }
    
    static func updateToken(
        _ tokenInfo: APIToken,
        provider: MoyaProvider<UCTokenService>,
        success: ((_ token: APIToken) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)?) {
        provider.request(
            .update(token: tokenInfo)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let token = try response.mapObject(APIToken.self)
                    if let errorCode = token.code {
                        failed?(UCAPIError.error(code: errorCode, msg: token.message ?? "未知错误"))
                    } else {
                        success?(token)
                    }
                } catch {
                    failed?(UCAPIError.error(code: response.statusCode, msg: response.description))
                }
            case let .failure(error):
                failed?(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
            }
            complete?()
        }
    }
    
    static func getInfo(
        _ tokenAddress: String,
        provider: MoyaProvider<UCTokenService>,
        success: @escaping (_ token: APIToken) -> Void,
        failed: @escaping (_ error: UCAPIError) -> Void,
        complete: @escaping () -> Void) {
        provider.request(
            .info(tokenAddress: tokenAddress)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let token: APIToken = try response.mapObject(APIToken.self)
                    if let errorCode = token.code {
                        failed(UCAPIError.error(code: errorCode, msg: token.message ?? "未知错误"))
                    } else {
                        success(token)
                    }
                    
                } catch {
                    failed(UCAPIError.error(code: response.statusCode, msg: response.description))
                }
            case let .failure(error):
                failed(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
            }
            complete()
        }
    }
}
