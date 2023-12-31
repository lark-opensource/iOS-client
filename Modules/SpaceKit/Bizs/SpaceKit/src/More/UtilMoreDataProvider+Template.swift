//
//  UtilMoreDataProvider+Template.swift
//  SpaceKit
//
//  Created by 曾浩泓 on 2022/1/7.
//  


import SKFoundation
import SKCommon
import SKUIKit
import SKSpace
import EENavigator
import SKResource
import RxSwift
import RxRelay
import RxCocoa
import SKBrowser
import LarkAlertController
import UniverseDesignToast
import SwiftyJSON
import SKWikiV2
import LarkUIKit
import LarkSuspendable
import UIKit
import UniverseDesignDialog
import UniverseDesignColor
import SpaceInterface
import SKInfra

extension UtilMoreDataProvider {
    func showInputNameAlertForTemplate() {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let request = PermissionRequest(entity: .ccm(token: docsInfo.token, type: docsInfo.type),
                                            operation: .createCopy,
                                            bizDomain: .ccm)
            let result = permissionSDK.validate(request: request)
            result.didTriggerOperation(controller: hostViewController ?? UIViewController())
            guard result.allow else {
                DocsLogger.error("permission validation failed: \(result.result)")
                return
            }
        } else {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCreateCopy,
                                                               fileBizDomain: .ccm,
                                                               docType: docsInfo.type,
                                                               token: docsInfo.token)
            if result.allow == false {
                switch result.validateSource {
                case .fileStrategy:
                    CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCreateCopy,
                                                                 fileBizDomain: .ccm,
                                                                 docType: docsInfo.type,
                                                                 token: docsInfo.token)
                case .securityAudit:
                    if let view = hostViewController?.view {
                        UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: view)
                    }
                case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                    DocsLogger.info("unknown type or dlp type")
                }
                return
            }
        }
        TemplateCenterTracker.reportManagementTemplateByUser(action: .clickSaveAs, templateMainType: .custom)
        let alert = LarkAlertController()
        let title = docsInfo.title ?? ""
        let tf = alert.addTextField(placeholder: BundleI18n.SKResource.Doc_More_RenameSheetPlaceholder, text: title)
        alert.setTitle(text: BundleI18n.SKResource.Doc_List_SaveAsTmpl, inputView: true)
        alert.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        let saveBtn = alert.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Save) { [weak alert] () -> Bool in
            guard let newName = alert?.textField.text, newName.isEmpty == false, let hostVC = self.hostViewController else { return true }
            self.handleSaveAsTemplate(name: newName, hostVC: hostVC, docsInfo: self.docsInfo)
            return true
        }
        alert.bindInputEventWithConfirmButton(saveBtn)
        guard let hostVC = self.hostViewController else {
            return
        }
        Navigator.shared.present(alert, from: hostVC, animated: true) {
            tf.becomeFirstResponder()
        }
    }
    
    private func handleSaveAsTemplate(name: String, hostVC: UIViewController, docsInfo: DocsInfo) {
        let fileType = docsInfo.type.rawValue
        let objToken = docsInfo.objToken
        UDToast.showDefaultLoading(on: hostVC.view, disableUserInteraction: false)
        let params: [String: Any] = [
            "obj_type": fileType,
            "obj_token": objToken,
            "obj_template_name": name,
            "extra_info": "{\"time_zone\": \"\(TimeZone.current.identifier)\"}"
        ]
        _ = DocsRequest<JSON>(path: OpenAPI.APIPath.saveAsTemplate, params: params)
            .set(method: .POST)
            .makeSelfReferenced()
            .start { [weak hostVC] (_, error) in
                guard let hostVC = hostVC else { return }
                UDToast.removeToast(on: hostVC.view)
                
                if let error = error {
                    QuotaAlertPresentor.shared.showQuotaAlertIfNeed(type: .saveAsTemplate, defaultToast: error.localizedDescription, error: error, from: hostVC, token: objToken)
                } else {
                    self.displayTipsView(on: hostVC)
                    TemplateCenterTracker.reportManagementTemplateByUser(action: .save, templateMainType: .custom)
                }
            }
    }
    func handleDeleteTemplateTag(docsInfo: DocsInfo, hostVC: UIViewController) {
        let fileType = docsInfo.type.rawValue
        let objToken = docsInfo.objToken
        var vc: UIViewController = hostVC
        if (SKDisplay.phone || hostVC.view.isMyWindowRegularSize()), let topVC = UIViewController.docs.topMost(of: hostVC) {
            vc = topVC
        }
        UDToast.showDefaultLoading(on: vc.view, disableUserInteraction: false)
        let params: [String: Any] = ["obj_type": fileType,
                                     "obj_token": objToken,
                                     "new_custom_fg": 1]
        _ = DocsRequest<JSON>(path: OpenAPI.APIPath.deleteDiyTemplate, params: params)
            .set(method: .POST)
            .makeSelfReferenced()
            .start { [weak self] (_, error) in
                guard let self = self else { return }
                UDToast.removeToast(on: vc.view)
                
                if let error = error {
                    QuotaAlertPresentor.shared.showQuotaAlertIfNeed(type: .saveAsTemplate, defaultToast: error.localizedDescription, error: error, from: vc, token: objToken)
                } else {
                    self.docsInfo.setTemplateType(.normal)
                    self.postTemplateTagChange(isShow: false)
                }
                self.reload()
            }
    }
    func handleAddTemplateTag(name: String, hostVC: UIViewController, docsInfo: DocsInfo, enableTemplateTag: Bool = false) {
        var vc: UIViewController = hostVC
        if (SKDisplay.phone || hostVC.view.isMyWindowRegularSize()), let topVC = UIViewController.docs.topMost(of: hostVC) {
            vc = topVC
        }
        
        if docsInfo.type == .bitable, self.bitableBridgeData?.isPro ?? false {
            showDialogForProBitable(fromVC: vc) { [weak self] agree in
                guard agree else {
                    self?.reload()
                    return
                }
                self?.requestAddTemplateTag(name: name, docsInfo: docsInfo, fromVC: vc)
            }
        } else {
            self.requestAddTemplateTag(name: name, docsInfo: docsInfo, fromVC: vc)
        }
    }
    private func showDialogForProBitable(fromVC: UIViewController, completion: @escaping (Bool) -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Bitable_AdvancedPermission_ConvertToTemplatePopupTitle)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel, dismissCompletion: {
            Self.reportProBitableDialogClick(type: .cancel)
            completion(false)
        })
        let confirmBtn = dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_AdvancedPermission_ConvertToTemplatePopupButtonYes, dismissCompletion: {
            Self.reportProBitableDialogClick(type: .confirm)
            completion(true)
        })
        confirmBtn.isEnabled = false
        confirmBtn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        let cv = BitableAdPermDialogContentView(
            contentText: BundleI18n.SKResource.Bitable_AdvancedPermission_ConvertToTemplatePopupContent,
            confirmText: BundleI18n.SKResource.Bitable_AdvancedPermission_DisablePopupContent2
        ) {
            confirmBtn.isEnabled = $0
            if $0 {
                Self.reportProBitableDialogClick(type: .checkbox)
            }
        }
        dialog.setContent(view: cv)
        fromVC.present(dialog, animated: true, completion: nil)
        Self.reportProBitableDialogShow()
    }
    private func requestAddTemplateTag(name: String, docsInfo: DocsInfo, fromVC: UIViewController) {
        let params: [String: Any] = [
            "obj_type": docsInfo.type.rawValue,
            "obj_token": docsInfo.objToken,
            "obj_template_name": name,
            "new_custom_fg": 1,
            "extra_info": "{\"time_zone\": \"\(TimeZone.current.identifier)\"}"
        ]
        UDToast.showDefaultLoading(on: fromVC.view, disableUserInteraction: false)
        _ = DocsRequest<JSON>(path: OpenAPI.APIPath.saveAsTemplate, params: params)
            .set(method: .POST)
            .makeSelfReferenced()
            .start { [weak self] (_, error) in
                guard let self = self else { return }
                UDToast.removeToast(on: fromVC.view)
                if let error = error {
                    let defaultToast: String
                    if let docsError = error as? DocsNetworkError {
                        defaultToast = docsError.code.templateErrorMsg()
                    } else {
                        defaultToast = BundleI18n.SKResource.Doc_List_TemplateGeneralErrorToast
                    }
                    QuotaAlertPresentor.shared.showQuotaAlertIfNeed(type: .saveAsTemplate, defaultToast: defaultToast, error: error, from: fromVC, token: docsInfo.objToken)
                    self.reload()
                } else {
                    UDToast.showSuccess(with: BundleI18n.SKResource.CreationMobile_Template_TransformDone_Toast, on: fromVC.view)
                    self.docsInfo.setTemplateType(DocsInfo.TemplateType.ugcTemplate)
                    self.postTemplateTagChange(isShow: true)
                    self.notifyJSCloseBitableAdvancedPermission()
                    self.reload()
                    TemplateCenterTracker.reportManagementTemplateByUser(action: .save, templateMainType: .custom)
                }
            }
    }
    private func postTemplateTagChange(isShow: Bool) {
        let info: [AnyHashable: Any] = [
            "isShow": isShow,
            "objToken": self.docsInfo.objToken
        ]
        NotificationCenter.default.post(name: .Docs.templateTagChange, object: nil, userInfo: info)
    }
    private func notifyJSCloseBitableAdvancedPermission() {
        guard self.docsInfo.type == .bitable, self.bitableBridgeData?.isPro ?? false else {
            return
        }
        let params: [String: Any] = ["checked": false, "needSendCS": false]
        self.model?.jsEngine.callFunction(.btUpgradeBase, params: params, completion: nil)
    }
    
    func displayTipsView(on hostVC: UIViewController) {
        guard let currentWindow = hostVC.view.window else {
            return
        }
        
        UDToast.showSuccess(with: BundleI18n.SKResource.Doc_List_SaveCustomTemplSuccess,
                            operationText: BundleI18n.SKResource.Doc_List_GoCheckCustomTempl,
                            on: currentWindow,
                            delay: 5,
                            operationCallBack: { [weak hostVC] _ in
                                guard let hostVC = hostVC else {
                                    return
                                }
                                self.pushToTemplateCenter(hostVC: hostVC)
                            })
    }
    private func pushToTemplateCenter(hostVC: UIViewController) {
        // push to 模板中心自定义模板
        let dataProvider = TemplateDataProvider()
        let vm = TemplateCenterViewModel(depandency: (networkAPI: dataProvider, cacheAPI: dataProvider),
                                         shouldCacheFilter: false)
        let vc = TemplateCenterViewController(viewModel: vm,
                                              initialType: .custom,
                                              templateCategory: TemplateCategory.SpecialCategoryId.mine.rawValue,
                                              targetPopVC: hostVC,
                                              source: .fromSaveasCustomtempl)
        if SKDisplay.pad {
            vc.modalPresentationStyle = .formSheet
            vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
            vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
            let nav = LkNavigationController(rootViewController: vc)
            Navigator.shared.present(nav, from: hostVC)
        } else {
            Navigator.shared.push(vc, from: hostVC)
        }
    }
    
    func enableSaveAsCustomTemplateV1() -> Bool {
        var show = true
        if self.docsInfo.type == .docX, show, !LKFeatureGating.templateDocXSaveToCustomEnable {
            show = false
        }
        if show, let isInVideoConference = self.docsInfo.isInVideoConference, isInVideoConference {
            show = false
        }
        if show, self.docsInfo.type == .bitable,
           let isPro = self.bitableBridgeData?.isPro, isPro,
           !LKFeatureGating.bitableAdvancedPermission {
            show = false
        }
        return show
    }
    
    func handleSaveMyTemplate() {
        guard let hostVC = self.hostViewController else { return }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let request = PermissionRequest(entity: .ccm(token: docsInfo.token, type: docsInfo.type),
                                            operation: .createCopy,
                                            bizDomain: .ccm)
            let result = permissionSDK.validate(request: request)
            result.didTriggerOperation(controller: hostVC)
            guard result.allow else {
                DocsLogger.error("permission validation failed: \(result.result)")
                return
            }
        } else {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCreateCopy,
                                                               fileBizDomain: .ccm,
                                                               docType: docsInfo.type,
                                                               token: docsInfo.token)
            if result.allow == false {
                switch result.validateSource {
                case .fileStrategy:
                    CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCreateCopy,
                                                                 fileBizDomain: .ccm,
                                                                 docType: docsInfo.type,
                                                                 token: docsInfo.token)
                case .securityAudit:
                    UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: hostVC.view)
                case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                    DocsLogger.info("unknown type or dlp type")
                }
                return
            }
        }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_Template_SureToSaveThisTemplate_Title)
        dialog.setContent(text: BundleI18n.SKResource.CreationMobile_Template_SureToSaveThisTemplate_Text)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Save, dismissCompletion: { [weak self] in
            self?.requestSaveAsMyTemplate()
        })
        Navigator.shared.present(dialog, from: hostVC, animated: true)
    }
    private func requestSaveAsMyTemplate() {
        guard let hostVC = self.hostViewController, let window = hostVC.view.window else { return }
        let fileType = docsInfo.type.rawValue
        let objToken = docsInfo.objToken
        UDToast.showDefaultLoading(on: hostVC.view, disableUserInteraction: false)
        let params: [String: Any] = [
            "obj_type": fileType,
            "obj_token": objToken,
            "obj_template_name": docsInfo.title ?? "",
            "new_custom_fg": 1,
            "extra_info": "{\"time_zone\": \"\(TimeZone.current.identifier)\"}"
        ]
        _ = DocsRequest<JSON>(path: OpenAPI.APIPath.saveAsTemplate, params: params)
            .set(method: .POST)
            .makeSelfReferenced()
            .start { [weak hostVC] (json, error) in
                guard let hostVC = hostVC else { return }
                UDToast.removeToast(on: hostVC.view)
                
                if let error = error {
                    let defaultToast: String
                    if let docsError = error as? DocsNetworkError {
                        defaultToast = docsError.code.templateErrorMsg()
                    } else {
                        defaultToast = BundleI18n.SKResource.Doc_List_TemplateGeneralErrorToast
                    }
                    QuotaAlertPresentor.shared.showQuotaAlertIfNeed(type: .saveAsTemplate, defaultToast: defaultToast, error: error, from: hostVC, token: objToken)
                } else if let json = json {
                    let data = json["data"]
                    if let token = data["obj_template_token"].string, let type = data["obj_type"].int {
                        let docsType = DocsType(rawValue: type)
                        let url = DocsUrlUtil.url(type: docsType, token: token)
                        Navigator.shared.open(url, from: hostVC)
                        UDToast.showSuccess(
                            with: BundleI18n.SKResource.CreationMobile_Template_Saved,
                            on: window,
                            delay: 5
                        )
                    }
                    TemplateCenterTracker.reportManagementTemplateByUser(action: .save, templateMainType: .custom)
                }
            }
    }

    @available(*, deprecated, message: "Use PermissionService instead - PermissionSDK")
    var saveAsTemplateEnable: Bool {
        let result = validateResult(type: .saveAsTemplate)
        return result.allow && self._canSaveAsTemplate()
    }
    
    private func _canSaveAsTemplate() -> Bool {
        var canSaveAsTemplate = self.userPermissions?.canDuplicate() ?? false
        if self.docsInfo.inherentType.isSupportSaveAsTemplate == false {
            canSaveAsTemplate = false
        }
        return canSaveAsTemplate
    }

    // 返回 (allow, isDisabled, completion)
    func checkSaveAsTemplateEnable(failedTips: String) -> (Bool, Bool, () -> Void) {
        let support = docsInfo.inherentType.isSupportSaveAsTemplate
        let isSystemTemplate = docsInfo.templateType == .pgcTemplate
        let permissionResponse: PermissionResponse
        if isSystemTemplate {
            permissionResponse = permissionService.validate(exemptScene: .duplicateSystemTemplate)
        } else {
            permissionResponse = permissionService.validate(operation: .createCopy)
        }
        let message: String
        if outsideControlItems?[.disable]?.contains(.saveAsTemplate) == true { // 说明是前端控制置灰的，目前只有 bitable 前端会控制这个置灰
            message = BundleI18n.SKResource.Bitable_AdvancedPermission_UnableToSaveAsTemplate
        } else {
            message = failedTips
        }
        let allowSaveAsTemplate = support && permissionResponse.allow
        let needDisabled = support && permissionResponse.result.needDisabled
        let saveCompletion = { [weak self] in
            guard let self, let hostController = self.hostViewController else { return }
            permissionResponse.didTriggerOperation(controller: hostController, message)
            if permissionResponse.allow, !DocsNetStateMonitor.shared.isReachable {
                self.handleDisableEvent(.saveAsTemplate)
            }
        }
        return (allowSaveAsTemplate, needDisabled, saveCompletion)
    }
}

extension UtilMoreDataProvider {
    enum ProBitableDialogClickType: String {
        case checkbox = "tick"
        case confirm = "confirm"
        case cancel = "cancel"
    }
    private static func reportProBitableDialogShow() {
        DocsTracker.newLog(event: DocsTracker.EventType.ccmBitablePremiumPermissionTemplateWarningView.rawValue, parameters: nil)
    }
    private static func reportProBitableDialogClick(type: ProBitableDialogClickType) {
        let params: [String: Any] = [
            "click": type.rawValue,
            "target": "none"
        ]
        DocsTracker.newLog(event: DocsTracker.EventType.ccmBitablePremiumPermissionTemplateWarningClick.rawValue, parameters: params)
    }
}
