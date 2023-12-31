//
//  BTJSService+Share.swift
//  SKBitable
//
//  Created by zhysan on 2022/12/8.
//

import Foundation
import SKFoundation
import SKCommon
import SKBrowser
import SKUIKit
import SKResource
import LarkUIKit
import UniverseDesignColor
import UniverseDesignToast

extension BTJSService {
    /// Bitable 通用分享
    func handleBitableShareService(_ params: [String: Any]) {
        DocsLogger.info("handleBitableShareService invoke")
        
        guard UserScopeNoChangeFG.ZYS.dashboardShare else {
            DocsLogger.error("handleBitableShareService failed due to fg disable!")
            return
        }
        // docx@base 不支持此分享，因此继续使用宿主信息
        guard let docsInfo = model?.hostBrowserInfo.docsInfo else {
            DocsLogger.error("docs info is nil")
            spaceAssertionFailure()
            return
        }
        
        navigator?.currentBrowserVC?.view.window?.endEditing(true)
        
        do {
            let param = try CodableUtility.decode(BitableShareParam.self, withJSONObject: params)
            let entity = SKShareEntity(
                objToken: param.baseToken,
                type: ShareDocsType.bitableSub(param.shareType).rawValue,
                title: param.title ?? "",
                isOwner: docsInfo.isOwner,
                ownerID: docsInfo.ownerID ?? "",
                displayName: docsInfo.displayName,
                tenantID: docsInfo.tenantID ?? "",
                isFromPhoenix: docsInfo.isFromPhoenix,
                shareUrl: docsInfo.shareUrl ?? "",
                enableShareWithPassWord: true,
                enableTransferOwner: true,
                onlyShowSocialShareComponent: param.isRecordShareV2 || param.isAddRecordShare,
                bitableShareEntity: BitableShareEntity(param: param, docUrl: model?.hostBrowserInfo.currentURL)
            )
            entity.formsCallbackBlocks.formHasLinkField = { [weak self] in
                return self?.cardVC?.currentCardHasLinkField ?? false
            }
            entity.shareHandlerProvider = self
            let vc = SKShareViewController(
                entity,
                delegate: self,
                router: self,
                source: .content,
                isInVideoConference: docsInfo.isInVideoConference ?? false
            )
            vc.watermarkConfig.needAddWatermark = model?.hostBrowserInfo.docsInfo?.shouldShowWatermark ?? true
            let nav = LkNavigationController(rootViewController: vc)
            
            if SKDisplay.pad, ui?.editorView.isMyWindowRegularSize() ?? false {
                vc.modalPresentationStyle = .popover
                vc.popoverPresentationController?.backgroundColor = UDColor.bgFloat
                let browserVC = navigator?.currentBrowserVC as? BaseViewController
                browserVC?.showPopover(to: nav, at: -1)
            } else {
                nav.modalPresentationStyle = .overFullScreen
                BTUtil.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                    self?.navigator?.presentViewController(nav, animated: false, completion: nil)
                }
            }
        } catch {
            DocsLogger.error("handleBitableShareService error: \(error)")
        }
    }
}

extension BTJSService: SKShareHandlerProvider {
    var shareToLarkHandler: ShareToLarkService.ContentType.TextShareCallback? {
        { [weak self] userIds, chatIds in
            DispatchQueue.main.async {
                guard let self = self, let wrapper = self.navigator?.currentBrowserVC?.view.affiliatedWindow else {
                    DocsLogger.error("share to lark callback, toast failed due to nil self or window")
                    return
                }
                guard !userIds.isEmpty || !chatIds.isEmpty else {
                    DocsLogger.error("share to lark callback, toast failed due to empty object")
                    return
                }
                UDToast.showSuccess(with: BundleI18n.SKResource.CreationMobile_mention_sharing_success, on: wrapper)
            }
        }
    }
}
