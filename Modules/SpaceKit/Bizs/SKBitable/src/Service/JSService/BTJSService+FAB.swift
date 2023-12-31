//
// Created by duanxiaochen.7 on 2021/3/11.
// Affiliated with SKBitable.
//
// Description: bitable@docs && bitable 单品的 FAB 按钮

import EENavigator
import UIKit
import HandyJSON
import SKCommon
import SKBrowser
import SKUIKit
import SKFoundation
import SKResource
import LarkUIKit
import UniverseDesignColor

extension BTJSService {

    func handleBitableFABService(_ params: [String: Any]) {
        DocsLogger.btInfo("[SYNC] handleBitableFABService params: \(String(describing: params.jsonString?.encryptToShort))")
        guard let fabParams = FABParams.deserialize(from: params), !fabParams.data.isEmpty else {
            DocsLogger.btInfo("[SYNC] bitableFAB insufficient params, hiding FAB")
            hideAllFAB()
            // 此时需要更新FAB数据
            toolbarsContainer.updateFAB(params: [])
            stopFabUIEventMonitor()
            return
        }
        toolbarsContainer.fabCallback = DocsJSCallBack(fabParams.callback)
        showFAB(data: fabParams.data)
        if fabParams.data.contains(where: { $0.id == .shareDashboard && !$0.disabled }) {
            // 只要包含通用分享（仪表盘分享）按钮，就监听 webview 滑动事件，上滑隐藏 Fab 按钮，下滑显示
            startFabUIEventMonitor()
        }
    }

