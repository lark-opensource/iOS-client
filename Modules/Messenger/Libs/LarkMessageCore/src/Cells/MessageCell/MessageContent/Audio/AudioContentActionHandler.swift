//
//  AudioContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/1.
//

import Foundation
import LarkModel
import LarkAudio
import LarkMessageBase
import UniverseDesignToast
import LarkMessengerInterface

public class AudioContentActionHandler<C: PageContext>: ComponentActionHandler<C> {
    private lazy var audioAction: AudioActionsService? = {
        return context.audioActionsService
    }()
    private lazy var audioLifeService: AudioContentLifeService? = {
        return context.audioContentLifeService
    }()

    // swiftlint:disable function_parameter_count
    func audioViewPanAction(
        audioView: AudioView,
        state: AudioView.PanState,
        progress: TimeInterval,
        duration: TimeInterval,
        stateValue: AudioPlayMediatorStatus,
        showStatusView: Bool,
        shouldPlayContinuously: Bool,
        audioProvider: @escaping () -> [AudioPlayable],
        content: AudioContent,
        message: Message,
        chat: Chat
    ) {
        if state == .start { AudioTracker.trackAudioPlayDrag() }

        // 开始结束更新状态
        if state != .dragging {
            var status: AudioPlayMediatorStatus
            if state == .start {
                // 开始拖动中暂停播放
                status = .pause(AudioProgress(key: content.key, authToken: content.authToken, current: TimeInterval(content.duration) * progress / 1000, duration: duration))
            } else {
                // 停止拖动播放
                status = .playing(AudioProgress(key: content.key, authToken: content.authToken, current: TimeInterval(content.duration) * progress / 1000, duration: duration))
            }
            self.playAudio(
                message: message,
                showStatusView: showStatusView,
                shouldPlayContinuously: shouldPlayContinuously,
                audioProvider: audioProvider,
                status: status
            )
        }

        if case .loading = stateValue {
            audioView.updateCurrentState(.loading(TimeInterval(content.duration) * progress / 1000))
        } else {
            audioView.updateCurrentState(.draging(TimeInterval(content.duration) * progress / 1000))
        }

        if state == .start {
            storeAudioContentKey(audioProvider: audioProvider)
            context.dataSourceAPI?.pauseDataQueue(true)
        } else if state == .end {
            context.dataSourceAPI?.pauseDataQueue(false)
        }
    }
    // swiftlint:enable function_parameter_count

    func audioViewTapAction(
        message: Message,
        chat: Chat,
        showStatusView: Bool,
        shouldPlayContinuously: Bool,
        audioProvider: @escaping () -> [AudioPlayable]
    ) {
        guard message.fileDeletedStatus == .normal else {
            if let window = self.context.targetVC?.view.window {
                switch message.fileDeletedStatus {
                case .freedUp:
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
                @unknown default:
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_Message_AudioMessageWithdrawToast, on: window)
                }
            }
            return
        }
        storeAudioContentKey(audioProvider: audioProvider)
        self.playAudio(
            message: message,
            showStatusView: showStatusView,
            shouldPlayContinuously: shouldPlayContinuously,
            audioProvider: audioProvider
        )
    }

    // 所有播放方法入口
    private func playAudio(
        message: Message,
        showStatusView: Bool,
        shouldPlayContinuously: Bool,
        audioProvider: @escaping () -> [AudioPlayable],
        status: AudioPlayMediatorStatus? = nil
    ) {
        guard let audioAction = self.audioAction else {
            return
        }
        audioAction.dataProvider = {
            audioProvider()
        }
        audioAction.showStatusView = showStatusView
        audioAction.shouldPlayContinuously = shouldPlayContinuously
        audioAction.playAudio(model: message, status: status, downloadFileScene: context.downloadFileScene)
    }

    // 缓存当前数据源内 messageID - key 的映射
    // 用于消息销毁时，通过id找key然后停止播放
    // 因为有语音连播，不能只缓存当前点击的message，需要全部缓存
    private func storeAudioContentKey(audioProvider: @escaping () -> [AudioPlayable]) {
        audioLifeService?.audioKeys.safeWrite { dict in
            audioProvider().forEach {
                dict[$0.messageId] = $0.audioKey
            }
        }
    }
}
