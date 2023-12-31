//
//  WorkspaceManagementAPI.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/11/1.
//

import Foundation
import SKFoundation
import RxSwift
import SwiftyJSON
import SpaceInterface
import SKInfra


// 移快复互通能力
public enum WorkspaceManagementAPI {

    public typealias CommonSettingScene = CCMCommonSettingsScene

    public static func getCommonSetting(scenes: Set<CommonSettingScene>, meta: SpaceMeta?) -> Single<[CommonSettingScene: CCMCommonSettingsScene.Value]> {
        CCMUserSettingsNetworkAPI.getCommonSetting(scenes: scenes, meta: meta)
    }

    public static func updaetCommonSetting(settings: [CommonSettingScene: Codable], meta: SpaceMeta?) -> Single<[CommonSettingScene: Bool]> {
        CCMUserSettingsNetworkAPI.updateCommonSetting(settings: settings, meta: meta)
    }

    public typealias DefaultCreateLocation = CCMCommonSettingsScene.Value.DefaultCreateLocation

    public static func getDefaultCreateLocation() -> Single<DefaultCreateLocation> {
        getCommonSetting(scenes: [.nodeDefaultCreatePosition], meta: nil)
            .map { result in
                guard case let .nodeDefaultCreatePosition(location) = result[.nodeDefaultCreatePosition] else {
                    throw DocsNetworkError.invalidData
                }
                return location
            }
    }
}

// 本体在 Space 的操作
public extension WorkspaceManagementAPI {
    enum Space {

        public struct CopyToSpaceRequest {
            public let sourceMeta: SpaceMeta
            public let ownerType: Int
            public let folderToken: String
            public let originName: String
            public let fileSize: Int64?
            public let trackParams: DocsCreateDirectorV2.TrackParameters

            public init(sourceMeta: SpaceMeta, ownerType: Int, folderToken: String, originName: String,
                        fileSize: Int64? = nil, trackParams: DocsCreateDirectorV2.TrackParameters) {
                self.sourceMeta = sourceMeta
                self.ownerType = ownerType
                self.folderToken = folderToken
                self.originName = originName
                self.fileSize = fileSize
                self.trackParams = trackParams
            }
        }
        // Space CopyTo Space, 返回副本的 URL
        public static func copyToSpace(request: CopyToSpaceRequest,
                                       // 仅为透传给 DocsCreateDirector，容量管理弹窗用
                                       router: DocsCreateViewControllerRouter?) -> Single<URL> {
            return Single.create { single in
                let docsCreateDir = DocsCreateDirectorV2(type: request.sourceMeta.objType,
                                                         ownerType: request.ownerType,
                                                         name: request.originName,
                                                         in: request.folderToken,
                                                         trackParamters: request.trackParams)
                docsCreateDir.handleRouter = false
                docsCreateDir.router = router
                docsCreateDir.makeSelfReferenced()
                docsCreateDir.createByCopy(orignalToken: request.sourceMeta.objToken,
                                           docType: request.sourceMeta.objType,
                                           name: request.originName,
                                           folderToken: request.folderToken,
                                           fileSize: request.fileSize) { newURL, _, _, _, error in
                    if let error = error {
                        single(.error(error))
                        return
                    }
                    guard let url = newURL, let fileURL = URL(string: url) else {
                        single(.error(DocsNetworkError.invalidData))
                        return
                    }
                    single(.success(fileURL))
                }
                return Disposables.create()
            }
        }

        // Space CopyTo Wiki, 返回副本的 wiki token
        public static func copyToWiki(objToken: String,
                                      objType: DocsType,
                                      location: WikiPickerLocation,
                                      title: String,
                                      needAsync: Bool) -> Single<(JSON, String)> {
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.copyToWiki,
                                            params: [
                                                "obj_token": objToken,
                                                "obj_type": objType.rawValue,
                                                "target_space_id": location.spaceID,
                                                "target_wiki_token": location.wikiToken,
                                                "title": title,
                                                "async": needAsync,
                                                "time_zone": TimeZone.current.identifier
                                            ])
                .set(method: .POST)
                .set(encodeType: .jsonEncodeDefault)
            return request.rxStart().map { json in
                guard let data = json?["data"],
                      let token = data["wiki_token"].string else {
                    throw DocsNetworkError.invalidData
                }
                return (data, token)
            }
        }

