//
//  PermissionManager+SingleContainerFolder.swift
//  SKCommon
//
//  Created by CJ on 2021/6/30.
//
//  swiftlint:disable file_length

import Foundation
import SwiftyJSON
import HandyJSON
import ThreadSafeDataStructure
import SKFoundation
import SpaceInterface
import SKInfra

// MARK: - 单容器版本协议
extension PermissionManager {
    // nolint: duplicated_code
    /// 获取v2文件夹公共权限
    public func requestV2FolderPublicPermissions(
        token: String,
        type: Int,
        complete: ((PublicPermissionMeta?, Error?) -> Void)? = nil) {
        let path = OpenAPI.APIPath.getShareFolderPublicPermissionV2
        let request = DocsRequest<JSON>(path: path + "?token=\(token)&type=\(type)", params: nil)
            .set(method: .GET)
            .set(timeout: 20)
            .makeSelfReferenced()
        request.start(callbackQueue: callbackQueue) { [weak self] (json, error) in
            guard let self else { return }
            guard let json = json,
                  let code = json["code"].int else {
                DocsLogger.error("fetch share folder public permission failed, json or code is nil", error: error)
                DispatchQueue.main.async { complete?(nil, error) }
                return
            }
            let data = json["data"]

            let permissionMeta = PublicPermissionMeta(v2FolderJson: data)
            guard code == 0, !data.isEmpty, let publicPermissionMeta = permissionMeta else {
                DocsLogger.warning("fetch share folder public permission failed, code is not equal 0 or data is nil", error: error)
                DispatchQueue.main.async { complete?(nil, error) }
                return
            }
            self.updatePublicPermissionMetas([token: publicPermissionMeta])
            DispatchQueue.main.async { complete?(publicPermissionMeta, nil) }
        }
    }
    // enable-lint: duplicated_code
    /// 更新共享文件夹公共权限
    /// - Parameters:
    ///   - token: 文件夹token
    ///   - externalAccess: 对外分享开关
    ///   - linkShareEntity: 链接分享选项
    ///   - complete: 结果回调
    /// - Returns:
    public static func updateV2FolderPublicPermissions(
        token: String,
        type: Int,
        params: [String: Any],
        complete: @escaping (Bool?, Error?, JSON?) -> Void) -> DocsRequest<JSON> {
        var requestParams: [String: Any] = ["token": token,
                                     "type": type]
        requestParams.merge(other: params)
        return DocsRequest<JSON>(path: OpenAPI.APIPath.updateShareFolderPublicPermissionV2, params: requestParams)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int else {
                    DocsLogger.error("update share folder public permissions failed", error: error, component: LogComponents.permission)
                    complete(nil, error, json)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("update share folder public permissions failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(nil, error, json)
                    return
                }
                complete(true, nil, json)
                DocsLogger.info("update share folder public permissions success", component: LogComponents.permission)
            }
    }

    /// 获取共享文件夹用户权限
    /// - Parameters:
    ///   - token: 共享文件夹token
    ///   - actions: 要查询权限集合["view", "edit", "invite", "create"]，传[]，获取所有点位
    ///   - complete: 请求回来调用的 completion block
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func requestShareFolderUserPermission(
        token: String,
        actions: [UserPermissionEnum],
        complete: @escaping (ShareFolderV2UserPermission?, Error?) -> Void) {
        let paramsActions = actions.map { $0.rawValue }
        let params: [String: Any] = ["token": token,
                                     "actions": paramsActions]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getShareFolderUserPermission, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .makeSelfReferenced()

        request.start { [weak self] (json, error) in
            guard let self else { return }
            guard let result = json,
                  let code = result["code"].int else {
                DocsLogger.error("request share folder user permission failed", error: error, component: LogComponents.permission)
                DispatchQueue.main.async { complete(nil, error) }
                return
            }
            guard code == 0 else {
                DocsLogger.error("request share folder user permission failed, code is \(code)", error: error, component: LogComponents.permission)
                DispatchQueue.main.async { complete(nil, error) }
                return
            }
            let permissions = ShareFolderV2UserPermission(json: result)
            let permissionDict = [token: permissions]
            self.updateUserPermissions(permissionDict)
            DocsLogger.info("request share folder user permission success", component: LogComponents.permission)
            DispatchQueue.main.async { complete(permissions, nil) }
        }
    }

