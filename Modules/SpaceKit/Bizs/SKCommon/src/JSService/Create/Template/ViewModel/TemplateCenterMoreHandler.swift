//
//  TemplateCenterMoreHandler.swift
//  SKCommon
//
//  Created by bytedance on 2021/2/24.
//

import SKFoundation
import SKUIKit
import SKResource
import EENavigator
import LarkUIKit
import UniverseDesignToast
import UniverseDesignActionPanel
import RxSwift
import UniverseDesignDialog
import UniverseDesignColor
import UIKit
import SwiftyJSON
import SKInfra

public final class TemplateCenterMoreHandler {
    struct PopSource {
        let sourceView: UIView
        let sourceRect: CGRect
        let arrowDirection: UIPopoverArrowDirection
        
        func udActionSheetSource() -> UDActionSheetSource {
            return UDActionSheetSource(
                sourceView: self.sourceView,
                sourceRect: self.sourceRect,
                arrowDirection: self.arrowDirection
            )
        }
    }
    
    static let didDeleteTemplateNotice = PublishSubject<TemplateModel>()
    private let networkAPI: TemplateCenterNetworkAPI
    let fromPage: TemplateCenterTracker.PageType
    let bag = DisposeBag()
    var templateSource: TemplateCenterTracker.TemplateSource?
    var templateCenterSource: TemplateCenterTracker.TemplateCenterSource?
    // 分享链接缓存，key：文档token value：分享链接
    private var shareUrlCache = [String: String]()
    init(networkAPI: TemplateCenterNetworkAPI, fromPage: TemplateCenterTracker.PageType) {
        self.networkAPI = networkAPI
        self.fromPage = fromPage
    }
    
