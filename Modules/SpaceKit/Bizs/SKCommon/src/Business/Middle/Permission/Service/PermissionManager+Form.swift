//
//  PermissionManager+Form.swift
//  SKCommon
//
//  Created by guoqp on 2021/7/19.
//

import Foundation
import SwiftyJSON
import HandyJSON
import ThreadSafeDataStructure
import SKFoundation
import SKInfra

private struct Const {
    static let defaultNetTimeout: Double = 20
}


///表单相关协议
extension PermissionManager {

    ///获取用户是否有分享表单的权限
    public func fetchFormUserPermissions(token: String, tableID: String, viewId: String, complete: ((UserPermissionMask?, Error?) -> Void)? = nil) {
        fetchBibtaleUserPermissions(token: token, tableID: tableID, viewId: viewId, shareType: .form, complete: complete)
    }
    
    /// 获取用户是否有分享 Bitable 的权限
    public func fetchBibtaleUserPermissions(token: String, tableID: String, viewId: String?, shareType: BitableShareSubType, complete: ((UserPermissionMask?, Error?) -> Void)? = nil) {
        let path = OpenAPI.APIPath.getFormPermissionPath(token)
        let params: [String: Any] = [
            "tableId": tableID,
            "viewId": viewId ?? "",
            "shareType": shareType.rawValue
        ]
        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
            .set(timeout: 20)
            .set(needVerifyData: false)
            .makeSelfReferenced()
        DocsLogger.info("[BTS] fetch bitable use permission start")
        request.start(callbackQueue: callbackQueue, result: { (json, error) in
            guard error == nil else {
                DocsLogger.error("[BTS] fetch bitable use permission failed")
                DispatchQueue.main.async { complete?(nil, error) }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("[BTS] fetch bitable use permission failed")
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }
            guard DocsNetworkError.isSuccess(code) else {
                DocsLogger.error("[BTS] fetch bitable use permission failed, code: \(code)")
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }
            let data: JSON = json["data"]
            if let permitted = data["permitted"].bool, permitted {
                DocsLogger.info("[BTS] fetch bitable use permission success")
                let mask: UserPermissionMask = [.share]
                DispatchQueue.main.async { complete?(mask, nil) }
            } else { // 未返回，按无权限处理
                DocsLogger.warning("[BTS] fetch bitable use permission failed, <permitted> missing!")
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
            }
        })
    }

