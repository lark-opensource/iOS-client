//
//  FolderListAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/10/25.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SpaceInterface
import SKInfra

// 子文件夹列表需要特别处理的 error
enum FolderListError: Error {
    case noPermission(ownerInfo: JSON?)
    case passwordRequired
    case folderDeleted
    case blockByTNS(info: TNSRedirectInfo)
}

protocol FolderListAPI {
    typealias ListError = FolderListError
    typealias SortOption = SpaceSortHelper.SortOption
    /// 拉取子文件夹列表
    static func queryList(folderToken: FileListDefine.ObjToken,
                          count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff>

    // 拉取共享文件夹列表的外部授权信息，仅 V1 共享文件夹才需要请求此接口，对 V2 无意义
    static func fetchExternalInfo(items: [SpaceItem]) -> Single<[FileListDefine.ObjToken: Bool]>
    // 申请文件夹权限
    static func requestPermission(folderToken: FileListDefine.ObjToken, message: String, roleToRequest: Int) -> Completable
}

extension FolderListAPI {
    static func queryList(folderToken: FileListDefine.ObjToken,
                          count: Int,
                          lastLabel: String? = nil,
                          sortOption: SortOption? = nil,
                          extraParams: [String: Any]? = nil) -> Single<FileDataDiff> {
        queryList(folderToken: folderToken, count: count, lastLabel: lastLabel, sortOption: sortOption, extraParams: extraParams)
    }
}

enum V1FolderListAPI: FolderListAPI {
    static func queryList(folderToken: FileListDefine.ObjToken,
                          count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = [
            "token": folderToken,
            "need_path": 1,
            "need_total": 1,
            "show_no_perm": 1,
            "length": count
        ]

        if UserScopeNoChangeFG.WWJ.ccmTNSParamsEnable {
            params["interflow_filter"] = "CLIENT_VARS"
        }

        if let lastLabel = lastLabel {
            params["last_label"] = lastLabel
        }

        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }

        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.folderDetail, params: params)
            .set(method: .GET)
        return request.rxResponse().observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { json, error in
                if let error = error {
                    if let docsError = error as? DocsNetworkError {
                        switch docsError.code {
                        case .forbidden:
                            if let permissionStatusCode = json?["data"]["permission_status_code"].int,
                               permissionStatusCode == DocsNetworkError.Code.passwordRequired.rawValue {
                                throw ListError.passwordRequired
                            }
                            throw ListError.noPermission(ownerInfo: json?["meta"]["owner"])
                        case .folderDeleted:
                            throw ListError.folderDeleted
                        default:
                            throw docsError
                        }
                    } else {
                        throw error
                    }
                }
                guard let json = json else {
                    throw NSError(domain: "request.space.sub-folder", code: -1, userInfo: ["des": "sub-folder data empty in fetch response"])
                }
                let dataDiff = DataBuilder.getFolderData(from: json, parent: folderToken)
                return dataDiff
            }
            .observeOn(MainScheduler.instance)
    }

    static func fetchExternalInfo(items: [SpaceItem]) -> Single<[FileListDefine.ObjToken: Bool]> {
        let objInfos = items.map { item -> [String: Any] in
            ["type": item.objType.rawValue, "token": item.objToken]
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.fileExternalHint, params: ["objs": objInfos])
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { data in
                guard let json = data else {
                    throw NSError(domain: "request.folder-external.space", code: -1, userInfo: ["des": "fetch external status found empty in fetch response"])
                }
                guard let externalInfo = json["data"].dictionaryObject as? [FileListDefine.ObjToken: Bool] else {
                    return [:]
                }
                return externalInfo
            }
    }

    static func requestPermission(folderToken: FileListDefine.ObjToken, message: String, roleToRequest: Int) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.folderPermission, params: ["token": folderToken, "message": message])
        return request.rxStart().asCompletable()
    }
}

