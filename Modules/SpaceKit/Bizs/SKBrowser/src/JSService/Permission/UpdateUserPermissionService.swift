//
//  UpdateUserPermissionService.swift
//  SpaceKit
//
//  Created by LiXiaolin on 2019/6/25.
//

import SKCommon
import SKFoundation
import SwiftyJSON
import RxSwift
import SpaceInterface
import SKInfra
import EENavigator
import WebBrowser

private struct BitableProInfo: Codable {
    
    // V1 版本：高级权限下 Owner 是前端拼好给客户端的，但是有边缘 Case 下前端可能取不到
    private struct BitableOwnerInfo: Codable {
        let id: String?
        let name: String?
        let display_name: UserAliasInfo?
    }
    
    // V2 版本：由后端返回，前端透传给客户端
    private struct BitableOwnerInfoV2: Codable {
        let userID: String?
        let name: String?
        let enName: String?
        let avatarUrl: String?
        let i18nName: String?
    }
    
    private struct Extra: Codable {
        let ownerInfo: BitableOwnerInfoV2?
    }
    
    let isAdvancedBase: Bool
    let isBaseAdmin: Bool
    let applyRoleIDs: [String]?
    
    private let owner: BitableOwnerInfo?
    
    private let extra: Extra?
}

extension BitableProInfo {
    
    var needApplyPro: Bool {
        // 开启了高级权限 && 不是管理员角色 && 没有命中任何角色组
        isAdvancedBase && !isBaseAdmin && applyRoleIDs?.isEmpty != false
    }
    
    var userId: String {
        if UserScopeNoChangeFG.ZYS.adPermApplyOwnerInfo, let uid = extra?.ownerInfo?.userID {
            // V2 版本：由后端返回，前端透传给客户端
            return uid
        }
        if let uid = owner?.id {
            // V1 版本：高级权限下 Owner 是前端拼好给客户端的，但是有边缘 Case 下前端可能取不到
            return uid
        }
        return ""
    }
    
    var displayName: String {
        if UserScopeNoChangeFG.ZYS.adPermApplyOwnerInfo, let extra = extra {
            // V2 版本：由后端返回，前端透传给客户端
            if let jsonStr = extra.ownerInfo?.i18nName, let data = jsonStr.data(using: .utf8) {
                do {
                    let alias = try JSONDecoder().decode(UserAliasInfo.self, from: data)
                    return alias.currentLanguageDisplayName ?? ""
                } catch {
                    DocsLogger.error("[BAP] BitableProInfo displayName decode error")
                    return extra.ownerInfo?.name ?? (extra.ownerInfo?.enName ?? "")
                }
            } else {
                return extra.ownerInfo?.name ?? (extra.ownerInfo?.enName ?? "")
            }
        }
        if let owner = owner {
            // V1 版本：高级权限下 Owner 是前端拼好给客户端的，但是有边缘 Case 下前端可能取不到
            if let displayName = owner.display_name?.currentLanguageDisplayName {
                return displayName
            } else {
                return owner.name ?? ""
            }
        }
        return ""
    }
}

class UpdateUserPermissionService: BaseJSService {
    var disposeBag = DisposeBag()
    let leaderPermHandler = LeaderPermHandler()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension UpdateUserPermissionService: BrowserViewLifeCycleEvent {

    func browserWillClear() {
        if model?.permissionConfig.isShowingApplyPermissionView == true {
            DocsLogger.info("browserWillClear dismissApplyPermissionView")
            model?.permissionConfig.dismissApplyPermissionView()
        }
    }

    func browserDidUpdateDocsInfo() {
        if let hostService = model?.permissionConfig.getPermissionService(for: .hostDocument),
           let tenantID = hostDocsInfo?.tenantID {
            hostService.update(tenantID: tenantID)
        }
    }
}

extension UpdateUserPermissionService: DocsJSServiceHandler {

