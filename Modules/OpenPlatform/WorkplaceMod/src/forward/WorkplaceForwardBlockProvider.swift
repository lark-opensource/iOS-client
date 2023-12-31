//
//  WorkplaceForwardBlockProvider.swift
//  WorkplaceMod
//
//  Created by Shengxy on 2023/5/11.
//

import Foundation
import EENavigator
import RxSwift
import UniverseDesignToast
import LarkWorkplaceModel
import LarkModel

#if MessengerMod
import LarkMessengerInterface

final class WorkplaceForwardBlockContent: ForwardAlertContent {
    let body: WorkplaceForwardBlockBody
    init(body: WorkplaceForwardBlockBody) { self.body = body }
}

final class WorkplaceForwardBlockProvider: ForwardAlertProvider {
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        return ((content as? WorkplaceForwardBlockContent) != nil)
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let forwardBlockContent = content as? WorkplaceForwardBlockContent,
              let window = from.view.window else { return .just([]) }
        UDToast.showLoading(with: BundleI18n.WorkplaceMod.OpenPlatform_BaseBlock_SharingStatus, on: window, disableUserInteraction: true)
        let receivers = dataTransition(items: items)
        guard let observable = forwardBlockContent.body.shareTaskGenerator(receivers, input) else {
            let error = NSError(domain: "share failed", code: -1)
            UDToast.showFailure(with: BundleI18n.WorkplaceMod.OpenPlatform_BaseBlock_ShareFailedToast, on: window, error: error)
            return .error(error)
        }
        return observable.do(
            onNext: { _ in
                UDToast.showSuccess(with: BundleI18n.WorkplaceMod.OpenPlatform_BaseBlock_SharedToast, on: window)
            },
            onError: { error in
                UDToast.showFailure(with: BundleI18n.WorkplaceMod.OpenPlatform_BaseBlock_ShareFailedToast, on: window, error: error)
            }
        )
    }

    /// ForwardItem -> WPMessageReceiver
    private func dataTransition(items: [ForwardItem]) -> [WPMessageReceiver] {
        return items.compactMap { item in
            switch item.type {
            case .chat:
                return WPMessageReceiver(type: .chat, id: item.id)
            case .user:
                return WPMessageReceiver(type: .user, id: item.id)
            case .bot:
                return WPMessageReceiver(type: .user, id: item.id)
            case .threadMessage, .replyThreadMessage, .unknown, .generalFilter, .myAi:
                return nil
            }
        }
    }
}
#endif
