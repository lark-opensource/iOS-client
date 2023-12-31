//
// Created by duanxiaochen.7 on 2020/6/7.
// Affiliated with SpaceKit.
//
// Description:

import Foundation
import SwiftyJSON
import HandyJSON
import ThreadSafeDataStructure
import SKFoundation
import SKInfra

extension PermissionManager {
    // nolint: duplicated_code
    /// 旧共享文件夹获取公共权限
    /// - Parameters:
    ///   - spaceID: 共享文件夹的 spaceID
    ///   - complete: 请求回来调用的 completion block
    public func getOldShareFolderPublicPermissionsRequest(
        spaceID: String,
        token: String,
        complete: @escaping (_ shareFolderPermissionMeta: PublicPermissionMeta?, Error?) -> Void) {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionShareSpaceSet + "?space_id=\(spaceID)", params: nil)
            .set(method: .GET)
            .set(timeout: 20)
            .makeSelfReferenced()
        request.start(callbackQueue: callbackQueue) { [weak self] (json, error) in
            guard let self else { return }
            guard let json = json,
                  let code = json["code"].int else {
                DocsLogger.warning("fetch publicPermissions failed with error", error: error)
                DispatchQueue.main.async { complete(nil, error) }
                return
            }
            let data = json["data"]
            guard code == 0, !data.isEmpty, let publicPermissionMeta = PublicPermissionMeta(shareFolderJSON: data) else {
                DocsLogger.warning("fetch publicPermissions failed with error", error: error)
                DispatchQueue.main.async { complete(nil, error) }
                return
            }
            if publicPermissionMeta != self.getPublicPermissionMeta(token: token) {
                self.updatePublicPermissionMetas([token: publicPermissionMeta])
            }
            DispatchQueue.main.async { complete(publicPermissionMeta, nil) }
        }
    }
    // enable-lint: magic number

    /// 查询成员对共享文件夹权限
    /// - Parameters:
    ///   - spaceID: 共享文件夹的 spaceID
    ///   - complete: 请求回来调用的 completion block
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func getShareFolderUserPermissionRequest(
        spaceID: String,
        token: String,
        complete: @escaping (UserPermissionMask?, Error?) -> Void) {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionShareSpaceCollaboratorPerm, params: ["space_id": spaceID])
            .set(method: .GET)
            .set(timeout: 20)
            .makeSelfReferenced()
        request.start(callbackQueue: callbackQueue) { [weak self] (json, _) in
            guard let self else { return }
            guard let result = json,
                  let code = result["code"].int,
                  code == 0
            else {
                DispatchQueue.main.async { complete(nil, DocsNetworkError.invalidData) }
                return
            }
            let data = result["data"]
            if let permissionsRaw = data["perm"].int {
                let permissions = UserPermissionMask.create(withPermRole: permissionsRaw)
                let permissionDict = [token: permissions]
                self.updateUserPermissions(permissionDict)
                DispatchQueue.main.async { complete(permissions, nil) }
                return
            } else { // 无权限处理
                let permissions: UserPermissionMask = []
                let permissionDict = [token: permissions]
                self.updateUserPermissions(permissionDict)
                DispatchQueue.main.async { complete([], nil) }
                return
            }
        }
    }


    /// 转移文件夹的权限
    /// - Parameters:
    ///   - spaceId: 共享文件夹的 spaceID
    ///   - ownerType: 新的 owner 的类型
    ///   - ownerID: 新的 owner 的 userID
    ///   - transferAllFile: 同时转移文件夹下的所有文档的所有者
    ///   - finish: 请求回来调用的 completion block
    static func transferOldFolderOwnerRequest(spaceId: String,
                                           ownerType: Int,
                                           ownerID: String,
                                           transferAllFile: Bool,
                                           finish: @escaping (_ code: Int, _ success: Bool, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        var params = [String: Any]()
        params["space_id"] = spaceId
        params["owner_id"] = ownerID
        params["owner_type"] = ownerType
        params["recursive_transfer"] = transferAllFile ? true : false
        let path = OpenAPI.APIPath.suitePermissionTransferFolderOwner
        return DocsRequest<JSON>(path: path, params: params)
            .set(timeout: 20)
            .set(encodeType: .urlEncodeDefault)
            .set(needVerifyData: false)
            .start(result: { (result, error) in
            guard error == nil else {
                finish(-1, false, result)
                return
            }
            let code = result?["code"].int ?? -1
            finish(code, code == 0, result)
        })
    }

    static func updateOldShareFolderCollaboratorPermissionRequest(
        params: [String: Any],
        complete: @escaping (JSON?, Error?) -> Void) -> DocsRequest<JSON> {
        return  DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionShareSpaceCollaboratorUpdate,
                                  params: params)
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (response, error) in
                DispatchQueue.main.async {
                    complete(response, error)
                }
            })
    }
    
    public static func updateOldShareFolderPublicPermissionRequest(
        params: [String: Any],
        complete: @escaping (JSON?, Error?) -> Void) -> DocsRequest<JSON> {
        return  DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionShareSpaceSetUpdate,
                                  params: params)
            .set(method: .POST)
            .set(needVerifyData: false)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (response, error) in
                DispatchQueue.main.async {
                    complete(response, error)
                }
            })
    }
}