        // Space ShortcutTo Space，返回 shortcut 的 node token
        public static func shortcutToSpace(objToken: String,
                                           objType: DocsType,
                                           folderToken: FileListDefine.NodeToken) -> Single<String> {
            let entities: [String: Any] = ["obj_token": objToken, "obj_type": objType.rawValue]
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.addShortCutTo,
                                            params: ["parent_token": folderToken, "entities": [entities]])
                .set(method: .POST)
                .set(encodeType: .jsonEncodeDefault)
            return request.rxStart().map { json in
                guard let nodes = json?["data"]["entities"]["nodes"].dictionaryObject,
                      let token = nodes.keys.first else {
                    throw DocsNetworkError.invalidData
                }
                return token
            }
        }

        public static func shortcutToWiki(objToken: String,
                                          objType: DocsType,
                                          title: String,
                                          location: WikiPickerLocation) -> Single<(String, JSON)> {
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiAddRelationV2,
                                            params: [
                                                "obj_token": objToken,
                                                "obj_type": objType.rawValue,
                                                "space_id": location.spaceID,
                                                "parent_wiki_token": location.wikiToken,
                                                "title": title,
                                                "node_type": 1
                                            ])
                .set(method: .POST)
                .set(encodeType: .jsonEncodeDefault)
            return request.rxStart()
                .map { json in
                    guard let data = json?["data"],
                          let wikiToken = data["wiki_token"].string else {
                        throw DocsNetworkError.invalidData
                    }
                    return (wikiToken, data)
                }
        }

        public static func getMoveReviewer(nodeToken: String?, item: SpaceMeta?, targetToken: String?) -> Maybe<AuthorizedUserInfo> {
            var params: [String: Any] = [:]
            if let nodeToken {
                params["src_token"] = nodeToken
            } else if let item {
                params["src_obj_token"] = item.objToken
                params["src_obj_type"] = item.objType.rawValue
            } else {
                spaceAssertionFailure("both nodeToken and item found nil")
                return .error(DocsNetworkError.invalidParams)
            }
            if let targetToken {
                params["dest_token"] = targetToken
            }
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getSpaceMoveReviewer,
                                            params: params)
                .set(method: .GET)
            return request.rxStart().flatMapMaybe { json -> Maybe<AuthorizedUserInfo> in
                guard let data = json?["data"] else {
                    throw DocsNetworkError.invalidData
                }
                guard let notNeedApply = data["not_need_apply"].bool else {
                    throw DocsNetworkError.invalidData
                }
                if notNeedApply {
                    return .empty()
                }
                guard let userID = data["reviewer"].string else {
                    DocsLogger.error("reviewer userID not found")
                    throw DocsNetworkError.invalidData
                }
                let userInfo = data["entities"]["users"][userID]
                guard let userName = userInfo["name"].string else {
                    DocsLogger.error("reviewer name not found")
                    throw DocsNetworkError.invalidData
                }
                var i18nNames: [String: String] = [:]
                i18nNames["zh_cn"] = userInfo["cn_name"].string
                i18nNames["en_us"] = userInfo["en_name"].string

                let aliasInfo = UserAliasInfo(json: userInfo["display_name"])
                let info = AuthorizedUserInfo(userID: userID,
                                              userName: userName,
                                              i18nNames: i18nNames,
                                              aliasInfo: aliasInfo)
                return .just(info)
            }
        }

        public static func applyMoveToSpace(nodeToken: String, targetToken: String?, reviewerID: String, comment: String?) -> Completable {
            var params: [String: Any] = [
                "src_token": nodeToken,
                "reviewer": reviewerID
            ]
            if let targetToken {
                params["dest_token"] = targetToken
            }
            if let comment {
                params["comment"] = comment
            }
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.spaceApplyMoveToSpace,
                                            params: params)
                .set(method: .POST)
            return request.rxStart().asCompletable()
        }

        public static func applyMoveToWiki(item: SpaceMeta, location: WikiPickerLocation, reviewerID: String, comment: String?) -> Completable {
            var params: [String: Any] = [
                "obj_token": item.objToken,
                "obj_type": item.objType.rawValue,
                "parent_wiki_token": location.wikiToken,
                "space_id": location.spaceID,
                "authorized_user_id": reviewerID // 后端接口定义是可选的，但在端上流程里是必传的，暂时要求必传
            ]
            if let comment {
                params["reason"] = comment
            }
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.spaceApplyMoveToWiki, params: params)
                .set(method: .POST)
                .set(encodeType: .jsonEncodeDefault)
            return request.rxStart().asCompletable()
        }

        private static func startMoveToWiki(item: SpaceMeta, location: WikiPickerLocation) -> Single<String> {
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.spaceStartMoveToWiki,
                                            params: [
                                                "parent_wiki_token": location.wikiToken,
                                                "space_id": location.spaceID,
                                                "objs": [ // 后端支持批量，但端上暂时只有单个移动场景
                                                    [
                                                        "obj_token": item.objToken,
                                                        "obj_type": item.objType.rawValue
                                                    ]
                                                ]
                                            ])
                .set(method: .POST)
                .set(encodeType: .jsonEncodeDefault)
            return request.rxStart().map { json in
                guard let taskID = json?["data"]["task_id"].string else {
                    throw DocsNetworkError.invalidData
                }
                return taskID
            }
        }

        private static func checkMoveToWikiStatus(taskID: String) -> Single<MoveToWikiStatus> {
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.spaceGetMoveToWikiStatus,
                                            params: ["task_id": taskID])
                .set(method: .GET)
            return request.rxStart().map { json in
                guard let data = json?["data"],
                      let taskStatus = data["task_status"].int else {
                    throw DocsNetworkError.invalidData
                }
                // taskStatus 0 表示移动中，1表示已完成
                if taskStatus == 0 {
                    return .moving
                }
                guard let moveInfo = data["move_objs"].array?.first,
                      let status = moveInfo["status"].int else {
                    throw DocsNetworkError.invalidData
                }
                switch status {
                case 0:
                    return .moving
                case 1:
                    guard let wikiToken = moveInfo["wiki_token"].string else {
                        throw DocsNetworkError.invalidData
                    }
                    return .succeed(wikiToken: wikiToken)
                default:
                    DocsLogger.error("check move to wiki status found error status", extraInfo: ["task_id": taskID, "status": status])
                    return .failed(code: status)
                }
            }
        }

        private static func pollingMoveToWikiStatus(taskID: String, delayMS: Int) -> Single<MoveToWikiStatus> {
            checkMoveToWikiStatus(taskID: taskID)
                .flatMap { status -> Single<MoveToWikiStatus> in
                    switch status {
                    case .moving:
                        // nolint-next-line: magic number
                        return pollingMoveToWikiStatus(taskID: taskID, delayMS: delayMS + 500)
                            .delaySubscription(.milliseconds(delayMS), scheduler: MainScheduler.instance)
                    case .succeed, .failed:
                        return .just(status)
                    }
                }
        }

        // 发起 + 轮询复合接口
        public static func moveToWiki(item: SpaceMeta, location: WikiPickerLocation) -> Single<MoveToWikiStatus> {
            startMoveToWiki(item: item, location: location)
                .flatMap { taskID -> Single<MoveToWikiStatus> in
                    // nolint-next-line: magic number
                    pollingMoveToWikiStatus(taskID: taskID, delayMS: 1000)
                }
                .timeout(.seconds(30), scheduler: MainScheduler.instance)
        }

    }
}