    /// 获取共享文件夹协作者
    /// - Parameters:
    ///   - token: 共享文件夹token
    ///   - lastPageLabel: 分页cursor
    ///   - complete: 请求回调
    /// - Returns:
    public func requestShareFolderCollaborators(
        token: String,
        shouldFetchNextPage: Bool = false,
        lastPageLabel: String? = nil,
        complete: ((CollaboratorResponse?, Error?) -> Void)? = nil) {
        var path = OpenAPI.APIPath.getShareFolderCollaborators + "?token=\(token)"
        if let lastPageLabel = lastPageLabel {
            path = "\(path)&last_label=\(lastPageLabel.urlEncoded())"
        }
        let augToken = augmentedToken(of: token)
        let request = DocsRequest<JSON>(path: path, params: nil)
            .set(method: .GET)
            .set(encodeType: .urlEncodeAsQuery)
            .set(timeout: 20)
            .makeSelfReferenced()
        request.start(callbackQueue: callbackQueue, result: { [weak self] json, error in
            guard let dict = json?.dictionaryObject,
                  let data = dict["data"] as? [String: Any],
                  let hasMore = data["has_more"] as? Bool,
                  let collaboratorsDict = data["collaborators"] as? [[String: Any]]
            else {
                DocsLogger.error("request share folder collaborators error", error: error, component: LogComponents.permission)
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }

            var items = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: true, isNewVersion: true)
            if let entities = data["entities"] as? [String: Any], let users = entities["users"] as? [String: [String: Any]] {
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.insert(users: users)
                Collaborator.localizeCollaboratorName(collaborators: &items, users: users)
                Collaborator.permissionStatistics(collaborators: &items, users: users)
            }
            self?.collaboratorStore.updateCollaborators(for: augToken, items)
            let thisPageLabel = data["last_label"] as? String // 如果是 nil，则代表该文件的协作者数量小于等于 50 个；否则需要业务通过 shouldFetchNextPage 明确是否需要继续请求剩余协作者
            let isFileOwnerFromAnotherTenant = data["is_external"] as? Bool ?? false
            let collaboratorCount = data["total_num"] as? Int ?? 1 // 1 是因为文件的 owner 一定是协作者
            DocsLogger.info("fetchShareFolderCollaborators items count = \(items.count), total_count = \(collaboratorCount), last_label = \(thisPageLabel)")
            if shouldFetchNextPage, hasMore { // 说明还有下一页，而且外部要求继续请求剩余协作者
                self?.requestShareFolderCollaborators(token: token, shouldFetchNextPage: true, lastPageLabel: thisPageLabel, complete: complete)
            } else {
                DispatchQueue.main.async { complete?((collaboratorCount, isFileOwnerFromAnotherTenant, thisPageLabel), nil) }
            }
        })
    }

    /// 文件夹(普通+共享)添加协作者
    /// - Parameters:
    ///   - token: 文件夹token
    ///   - candidates: 新添加的协作者的候选集合
    ///   - containPermssion: 请求头是否包含权限数值
    ///   - sendLarkIm: 是否IM内通知被邀请人
    ///   - larkIMText: 通知的留言
    ///   - complete: 请求回来调用的 completion block
    public static func inviteCollaboratorForFolder(
        token: String,
        candidates: Set<Collaborator>,
        botNotify: Bool = false,
        note: String?,
        complete: @escaping ((Bool, JSON?)?, Error?) -> Void) -> DocsRequest<(Bool, JSON?)> {
        var collaborators = [[String: Any]]()
        candidates.forEach { (collaborator) in
            if let type = collaborator.type {
                var dic: [String: Any] = ["collaborator_id": collaborator.userID, "collaborator_type": type.rawValue]
                dic["perm_role"] = collaborator.userPermissions.permRoleValue
                collaborators.append(dic)
            } else {
                spaceAssertionFailure()
                DocsLogger.error("不支持的邀请类型")
            }
        }
        var parameters = ["need_notify": botNotify, "collaborators": collaborators] as [String: Any]
        if let note = note {
            parameters["notify_text"] = note
        }
        parameters.updateValue(token, forKey: "token")
        return DocsRequest<(Bool, JSON?)>(path: OpenAPI.APIPath.addFolderCollaborator, params: parameters)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .set(transform: { (json) -> (result: (Bool, JSON?), error: Error?) in
                guard let code = json?["code"].int else {
                    DocsLogger.error("invite collaborator for folder failed, code is nil", component: LogComponents.permission)
                    return ((false, json), CollaboratorsError.parseError)
                }
                if DocsNetworkError.isSuccess(code) {
                    return ((true, json), nil)
                }
                DocsLogger.error("invite collaborator for folder failed, code is \(code)", component: LogComponents.permission)
                // DocsNetworkError.invalidData。意味着这个 Code 没有带回来，或者是一个新的 Code
                return ((false, json), DocsNetworkError(json?["code"].int) ?? DocsNetworkError.invalidData)
            })
            .start(result: complete)
    }

    /// 更新共享文件夹协作者权限
    /// - Parameters:
    ///   - token: 文件夹的 token
    ///   - memberId: 协作者ID
    ///   - memberType: 协作者类型
    ///   - permRole: 角色类型
    ///   - complete: 回调
    /// - Returns:
    public static func updateShareFolderCollaboratorPermission(
        token: String,
        collaboratorId: String,
        collaboratorType: Int,
        permRole: Int,
        complete:  @escaping (JSON?, Error?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token,
                                     "collaborator_id": collaboratorId,
                                     "collaborator_type": collaboratorType,
                                     "perm_role": permRole]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.updateShareFolderCollaboratorPermission, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (response, error) in
                DispatchQueue.main.async {
                    complete(response, error)
                }
            })
    }

    /// 删除共享文件夹协作者权限
    /// - Parameters:
    ///   - token: 文件夹的 token
    ///   - memberId: 协作者ID
    ///   - memberType: 协作者类型
    ///   - complete: 回调
    /// - Returns:
    public static func deleteShareFolderCollaborator(
        token: String,
        collaboratorId: String,
        collaboratorType: Int,
        complete: @escaping (Bool?, Error?, JSON?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token,
                                     "collaborator_id": collaboratorId,
                                     "collaborator_type": collaboratorType]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.deleteShareFolderCollaborator, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int else {
                    complete(false, error, json)
                    DocsLogger.error("delete share folder collaborator failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("delete share folder collaborator failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, error, json)
                    return
                }
                DocsLogger.info("delete share folder collaborator success", component: LogComponents.permission)
                complete(true, nil, json)
            }
    }

    /// 转移文件夹的权限
    /// - Parameters:
    ///   - token: 文件夹的 token
    ///   - memberId: 协作者ID
    ///   - memberType: 协作者类型
    ///   - complete: 回调
    public static func transferShareFolderOwner(
        token: String,
        collaboratorId: String,
        transferAllFile: Bool,
        complete: @escaping (_ success: Bool, _ cacBlocked: Bool, _ error: Error?, _ json: JSON?) -> Void) -> DocsRequest<JSON> {
        var params = [String: Any]()
        params["token"] = token
        params["collaborator_id"] = collaboratorId
        params["recursive_transfer"] = transferAllFile ? true : false
        return DocsRequest<JSON>(path: OpenAPI.APIPath.transferShareFolderOwner, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int else {
                    complete(false, false, error, json)
                    DocsLogger.error("transfer share folder owner failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("transfer share folder owner failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, false, error, json)
                    return
                }
                var success = (code == 0)
                let cacBlocked = transferShareFolderOwnerCacBlocked(json: result)
                if cacBlocked {
                    success = false
                }
                DocsLogger.info("transfer share folder owner complete, success \(success),  code \(code), cacBlocked \(cacBlocked) ", component: LogComponents.permission)
                complete(success, cacBlocked, error, json)
            }
    }
    
    
    private static func transferShareFolderOwnerCacBlocked(json: JSON) -> Bool {
        guard let userfailMaps = json["data"]["fail_map"].dictionary else { return false }
        let userIDs = userfailMaps.compactMap { userID, reasonValue -> String? in
            guard reasonValue.int == 2002 || reasonValue.string == "2002" else { return nil }
            return userID
        }
        return userIDs.count > 0
    }
    

    public static func applyFolderPermission(
        token: String,
        permRole: Int,
        message: String,
        complete: @escaping (Bool?, Error?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token,
                                     "perm_role": permRole,
                                     "message": message]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.applyFolderPermission, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int else {
                    complete(false, error)
                    DocsLogger.error("apply folder permission failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("apply folder permission failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, error)
                    return
                }
                DocsLogger.info("apply folder permission success", component: LogComponents.permission)
                complete(true, nil)
            }
    }

    /// 共享文件夹解锁
    /// - Parameters:
    ///   - token: 文件夹的 token
    ///   - complete: 请求回来调用的 completion block
    public static func unlockShareFolder(
        token: String,
        complete: @escaping (Bool?, Error?) -> Void) -> DocsRequest<Bool> {
        var params = [String: Any]()
        params["token"] = token
        return DocsRequest<Bool>(path: OpenAPI.APIPath.unlockShareFolder, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .set(transform: { (json) -> (Bool?, error: Error?) in
                guard let json = json,
                      let code = json["code"].int,
                      code == 0 else {
                    let error = NSError(domain: "docs.unlock.sharefolder.failed ", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: ""])
                    DocsLogger.warning("unlock share folder failed", error: error, component: LogComponents.permission)
                    return (false, error)
                }
                DocsLogger.warning("unlock share folder success", component: LogComponents.permission)
                return (true, nil)
            })
            .start(result: complete)
    }

    /// 判断共享文件夹修改公共权限是否触发加锁
    /// - Parameters:
    ///   - token: 文件夹token
    ///   - externalAccess: 对外分享开关
    ///   - linkShareEntity: 链接分享选项
    ///   - complete: 回调
    public static func checkLockByUpdateShareFolderPublicPermission(
        token: String,
        externalAccess: Bool? = nil,
        externalAccessEntity: Int? = nil,
        linkShareEntity: Int? = nil,
        linkShareEntityV2: Int? = nil,
        complete: @escaping (_ success: Bool, _ needLock: Bool, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        var params: [String: Any] = ["token": token]
        if let linkShareEntity = linkShareEntity {
            params["link_share_entity"] = linkShareEntity
        }
        if let linkShareEntityV2 = linkShareEntityV2 {
            params["link_share_entity_v2"] = linkShareEntityV2
        }
        if let externalAccess = externalAccess {
            params["external_access"] = externalAccess
        }
        if let externalAccessEntity = externalAccessEntity {
            params["external_access_entity"] = externalAccessEntity
        }
        return DocsRequest<JSON>(path: OpenAPI.APIPath.checkLockByUpdateShareFolderPublicPermission, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int,
                      let data = result["data"].dictionaryObject else {
                    complete(false, false, json)
                    DocsLogger.error("check lock by update share folder public permission failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("check lock by update share folder public permission failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, false, json)
                    return
                }
                DocsLogger.info("check lock by update share folder public permission success", component: LogComponents.permission)
                let needLock = data["need_lock"] as? Bool ?? false
                complete(true, needLock, json)
            }
    }

    /// 判断共享文件夹更新协作者权限是否触发加锁
    /// - Parameters:
    ///   - token: 文件夹的 token
    ///   - memberId: 协作者ID
    ///   - memberType: 协作者类型
    ///   - permRole: 角色类型
    ///   - complete: 回调
    public static func checkLockByUpdateShareFolderCollaboratorPermission(
        token: String,
        collaboratorId: String,
        collaboratorType: Int,
        permRole: Int,
        complete: @escaping (_ success: Bool, _ needLock: Bool, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token,
                                     "collaborator_id": collaboratorId,
                                     "collaborator_type": collaboratorType,
                                     "perm_role": permRole]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.checkLockByUpdateShareFolderCollaboratorPermission, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int,
                      let data = result["data"].dictionaryObject else {
                    complete(false, false, json)
                    DocsLogger.error("check lock by update share folder collaborator permission failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("check lock by update share folder collaborator permission failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, false, json)
                    return
                }
                DocsLogger.info("check lock by update share folder collaborator permission success", component: LogComponents.permission)
                let needLock = data["need_lock"] as? Bool ?? false
                complete(true, needLock, json)
            }
    }

    /// 判断共享文件夹删除协作者是否触发加锁
    /// - Parameters:
    ///   - token: 文件夹的 token
    ///   - memberId: 协作者ID
    ///   - memberType: 协作者类型
    ///   - permRole: 角色类型
    ///   - complete: 回调
    public static func checkLockByDeleteShareFolderCollaborator(
        token: String,
        collaboratorId: String,
        collaboratorType: Int,
        complete: @escaping (_ success: Bool, _ needLock: Bool, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token,
                                     "collaborator_id": collaboratorId,
                                     "collaborator_type": collaboratorType]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.checkLockByDeleteShareFolderCollaborator, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int,
                      let data = result["data"].dictionaryObject else {
                    complete(false, false, json)
                    DocsLogger.error("check lock by delete share folder collaborator failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("check lock by delete share folder collaborator failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, false, json)
                    return
                }
                DocsLogger.info("check lock by delete share folder collaborator success", component: LogComponents.permission)
                let needLock = data["need_lock"] as? Bool ?? false
                complete(true, needLock, json)
            }
    }

    /// 创建密码
    /// - Parameters:
    ///   - token: 文件夹token
    ///   - type: 文件夹type
    ///   - complete: 回调
    /// - Returns:
    public static func createPasswordForShareFolder(
        token: String,
        type: Int,
        complete: @escaping (_ success: Bool, _ password: String?, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token, "type": type]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.createPasswordForShareFolder, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int,
                      let data = result["data"].dictionaryObject else {
                    complete(false, "", json)
                    DocsLogger.error("create password for share folder failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("create password for share folder failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, "", json)
                    return
                }
                DocsLogger.info("create password for share folder success", component: LogComponents.permission)
                let password = data["password"] as? String ?? ""
                complete(true, password, json)
            }
    }

    /// 刷新密码
    /// - Parameters:
    ///   - token: 文件夹token
    ///   - type: 文件夹type
    ///   - complete: 回调
    /// - Returns:
    public static func refreshPasswordForShareFolder(
        token: String,
        type: Int,
        complete: @escaping (_ success: Bool, _ password: String?, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token, "type": type]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.refreshPasswordForShareFolder, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int,
                      let data = result["data"].dictionaryObject else {
                    complete(false, "", json)
                    DocsLogger.error("refresh password for share folder failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("refresh password for share folder failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, "", json)
                    return
                }
                DocsLogger.info("refresh password for share folder success", component: LogComponents.permission)
                let password = data["password"] as? String ?? ""
                complete(true, password, json)
            }
    }

    /// 验证密码
    /// - Parameters:
    ///   - token: 文件夹token
    ///   - type: 文件夹type
    ///   - password: password
    ///   - complete: 回调
    /// - Returns:
    public static func inputPasswordForShareFolder(
        token: String,
        type: Int,
        password: String,
        complete: @escaping (_ success: Bool, _ code: Int, _ error: Error?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token,
                                     "type": type,
                                     "password": password]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.inputPasswordForShareFolder, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int else {
                    complete(false, -1, error)
                    DocsLogger.error("input password for share folder failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("input password for share folder failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, code, error)
                    return
                }
                DocsLogger.info("input password for share folder success", component: LogComponents.permission)
                complete(true, code, error)
            }
    }

    /// 删除密码
    /// - Parameters:
    ///   - token: 文件夹token
    ///   - type: 文件夹type
    ///   - complete: 回调
    /// - Returns:
    public static func deletePasswordForShareFolder(
        token: String,
        type: Int,
        complete: @escaping (_ success: Bool, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token, "type": type]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.deletePasswordForShareFolder, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start { json, error in
                guard let result = json,
                      let code = result["code"].int else {
                    complete(false, json)
                    DocsLogger.error("delete password for share folder failed", error: error, component: LogComponents.permission)
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("delete password for share folder failed, code is \(code)", error: error, component: LogComponents.permission)
                    complete(false, json)
                    return
                }
                DocsLogger.info("delete password for share folder success", component: LogComponents.permission)
                complete(true, json)
            }
    }

    /// 批量查询用户是否已经是文件夹协作者
    /// - Parameters:
    ///   - type: 文件夹类型
    ///   - token: 文件夹的 objToken
    ///   - candidates: 协作者的候选集合
    ///   - complete: 请求回来调用的 completion block
    static func batchQueryCollaboratorsExistForFolder(
        token: String?,
        candidates: Set<Collaborator>,
        complete:  @escaping ([Collaborator]?, Error?) -> Void) -> DocsRequest<JSON> {
        var dictionary = [[String: Any]]()
        dictionary = Array(candidates).map {
            return ["collaborator_id": $0.userID, "collaborator_type": $0.rawValue]
        }
        var parameters: [String: Any] = ["collaborators": dictionary]
        if let token = token {
            parameters.merge(other: ["token": token])
        }
        return DocsRequest<JSON>(path: OpenAPI.APIPath.collaboratorsExistForShareFolder, params: parameters)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: 20)
            .start(result: { (json, error) in
                guard error == nil else {
                    DocsLogger.error("batch query collaborators exist for folder failed!", extraInfo: nil, error: error, component: nil)
                    DispatchQueue.main.async {
                        complete(nil, CollaboratorsError.networkError)
                    }
                    return
                }
                guard let json = json,
                      let dict = json.dictionaryObject,
                      let data = dict["data"] as? [String: Any],
                      let collaboratorsDict = data["existed_collaborators"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        complete(nil, CollaboratorsError.parseError)
                    }
                    return
                }
                let items = Collaborator.existCollaboratorsForFolder(collaboratorsDict)
                DispatchQueue.main.async {
                    complete(items, nil)
                }
            })
    }
}
