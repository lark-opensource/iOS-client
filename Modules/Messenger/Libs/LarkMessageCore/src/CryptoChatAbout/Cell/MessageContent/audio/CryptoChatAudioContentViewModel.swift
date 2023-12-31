//
//  CryptoChatAudioContentViewModel.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/18.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkAudio
import LarkUIKit
import LKCommonsLogging
import RxSwift
import LarkMessengerInterface
import UniverseDesignToast
import LarkSetting
import LarkFoundation
import RustPB

class CryptoAudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: MessageSubViewModel<M, D, C> {
    private var audioResource: AudioResourceManager?
    private lazy var audioAction: AudioActionsService? = {
        return context.audioActionsService
    }()

    private lazy var audioLifeService: AudioContentLifeService? = {
        return context.audioContentLifeService
    }()

    override public init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        if let audioResourceService = context.audioResourceService {
            self.audioResource = AudioResourceManager(message: metaModel.message, audioService: audioResourceService)
        }
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    override public var identifier: String {
        return "audio"
    }

    public var content: AudioContent {
        return (message.content as? AudioContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    public var isFileDeleted: Bool {
        return message.fileDeletedStatus != .normal
    }

    // 总时长
    public var duration: TimeInterval {
        return TimeInterval(content.duration) / 1000
    }

    // 根据AudioLevel控制View宽度
    public var audioLevel: AudioLevel {
        return  AudioLevel.level(time: duration)
    }

    // AudioView最小宽度
    public var audioViewMinwidth: CGFloat {
        return audioLevel.minLenght()
    }

    public var isMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    public var audioToTextEnable: Bool {
        return context.audioToTextEnable
    }

    public var hasRedDot: Bool {
        // 只有当未读且语音未转文字的时候才显示红点
        // 上游资源被撤回时不论已读未读都需要去掉红点
        return !message.meRead && !isMe && text.isEmpty && !isFileDeleted
    }

    // 点赞（非newchat）/回复 未读红点在气泡内
    public var isDotInside: Bool {
        if !message.rootId.isEmpty { return true }
        if !message.reactions.isEmpty && self.context.scene != .newChat { return true }
        return false
    }

    public var hasBoder: Bool {
        return false
    }

    public var hasCorner: Bool {
        return true
    }

    public var stateValue: AudioPlayMediatorStatus = .default(nil) {
        didSet {
            self.binder.update(with: self)
            update(component: binder.component)
        }
    }

    public override func willDisplay() {
        super.willDisplay()
        if message.localStatus == .success && audioWaves.isEmpty {
            audioResource?.downloadAudioIfNeeded(downloadFileScene: context.downloadFileScene) { [weak self] _ in
                guard let `self` = self else { return }
                self.binder.update(with: self)
            }
        }
        // 语音转文字没有处理完成
        if audioToTextEnable && !isLoadingFinished {
            self.binder.update(with: self)
            self.update(component: self.binder.component, animation: .none)
        }
    }

    public var audioWaves: [AudioProcessWave] {
        return audioResource?.audioWaves ?? []
    }

    public var originText: String {
        if self.isFileDeleted { return "" }
        return audioToTextEnable ? content.voiceText : ""
    }

    public var text: String {
        if self.isFileDeleted { return "" }
        return audioToTextEnable ? content.showVoiceText : ""
    }

    public var hideVoice2Text: Bool {
        return content.hideVoice2Text
    }

    lazy var audioProvider: () -> [AudioPlayable] = {
        // cellvm不保证生命周期，会被销毁。音频数据源本身的提供者也应该是context，而不是cellvm,不能依赖self，而需要持有context
        // MARK: 请不要在下面这个闭包里访问self,否则会造成循环引用
        let context = self.context
        // context会持有AudioActionsService，AudioActionsService最终会通过AudiosProvider持有context，
        // context这里也需要weak，否则会引用循环
        return { [weak context] in
            let viewModels: [MessageCellViewModel<M, D, C>] = context?.filter { _ in true } ?? []
            return viewModels.compactMap { $0.content as? CryptoAudioContentViewModel<M, D, C> }
        }
    }()

    // 缓存当前数据源内 messageID - key 的映射
    // 用于消息销毁时，通过id找key然后停止播放
    // 因为有语音连播，不能只缓存当前点击的message，需要全部缓存
    private func storeAudioContentKey() {
        audioLifeService?.audioKeys.safeWrite { dict in
            audioProvider().forEach {
                dict[$0.messageId] = $0.audioKey
            }
        }
    }

    // 是否显示顶部提示Banner
    var showStatusView: Bool {
        return false
    }

    // 是否是用户填写的文字
    var isAudioWithText: Bool {
        return self.content.isAudioWithText
    }

    // 是否可以连续播放
    var shouldPlayContinuously: Bool {
        return false
    }

    var contentPreferMaxWidth: CGFloat {
        let rawWidth = metaModelDependency.getContentPreferMaxWidth(message)
        // 语音气泡在回复内||Reaction，左右加缩进
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return rawWidth - 2 * metaModelDependency.contentPadding
        }
        return rawWidth
    }

    var style: AudioView.Style {
        return .light
    }

    var audioViewInset: UIEdgeInsets {
        var inset = AudioView.defaultInset

        // 用户主动设置文字
        if content.isAudioWithText {
            if !text.isEmpty {
                inset.top = 9
            }
        }
        // 自动识别文字
        else {
            if !text.isEmpty {
                inset.bottom = 9
            }
        }
        return inset
    }

    var isLoadingFinished: Bool {
        /// 密聊会话不存在 loading 状态
        return true
    }

    // 非回复消息，没有 reaction 隐藏 margin
    public var disableMarginWhenAudioToText: Bool {
        return message.parentMessage == nil
            && message.reactions.isEmpty
    }

    public override var contentConfig: ContentConfig? {
        if disableMarginWhenAudioToText {
            return ContentConfig(hasMargin: false, supportMutiSelect: true)
        }

        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, supportMutiSelect: true)
        }
        return ContentConfig(hasMargin: false, supportMutiSelect: true)
    }

    public var background: UIColor? {
        if message.rootId.isEmpty && message.reactions.isEmpty {
            return .clear
        }
        let colorThemeType: Type = isMe ? .mine : .other
        return context.getColor(for: .Message_Audio_BubbleBackground, type: colorThemeType)
    }

    public var audioWithTextTextColor: UIColor {
        let colorThemeType: Type = isMe ? .mine : .other
        return context.getColor(for: .Message_Text_Foreground, type: colorThemeType)
    }

    public var audioTextColor: UIColor {
        return UIColor.ud.textTitle
    }

    public var convertStateColor: UIColor {
        let colorThemeType: Type = isMe ? .mine : .other
        return context.getColor(for: .Message_Audio_ConvertState, type: colorThemeType)
    }

    public var convertStateButtonBackground: UIColor {
        let colorThemeType: Type = isMe ? .mine : .other
        return context.getColor(for: .Message_Audio_ConvertStateButtonBackground, type: colorThemeType)
    }

    public func generateColorConfig() -> AudioView.ColorConfig? {
        let colorThemeType: Type = isMe ? .mine : .other
        return AudioView.ColorConfig(
            panColorConfig: AudioView.PanColorConfig(
                background: context.getColor(for: .Message_Audio_ButtonBackground, type: colorThemeType),
                readyBorder: nil,
                playBorder: nil
            ),
            stateColorConfig: AudioView.StateColorConfig(
                background: context.getColor(for: .Message_Audio_ButtonBackground, type: colorThemeType),
                foreground: context.getColor(for: .Message_Audio_PlayButtonBackground, type: colorThemeType)
            ),
            background: UIColor.clear,
            lineBackground: context.getColor(for: .Message_Audio_ProgressBarBackground, type: colorThemeType),
            processLineBackground: context.getColor(for: .Message_Audio_ProgressBarForeground, type: colorThemeType),
            timeLabelText: context.getColor(for: .Message_Audio_TimeTextForeground, type: colorThemeType),
            invalidTimeLabelText: nil
        )
    }
}