    func handleFormShareService(_ params: [String: Any]) {
        DocsLogger.btInfo("[SYNC] handleShareService")
        guard let baseToken = params["baseToken"] as? String,
              let tableId = params["tableId"] as? String,
              let viewId = params["viewId"] as? String,
              let formName = params["formName"] as? String else {
                DocsLogger.btError("[SYNC] share params not right")
                return
        }
        let formShareMode = params["formShareMode"] as? String
        let onlyShowSocialShareComponent = formShareMode == "formUser"
        let isNewForm = formShareMode == "formMaker" || onlyShowSocialShareComponent
        let hasUserFields = params["hasUserFields"] as? Bool ?? false
        let hasAttachmentFields = params["hasAttachmentFields"] as? Bool ?? false
        let formEditable = params["formEditable"] as? Bool
        PermissionStatistics.formEditable = formEditable

        // base@docx不支持表单视图，这里取宿主信息即可
        guard let docsInfo = model?.hostBrowserInfo.docsInfo else {
            DocsLogger.btError("[SYNC] docs info or authinfo is nil")
            spaceAssertionFailure()
            return
        }

        navigator?.currentBrowserVC?.view.window?.endEditing(true)
        let hasCover: Bool
        if let formBannerUrl = cardVC?.viewModel.tableValue.formBannerUrl {
            if formBannerUrl.isEmpty {
                hasCover = false
            } else {
                hasCover = true
            }
        } else {
            hasCover = false
        }
        let formShareMeta = FormShareMeta(token: baseToken,
                                          tableId: tableId,
                                          viewId: viewId,
                                          shareType: 1,
                                          hasCover: hasCover)
        if let url = model?.hostBrowserInfo.currentURL, // base@docx不支持表单视图，这里取宿主信息即可
           let shareHost = DocsUrlUtil.getDocsCurrentUrlInfo(url).srcHost,
           !shareHost.isEmpty {
            formShareMeta.updateShareHost(shareHost)
        }
        var onlyBottomCells = false
        if let editable = formEditable {
            if !editable {
                onlyBottomCells = true
            }
        }
        var shareEntity = SKShareEntity(objToken: baseToken,
                                        type: ShareDocsType.form.rawValue,
                                        title: formName,
                                        isOwner: docsInfo.isOwner,
                                        ownerID: docsInfo.ownerID ?? "",
                                        displayName: docsInfo.displayName,
                                        shareFolderInfo: docsInfo.shareFolderInfo,
                                        folderType: docsInfo.folderType,
                                        tenantID: docsInfo.tenantID ?? "",
                                        createTime: docsInfo.createTime ?? 0,
                                        createDate: docsInfo.createDate ?? "",
                                        creatorID: docsInfo.creatorID ?? "",
                                        wikiInfo: docsInfo.wikiInfo,
                                        isFromPhoenix: docsInfo.isFromPhoenix,
                                        shareUrl: docsInfo.shareUrl ?? "",
                                        fileType: docsInfo.fileType ?? "",
                                        defaultIcon: docsInfo.defaultIcon,
                                        wikiV2SingleContainer: false,
                                        spaceSingleContainer: false,
                                        enableShareWithPassWord: true,
                                        enableTransferOwner: true,
                                        onlyShowSocialShareComponent: onlyBottomCells,
                                        formShareMeta: formShareMeta)
        shareEntity.isOldForm = true
        shareEntity.formsCallbackBlocks.formHasAttachmentField = { [weak self] in
            if isNewForm {
                return hasAttachmentFields
            }
            return self?.cardVC?.currentCardHasAttachmentField ?? false
        }

        shareEntity.formsCallbackBlocks.formHasUserField = { [weak self] in
            if isNewForm {
                return hasUserFields
            }
            return self?.cardVC?.currentCardHasUserField ?? false
        }
        shareEntity.formsCallbackBlocks.formHasLinkField = { [weak self] in
            return self?.cardVC?.currentCardHasLinkField ?? false
        }

        if UserScopeNoChangeFG.ZYS.formSupportFormula {
            shareEntity.formsCallbackBlocks.formShareSuccessTip = { [weak self] in
                self?.cardVC?.getFormShareEnableTip()
            }
        }
        shareEntity.formsCallbackBlocks.formEventTracing = { [weak self] in
            //埋点上报
            let hasUserField = self?.cardVC?.currentCardHasUserField ?? false
            let hasAttachmentField = self?.cardVC?.currentCardHasAttachmentField ?? false

            let commonParams = self?.cardVC?.viewModel.getCommonTrackParams() ?? [:]

            var reason = "" 
            if hasUserField {
                if hasAttachmentField {
                    reason = "person_attachement"
                } else {
                    reason = "person"
                }
            } else if hasAttachmentField {
                reason = "attachment"
            }
            var parameters: [String: Any] = ["reason": reason,
                              "target": "none"]
            parameters.merge(other: commonParams)
            DocsTracker.newLog(enumEvent: .bitableFormInternetPopupView, parameters: parameters)
        }
        
        shareEntity.shareHandlerProvider = self

        let shareVC = SKShareViewController(shareEntity,
                                            delegate: self,
                                            router: self,
                                            source: .content,
                                            isInVideoConference: docsInfo.isInVideoConference ?? false)
        shareVC.isNewForm = isNewForm
        shareVC.isNewFormUser = onlyShowSocialShareComponent
        shareVC.formEditable = formEditable
        shareVC.watermarkConfig.needAddWatermark = model?.hostBrowserInfo.docsInfo?.shouldShowWatermark ?? true // base@docx不支持表单视图，这里取宿主信息即可
        let nav = LkNavigationController(rootViewController: shareVC)

        if SKDisplay.pad, ui?.editorView.isMyWindowRegularSize() ?? false {
            shareVC.modalPresentationStyle = .popover
            shareVC.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            let browserVC = navigator?.currentBrowserVC as? BaseViewController
            let code = -1   // 新框架下，popover要跟随最右边的item
            browserVC?.showPopover(to: nav, at: code, isNewForm: true)
        } else {
            nav.modalPresentationStyle = .overFullScreen
            BTUtil.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                self?.navigator?.presentViewController(nav, animated: false, completion: nil)
            }
        }
    }
}

