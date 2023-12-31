//
//  PermissionManager+Biz.swift
//  SKCommon
//
//  Created by CJ on 2021/2/18.
//
//  swiftlint:disable file_length

import Foundation
import SwiftyJSON
import HandyJSON
import SKFoundation
import RxSwift
import SKInfra
import SpaceInterface

/// 权限相关网络请求的响应状态码
public enum PermissionStatusCode: Int {
    /// 默认值
    case defaultValue = 0
    /// 机器审核不过
    case auditError = 10009
    /// 人工审核不过 或者被举报
    case reportError = 10013
    /// 需要输入密码才可以访问文档/文件夹
    case passwordRequired = 10016
    /// 密码错误
    case wrongPassword = 10017
    /// 错误达上限
    case errorReachedLimit = 10018
}

extension UserPermissionAbility {
    // askOwner和sendLink接口 编辑权限传4，但是之前都是通过rawValue传5。
    public var newPermissonValue: Int {
        if canEdit() {
            return 4
        } else if canView() {
            return 1
        } else {
            return 0
        }
    }
}

extension PermissionManager {
//    public func rxRequestDocumentActionsState(token: String, type: Int, actions: [UserPermissionEnum]) -> Single<UserPermissionRequestInfo> {
//        Single.create { [self] single in
//            requestDocumentActionsState(token: token, type: type, actions: actions) { info, error in
//                if let info = info {
//                    single(.success(info))
//                } else {
//                    let error = error ?? DocsNetworkError.invalidData
//                    single(.error(error))
//                }
//            }
//            return Disposables.create()
//        }
//    }
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func requestDocumentActionsState(
        token: String,
        type: Int,
        actions: [UserPermissionEnum],
        parent: (String, Int)? = nil,
        complete: ((UserPermissionRequestInfo?, Error?) -> Void)? = nil) {
            var moreActions: [UserPermissionEnum] = actions
            if actions.isEmpty {
                moreActions = UserPermissionEnum.allCases
            }
            let paramsActions = moreActions.map { $0.rawValue }
            var params: [String: Any] = [
                "token": token,
                "type": type,
                "actions": paramsActions
            ]
            if let (parentToken, parentType) = parent {
                spaceAssert(parentType != 16, "prefer using wiki content obj token and type")
                params["relation"] = [
                    "entity_token": parentToken,
                    "entity_type": parentType,
                    "relation_type": 1 // 1:父；2:子
                ]
            }
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissonDocumentActionsState, params: params)
                .set(method: .POST)
                .set(timeout: 20)
                .set(encodeType: .jsonEncodeDefault)
                .makeSelfReferenced()

