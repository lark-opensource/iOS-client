//
//  AudioContentViewModel.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/10.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkAudio
import LarkUIKit
import LarkSetting
import LKCommonsLogging
import RxSwift
import LarkMessengerInterface
import UniverseDesignToast
import LarkFoundation
import RustPB
import LKRichView

// VM 最小依赖
public protocol AudioContentViewModelContext: ViewModelContext {
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterId: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    var audioPlayMediator: AudioPlayMediator? { get }
    var audioResourceService: AudioResourceService? { get }
    var audioToTextEnable: Bool { get }
    var audioActionsService: AudioActionsService? { get }
    var audioContentLifeService: AudioContentLifeService? { get }
    var downloadFileScene: RustPB.Media_V1_DownloadFileScene? { get }
}

public struct AudioContentConfig {
    // 是否展示未读小红点
    public var showRedDot: Bool
    // 是否主动添加圆角，nil时走默认实现
    public var hasCorner: Bool?
    // 是否主动添加背景色，nil时走默认实现
    public var hasBackgroundColor: Bool?

    public init(
        showRedDot: Bool = true,
        hasCorner: Bool? = nil,
        hasBackgroundColor: Bool? = nil
    ) {
        self.showRedDot = showRedDot
        self.hasCorner = hasCorner
        self.hasBackgroundColor = hasBackgroundColor
    }
}

public class AudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: NewMessageSubViewModel<M, D, C> {

    private var audioResource: AudioResourceManager?
    let audioContentConfig: AudioContentConfig

    public init(metaModel: M, metaModelDependency: D, context: C, audioContentConfig: AudioContentConfig = AudioContentConfig()) {
        if let audioResourceService = context.audioResourceService {
            self.audioResource = AudioResourceManager(message: metaModel.message, audioService: audioResourceService)
        }
        self.audioContentConfig = audioContentConfig
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
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

    lazy var threadReplyBubbleOptimize: Bool = {
        return self.context.getStaticFeatureGating("im.message.thread_reply_bubble_optimize")
    }()

    public var hasRedDot: Bool {
        // thread、合并转发详情页中音频不需要未读红点。
        if context.scene.isThreadScence() || context.scene == .mergeForwardDetail {
            return false
        }
        // 只有当未读且语音未转文字的时候才显示红点
        // 上游资源被撤回时不论已读未读都需要去掉红点
        return audioContentConfig.showRedDot && !message.meRead && !isMe && text.isEmpty && !isFileDeleted && !self.metaModel.getChat().isSuper
    }

    public var boderWidth: CGFloat? {
        return nil
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
            self.binderAbility?.syncToBinder()
            self.binderAbility?.updateComponent()
        }
    }

    public override func willDisplay() {
        super.willDisplay()
        if message.localStatus == .success && audioWaves.isEmpty {
            audioResource?.downloadAudioIfNeeded(downloadFileScene: context.downloadFileScene) { [weak self] _ in
                guard let `self` = self else { return }
                self.binderAbility?.syncToBinder()
            }
        }
        // 语音转文字没有处理完成
        if audioToTextEnable && !isLoadingFinished {
            self.binderAbility?.syncToBinder()
            self.binderAbility?.updateComponent(animation: .none)
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
            return viewModels.compactMap { $0.content as? AudioContentViewModel<M, D, C> }
        }
    }()

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
        var isAudioRecognizeFinish = content.isAudioRecognizeFinish

