//
//  BrowserView+Permission.swift
//  SpaceKit
//
//  Created by Gill on 2019/12/11.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource
import EENavigator
import SKUIKit
import UniverseDesignEmpty
import SKInfra
import SpaceInterface

private var allowCopyKey: UInt8 = 0

struct BrowserPermissionModel {
    /// 前端直接告诉我们的公共权限
    var publicPermissions: PublicPermissionMeta = PublicPermissionMeta()
    /// 从网络重新拉取的权限信息，带有更多的信息
    var publicPermissionMeta: PublicPermissionMeta?
}

class BrowserPermissionManager {
    let hostPermissionNotifier = DocsPermissionEventNotifier()
    // 负责关联文档的权限通知
    private var permissionNotifiers: [String: DocsPermissionEventNotifier] = [:]
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    func getPermissionNotifier(for objToken: String) -> DocsPermissionEventNotifier {
        if let notifier = permissionNotifiers[objToken] {
            return notifier
        }
        let notifier = DocsPermissionEventNotifier()
        permissionNotifiers[objToken] = notifier
        return notifier
    }

    var hostPermissionModel = BrowserPermissionModel()
    // 考虑到可复制点位用的地方比较多，这里给一个点位计算的缓存
    /// 可复制点位
    private var canCopyFlags: [String: Bool] = [:]
    var allCanCopy: Bool { canCopyFlags.values.allSatisfy { $0 } }
    func checkCanCopy(for objToken: String) -> Bool { canCopyFlags[objToken] ?? false }
    func set(canCopy: Bool, for objToken: String) { canCopyFlags[objToken] = canCopy }

    /// 用户权限模型
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    private var userPermissions: [String: UserPermissionAbility] = [:]
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    func getUserPermission(for objToken: String) -> UserPermissionAbility? { userPermissions[objToken] }
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    func set(userPermission: UserPermissionAbility?, for objToken: String) { userPermissions[objToken] = userPermission }

    /// 新用户权限模型
    private(set) var permissionServices: [String: UserPermissionService] = [:]
    func getPermissionService(for objToken: String) -> UserPermissionService? {
        permissionServices[objToken]
    }

    func getPermissionService(for objToken: String, objType: DocsType) -> UserPermissionService {
        if let service = permissionServices[objToken] { return service }
        let service = DocsContainer.shared.resolve(PermissionSDK.self)!
            .userPermissionService(for: .document(token: objToken, type: objType))
        service.notifyResourceWillAppear()
        permissionServices[objToken] = service
        return service
    }
    
    func getPermissionService(for docsInfo: DocsInfo) -> UserPermissionService {
        let meta = docsInfo.getMeta()
        if let service = permissionServices[meta.objToken] { return service }
        var dlpMeta: SpaceMeta?
        if meta.objType == .sync {
            dlpMeta = docsInfo.getMeta(include: [.version])
        }
        let service = DocsContainer.shared.resolve(PermissionSDK.self)!
            .userPermissionService(for: .document(token: meta.objToken, type: meta.objType), withPush: false, extraInfo: PermissionExtraInfo(dlpMeta: dlpMeta))
        permissionServices[meta.objToken] = service
        return service
    }

    func clear() {
        permissionNotifiers = [:]
        userPermissions = [:]
        permissionServices = [:]
        canCopyFlags = [:]
    }
}

extension BrowserView: BrowserPermissionConfig {
    public func getPermissionService(for docsType: SpaceInterface.DocsType, objToken: String) -> SpaceInterface.UserPermissionService? {
        permissionManager.getPermissionService(for: objToken, objType: docsType)
    }
    

    @available(*, deprecated, message: "Disambiguate using hostUserPermissions - PermissionUpdate")
    public var userPermissions: UserPermissionAbility? {
        get {
            hostUserPermissions
        }
        set {
            hostUserPermissions = newValue
        }
    }