    ///获取分享表单meta
    public func fetchFormShareMeta(token: String,
                                   tableID: String,
                                   viewId: String,
                                   shareType: Int = 1,
                                   complete: ((FormShareMeta?, Error?) -> Void)? = nil) {
        let path = OpenAPI.APIPath.getFormShareMetaPath(token)
        let params: [String: Any] = [
            "tableId": tableID,
            "viewId": viewId,
            "shareType": shareType
        ]
        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
            .set(timeout: 20)
            .set(needVerifyData: false)
            .makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { (json, error) in
            guard error == nil else {
                DispatchQueue.main.async { complete?(nil, error) }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }
            guard DocsNetworkError.isSuccess(code) else {
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }
            let data: JSON = json["data"]
            if let flag = data["flag"].int, let shareToken = data["shareToken"].string {
                let meta = FormShareMeta(token: token, tableId: tableID, viewId: viewId, shareType: shareType)
                meta.updateFlag((flag == 1))
                meta.updateShareToken(shareToken)
                DispatchQueue.main.async { complete?(meta, nil) }
            } else { // 未返回权限值，按无权限处理
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }

            }
        })
    }
    
    /// 获取 Bitable 分享 meta
    public func fetchBitableShareMeta(param: BitableShareParam, completion: ((Result<BitableShareMeta, Error>, Int?) -> Void)?) {
        if param.isRecordShareV2 {
            fetchBaseRecordShareMeta(param: param, completion: completion)
            return
        } else if param.isAddRecordShare {
            fetchBaseAddRecordShareMeta(param: param, completion: completion)
            return
        }
        DocsLogger.info("fetch bitable meta start")
        let path = OpenAPI.APIPath.getFormShareMetaPath(param.baseToken)
        var parameters: [String: Any] = [
            "tableId": param.tableId,
            "shareType": param.shareType.rawValue
        ]
        parameters["viewId"] = param.viewId
        parameters["recordId"] = param.recordId
        
        let request = DocsRequest<JSON>(path: path, params: parameters)
            .set(method: .GET)
            .set(timeout: 20)
            .set(needVerifyData: true)
            .makeSelfReferenced()
        DocsLogger.info("[BTS] fetch bitable share meta start, type: \(param.shareType)")
        request.start(callbackQueue: callbackQueue, result: { (json, error) in
            guard let json = json else {
                let error = error ?? DocsNetworkError.invalidData
                DocsLogger.error("fetch bitable meta failed: \(error)")
                DispatchQueue.main.async {
                    completion?(.failure(error), nil)
                }
                return
            }
            do {
                DocsLogger.info("fetch bitable meta success")
                let code = json["code"].intValue
                var dicData = json["data"]
                let shareType = dicData["shareType"].intValue
                if shareType == 0 {
                    dicData["shareType"] = JSON(integerLiteral: param.shareType.rawValue)
                }
                let data = try dicData.rawData()
                // 对于没有打开过分享的服务端默认会给ShareType为0，导致JSON序列化失败，这里把参数中的shareType作为返回的值
                let meta = try JSONDecoder().decode(BitableShareMeta.self, from: data)
                DispatchQueue.main.async {
                    completion?(.success(meta), code)
                }
            } catch {
                DocsLogger.error("fetch bitable meta failed, decode error: \(error)")
                DispatchQueue.main.async {
                    completion?(.failure(error), nil)
                }
            }
        })
    }
    
    public func fetchBaseRecordShareMeta(param: BitableShareParam, completion: ((Result<BitableShareMeta, Error>, Int?) -> Void)?) {
        DocsLogger.info("fetch bitable record share meta start")
        let path = OpenAPI.APIPath.getBaseRecordShareMeta
        spaceAssert(param.shareType == .record, "share type is not base record!")
        var parameters: [String: Any] = [
            "token": param.baseToken,
            "tableID": param.tableId,
        ]
        parameters["recordID"] = param.recordId
        
        let request = DocsRequest<JSON>(path: path, params: parameters)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: Const.defaultNetTimeout)
            .set(needVerifyData: true)
            .makeSelfReferenced()
        request.start(callbackQueue: callbackQueue, result: { (json, error) in
            guard let json = json else {
                let error = error ?? DocsNetworkError.invalidData
                DocsLogger.error("fetch bitable record share meta failed: \(error)")
                DispatchQueue.main.async {
                    completion?(.failure(error), nil)
                }
                return
            }
            DocsLogger.info("fetch bitable record share meta success")
            let code = json["code"].intValue
            var dicData = json["data"]
            let shareToken = dicData["recordShareToken"].stringValue
            guard !shareToken.isEmpty else {
                DocsLogger.error("fetch bitable record share meta fail, empty token!")
                DispatchQueue.main.async {
                    completion?(.failure(DocsNetworkError.invalidData), code)
                }
                return
            }
            let meta = BitableShareMeta(
                flag: .open,
                objType: nil,
                shareToken: shareToken,
                shareType: .record,
                constraintExternal: nil
            )
            DispatchQueue.main.async {
                completion?(.success(meta), code)
            }
        })
    }
    
    public func fetchBaseAddRecordShareMeta(param: BitableShareParam, completion: ((Result<BitableShareMeta, Error>, Int?) -> Void)?) {
        if let preShareToken = param.preShareToken {
            let meta = BitableShareMeta(
                flag: .open,
                objType: nil,
                shareToken: preShareToken,
                shareType: param.shareType,
                constraintExternal: nil
            )
            DispatchQueue.main.async {
                completion?(.success(meta), nil)
            }
            return
        }
        DocsLogger.info("fetch bitable add record share meta start")
        let path = OpenAPI.APIPath.getBaseAddRecordShareMeta(param.baseToken)
        spaceAssert(param.shareType == .addRecord, "share type is not base add_record!")
        var parameters: [String: Any] = [
//            "token": param.baseToken,
            "tableID": param.tableId,
        ]
        
        let request = DocsRequest<JSON>(path: path, params: parameters)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: Const.defaultNetTimeout)
            .set(needVerifyData: true)
        request.makeSelfReferenced()
