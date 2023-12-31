//
//  UtilTemplateService.swift
//  SKBrowser
//
//  Created by 曾浩泓 on 2021/12/31.
//  


import Foundation
import SKFoundation
import SKCommon
import UniverseDesignToast
import SKResource
import UIKit
import SKUIKit
import LarkUIKit
import EENavigator
import UniverseDesignNotice
import RxRelay
import RxSwift
import SwiftyJSON
import SpaceInterface
import SKInfra

public final class UtilTemplateService: BaseJSService {
    private var template: TemplateModel?
    private var director: DocsCreateDirectorV2?
    private var showTemplateTag: Bool?
    private let disposeBag = DisposeBag()
    private var reportedObjToken: String?// 防止重复上报
    private lazy var tipView: CustomTemplateTipView = {
        let view = CustomTemplateTipView(frame: .zero)
        view.actionDelegate = self
        return view
    }()
    
    var ownerInfo: (isOwner: Bool, ownerID: String)

    var updateDocInfo = PublishRelay<Void>()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        let service = model.permissionConfig.getPermissionService(for: .hostDocument)
        let isOwner = service?.containerResponse?.container?.isOwner ?? false
        let ownerID = model.hostBrowserInfo.docsInfo?.ownerID ?? ""
        self.ownerInfo = (isOwner: isOwner, ownerID: ownerID)
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        model.permissionConfig.hostPermissionEventNotifier.addObserver(self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveTemplateTagChangeNotification),
            name: Notification.Name.Docs.templateTagChange,
            object: nil
        )
        subscribeUpdateDocInfo()
    }
    
    func subscribeUpdateDocInfo() {
        let debounceMilliseconds: Int = 500
        updateDocInfo.debounce(.milliseconds(debounceMilliseconds), scheduler: MainScheduler.instance)
                     .subscribe { [weak self] _ in
            self?.utilUpdateDocInfo()
        }.disposed(by: disposeBag)
    }
    
    private func updateUI() {
        guard let browserVC = self.ui?.hostView.affiliatedViewController as? BrowserViewController,
              !browserVC.isFromTemplatePreview,
              !browserVC.isInVideoConference,
              let docsInfo = hostDocsInfo else {
            return
        }
        guard OpenAPI.enableTemplateTag(docsInfo: docsInfo) else {
            return
        }
        var showTemplate = false
        if !browserVC.isShowingDeleteHintView.value {
            if let showTemplateTag = showTemplateTag {
                showTemplate = showTemplateTag
            } else {
                showTemplate = docsInfo.templateType == .ugcTemplate || docsInfo.templateType == .pgcTemplate
            }
        }
        
        if showTemplate {
            if let docsInfo = hostDocsInfo {
                showBanner(docsInfo, templateUsedCount: template?.usedCount)
            }
        } else {
            ui?.bannerAgent.requestHideItem(tipView)
        }
        ui?.displayConfig.setShowTemplateTag(showTemplate)
        if showTemplate {
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                updateButtonStateWithPermissionSDK()
            } else {
                if let userPermissions = model?.permissionConfig.hostUserPermissions {
                    updateUseButtonState(canDuplicate: userPermissions.canDuplicate(), tipView: tipView)
                } else if let docsInfo = hostDocsInfo {
                    let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
                    permissionManager.fetchUserPermissions(token: docsInfo.token, type: docsInfo.type.rawValue) { [weak self] info, error in
                        guard let view = self?.tipView else { return }
                        if let error = error {
                            DocsLogger.error("fetch user permission error", error: error, component: LogComponents.permission)
                            return
                        }
                        self?.updateUseButtonState(canDuplicate: info?.mask?.canDuplicate() ?? false, tipView: view)
                    }
                }
            }
        }
    }

    private func updateButtonStateWithPermissionSDK() {
        guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
            spaceAssertionFailure()
            return
        }
        let validationBlock = { [weak self] in
            guard let self else { return }
            // 对齐旧逻辑，取不到 hostDocsInfo 默认是 true
            var isSystemTemplate = true
            if let hostDocsInfo = self.hostDocsInfo {
                isSystemTemplate = hostDocsInfo.templateType == .pgcTemplate
            }
            let response: PermissionResponse
            if isSystemTemplate {
                response = permissionService.validate(exemptScene: .duplicateSystemTemplate)
            } else {
                response = permissionService.validate(exemptScene: .useTemplateButtonEnable)
            }
            switch response.result {
            case .allow:
                self.tipView.setUseButtonEnable(true)

            case let .forbidden(denyType, _):
                if case .blockByFileStrategy = denyType {
                    self.tipView.setUseButtonEnableUIStyle(false)
                } else {
                    self.tipView.setUseButtonEnable(false)
                }
            }
        }
        if permissionService.ready {
            validationBlock()
        } else {
            permissionService.updateUserPermission().subscribe { _ in
                validationBlock()
            } onError: { error in
                DocsLogger.error("fetch user permission error when check template banner",
                                 error: error, component: LogComponents.permission)
            }
            .disposed(by: disposeBag)
        }
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func updateUseButtonState(canDuplicate: Bool, tipView: CustomTemplateTipView) {
        let cacEnabled: Bool // 条件访问控制
        if let docsInfo = hostDocsInfo {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCreateCopy,
                                                               fileBizDomain: .ccm,
                                                               docType: docsInfo.type,
                                                               token: docsInfo.token)
            let isSystemTemplate = docsInfo.templateType == .pgcTemplate
            cacEnabled = isSystemTemplate ? true : result.allow // `系统模板`不置灰
        } else {
            cacEnabled = true
        }
        if cacEnabled {
            tipView.setUseButtonEnable(canDuplicate)
        } else {
            tipView.setUseButtonEnableUIStyle(false)
        }
        DocsLogger.info("cacEnabled is \(cacEnabled)")
    }

    private func showBanner(_ docsInfo: DocsInfo?, templateUsedCount: Int?) {
        guard let docsInfo = docsInfo, let templateType = docsInfo.templateType else {
            return
        }
        switch templateType {
        case .pgcTemplate:
            if let usedCount = templateUsedCount {
                tipView.setTemplateType(.pgc(usedCount: usedCount))
            } else {
                tipView.setTemplateType(.pgc(usedCount: nil))
            }
        case .ugcTemplate:
            var ownerUsername = docsInfo.ownerDisplayName
            if ownerUsername.isEmpty {
                ownerUsername = docsInfo.ownerName ?? ""
            }
            tipView.setTemplateType(.ugc(username: ownerUsername, isOwner: docsInfo.isOwner))
        case .egcTemplate, .normal:
            return
        @unknown default:
            return
        }
        ui?.bannerAgent.requestShowItem(tipView)
        reportShow()
    }
    
    @objc
    private func receiveTemplateTagChangeNotification(_ notification: Notification) {
        guard let browserVC = self.ui?.hostView.affiliatedViewController as? BrowserViewController,
              !browserVC.isFromTemplatePreview,
              !browserVC.isInVideoConference else { return }
        guard let info = notification.userInfo else { return }
        guard let objToken = info["objToken"] as? String, let show = info["isShow"] as? Bool else { return }
        guard objToken == hostDocsInfo?.objToken else { return }
        showTemplateTag = show
        updateUI()
    }
    
    private func fetchTemplateInfo() {
        guard let docsInfo = hostDocsInfo else {
            return
        }
        let params: [String: Any] = [
            "obj_token": docsInfo.objToken,
            "obj_type": docsInfo.inherentType.rawValue
        ]
        RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.templateInfoV2,
                     params: params,
                     method: .GET)
            .flatMap { (result) -> Observable<TemplateModel> in
                if let result = result,
                   let data = result["data"]["template"].rawString()?.data(using: .utf8) {
                    do {
                        let model = try JSONDecoder().decode(TemplateModel.self, from: data)
                        return .just(model)
                    } catch {
                        spaceAssertionFailure("parse data error \(error)")
                        return .error(error)
                    }
                } else {
                    spaceAssertionFailure("cannot parse templateRecommendBottom")
                    return .error(DocsNetworkError.invalidData)
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.template = $0
                self.updateUI()
            })
            .disposed(by: disposeBag)
    }
}
extension UtilTemplateService: DocsPermissionEventObserver {
    // 这里是为了文档owner转移后，重新请求meta信息，更新banner
    public func onCopyPermissionUpdated(canCopy: Bool) {
        let service = self.model?.permissionConfig.getPermissionService(for: .hostDocument)
        let isOwner = service?.containerResponse?.container?.isOwner ?? false
        let ownerID = self.model?.hostBrowserInfo.docsInfo?.ownerID ?? ""
        if self.ownerInfo.isOwner == isOwner,
           self.ownerInfo.ownerID == ownerID {
            return
        }
        self.ownerInfo = (isOwner: isOwner, ownerID: ownerID)
        self.updateDocInfo.accept(())
    }
     
