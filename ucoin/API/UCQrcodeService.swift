//
//  UCQrcodeService.swift
//  ucoin
//
//  Created by Syd on 2018/7/11.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya
import Hydra

enum UCQrcodeService {
    case collect(token: String?, amount: UInt64?)
    case parse(uri: String)
}

// MARK: - TargetType Protocol Implementation
extension UCQrcodeService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/qrcode")! }
    var path: String {
        switch self {
        case .collect(_, _):
            return "/collect"
        case .parse(_):
            return "/parse"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .collect, .parse:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .collect(token, amount):
            var params: [String:Any] = [:]
            if token != nil {
                params["token"] = token
            }
            if amount != nil {
                params["amount"] = amount
            }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case let .parse(uri):
            return .requestParameters(parameters: ["uri": uri], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .collect(_, _):
            return "{}".utf8Encoded
        case .parse(_):
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension UCQrcodeService {
    static func getCollectCode(
        _ token: String?,
        amount: UInt64?,
        provider: MoyaProvider<UCQrcodeService>) -> Promise<String> {
        return Promise<String>(in: .background, {resolve, reject, _ in
            provider.request(
                .collect(token: token, amount: amount)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIResponse.self)
                        if let errorCode = resp.code {
                            reject(UCAPIError.error(code: errorCode, msg: resp.message ?? "未知错误"))
                        } else if let message = resp.message {
                            resolve(message)
                        } else {
                            reject(UCAPIError.error(code: 0, msg: "未知错误"))
                        }
                    } catch {
                        reject(UCAPIError.error(code: response.statusCode, msg: response.description))
                    }
                case let .failure(error):
                    reject(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
                }
            }
        })
    }
    
    static func parseCode(
        _ uri: String,
        provider: MoyaProvider<UCQrcodeService>) -> Promise<APIQrcodeType> {
        return Promise<APIQrcodeType>(in: .background, {resolve, reject, _ in
            provider.request(
                .parse(uri: uri)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let qrcode = try response.mapObject(APIQrcode.self)
                        if let errorCode = qrcode.code {
                            reject(UCAPIError.error(code: errorCode, msg: qrcode.message ?? "未知错误"))
                        }
                        if let method = qrcode.method {
                            if let methodType = UCQrcodeMethod(rawValue: method) {
                                switch methodType {
                                case .collect:
                                    let resp = try response.mapObject(APIQRCollect.self)
                                    resolve(resp)
                                case .orderInfo:
                                    let resp = try response.mapObject(APIQROrder.self)
                                    resolve(resp)
                                }
                            }
                        } else {
                            reject(UCAPIError.error(code: 0, msg: "Unknown message"))
                        }
                    } catch {
                        reject(UCAPIError.error(code: response.statusCode, msg: response.description))
                    }
                case let .failure(error):
                    reject(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
                }
            }
        })
    }
}
