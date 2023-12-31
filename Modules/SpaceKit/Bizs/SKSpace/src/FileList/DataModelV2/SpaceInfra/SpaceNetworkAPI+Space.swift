//
//  SpaceNetworkAPI.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/6/22.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SpaceInterface
import SKInfra
import SKWorkspace

typealias SpaceItem = SpaceMeta

// Space 更新文档属性接口
extension SpaceNetworkAPI {

    static func rename(objToken: String, with newName: String) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.rename,
                                        params: ["token": objToken, "name": newName])
        return request.rxStart().flatMapCompletable { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                throw error
            }
            return .empty()
        }
    }

    static func renameV2(nodeToken: String, with newName: String) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.renameV2,
                                        params: ["token": nodeToken, "name": newName])
        return request.rxStart().flatMapCompletable { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                throw error
            }
            return .empty()
        }
    }

    static func move(nodeToken: FileListDefine.NodeToken, to destFolder: FileListDefine.NodeToken) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.move,
                                        params: ["src_token": nodeToken, "dest_token": destFolder])
        return request.rxStart().asCompletable()
    }

    static func moveV2(nodeToken: FileListDefine.NodeToken, to destFolder: FileListDefine.NodeToken) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.moveV2,
                                        params: ["src_token": [nodeToken], "dest_token": destFolder])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().asCompletable()
    }

    // 返回新创建的 shortcut 的 node token
    static func createShortCut(for item: SpaceItem, in destFolder: FileListDefine.NodeToken) -> Single<String> {
        let entities: [String: Any] = ["obj_token": item.objToken, "obj_type": item.objType.rawValue]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.addShortCutTo,
                                        params: ["parent_token": destFolder, "entities": [entities]])
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

    static func add(objToken: FileListDefine.ObjToken, to destFolder: FileListDefine.NodeToken) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.addTo,
                                        params: ["obj_token": objToken, "dest_token": destFolder])
        return request.rxStart().asCompletable()
    }

    /// v1 删除接口
    /// - Parameter item: 需要删除的 objToken 和 objType
    /// - Returns: 返回删除成功的 objTokens
    static func delete(item: SpaceItem) -> Single<[String]?> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.deleteByObjToken,
                                        params: ["obj_token": item.objToken, "obj_type": item.objType.rawValue])
        return request.rxStart().map { json -> [String]? in
            return json?["data"]["success_token"].arrayObject as? [String]
        }
    }

    /// 从文件夹移除文件接口
    /// - Parameter token: 被删除文件的 nodeToken，删除文件夹时，文件夹的 nodeToken 和 objToken 相同
    /// - Returns: 返回删除成功的 nodeToken
    static func removeFromFolder(nodeToken: FileListDefine.NodeToken) -> Single<[String]?> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.deleteFileInFolderByToken,
                                        params: ["token": nodeToken])
        return request.rxStart().map { json -> [String]? in
            return json?["data"]["success_token"].arrayObject as? [String]
        }
    }


    /// 从共享空间列表中移除文件接口。删除单容器文件时，后端虽然返回成功，但刷新后仍在列表中。在 v2 与我共享列表中，应该隐藏删除按钮
    /// - Returns: 需要删除的文件 objToken
    static func removeFromShareWithMeList(objToken: FileListDefine.ObjToken) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.deleteShareWithMeListFileByObjToken,
                                        params: ["obj_token": objToken])
        return request.rxStart().asCompletable()
    }

    /// v2 删除接口，注意只能删除文档原身，不能删除快捷方式、文件夹，目前只能用在文档内 More 菜单使用，若需要申请返回申请人信息
    /// - Parameter item: 需要删除的 objToken 和 objType
    static func deleteV2(item: SpaceItem, canApply: Bool) -> Maybe<AuthorizedUserInfo> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.deleteInDoc,
                                        params: [
                                            "obj_token": item.objToken,
                                            "obj_type": item.objType.rawValue,
                                            "apply": canApply ? 1 : 0
                                        ])
        return request.rxResponse()
            .compactMap { json, error in
                guard let json else {
                    throw error ?? DocsNetworkError.invalidData
                }
                guard let code = json["code"].int else {
                    DocsLogger.error("failed to parse code from delete in doc response")
                    throw error ?? DocsNetworkError.invalidData
                }
                if code == DocsNetworkError.Code.success.rawValue {
                    // 成功时，直接返回 nil 表示没有失败
                    return nil
                }

                if code == WikiErrorCode.operationNeedApply.rawValue {
                    let data = json["data"]
                    guard let userID = data["reviewer"].string else {
                        DocsLogger.error("missing required field for delete reviewer")
                        throw DocsNetworkError.invalidData
                    }
                    let userData = data["users"][userID]
                    guard let userName = userData["name"].string else {
                        DocsLogger.error("missing required field for delete reviewer")
                        throw DocsNetworkError.invalidData
                    }
                    let aliasInfo = UserAliasInfo(json: userData["display_name"])
                    let reviewerInfo = AuthorizedUserInfo(userID: userID, userName: userName, i18nNames: [:], aliasInfo: aliasInfo)
                    return reviewerInfo
                }

                if let error { throw error }
                // 其他错误，都直接抛出
                let message = json["msg"].stringValue
                guard var docsError = DocsNetworkError(code) else {
                    // 非 DocsNetworkError 识别的错误码
                    throw NSError(domain: message, code: code, userInfo: nil)
                }
                docsError.set(msg: message)
                throw docsError
            }
    }


    enum DeleteResponse {
        case success
        case partialFailed(entries: [SpaceEntry])
        case needApply(reviewer: AuthorizedUserInfo)
    }
    /// v2 删除接口，可以删原身、快捷方式和文件夹，适用于列表场景
    /// - Parameter nodeToken: 需要删除的 nodeToken
    /// - Returns: 无权限导致部分删除失败时，返回部分失败的文档信息
    static func deleteV2(nodeToken: FileListDefine.NodeToken,
                         canApply: Bool) -> Single<DeleteResponse> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.deleteV2,
                                        params: [
                                            "token": [nodeToken],
                                            "apply": canApply ? 1 : 0
                                        ])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false) // 设为 false 是为了自行处理 error 场景，解析出权限问题失败时，未成功删除的文档
        return request.rxData()
            .observeOn(SerialDispatchQueueScheduler(qos: .default)) // 可能包含数据解析逻辑，放在后台线程解析
            .map { responseData, _ in
                guard let responseData else { throw DocsNetworkError.invalidData }
                let json = JSON(responseData)
                guard let code = json["code"].int else {
                    DocsLogger.error("failed to parse code from deleteV2 response")
                    throw DocsNetworkError.invalidData
                }

                if code == DocsNetworkError.Code.success.rawValue {
                    // 全部成功时，直接返回 nil 表示没有失败
                    return .success
                }

                if code == WikiErrorCode.operationNeedApply.rawValue {
                    let data = json["data"]
                    guard let userID = data["reviewer"].string else {
                        DocsLogger.error("missing required field for delete reviewer")
                        throw DocsNetworkError.invalidData
                    }
                    let userData = data["users"][userID]
                    guard let userName = userData["name"].string else {
                        DocsLogger.error("missing required field for delete reviewer")
                        throw DocsNetworkError.invalidData
                    }
                    let aliasInfo = UserAliasInfo(json: userData["display_name"])
                    let reviewerInfo = AuthorizedUserInfo(userID: userID, userName: userName, i18nNames: [:], aliasInfo: aliasInfo)
                    return .needApply(reviewer: reviewerInfo)
                }

                guard code == DocsNetworkError.Code.forbidden.rawValue else {
                    // 除 forbidden 之外的其他错误，都直接抛出
                    let message = json["msg"].stringValue
                    guard var docsError = DocsNetworkError(code) else {
                        // 非 DocsNetworkError 识别的错误码
                        throw NSError(domain: message, code: code, userInfo: nil)
                    }
                    docsError.set(msg: message)
                    throw docsError
                }

                // 下面处理 forbidden 错误
                let dataParser = DataParser(json: json)
                let files = dataParser.getEntries()
                if files.isEmpty {
                    let message = json["msg"].stringValue
                    guard var docsError = DocsNetworkError(code) else {
                        // 非 DocsNetworkError 识别的错误码
                        throw NSError(domain: message, code: code, userInfo: nil)
                    }
                    docsError.set(msg: message)
                    throw docsError
                }
                // 返回部分失败的文档
                return .partialFailed(entries: files)
            }
            .observeOn(MainScheduler.instance) // 最终放回主线程
    }

    static func applyDelete(meta: SpaceMeta, reviewerID: String, reason: String?) -> Completable {
        var params: [String: Any] = [
            "obj_token": meta.objToken,
            "obj_type": meta.objType.rawValue,
            "reviewer": reviewerID
        ]
        if let reason, !reason.isEmpty {
            params["reason"] = reason
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.spaceApplyDelete,
                                        params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().asCompletable()
    }

    static func update(isFavorites: Bool, item: SpaceItem) -> Completable {
        let path = isFavorites ? OpenAPI.APIPath.addFavorites : OpenAPI.APIPath.removeFavorites
        // 两个接口的参数名不同
        let tokenKey = isFavorites ? "obj_token" : "token"
        let request = DocsRequest<JSON>(path: path,
                                        params: [
                                            tokenKey: item.objToken,
                                            "type": item.objType.rawValue
                                        ])
        return request.rxStart().asCompletable()
    }

    static func update(isSubscribe: Bool, subType: Int, item: SpaceItem) -> Completable {
        let path = isSubscribe ? OpenAPI.APIPath.addSubscribe : OpenAPI.APIPath.removeSubscribe
        let request = DocsRequest<JSON>(path: path,
                                        params: ["obj_token": item.objToken,
                                                 "obj_type": item.objType.rawValue,
                                                 "sub_type": subType])
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().asCompletable()
    }

    static func update(isPin: Bool, item: SpaceItem) -> Completable {
        let path = isPin ? OpenAPI.APIPath.addPins : OpenAPI.APIPath.removePins
        var params: [String: Any] = ["token": item.objToken, "type": item.objType.rawValue]
        if UserScopeNoChangeFG.WWJ.newSpaceTabEnable, isPin {
            params["pin_to_first"] = true
        }
        let request = DocsRequest<JSON>(path: path,
                                        params: params)
        return request.rxStart().asCompletable()
    }

    static func update(isHidden: Bool, folderToken: FileListDefine.NodeToken) -> Completable {
        let path = isHidden ? OpenAPI.APIPath.hideShareFolder : OpenAPI.APIPath.showShareFolder
        let request = DocsRequest<JSON>(path: path,
                                        params: ["token": folderToken])
            .set(method: .POST)
        return request.rxStart().asCompletable()
    }
    
    static func updateHiddenV2(isHidden: Bool, folderToken: FileListDefine.NodeToken) -> Completable {
        let path = isHidden ? OpenAPI.APIPath.hideShareFolderV2 : OpenAPI.APIPath.showShareFolderV2
        let request = DocsRequest<JSON>(path: path,
                                        params: ["token": folderToken])
            .set(method: .POST)
        return request.rxStart().asCompletable()
    }

    static func updateSecLabel(token: String, type: Int, id: String, reason: String) -> Completable {
        DocsLogger.info("begin update sec Label")
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.updateSecLabel,
                                        params: ["token": token,
                                                 "type": type,
                                                 "sec_label_id": id,
                                                 "change_reason": reason])
        return request.rxStart().flatMapCompletable { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                DocsLogger.error("update sec Label falid, json \(String(describing: json))")
                throw error
            }
            DocsLogger.info("update sec Label success")
            return .empty()
        }
    }

    static func getParentFolderToken(item: SpaceItem) -> Single<String> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getObjPath,
                                        params: [
                                            "obj_token": item.objToken,
                                            "obj_type": item.objType.rawValue,
                                            "need_path": false
                                        ])
            .set(method: .GET)
        return request.rxStart().map { json in
            guard let paths = json?["data"]["path"].arrayObject as? [String] else {
                throw DocsNetworkError.invalidData
            }
            guard paths.count >= 2 else {
                throw DocsNetworkError.forbidden
            }
            return paths[paths.count - 2]
        }
    }
}
