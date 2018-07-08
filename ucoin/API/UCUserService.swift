//
//  UCUserService.swift
//  ucoin
//
//  Created by Syd on 2018/6/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya
import SwiftyUserDefaults

enum UCUserService {
    case create(country: UInt, mobile: String, verifyCode: String, password: String, repassword: String)
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
        case .info(_):
            return "/info"
        }
    }
    var method: Moya.Method {
        switch self {
        case .create:
            return .post
        case .info:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .create(country, mobile, verifyCode, password, repassword):
            return .requestParameters(parameters: ["country_code": country, "mobile": mobile, "verify_code": verifyCode, "passwd": password, "repasswd": repassword], encoding: JSONEncoding.default)
        case let .info(refresh):
            return .requestParameters(parameters: ["refresh": refresh], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .create(_, _, _, _, _):
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
    static func getUserInfo(
        _ refresh: Bool,
        provider: MoyaProvider<UCUserService>,
        success: ((_ user: APIUser) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)?) {
        provider.request(
            .info(refresh: refresh)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let userInfo = try response.mapObject(APIUser.self)
                    if let errorCode = userInfo.code {
                        failed?(UCAPIError.error(code: errorCode, msg: userInfo.message ?? "未知错误"))
                    } else {
                        Defaults[.user] = DefaultsUser.init(
                            id: userInfo.id!, countryCode: userInfo.countryCode ?? 0, mobile: userInfo.mobile ?? "", showName: userInfo.showName ?? "", avatar: userInfo.avatar ?? "", wallet: userInfo.wallet ?? "")
                        Defaults.synchronize()
                        success?(userInfo)
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