enum V2FolderListAPI: FolderListAPI {
    static func queryList(folderToken: FileListDefine.ObjToken,
                          count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        var params: [String: Any] = [
            "token": folderToken,
            "length": count
        ]

        if UserScopeNoChangeFG.WWJ.ccmTNSParamsEnable {
            params["interflow_filter"] = "CLIENT_VARS"
        }

        if let lastLabel = lastLabel {
            params["last_label"] = lastLabel
        }

        if let sortParams = sortOption?.sortParams {
            params = params.merging(sortParams, uniquingKeysWith: { $1 })
        }

        if let extraParams = extraParams {
            params = params.merging(extraParams, uniquingKeysWith: { $1 })
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.childrenListV3, params: params)
            .set(method: .GET)
            // TNS 错误码不是 CCM 的 data 格式，要关掉这个
            .set(needVerifyData: false)
        return request.rxResponse().observeOn(SerialDispatchQueueScheduler(qos: .default))
            .flatMap { json, error -> Single<FileDataDiff> in
                guard let json else {
                    throw error ?? NSError(domain: "request.space.sub-folder", code: -1, userInfo: ["des": "sub-folder data empty in fetch response"])
                }
                let serverError: Error?
                if let error {
                    serverError = error
                } else {
                    guard let code = json["code"].int else {
                        throw DocsNetworkError.invalidData
                    }
                    if let errorCode = DocsNetworkError.Code(rawValue: code),
                       let error = DocsNetworkError(errorCode.rawValue) {
                        serverError = error
                    } else {
                        serverError = nil
                    }
                }

                if let error = serverError {
                    if let docsError = error as? DocsNetworkError {
                        switch docsError.code {
                        case .forbidden:
                            return checkCanApplyPermission(token: folderToken).map { throw $0 }
                        case .folderDeleted:
                            throw ListError.folderDeleted
                        case .tnsCrossBrandBlocked:
                            guard let url = json["url"].url else {
                                DocsLogger.error("failed to get url from tns blocked response")
                                throw docsError
                            }
                            let info = TNSRedirectInfo(meta: SpaceMeta(objToken: folderToken, objType: .folder),
                                                       redirectURL: url,
                                                       module: "folder",
                                                       appForm: .standard)
                            throw ListError.blockByTNS(info: info)
                        default:
                            throw docsError
                        }
                    } else {
                        throw error
                    }
                }

                let dataDiff = DataBuilder.getFolderData(from: json, parent: folderToken)
                return .just(dataDiff)
            }
            .observeOn(MainScheduler.instance)
    }
    
    private static func checkCanApplyPermission(token: FileListDefine.ObjToken) -> Single<FolderListError> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getShareFolderUserPermission,
                                        params: ["token": token, "actions": ["view"]])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        return request.rxStart().map { data -> FolderListError in
            guard let json = data else { return .noPermission(ownerInfo: nil) }
            guard let code = json["code"].int,
                  code == OpenAPI.ServerErrorCode.noPermission.rawValue else {
                      return .noPermission(ownerInfo: nil)
                  }
            if let permissionStatusCode = json["data"]["permission_status_code"].int,
               permissionStatusCode == DocsNetworkError.Code.passwordRequired.rawValue {
                return .passwordRequired
            }
            let ownerJSON = json["meta"]["owner"]
            guard let canApply = ownerJSON["can_apply_perm"].bool,
                  canApply else {
                      return .noPermission(ownerInfo: nil)
                  }
            return .noPermission(ownerInfo: ownerJSON)
        }
    }
    
    // V2 共享文件夹请求此接口无意义
    static func fetchExternalInfo(items: [SpaceItem]) -> Single<[FileListDefine.ObjToken: Bool]> {
        .just([:])
    }
    // V2 共享文件夹申请权限由 PermissionManager 处理
    static func requestPermission(folderToken: FileListDefine.ObjToken, message: String, roleToRequest: Int) -> Completable {
        Single<Void>.create { single in
            let request = PermissionManager.applyFolderPermission(token: folderToken, permRole: roleToRequest, message: message) { _, error in
                if let error = error {
                    single(.error(error))
                } else {
                    single(.success(()))
                }
            }
            return Disposables.create {
                request.cancel()
            }
        }.asCompletable()
    }
    
    static func reportViewFolder(token: String) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.spaceOpenReport,
                                        params: ["obj_token": token, "obj_type": DocsType.folder.rawValue])
            .set(method: .POST)
        
        return request.rxStart().asCompletable()
    }
}
