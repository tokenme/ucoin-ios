//
//  UCUserService.swift
//  ucoin
//
//  Created by Syd on 2018/6/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults
import Hydra

enum UCUserService {
    case create(country: UInt, mobile: String, verifyCode: String, password: String, repassword: String)
    case update(user: APIUser)
    case info(refresh: Bool)
}

// MARK: - TargetType Protocol Implementation
extension UCUserService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/user")! }
    var path: String {
        switch self {
        case .create(_, _, _, _, _):
            return "/create"
        case .update(_):
            return "/update"
        case .info(_):
            return "/info"
        }
    }
    var method: Moya.Method {
        switch self {
        case .create, .update:
            return .post
        case .info:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .create(country, mobile, verifyCode, password, repassword):
            return .requestParameters(parameters: ["country_code": country, "mobile": mobile, "verify_code": verifyCode, "passwd": password, "repasswd": repassword], encoding: JSONEncoding.default)
        case let .update(user):
            var params: [String:Any] = [:]
            if let nick = user.nick {
                params["nick"] = nick
            }
            if let avatar = user.avatar {
                params["avatar"] = avatar
            }
            if let paymentPasswd = user.paymentPasswd {
                params["payment_passwd"] = paymentPasswd
            }
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case let .info(refresh):
            return .requestParameters(parameters: ["refresh": refresh], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .create(_, _, _, _, _):
            return "ok".utf8Encoded
        case .update(_):
            return "ok".utf8Encoded
        case .info(_):
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension UCUserService {
    
    static func getUserInfo(_ refresh: Bool, provider: MoyaProvider<UCUserService>) -> Promise<APIUser> {
        return Promise<APIUser> (in: .background, { resolve, reject, _ in
            provider.request(
                .info(refresh: refresh)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let userInfo = try response.mapObject(APIUser.self)
                        if let errorCode = userInfo.code {
                            reject(UCAPIError.error(code: errorCode, msg: userInfo.message ?? "未知错误"))
                        } else {
                            Defaults[.user] = DefaultsUser.init(
                                id: userInfo.id!, countryCode: userInfo.countryCode ?? 0, mobile: userInfo.mobile ?? "", showName: userInfo.showName ?? "", avatar: userInfo.avatar ?? "", wallet: userInfo.wallet ?? "", canPay: userInfo.canPay ?? 0)
                            Defaults.synchronize()
                            resolve(userInfo)
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
    
    static func updateUserInfo(_ user: APIUser, provider: MoyaProvider<UCUserService>) -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, { resolve, reject, _ in
            provider.request(
                .update(user: user)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let resp = try response.mapObject(APIResponse.self)
                        if let errorCode = resp.code {
                            reject(UCAPIError.error(code: errorCode, msg: resp.message ?? "未知错误"))
                        } else {
                            resolve(resp)
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