extension BTJSService {

    func showFAB(data: [FABData]) {
        guard let hostVC = registeredVC as? BrowserViewController else {
            DocsLogger.btError("[SYNC] not in BrowserViewController")
            return
        }
        toolbarsContainer.updateFAB(params: data)
        relayoutToolbarsContainer(browserVC: hostVC, cardVC: cardVC)

        if cardVC == nil {
            //非表单情况下
            toolbarsContainer.setFABHide(false)
        }
    }

    func hideAllFAB() {
        toolbarsContainer.setFABHide(true)
        (registeredVC as? BrowserViewController)?.editor.fabContainer = nil
    }
    
    func relayoutToolbarsContainer(browserVC: BrowserViewController, cardVC: UIViewController?) {
        if let container = container {
            container.getOrCreatePlugin(BTContainerFABPlugin.self).relayoutToolbarsContainer(toolbarsContainer: toolbarsContainer, cardVC: cardVC)
            return
        }
        // 下方代码即将废弃
        toolbarsContainer.removeFromSuperview()
        toolbarsContainer.snp.removeConstraints()
        if let cardVC = cardVC, cardVC.isViewLoaded {
            cardVC.view.addSubview(toolbarsContainer)
        } else {
            browserVC.editor.editorView.addSubview(toolbarsContainer)
            browserVC.editor.fabContainer = toolbarsContainer.fabContainerView
        }
        toolbarsContainer.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
        }
    }
}

/// Webview 滑动事件监听
extension BTJSService {
    func startFabUIEventMonitor() {
        guard let ancestorView = (self.ui?.editorView as? DocsWebViewProtocol)?.contentView ?? self.ui?.editorView else {
            DocsLogger.btError("startMonitor get ancestorView error")
            return
        }
        fabUIEventMonitor = BTUIEventMonitor(ancestorView: ancestorView)
        fabUIEventMonitor?.didReceiveMove = {[weak self] moveTranslaction in
            self?.handleFabTranslaction(moveTranslaction)
        }
    }
    
    func stopFabUIEventMonitor() {
        fabUIEventMonitor = nil
    }
    
    private func handleFabTranslaction(_ translation: CGPoint) {
        let direction = TranslationDirectionDetector.detect(translation)
        handleFabDirection(direction)
    }
    
    private func handleFabDirection(_ direction: TranslationDirectionDetector.ScrollDirection) {
        switch direction {
        case .up:
            setFABHidden(true, isForm: false, isDashboardShare: true)
        case .down:
            setFABHidden(false, isForm: false, isDashboardShare: true)
        default: break
        }
    }
}

extension BTJSService: FABContainerDelegate {
    func didClickFABButton(_ button: FABIdentifier, view: FABContainer) {
        DocsLogger.btInfo("FABContainer didSelcted \(button.rawValue)")
        let params = ["id": button.rawValue]
        let logParams = ["click": "share",
                         "target": "ccm_bitable_external_permission_view",
                         "share_type": "dashboard"
        ]
        DocsTracker.newLog(enumEvent: .bitableToolBarClick, parameters: params)
        model?.jsEngine.callFunction(toolbarsContainer.fabCallback, params: params, completion: nil)
    }
}

extension BTJSService: ShareViewControllerDelegate, ShareRouterAbility {
    func requestShareToLarkServiceFromViewController() -> UIViewController? {
        return navigator?.currentBrowserVC
    }
    
    func onRemindNotificationViewClick(
        controller: UIViewController,
        shareToken: String
    ) {
        DocsLogger.info("onRemindNotificationViewClick")
        controller
            .dismiss(
                animated: false
            ) {
                self
                    .model?
                    .jsEngine
                    .callFunction(
                        DocsJSCallBack
                            .remindNotificationClick,
                        params: [
                            "shareToken": shareToken
                        ],
                        completion: nil
                    )
            }
        
    }
}
