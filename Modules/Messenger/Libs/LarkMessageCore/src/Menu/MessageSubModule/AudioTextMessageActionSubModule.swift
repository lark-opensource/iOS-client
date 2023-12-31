//
//  AudioText.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/16.
//

import Foundation
import LarkModel
import RxSwift
import LarkOpenChat
import UniverseDesignToast
import LarkKAFeatureSwitch
import LarkSetting
import LarkFeatureGating
import LarkContainer
import LarkAudio
import LarkSDKInterface
import Reachability
import LarkMessengerInterface
import LKCommonsLogging

public final class AudioTextMessageActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy var audioAPI: AudioAPI?
    @ScopedInjectedLazy var translateService: NormalTranslateService?

    private let disposeBag: DisposeBag = DisposeBag()

    static let logger = Logger.log(AudioTextMessageActionSubModule.self, category: "lark.hide.audio.text")
    public override var type: MessageActionType {
        return .audioText
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        let fg = context.userResolver.fg
        let audioFS = fg.staticFeatureGatingValue(with: .init(switch: .suiteVoice2Text))
        return fg.staticFeatureGatingValue(with: .init(key: .audioToTextEnable)) && audioFS
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        guard let content = model.message.content as? AudioContent else { return false }
        return true
    }

    private func handle(message: Message, chat: Chat, hideVoice2Text: Bool) {
        guard let targetVC = try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self).pageAPI else { return }
        guard let content = message.content as? AudioContent, let window = targetVC.view.window else { return }

        guard message.fileDeletedStatus == .normal else {
            if message.fileDeletedStatus == .freedUp {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
            } else {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_Message_AudioMessageWithdrawMessageToast, on: window)
            }
            return
        }

        self.audioAPI?.toggleTextOnAudio(messageID: message.id, hideVoice2Text: hideVoice2Text)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                Self.logger.info("hide audio text success")
            }, onError: { error in
                Self.logger.error("hide audio text failed", additionalData: ["messageID": message.id], error: error)
            }).disposed(by: disposeBag)

        // 本地不存在翻译结果, 且并不在识别中，向服务再次请求数据
        // voiceText 为识别文案
        if hideVoice2Text == false, content.voiceText.isEmpty, content.isAudioRecognizeFinish == true {
            if let reachability = Reachability(), reachability.connection != .none {
                // 有网络发起请求，使用本地选择语言
                let speechLocale: String = RecognizeLanguageManager.shared.recognitionLanguage.localeIdentifier
                self.audioAPI?.recognitionAudioMessage(
                    messageID: message.id,
                    audioRate: 16_000,
                    audioFormat: "opus",
                    deviceLocale: speechLocale.lowercased())
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        Self.logger.info("recognition audio message success")
                    }, onError: { [weak window] error in
                        guard let window = window else { return }
                        Self.logger.error(
                            "recognition audio message failed",
                            additionalData: ["messageID": message.id],
                            error: error
                        )
                        if let apiError = error.underlyingError as? APIError {
                            switch apiError.type {
                            case .recognitionWithEmptyResult:
                                UDToast.showFailure(
                                    with: BundleI18n.LarkMessageCore.Lark_Chat_AudioConvertToTextError,
                                    on: window,
                                    error: error
                                )
                                return
                            default: break
                            }
                        }
                        UDToast.showFailure(
                            with: BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip,
                            on: window,
                            error: error
                        )
                    }).disposed(by: disposeBag)
            } else {
                // 无网络报错
                UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_NetworkError, on: window)
            }
        } else {
            var isTranslated: Bool {
                if message.displayRule == .noTranslation || message.displayRule == .unknownRule { return false }
                if message.translateLanguage.isEmpty { return false }
                return true
            }
            if isTranslated {
                let translateParam = MessageTranslateParameter(message: message,
                                                               source: MessageSource.common(id: message.id),
                                                               chat: chat)
                translateService?.translateMessage(translateParam: translateParam, from: targetVC)
            }
        }
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        guard let content = model.message.content as? AudioContent else { return nil }
        if content.showVoiceText.isEmpty {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_ConvertToText_Button,
                                     icon: BundleResources.Menu.menu_show_audio_text,
                                     trackExtraParams: ["click": "speech_to_text'", "target": "none"]) { [weak self] in
                self?.handle(message: model.message, chat: model.chat, hideVoice2Text: false)
            }
        } else {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_HideText_Button,
                                     icon: BundleResources.Menu.menu_hide_audio_text,
                                     trackExtraParams: ["click": "hide_text", "target": "none"]) { [weak self] in
                self?.handle(message: model.message, chat: model.chat, hideVoice2Text: true)
            }
        }
    }
}
