//
//  TranslateServiceImp.swift
//  LarkAI
//
//  Created by bytedance on 2020/9/21.
//

import Foundation
import UIKit
import RxSwift
import LarkMessengerInterface
import LarkModel
import Swinject
import LarkSDKInterface
import RustPB

final class TranslateServiceImp: NSObject, TranslateFeedbackService {

    /// 翻译服务依赖
    private let dependency: TranslateServiceDependency

    // MARK: - init
    init(dependency: TranslateServiceDependency) {
        self.dependency = dependency
    }

    // MARK: - 发送翻译反馈
    func sendTranslateFeedback(scene: RustPB.Ai_V1_TranslationScene,
                               score: Int,
                               originText: String,
                               targetText: String,
                               hasSuggestText: Bool,
                               suggestText: String,
                               editSuggestText: Bool,
                               originLanguage: String,
                               targetLanguage: String,
                               objectID: String? = nil) -> Observable<Void> {
        return dependency.translateAPI.sendTranslateFeedback(scene: scene,
                                                             score: score,
                                                             originText: originText,
                                                             targetText: targetText,
                                                             hasSuggestText: hasSuggestText,
                                                             suggestText: suggestText,
                                                             editSuggestText: editSuggestText,
                                                             originLanguage: originLanguage,
                                                             targetLanguage: targetLanguage,
                                                             objectID: objectID)
    }

    /// 调起发送消息反馈的弹框
    func showTranslateFeedbackView(message: Message, fromVC: UIViewController) {
        let translateFeedbackService = MessageTranslateFeedbackService(userResolver: self.dependency.useResolver)
        translateFeedbackService.showMessageTranslateFeedbackView(translateService: self,
                                                                  message: message,
                                                                  userAppConfig: self.dependency.userAppConfig,
                                                                  fromVC: fromVC)
    }

    // 划词翻译调用弹窗
    func showTranslateFeedbackForSelectText(selectText: String,
                                            translateText: String,
                                            targetLanguage: String,
                                            copyConfig: TranslateCopyConfig,
                                            extraParam: [String: Any],
                                            fromVC: UIViewController) {
        let translateFeedbackService = MessageTranslateFeedbackService(userResolver: self.dependency.useResolver)
        translateFeedbackService.showTextTranslateFeedbackView(translateService: self,
                                                               selectText: selectText,
                                                               translateText: translateText,
                                                               targetLanguage: targetLanguage,
                                                               userAppConfig: self.dependency.userAppConfig,
                                                               copyConfig: copyConfig,
                                                               extraParam: extraParam,
                                                               fromVC: fromVC)
    }

}