        request.start { [weak self] (json, error) in
            guard let self else { return }
            guard let result = json,
                  let code = result["code"].int else {
                DocsLogger.error("request user permisson action state failed", error: error, component: LogComponents.permission)
                DispatchQueue.main.async { complete?(nil, error) }
                return
            }
            let data = result["data"]
            let permissions = UserPermission(json: result)
            let permissionDict = [token: permissions]
            self.updateUserPermissions(permissionDict)

            let permissionStatusCode = data["permission_status_code"].intValue
            let permissonCode = PermissionStatusCode(rawValue: permissionStatusCode) ?? .defaultValue
            DocsLogger.info("request user permisson action state success, token = \(token.encryptToken), code = \(code), permissionStatusCode = \(permissionStatusCode)", extraInfo: permissions.reportData, component: LogComponents.permission)

            DispatchQueue.main.async { complete?((permissions, permissonCode), error) }
        }
    }

    // 查询文档附件权限时，需要同时把父文档的 parentToken 和 parentType 传进来
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func fetchUserPermissions(token: String, type: Int, parent: (String, Int)? = nil, complete: ((UserPermissionRequestInfo?, Error?) -> Void)? = nil) {
        requestDocumentActionsState(token: token, type: type, actions: [], parent: parent, complete: complete)
    }

    /// Fetch from server the public permission meta for a designated file
    /// - Parameters:
    ///   - token: file's `objToken`
    ///   - type: file's `DocsType` rawValue
    ///   - complete: The completion block sent to main thread handling the fetch result, optional. Argument: ((public permission meta provided by the server, Error?))
    public func fetchPublicPermissions(token: String, type: Int, complete: ((PublicPermissionMeta?, Error?) -> Void)? = nil) {
        let path = ShareFeatureGating.newPermissionSettingEnable(type: type) ? OpenAPI.APIPath.suitePermissionPublicV4 : OpenAPI.APIPath.suitePermissionPublic
        let request = DocsRequest<JSON>(path: path + "?token=\(token)&type=\(type)", params: nil)
            .set(method: .GET)
            .set(timeout: 20)
            .set(needVerifyData: true)
            .makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { [weak self] (json, error) in
            guard let self else { return }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("fetch publicPermissionMeta failed with error", error: error)
                DispatchQueue.main.async {
                    complete?(nil, error)
                }
                return
            }

            let data = json["data"]

            var permissionMeta: PublicPermissionMeta?
            if ShareFeatureGating.newPermissionSettingEnable(type: type) {
                permissionMeta = PublicPermissionMeta(newJson: data)
            } else {
                permissionMeta = PublicPermissionMeta(json: data)
            }

            guard code == 0, !data.isEmpty, let publicPermissionMeta = permissionMeta else {
                DocsLogger.error("fetch publicPermissionMeta failed with error", error: error)
                DispatchQueue.main.async {
                    complete?(nil, error)
                }
                return
            }

            self.updatePublicPermissionMetas([token: publicPermissionMeta])

            DocsLogger.info("request public permisson success, token = \(token.encryptToken)", extraInfo: data.dictionaryObject, component: LogComponents.permission)
            DispatchQueue.main.async { complete?(publicPermissionMeta, error) }
        })
    }
    
    static func checkSpaceRoot(token: String, type: Int) -> Single<Bool> {
        let parameters = [
            "entities": [
                ["obj_token": token, "obj_type": type]
            ]
        ] as [String : Any]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.checkSpaceRoot, params: parameters)
            .set(encodeType: .jsonEncodeDefault)
            .rxStart()
            .flatMap({ json in
                guard let json = json,
                      let dict = json.dictionaryObject,
                      let data = dict["data"] as? [String: Any],
                      let infoDict = data["space_root_info"] as? [String: Any],
                let result = infoDict[token] as? Bool else {
                    return .error(CollaboratorsError.parseError)
                }
                return .just(result)
            })
            .catchError { error in
                DocsLogger.error("checkSpaceRoot failed!", extraInfo: nil, error: error, component: nil)
                throw CollaboratorsError.networkError
            }
    }
    
    /// 转移文件的权限 doc/sheet/bitable等
    /// - Parameters:
    ///   - token: 文件的 objToken
    ///   - type: 文件类型
    ///   - ownerId: 新的 owner 的 userID
    ///   - finish: 请求回来调用的 completion block
    static func transferFileOwnerRequest(token: String,
                                         type: Int,
                                         ownerId: String,
                                         finish: @escaping (_ success: Bool, _ cacBlocked: Bool, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        var params = [String: Any]()
        params["token"] = token
        params["type"] = type
        params["owner_id"] = ownerId
        params["owner_type"] = 1
        params["source"] = "suite_share"
        
        return DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionTransferFileOwner, params: params)
            .set(encodeType: .urlEncodeDefault)
            .set(timeout: 20)
            .set(needVerifyData: false)
            .start(result: { (result, error) in
                guard error == nil else {
                    finish(false, false, result)
                    return
                }
                let code = (result?["code"].int) ?? -1
                let success = code == 0
                let cacBlocked = code == 2002
                DocsLogger.info("transferFileOwnerRequest finished, code is \(code)")
                finish(success, cacBlocked, result)
            })
    }
    
    /// 更新文档公共权限
    /// - Parameters:
    ///   - params: 参数
    ///   - complete: 回调
    /// - Returns:
    public static func updateBizsPublicPermission(type: Int, params: [String: Any], complete: @escaping (JSON?, Error?) -> Void) -> DocsRequest<JSON> {
        let path = OpenAPI.APIPath.suitePermissionPublicUpdateV5
        return DocsRequest<JSON>(path: path, params: params)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .start(result: {(response, error) in
                complete(response, error)
            })
    }

    /// 更新文档公共权限的 Rx 包装
    /// - Parameters:
    ///   - params: 参数
    public static func updateBizsPublicPermission(params: [String: Any]) -> Single<JSON?> {
        return DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionPublicUpdate, params: params)
            .set(encodeType: .jsonEncodeDefault)
            .rxStart()
    }
    
    public static func updateBizsCollaboratorsPermissionRequest(params: [String: Any], complete: @escaping (JSON?, Error?) -> Void) -> DocsRequest<JSON> {
        let path = OpenAPI.APIPath.suitePermissionCollaboratorsUpdateV2
        return DocsRequest<JSON>(path: path, params: params)
            .start(result: {(response, error) in
                complete(response, error)
            })
    }

    public func fetchCollaboratorsCount(token: String,
                                   type: Int,
                                   complete: ((Int?, Error?) -> Void)? = nil) {
        let subpath = "?token=\(token)&type=\(type)"
        let request = DocsRequest<JSON>(
            path: OpenAPI.APIPath.suitePermissionCollaboratorsCount + subpath,
            params: nil
        ).set(method: .GET).set(timeout: 20).makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { json, error in
            guard let dict = json?.dictionaryObject,
                let data = dict["data"] as? [String: Any],
                let count = data["count"] as? Int
            else {
                DocsLogger.error("PermissionManager fetch collaborator count error", error: error, component: LogComponents.permission)
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }
            DispatchQueue.main.async { complete?(count, nil) }
        })
    }

    /// Fetch from server the collaborators for a designated file.
    /// The response is paged (50 collaborator once), meaning a 'last_label' is passed in a request for ordering
    /// - Parameters:
    ///   - token: file's `objToken`
    ///   - type: file's `DocsType` rawValue
    ///   - lastLabel: page description
    ///   - complete: The completion block sent to main thread handling the fetch result, optional. Argument: ((collaborator response model?, Error?))
    public func fetchCollaborators(token: String,
                                   type: Int,
                                   shouldFetchNextPage: Bool,
                                   clearAllBeforeFetch: Bool = false,
                                   lastPageLabel: String? = nil,
                                   collaboratorSource: CollaboratorSource,
                                   complete: ((CollaboratorResponse?, Error?) -> Void)? = nil) {
        let augToken = augmentedToken(of: token)
        var subpath = "?token=\(token)&type=\(type)"
        if let lastPageLabel = lastPageLabel {
            subpath = "\(subpath)&last_label=\(lastPageLabel.urlEncoded())"
        }
        subpath = "\(subpath)&perm_type=\(collaboratorSource.rawValue)"
        
        if clearAllBeforeFetch {
            collaboratorStore.removeAllCollaborators(for: augToken)
        }

        let request = DocsRequest<JSON>(
            path: OpenAPI.APIPath.suitePermissionCollaboratorsV2 + subpath,
            params: nil
        ).set(method: .GET).set(timeout: 20).makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { [weak self] json, error in
            guard let dict = json?.dictionaryObject,
                let data = dict["data"] as? [String: Any],
                let hasMore = data["has_more"] as? Bool,
                let collaboratorsDict = data["members"] as? [[String: Any]]
            else {
                DocsLogger.error("PermissionManager fetch collaborator error", error: error, component: LogComponents.permission)
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }

            var items = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
            if let entities = data["entities"] as? [String: Any], let users = entities["users"] as? [String: [String: Any]] {
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.insert(users: users)
                Collaborator.localizeCollaboratorName(collaborators: &items, users: users)
                Collaborator.permissionStatistics(collaborators: &items, users: users)
            }
            self?.updateCollaborators([augToken: items], collaboratorSource: collaboratorSource)
            let thisPageLabel = data["last_label"] as? String // 如果是 nil，则代表该文件的协作者数量小于等于 50 个；否则需要业务通过 shouldFetchNextPage 明确是否需要继续请求剩余协作者
            let isFileOwnerFromAnotherTenant = data["is_external"] as? Bool ?? false
            let collaboratorCount = data["total_num"] as? Int ?? 1 // 1 是因为文件的 owner 一定是协作者
            DocsLogger.info("fetchCollaborators items count = \(items.count), total_count = \(collaboratorCount), last_label = \(thisPageLabel), hasmore = \(hasMore)")
            if shouldFetchNextPage, hasMore { // 说明还有下一页，而且外部要求继续请求剩余协作者
                self?.fetchCollaborators(token: token, type: type,
                                         shouldFetchNextPage: true,
                                         lastPageLabel: thisPageLabel,
                                         collaboratorSource: collaboratorSource,
                                         complete: complete)
            } else {
                DispatchQueue.main.async {
                    ///通知其它模块协作者列表变化
                    let userInfo: [String: Any] = [
                    "token": token,
                    "type": type,
                    "collaboratorSource": collaboratorSource.rawValue,
                    "count": collaboratorCount
                    ]
                    NotificationCenter.default.post(name: Notification.Name.Docs.CollaboratorListChanged,
                                                object: nil,
                                                userInfo: userInfo)
                    complete?((collaboratorCount, isFileOwnerFromAnotherTenant, thisPageLabel), nil)
                }
            }
        })
    }

    public func fetchBlockCollaborators(token: String,
                                   type: Int,
                                   shouldFetchNextPage: Bool,
                                   lastPageLabel: String? = nil,
                                   complete: ((CollaboratorResponse?, Error?) -> Void)? = nil) {
        let augToken = augmentedToken(of: token)
        var subpath = "?token=\(token)&type=\(type)"
        if let lastPageLabel = lastPageLabel {
            subpath = "\(subpath)&last_label=\(lastPageLabel.urlEncoded())"
        }

        let request = DocsRequest<JSON>(
            path: OpenAPI.APIPath.suitePermissionBlockCollaborators + subpath,
            params: nil
        ).set(method: .GET).set(timeout: 20).makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { [weak self] json, error in
            guard let dict = json?.dictionaryObject,
                let data = dict["data"] as? [String: Any],
                let hasMore = data["has_more"] as? Bool,
                let collaboratorsDict = data["members"] as? [[String: Any]]
            else {
                DocsLogger.error("PermissionManager fetch collaborator error", error: error, component: LogComponents.permission)
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }

            var items = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
            if let parentDocInfo = data["parent_doc_info"] as? [String: Any],
            let iconToken = parentDocInfo["icon_token"] as? String, let spaceType = Collaborator.explorerSpaceType(type: .hostDoc) {
                let parentDocItem = Collaborator(rawValue: spaceType, userID: "", name: "", avatarURL: "", avatarImage: nil, iconToken: iconToken, userPermissions: UserPermissionMask(rawValue: 0), groupDescription: nil)
                items.insert(parentDocItem, at: 0)
            }
            self?.updateCollaborators([augToken: items], collaboratorSource: .defaultType)
            let thisPageLabel = data["last_label"] as? String // 如果是 nil，则代表该文件的协作者数量小于等于 50 个；否则需要业务通过 shouldFetchNextPage 明确是否需要继续请求剩余协作者
            let isFileOwnerFromAnotherTenant = data["is_external"] as? Bool ?? false
            let collaboratorCount = data["total_num"] as? Int ?? 1 // 1 是因为文件的 owner 一定是协作者
            DocsLogger.info("fetchCollaborators items count = \(items.count), total_count = \(collaboratorCount), last_label = \(thisPageLabel), hasmore = \(hasMore)")
            if shouldFetchNextPage, hasMore { // 说明还有下一页，而且外部要求继续请求剩余协作者
                self?.fetchBlockCollaborators(token: token, type: type,
                                         shouldFetchNextPage: true,
                                         lastPageLabel: thisPageLabel,
                                         complete: complete)
            } else {
                DispatchQueue.main.async {
                    ///通知其它模块协作者列表变化
                    let userInfo: [String: Any] = [
                    "token": token,
                    "type": type,
                    "collaboratorSource": CollaboratorSource.defaultType,
                    "count": collaboratorCount
                    ]
                    NotificationCenter.default.post(name: Notification.Name.Docs.CollaboratorListChanged,
                                                object: nil,
                                                userInfo: userInfo)
                    complete?((collaboratorCount, isFileOwnerFromAnotherTenant, thisPageLabel), nil)
                }
            }
        })
    }

    func askOwnerForInviteCollaborator(
        type: Int?,
        token: String?,
        candidates: Set<Collaborator>,
        larkIMText: String? = "",
        complete: @escaping (JSON?, URLResponse?, Error?) -> Void)
        -> DocsRequest<Any> {
            var dictionary = [[String: Any]]()
            dictionary = Array(candidates).map {
                return ["owner_id": $0.userID, "owner_type": $0.rawValue, "permission": $0.userPermissions.newPermissonValue]
            }
            var parameters = [String: Any]()
            if let type = type, let token = token {
                parameters = ["type": type,
                              "token": token,
                              "members": dictionary]
                if let larkIMText = larkIMText {
                    parameters.merge(other: ["remark": larkIMText])
                }
            }
        let askownerRequest = DocsRequest<Any>(path: OpenAPI.APIPath.askOwnerForInviteCollaborator, params: parameters)
            .set(timeout: 20)
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        askownerRequest.start(rawResult: { (data, response, error) in
            guard error == nil, let jsonData = data,
                  let json = jsonData.json else {
                DocsLogger.error("askOwnerForInviteCollaborator failed!", extraInfo: nil, error: error, component: nil)
                DispatchQueue.main.async {
                    complete(nil, response, DocsNetworkError.invalidData)
                }
                return
            }
            DispatchQueue.main.async {
                complete(json, response, nil)
            }
        })
        return askownerRequest
    }

    func sendLinkForInviteCollaborator(
        type: Int?,
        token: String?,
        candidates: Set<Collaborator>,
        larkIMText: String? = "",
        complete: @escaping (JSON?, Error?) -> Void)
        -> DocsRequest<JSON> {
            var dictionary = [[String: Any]]()
            dictionary = Array(candidates).map {
                return ["owner_id": $0.userID, "owner_type": $0.rawValue, "permission": $0.userPermissions.newPermissonValue]
            }
            var parameters = [String: Any]()
            if let type = type, let token = token {
                parameters = ["type": type,
                              "token": token,
                              "members": dictionary]
                if let larkIMText = larkIMText {
                    parameters.merge(other: ["remark": larkIMText])
                }
            }
            return DocsRequest<JSON>(path: OpenAPI.APIPath.sendLinkForInviteCollaborator, params: parameters)
                .set(timeout: 20)
                .set(headers: ["Content-Type": "application/json"])
                .set(encodeType: .jsonEncodeDefault)
                .set(needVerifyData: false)
                .start(result: { (json, error) in
                    guard error == nil, let json = json else {
                        DocsLogger.error("inviteCollaboratorsRequest failed!", extraInfo: nil, error: error, component: nil)
                        DispatchQueue.main.async {
                            complete(nil, DocsNetworkError.invalidData)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        complete(json, nil)
                    }
                })
    }
}