extension PermissionManager {
    /// 邀请文件夹(文件夹和旧共享文件夹)的协作者
    /// - Parameters:
    ///   - spaceID: 共享文件夹的 spaceID
    ///   - token: 文件夹的 objToken
    ///   - candidates: 新添加的协作者的候选集合
    ///   - containPermssion: 请求头是否包含权限数值
    ///   - sendLarkIm: 是否IM内通知被邀请人
    ///   - larkIMText: 通知的留言
    ///   - complete: 请求回来调用的 completion block
    static func addFolderCollaboratorsRequest(
        spaceID: String?,
        token: String,
        candidates: Set<Collaborator>,
        containPermssion: Bool = false,
        sendLarkIm: Bool,
        larkIMText: String?,
        complete: @escaping ((Bool, JSON?)?, Error?) -> Void) -> DocsRequest<(Bool, JSON?)> {
        var dictionary = [[String: Any]]()
        candidates.forEach { (collaborator) in
            if let type = collaborator.type, let spaceType = Collaborator.explorerSpaceType(type: type) {
                var dic: [String: Any] = ["id": collaborator.userID, "type": spaceType]
                if containPermssion {
                    dic["perm"] = collaborator.userPermissions.permRoleValue
                }
                dictionary.append(dic)
            } else {
                spaceAssertionFailure()
                DocsLogger.error("不支持的邀请类型")
            }
        }
        let collaboratorString: String
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            collaboratorString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch _ {
            collaboratorString = ""
        }
        var parameters = ["need_notify": 0, "owners": collaboratorString, "send_lark_im": sendLarkIm] as [String: Any]
        if let spaceID = spaceID, !spaceID.isEmpty {
            parameters.updateValue(spaceID, forKey: "space_id")
        }
        if let larkIMText = larkIMText {
            parameters["lark_im_text"] = larkIMText
        }
        parameters.updateValue(token, forKey: "token")
        return DocsRequest<(Bool, JSON?)>(path: OpenAPI.APIPath.explorerSpaceAdd, params: parameters)
            .set(timeout: 20)
            .set(transform: { (json) -> (result: (Bool, JSON?), error: Error?) in
                guard let code = json?["code"].int else {
                    return ((false, json), CollaboratorsError.parseError)
                }
                if DocsNetworkError.isSuccess(code) {
                    return ((true, json), nil)
                }
                // DocsNetworkError.invalidData。意味着这个 Code 没有带回来，或者是一个新的 Code
                return ((false, json), DocsNetworkError(json?["code"].int) ?? DocsNetworkError.invalidData)
            })
            .start(result: complete)
    }
    
    /// 查询旧共享文件夹协作者
    /// - Parameters:
    ///   - spaceID: 共享文件夹的 spaceID
    ///   - complete: 请求回来调用的 completion block
    public static func getOldShareFolderCollaboratorsRequest(
        spaceID: String,
        complete: @escaping ([Collaborator]?, Error?) -> Void) -> DocsRequest<[Collaborator]> {
        return DocsRequest<[Collaborator]>(path: OpenAPI.APIPath.explorerSpaceMget, params: ["space_id": spaceID])
            .set(method: .GET)
            .set(encodeType: .urlEncodeAsQuery)
            .set(timeout: 20)
            .set(transform: { (json) -> ([Collaborator]?, error: Error?) in
                guard let dict = json?.dictionaryObject,
                    let data = dict["data"] as? [String: Any],
                    let collaboratorsDict = data[spaceID] as? [[String: Any]]
                else {
                    return (nil, DocsNetworkError.invalidData)
                }
                var items = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: true)
                if let entities = data["entities"] as? [String: Any], let users = entities["users"] as? [String: Any] {
                    Collaborator.localizeCollaboratorName(collaborators: &items, users: users)
                    Collaborator.permissionStatistics(collaborators: &items, users: users)
                }
                return (items, nil)
            })
            .start(result: complete)
    }
    
    static func removeShareFolderCollaboratorsRequest(
        spaceID: String,
        ownerId: String,
        complete: @escaping (JSON?, Error?) -> Void) -> DocsRequest<JSON> {
        return DocsRequest<JSON>(path: OpenAPI.APIPath.explorerSpaceRemove, params: ["space_id": "\(spaceID)", "owner_id": ownerId])
            .start(result: { (response, error) in
                DispatchQueue.main.async {
                    complete(response, error)
                }
            })
    }
}
