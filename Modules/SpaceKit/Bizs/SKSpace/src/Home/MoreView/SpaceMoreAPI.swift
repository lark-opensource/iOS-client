//
//  SpaceMoreAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/10/27.
//

import Foundation
import SKCommon
import RxSwift
import RxRelay
import SKResource
import SKFoundation
import SwiftyJSON
import SpaceInterface
import SKInfra

// 帮助统一 More 面板内常规功能选项的逻辑
enum SpaceMoreAPI {

    enum ListType: Equatable {
        // 最近列表
        case recent
        // 收藏列表
        case favorites
        // 快速访问
        case quickAccess
        // 离线
        case offline
        // 我的空间（v1）
        case mySpaceV1
        // 我的空间（v2）
        case mySpace
        // 我的文件夹（v1）
        case myFolder
        // 共享空间（v1）
        case shareSpace
        // 与我共享（v2）
        case shareToMe
        // 共享文件夹（v1/v2）
        case shareFolder
        // 子文件夹（v1/v2）
        // TODO: 1.0 共享文件夹依赖额外参数，后续去掉
        case subFolder(type: SubFolderType)
        // 新首页-置顶云文档列表
        case clipDocument
        

        enum SubFolderType: Equatable {
            case v1Personal
            case v1Share(spaceID: String)
            case v2Personal
            case v2Share
        }

        // 是否是个人空间，不区分 1.0 2.0
        var isMySpace: Bool {
            switch self {
            case .mySpaceV1, .mySpace:
                return true
            default:
                return false
            }
        }

        var isSubFolder: Bool {
            if case .subFolder = self {
                return true
            } else {
                return false
            }
        }

        // 列表内item是否有"移动到"入口
        var hasMoveToAction: Bool {
            switch self {
            case .mySpace, .mySpaceV1,
                 .subFolder, .myFolder:
                return true
            case .recent, .favorites, .quickAccess, .clipDocument:
                return UserScopeNoChangeFG.ZYP.spaceMoveToEnable
            default:
                return false
            }
        }
    }

    enum MoreError: Error {
        case fetchFailed
    }

    // 通过 publicPermission 接口检查文档是否被删除，仅在文档 shortcut 场景有用
    static func fetchIsFileDeleted(item: SpaceItem) -> Single<Bool> {
        return Single.create { single in
            let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
            permissionManager.fetchPublicPermissions(token: item.objToken, type: item.objType.rawValue) { _, error in
                guard let error = error else {
                    single(.success(false))
                    return
                }
                guard let docsError = error as? DocsNetworkError else {
                    single(.error(error))
                    return
                }
                switch docsError.code {
                case .entityDeleted, .notFound:
                    single(.success(true))
                default:
                    single(.error(docsError))
                }
            }
            return Disposables.create()
        }
    }

    static func userPermissionService(for entry: SpaceEntry) -> UserPermissionService {
        let service = DocsContainer.shared.resolve(PermissionSDK.self)!
            .userPermissionService(for: entry.userPermissionEntity)
        if let tenantID = entry.ownerTenantID {
            service.update(tenantID: tenantID)
        }
        return service
    }

    static func parentFolderPermissionService(for entry: SpaceEntry, listType: ListType) -> UserPermissionService {
        let sdk = DocsContainer.shared.resolve(PermissionSDK.self)!
        guard let parentToken = entry.parent, !parentToken.isEmpty else {
            return sdk.userPermissionService(for: .personalRootFolder)
        }
        guard case let .subFolder(type) = listType else {
            return sdk.userPermissionService(for: .folder(token: parentToken))
        }
        switch type {
        case .v1Personal:
            return sdk.userPermissionService(for: .legacyFolder(info: SpaceV1FolderInfo(token: parentToken, folderType: .personal)))
        case let .v1Share(spaceID):
            // more 面板场景不关心 isRoot 和 ownerID 的真实值
            return sdk.userPermissionService(for: .legacyFolder(info: SpaceV1FolderInfo(token: parentToken, folderType: .share(spaceID: spaceID, isRoot: false, ownerID: nil))))
        case .v2Personal, .v2Share:
            return sdk.userPermissionService(for: .folder(token: parentToken))
        }
    }

