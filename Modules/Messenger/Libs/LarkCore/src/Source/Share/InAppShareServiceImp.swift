//
//  InAppShareServiceImp.swift
//  LarkCore
//
//  Created by shizhengyu on 2020/5/11.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LarkSnsShare
import EENavigator
import LarkLocalizations
import UniverseDesignIcon
import LarkContainer

final class InAppShareServiceImp: InAppShareService {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 用于动态分享配置（推荐）
    func genInAppShareContext(content: InAppShareContent) -> CustomShareContext {
        return CustomShareContext.larkShareContext(userResolver: userResolver, content: content)
    }

    /// 用于静态分享配置
    func genInAppShareItem(content: InAppShareContent) -> LarkShareItemType {
        return LarkShareItemType.custom(CustomShareContext.larkShareContext(userResolver: userResolver, content: content))
    }
}

extension CustomShareContext {
    static let imageContentNameKey = "name"
    static let imageContentTypeKey = "type"
    static let imageContentNeedFilterExternalKey = "needFilterExternal"
    static let imageContentCancelCallBackKey = "cancelHandler"
    static let imageContentSuccessCallBackKey = "successCallBack"
    static let textContentSendHandlerKey = "sentHandler"
    static let contentShareResultsCallBackKey = "shareResultsCallBack"

    public static func larkShareContext(
        userResolver: UserResolver,
        content: InAppShareContent
    ) -> CustomShareContext {
        let icon = UDIcon.getIconByKey(.forwardOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
        let itemContext = CustomShareItemContext(title: BundleI18n.LarkCore.Lark_IMGroups_ShareSendToChat_ButtonText, icon: icon)

        var contentContext: [String: Any] = [:]
        var customShareContent: CustomShareContent = .text("", contentContext)

        switch content {
        case .image(let content):
            contentContext[imageContentNameKey] = content.name
            contentContext[imageContentTypeKey] = content.type
            contentContext[imageContentNeedFilterExternalKey] = content.needFilterExternal
            contentContext[imageContentCancelCallBackKey] = content.cancelCallBack
            contentContext[imageContentSuccessCallBackKey] = content.successCallBack
            contentContext[contentShareResultsCallBackKey] = content.shareResultsCallBack
            customShareContent = .image(content.image, contentContext)
        case .text(let content):
            contentContext[textContentSendHandlerKey] = content.sendHandler
            contentContext[contentShareResultsCallBackKey] = content.shareResultsCallBack
            customShareContent = .text(content.text, contentContext)
        case .url(let content):
            contentContext[textContentSendHandlerKey] = content.ShareTextSuccessCallBack
            contentContext[imageContentTypeKey] = content.imageShareType
            contentContext[imageContentNeedFilterExternalKey] = content.imageNeedFilterExternal
            contentContext[imageContentSuccessCallBackKey] = content.ShareImageSuccessCallBack
            customShareContent = .url(URLContent(url: content.url, image: content.image), contentContext)
        }

        let action: (CustomShareContent, UIViewController, PanelType) -> Void = { (shareContent, from, panelType) in
            switch shareContent {
            case .image(let image, let context):
                let name = context[imageContentNameKey] as? String ?? ""
                let type = context[imageContentTypeKey] as? ShareImageType ?? .normal
                let needFilterExternal = context[imageContentNeedFilterExternalKey] as? Bool ?? true
                let successHandler = context[imageContentSuccessCallBackKey] as? () -> Void
                let shareResultsCallBack = context[contentShareResultsCallBackKey] as? ([(String, Bool)]?) -> Void
                var shareImageBody = ShareImageBody(name: name,
                                                    image: image,
                                                    type: type,
                                                    needFilterExternal: needFilterExternal,
                                                    cancelCallBack: nil,
                                                    successCallBack: { [weak from] in
                                                        successHandler?()
                                                        from?.dismiss(animated: true, completion: nil)
                                                    })
                shareImageBody.shareResultsCallBack = shareResultsCallBack
                userResolver.navigator.present(
                    body: shareImageBody,
                    from: from,
                    prepare: { $0.modalPresentationStyle = .formSheet })
            case .text(let text, let context):
                let sendHandler = context[textContentSendHandlerKey] as? TextContentInLark.SendHandler
                let shareResultsCallBack = context[contentShareResultsCallBackKey] as? ([(String, Bool)]?) -> Void
                var forwardTextBody = ForwardTextBody(text: text, sentHandler: { [weak from] userIds, chatIds in
                    sendHandler?(userIds, chatIds)
                    from?.dismiss(animated: true, completion: nil)
                })
                forwardTextBody.shareResultsCallBack = shareResultsCallBack
                userResolver.navigator.present(
                    body: forwardTextBody,
                    from: from,
                    prepare: { $0.modalPresentationStyle = .formSheet })
            case .url(let urlContent, let context):
                switch panelType {
                case .actionPanel:
                    let sendHandler = context[textContentSendHandlerKey] as? URLContentInLark.SendHandler
                    let forwardTextBody = ForwardTextBody(text: urlContent.url, sentHandler: { [weak from] userIds, chatIds in
                        sendHandler?(userIds, chatIds)
                        from?.dismiss(animated: true, completion: nil)
                    })
                    userResolver.navigator.present(
                        body: forwardTextBody,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet })
                case .imagePanel:
                    let name = context[imageContentNameKey] as? String ?? ""
                    let type = context[imageContentTypeKey] as? ShareImageType ?? .normal
                    let needFilterExternal = context[imageContentNeedFilterExternalKey] as? Bool ?? true
                    let successHandler = context[imageContentSuccessCallBackKey] as? () -> Void
                    let shareImageBody = ShareImageBody(name: name,
                                                        image: urlContent.image,
                                                        type: type,
                                                        needFilterExternal: needFilterExternal,
                                                        cancelCallBack: nil,
                                                        successCallBack: { [weak from] in
                                                            successHandler?()
                                                            from?.dismiss(animated: true, completion: nil)
                                                        })
                    userResolver.navigator.present(
                        body: shareImageBody,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet })
                }
            @unknown default: break
            }
        }

        return CustomShareContext(
            identifier: "inapp",
            itemContext: itemContext,
            content: customShareContent,
            action: action
        )
    }
}