    var isBrowserVisible: Bool {
        if let webBrowserView = self.ui as? WebBrowserView {
            return !webBrowserView.isInEditorPool
        }
        return false
    }

    var handleServices: [DocsJSService] {
        return [.userDocPermission]
    }

    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .userDocPermission:
            notifyPermissionChange(params: params)
        default:
            break
        }
    }

    func notifyPermissionChange(params: [String: Any]) {
        DocsLogger.info("UpdateUserPermissionService notifyPermissionChange", component: LogComponents.permission)
        guard let objToken = params["token"] as? String, let typeValue = params["type"] as? Int else {
            DocsLogger.error("UpdateUserPermissionService，failed to parse token or type from params")
            return
        }
        disposeBag = DisposeBag()
        let objType = DocsType(rawValue: typeValue)
        if isCurrentDoc(token: objToken) {
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                updateHostPermissionV2(objToken: objToken, objType: objType, params: params)
            } else {
                updateHostPermission(objToken: objToken, objType: objType, params: params)
            }
        } else {
            guard UserScopeNoChangeFG.WWJ.permissionReferenceDocumentEnable else { return }
            DocsLogger.info("UpdateUserPermissionService token is not equal current objtoken", component: LogComponents.permission)
            // 非当前文档，按关联文档处理
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                updateReferencePermissionV2(objToken: objToken, objType: objType, params: params)
            } else {
                updateReferencePermission(objToken: objToken, objType: objType, params: params)
            }
        }
    }

    private func updateHostPermission(objToken: String, objType: DocsType, params: [String: Any]) {
        DocsLogger.info("updating host document permission",
                        extraInfo: ["objToken": DocsTracker.encrypt(id: objToken), "objType": objType],
                        component: LogComponents.permission)
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        let userPermissionRequest = permissionManager.fetchUserPermission(token: objToken, type: objType.rawValue)
            .subscribeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { [weak self] userPermission in
                DocsLogger.info("update user permission service fetch user permission success")
                guard let self else { return }
                // 查看中途的监听回调
                DocsLogger.info("UpdateUserPermissionService update user permission")
                self.model?.permissionConfig.update(userPermission: userPermission, for: .hostDocument, objType: objType)
                self.leaderPermHandler.showLeaderManagerAlertIfNeeded(objToken, userPermission: userPermission, topVC: self.navigator?.currentBrowserVC)
                self.notifyOtherService()
            }, onError: { error in
                DocsLogger.error("update user permission service fetch user permission error", error: error, component: LogComponents.permission)
            })

        let publicPermissionRequest = permissionManager.fetchPublicPermission(token: objToken, type: objType.rawValue)
            .subscribeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { _ in
                DocsLogger.info("update user permission service fetch public permission success")
            }, onError: { error in
                DocsLogger.error("update user permission service fetch public permission error", error: error, component: LogComponents.permission)
            })

        Single.zip(userPermissionRequest, publicPermissionRequest)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe { [weak self] (userPermission, publicPermission) in
                if let docsInfo = self?.model?.hostBrowserInfo.docsInfo {
                    PermissionStatistics.shared.updateCcmCommonParameters(docsInfo: docsInfo, userPermission: userPermission, publicPermission: publicPermission)
                }
            }.disposed(by: disposeBag)


        guard let userPermissionsV2 = params["userPermissionsV2"] as? [String: Any] else {
            spaceAssertionFailure()
            DocsLogger.error("no userPermissionsV2 key or to json fail")
            return
        }

        let json = JSON(userPermissionsV2)
        let userPermisson = UserPermission(json: json)

        if userPermisson.shareControlByCAC() {
            DocsLogger.info("show cac share control block permission view by userPermisson")
            model?.permissionConfig.showApplyPermissionView(false, name: "", ownerID: "", blockType: .shareControlByCAC)
        } else if userPermisson.previewControlByCAC() {
            DocsLogger.info("show cac preview control block permission view by userPermisson")
            model?.permissionConfig.showApplyPermissionView(false, name: "", ownerID: "", blockType: .previewControlByCAC)
        }  else if userPermisson.adminBlocked() {
            DocsLogger.info("show admin block permission view")
            model?.permissionConfig.showApplyPermissionView(false, name: "", ownerID: "", blockType: .adminBlock)
        } else if case .bitable = objType {
            showBitableApplyPermissionViewIfNeeded(params)
        } else {
            judgeToShowApplyPermissionView(params: json)
        }
    }

    private func updateReferencePermission(objToken: String, objType: DocsType, params: [String: Any]) {
        DocsLogger.info("updating reference document permission",
                        extraInfo: ["objToken": DocsTracker.encrypt(id: objToken), "objType": objType],
                        component: LogComponents.permission)
        guard let userPermissionsV2 = params["userPermissionsV2"] as? [String: Any] else {
            spaceAssertionFailure()
            DocsLogger.error("updating reference document permission failed, no userPermissionsV2 key or parse json fail")
            return
        }

        let json = JSON(userPermissionsV2)
        let userPermisson = UserPermission(json: json)
        model?.permissionConfig.update(userPermission: userPermisson,
                                       for: .referenceDocument(objToken: objToken),
                                       objType: objType)
    }

    private func judgeToShowApplyPermissionView(params: JSON) {
        guard isBrowserVisible else {
            DocsLogger.info("current browserview is not visible")
            return
        }
        DocsLogger.info("judgeToShowApplyPermissionView")
        // code = 4, 同时permission_status_code = 0, 才显示申请权限页面
        guard let code = params["code"].int,
              let permissionStatusCode = params["data"]["permission_status_code"].int else {
            DocsLogger.info("UpdateUserPermissionService code or permission_status_code is nil", component: LogComponents.permission)
            return
        }
        DocsLogger.info("UpdateUserPermissionService code is \(code), permission_status_code is \(permissionStatusCode)", component: LogComponents.permission)

        guard code == 4 && permissionStatusCode == 0 else {
            // 有权限或密码访问的情况，隐藏申请页
            if true == model?.permissionConfig.isShowingApplyPermissionView,
               //产品要求：slides在vcFollow中，无权限更新为有权限时，不做自动跳转操作。原因slides暂不支持在vcfollow中展示
               docsInfo?.inherentType != .slides || !isInVideoConference {
                DocsLogger.info("judgeToShowApplyPermissionView hide permission view code \(code), permission_status_code \(permissionStatusCode)")
                model?.permissionConfig.dismissApplyPermissionView()
                ui?.displayConfig.rerenderWebview()
            }
            return
        }
        
        let ownerInfo = params["meta"]["owner"]
        let canApply = ownerInfo["can_apply_perm"].bool == true
        let enName = ownerInfo["en_name"].stringValue
        let cnName = ownerInfo["cn_name"].stringValue
        let ownerid = ownerInfo["id"].stringValue
        let tenantID = ownerInfo["tenant_id"].stringValue
        let name: String
        if let aliasData = ownerInfo["display_name"].dictionaryObject,
           let displayName = UserAliasInfo(data: aliasData).currentLanguageDisplayName {
            name = displayName
        } else {
            name = DocsSDK.currentLanguage == .zh_CN ? cnName : enName
        }
        DocsLogger.info("UpdateUserPermissionService showApplyPermissionView \(canApply ? "can" : "can not") canApply")
        model?.permissionConfig.showApplyPermissionView(canApply, name: name,
                                                        ownerID: ownerid, blockType: .userPermissonBlock)
    }

    
    private func showBitableApplyPermissionViewIfNeeded(_ params: [String: Any]) {
        guard isBrowserVisible else {
            DocsLogger.info("current browserview is not visible")
            return
        }
        guard let pInfo = params["userPermissionsV2"] as? [String: Any],
              let code = pInfo["code"] as? Int,
              let pDataDict = pInfo["data"] as? [String: Any],
              let permissionStatusCode = pDataDict["permission_status_code"] as? Int else {
            DocsLogger.error("[BAP] apply | missing code or permission_status_code!", component: LogComponents.permission)
            return
        }
        let bitableProInfoDict = params["bitableProInfo"] as? [String: Any]
        
        DocsLogger.info("[BAP] apply | BAP change, code: \(code), permission_status_code: \(permissionStatusCode), pro info: \(bitableProInfoDict ?? [:])")
        
        var bitableProInfo: BitableProInfo?
        if let jsonDict = bitableProInfoDict {
            do {
                let data = try JSONSerialization.data(withJSONObject: jsonDict)
                bitableProInfo = try JSONDecoder().decode(BitableProInfo.self, from: data)
            } catch {
                DocsLogger.error("[BAP] apply | pro info decode error: \(error)")
                // spaceAssertionFailure("BitableProInfo decode failed: \(error)")
            }
        }
        
        // 1. 已有文档权限
        guard code == 4 else {
            if bitableProInfo?.needApplyPro == true {
                // 缺少高级权限，展示高级权限申请页
                DocsLogger.info("[BAP] apply | show ad permission apply page")
                model?.permissionConfig.showApplyPermissionView(
                    true,
                    name: bitableProInfo?.displayName ?? "",
                    ownerID: bitableProInfo?.userId ?? "",
                    blockType: .bitablePro
                )
            } else {
                // 没有权限需要申请，鉴权通过
                DocsLogger.info("[BAP] apply | permission auth passed!")
                model?.permissionConfig.dismissApplyPermissionView()
            }
            return
        }
        
        // 2. 没有文档权限
        guard permissionStatusCode == 0 else {
            // 2.1 permissionStatusCode != 0，还未走到鉴权，留给前端自己处理
            // 目前只有开启密码访问， permissionStatusCode = 10016 ，需要先展示前端页面进行解密
            DocsLogger.info("[BAP] apply | show no page, permissionStatusCode == \(permissionStatusCode)")
            model?.permissionConfig.dismissApplyPermissionView()
            return
        }
        
        // 2.2 需要鉴权，展示权限申请页面
        let ownerInfo = params["owner"] as? [String: Any]
        let enName = ownerInfo?["en_name"] as? String ?? ""
        let cnName = ownerInfo?["cn_name"] as? String ?? ""
        let ownerid = ownerInfo?["id"] as? String ?? ""
        let name: String
        if let aliasData = ownerInfo?["display_name"] as? [String: Any],
           let displayName = UserAliasInfo(data: aliasData).currentLanguageDisplayName {
            name = displayName
        } else {
            name = DocsSDK.currentLanguage == .zh_CN ? cnName : enName
        }
        var canApply: Bool = false
        if let val = ownerInfo?["admin_can_cross"] as? Bool {
            canApply = val
        }
        
        if !canApply {
            // 展示文档权限申请页（不可申请）
            DocsLogger.info("[BAP] apply | show doc permission not available page")
            model?.permissionConfig.showApplyPermissionView(
                false,
                name: name,
                ownerID: ownerid,
                blockType: .userPermissonBlock
            )
        } else {
            if bitableProInfo?.needApplyPro == true {
                // 展示高级权限申请页
                DocsLogger.info("[BAP] apply | show ad permission apply page")
                model?.permissionConfig.showApplyPermissionView(
                    true,
                    name: name,
                    ownerID: ownerid,
                    blockType: .bitablePro
                )
            } else {
                // 展示文档权限申请页（可申请）
                DocsLogger.info("[BAP] apply | show doc permission apply page")
                model?.permissionConfig.showApplyPermissionView(
                    true,
                    name: name,
                    ownerID: ownerid,
                    blockType: .userPermissonBlock
                )
            }
        }
    }

    private func isCurrentDoc(token: String) -> Bool {
        if token.hasPrefix("wiki") {
            spaceAssertionFailure("UpdateUserPermissionService token is a wikiToken")
            DocsLogger.error("UpdateUserPermissionService token is a wikiToken")
        }
        guard let objToken = model?.hostBrowserInfo.docsInfo?.getToken() else {
            spaceAssertionFailure("UpdateUserPermissionService docsInfo token is nil")
            DocsLogger.error("UpdateUserPermissionService docsInfo token is nil")
            return false
        }
        if objToken.hasPrefix("wiki") {
            spaceAssertionFailure("UpdateUserPermissionService docsInfo token is a wikiToken")
            DocsLogger.error("UpdateUserPermissionService docsInfo token is a wikiToken")
        }
        DocsLogger.info("UpdateUserPermissionService isCurrentDoc token:\(DocsTracker.encrypt(id: token)) objToken:\(DocsTracker.encrypt(id: objToken))")
        return objToken == token
    }
    
    private func notifyOtherService() {
        if let chatModeService = model?.jsEngine.fetchServiceInstance(AIChatModeService.self) {
            chatModeService.handleUserPermissionUpdate()
        } else {
            DocsLogger.info("cannot get chatModeService")
        }
    }
}

