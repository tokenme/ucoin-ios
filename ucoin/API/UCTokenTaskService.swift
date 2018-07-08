//
//  UCTokenTaskService.swift
//  ucoin
//
//  Created by Syd on 2018/7/2.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya

enum UCTokenTaskService {
    case create(task: APITokenTask)
    case update(task: APITokenTask)
    case list(token: String, page: UInt, pageSize: UInt)
    case info(taskId: UInt64)
}

// MARK: - TargetType Protocol Implementation
extension UCTokenTaskService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/token/task")! }
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
        case let .create(tokenTask):
            guard let token = tokenTask.token else {
                return .requestParameters(parameters: [:], encoding: JSONEncoding.default)
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            var imagesStr: String = ""
            
            if let images = tokenTask.images {
                imagesStr = images.joined(separator: ",")
            } else if let images = tokenTask.UIImages {
                
                var multipartData: [MultipartFormData] = []
                for image in images {
                    if let imageData = image.data() {
                        let imgData = MultipartFormData(provider: .data(imageData), name: "images", fileName: "product."+image.fileExtension(), mimeType: image.mime())
                        multipartData.append(imgData)
                    }
                }
                if let title = tokenTask.title {
                    let titleData = MultipartFormData(provider: .data(title.data(using: .utf8)!), name: "title")
                    multipartData.append(titleData)
                }
                
                if let bonus = tokenTask.bonus {
                    let priceData = MultipartFormData(provider: .data(String(bonus).data(using: .utf8)!), name: "bonus")
                    multipartData.append(priceData)
                }
                
                if let amount = tokenTask.amount {
                    let amountData = MultipartFormData(provider: .data(String(amount).data(using: .utf8)!), name: "amount")
                    multipartData.append(amountData)
                }
                
                if let needEvidence = tokenTask.needEvidence {
                    let needEvidenceData = MultipartFormData(provider: .data(String(needEvidence).data(using: .utf8)!), name: "need_evidence")
                    multipartData.append(needEvidenceData)
                }
                
                if let startDate = tokenTask.startDate {
                    let dateStr = dateFormatter.string(from: startDate)
                    let startDateData = MultipartFormData(provider: .data(dateStr.data(using: .utf8)!), name: "start_date")
                    multipartData.append(startDateData)
                }
                
                if let endDate = tokenTask.endDate {
                    let dateStr = dateFormatter.string(from: endDate)
                    let endDateData = MultipartFormData(provider: .data(dateStr.data(using: .utf8)!), name: "end_date")
                    multipartData.append(endDateData)
                }
                
                if let desc = tokenTask.desc {
                    let descData = MultipartFormData(provider: .data(desc.data(using: .utf8)!), name: "desc")
                    multipartData.append(descData)
                }
                
                if let tags = tokenTask.tags {
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
            if let tags = tokenTask.tags {
                if tags.count > 0 {
                    tagsStr = tags.joined(separator: " ")
                }
            }
            
            let amount: UInt = tokenTask.amount ?? 0
            let needEvidence: Int8 = tokenTask.needEvidence ?? 0
            
            return .requestParameters(parameters: ["title": tokenTask.title!, "bonus": tokenTask.bonus!, "amount": amount, "need_evidence": needEvidence, "start_date": dateFormatter.string(from: tokenTask.startDate!), "end_date": dateFormatter.string(from: tokenTask.endDate!), "desc": tokenTask.desc!, "token": token.address!, "tags": tagsStr, "images": imagesStr], encoding: JSONEncoding.default)
        case let .update(tokenTask):
            guard let token = tokenTask.token else {
                return .requestParameters(parameters: [:], encoding: JSONEncoding.default)
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            var imagesStr: String = ""
            
            if let images = tokenTask.images {
                imagesStr = images.joined(separator: ",")
            } else if let images = tokenTask.UIImages {
                
                var multipartData: [MultipartFormData] = []
                for image in images {
                    if let imageData = image.data() {
                        let imgData = MultipartFormData(provider: .data(imageData), name: "images", fileName: "product."+image.fileExtension(), mimeType: image.mime())
                        multipartData.append(imgData)
                    }
                }
                
                if let id = tokenTask.id {
                    let idData = MultipartFormData(provider: .data(String(id).data(using: .utf8)!), name: "id")
                    multipartData.append(idData)
                }
                
                if let title = tokenTask.title {
                    let titleData = MultipartFormData(provider: .data(title.data(using: .utf8)!), name: "title")
                    multipartData.append(titleData)
                }
                
                if let bonus = tokenTask.bonus {
                    let priceData = MultipartFormData(provider: .data(String(bonus).data(using: .utf8)!), name: "bonus")
                    multipartData.append(priceData)
                }
                
                if let amount = tokenTask.amount {
                    let amountData = MultipartFormData(provider: .data(String(amount).data(using: .utf8)!), name: "amount")
                    multipartData.append(amountData)
                }
                
                if let startDate = tokenTask.startDate {
                    let dateStr = dateFormatter.string(from: startDate)
                    let startDateData = MultipartFormData(provider: .data(dateStr.data(using: .utf8)!), name: "start_date")
                    multipartData.append(startDateData)
                }
                
                if let endDate = tokenTask.endDate {
                    let dateStr = dateFormatter.string(from: endDate)
                    let endDateData = MultipartFormData(provider: .data(dateStr.data(using: .utf8)!), name: "end_date")
                    multipartData.append(endDateData)
                }
                
                if let onlineStatus = tokenTask.onlineStatus {
                    let onlineStatusData = MultipartFormData(provider: .data(String(onlineStatus).data(using: .utf8)!), name: "online_status")
                    multipartData.append(onlineStatusData)
                }
                
                if let needEvidence = tokenTask.needEvidence {
                    let needEvidenceData = MultipartFormData(provider: .data(String(needEvidence).data(using: .utf8)!), name: "need_evidence")
                    multipartData.append(needEvidenceData)
                }
                
                if let desc = tokenTask.desc {
                    let descData = MultipartFormData(provider: .data(desc.data(using: .utf8)!), name: "desc")
                    multipartData.append(descData)
                }
                
                if let tags = tokenTask.tags {
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
            if let tags = tokenTask.tags {
                if tags.count > 0 {
                    tagsStr = tags.joined(separator: " ")
                }
            }
            
            let amount: UInt = tokenTask.amount ?? 0
            let onlineStatus: Int8 = tokenTask.onlineStatus ?? 0
            let needEvidence: Int8 = tokenTask.needEvidence ?? 0
            
            return .requestParameters(parameters: ["id": tokenTask.id!, "title": tokenTask.title!, "bonus": tokenTask.bonus!, "amount": amount, "online_status": onlineStatus, "need_evidence": needEvidence, "start_date": dateFormatter.string(from: tokenTask.startDate!), "end_date": dateFormatter.string(from: tokenTask.endDate!), "desc": tokenTask.desc!, "token": token.address!, "tags": tagsStr, "images": imagesStr], encoding: JSONEncoding.default)
        case let .list(token, page, pageSize):
            return .requestParameters(parameters: ["token": token, "page": page , "page_size": pageSize], encoding: URLEncoding.queryString)
        case let .info(taskId):
            return .requestParameters(parameters: ["id": taskId], encoding: URLEncoding.queryString)
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

extension UCTokenTaskService {
    static func createTokenTask(
        _ taskInfo: APITokenTask,
        provider: MoyaProvider<UCTokenTaskService>,
        success: ((_ product: APITokenTask) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)? ) {
        provider.request(
            .create(task: taskInfo)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let task = try response.mapObject(APITokenTask.self)
                    if let errorCode = task.code {
                        failed?(UCAPIError.error(code: errorCode, msg: task.message ?? "未知错误"))
                    } else {
                        success?(task)
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
    
    static func updateTokenTask(
        _ taskInfo: APITokenTask,
        provider: MoyaProvider<UCTokenTaskService>,
        success: ((_ product: APITokenTask) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)? ) {
        provider.request(
            .update(task: taskInfo)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let task = try response.mapObject(APITokenTask.self)
                    if let errorCode = task.code {
                        failed?(UCAPIError.error(code: errorCode, msg: task.message ?? "未知错误"))
                    } else {
                        success?(task)
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
    
    static func listTokenTask(
        _ tokenAddress: String,
        _ page: UInt,
        _ pageSize: UInt,
        provider: MoyaProvider<UCTokenTaskService>,
        success: ((_ products: [APITokenTask]) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: @escaping () -> Void) {
        provider.request(
            .list(token: tokenAddress, page: page, pageSize: pageSize)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let tasks = try response.mapArray(APITokenTask.self)
                    success?(tasks)
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
            complete()
        }
    }
    
    static func getTokenTask(
        _ taskId: UInt64,
        provider: MoyaProvider<UCTokenTaskService>,
        success: ((_ product: APITokenTask) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)? ) {
        provider.request(
            .info(taskId: taskId)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let task = try response.mapObject(APITokenTask.self)
                    if let errorCode = task.code {
                        failed?(UCAPIError.error(code: errorCode, msg: task.message ?? "未知错误"))
                    } else {
                        success?(task)
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
