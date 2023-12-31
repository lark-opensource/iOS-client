//
//  MessageTranslateFeedBackService.swift
//  LarkChat
//
//  Created by bytedance on 2020/8/24.
//

import Foundation
import UIKit
import EENavigator
import LarkSDKInterface
import LarkModel
import LarkMessengerInterface
import UniverseDesignToast
import LarkUIKit
import LarkContainer

final class MessageTranslateFeedbackService: NSObject, UserResolverWrapper {

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    // 消息调用翻译反馈
    func showMessageTranslateFeedbackView(translateService: TranslateFeedbackService,
                                          message: Message,
                                          userAppConfig: UserAppConfig,
                                          fromVC: UIViewController) {
        let hudOn = fromVC.view.window
        let trackParam: [String: Any] = [
            "messageID": message.id,
            "messageType": message.type.trackValue,
            "srcLanguage": message.messageLanguage,
            "trgLanguage": message.translateLanguage,
            "cardSource": "im_card",
            "fromType": "full_translate"
        ]
        MessageTranslateFeedbackTracker.translateFeedbackView(messageID: trackParam["messageID"],
                                                               messageType: trackParam["messageType"],
                                                               srcLanguage: trackParam["srcLanguage"],
                                                               trgLanguage: trackParam["trgLanguage"],
                                                               cardSource: trackParam["cardSource"],
                                                               fromType: trackParam["fromType"])
        let feedbackController = MessageTranslateFeedbackController(
            userResolver: userResolver,
            translateService: translateService,
            originLanguage: message.messageLanguage,
            targetLanguage: message.translateLanguage,
            isSelectTranslate: false,
            message: message,
            userAppConfig: userAppConfig,
            successBlock: nil,
            failBlock: nil,
            cancelBlock: nil,
            trackParam: trackParam)
        navigator.present(
            feedbackController, wrap: LkNavigationController.self, from: fromVC,
            prepare: {
                $0.transitioningDelegate = feedbackController
                $0.modalPresentationStyle = .custom
            },
            animated: true)
    }

    // 划词翻译调用翻译反馈
    func showTextTranslateFeedbackView(translateService: TranslateFeedbackService,
                                       selectText: String,
                                       translateText: String,
                                       targetLanguage: String,
                                       userAppConfig: UserAppConfig,
                                       copyConfig: TranslateCopyConfig,
                                       extraParam: [String: Any],
                                       fromVC: UIViewController) {
        let trackParam: [String: Any] = [
            "srcLanguage": "auto",
            "trgLanguage": targetLanguage,
            "cardSource": extraParam["cardSource"],
            "fromType": "hyper_translate"
        ]

        MessageTranslateFeedbackTracker.translateFeedbackView(srcLanguage: trackParam["srcLanguage"],
                                                              trgLanguage: trackParam["trgLanguage"],
                                                              cardSource: trackParam["cardSource"],
                                                              fromType: trackParam["fromType"])

        let feedbackController = MessageTranslateFeedbackController(
            userResolver: userResolver,
            translateService: translateService,
            selectText: selectText,
            translateText: translateText,
            originLanguage: "auto",
            targetLanguage: targetLanguage,
            isSelectTranslate: true,
            userAppConfig: userAppConfig,
            copyConfig: copyConfig,
            trackParam: trackParam)
        navigator.present(
            feedbackController, wrap: LkNavigationController.self, from: fromVC,
            prepare: {
                $0.transitioningDelegate = feedbackController
                $0.modalPresentationStyle = .custom
            },
            animated: true)
    }
}