        let lastUpdateTime = max(message.createTime, content.audio2TextStartTime)
        // 超过 30s 强制不显示 loading
        if Date().timeIntervalSince1970 - lastUpdateTime > 30 {
            isAudioRecognizeFinish = true
        }
        return isAudioRecognizeFinish
    }

    var displayRule: RustPB.Basic_V1_DisplayRule {
        return message.displayRule
    }

    var translateText: String {
        if let content = metaModel.message.translateContent as? AudioContent {
            return content.voiceText
        }
        return ""
    }

    /// 分割线颜色
    public lazy var lineColor: UIColor = {
        return self.context.getColor(for: .Message_BubbleSplitLine, type: self.isFromMe ? .mine : .other)
    }()

    /// 是不是我发的消息
    public lazy var isFromMe: Bool = {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }()

    public var translateContentTextFont: UIFont {
        return UIFont.systemFont(ofSize: 17)
    }

    private lazy var translateMoreActionHandler: TranslateMoreActionHandler = {
        return TranslateMoreActionHandler(context: context, metaModel: metaModel)
    }()

    func translateFeedBackTapHandler() {
        translateMoreActionHandler.translateFeedBackTapHandler()
    }

    func translateMoreTapHandler(_ view: UIView) {
        translateMoreActionHandler.translateMoreTapHandler(view)
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

// MARK: - DataSource for AudioPlayable
extension AudioContentViewModel: AudioPlayable {
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
        return self.metaModel.getChat().isSuper ? true : self.message.meRead
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
final class ChatAudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: AudioContentViewModel<M, D, C> {
    override var showStatusView: Bool {
        return true
    }

    override var shouldPlayContinuously: Bool {
        return true
    }

    override public var hasCorner: Bool {
        if let hasCorner = audioContentConfig.hasCorner {
            return hasCorner
        }
        if message.showInThreadModeStyle {
            return true
        }
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return true
        }
        return false
    }

    override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if disableMarginWhenAudioToText {
            return ContentConfig(hasMargin: false, supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        }

        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        }
        return ContentConfig(hasMargin: false, supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
    }

    override public var background: UIColor? {
        if let hasBackgroundColor = audioContentConfig.hasBackgroundColor {
            let colorThemeType: Type = isMe ? .mine : .other
            return hasBackgroundColor ? context.getColor(for: .Message_Bubble_Background, type: colorThemeType) : .clear
        }
        // 话题模式创建的语音消息
        if message.displayInThreadMode {
            let colorThemeType: Type = isMe ? .mine : .other
            return context.getColor(for: .Message_Bubble_Background, type: colorThemeType)
        }
        // 话题回复，没开FG，则使用和话题模式一样的颜色
        if message.showInThreadModeStyle, !message.displayInThreadMode, !self.threadReplyBubbleOptimize {
            let colorThemeType: Type = isMe ? .mine : .other
            return context.getColor(for: .Message_Bubble_Background, type: colorThemeType)
        }

        // 话题回复该语音消息需要设置背景色
        if message.rootId.isEmpty && message.reactions.isEmpty && !message.showInThreadModeStyle {
            return .clear
        }
        let colorThemeType: Type = isMe ? .mine : .other
        return context.getColor(for: .Message_Audio_BubbleBackground, type: colorThemeType)
    }

    override var contentPreferMaxWidth: CGFloat {
        let rawWidth = metaModelDependency.getContentPreferMaxWidth(message)
        if self.context.scene == .newChat, message.showInThreadModeStyle {
            return rawWidth
        }
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return rawWidth - 2 * metaModelDependency.contentPadding
        }
        return rawWidth
    }
}

final class MergeForwardAudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: AudioContentViewModel<M, D, C> {
    override public var background: UIColor? {
        // 话题模式创建的语音消息
        if message.displayInThreadMode {
            let colorThemeType: Type = isMe ? .mine : .other
            return context.getColor(for: .Message_Bubble_Background, type: colorThemeType)
        }
        // 话题回复，没开FG，则使用和话题模式一样的颜色
        if message.showInThreadModeStyle, !message.displayInThreadMode, !self.threadReplyBubbleOptimize {
            let colorThemeType: Type = isMe ? .mine : .other
            return context.getColor(for: .Message_Bubble_Background, type: colorThemeType)
        }
        // 话题回复该语音消息需要设置背景色
        if message.rootId.isEmpty && message.reactions.isEmpty && !message.showInThreadModeStyle {
            return .clear
        }
        let colorThemeType: Type = isMe ? .mine : .other
        return context.getColor(for: .Message_Audio_BubbleBackground, type: colorThemeType)
    }

    override var showStatusView: Bool {
        return true
    }

    override var shouldPlayContinuously: Bool {
        return true
    }

    override public var hasCorner: Bool {
        if message.showInThreadModeStyle {
            return true
        }
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return true
        }
        return false
    }

    override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if disableMarginWhenAudioToText {
            return ContentConfig(hasMargin: false, supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        }

        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        }
        return ContentConfig(hasMargin: false, supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
    }

    override var contentPreferMaxWidth: CGFloat {
        let rawWidth = metaModelDependency.getContentPreferMaxWidth(message)
        if self.context.scene == .mergeForwardDetail, message.showInThreadModeStyle {
            return rawWidth
        }
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return rawWidth - 2 * metaModelDependency.contentPadding
        }
        return rawWidth
    }
}

final class ThreadChatAudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: AudioContentViewModel<M, D, C> {
    override var background: UIColor? {
        return context.getColor(for: .Message_Bubble_Background, type: .other)
    }

    override func generateColorConfig() -> AudioView.ColorConfig? {
        let colorThemeType: Type = .other
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

final class ThreadDetailAudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: AudioContentViewModel<M, D, C> {
    override var shouldPlayContinuously: Bool {
        return true
    }

    override var background: UIColor? {
        if context.scene == .replyInThread {
            let colorThemeType: Type = isMe ? .mine : .other
            return context.getColor(for: .Message_Bubble_Background, type: colorThemeType)
        }
        return context.getColor(for: .Message_Bubble_Background, type: .other)
    }

    override func generateColorConfig() -> AudioView.ColorConfig? {
        if context.scene == .replyInThread {
            return super.generateColorConfig()
        }
        let colorThemeType: Type = .other
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

final class MessageDetailAudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: AudioContentViewModel<M, D, C> {
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

final class PinAudioContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: AudioContentViewModel<M, D, C> {
    override var showStatusView: Bool {
        return true
    }

    override var shouldPlayContinuously: Bool {
        return false
    }

    override var background: UIColor? {
        // Pin不区分自己和他人，都用他人
        return context.getColor(for: .Message_Bubble_Background, type: .other)
    }

    override func generateColorConfig() -> AudioView.ColorConfig? {
        let colorThemeType: Type = .other
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
