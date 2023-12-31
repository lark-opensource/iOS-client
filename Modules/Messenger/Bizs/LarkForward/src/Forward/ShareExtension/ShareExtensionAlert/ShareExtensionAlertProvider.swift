//
//  ShareExtensionAlertProvider.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/4/2.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkExtensionCommon
import EENavigator
import RxSwift
import LKCommonsLogging
import LarkAlertController
import LarkMessengerInterface
import LarkSDKInterface
import UniverseDesignToast

struct ShareExtensionAlertContent: ForwardAlertContent {
    let shareContentData: Data
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ShareExtensionAlertProvider: ForwardAlertProvider {
    static let logger = Logger.log(ShareExtensionAlertProvider.self, category: "Module.IM.Share")

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareExtensionAlertContent != nil {
            return true
        }
        return false
    }

    override var isSupportMention: Bool {
        return true
    }

    override var isSupportMultiSelectMode: Bool {
        return false
    }

    override func getTitle(by items: [ForwardItem]) -> String? {
        return BundleI18n.LarkForward.Lark_Legacy_ShareExtensionConfirmSendTo
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        // 话题置灰
        return [ForwardUserEnabledEntityConfig(),
                ForwardGroupChatEnabledEntityConfig(),
                ForwardBotEnabledEntityConfig(),
                ForwardMyAiEnabledEntityConfig()]
    }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        return [ForwardUserEntityConfig(),
                ForwardGroupChatEntityConfig(),
                ForwardBotEntityConfig(),
                ForwardThreadEntityConfig(),
                ForwardMyAiEntityConfig()]
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ShareExtensionAlertContent,
              let forwardService = try? resolver.resolve(assert: ForwardService.self)
        else { return .just([]) }
        let topmostWindow = WindowTopMostFrom(vc: from)

        let ids = self.itemsToIds(items)

        return forwardService
                        .extensionShare(content: messageContent.shareContentData,
                                        to: ids.chatIds,
                                        userIds: ids.userIds,
                                        extraText: input ?? "")
                        .observeOn(MainScheduler.instance)
                        .do(onError: { [weak self] (error) in
                            guard let self = self else { return }
                            baseErrorHandler(
                                userResolver: self.userResolver,
                                hud: UDToast(),
                                on: from,
                                error: error,
                                defaultErrorMessage: BundleI18n.LarkForward.Lark_Legacy_ShareFailed) {
                                self.showReadDataError(from: topmostWindow)
                            }
                            ShareExtensionAlertProvider.logger.error("内容分享失败", error: error)
                        })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ShareExtensionAlertContent,
              let forwardService = try? resolver.resolve(assert: ForwardService.self)
        else { return .just([]) }
        let topmostWindow = WindowTopMostFrom(vc: from)

        let ids = self.itemsToIds(items)

        return forwardService
                        .extensionShare(content: messageContent.shareContentData,
                                        to: ids.chatIds,
                                        userIds: ids.userIds,
                                        attributeExtraText: attributeInput ?? NSAttributedString(string: ""))
                        .observeOn(MainScheduler.instance)
                        .do(onError: { [weak self] (error) in
                            guard let self = self else { return }
                            baseErrorHandler(
                                userResolver: self.userResolver,
                                hud: UDToast(),
                                on: from,
                                error: error,
                                defaultErrorMessage: BundleI18n.LarkForward.Lark_Legacy_ShareFailed) {
                                self.showReadDataError(from: topmostWindow)
                            }
                            ShareExtensionAlertProvider.logger.error("内容分享失败", error: error)
                        })
    }

    private func showReadDataError(from: NavigatorFrom) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkForward.Lark_Legacy_ShareExtensionReadDataError)
        alertController.addPrimaryButton(text: BundleI18n.LarkForward.Lark_Legacy_Cancel, dismissCompletion: {
            self.cancelSend()
        })

        self.userResolver.navigator.present(alertController, from: from)
    }

    private func cancelSend() {
        ShareExtensionConfig.share.cleanShareCache()
    }
}
