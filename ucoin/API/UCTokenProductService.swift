//
//  UCTokenProductService.swift
//  ucoin
//
//  Created by Syd on 2018/6/22.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya
import Hydra

enum UCTokenProductService {
    case create(product: APITokenProduct)
    case update(product: APITokenProduct)
    case list(token: String, page: UInt, pageSize: UInt)
    case info(address: String)
}

// MARK: - TargetType Protocol Implementation
extension UCTokenProductService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/token/product")! }
    var path: String {
        switch self {
        case .create(_):
            return "/create"
        case .update(_):
            return "/update"
        case .list(_, _, _):
            return "/list"
        case .info(_):
            return "/info"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .create, .update:
            return .post
        case .list, .info:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .create(product):
            guard let token = product.token else {
                return .requestParameters(parameters: [:], encoding: JSONEncoding.default)
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            var imagesStr: String = ""
            
            if let images = product.images {
                imagesStr = images.joined(separator: ",")
            } else if let images = product.UIImages {
                
                var multipartData: [MultipartFormData] = []
                for image in images {
                    if let imageData = image.data() {
                        let imgData = MultipartFormData(provider: .data(imageData), name: "images", fileName: "product."+image.fileExtension(), mimeType: image.mime())
                        multipartData.append(imgData)
                    }
                }
                if let title = product.title {
                    let titleData = MultipartFormData(provider: .data(title.data(using: .utf8)!), name: "title")
                    multipartData.append(titleData)
                }
                
                if let price = product.price {
                    let priceData = MultipartFormData(provider: .data(String(price).data(using: .utf8)!), name: "price")
                    multipartData.append(priceData)
                }
                
                if let amount = product.amount {
                    let amountData = MultipartFormData(provider: .data(String(amount).data(using: .utf8)!), name: "amount")
                    multipartData.append(amountData)
                }
                
                if let startDate = product.startDate {
                    let dateStr = dateFormatter.string(from: startDate)
                    let startDateData = MultipartFormData(provider: .data(dateStr.data(using: .utf8)!), name: "start_date")
                    multipartData.append(startDateData)
                }
                
                if let endDate = product.endDate {
                    let dateStr = dateFormatter.string(from: endDate)
                    let endDateData = MultipartFormData(provider: .data(dateStr.data(using: .utf8)!), name: "end_date")
                    multipartData.append(endDateData)
                }
                
                if let desc = product.desc {
                    let descData = MultipartFormData(provider: .data(desc.data(using: .utf8)!), name: "desc")
                    multipartData.append(descData)
                }
                
                if let tags = product.tags {
                    if tags.count > 0 {
                        let tagsStr = tags.joined(separator: " ")
                        let tagsData = MultipartFormData(provider: .data(tagsStr.data(using: .utf8)!), name: "tags")
                        multipartData.append(tagsData)
                    }
                }
                let tokenData = MultipartFormData(provider: .data(token.address!.data(using: .utf8)!), name: "token")
                multipartData.append(tokenData)
                
                return .uploadMultipart(multipartData)
            }
            
            var tagsStr: String = ""
            if let tags = product.tags {
                if tags.count > 0 {
                    tagsStr = tags.joined(separator: " ")
                }
            }
            
            return .requestParameters(parameters: ["title": product.title!, "price": product.price!, "amount": product.amount ?? 0, "start_date": dateFormatter.string(from: product.startDate!), "end_date": dateFormatter.string(from: product.endDate!), "desc": product.desc!, "token": token.address!, "tags": tagsStr, "images": imagesStr], encoding: JSONEncoding.default)
        case let .update(product):
            guard let token = product.token else {
                return .requestParameters(parameters: [:], encoding: JSONEncoding.default)
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            var imagesStr: String = ""
            
            if let images = product.images {
                imagesStr = images.joined(separator: ",")
            } else if let images = product.UIImages {
                
                var multipartData: [MultipartFormData] = []
                for image in images {
                    if let imageData = image.data() {
                        let imgData = MultipartFormData(provider: .data(imageData), name: "images", fileName: "product."+image.fileExtension(), mimeType: image.mime())
                        multipartData.append(imgData)
                    }
                }
                if let address = product.address {
                    let addressData = MultipartFormData(provider: .data(address.data(using: .utf8)!), name: "address")
                    multipartData.append(addressData)
                }
                
                if let title = product.title {
                    let titleData = MultipartFormData(provider: .data(title.data(using: .utf8)!), name: "title")
                    multipartData.append(titleData)
                }
                
                if let price = product.price {
                    let priceData = MultipartFormData(provider: .data(String(price).data(using: .utf8)!), name: "price")
                    multipartData.append(priceData)
                }
                
                if let amount = product.amount {
                    let amountData = MultipartFormData(provider: .data(String(amount).data(using: .utf8)!), name: "amount")
                    multipartData.append(amountData)
                }
                
                if let startDate = product.startDate {
                    let dateStr = dateFormatter.string(from: startDate)
                    let startDateData = MultipartFormData(provider: .data(dateStr.data(using: .utf8)!), name: "start_date")
                    multipartData.append(startDateData)
                }
                
                if let endDate = product.endDate {
                    let dateStr = dateFormatter.string(from: endDate)
                    let endDateData = MultipartFormData(provider: .data(dateStr.data(using: .utf8)!), name: "end_date")
                    multipartData.append(endDateData)
                }
                
                if let onlineStatus = product.onlineStatus {
                    let onlineStatusData = MultipartFormData(provider: .data(String(onlineStatus).data(using: .utf8)!), name: "online_status")
                    multipartData.append(onlineStatusData)
                }
                
                if let desc = product.desc {
                    let descData = MultipartFormData(provider: .data(desc.data(using: .utf8)!), name: "desc")
                    multipartData.append(descData)
                }
                
                if let tags = product.tags {
                    if tags.count > 0 {
                        let tagsStr = tags.joined(separator: " ")
                        let tagsData = MultipartFormData(provider: .data(tagsStr.data(using: .utf8)!), name: "tags")
                        multipartData.append(tagsData)
                    }
                }
                let tokenData = MultipartFormData(provider: .data(token.address!.data(using: .utf8)!), name: "token")
                multipartData.append(tokenData)
                
                return .uploadMultipart(multipartData)
            }
            
            var tagsStr: String = ""
            if let tags = product.tags {
                if tags.count > 0 {
                    tagsStr = tags.joined(separator: " ")
                }
            }
            let amount: UInt = product.amount ?? 0
            let onlineStatus: Int8 = product.onlineStatus ?? 0
            return .requestParameters(parameters: ["address": product.address!, "title": product.title!, "price": product.price!, "amount": amount, "online_status": onlineStatus, "start_date": dateFormatter.string(from: product.startDate!), "end_date": dateFormatter.string(from: product.endDate!), "desc": product.desc!, "token": token.address!, "tags": tagsStr, "images": imagesStr], encoding: JSONEncoding.default)
        case let .list(token, page, pageSize):
            return .requestParameters(parameters: ["token": token, "page": page , "page_size": pageSize], encoding: URLEncoding.queryString)
        case let .info(address):
            return .requestParameters(parameters: ["address": address], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .create(_):
            return "{}".utf8Encoded
        case .update(_):
            return "{}".utf8Encoded
        case .list(_, _, _):
            return "[]".utf8Encoded
        case .info(_):
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension UCTokenProductService {
    static func createTokenProduct(
        _ productInfo: APITokenProduct,
        provider: MoyaProvider<UCTokenProductService>) -> Promise<APITokenProduct> {
        return Promise<APITokenProduct>(in: .background, {resolve, reject, _ in
            provider.request(
                .create(product: productInfo)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let product = try response.mapObject(APITokenProduct.self)
                        if let errorCode = product.code {
                            reject(UCAPIError.error(code: errorCode, msg: product.message ?? "未知错误"))
                        } else {
                            resolve(product)
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
    
    static func updateTokenProduct(
        _ productInfo: APITokenProduct,
        provider: MoyaProvider<UCTokenProductService>) -> Promise<APITokenProduct> {
        return Promise<APITokenProduct>(in: .background, {resolve, reject, _ in
            provider.request(
                .update(product: productInfo)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let product = try response.mapObject(APITokenProduct.self)
                        if let errorCode = product.code {
                            reject(UCAPIError.error(code: errorCode, msg: product.message ?? "未知错误"))
                        } else {
                            resolve(product)
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
    
    static func listTokenProduct(
        _ tokenAddress: String,
        _ page: UInt,
        _ pageSize: UInt,
        provider: MoyaProvider<UCTokenProductService>) -> Promise<[APITokenProduct]> {
        return Promise<[APITokenProduct]> (in: .background, { resolve, reject, _ in
            provider.request(
                .list(token: tokenAddress, page: page, pageSize: pageSize)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let products = try response.mapArray(APITokenProduct.self)
                        resolve(products)
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
    
    static func getTokenProduct(
        _ address: String,
        provider: MoyaProvider<UCTokenProductService>) -> Promise<APITokenProduct> {
        return Promise<APITokenProduct>(in: .background, {resolve, reject, _ in
            provider.request(
                .info(address: address)
            ){ result in
                switch result {
                case let .success(response):
                    do {
                        let product = try response.mapObject(APITokenProduct.self)
                        if let errorCode = product.code {
                            reject(UCAPIError.error(code: errorCode, msg: product.message ?? "未知错误"))
                        } else {
                            resolve(product)
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