// 本体在 Wiki 的操作
public extension WorkspaceManagementAPI {
    enum Wiki {
        // Wiki CopyTo Space, 返回副本的 objToken 和 URL
        public static func copyToSpace(sourceWikiToken: String,
                                       sourceSpaceID: String,
                                       title: String,
                                       folderToken: String,
                                       needAsync: Bool) -> Single<(String, URL)> {
            let params: [String: Any] = [
                "time_zone": TimeZone.current.identifier,
                "space_id": sourceSpaceID,
                "wiki_token": sourceWikiToken,
                "parent_token": folderToken,
                "title": title,
                "async": needAsync
            ]
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiCopyFileToSpace, params: params)
                .set(method: .POST)
                .set(encodeType: .jsonEncodeDefault)
            return request.rxStart().map { json in
                guard let data = json?["data"],
                      let url = data["url"].url,
                      let objToken = data["obj_token"].string else {
                    throw WikiError.dataParseError
                }
                return (objToken, url)
            }
        }

        // Wiki CopyTo Wiki, 返回 data json 和 URL
        public static func copyToWiki(sourceMeta: WikiMeta,
                                      targetMeta: WikiMeta,
                                      title: String,
                                      needAsync: Bool,
                                      synergyUUID: String?) -> Single<(JSON, URL)> {
            var params: [String: Any] = [
                "time_zone": TimeZone.current.identifier,
                "space_id": sourceMeta.spaceID,
                "wiki_token": sourceMeta.wikiToken,
                "target_space_id": targetMeta.spaceID,
                "target_wiki_token": targetMeta.wikiToken,
                "title": title,
                "async": needAsync
            ]
            if let synergyUUID = synergyUUID {
                params["synergy_uuid"] = synergyUUID
            }
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiCopyFile,
                                            params: params)
                .set(method: .POST)
                .set(encodeType: .jsonEncodeDefault)
            return request.rxStart().map { json in
                guard let data = json?["data"],
                      let url = data["url"].url else {
                    DocsLogger.warning("parse copyWikiNode response data failed")
                    throw WikiError.dataParseError
                }
                return (data, url)
            }
        }

        // Wiki CopyTo Space, 返回 shortcut node token 和 文件夹 URL
        public static func shortcutToSpace(objToken: String,
                                           objType: DocsType,
                                           folderToken: String) -> Single<(String, URL)> {
            Space.shortcutToSpace(objToken: objToken, objType: objType, folderToken: folderToken)
                .map { shortcutNodeToken in
                    let folderURL = DocsUrlUtil.url(type: .folder, token: folderToken)
                    return (shortcutNodeToken, folderURL)
                }
        }

        // Wiki ShortcutTo Wiki, 返回 data json 结构
        public static func shortcutToWiki(sourceWikiToken: String,
                                          targetWikiToken: String,
                                          targetSpaceID: String,
                                          title: String?,
                                          synergyUUID: String?) -> Single<JSON> {
            var params: [String: Any] = [
                "time_zone": TimeZone.current.identifier,
                "space_id": targetSpaceID,
                "parent_wiki_token": targetWikiToken,
                "node_type": 1, // 表示 shortcut 节点
                "wiki_token": sourceWikiToken,
                "expand_shortcut": true
            ]
            if let title = title {
                params["title"] = title
            }
            if let synergyUUID = synergyUUID {
                params["synergy_uuid"] = synergyUUID
            }
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiAddRelationV2, params: params)
                .set(method: .POST)
                .set(encodeType: .jsonEncodeDefault)
            return request.rxStart()
                .map { json in
                    guard let data = json?["data"] else {
                        DocsLogger.error("create wiki shortcut node failed")
                        throw WikiError.dataParseError
                    }
                    return data
                }
        }

        // location 为 nil 表示创建到我的文档库默认位置
        public static func createNode(location: (spaceID: String, parentWikiToken: String)?,
                                      objType: DocsType,
                                      templateToken: String?,
                                      templateSource: String? = nil,
                                      synergyUUID: String?) -> Single<JSON> {
            var params: [String: Any] = [
                "time_zone": TimeZone.current.identifier,
                "node_type": 0, // 表示实体节点
                "obj_type": objType.rawValue,
                "expand_shortcut": true
            ]
            if let location {
                params["space_id"] = location.spaceID
                params["parent_wiki_token"] = location.parentWikiToken
            }
            if let synergyUUID = synergyUUID {
                params["synergy_uuid"] = synergyUUID
            }
            if let templateToken = templateToken {
                params["template_token"] = templateToken
                if let temStr = templateSource {
                    let templateSource = TemplateCenterTracker.TemplateSource.init(temStr)
                    params["ext_info_str"] = templateSource.i18nExtInfo().jsonString
                }
            }
            
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiAddRelationV2, params: params)
                .set(method: .POST)
                .set(encodeType: .jsonEncodeDefault)
            return request.rxStart()
                .map { json in
                    guard let data = json?["data"] else {
                        DocsLogger.error("create wiki node failed")
                        throw WikiError.dataParseError
                    }
                    return data
                }
        }
    }
}
