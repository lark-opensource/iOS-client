import EENavigator
import Foundation
import LarkUIKit
import LKCommonsLogging
import SKBrowser
import SKCommon
import SKFoundation
import SpaceInterface
import SKUIKit
import UniverseDesignColor

final class FormsShareComponent: BTDDUIComponentProtocol {
    
    static let logger = Logger.formsSDKLog(FormsShareComponent.self, category: "FormsShareComponent")
    
    typealias UIModel = FormsShareModel
    
    weak private var controller: SKShareViewController?
    
    static func convert(from payload: Any?) throws -> FormsShareModel {
        try CodableUtility.decode(FormsShareModel.self, withJSONObject: payload ?? [:])
    }
    
    deinit {
        Self.logger.info("FormsShareComponent deinit")
    }
    
    func mount(with model: FormsShareModel) throws {
        let formsShareModel = model
        Self.logger.info("formsShare params is: \(formsShareModel.logInfo())")
        
        PermissionStatistics.formEditable = true // 和PM进行了咨询，现在的业务逻辑，如果不能编辑完全进不来
        
        guard let context = context else {
            throw BTDDUIError.componentMountFailed
        }
        
        guard let navigator = context.navigator else {
            throw BTDDUIError.componentMountFailed
        }
        
        guard let currentBrowserVC = navigator.currentBrowserVC as? BrowserViewController else {
            throw BTDDUIError.componentMountFailed
        }
        
        guard let modelConfig = context.modelConfig else {
            throw BTDDUIError.componentMountFailed
        }
        
        guard let docsInfo = modelConfig.browserInfo.docsInfo else {
            throw BTDDUIError.componentMountFailed
        }

        currentBrowserVC.view.window?.endEditing(true)
        
        let formShareMeta = FormShareMeta(
            token: formsShareModel.baseToken,
            tableId: formsShareModel.tableId,
            viewId: formsShareModel.viewId,
            shareType: 1,
            hasCover: false
        )
        formShareMeta.updateFlag(true) // 新收集表默认可以分享
        if let shareToken = formsShareModel.shareToken {
            formShareMeta.updateShareToken(shareToken)
        }
        
        // 下边代码和之前老表单分享入参一致
        if let url = modelConfig.browserInfo.currentURL,
           let shareHost = DocsUrlUtil.getDocsCurrentUrlInfo(url).srcHost,
           !shareHost.isEmpty {
            formShareMeta.updateShareHost(shareHost)
        }
        
        var shareEntity = SKShareEntity(
            objToken: formsShareModel.baseToken,
            type: ShareDocsType.form.rawValue,
            title: formsShareModel.formName,
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
            enableShareWithPassWord: true,
            enableTransferOwner: true,
            formShareMeta: formShareMeta
        )
        shareEntity.formsShareModel = formsShareModel
        let onClick = model.onClick ?? ""
        shareEntity.formsCallbackBlocks.noticeMeClick = { [weak self] (value: Bool) in
            let args: [String: Any] = [
                "noticeMeValue": value
            ]
            self?.context?.emitEvent(onClick, args: args)
        }
        
        let shareVC = SKShareViewController(
            shareEntity,
            delegate: self,
            router: self,
            source: .content,
            isInVideoConference: docsInfo.isInVideoConference ?? false
        )
        shareVC.watermarkConfig.needAddWatermark = docsInfo.shouldShowWatermark
        shareVC.popoverDisappearBlock = { [weak self] in
            self?.onUnmounted()
        }
        
        let nav = LkNavigationController(rootViewController: shareVC)
        controller = shareVC
        
        if SKDisplay.pad, context.uiConfig?.editorView.isMyWindowRegularSize() ?? false {
            shareVC.modalPresentationStyle = .popover
            shareVC.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            var at = -1 // 新框架下，popover对齐最右边
            currentBrowserVC.showPopover(to: nav, at: at, isNewForm: true) { [weak self] in
                self?.onMounted()
            }
        } else {
            nav.modalPresentationStyle = .overFullScreen
            navigator.presentViewController(nav, animated: false) { [weak self] in
                self?.onMounted()
            }
        }
    }
    
    func setData(with model: FormsShareModel) throws {
        //  暂时只更新NoticeMe
        controller?.updateNoticeMe(value: model.noticeMe == true)
    }
    
    func unmount() {
        controller?.navigationController?.dismiss(animated: false)
    }
    
}

extension FormsShareComponent: ShareRouterAbility {
    
}

extension FormsShareComponent: ShareViewControllerDelegate {
    func requestShareToLarkServiceFromViewController() -> UIViewController? {
        context?.navigator?.currentBrowserVC
    }
}
