//
//  DocRestoreHandler.swift
//  SKCommon
//
//  Created by majie.7 on 2022/10/31.
//

import Foundation
import SKFoundation
import SwiftyJSON
import UniverseDesignEmpty
import RxSwift
import SpaceInterface
import SKInfra

public final class DocsRestoreHandler {
    // MARK: Space 恢复
    // 检查是否可以恢复
    public static func checkDocsDeletedCanRestore(token: String, type: DocsType) -> Single<(Bool, String?)> {
        let path = OpenAPI.APIPath.spaceCanRestore
        let pramas: [String: Any] = ["obj_token": token, "obj_type": type.rawValue]
        
        let request = DocsRequest<JSON>(path: path, params: pramas).set(method: .POST)
        return request.rxStart().map { json in
            guard let json else {
                return (false, nil)
            }
            let nodeToken = json["data"]["node_token"].string
            if let canRestore = json["data"]["can_restore"].bool {
                return (canRestore, nodeToken)
            } else {
                DocsLogger.error("check wiki docs restore status data invild")
                return (false, nil)
            }
        }
    }
    // 恢复文档
    // 发起请求 + 轮询
    public static func docsRestore(nodeToken: String) -> Single<Void> {
        Self.docsRestoreRequest(nodeToken: nodeToken)
            .flatMap { taskId in
                return Self.pollingDocsRestoreStatus(taskID: taskId, delayMS: 1000)
            }
            .timeout(.seconds(30), scheduler: MainScheduler.instance)
    }
    