    func showMoreActionSheet(templateModel: TemplateModel, fromVC: UIViewController, popSource: PopSource? = nil, needEdit: Bool = false) {
        let alert = UDActionSheet.actionSheet(popSource: popSource?.udActionSheetSource())
        alert.addDefaultItem(text: BundleI18n.SKResource.Doc_Facade_Share) { [weak fromVC, weak self] in
            TemplateCenterTracker.reportManagementTemplateByUser(action: .clickShare,
                                                                 templateMainType: templateModel.templateMainType)
            self?.reportTemplateShare(template: templateModel)
            
            guard let fromVC = fromVC else { return }
            self?.showShareTemplatePopVCV2(templateModel: templateModel, fromVC: fromVC, popSource: popSource)
        }
        let fromUserId = templateModel.fromUserId ?? ""
        let isCustomOwn = fromUserId.isEmpty || templateModel.tag == .customOwn
        if needEdit, isCustomOwn {
            alert.addDefaultItem(text: BundleI18n.SKResource.Bitable_Common_ButtonEdit) { [weak fromVC] in
                guard let fromVC = fromVC else { return }
                let url = DocsUrlUtil.url(type: templateModel.docsType, token: templateModel.objToken)
                Navigator.shared.open(url, from: fromVC)
            }
        } else {
            DocsLogger.info("needEdit:\(needEdit) fromUserId is nil:\(templateModel.fromUserId == nil)")
        }
        
        alert.addDestructiveItem(text: BundleI18n.SKResource.Doc_Facade_Delete) { [weak fromVC, weak self] in
            TemplateCenterTracker.reportManagementTemplateByUser(action: .clickDelete,
                                                                 templateMainType: templateModel.templateMainType)
            self?.reportTemplateDelete(template: templateModel)
            guard let fromVC = fromVC else { return }
            self?.showDeleteConfirmAlertView(templateModel: templateModel, fromVC: fromVC)
        }
        if !Display.pad {
            alert.setCancelItem(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        }
        Navigator.shared.present(alert, from: fromVC)
    }
    
    func showGalleryTemplateSharePopVC(template: TemplateModel, fromVC: UIViewController, popSource: PopSource? = nil) {
        fetchShareUrl(of: template, with: fromVC) { [weak self] shareUrl in
            guard let self = self else { return }
            guard let shareUrl = shareUrl else {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Doc_NetException, on: fromVC.view)
                return
            }
            self._showGalleryTemplateSharePopVC(template: template, shareUrl: shareUrl, fromVC: fromVC, popSource: popSource)
        }
        reportTemplateShare(template: template)
    }
    private func _showGalleryTemplateSharePopVC(template: TemplateModel, shareUrl: String, fromVC: UIViewController, popSource: PopSource? = nil) {
        let shareEntity = SKShareEntity(
            objToken: template.objToken, type: template.objType, title: template.displayTitle,
            isOwner: false, ownerID: "", displayName: template.displayTitle, tenantID: "",
            isFromPhoenix: false, shareUrl: shareUrl, enableShareWithPassWord: false,
            enableTransferOwner: false, onlyShowSocialShareComponent: true
        )
        let shareVC = SKShareViewController(shareEntity,
                                            source: .content,
                                            isInVideoConference: false)
        shareVC.watermarkConfig.needAddWatermark = true
        let nav = LkNavigationController(rootViewController: shareVC)

        if SKDisplay.pad, fromVC.view.isMyWindowRegularSize() ?? false {
            shareVC.modalPresentationStyle = .popover
            nav.modalPresentationStyle = .popover
            nav.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            nav.popoverPresentationController?.sourceView = popSource?.sourceView
            nav.popoverPresentationController?.sourceRect = popSource?.sourceRect ?? .zero
            nav.popoverPresentationController?.permittedArrowDirections = popSource?.arrowDirection ?? .any
            fromVC.present(nav, animated: true)
        } else {
            nav.modalPresentationStyle = .overFullScreen
            Navigator.shared.present(nav, from: fromVC, animated: false)
        }
    }
    private func fetchShareUrl(of template: TemplateModel, with fromVC: UIViewController, completion: @escaping ((String?) -> Void)) {
        if let shareUrl = shareUrlCache[template.objToken] {
            completion(shareUrl)
            return
        }
        let loading = UDToast.showLoading(with: BundleI18n.SKResource.Doc_Facade_Loading, on: fromVC.view)
        let params: [String: Any] = ["type": template.objType,
                                     "token": template.objToken]
        DocsRequest<JSON>(path: OpenAPI.APIPath.findMeta, params: params)
            .set(method: .GET)
            .rxStart()
            .map({ (result) -> String? in
                return result?["data"]["url"].string
            })
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] shareUrl in
                loading.remove()
                self?.shareUrlCache[template.objToken] = shareUrl
                completion(shareUrl)
            } onError: { error in
                DocsLogger.error("request shareUrl fail: \(error)")
                loading.remove()
                completion(nil)
            }
            .disposed(by: bag)
    }
    
    private func showDeleteConfirmAlertView(templateModel: TemplateModel, fromVC: UIViewController) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_List_CustomTemplateDeleteTitle)
        dialog.setContent(text: BundleI18n.SKResource.Doc_List_CustomTemplateDelete)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Delete, dismissCompletion: { [weak fromVC, weak self] in
            guard let fromVC = fromVC else { return }
            self?.deleteDIYTemplate(templateModel: templateModel, fromVC: fromVC)
        })
        Navigator.shared.present(dialog, from: fromVC, animated: true)
    }
    
    /*
    private func showShareTemplatePopVCV1(templateModel: TemplateModel, fromVC: UIViewController) {
        guard DocsNetStateMonitor.shared.isReachable else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_NoInternetClickMoreToast, on: fromVC.view.window ?? fromVC.view)
            return
        }
        guard let userInfo = User.current.info, let createTime = templateModel.createTime else {
            DocsLogger.error("current userinfo is nil when try to share")
            return
        }
        let docsType = ShareDocsType(rawValue: templateModel.objType)
        var isOwner = true
        var ownerId = userInfo.userID
        var creatorId = userInfo.userID
        if let fromUserId = templateModel.fromUserId, !fromUserId.isEmpty, fromUserId != userInfo.userID {
            isOwner = false
            ownerId = fromUserId
            creatorId = fromUserId
        }
        
        let fileModel = CollaboratorFileModel(objToken: templateModel.objToken,
                                              docsType: docsType,
                                              title: templateModel.displayTitle,
                                              isOWner: isOwner,
                                              ownerID: ownerId,
                                              displayName: templateModel.displayTitle,
                                              spaceID: "",
                                              folderType: nil,
                                              tenantID: userInfo.tenantID,
                                              createTime: createTime,
                                              createDate: "\(createTime)",
                                              creatorID: creatorId,
                                              templateMainType: templateModel.templateMainType,
                                              enableTransferOwner: true,
                                              formMeta: nil)
        let reporter: CollaboratorStatistics = {
            let info = CollaboratorAnalyticsFileInfo(fileType: docsType.name, fileId: templateModel.objToken.encryptToken)
            let obj = CollaboratorStatistics(docInfo: info, module: ShareSource.diyTemplate.rawValue)
            return obj
        }()
        let defaultPermissons = UserPermissionMask.mockPermisson()

        let viewModel = CollaboratorSearchViewModel(existedCollaborators: [],
                                                    selectedItems: [],
                                                    fileModel: fileModel,
                                                    lastPageLabel: "",
                                                    statistics: reporter,
                                                    userPermission: defaultPermissons,
                                                    publicPermisson: PublicPermissionMeta(),
                                                    inviteSource: .diyTemplate)
        viewModel.naviBarTitle = BundleI18n.SKResource.Doc_List_ShareTemplTitle
        let dependency = CollaboratorSearchVCDependency(statistics: reporter,
                                                        permStatistics: nil,
                                                        needShowOptionBar: false)
        let uiConfig = CollaboratorSearchVCUIConfig(needActivateKeyboard: true,
                                                    source: .diyTemplate)
        let vc = CollaboratorSearchViewController(viewModel: viewModel,
                                                  dependency: dependency,
                                                  uiConfig: uiConfig)
        
        let navVC = LkNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        Navigator.shared.present(navVC, from: fromVC)
        TemplateCenterTracker.reportPageViewEvent(page: .share)
    }
     */
    
    private func showShareTemplatePopVCV2(templateModel: TemplateModel, fromVC: UIViewController, popSource: PopSource? = nil) {
        guard DocsNetStateMonitor.shared.isReachable else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_NoInternetClickMoreToast, on: fromVC.view)
            return
        }
        let hub = UDToast.showLoading(with: BundleI18n.SKResource.Doc_Facade_Loading, on: fromVC.view)
        DocsRequestCenter.getEntryInfoFor(objToken: templateModel.objToken, objType: templateModel.docsType) { [weak self] ownerType, error in
            if let error = error {
                hub.showFailure(with: error.localizedDescription, on: fromVC.view)
                return
            }
            hub.remove()
            if let ownerType = ownerType {
                self?.showSharePanel(template: templateModel, ownerType: ownerType, fromVC: fromVC, popSource: popSource)
            }
        }.makeSelfReferenced()
    }
    
    private func showSharePanel(template: TemplateModel, ownerType: Int, fromVC: UIViewController, popSource: PopSource?) {
        let isShared = !(template.fromUserId ?? "").isEmpty
        let ownerID = (isShared ? template.fromUserId : User.current.info?.userID) ?? ""
        let tenantID = (isShared ? "" : User.current.info?.tenantID) ?? ""
        let shareEntity = SKShareEntity(
            objToken: template.objToken,
            type: template.objType,
            title: template.displayTitle,
            isOwner: !isShared, ownerID: ownerID,
            displayName: template.displayTitle,
            tenantID: tenantID,
            isFromPhoenix: false,
            shareUrl: "",
            spaceSingleContainer: ownerType == singleContainerOwnerTypeValue,
            enableShareWithPassWord: true,
            enableTransferOwner: true)
        let shareVC = SKShareViewController(
            shareEntity,
            source: .diyTemplate,
            isInVideoConference: false
        )
        shareVC.watermarkConfig.needAddWatermark = true
        let nav = LkNavigationController(rootViewController: shareVC)

        if SKDisplay.pad, fromVC.view.isMyWindowRegularSize() ?? false {
            shareVC.modalPresentationStyle = .popover
            nav.modalPresentationStyle = .popover
            nav.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            nav.popoverPresentationController?.sourceView = popSource?.sourceView
            nav.popoverPresentationController?.sourceRect = popSource?.sourceRect ?? .zero
            nav.popoverPresentationController?.permittedArrowDirections = popSource?.arrowDirection ?? .any
            fromVC.present(nav, animated: true)
        } else {
            nav.modalPresentationStyle = .overFullScreen
            Navigator.shared.present(nav, from: fromVC, animated: false)
        }
    }
    
    private func deleteDIYTemplate(templateModel: TemplateModel, fromVC: UIViewController) {
        guard DocsNetStateMonitor.shared.isReachable else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_NoInternetClickMoreToast, on: fromVC.view.window ?? fromVC.view)
            return
        }
        networkAPI.deleteDIYTemplate(templateToken: templateModel.objToken, objType: templateModel.objType)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak fromVC] (json) in
                DocsLogger.debug("delete diy template result: \(String(describing: json))")
                guard let fromVC = fromVC else { return }
                guard let json = json, let code = json["code"].int, code == 0 else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_SaveCustomTemplFailed, on: fromVC.view)
                    return
                }
                TemplateCenterTracker.reportManagementTemplateByUser(
                    action: .delete,
                    templateMainType: templateModel.templateMainType
                )
                Self.didDeleteTemplateNotice.onNext(templateModel)
                DispatchQueue.main.async { [weak fromVC] in // 不加延时会被前端biz.util.hideToast提前移除
                    guard let fromVC = fromVC else { return }
                    UDToast.showSuccess(with: BundleI18n.SKResource.Doc_List_DeleteSuccessfully, on: fromVC.view.window ?? fromVC.view)
                }
            })
            .disposed(by: bag)
    }
    
    private func reportTemplateShare(template: TemplateModel) {
        TemplateCenterTracker.reportTemplateShare(
            template: template, from: fromPage,
            templateSource: templateSource,
            templateCenterSource: templateCenterSource
        )
    }
    
    private func reportTemplateDelete(template: TemplateModel) {
        TemplateCenterTracker.reportTemplateDelete(template: template, from: fromPage)
    }
}