//        let augToken = augmentedToken(of: param.baseToken)
//        userPermissionStore.setUserPermissionRequest(for: augToken, to: request)
        request.start(callbackQueue: callbackQueue, result: { (json, error) in
//            self.userPermissionStore.setUserPermissionResponseTime(for: request.requestID)
            guard let json = json else {
                let error = error ?? DocsNetworkError.invalidData
                DocsLogger.error("fetch bitable add record share meta failed: \(error)")
                DispatchQueue.main.async {
                    completion?(.failure(error), nil)
                }
                return
            }
            DocsLogger.info("fetch bitable add record share meta success")
            let code = json["code"].intValue
            let dicData = json["data"]
            let shareToken = dicData["addRecordToken"].stringValue
            guard !shareToken.isEmpty else {
                DocsLogger.error("fetch bitable add record share meta fail, empty token!")
                DispatchQueue.main.async {
                    completion?(.failure(DocsNetworkError.invalidData), code)
                }
                return
            }
            let meta = BitableShareMeta(
                flag: .open,
                objType: nil,
                shareToken: shareToken,
                shareType: param.shareType,
                constraintExternal: nil
            )
            DispatchQueue.main.async {
                completion?(.success(meta), code)
            }
        })
    }

    ///开启/关闭分享表单
    public func updateFormShareMeta(token: String,
                                    tableID: String,
                                    viewId: String,
                                    recordId: String?,
                                    shareType: Int = 1,
                                    flag: Bool,
                                    complete: ((Bool, String?, Error?) -> Void)? = nil) {
        let path = OpenAPI.APIPath.updateFormMetaPath
        var params: [String: Any] = [
            "baseToken": token,
            "tableId": tableID,
            "viewId": viewId,
            "shareType": shareType,
            "flag": flag ? 1 : 0
        ]
        params["recordId"] = recordId
        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: 20)
            .set(needVerifyData: false)
            .makeSelfReferenced()
        DocsLogger.info("[BTS] update bitable share meta start, flag: \(flag), type: \(shareType)")
        request.start(callbackQueue: callbackQueue, result: { (json, error) in
            DocsLogger.info("[BTS] update bitable share meta end, error: \(error)")
            guard error == nil else {
                DispatchQueue.main.async { complete?(false, nil, error) }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DispatchQueue.main.async { complete?(false, nil, DocsNetworkError.invalidData) }
                return
            }
            guard DocsNetworkError.isSuccess(code) else {
                if code == 800004000 {
                    // 被分享的实体还未准备好(加载中)
                    DispatchQueue.main.async { complete?(false, nil, NSError(domain: DocsNetworkError.errorDomain, code: code)) }
                } else {
                    DispatchQueue.main.async { complete?(false, nil, DocsNetworkError.invalidData) }
                }
                return
            }
            let data: JSON = json["data"]
            let shareToken = data["shareToken"].string
            DispatchQueue.main.async { complete?(true, shareToken, DocsNetworkError.invalidData) }
        })
    }
    
    /// 开启/关闭 Bitable 分享（表单、仪表盘等，和表单开关更新是一个接口）
    public func updateBitableShareFlag(_ flag: Bool, param: BitableShareParam, completion: ((Result<String, Error>) -> Void)?) {
        updateFormShareMeta(
            token: param.baseToken,
            tableID: param.tableId,
            viewId: param.viewId ?? "",
            recordId: param.recordId,
            shareType: param.shareType.rawValue,
            flag: flag
        ) { (ret, shareToken, error) in
            if ret, let shareToken = shareToken {
                completion?(.success(shareToken))
            } else {
                let error = error ?? DocsNetworkError.invalidData
                completion?(.failure(error))
            }
        }
    }

    ///获取表单公共权限
    public func fetchFormPublicPermissions(baseToken: String,
                                           shareToken: String,
                                           complete: ((PublicPermissionMeta?, Error?) -> Void)? = nil) {
        fetchBitablePublicPermissions(baseToken: baseToken, shareToken: shareToken, complete: complete)
    }
    
    /// 获取 Bitable 分享范围
    public func fetchBitablePublicPermissions(baseToken: String, shareToken: String, complete: ((PublicPermissionMeta?, Error?) -> Void)? = nil) {
        // spaceAssert(!shareToken.isEmpty, "shareToken must not empty")
        let path = OpenAPI.APIPath.getFormPermissionSettingPath(baseToken)
        let request = DocsRequest<JSON>(path: path, params: ["shareToken": shareToken])
            .set(method: .GET)
            .set(timeout: 20)
            .set(needVerifyData: true)
            .makeSelfReferenced()

        request.start(callbackQueue: callbackQueue, result: { [weak self] (json, error) in
            guard let self else { return }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("fetch form publicPermissionMeta failed with error", error: error)
                DispatchQueue.main.async {
                    complete?(nil, error)
                }
                return
            }

            let data = json["data"]
            guard code == 0, !data.isEmpty, let publicPermissionMeta = PublicPermissionMeta(formJSON: data) else {
                DocsLogger.error("fetch publicPermissionMeta failed with error", error: error)
                DispatchQueue.main.async {
                    complete?(nil, error)
                }
                return
            }

            if publicPermissionMeta != self.getPublicPermissionMeta(token: baseToken) {
                self.updatePublicPermissionMetas([baseToken: publicPermissionMeta])
            }
            DispatchQueue.main.async { complete?(publicPermissionMeta, error) }
        })
    }

    /// 设置分享表单的填写权限
    public static func updateFormPublicPermission(params: [String: Any], complete: @escaping (JSON?, Error?) -> Void) -> DocsRequest<JSON> {
        return DocsRequest<JSON>(path: OpenAPI.APIPath.updateFormSharePermissionPath, params: params)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .start(result: {(response, error) in
                complete(response, error)
            })
    }
    
    /// 设置 Bitable 公共权限（分享范围）
    public static func updateBitablePublicPermission(
        shareToken: String,
        linkShareEntity: ShareLinkChoice,
        completion: ((Error?) -> Void)?
    ) -> DocsRequest<JSON> {
        let params: [String: Any] = [
            "shareToken": shareToken,
            "linkShareEntity": linkShareEntity.rawValue
        ]
        DocsLogger.info("[BTS] update bitable public permission start, val: \(linkShareEntity.rawValue)")
        return DocsRequest<JSON>(path: OpenAPI.APIPath.updateFormSharePermissionPath, params: params)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: true)
            .start(callbackQueue: DispatchQueue.main, result: {(_, error) in
                if let error = error {
                    DocsLogger.error("[BTS] update bitable public permission failed", error: error)
                    completion?(error)
                    return
                }
                DocsLogger.info("[BTS] update bitable public permission success")
                completion?(nil)
            })
    }

    /// 获取表单协作者列表
    public func fetchFormCollaborators(token: String,
                                    shareToken: String,
                                   shouldFetchNextPage: Bool,
                                   lastPageLabel: String? = nil,
                                       complete: ((CollaboratorResponse?, Error?) -> Void)? = nil) {
        fetchBitableCollaborators(token: token, shareToken: shareToken, shouldFetchNextPage: shouldFetchNextPage, complete: complete)
    }
    
    /// 获取 Bitable 协作者列表（同表单）
    public func fetchBitableCollaborators(
        token: String,
        shareToken: String,
        shouldFetchNextPage: Bool,
        lastPageLabel: String? = nil,
        complete: ((CollaboratorResponse?, Error?) -> Void)? = nil
    ) {
        // spaceAssert(!shareToken.isEmpty, "shareToken must not empty")
        let path = OpenAPI.APIPath.getFormPermissionMembersPath(token)
        var params: [String: Any] = ["shareToken": shareToken]

        if let lastPageLabel = lastPageLabel {
            params["lastLabel"] = lastPageLabel
        }

        let request = DocsRequest<JSON>(
            path: path,
            params: params
        // nolint-next-line: magic number
        ).set(method: .GET).set(timeout: 20).makeSelfReferenced()

        let augToken = augmentedToken(of: shareToken)
        DocsLogger.info("[BTS] update bitable collaborators start")
        request.start(callbackQueue: callbackQueue, result: { [weak self] json, error in
            guard let dict = json?.dictionaryObject,
                let data = dict["data"] as? [String: Any],
                let hasMore = data["hasMore"] as? Bool,
                let collaboratorsDict = data["members"] as? [[String: Any]]
            else {
                DocsLogger.error("PermissionManager fetch collaborator error", error: error, component: LogComponents.permission)
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }

            var items = Collaborator.collaborators(form: collaboratorsDict)
            if let entities = data["entities"] as? [String: Any], let users = entities["users"] as? [String: [String: Any]] {
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.insert(users: users)
                Collaborator.localizeCollaboratorName(collaborators: &items, users: users)
                Collaborator.permissionStatistics(collaborators: &items, users: users)
            }
            self?.collaboratorStore.updateCollaborators(for: augToken, items)
            let thisPageLabel = data["lastLabel"] as? String // 如果是 nil，则代表该文件的协作者数量小于等于 50 个；否则需要业务通过 shouldFetchNextPage 明确是否需要继续请求剩余协作者
            let isFileOwnerFromAnotherTenant = data["is_external"] as? Bool ?? false
            let collaboratorCount = data["totalNum"] as? Int ?? 1 // 1 是因为文件的 owner 一定是协作者
            DocsLogger.info("fetchFormCollaborators items count = \(items.count), total_count = \(collaboratorCount), last_label = \(thisPageLabel)")
            if shouldFetchNextPage, hasMore { // 说明还有下一页，而且外部要求继续请求剩余协作者
                self?.fetchBitableCollaborators(token: token,
                                             shareToken: shareToken,
                                             shouldFetchNextPage: true,
                                             lastPageLabel: thisPageLabel,
                                             complete: complete)
            } else {
                DispatchQueue.main.async { complete?((collaboratorCount, isFileOwnerFromAnotherTenant, thisPageLabel), nil) }
            }
        })
    }

    /// 表单邀请协作者
    /// - Parameters:
    ///   - shareToken: 表单 shareToken
    ///   - candidates: 协作者的候选集合
    ///   - notify: 是否通知被邀请人
    ///   - complete: 请求回来调用的 completion block
    static func inviteFormCollaboratorsRequest(
        shareToken: String,
        candidates: Set<Collaborator>,
        notify: Bool,
        complete: @escaping (JSON?, Error?) -> Void)
    -> DocsRequest<JSON> {
        inviteBitableCollaboratorsRequest(shareToken: shareToken, candidates: candidates, notify: notify, complete: complete)
    }
    
    /// Bitable 邀请协作者
    static func inviteBitableCollaboratorsRequest(
        shareToken: String,
        candidates: Set<Collaborator>,
        notify: Bool,
        complete: @escaping (JSON?, Error?) -> Void
    ) -> DocsRequest<JSON> {
        spaceAssert(!shareToken.isEmpty, "shareToken must not empty")
        var dictionary = [[String: Any]]()
        dictionary = Array(candidates).map {
            return ["memberId": $0.userID,
                    "memberType": $0.rawValue,
                    "permission": 4] //默认传4
        }
        var parameters: [String: Any] = ["members": dictionary]
        parameters.merge(other: ["shareToken": shareToken])
        parameters.merge(other: ["notifyLark": notify ? 1 : 0])
        return DocsRequest<JSON>(path: OpenAPI.APIPath.inviteFormMembersPath, params: parameters)
            .set(needVerifyData: false)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: 20)
            .start(result: { (json, error) in
                guard error == nil else {
                    DocsLogger.error("invite form CollaboratorsRequest failed!", extraInfo: nil, error: error, component: nil)
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


    // 表单删除协作者
    public static func getDeleteFormCollaboratorsRequest(shareToken: String,
                                                     ownerID: String,
                                                     ownerType: Int,
                                                         complete: @escaping (Result<Void, Error>, JSON?) -> Void) -> DocsRequest<JSON> {
        deleteBitableCollaboratorsRequest(shareToken: shareToken, memberId: ownerID, memberType: ownerType, complete: complete)
    }
    
    // Bitable 删除协作者
    public static func deleteBitableCollaboratorsRequest(
        shareToken: String,
        memberId: String,
        memberType: Int,
        complete: @escaping (Result<Void, Error>, JSON?) -> Void
    ) -> DocsRequest<JSON> {
        spaceAssert(!shareToken.isEmpty, "shareToken must not empty")
        let dictionary: [[String: Any]] = [["memberId": memberId,
                                         "memberType": memberType]]
        var parameters: [String: Any] = ["members": dictionary]
        parameters.merge(other: ["shareToken": shareToken])

        return DocsRequest<JSON>(path: OpenAPI.APIPath.deleteFormMembersPath, params: parameters)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .start(result: { (json, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        complete(.failure(error), json)
                    }
                    return
                }
                guard let code = json?["code"].int else {
                    DocsLogger.error("delete form collaborators request failed, json: \(String(describing: json))")
                    DispatchQueue.main.async {
                        complete(.failure(CollaboratorsError.parseError), json)
                    }
                    return
                }
                guard code == 0 else {
                    DispatchQueue.main.async {
                        complete(.failure(CollaboratorsError.networkError), json)
                    }
                    return
                }
                DispatchQueue.main.async {
                    complete(.success(()), json)
                }
        })
    }
}