// MARK: - AudioViewActionDelegate
extension CryptoAudioContentViewModel: AudioViewActionDelegate {
    public func audioViewPanAction(_ audioView: AudioView, _ state: AudioView.PanState, _ progress: TimeInterval) {
        if state == .start { AudioTracker.trackAudioPlayDrag() }

        // 开始结束更新状态
        if state != .dragging {
            var status: AudioPlayMediatorStatus
            if state == .start {
                // 开始拖动中暂停播放
                status = .pause(AudioProgress(
                    key: content.key,
                    authToken: content.authToken,
                    current: TimeInterval(content.duration) * progress / 1000,
                    duration: duration
                ))
            } else {
                // 停止拖动播放
                status = .playing(AudioProgress(
                    key: content.key,
                    authToken: content.authToken,
                    current: TimeInterval(content.duration) * progress / 1000,
                    duration: duration
                ))
            }
            self.playAudio(model: message, status: status)
        }

        if case .loading = self.stateValue {
            audioView.updateCurrentState(.loading(TimeInterval(content.duration) * progress / 1000))
        } else {
            audioView.updateCurrentState(.draging(TimeInterval(content.duration) * progress / 1000))
        }

        if state == .start {
            storeAudioContentKey()
            context.dataSourceAPI?.pauseDataQueue(true)
        } else if state == .end {
            context.dataSourceAPI?.pauseDataQueue(false)
        }
    }

