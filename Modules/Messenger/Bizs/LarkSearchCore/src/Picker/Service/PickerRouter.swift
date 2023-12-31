//
//  PickerRouter.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/2/23.
//

import Foundation
import LarkModel
import LarkMessengerInterface
import LarkUIKit
import EENavigator
import LarkContainer

final class PickerRouter: PickerRouterType, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    var navigator: Navigatable { self.userResolver.navigator }
    var tracker: PickerTracker?
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }

    func pushToMultiSelectedPage(from: UIViewController, picker: Picker, context: PickerContext, completion handler: @escaping ((UIViewController) -> Void)) {
        var body = PickerSelectedBody(
            picker: picker,
            confirmTitle: context.featureConfig.navigationBar.title,
            allowSelectNone: true,
            targetPreview: context.featureConfig.targetPreview.isOpen,
            completion: {
                handler($0)
            }
        )
        body.userId = context.userId
        body.isUseDocIcon = picker.featureGating.isEnable(name: .corePickerDocicon)
        navigator.push(body: body, from: from)
    }

    func presentToTargetPreviewPage(from: UIViewController, item: PickerItem) {
        switch item.meta {
        case .chatter(let chatter):
            let chatID = chatter.p2pChat?.id ?? ""
            let userID = chatter.id
            let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: chatID, userId: userID, title: chatter.localizedRealName ?? "")
            navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: from)
            tracker?.trackTargetPreviewShowed()
        default:
            PickerLogger.shared.error(module: PickerLogger.Module.router, event: "present target preview", parameters: "type: \(item.meta.type)")
        }
    }
}
