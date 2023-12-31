//
//  WikiMoreAPI.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/9/26.
//

import Foundation
import SKFoundation
import SKResource
import SKCommon
import RxSwift
import RxCocoa
import SwiftyJSON
import SpaceInterface
import SKInfra

public final class WikiMoreAPI {
    
    public static func fetchWikiMetaStarStatus(wikiToken: String) -> Single<Bool> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getWikiInfoV2,
                                        params: ["wiki_token": wikiToken,
                                                 "need_star": true,
                                                 "expand_shortcut": true]).set(method: .GET)
        return request.rxStart().map { json in
            guard let isStar = json?["data"]["is_star"].bool else {
                return false
            }
            return isStar
        }
    }
    
    public static func fetchDriveFileInfo(wikiMeta: WikiTreeNodeMeta) -> Single<[String: Any]> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.fetchFileInfo,
                                        params: ["file_token": wikiMeta.objToken, "mount_point": DriveConstants.wikiMountPoint])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        return request.rxStart().map { json in
            guard let data = json, let code = data["code"].int else {
                throw WikiError.dataParseError
            }
            if code != 0 {
                throw WikiError.serverError(code: code)
            }
            guard let dic = data["data"].dictionaryObject else {
                throw WikiError.dataParseError
            }
            guard dic["name"] != nil, dic["size"] != nil, dic["type"] != nil else {
                throw WikiError.dataParseError
            }
            return dic
        }
    }
    
    public static func updateDriveTitle(newTitle: String, objToken: String) -> Completable {
        let params: [String: Any] = ["name": newTitle,
                                     "file_token": objToken,
                                     "mount_point": "wiki"]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.updateFileInfo,
                                        params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        return request.rxStart().map { data -> Void in
            guard let code = data?["code"].int else {
                throw WikiError.dataParseError
            }
            guard code == 0 else {
                throw WikiError.serverError(code: code)
            }
        }.asCompletable()
    }
    
    static func updateSheetTitle(newTitle: String, objToken: String) -> Completable {
        SpaceNetworkAPI.renameSheet(objToken: objToken, with: newTitle)
    }
    
    static func updateBitableTitle(newTitle: String, objToken: String) -> Completable {
        SpaceNetworkAPI.renameBitable(objToken: objToken, with: newTitle)
    }
    
    static func updateMindnoteTitle(newTitle: String, objToken: String) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.renameMindnote,
                                        params: ["token": objToken, "title": newTitle, "type": DocsType.mindnote.rawValue])
        return request.rxStart().flatMapCompletable { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                throw error
            }
            return .empty()
        }
    }
    
    static func updateSlidesTitle(newTitle: String, objToken: String) -> Completable {
        SpaceNetworkAPI.renameSlides(objToken: objToken, with: newTitle)
    }
    
    public static func rename(meta: WikiTreeNodeMeta, newTitle: String) -> Completable {
        guard !meta.isShortcut else {
            return WikiNetworkManager.shared.update(newTitle: newTitle, wikiToken: meta.wikiToken)
        }
        
        switch meta.objType {
        case .doc, .docX:
            return WikiNetworkManager.shared.update(newTitle: newTitle, wikiToken: meta.wikiToken)
        case .sheet:
            return WikiMoreAPI.updateSheetTitle(newTitle: newTitle, objToken: meta.objToken)
        case .bitable:
            return WikiMoreAPI.updateBitableTitle(newTitle: newTitle, objToken: meta.objToken)
        case .mindnote:
            return WikiMoreAPI.updateMindnoteTitle(newTitle: newTitle, objToken: meta.objToken)
        case .file:
            return WikiMoreAPI.updateDriveTitle(newTitle: newTitle, objToken: meta.objToken)
        case .slides:
            return WikiMoreAPI.updateSlidesTitle(newTitle: newTitle, objToken: meta.objToken)
        default:
            spaceAssertionFailure("the wiki docsType can't rename! please check the wiki docsType!")
            return .error(WikiError.dataParseError)
        }
    }
    
    // 从 meta 接口获取文档名字，仅在对 shortcut 创建副本场景有用
    // meta 接口暂时只有这一个场景用到，后续如果其他场景需要复用，就拓展一下此方法
    public static func fetchNameFromMeta(objToken: String, objType: DocsType) -> Single<String> {
        DocsInfoDetailHelper.fetchDetail(token: objToken, type: objType)
            .map { _, detailInfo in
                guard let title = detailInfo["title"] as? String else {
                    throw DocsInfoDetailError.parseDataFailed
                }
                return title
            }
    }

    private enum DeleteResponse {
        case success(taskID: String)
        case needApply(reviewer: WikiAuthorizedUserInfo)
    }

    // 删除单个节点
    // 发起 + 轮询复合接口
    public static func deleteSingleNode(wikiToken: String, spaceID: String, synergyUUID: String? = nil) -> Maybe<WikiAuthorizedUserInfo> {
        deleteSingleNodeRequest(wikiToken: wikiToken,
                                spaceID: spaceID,
                                canApply: UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled,
                                synergyUUID: synergyUUID)
        .flatMapMaybe { response in
            switch response {
            case let .success(taskID):
                return pollingDeleteSingleNodeStatus(taskID: taskID, delayMS: 1000).flatMapMaybe { _ in .empty() }
            case let .needApply(reviewerInfo):
                return .just(reviewerInfo)
            }
        }
        .timeout(.seconds(30), scheduler: MainScheduler.instance)
    }

    private static func deleteSingleNodeRequest(wikiToken: String,
                                                spaceID: String,
                                                canApply: Bool,
                                                synergyUUID: String?) -> Single<DeleteResponse> {
        var params: [String: Any] = [
            "wiki_token": wikiToken,
            "space_id": spaceID,
            "auto_delete_mode": 2,
            "apply": canApply ? 1 : 0
        ]
        if let synergyUUID {
            params["synergy_uuid"] = synergyUUID
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiDeleteSingleNode,
                                        params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)

        return request.rxResponse().map { json, error in
            guard let json,
                  let code = json["code"].int else {
                throw WikiError.dataParseError
            }
            switch code {
            case 0:
                guard let taskID = json["data"]["task_id"].string else {
                    throw WikiError.dataParseError
                }
                return .success(taskID: taskID)
            case WikiErrorCode.operationNeedApply.rawValue:
                let data = json["data"]
                guard let userID = data["reviewer"].string else {
                    DocsLogger.error("missing required field for delete reviewer")
                    throw WikiError.dataParseError
                }
                let userData = data["users"][userID]
                guard let userName = userData["name"].string else {
                    DocsLogger.error("missing required field for delete reviewer")
                    throw WikiError.dataParseError
                }
                let aliasInfo = UserAliasInfo(json: userData["display_name"])
                let userInfo = WikiAuthorizedUserInfo(userID: userID, userName: userName, i18nNames: [:], aliasInfo: aliasInfo)
                return .needApply(reviewer: userInfo)
            default:
                if let error {
                    throw error
                }
                throw WikiError.serverError(code: code)
            }
        }
    }
    
    private static func pollingDeleteSingleNodeStatus(taskID: String, delayMS: Int) -> Single<String> {
        checkDeleteNodeStatus(taskID: taskID)
            .flatMap { status in
                switch status {
                case .deleting:
                    // 延迟后再请求，并延长后续请求的延迟
                    return pollingDeleteSingleNodeStatus(taskID: taskID, delayMS: delayMS + 500)
                        .delaySubscription(.milliseconds(delayMS), scheduler: MainScheduler.instance)
                case .succeed:
                    return .just(taskID)
                case .failed:
                    // 非预期失败
                    DocsLogger.error("[wiki]: check delete single node status failed")
                    throw WikiError.invalidWikiError
                }
            }
    }
    
    private enum DeleteStatus {
        case deleting
        case succeed
        case failed
    }
    
    private static func checkDeleteNodeStatus(taskID: String) -> Single<DeleteStatus> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiDeleteNodeStatus,
                                  params: ["task_id": taskID]).set(method: .GET)
        return request.rxStart().map { json in
            guard let data = json?["data"] else {
                throw WikiError.dataParseError
            }
            guard let status = data["status"].int else {
                DocsLogger.error("missing required field")
                throw WikiError.dataParseError
            }
            switch status {
            case 1:
                return .deleting
            case 2:
                return .succeed
            case 3:
                return .failed
            default:
                spaceAssertionFailure("unknown status code: \(status) when check delete single node status")
                DocsLogger.error("unknown status code: \(status) when check delete single node status")
                return .failed
            }
        }
    }

    public static func applyDelete(wikiMeta: WikiMeta,
                                   isSingleDelete: Bool,
                                   reason: String?,
                                   reviewerID: String) -> Completable {
        var params: [String: Any] = [
            "token": wikiMeta.wikiToken,
            "space_id": wikiMeta.spaceID,
            "reviewer": reviewerID,
            "delete_opt": isSingleDelete ? 2 : 1
        ]
        if let reason, !reason.isEmpty {
            params["reason"] = reason
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiApplyDelete,
                                        params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().asCompletable()
    }
}