    func utilUpdateDocInfo() {
        guard needFetchTemplateInfo else { return }
        model?.jsEngine.simulateJSMessage(DocsJSService.utilUpdateDocInfo.rawValue, params: ["docsInfo": docsInfo, "forceRequest": true])
    }
}
extension UtilTemplateService: BrowserViewLifeCycleEvent {
    
    var needFetchTemplateInfo: Bool {
        guard let docsInfo = hostDocsInfo else {
            return false
        }
        if  docsInfo.templateType == .pgcTemplate ||
            docsInfo.templateType == .ugcTemplate ||
            docsInfo.templateType == .egcTemplate {
            return true
        }
        return false
    }

    public func browserDidUpdateDocsInfo() {
        guard let docsInfo = hostDocsInfo else {
            return
        }
        updateUI()
        if (docsInfo.templateType == .pgcTemplate ||
            docsInfo.templateType == .ugcTemplate ||
            docsInfo.templateType == .egcTemplate),
            template == nil {
            fetchTemplateInfo()
        }
    }
    
    public func browserDidAppear() {
        guard let browserVC = self.ui?.hostView.affiliatedViewController as? BrowserViewController,
              !browserVC.isFromTemplatePreview,
              !browserVC.isInVideoConference else { return }
        browserVC.isShowingDeleteHintView
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateUI()
            })
            .disposed(by: disposeBag)
    }
}
extension UtilTemplateService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] { return [] }
    public func handle(params: [String: Any], serviceName: String) { }
}
extension UtilTemplateService: CustomTemplateTipViewDelegate {
    func templateTipViewDidClickUseButton(_ templateTipView: CustomTemplateTipView) {
        didClickUseTemplate()
        reportClick()
    }
    func templateTipViewDidClickLink(_ templateTipView: CustomTemplateTipView) {
        guard let vc = self.ui?.hostView.affiliatedViewController else {
            return
        }
        if hostDocsInfo?.templateType == .ugcTemplate {
            if let ownerID = hostDocsInfo?.ownerID {
                HostAppBridge.shared.call(ShowUserProfileService(userId: ownerID, fromVC: vc))
            }
        } else if hostDocsInfo?.templateType == .pgcTemplate {
            openTemplateCenter()
        }
    }