    @available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK | hostUserPermissions")
    public var hostUserPermissions: UserPermissionAbility? {
        get {
            guard let token = docsInfo?.getToken() else {
                return nil
            }
            return permissionManager.getUserPermission(for: token)
        }
        set {
            guard let token = docsInfo?.getToken() else {
                spaceAssertionFailure("set host user permission when docsInfo not ready")
                return
            }
            permissionManager.set(userPermission: newValue, for: token)
        }
    }

    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func getUserPermission(for documentType: BrowserDocumentType) -> UserPermissionAbility? {
        let targetToken: String
        let documentType: BrowserDocumentType = UserScopeNoChangeFG.WWJ.permissionReferenceDocumentEnable ? documentType : .hostDocument
        switch documentType {
        case .hostDocument:
            guard let hostToken = docsInfo?.getToken() else {
                spaceAssertionFailure("host document token not found when update user permission")
                return nil
            }
            targetToken = hostToken
        case let .referenceDocument(objToken):
            targetToken = objToken
        }
        return permissionManager.getUserPermission(for: targetToken)
    }

    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func update(userPermission: UserPermissionAbility?,
                       for documentType: BrowserDocumentType,
                       objType: DocsType) {
        let documentType: BrowserDocumentType = UserScopeNoChangeFG.WWJ.permissionReferenceDocumentEnable ? documentType : .hostDocument
        switch documentType {
        case .hostDocument:
            guard let hostToken = docsInfo?.getToken() else {
                spaceAssertionFailure("host document token not found when update user permission")
                return
            }
            let oldPermission = permissionManager.getUserPermission(for: hostToken)
            onHostUserPermissionsUpdated(oldValue: oldPermission, newValue: userPermission)
        case let .referenceDocument(objToken):
            onReferenceUserPermissionsUpdated(objToken: objToken, objType: objType, newValue: userPermission)
        }
    }

    public var publicPermissionMeta: PublicPermissionMeta? {
        return permissionManager.hostPermissionModel.publicPermissionMeta
    }
    
    public var isShowingApplyPermissionView: Bool {
        return isShowApplyPermissionView
    }

    @available(*, deprecated, message: "Disambiguate using hostCanCopy - PermissionUpdate")
    public var canCopy: Bool {
        hostCanCopy
    }
    public var hostCanCopy: Bool {
        checkCanCopy(for: .hostDocument)
    }
    
    ///宿主文档是否可截屏需要判断所有引用block的权限
    public var hostCaptureAllowed: Bool {
        guard let token = docsInfo?.getToken() else {
            return false
        }
        return permissionManager.checkCanCopy(for: token) && permissionManager.allCanCopy
    }
    
    public func checkCanCopy(for documentType: BrowserDocumentType) -> Bool {
        let documentType: BrowserDocumentType = UserScopeNoChangeFG.WWJ.permissionReferenceDocumentEnable ? documentType : .hostDocument
        switch documentType {
        case .hostDocument:
            guard let hostToken = docsInfo?.getToken() else {
                DocsLogger.warning("host document token not found when check can copy")
                return false
            }
            return permissionManager.checkCanCopy(for: hostToken)
        case let .referenceDocument(objToken):
            return permissionManager.checkCanCopy(for: objToken)
        }
    }

