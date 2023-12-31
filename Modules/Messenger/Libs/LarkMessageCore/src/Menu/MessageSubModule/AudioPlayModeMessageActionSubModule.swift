//
//  AudioPlayMode.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/16.
//

import Foundation
import LarkModel
import RxSwift
import LarkOpenChat
import UniverseDesignToast
import LarkUIKit
import LarkMessengerInterface
import LarkContainer

public final class AudioPlayModeMessageActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType {
        return .audioPlayMode
    }

    @ScopedInjectedLazy private var audioPlayMediator: AudioPlayMediator?

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return Display.phone
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        guard model.message.type == .audio else { return false}
        return true
    }

    /// 切换播放模式
    private func handle(message: Message, chat: Chat, toSpeaker: Bool) {
        guard let targetVC = self.context.targetVC, var audioPlayMediator = self.audioPlayMediator else { return }
        if self.context.userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.playby.improvements") {
            let canStop = switch audioPlayMediator.status {
                          case .playing, .pause: true
                          default: false
            }
            if canStop {
                audioPlayMediator.stopPlayingAudio()
            }
            audioPlayMediator.outputType = toSpeaker ? .speaker : .earPhone
            AudioPlayUtil.showPlayStatusOnView(targetVC.view, status: toSpeaker ? .audioSpeaker : .audioEarPhone)
            return
        }
        if audioPlayMediator.isPlaying {
            audioPlayMediator.stopPlayingAudio()
        }
        audioPlayMediator.outputType = toSpeaker ? .speaker : .earPhone
        AudioPlayStatusView.showAudioPlayStatusOnView(targetVC.view, status: toSpeaker ? .audioSpeaker : .audioEarPhone)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        guard let audioPlayMediator = self.audioPlayMediator else { return nil }
        /// 这里是当前的播放模式 所以如果是speaker就需要调整为earpiece_play
        switch audioPlayMediator.outputType {
        case .speaker:
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_PlayByReceiver_Button,
                                     icon: BundleResources.Menu.menu_earphone,
                                     trackExtraParams: ["click": "earpiece_play_voice", "target": "none"]) { [weak self] in
                self?.handle(message: model.message, chat: model.chat, toSpeaker: false)
            }
        default:
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_PlayBySpeaker_Button,
                                     icon: BundleResources.Menu.menu_speaker,
                                     trackExtraParams: ["click": "speaker_play_voice", "target": "none"]) { [weak self] in
                self?.handle(message: model.message, chat: model.chat, toSpeaker: true)
            }
        }
    }
}