    public func audioViewTapAction() {
        guard !isFileDeleted else {
            if let window = self.context.targetVC?.view.window {
                switch self.message.fileDeletedStatus {
                case .freedUp:
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
                @unknown default:
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_Message_AudioMessageWithdrawToast, on: window)
                }
            }
            return
        }
        storeAudioContentKey()
        self.playAudio(model: message)
    }

    // 所有播放方法入口
    private func playAudio(model: Message, status: AudioPlayMediatorStatus? = nil) {
        let audioProvider = self.audioProvider
        guard let audioAction = self.audioAction else {
            return
        }
        audioAction.dataProvider = {
            audioProvider()
        }
        audioAction.showStatusView = self.showStatusView
        audioAction.shouldPlayContinuously = self.shouldPlayContinuously
        audioAction.playAudio(model: message, status: status, downloadFileScene: context.downloadFileScene)
    }
}

// MARK: - DataSource for AudioPlayable
extension CryptoAudioContentViewModel: AudioPlayable {
    var audioKey: String {
        return (self.message.content as? AudioContent)?.key ?? ""
    }

    var audioLength: TimeInterval {
        return TimeInterval((self.message.content as? AudioContent)?.duration ?? 0)
    }

    var fromId: String {
        return self.message.fromId
    }

    var meRead: Bool {
        return self.message.meRead
    }

    var messageId: String {
        return self.message.id
    }

    var messageCid: String {
        return self.message.cid
    }

    var position: Int32 {
        return self.message.position
    }

    var positionBadgeCount: Int32 {
        return self.message.badgeCount
    }

    var channel: RustPB.Basic_V1_Channel {
        return self.message.channel
    }

    var state: AudioPlayMediatorStatus {
        get { return self.stateValue }
        set { self.stateValue = newValue }
    }

    var authToken: String? {
        return (self.message.content as? AudioContent)?.authToken
    }
}

/// SubClass
final class CryptoChatAudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: CryptoAudioContentViewModel<M, D, C> {
    override var showStatusView: Bool {
        return true
    }

    override var shouldPlayContinuously: Bool {
        return true
    }

    override public var hasCorner: Bool {
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return true
        }
        return false
    }

    override var contentConfig: ContentConfig? {
        if disableMarginWhenAudioToText {
            return ContentConfig(hasMargin: false, supportMutiSelect: true)
        }

        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, supportMutiSelect: true)
        }
        return ContentConfig(hasMargin: false, supportMutiSelect: true)
    }
}

final class CryptoChatMessageDetailAudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: CryptoAudioContentViewModel<M, D, C> {
    override public var isDotInside: Bool {
        return false
    }

    override var background: UIColor? {
        let colorThemeType: Type = isMe ? .mine : .other
        return context.getColor(for: .Message_Bubble_Background, type: colorThemeType)
    }

    override var showStatusView: Bool {
        return true
    }

    override var shouldPlayContinuously: Bool {
        return true
    }
}