    public func showApplyPermissionView(_ canApply: Bool,
                                        name: String,
                                        ownerID: String,
                                        blockType: SKApplyPermissionBlockType) {
        // 暴露出去，方便做一些事
        let container = self.delegate?.browserPermissionHostView(self) ?? self
        self.delegate?.browserViewWillShowNoPermissionView(self)
        dismissApplyPermissionView()

        guard let docsInfo = docsInfo else { return }
        let meta = docsInfo.getMeta()
        let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: meta.objToken)
        let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: meta.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: meta.objType.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: meta.objType.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        
        let applyPermissionView = SKApplyPermissionView(token: meta.objToken,
                                                        type: meta.objType,
                                                        canApplyPermission: canApply,
                                                        ownerName: name,
                                                        ownerID: ownerID,
                                                        permStatistics: permStatistics,
                                                        applyType: blockType)
        applyPermissionView.delegate = self
        container.addSubview(applyPermissionView)
        container.bringSubviewToFront(applyPermissionView)
        applyPermissionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        switch blockType {
        case .adminBlock, .previewControlByCAC:  ///预览管控
            applyPermissionView.iconImage = UDEmptyType.noPreview.defaultImage()
            applyPermissionView.tipTitle = ""
            applyPermissionView.tipDetail = BundleI18n.SKResource.CreationMobile_Docs_UnableToAccess_SecurityReason
        case .shareControlByCAC:  /// cac分享管控
            applyPermissionView.iconImage = UDEmptyType.noAccess.defaultImage()
            applyPermissionView.tipDetail = BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoPerm_Description
        default: break
        }
        
        if !UserScopeNoChangeFG.ZYS.disableBarHiddenInPermView {
            self.setCatalogueBanner(visible: false)
        }
        self.applyPermissionView = applyPermissionView
        self.isShowApplyPermissionView = true
        self.noPermissionNotifyEvent()
    }
    
    public func dismissApplyPermissionView() {
        if !UserScopeNoChangeFG.ZYS.disableBarHiddenInPermView {
            self.setCatalogueBanner(visible: true)
        }
        self.isShowApplyPermissionView = false
        if applyPermissionView != nil {
            applyPermissionView?.removeFromSuperview()
            applyPermissionView = nil
        }
    }
    
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    private func onHostUserPermissionsUpdated(oldValue: UserPermissionAbility?, newValue: UserPermissionAbility?) {
        guard let docsInfo = self.docsInfo else { return }
        let meta = docsInfo.getMeta()
        permissionManager.set(userPermission: newValue, for: meta.objToken)
        updateCanCopy(objToken: meta.objToken, objType: meta.objType, userPermission: newValue)
        let canCopy = hostCanCopy
        
        permissionManager.hostPermissionNotifier.allObservers.forEach {
            $0.onCopyPermissionUpdated(canCopy: canCopy)
            $0.onViewPermissionUpdated(oldCanView: oldValue?.canView() ?? false,
                                       newCanView: newValue?.canView() ?? false)
        }
    }

    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    private func onReferenceUserPermissionsUpdated(objToken: String, objType: DocsType, newValue: UserPermissionAbility?) {
        permissionManager.set(userPermission: newValue, for: objToken)
        updateCanCopy(objToken: objToken, objType: objType, userPermission: newValue)
    }

    private func updateCaptureAllowed() {
        let desc2 = "\(ObjectIdentifier(viewCapturePreventer.contentView))"
        let isCaptureAllowed = hostCaptureAllowed
        viewCapturePreventer.isCaptureAllowed = isCaptureAllowed
        permissionManager.hostPermissionNotifier.allObservers.forEach {
            $0.onCaptureAllowedUpdated()
        }
        DocsLogger.info("viewCapturePreventer ContentView: \(desc2), set `isCaptureAllowed` -> \(isCaptureAllowed)")
    }

    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func notifyPermissionUpdate(for documentType: BrowserDocumentType, type: DocsType) {
        switch documentType {
        case .hostDocument:
            guard let docsInfo else {
                return
            }
            let hostMeta = docsInfo.getMeta()
            updateCanCopy(objToken: hostMeta.objToken, objType: hostMeta.objType, userPermission: permissionManager.getUserPermission(for: hostMeta.objToken))
        case .referenceDocument(let objToken):
            updateCanCopy(objToken: objToken, objType: type, userPermission: permissionManager.getUserPermission(for: objToken))
        }
    }

    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    private func updateCanCopy(objToken: String, objType: DocsType, userPermission: UserPermissionAbility?) {
        let oldPermission = permissionManager.getUserPermission(for: objToken)
        let oldCanCopy = oldPermission?.canCopy() ?? false
        let isAdminCanCopy = DocPermissionHelper.checkPermission(.ccmCopy,
                                                                 meta: SpaceMeta(objToken: objToken, objType: objType),
                                                                 showTips: false)
        let status = DlpManager.status(with: objToken, type: objType, action: .COPY)
        let isDlpCanCopy = (status == .Safe)
        let canView = userPermission?.canView() ?? false // 特殊处理: 不能阅读时(显示申请权限视图)允许正常截图
        let userCanCopy = userPermission?.canCopy() ?? false
        let newCanCopy = (userCanCopy && isAdminCanCopy && isDlpCanCopy) || (canView == false)
        DocsLogger.info("update user permission can copy flag",
                        extraInfo: [
                            "objToken": DocsTracker.encrypt(id: objToken),
                            "objType": objType,
                            "canCopy": newCanCopy,
                            "oldCanCopy": oldCanCopy,
                            "adminCanCopy": isAdminCanCopy,
                            "dlpCanCopy": isDlpCanCopy,
                            "canView": canView
                        ])
        permissionManager.set(canCopy: newCanCopy, for: objToken)
        updateCaptureAllowed()
    }

    @available(*, deprecated, message: "Disambiguate using hostPermissionEventNotifier - PermissionUpdate")
    public var permissionEventNotifier: DocsPermissionEventNotifier {
        hostPermissionEventNotifier
    }

    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public var hostPermissionEventNotifier: DocsPermissionEventNotifier {
        permissionManager.hostPermissionNotifier
    }

    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    public func getPermissionEventNotifier(for documentType: BrowserDocumentType) -> DocsPermissionEventNotifier {
        let documentType: BrowserDocumentType = UserScopeNoChangeFG.WWJ.permissionReferenceDocumentEnable ? documentType : .hostDocument
        switch documentType {
        case .hostDocument:
            return hostPermissionEventNotifier
        case let .referenceDocument(objToken):
            guard let docsInfo = docsInfo else {
                assertionFailure("can not determind objToken is hostToken, which may cause unable to recive host token update by this way")
                return permissionManager.getPermissionNotifier(for: objToken)
            }
            if objToken == docsInfo.getToken() {
                // 如果把 hostToken 当做关联文档传进来，优先返回 hostNotifier
                return hostPermissionEventNotifier
            } else {
                return permissionManager.getPermissionNotifier(for: objToken)
            }
        }
    }
    
    public func noPermissionNotifyEvent() {
        self.delegate?.noPermissionNotifyEvent(self)
    }

    private func isSameTenantWithCurrentUser(tenantID: String) -> Bool {
        if let userTenantID = User.current.info?.tenantID,
           userTenantID == tenantID {
            return true
        }
        return false
    }
}

