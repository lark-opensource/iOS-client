//
// Created by duanxiaochen.7 on 2021/2/7.
// Affiliated with SKBrowser.
//
// Description:

import SKFoundation
import SKUIKit
import SKResource
import SKCommon
import UniverseDesignToast
import SKInfra


// 分享文本相关
extension SheetShareManager {
    func saveTextAndToast() {
        let pointId = ClipboardManager.shared.getEncryptId(token: self.docsInfo.objToken)
        let isSuccess = SKPasteboard.setString(shareText,
                               pointId: pointId,
                             psdaToken: PSDATokens.Pasteboard.sheet_card_view_share_text)
        guard let window = shareTextView?.window else {
            DocsLogger.error("cannot get share text view's window")
            return
        }
        if isSuccess {
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Doc_CopySuccess, on: window)
        }
    }

    func shareTextToLark(finishCallback: () -> Void) {
        HostAppBridge.shared.call(ShareToLarkService(contentType: .text(content: shareText), fromVC: registeredVC, type: .feishu))
        finishCallback()
    }

    func shareTextToOtherApp(_ type: ShareAssistType, finishCallback: () -> Void) {
        if type == .more {
            showMoreViewController([shareText])
            finishCallback()
            return
        }

        shareActionManager?.shareTextToSocialApp(type: type, text: shareText)
        finishCallback()
    }
}