public struct CollaboratorsRequest {
    public let type: Int?
    public let token: String?
    public let candidates: Set<Collaborator>
    public let notify: Bool
    public let larkIMText: String?
    public let collaboratorSource: CollaboratorSource

}

public struct UpdateCollaboratorsPremission {
    public let type: Int
    public let token: String
    public let memberId: String
    public let memberType: Int
    public let permission: Int
}

extension PermissionManager {

    enum InviteCollaboratorsNotifyType {
        case bot
        case im
    }

    /// 邀请协作者
    /// - Parameters:
    ///   - type: 文件类型
    ///   - token: 文件的 objToken
    ///   - candidates: 协作者的候选集合
    ///   - notify: 是否通知被邀请人
    ///   - notifyType: 通知类型
    ///   - lark_im_text: IM纯文本内容
    ///   - isContainer: 是不是容器协作者
    ///   - complete: 请求回来调用的 completion block
    static func inviteCollaboratorsRequest(
        context: CollaboratorsRequest,
        notifyType: InviteCollaboratorsNotifyType,
        complete: @escaping (JSON?, Error?) -> Void)
    -> DocsRequest<JSON> {
        var dictionary = [[String: Any]]()
        dictionary = Array(context.candidates).map {
            return ["owner_id": $0.userID,
                    "owner_type": $0.rawValue,
                    "permission": $0.userPermissions.rawValue]
        }
        let collaboratorString: String
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            collaboratorString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            collaboratorString = ""
        }
        var parameters: [String: Any] = ["owners": collaboratorString]
        if let type = context.type, let token = context.token {
            parameters.merge(other: ["type": type, "token": token])
        }