extension BrowserView: SKApplyPermissionViewDelegate {
    public func getHostVC() -> UIViewController? {
        return currentBrowserVC
    }
    public func presentVC(_ vc: UIViewController, animated: Bool) {
        presentViewController(vc, animated: animated, completion: nil)
    }

    public func showOwnerProfile(ownerID: String, ownerName: String) {
        guard ownerID.isEmpty == false else {
            DocsLogger.warning("ownerid is empty")
            return
        }
        guard let vc = self.currentBrowserVC else {
            DocsLogger.warning("vc is nil")
            return
        }
        HostAppBridge.shared.call(ShowUserProfileService(userId: ownerID, fromVC: vc))
    }
}

// MARK: PermissionSDK impl
extension BrowserView {
    public func getPermissionService(for documentType: BrowserDocumentType) -> UserPermissionService? {
        switch documentType {
        case .hostDocument:
            guard let docsInfo else {
                spaceAssertionFailure("host document token not found when update user permission")
                return nil
            }
            return permissionManager.getPermissionService(for: docsInfo)
        case let .referenceDocument(objToken):
            return permissionManager.getPermissionService(for: objToken)
        }
    }

    public func update(permissionData: Data, for documentType: BrowserDocumentType, objType: DocsType) {
        switch documentType {
        case .hostDocument:
            guard let docsInfo else {
                spaceAssertionFailure("host document token not found when update user permission")
                return
            }
            let service = permissionManager.getPermissionService(for: docsInfo)
            if let tenantID = docsInfo.tenantID {
                service.update(tenantID: tenantID)
            }
            do {
                let response = try service.setUserPermission(data: permissionData)
                notifyDidUpdate(permisisonResponse: response, for: documentType, objType: objType)
            } catch {
                DocsLogger.error("update host permissionData failed", error: error)
            }
        case let .referenceDocument(objToken):
            let service = permissionManager.getPermissionService(for: objToken, objType: objType)
            if let tenantID = docsInfo?.getBlockTenantId(srcObjToken: objToken) {
                service.update(tenantID: tenantID)
            }
            do {
                let response = try service.setUserPermission(data: permissionData)
                notifyDidUpdate(permisisonResponse: response, for: documentType, objType: objType)
            } catch {
                DocsLogger.error("update reference document permissionData failed", error: error)
            }
        }
    }