    // 查询用户权限
    @available(*, deprecated, message: "Use UserPermissionService instead")
    static func fetchUserPermission(item: SpaceItem) -> Single<UserPermissionAbility> {
        return Single.create { single in
            let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
            permissionManager.fetchUserPermissions(token: item.objToken, type: item.objType.rawValue) { info, error in
                if let error = error {
                    single(.error(error))
                    return
                }
                guard let mask = info?.mask else {
                    single(.error(MoreError.fetchFailed))
                    return
                }
                single(.success(mask))
            }
            // 没法取消权限请求
            return Disposables.create()
        }
    }

    // 查询对 v2 folder 的用户权限
    @available(*, deprecated, message: "Use UserPermissionService instead")
    static func fetchV2FolderUserPermission(folderToken: FileListDefine.ObjToken) -> Single<ShareFolderV2UserPermission> {
        return Single.create { single in
            let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
            permissionManager.requestShareFolderUserPermission(token: folderToken, actions: []) { permissionMask, error in
                if let error = error {
                    single(.error(error))
                    return
                }
                guard let permission = permissionMask else {
                    single(.error(MoreError.fetchFailed))
                    return
                }
                single(.success(permission))
            }
            // 没法取消权限请求
            return Disposables.create()
        }
    }

    // 查询对 v1 folder 是否有编辑权限，除 edit 权限外其他点位都没用上，所以直接封装为查询编辑权限
    @available(*, deprecated, message: "Use UserPermissionService instead")
    static func fetchV1FolderEditPermission(folderToken: FileListDefine.ObjToken, spaceID: String) -> Single<Bool> {
        return Single.create { single in
            let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
            permissionManager.getShareFolderUserPermissionRequest(spaceID: spaceID, token: folderToken) { permission, error in
                if let error = error {
                    single(.error(error))
                    return
                }
                guard let permission = permission else {
                    single(.error(MoreError.fetchFailed))
                    return
                }
                single(.success(permission.contains(.edit)))
            }
            // 没法取消权限请求
            return Disposables.create()
        }
    }

    // 通过 folderChildren 接口查询文件夹是否被删除、是否被封禁
    static func fetchFolderStatus(folderToken: FileListDefine.ObjToken, isV2Folder: Bool) -> Single<(deleted: Bool, complaint: Bool)> {
        let path: String
        if isV2Folder {
            path = OpenAPI.APIPath.childrenListV3
        } else {
            path = OpenAPI.APIPath.folderDetail
        }
        let request = DocsRequest<JSON>(path: path, params: ["token": folderToken])
            .set(method: .GET)
        return request.rxResponse()
            .map { data, _ in
                guard let json = data else {
                    throw MoreError.fetchFailed
                }
                let deleted: Bool
                let complaint: Bool
                if let code = json["code"].int {
                    deleted = (code == DocsNetworkError.Code.folderDeleted.rawValue)
                    || (code == DocsNetworkError.Code.notFound.rawValue)
                } else {
                    deleted = false
                }
                complaint = json["data"]["entities"]["nodes"][folderToken]["extra"]["complaint"].bool ?? false
                return (deleted, complaint)
            }
    }