// MARK: - PermissionSDK
extension UpdateUserPermissionService {

    private func updateHostPermissionV2(objToken: String, objType: DocsType, params: [String: Any]) {
        guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
            spaceAssertionFailure("update host permission failed, unable to get permissionService")
            return
        }
        if let hostTenantID = hostDocsInfo?.tenantID {
            permissionService.update(tenantID: hostTenantID)
        }
        permissionService.updateUserPermission()
            .observeOn(MainScheduler.instance)
            .do(onSuccess: { [weak self, weak permissionService] response in
                DocsLogger.info("update user permission service fetch user permission success")
                guard let self, let permissionService else { return }

                DocsLogger.info("UpdateUserPermissionService update user permission")
                self.model?.permissionConfig.notifyDidUpdate(permisisonResponse: response, for: .hostDocument, objType: objType)
                guard let containerResponse = permissionService.containerResponse,
                      case let .success(container) = containerResponse else {
                    spaceAssertionFailure("failed to get permission container after load success")
                    return
                }
                self.leaderPermHandler.showLeaderManagerAlertIfNeeded(token: objToken, permissionContainer: container, topVC: self.navigator?.currentBrowserVC)
            }, onError: { error in
                DocsLogger.error("update user permission service fetch user permission error", error: error, component: LogComponents.permission)
            })
            .subscribe().disposed(by: disposeBag)