    private static func docsRestoreRequest(nodeToken: String) -> Single<String> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.spaceRestore, params: ["token": nodeToken,
                                                                                     "need_no_perm_info": true])
            .set(method: .POST).set(needVerifyData: false)
        return request.rxStart().map { json in
            guard let json else {
                throw DocsNetworkError.invalidData
            }
            if let taskID = json["data"]["task_id"].string {
                return taskID
            } else if let delOperator = json["data"]["fail_data"]["no_perm_info"]["del_operator"].dictionaryObject,
                      let id = delOperator["id"] as? String,
                      let cnName = delOperator["cn_name"] as? String,
                      let enName = delOperator["en_name"] as? String {
                let failedInfo = DocsRestoreFailedInfo(deleteOperator: .init(id: id, cnName: cnName, enName: enName),
                                                       spaceName: nil,
                                                       spaceID: nil)
                throw RestoreNetWorkError.permissionError(failedInfo: failedInfo)
            } else {
                throw RestoreNetWorkError.unknown
            }
        }
    }
    
    enum RestoreStatus {
        case restoring
        case success
        case failed
    }
    
    private static func pollingDocsRestoreStatus(taskID: String, delayMS: Int) -> Single<Void> {
        Self.checkDocsRestoreStatus(taskID: taskID)
            .flatMap { status in
                switch status {
                case .restoring:
                    return pollingDocsRestoreStatus(taskID: taskID, delayMS: delayMS + 500)
                        .delaySubscription(.milliseconds(delayMS), scheduler: MainScheduler.instance)
                case .success:
                    return .just(())
                case .failed:
                    //非预期失败
                    DocsLogger.error("[space docs] check restore status failed")
                    throw DocsNetworkError.invalidData
                }
            }
    }
    
    private static func checkDocsRestoreStatus(taskID: String) -> Single<RestoreStatus> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getTask, params: ["task_id": taskID])
            .set(method: .GET)
        return request.rxStart().map { json in
            guard let json,
                  let isFinish = json["data"]["is_finish"].bool,
                  let isFail = json["data"]["is_fail"].bool else {
                throw DocsNetworkError.invalidData
            }
            if isFinish, !isFail {
                return .success
            } else if isFinish, isFail {
                return .failed
            } else if !isFinish, !isFail {
                return .restoring
            } else if !isFinish, isFail {
                return .failed
            } else {
                DocsLogger.error("unknow restore status: isFinish: \(isFinish), isFail: \(isFail)")
                return .failed
            }
        }
    }
    
    // MARK: Wiki 恢复
    // 检查wiki文档是否可以恢复
    public static func checkWikiDocsDeletedCanRestore(wikiToken: String) -> Single<(Bool, String?, Int?)> {
        let pramas: [String: Any] = ["wiki_token": wikiToken]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiCanRestore, params: pramas).set(method: .POST).set(encodeType: .jsonEncodeDefault)
        return request.rxStart().map { json in
            guard let json else {
                return (false, nil, nil)
            }
            let spaceID = json["data"]["space_id"].string
            let targetType = json["data"]["target_type"].int
            if let canRestore = json["data"]["can_restore"].bool {
                return (canRestore, spaceID, targetType)
            } else {
                DocsLogger.error("check wiki docs restore status data invild")
                return (false, nil, nil)
            }
        }
    }
    // 恢复wiki文档
    public static func wikIRestore(wikiToken: String,
                                   spaceID: String,
                                   targetType: Int) -> Single<Void> {
        let timeoutSeconds = 30 //超时时长为30s
        return Self.wikiRestoreRequest(wikiToken: wikiToken, spaceID: spaceID, targetType: targetType)
            .flatMap { taskId in
                let delayMS = 1000  // 每1000微秒间隔查询一次task状态
                return Self.pollingWikiRestoreStatus(taskID: taskId, delayMS: delayMS)
            }
            .timeout(.seconds(timeoutSeconds), scheduler: MainScheduler.instance)
    }
    
    private static func wikiRestoreRequest(wikiToken: String,
                                           spaceID: String,
                                           targetType: Int) -> Single<String> {
        let params: [String: Any] = ["wiki_token": wikiToken,
                                     "space_id": spaceID,
                                     "target_type": targetType,
                                     "need_no_perm_info": true]
        let requset = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiRestore, params: params)
            .set(method: .POST).set(encodeType: .jsonEncodeDefault).set(needVerifyData: false)
        return requset.rxStart().map { json in
            guard let json else {
                throw WikiError.dataParseError
            }
            if json["code"] == 0, let taskId = json["data"]["task_id"].string {
                return taskId
            }
            
            if let delOperator = json["data"]["fail_data"]["no_perm_info"]["del_operator"].dictionaryObject,
               let id = delOperator["id"] as? String,
               let cnName = delOperator["cn_name"] as? String,
               let enName = delOperator["en_name"] as? String,
               let spaceName = json["data"]["fail_data"]["no_perm_info"]["space_name"].string,
               let spaceID = json["data"]["fail_data"]["no_perm_info"]["space_id"].string {
                let failedInfo = DocsRestoreFailedInfo(deleteOperator: .init(id: id, cnName: cnName, enName: enName),
                                             spaceName: spaceName,
                                             spaceID: spaceID)
                throw RestoreNetWorkError.permissionError(failedInfo: failedInfo)
            }
            throw RestoreNetWorkError.unknown
        }
    }
    
    private static func pollingWikiRestoreStatus(taskID: String, delayMS: Int) -> Single<Void> {
        Self.checkWikiRestoreStatus(taskID: taskID)
            .flatMap { status in
                switch status {
                case .restoring:
                    let addDelayMS = 500    // 每次轮询新增500毫秒间隔
                    return pollingWikiRestoreStatus(taskID: taskID, delayMS: delayMS + addDelayMS)
                        .delaySubscription(.milliseconds(delayMS), scheduler: MainScheduler.instance)
                case .success:
                    return .just(())
                case .failed:
                    //非预期失败
                    DocsLogger.error("[wiki docs] check restore status failed")
                    throw DocsNetworkError.invalidData
                }
            }
    }
    
    private static func checkWikiRestoreStatus(taskID: String) -> Single<RestoreStatus> {
        enum TaskType: Int {
            case restoreNode = 5
        }
        
        enum TaskStatus: Int {
            case waiting    = 0
            case processing = 1
            case success    = 2
            case failure    = 3
        }
        
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getWikiTaskStatus, params: ["task_id": taskID, "task_type": TaskType.restoreNode.rawValue])
            .set(method: .GET)
        return request.rxStart().map { json in
            guard let json, let status = json["data"]["status"].int else {
                throw DocsNetworkError.invalidData
            }
            
            guard let taskStatus = TaskStatus(rawValue: status) else {
                DocsLogger.error("unknow restore status: \(status)")
                return .failed
            }
            
            switch taskStatus {
            case .waiting, .processing:
                return .restoring
            case .success:
                return .success
            case .failure:
                return .failed
            }
        }
    }
    
    
}