    // 通过 FileInfo 接口查询 drive 文件大小，目前 FileInfo 其他字段暂时没用上，这里直接封装成 fileSize
    static func fetchFileSize(fileToken: FileListDefine.ObjToken) -> Single<Int64> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.fetchFileInfo,
                                        params: ["file_token": fileToken, "mount_point": DriveConstants.driveMountPoint]) // 暂时只考虑 space mount point
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        return request.rxStart().map { data in
            guard let json = data else {
                throw MoreError.fetchFailed
            }
            guard let size = json["data"]["size"].int64, size > 0 else {
                throw MoreError.fetchFailed
            }
            return size
        }
    }

    typealias AggregationInfoType = DocsInfoDetailHelper.AggregationInfoType
    typealias AggregationInfo = DocsInfoDetailHelper.AggregationInfo

    static func fetchAggregationInfo(item: SpaceItem, infoTypes: Set<AggregationInfoType>) -> Single<AggregationInfo> {
        DocsInfoDetailHelper.getAggregationInfo(token: item.objToken, objType: item.objType,
                                                infoTypes: infoTypes, scence: .listDetail)
            .map { result in
                switch result {
                case let .success(info),
                    let .partialSuccess(info):
                    return info
                case .allFailed,
                        .invalidParameter,
                        .fileNotFound,
                        .internalUnknownError:
                    DocsLogger.error("check is subscribed failed with result: \(result)")
                    throw MoreError.fetchFailed
                @unknown default:
                    DocsLogger.error("check is subscribed failed with unknown result")
                    throw MoreError.fetchFailed
                }
            }
    }

    static func fetchSubscribedStatus(item: SpaceItem) -> Single<Bool> {
        fetchAggregationInfo(item: item, infoTypes: [.isSubscribed]).map { info in
            guard let isSubscribed = info.isSubscribed else {
                throw MoreError.fetchFailed
            }
            return isSubscribed
        }
    }
    
    // 查询保留标签资格
    static func fetchRetentionEnable(token: String, docsType: DocsType) -> Single<Bool> {
        guard LKFeatureGating.retentionEnable else {
            DocsLogger.info("retention item featureGating state is closed")
            return .just(false)
        }
        guard let host = SettingConfig.retentionDomainConfig else {
            DocsLogger.warning("get retention domain config error")
            return .just(false)
        }
        let path = "https://" + host + OpenAPI.APIPath.retentionItemVisible
        let params: [String: Any] = ["token": token, "entityType": docsType.entityType]
        let request = DocsRequest<JSON>(url: path, params: params)
            .set(method: .GET)

        return request.rxStart()
            .map { result in
                guard let json = result else {
                    return false
                }

                guard let canSetRetentionLabel = json["data"]["data"]["canSetRetentionLabel"].bool else {
                    return false
                }
                return canSetRetentionLabel
            }
    }

    // 从 meta 接口获取文档名字，仅在对 shortcut 创建副本场景有用
    // meta 接口暂时只有这一个场景用到，后续如果其他场景需要复用，就拓展一下此方法
    static func fetchNameFromMeta(objToken: String, objType: DocsType) -> Single<String> {
        DocsInfoDetailHelper.fetchDetail(token: objToken, type: objType)
            .map { _, detailInfo in
                guard let title = detailInfo["title"] as? String else {
                    throw DocsInfoDetailError.parseDataFailed
                }
                return title
            }
    }
    // 获取spac列表的wiki本体的收藏状态
    static func fetchWikiStarStatus(wikiToken: String) -> Single<Bool> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getWikiInfoV2,
                                        params: ["wiki_token": wikiToken,
                                                 "need_star": true,
                                                 "expand_shortcut": true]).set(method: .GET)
        return request.rxStart().map { json in
            guard let isStar = json?["data"]["is_explorer_star"].bool else {
                return false
            }
            return isStar
        }
    }
}

private extension DocsType {
    // 仅用于文档保留标签设置接口取对应参数使用
    var entityType: String {
        switch self {
        case .doc:
            return "DOC"
        case .sheet:
            return "SHEET"
        case .bitable:
            return "BITABLE"
        case .mindnote:
            return "MINDNOTE"
        case .file:
            return "FILE"
        case .docX:
            return "DOCX"
        case .slides:
            return "SLIDES"
        default:
            DocsLogger.info("retention api can not support the DocsType")
            return ""
        }
    }
}

extension SpaceEntry {
    var userPermissionEntity: UserPermissionEntity {
        if let folderEntry = self as? FolderEntry {
            switch folderEntry.folderType {
            case .v2Common, .v2Shared, .unknown:
                return .folder(token: folderEntry.objToken)
            case .common:
                return .legacyFolder(info: SpaceV1FolderInfo(token: folderEntry.objToken,
                                                             folderType: .personal))
            case .share:
                guard let shareFolderInfo = folderEntry.shareFolderInfo else {
                    spaceAssertionFailure("failed to get shareFolderInfo from legacy folder entry")
                    return .legacyFolder(info: SpaceV1FolderInfo(token: folderEntry.objToken,
                                                                 folderType: .share(spaceID: "",
                                                                                    isRoot: false,
                                                                                    ownerID: folderEntry.ownerID)))
                }
                return .legacyFolder(info: SpaceV1FolderInfo(token: folderEntry.objToken,
                                                             folderType: .share(spaceID: shareFolderInfo.spaceID ?? "",
                                                                                isRoot: shareFolderInfo.shareRoot ?? false,
                                                                                ownerID: folderEntry.ownerID)))
            }
        } else if let wikiEntry = self as? WikiEntry,
                  let wikiInfo = wikiEntry.wikiInfo {
            // wiki 的鉴权、CAC 等逻辑需要用原始 token 和 type
            return .document(token: wikiInfo.objToken, type: wikiInfo.docsType)
        }
        return .document(token: objToken, type: type)
    }
}