        //1. notify_lark：传1，发bot通知
        //2. notify_lark_v3：传true，服务端去发送im通知
        switch notifyType {
        case .bot:
            parameters.merge(other: ["notify_lark": context.notify])
        case .im:
            if let larkIMText = context.larkIMText {
                parameters.merge(other: ["lark_im_text": larkIMText])
            }
            parameters.merge(other: ["notify_lark_v3": context.notify])
        }
        parameters.merge(other: ["perm_type": context.collaboratorSource.rawValue])

        return DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionCollaboratorsCreate, params: parameters)
            .set(needVerifyData: false)
            .set(timeout: 20)
            .start(result: { (json, error) in
                guard error == nil else {
                    DocsLogger.error("inviteCollaboratorsRequest failed!", extraInfo: nil, error: error, component: nil)
                    DispatchQueue.main.async {
                        complete(nil, CollaboratorsError.networkError)
                    }
                    return
                }
                guard let json = json, let code = json["code"].int else {
                    DispatchQueue.main.async {
                        complete(nil, CollaboratorsError.parseError)
                    }
                    return
                }
                if let err = DocsNetworkError(code) {
                    DispatchQueue.main.async {
                        complete(json, err)
                    }
                    return
                }
                DispatchQueue.main.async {
                    complete(json, nil)
                }
            })
    }

    /// 邀请协作者
    /// - Parameters:
    ///   - type: 文件类型
    ///   - token: 文件的 objToken
    ///   - ownerId: 协作者id
    ///   - ownerType: 协作者类型
    ///   - complete: 请求回来调用的 completion block
    static func inviteCollaboratorsByAdjustSettings(
        type: Int,
        token: String,
        ownerId: String,
        ownerType: Int
    ) -> Completable {
        let dictionary = [["owner_id": ownerId,
                           "owner_type": ownerType,
                           "permission": 1]]
        let collaboratorString: String
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            collaboratorString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            collaboratorString = ""
        }
        var parameters: [String: Any] = ["owners": collaboratorString]
        parameters.merge(other: ["type": type, "token": token])
        parameters.merge(other: ["notify_lark_v3": false])
        parameters.merge(other: ["perm_type": CollaboratorSource.singlePage.rawValue])

        return DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionCollaboratorsCreate, params: parameters)
            .set(needVerifyData: true)
            .set(timeout: 20)
            .rxStart()
            .asCompletable()
    }

    /// 批量查询用户是否已经是协作者
    /// - Parameters:
    ///   - type: 文件类型
    ///   - token: 文件的 objToken
    ///   - candidates: 协作者的候选集合
    ///   - complete: 请求回来调用的 completion block
    static func checkCollaboratorsExist(
        type: Int,
        token: String,
        ownerId: String,
        ownerType: Int
    ) -> Single<Bool> {
        let dictionary = [["member_id": ownerId, "member_type": ownerType]]
        var parameters: [String: Any] = ["members": dictionary]
        parameters.merge(other: ["type": type, "token": token])
        return DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionCollaboratorsExist, params: parameters)
            .set(encodeType: .jsonEncodeDefault)
            .rxStart()
            .map({ json in
                guard let json = json,
                      let dict = json.dictionaryObject,
                      let data = dict["data"] as? [String: Any],
                      let collaboratorsDict = data["existed_members"] as? [[String: Any]] else {
                    throw DocsNetworkError.invalidData
                }
                let items = Collaborator.existCollaborators(collaboratorsDict)
                let ids = items.map({ $0.userID })
                return ids.contains(ownerId)
            })
    }
    
    /// 批量查询用户是否已经是协作者
    /// - Parameters:
    ///   - type: 文件类型
    ///   - token: 文件的 objToken
    ///   - candidates: 协作者的候选集合
    ///   - complete: 请求回来调用的 completion block
    static func batchQueryCollaboratorsExist(
        type: Int?,
        token: String?,
        candidates: Set<Collaborator>,
        complete:  @escaping ([Collaborator]?, Error?) -> Void) -> DocsRequest<JSON> {
        var dictionary = [[String: Any]]()
        dictionary = Array(candidates).map {
            return ["member_id": $0.userID, "member_type": $0.rawValue]
        }
        var parameters: [String: Any] = ["members": dictionary]
        if let type = type, let token = token {
            parameters.merge(other: ["type": type, "token": token])
        }
        return DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionCollaboratorsExist, params: parameters)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: 20)
            .start(result: { (json, error) in
                guard error == nil else {
                    DocsLogger.error("batchQueryCollaboratorsExist failed!", extraInfo: nil, error: error, component: nil)
                    DispatchQueue.main.async {
                        complete(nil, CollaboratorsError.networkError)
                    }
                    return
                }
                guard let json = json,
                      let dict = json.dictionaryObject,
                      let data = dict["data"] as? [String: Any],
                      let collaboratorsDict = data["existed_members"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        complete(nil, CollaboratorsError.parseError)
                    }
                    return
                }
                let items = Collaborator.existCollaborators(collaboratorsDict)
                DispatchQueue.main.async {
                    complete(items, nil)
                }
            })
    }
}