    public func notifyDidUpdate(permisisonResponse: UserPermissionResponse?, for documentType: BrowserDocumentType, objType: DocsType) {
        // update canCopy
        switch documentType {
        case .hostDocument:
            guard let docsInfo else {
                spaceAssertionFailure("host document token not found when notify update user permission")
                return
            }
            let hostMeta = docsInfo.getMeta()
            updateCanCopy(objToken: hostMeta.objToken, objType: hostMeta.objType)
            notifyHostUserPermissionsUpdated()
        case let .referenceDocument(objToken):
            updateCanCopy(objToken: objToken, objType: objType)
        }
    }

    private func updateCanCopy(objToken: String, objType: DocsType) {
        let service = permissionManager.getPermissionService(for: objToken, objType: objType)
        var canCopy = service.validate(operation: .copyContent).allow
        DocsLogger.info("update user permission can copy flag",
                        extraInfo: [
                            "objToken": DocsTracker.encrypt(id: objToken),
                            "objType": objType,
                            "canCopy": canCopy
                        ])
        // 这里做一个特化逻辑，如果文档是删除状态，允许 copy 操作
        if case let .noPermission(_, statusCode, _) = service.containerResponse,
           statusCode == .entityDeleted {
            canCopy = true
            DocsLogger.info("override user permission can copy for entityDeleted status",
            extraInfo: [
                "objToken": DocsTracker.encrypt(id: objToken),
                "objType": objToken,
                "canCopy": true
            ])
        }
        permissionManager.set(canCopy: canCopy, for: objToken)
        updateCaptureAllowed()
    }

    private func notifyHostUserPermissionsUpdated() {
        guard let docsInfo else { return }
        let canCopy = hostCanCopy
        let desc2 = "\(ObjectIdentifier(viewCapturePreventer.contentView))"
        DocsLogger.info("viewCapturePreventer ContentView: \(desc2), set `isCaptureAllowed` -> \(canCopy)")
        let service = permissionManager.getPermissionService(for: docsInfo)
        let canView = service.validate(operation: .view).allow
        permissionManager.hostPermissionNotifier.allObservers.forEach {
            $0.onCopyPermissionUpdated(canCopy: canCopy)
            $0.onViewPermissionUpdated(oldCanView: false,
                                       newCanView: canView)
        }
    }

    func notifyWillAppearForPermission() {
        permissionManager.permissionServices.values.forEach { service in
            service.notifyResourceWillAppear()
        }
    }

    func notifyDidDisappearForPermission() {
        permissionManager.permissionServices.values.forEach { service in
            service.notifyResourceDidDisappear()
        }
    }
}
