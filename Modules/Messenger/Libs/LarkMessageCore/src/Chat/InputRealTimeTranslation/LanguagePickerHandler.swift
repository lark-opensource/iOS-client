//
//  LanguagePickerHandler.swift
//  LarkMessageCore
//
//  Created by bytedance on 4/7/22.
//

import Foundation
import LarkMessengerInterface
import EENavigator
import Swinject
import UniverseDesignActionPanel
import LarkUIKit
import LarkNavigator

public final class LanguagePickerHandler: UserTypedRouterHandler {

    public func handle(_ body: LanguagePickerBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let vc = LanguagePickerViewController(userResolver: userResolver,
                                              chatId: body.chatId,
                                              currentTargetLanguage: body.currentTargetLanguage,
                                              chatFromWhere: body.chatFromWhere)
        vc.targetLanguageChangeCallBack = body.targetLanguageChangeCallBack
        vc.closeRealTimeTranslateCallBack = body.closeRealTimeTranslateCallBack
        let navVC = LkNavigationController(rootViewController: vc)
        let actionPanel = UDActionPanel(
            customViewController: navVC,
            config: UDActionPanelUIConfig(
                originY: 88,
                canBeDragged: true
            )
        )
        res.end(resource: actionPanel)
    }
}
