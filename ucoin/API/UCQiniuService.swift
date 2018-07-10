//
//  UCQiniuService.swift
//  ucoin
//
//  Created by Syd on 2018/6/25.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya

enum UCQiniuService {
    case tokenProduct(token: String, amount: Int)
    case tokenTask(token: String, amount: Int)
    case tokenTaskEvidence(taskId: UInt64, amount: Int)
    case tokenLogo(token: String)
}

// MARK: - TargetType Protocol Implementation
extension UCQiniuService: TargetType, AccessTokenAuthorizable {
    
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/qiniu")! }
    var path: String {
        switch self {
        case .tokenProduct(_, _):
            return "/token/product"
        case .tokenTask(_, _):
            return "/token/task"
        case .tokenTaskEvidence(_, _):
            return "/token/task/evidence"
        case .tokenLogo(_):
            return "/token/logo"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .tokenProduct, .tokenTask, .tokenLogo, .tokenTaskEvidence:
            return .post
        }
    }
    var task: Task {
        switch self {
        case let .tokenProduct(token, amount):
            return .requestParameters(parameters: ["token": token, "amount": amount], encoding: JSONEncoding.default)
        case let .tokenTask(token, amount):
            return .requestParameters(parameters: ["token": token, "amount": amount], encoding: JSONEncoding.default)
        case let .tokenTaskEvidence(taskId, amount):
            return .requestParameters(parameters: ["task_id": taskId, "amount": amount], encoding: JSONEncoding.default)
        case let .tokenLogo(token):
            return .requestParameters(parameters: ["token": token], encoding: JSONEncoding.default)
        }
    }
    
    var sampleData: Data {
        switch self {
        case .tokenProduct(_, _):
            return "[]".utf8Encoded
        case .tokenTask(_, _):
            return "[]".utf8Encoded
        case .tokenTaskEvidence(_, _):
            return "[]".utf8Encoded
        case .tokenLogo(_):
            return "{}".utf8Encoded
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension UCQiniuService {
    static func getTokenProduct(
        _ token: String,
        _ amount: Int,
        provider: MoyaProvider<UCQiniuService>,
        success: ((_ upTokens: [APIQiniu]) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)?) {
        provider.request(
            .tokenProduct(token: token, amount: amount)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let upTokens = try response.mapArray(APIQiniu.self)
                    success?(upTokens)
                } catch {
                    do {
                        let err = try response.mapObject(APIResponse.self)
                        if let errorCode = err.code {
                            failed?(UCAPIError.error(code: errorCode, msg: err.message ?? "未知错误"))
                        } else {
                            failed?(UCAPIError.error(code: 0, msg: "未知错误"))
                        }
                    } catch {
                        failed?(UCAPIError.error(code: response.statusCode, msg: response.description))
                    }
                }
            case let .failure(error):
                failed?(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
            }
            complete?()
        }
    }
    
    static func getTokenTask(
        _ token: String,
        _ amount: Int,
        provider: MoyaProvider<UCQiniuService>,
        success: ((_ upTokens: [APIQiniu]) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)?) {
        provider.request(
            .tokenTask(token: token, amount: amount)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let upTokens = try response.mapArray(APIQiniu.self)
                    success?(upTokens)
                } catch {
                    do {
                        let err = try response.mapObject(APIResponse.self)
                        if let errorCode = err.code {
                            failed?(UCAPIError.error(code: errorCode, msg: err.message ?? "未知错误"))
                        } else {
                            failed?(UCAPIError.error(code: 0, msg: "未知错误"))
                        }
                    } catch {
                        failed?(UCAPIError.error(code: response.statusCode, msg: response.description))
                    }
                }
            case let .failure(error):
                failed?(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
            }
            complete?()
        }
    }
    
    static func getTokenTaskEvidence(
        _ taskId: UInt64,
        _ amount: Int,
        provider: MoyaProvider<UCQiniuService>,
        success: ((_ upTokens: [APIQiniu]) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)?) {
        provider.request(
            .tokenTaskEvidence(taskId: taskId, amount: amount)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let upTokens = try response.mapArray(APIQiniu.self)
                    success?(upTokens)
                } catch {
                    do {
                        let err = try response.mapObject(APIResponse.self)
                        if let errorCode = err.code {
                            failed?(UCAPIError.error(code: errorCode, msg: err.message ?? "未知错误"))
                        } else {
                            failed?(UCAPIError.error(code: 0, msg: "未知错误"))
                        }
                    } catch {
                        failed?(UCAPIError.error(code: response.statusCode, msg: response.description))
                    }
                }
            case let .failure(error):
                failed?(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
            }
            complete?()
        }
    }
    
    static func getTokenLogo(
        _ token: String?,
        provider: MoyaProvider<UCQiniuService>,
        success: ((_ upToken: APIQiniu) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)?) {
        provider.request(
            .tokenLogo(token: token ?? "")
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let upToken = try response.mapObject(APIQiniu.self)
                    if let errorCode = upToken.code {
                        failed?(UCAPIError.error(code: errorCode, msg: upToken.message ?? "未知错误"))
                    } else {
                        success?(upToken)
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
}