        permissionService.offlinePermission.observeOn(MainScheduler.instance).subscribe { [weak self] response in
            if response == .success {
                self?.model?.permissionConfig.notifyDidUpdate(permisisonResponse: response, for: .hostDocument, objType: objType)
            }
        }.disposed(by: disposeBag)

        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        let publicPermissionRequest = permissionManager.fetchPublicPermission(token: objToken, type: objType.rawValue)
            .subscribeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { _ in
                DocsLogger.info("update user permission service fetch public permission success")
            }, onError: { error in
                DocsLogger.error("update user permission service fetch public permission error", error: error, component: LogComponents.permission)
            })
        publicPermissionRequest
            .subscribe { [weak self] (publicPermission) in
                if let docsInfo = self?.model?.hostBrowserInfo.docsInfo {
                    // TODO: 补充 userPermission data
                    PermissionStatistics.shared.updateCcmCommonParameters(docsInfo: docsInfo, userPermission: nil, publicPermission: publicPermission)
                }
            }.disposed(by: disposeBag)


        guard let userPermissionsV2 = params["userPermissionsV2"] as? [String: Any] else {
            spaceAssertionFailure()
            DocsLogger.error("no userPermissionsV2 key or to json fail")
            return
        }

        do {
            let permissionData = try JSONSerialization.data(withJSONObject: userPermissionsV2)
            let containerResponse = try permissionService.parsePermissionContainer(data: permissionData)
            switch containerResponse {
            case .success(let container):
                if container.shareControlByCAC {
                    DocsLogger.info("show cac share control block permission view by userPermissonContainer")
                    model?.permissionConfig.showApplyPermissionView(false, name: "", ownerID: "", blockType: .shareControlByCAC)
                    return
                }

                if container.previewControlByCAC {
                    DocsLogger.info("show cac preview control block permission view by userPermisson")
                    model?.permissionConfig.showApplyPermissionView(false, name: "", ownerID: "", blockType: .previewControlByCAC)
                    return
                }

                if container.viewBlockByAudit && UserScopeNoChangeFG.WWJ.auditPermissionControlEnable {
                    DocsLogger.info("show audit block permission view")
                    model?.permissionConfig.showApplyPermissionView(false, name: "", ownerID: "", blockType: .viewBlockByAudit)
                    return
                }

                if container.previewBlockByAdmin {
                    DocsLogger.info("show admin block permission view")
                    model?.permissionConfig.showApplyPermissionView(false, name: "", ownerID: "", blockType: .adminBlock)
                    return
                }

                if objType == .bitable {
                    showBitableApplyPermissionViewIfNeeded(params)
                } else {
                    // 有权限要主动隐藏下申请页
                    hideApplyPermissionView()
                }

            case let .noPermission(_, statusCode, applyUserInfo):
                if objType == .bitable {
                    showBitableApplyPermissionViewIfNeeded(params)
                } else {
                    showApplyPermissionViewIfNeed(statusCode: statusCode, applyInfo: applyUserInfo)
                }
            }
        } catch {
            spaceAssertionFailure()
            DocsLogger.error("parse userPermissionsV2 fail", error: error)
            return
        }
    }

    private func updateReferencePermissionV2(objToken: String, objType: DocsType, params: [String: Any]) {
        DocsLogger.info("updating reference document permission service",
                        extraInfo: ["objToken": DocsTracker.encrypt(id: objToken), "objType": objType],
                        component: LogComponents.permission)
        guard let userPermissionsV2 = params["userPermissionsV2"] as? [String: Any] else {
            spaceAssertionFailure()
            DocsLogger.error("updating reference document permission failed, no userPermissionsV2 key or parse json fail")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: userPermissionsV2)
            model?.permissionConfig.update(permissionData: data, for: .referenceDocument(objToken: objToken), objType: objType)
        } catch {
            spaceAssertionFailure("update reference document permission service failed")
            DocsLogger.error("update reference document permission service failed", error: error)
        }
    }

    private func showApplyPermissionViewIfNeed(statusCode: UserPermissionResponse.StatusCode, applyInfo: AuthorizedUserInfo?) {
        guard isBrowserVisible else {
            DocsLogger.info("current browserview is not visible")
            return
        }
        DocsLogger.info("showApplyPermissionViewIfNeed")
        switch statusCode {
        case .normal:
            // 只有 normal 场景允许展示无权限页面
            if let applyInfo {
                model?.permissionConfig.showApplyPermissionView(true,
                                                                name: applyInfo.getDisplayName(),
                                                                ownerID: applyInfo.userID,
                                                                blockType: .userPermissonBlock)
            } else {
                model?.permissionConfig.showApplyPermissionView(false,
                                                                name: "",
                                                                ownerID: "",
                                                                blockType: .userPermissonBlock)
            }
        default:
            // 密码访问的情况，隐藏申请页
            hideApplyPermissionView()
        }
    }

    private func hideApplyPermissionView() {
        // 有权限或密码访问的情况，隐藏申请页
        guard model?.permissionConfig.isShowingApplyPermissionView == true else {
            // 没有展示无权限页，不需要隐藏
            return
        }
        if hostDocsInfo?.inherentType == .slides && isInVideoConference {
            //产品要求：slides在vcFollow中，无权限更新为有权限时，不做自动跳转操作。原因slides暂不支持在vcfollow中展示
            return
        }
        model?.permissionConfig.dismissApplyPermissionView()
        ui?.displayConfig.refresh()
    }
}