// MARK: - 单容器文档新增协议
extension PermissionManager {
    /// 文件解锁
    /// - Parameters:
    ///   - token: 文件token
    ///   - type: 文件type
    ///   - complete: 请求回来调用的 completion block
    public static func unlockFile(
        token: String,
        type: Int,
        complete: @escaping (Bool?, Error?) -> Void) -> DocsRequest<Bool> {
        var params = [String: Any]()
        params["token"] = token
        params["type"] = type

        return DocsRequest<Bool>(path: OpenAPI.APIPath.unlockFile, params: params)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .set(transform: { (json) -> (Bool, error: Error?) in
                guard let json = json,
                      let code = json["code"].int,
                      code == 0 else {
                    let error = NSError(domain: "docs.unlock.file.failed ", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: ""])
                    DocsLogger.error("unlock file failed", error: error, component: LogComponents.permission)
                    return (false, error)
                }
                DocsLogger.info("unlock file success", component: LogComponents.permission)
                return (true, nil)
            })
            .start(result: complete)
    }
    
    /// 判断bizs文档修改公共权限是否触发加锁
    /// - Parameters:
    ///   - token: 文件夹token
    ///   - externalAccess: 对外分享开关
    ///   - linkShareEntity: 链接分享选项
    ///   - complete: 回调
    static func checkLockByUpdateFilePublicPermission(
        token: String,
        type: Int,
        externalAccess: Bool? = nil,
        externalAccessEntity: Int? = nil,
        commentEntity: Int? = nil,
        shareEntity: Int? = nil,
        inviteExternal: Bool? = nil,
        securityEntity: Int? = nil,
        linkShareEntity: Int? = nil,
        linkShareEntityV2: Int? = nil,
        searchEntity: Int? = nil,
        complete:  @escaping (_ success: Bool, _ needLock: Bool, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        var params: [String: Any] = ["token": token, "type": type]
        if let externalAccess = externalAccess {
            params["external_access"] = externalAccess
        }
        if let externalAccessEntity = externalAccessEntity {
            params["external_access_entity"] = externalAccessEntity
        }
        if let commentEntity = commentEntity {
            params["comment_entity"] = commentEntity
        }
        if let shareEntity = shareEntity {
            params["share_entity"] = shareEntity
        }
        if let inviteExternal = inviteExternal {
            params["invite_external"] = inviteExternal
        }
        if let securityEntity = securityEntity {
            params["security_entity"] = securityEntity
        }
        if let linkShareEntity = linkShareEntity {
            params["link_share_entity"] = linkShareEntity
        }
        if let linkShareEntityV2 = linkShareEntityV2 {
            params["link_share_entity_v2"] = linkShareEntityV2
        }
        if let searchEntity = searchEntity {
            params["search_entity"] = searchEntity
        }
        return DocsRequest<JSON>(path: OpenAPI.APIPath.checkLockByUpdateFilePublicPermission, params: params)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (json, error) in
                guard error == nil,
                      let result = json,
                      let code = result["code"].int, code == 0,
                      let data = result["data"].dictionaryObject else {
                    complete(false, false, json)
                    DocsLogger.error("check Lock By Update File PublicPermission failed", error: error, component: LogComponents.permission)
                    return
                }
                DocsLogger.info("check Lock By Update File PublicPermission success", component: LogComponents.permission)
                let needLock = data["need_lock"] as? Bool ?? false
                complete(true, needLock, json)
            })
    }
    
    /// 判断bizs文档更新协作者权限是否触发加锁
    /// - Parameters:
    ///   - token: 文件夹的 token
    ///   - memberId: 协作者ID
    ///   - memberType: 协作者类型
    ///   - permRole: 角色类型
    ///   - complete: 回调
    static func checkLockByUpdateFileCollaboratorPermission(
        context: UpdateCollaboratorsPremission,
        complete: @escaping (_ success: Bool, _ needLock: Bool, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
            let params: [String: Any] = ["token": context.token,
                                         "type": context.type,
                                         "member_id": context.memberId,
                                         "member_type": context.memberType,
                                         "permission": context.permission]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.checkLockByUpdateFileCollaboratorPermission, params: params)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (json, error) in
                guard error == nil,
                      let result = json,
                      let code = result["code"].int, code == 0,
                      let data = result["data"].dictionaryObject else {
                    complete(false, false, json)
                    DocsLogger.error("check Lock By Update File Collaborator Permission failed", error: error, component: LogComponents.permission)
                    return
                }
                let needLock = data["need_lock"] as? Bool ?? false
                DocsLogger.info("check Lock By Update File Collaborator Permission success, need_lock is \(needLock)", component: LogComponents.permission)
                complete(true, needLock, json)
            })
    }
    
    /// 判断bizs文档删除协作者是否触发加锁
    /// - Parameters:
    ///   - token: 文件夹的 token
    ///   - memberId: 协作者ID
    ///   - memberType: 协作者类型
    ///   - permRole: 角色类型
    ///   - complete: 回调
    static func checkLockByDeleteFileCollaborator(
        token: String,
        type: Int,
        memberId: String,
        memberType: Int,
        complete: @escaping (_ success: Bool, _ needLock: Bool, _ result: JSON?) -> Void) -> DocsRequest<JSON> {
        let params: [String: Any] = ["token": token,
                                     "type": type,
                                     "member_id": memberId,
                                     "member_type": memberType]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.checkLockByDeleteFileCollaborator, params: params)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (json, error) in
                guard error == nil,
                      let result = json,
                      let code = result["code"].int, code == 0,
                      let data = result["data"].dictionaryObject else {
                    complete(false, false, json)
                    DocsLogger.error("check Lock By Delete File Collaborator failed", error: error, component: LogComponents.permission)
                    return
                }
                let needLock = data["need_lock"] as? Bool ?? false
                DocsLogger.info("check Lock By Delete File Collaborator success, need_lock is \(needLock)", component: LogComponents.permission)
                complete(true, needLock, json)
            })
    }
}

public extension TNSRedirectInfo {
    public var finalURL: URL {
        guard var components = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false) else {
            return redirectURL
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "os_name", value: UIDevice.current.systemName))
        queryItems.append(URLQueryItem(name: "os_version", value: UIDevice.current.systemVersion))
        queryItems.append(URLQueryItem(name: "platform", value: "lark"))
        queryItems.append(URLQueryItem(name: "file_id", value: DocsTracker.encrypt(id: meta.objToken)))
        queryItems.append(URLQueryItem(name: "file_type", value: String(meta.objType.rawValue)))
        queryItems.append(URLQueryItem(name: "app_form", value: appForm.rawValue))
        queryItems.append(URLQueryItem(name: "module", value: module))
        if let subModule {
            queryItems.append(URLQueryItem(name: "sub_module", value: subModule))
        }
        if let creatorID {
            queryItems.append(URLQueryItem(name: "creator_id", value: creatorID))
        }
        if let ownerID {
            queryItems.append(URLQueryItem(name: "owner_id", value: ownerID))
        }
        if let ownerTenantID {
            queryItems.append(URLQueryItem(name: "owner_tenant_id", value: ownerTenantID))
        }
        components.queryItems = queryItems
        return components.url ?? redirectURL
    }
}
