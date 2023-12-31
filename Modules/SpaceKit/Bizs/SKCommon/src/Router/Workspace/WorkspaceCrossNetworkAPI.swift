//
//  WorkspaceCrossNetworkAPI.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/8/2.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SpaceInterface
import SKInfra

public enum WorkspaceCrossNetworkAPI {

    static func getInWikiStatus(wikiToken: String) -> Single<WorkspaceCrossRouteRecord> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetObjInfo, params: ["wiki_token": wikiToken])
            .set(method: .GET)
        return request.rxStartWithLogID()
            .map { json, logID -> WorkspaceCrossRouteRecord in
                guard let data = json?["data"] else {
                    throw WikiError.dataParseError
                }
                guard let isWiki = data["is_wiki"].bool,
                      let objToken = data["obj_token"].string,
                      let objTypeValue = data["obj_type"].int else {
                    DocsLogger.error("missing required field")
                    throw WikiError.dataParseError
                }
                let docType = DocsType(rawValue: objTypeValue)
                return WorkspaceCrossRouteRecord(wikiToken: wikiToken,
                                                 objToken: objToken,
                                                 objType: docType,
                                                 inWiki: isWiki,
                                                 logID: logID)
            }
    }

    // 对应后端 BizType
    public enum ContainerType: Int, Equatable {
        case space = 1
        case wiki = 2
        case phoenix = 3
    }

    public struct ContainerInfo: Equatable {
        // 容器 token，结合容器类型使用
        public let containerToken: String
        public let containerType: ContainerType

        public var wikiToken: String? {
            if containerType == .wiki {
                return containerToken
            }
            return nil
        }

        public var phoenixToken: String? {
            if containerType == .phoenix {
                return containerToken
            }
            return nil
        }

        public var nodeToken: String? {
            if containerType == .space {
                return containerToken
            }
            return nil
        }
    }

    // 查询文档容器信息 https://bytedance.feishu.cn/wiki/wikcnkLrDt5nug8k9Zz6PX5UPzh
    // 返回 nil 表示 token 不存在, 第二个返回值为 logID
    public static func getContainerInfo(objToken: String, objType: DocsType) -> Single<(ContainerInfo?, String?)> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getWorkspaceContainerInfo,
                                        params: [
                                            "obj_token": objToken,
                                            "obj_type": objType.rawValue
                                        ])
            .set(method: .GET)
        return request.rxStartWithLogID()
            .map { json, logID -> (ContainerInfo?, String?) in
                guard let data = json?["data"] else {
                    throw DocsNetworkError.invalidData
                }
                guard let isExist = data["is_exist"].bool else {
                    DocsLogger.error("missing required field")
                    throw DocsNetworkError.invalidData
                }
                guard isExist else {
                    return (nil, logID)
                }
                guard let nodeToken = data["node_token"].string,
                      let bizType = data["biz_type"].int else {
                    DocsLogger.error("missing required field")
                    throw DocsNetworkError.invalidData
                }
                guard let containerType = ContainerType(rawValue: bizType) else {
                    DocsLogger.error("unknown bizType: \(bizType)")
                    throw DocsNetworkError.invalidData
                }
                let info = ContainerInfo(containerToken: nodeToken, containerType: containerType)
                return (info, logID)
            }
    }

    // 校验目标 wiki 位置的 create 权限
    // TODO: 以下 wiki 权限接口逻辑来自 WikiNetworkManager，后续考虑下沉到这里，替换掉重复的实现
    public static func checkWikiCreatePermission(location: WikiPickerLocation) -> Single<Bool> {
        if location.isMainRoot {
            return checkWikiSpaceCreatePermission(spaceID: location.spaceID)
        } else {
            return checkWikiNodeCreatePermission(wikiToken: location.wikiToken, spaceID: location.spaceID)
        }
    }

    private static func checkWikiSpaceCreatePermission(spaceID: String) -> Single<Bool> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetSpacePermission,
                                        params: ["space_id": spaceID])
            .set(method: .GET)
        return request.rxStart()
            .map { json in
                guard let canEditFirstLevel = json?["data"][spaceID]["can_edit_first_level"].bool else {
                    DocsLogger.error("can not parse wiki space perm")
                    throw DocsNetworkError.invalidData
                }
                return canEditFirstLevel
            }
    }

    private static func checkWikiNodeCreatePermission(wikiToken: String, spaceID: String) -> Single<Bool> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetNodePermission,
                                        params: ["space_id": spaceID, "wiki_token": wikiToken])
            .set(method: .GET)
        return request.rxStart()
            .map { json in
                guard let canCreate = json?["data"]["can_create"].bool else {
                    DocsLogger.error("can not parse node perm")
                    throw DocsNetworkError.invalidData
                }
                return canCreate
            }
    }
    
    public static func addShortcutDuplicateCheck(objToken: String,
                                                 objType: DocsType,
                                                 location: WorkspacePickerLocation) -> Single<CreateShortcutStages> {
        let params: [String: Any] = ["parent_node_token": location.targetParentToken,
                                     "obj_token": objToken,
                                     "obj_type": objType.rawValue,
                                     "biz_type": location.targetBizType]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.checkRepeatCreateShortcut, params: params)
            .set(method: .GET)
        return request.rxStart()
            .map { json in
                guard let hasShorcut = json?["data"]["has_shortcut"].bool,
                      let hasEntity = json?["data"]["has_entity"].bool else {
                    throw DocsNetworkError.invalidData
                }
                if hasEntity {
                    return .hasEntity
                } else if hasShorcut {
                    return .hasShortcut
                } else {
                    return .normal
                }
            }
    }
}
