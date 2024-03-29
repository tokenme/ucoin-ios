//
//  UCOrderService.swift
//  ucoin
//
//  Created by Syd on 2018/7/5.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya
import Hydra

enum UCOrderService {
    case create(address: String)
    case info(id: UInt64, product: String)
    case list(product: String, ownerType: UInt8, page: UInt, pageSize: UInt)
}

// MARK: - TargetType Protocol Implementation
extension UCOrderService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/order")! }
    var path: String {
        switch self {
        case .create(_):
            return "/create"
        case .info(_, _):
            return "/info"
        case .list(_, _, _, _):
            return "/list"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .create:
            return .post
        case .info, .list:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .create(address):
            return .requestParameters(parameters: ["address": address], encoding: JSONEncoding.default)
        case let .list(product, ownerType, page, pageSize):
            return .requestParameters(parameters: ["product": product, "owner_type": ownerType, "page": page , "page_size": pageSize], encoding: URLEncoding.queryString)
        case let .info(id, product):
            return .requestParameters(parameters: ["id": id, "product": product], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .create(_):
            return "{}".utf8Encoded
        case .info(_, _):
            return "{}".utf8Encoded
        case .list(_, _, _, _):
            return "[]".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension UCOrderService {
    static func createOrder(
        _ productAddress: String,
        provider: MoyaProvider<UCOrderService>) -> Promise<APIOrder> {
        return Promise<APIOrder>(in: .background, {resolve, reject, _ in
            provider.request(
                .create(address: productAddress)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let order = try response.mapObject(APIOrder.self)
                        if let errorCode = order.code {
                            reject(UCAPIError.error(code: errorCode, msg: order.message ?? "未知错误"))
                        } else {
                            resolve(order)
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
    
    static func getOrder(
        _ orderId: UInt64,
        _ productAddress: String,
        provider: MoyaProvider<UCOrderService>) -> Promise<APIOrder> {
        return Promise<APIOrder>(in: .background, {resolve, reject, _ in
            provider.request(
                .info(id: orderId, product: productAddress)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let order = try response.mapObject(APIOrder.self)
                        if let errorCode = order.code {
                            reject(UCAPIError.error(code: errorCode, msg: order.message ?? "未知错误"))
                        } else {
                            resolve(order)
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
    
    static func listOrders(
        _ productAddress: String,
        _ ownerType: UInt8,
        _ page: UInt,
        _ pageSize: UInt,
        provider: MoyaProvider<UCOrderService>) -> Promise<[APIOrder]> {
        return Promise<[APIOrder]>(in: .background, {resolve, reject, _ in
            provider.request(
                .list(product: productAddress, ownerType: ownerType, page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let orders = try response.mapArray(APIOrder.self)
                        resolve(orders)
                    } catch {
                        do {
                            let err = try response.mapObject(APIResponse.self)
                            if let errorCode = err.code {
                                reject(UCAPIError.error(code: errorCode, msg: err.message ?? "未知错误"))
                            } else {
                                reject(UCAPIError.error(code: 0, msg: "未知错误"))
                            }
                        } catch {
                            if response.statusCode == 200 {
                                resolve([])
                            } else {
                                reject(UCAPIError.error(code: response.statusCode, msg: response.description))
                            }
                        }
                    }
                case let .failure(error):
                    reject(UCAPIError.error(code: 0, msg: error.errorDescription ?? "未知错误"))
                }
            }
        })
    }
}
