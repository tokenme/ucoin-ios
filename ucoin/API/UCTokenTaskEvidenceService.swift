//
//  UCTokenTaskEvidenceService.swift
//  ucoin
//
//  Created by Syd on 2018/7/9.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Moya

enum UCTokenTaskEvidenceService {
    case create(evidence: APITokenTaskEvidence)
    case list(taskId: UInt64, approveStatus: Int8, page: UInt, pageSize: UInt)
    case approve(evidenceId: UInt64, approveStatus: Int8)
}

// MARK: - TargetType Protocol Implementation
extension UCTokenTaskEvidenceService: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        get {
            return .bearer
        }
    }
    
    var baseURL: URL { return URL(string: kAPIBaseURL + "/token/task/evidence")! }
    var path: String {
        switch self {
        case .create(_):
            return "/create"
        case .list(_, _, _, _):
            return "/list"
        case .approve(_, _):
            return "/approve"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .create, .approve:
            return .post
        case .list:
            return .get
        }
    }
    var task: Task {
        switch self {
        case let .create(evidence):
            guard let task = evidence.task else {
                return .requestParameters(parameters: [:], encoding: JSONEncoding.default)
            }
            var imagesStr: String = ""
            
            if let images = task.images {
                imagesStr = images.joined(separator: ",")
            } else if let images = task.UIImages {
                
                var multipartData: [MultipartFormData] = []
                for image in images {
                    if let imageData = image.data() {
                        let imgData = MultipartFormData(provider: .data(imageData), name: "images", fileName: "product."+image.fileExtension(), mimeType: image.mime())
                        multipartData.append(imgData)
                    }
                }
                
                if let taskId = task.id {
                    let idData = MultipartFormData(provider: .data(String(taskId).data(using: .utf8)!), name: "task_id")
                    multipartData.append(idData)
                }
                
                if let desc = evidence.desc {
                    let descData = MultipartFormData(provider: .data(desc.data(using: .utf8)!), name: "desc")
                    multipartData.append(descData)
                }
                
                return .uploadMultipart(multipartData)
            }
            
            return .requestParameters(parameters: ["desc": evidence.desc!, "task_id": task.id!, "images": imagesStr], encoding: JSONEncoding.default)
        case let .list(taskId, approveStatus, page, pageSize):
            return .requestParameters(parameters: ["task_id": taskId, "approve_status": approveStatus, "page": page , "page_size": pageSize], encoding: URLEncoding.queryString)
        case let .approve(evidenceId, approveStatus):
            return .requestParameters(parameters: ["evidence_id": evidenceId, "approve_status": approveStatus], encoding: JSONEncoding.default)
        }
    }
    
    var sampleData: Data {
        switch self {
        case .create(_):
            return "{}".utf8Encoded
        case .list(_, _, _, _):
            return "[]".utf8Encoded
        case .approve(_, _):
            return "{}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}

extension UCTokenTaskEvidenceService {
    static func createEvidence(
        _ evidence: APITokenTaskEvidence,
        provider: MoyaProvider<UCTokenTaskEvidenceService>,
        success: ((_ evidence: APITokenTaskEvidence) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)? ) {
        provider.request(
            .create(evidence: evidence)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let evidence = try response.mapObject(APITokenTaskEvidence.self)
                    if let errorCode = evidence.code {
                        failed?(UCAPIError.error(code: errorCode, msg: evidence.message ?? "未知错误"))
                    } else {
                        success?(evidence)
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
    
    static func listEvidence(
        _ taskId: UInt64,
        _ approveStatus: Int8,
        _ page: UInt,
        _ pageSize: UInt,
        provider: MoyaProvider<UCTokenTaskEvidenceService>,
        success: ((_ evidences: [APITokenTaskEvidence]) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: @escaping () -> Void) {
        provider.request(
            .list(taskId: taskId, approveStatus: approveStatus, page: page, pageSize: pageSize)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let evidences = try response.mapArray(APITokenTaskEvidence.self)
                    success?(evidences)
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
    
    static func approveEvidence(
        _ evidenceId: UInt64,
        approveStatus: Int8,
        provider: MoyaProvider<UCTokenTaskEvidenceService>,
        success: ((_ evidence: APITokenTaskEvidence) -> Void)?,
        failed: ((_ error: UCAPIError) -> Void)?,
        complete: (() -> Void)? ) {
        provider.request(
            .approve(evidenceId: evidenceId, approveStatus: approveStatus)
        ){ result in
            switch result {
            case let .success(response):
                do {
                    let evidence = try response.mapObject(APITokenTaskEvidence.self)
                    if let errorCode = evidence.code {
                        failed?(UCAPIError.error(code: errorCode, msg: evidence.message ?? "未知错误"))
                    } else {
                        success?(evidence)
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