    private func checkCanUseTemplate(token: String, type: DocsType, controller: UIViewController) -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let request = PermissionRequest(entity: .ccm(token: token, type: type),
                                            operation: .createCopy,
                                            bizDomain: .ccm)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: controller)
            return response.allow
        } else {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCreateCopy,
                                                               fileBizDomain: .ccm,
                                                               docType: type,
                                                               token: token)
            if result.allow { return true }
            switch result.validateSource {
            case .fileStrategy:
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCreateCopy,
                                                             fileBizDomain: .ccm,
                                                             docType: type,
                                                             token: token)
            case .securityAudit:
                if let view = ui?.editorView {
                    UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: view)
                }
            case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                DocsLogger.info("unknown type or dlp type")
            }
            return false
        }
    }

    private func didClickUseTemplate() {
        guard DocsNetStateMonitor.shared.isReachable else {
            return
        }
        guard let docsInfo = hostDocsInfo,
              let hostView = ui?.hostView.window,   // // Docx@Base 情况下，应该显示在 window 上，避免被 docx 盖住
              let currentVC = self.registeredVC else {
            return
        }
        let templateToken = docsInfo.token
        let docsType = docsInfo.type

        let isSystemTemplate = docsInfo.templateType == .pgcTemplate
        if !isSystemTemplate {
            guard checkCanUseTemplate(token: templateToken,
                                      type: docsType,
                                      controller: currentVC) else {
                return
            }
        }

        UDToast.showLoading(
            with: BundleI18n.SKResource.Doc_List_TemplateCreateLoading,
            on: hostView,
            disableUserInteraction: true
        )
        director = DocsCreateDirectorV2(
            type: docsType,
            ownerType: SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType,
            name: nil,
            in: ""
        )
        director?.createByTemplate(templateObjToken: docsInfo.objToken,
                                   templateType: .custom,
                                   templateCenterSource: nil,
                                   statisticsExtra: nil,
                                   completion: {[weak self, weak hostView] newDocsToken, vc, newDocsType, _, error in
            guard let self = self, let hostView = hostView else {
                return
            }
            UDToast.removeToast(on: hostView)
            if let error = error {
                DocsLogger.info("Create By template error: \(error)")
                let message: String
                if let docsError = error as? DocsNetworkError {
                    message = docsError.code.templateErrorMsg()
                } else {
                    message = BundleI18n.SKResource.Doc_List_TemplateGeneralErrorToast
                }
                QuotaAlertPresentor.shared.showQuotaAlertIfNeed(
                    type: .createByTemplate,
                    defaultToast: message,
                    error: error,
                    from: currentVC,
                    token: docsInfo.objToken
                )
                return
            }
            guard let targetVC = vc else {
                return
            }
            self.jumpTo(docsViewController: targetVC, from: currentVC)
            self.reportCreate(docsToken: newDocsToken, docsType: newDocsType)
        })
    }
    
    private func jumpTo(docsViewController: UIViewController, from: UIViewController) {
        model?.userResolver.navigator.push(docsViewController, from: from)
    }
    
    private func openTemplateCenter() {
        guard let currentVC = self.registeredVC else {
            return
        }
        let vc = TemplateCenterViewController(
            initialType: .gallery,
            source: .docsBanner
        )
        if SKDisplay.pad {
            vc.modalPresentationStyle = .formSheet
            vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
            vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
            let nav = LkNavigationController(rootViewController: vc)
            model?.userResolver.navigator.present(nav, from: currentVC)
        } else {
            model?.userResolver.navigator.push(vc, from: currentVC)
        }
        reportOpenTemplateCenter()
    }
    
    private func reportClick() {
        guard let docsInfo = hostDocsInfo, let template = template else { return }
        TemplateCenterTracker.reportDocsBannerClick(template: template, docsInfo: docsInfo, clickType: .use)
    }
    
    private func reportCreate(docsToken: String?, docsType: DocsType?) {
        guard let docsInfo = hostDocsInfo, let template = template else { return }
        guard let docsToken = docsToken, let docsType = docsType else {
            return
        }
        let ext: [String: Any] = [
            "file_id": docsToken.encryptToken,
            "create_file_type": docsType.rawValue
        ]
        TemplateCenterTracker.reportDocsBannerClick(template: template, docsInfo: docsInfo, clickType: .create, extParams: ext)
    }
    private func reportShow() {
        guard let docsInfo = hostDocsInfo, let template = template else { return }
        guard reportedObjToken != docsInfo.objToken else { return }
        TemplateCenterTracker.reportDocsBannerShow(template: template, docsInfo: docsInfo)
        reportedObjToken = docsInfo.objToken
    }
    private func reportOpenTemplateCenter() {
        guard let docsInfo = hostDocsInfo, let template = template else { return }
        let ext: [String: Any] = [
            "target": TemplateCenterTracker.PageType.systemCenter.rawValue
        ]
        TemplateCenterTracker.reportDocsBannerClick(template: template, docsInfo: docsInfo, clickType: .openTemplateCenter, extParams: ext)
    }
}
