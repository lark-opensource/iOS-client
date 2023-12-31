//
//  FloatingInteractionViewModel.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/8/19.
//

import Foundation
import ByteViewCommon
import ByteViewSetting
import ByteViewNetwork

// 以下方法均保证在主线程执行
protocol FloatingInteractionViewModelDelegate: AnyObject {
    // ====== Reaction ======

    func toolbarReactionVisibilityDidChange()
    func recentReactionsDidChange(reactions: [ReactionEntity])
    func allReactionsDidChange(reactions: [Emojis])
    /// 从后端收到新的表情推送，或者自己发送了新表情时的回调，小窗回大窗时也会把当前保存的未过期的表情回调
    func didReceiveNewReaction(reactionMessage: ReactionMessage)

    func didChangeStatusReaction(info: ParticipantSettings.ConditionEmojiInfo?)

    func didChangePanelistPermission(isUpdateMessage: Bool)

    func didUpdateHandsUpSkin(key: String)
    // ======= whiteboardStateChange =======
    func didChangeWhiteboardOperateStatus(isOpaque: Bool)
}

extension FloatingInteractionViewModelDelegate {
    func toolbarReactionVisibilityDidChange() {}
    func recentReactionsDidChange(reactions: [ReactionEntity]) {}
    func allReactionsDidChange(reactions: [Emojis]) {}
    func didReceiveNewReaction(reactionMessage: ReactionMessage) {}
    func didChangeStatusReaction(info: ParticipantSettings.ConditionEmojiInfo?) {}
    func didChangePanelistPermission(isUpdateMessage: Bool) {}
    func didUpdateHandsUpSkin(key: String) {}
    func didChangeWhiteboardOperateStatus(isOpaque: Bool) {}
}

final class FloatingInteractionViewModel {
    var currentPosition: CGPoint?
    var panelState: PanelState = .expanded
    var panelLocation: PanelLocation = .left
    var isPortraitOnExit = false
    var isLongPress = false
    var isToolBarReactionHidden = false {
        didSet {
            if isToolBarReactionHidden != oldValue {
                listeners.forEach { $0.toolbarReactionVisibilityDidChange() }
            }
        }
    }

    enum PanelState {
        case expanded
        case collapsed
        case dragging
    }

    enum PanelLocation {
        case left
        case right
    }

    private static let logger = Logger.im

    private lazy var bubbleConfig = BubbleReactionConfig()
    lazy var floatConfig = FloatReactionConfig(setting: meeting.setting)
    private let listeners = Listeners<FloatingInteractionViewModelDelegate>()
    /// 从后端拉的 IM 最近使用表情
    @RwAtomic
    private var recentReactions: [ReactionEntity] = []
    /// 从后端拉的所有表情
    private var allReactions: [Emojis] = []
    /// 本地保存的从后端收到的表情，一段时间后过期，用于从小窗回到大窗时，回调给上层当前未过期的表情
    private var pendingReactions: [ReactionMessage] = []
    private var lastStatusEmojiInfo: ParticipantSettings.ConditionEmojiInfo?

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    private var avatarInfo: AvatarInfo = .asset(AvatarResources.unknown)
    private let chatViewModel: ChatMessageViewModel
    private let imChatViewModel: IMChatViewModel
    private var httpClient: HttpClient { meeting.httpClient }
    private var emotion: EmotionDependency { meeting.service.emotion }
    private var emojiData: EmojiDataDependency { meeting.service.emojiData }
    var fullScreenDetector: InMeetFullScreenDetector? { context.fullScreenDetector }
    var showReactionPanelBlock: ((UIView) -> Void)?
    var hideReactionPanelBlock: (() -> Void)?

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        self.chatViewModel = resolver.resolve()!
        self.imChatViewModel = resolver.resolve()!
        meeting.addMyselfListener(self)
        meeting.setting.addListener(self, for: [.allowSendMessage, .allowSendReaction])
        meeting.setting.addComplexListener(self, for: .handsUpEmojiKey)
        meeting.push.chatMessage.addObserver(self)
        context.addListener(self, for: [.scope, .whiteboardOperateStatus])
        meeting.push.userRecentEmojiEvent.addObserver(self) { [weak self] in
            self?.didReceiveUserRecentEmojiEvent($0)
        }
        meeting.push.emojiPanel.addObserver(self) { [weak self] in
            self?.didReceiveEmojiPanelMessages($0)
        }
        DispatchQueue.global().async { [weak self] in
            self?.fetchData()
        }
    }

    // MARK: - Public

    var isFlowPageControlVisible: Bool {
        context.isFlowPageControlVisible
    }

    var meetingTopic: String {
        meeting.topic
    }

    var allowSendMessage: Bool {
        meeting.setting.allowSendMessage
    }

    var allowSendReaction: Bool {
        meeting.setting.allowSendReaction
    }

    var isReactionPanelExpanded = false

    func addListener(_ listener: FloatingInteractionViewModelDelegate, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            notifyListenerImmediately(listener)
        }
    }

    func sendReaction(_ reactionKey: String) {
        let id = meeting.data.meetingIdForRequest
        let role = meeting.myself.meetingRole
        let request = SendInteractionMessageRequest(meetingId: id, content: .reaction(reactionKey), role: role)
        httpClient.send(request)
        let myself = meeting.myself
        let participantService = httpClient.participantService
        participantService.participantInfo(pid: myself, meetingId: meeting.meetingId) { [weak self] info in
            guard let self = self else { return }
            let account = self.meeting.account
            let reactionMessage = ReactionMessage(userId: account.id,
                                                  userName: info.name,
                                                  avatarInfo: self.avatarInfo,
                                                  userType: account.type,
                                                  userRole: self.meeting.myself.role,
                                                  reactionKey: reactionKey)
            self.updateShowingReactions(reactionMessage: reactionMessage)
        }
    }

    func sendMessage(_ text: String) {
        if meeting.setting.isUseImChat {
            imChatViewModel.sendText(text)
        } else {
            chatViewModel.sendMessage(content: text)
        }
    }

    func updateUnsendText(_ text: String) {
        chatViewModel.recordUnSendText(text)
    }

    func showReactionPanel(at anchor: UIView) {
        showReactionPanelBlock?(anchor)
    }

    func hideReactionPanel() {
        hideReactionPanelBlock?()
    }

    func raiseHand(isHandsUp: Bool, handsUpEmojiKey: String) {
        var request = ParticipantChangeSettingsRequest(meeting: meeting)
        request.participantSettings.conditionEmojiInfo = ParticipantSettings.ConditionEmojiInfo(isHandsUp: isHandsUp, handsUpEmojiKey: handsUpEmojiKey)
        httpClient.send(request)
    }

    func quickLeave(isStepUp: Bool) {
        var request = ParticipantChangeSettingsRequest(meeting: meeting)
        request.participantSettings.conditionEmojiInfo = ParticipantSettings.ConditionEmojiInfo(isStepUp: isStepUp)
        httpClient.send(request)
    }

    func createMeetingGroupIfNeeded() {
        imChatViewModel.createMeetingGroupIfNeeded()
    }

    func isChatEnabled() -> Bool {
        imChatViewModel.isChatEnabled()
    }

    func isChangeSkin(_ reactionKey: String) -> Bool {
        allReactions.first { $0.keys.contains { $0.key != reactionKey && $0.selectedSkinKey == reactionKey } } != nil
    }

    func selectedSkinKey(for reactionKey: String) -> String? {
        allReactions.flatMap { $0.keys }.first { $0.key == reactionKey }?.selectedSkinKey
    }

    func updateRecentEmoji() {
        let imRecentReactions = emojiData.getUserReactionsByType()
        if imRecentReactions.isEmpty {
            Self.logger.error("im recent reaction keys is empty")
        }
        if recentReactions.isEmpty {
            recentReactions = imRecentReactions
        } else {
            recentReactions = (recentReactions + imRecentReactions).uniqued(by: { $0.key })
        }
        Util.runInMainThread {
            self.listeners.forEach { $0.recentReactionsDidChange(reactions: self.recentReactions) }
        }
    }

    // MARK: - Private

    private func fetchData() {
        let participantService = httpClient.participantService
        participantService.participantInfo(pid: meeting.account, meetingId: meeting.meetingId) { [weak self] ap in
            self?.avatarInfo = ap.avatarInfo
        }
        updateRecentEmoji()

        let reactionGroups = emojiData.getAllReactions()
        self.allReactions = reactionGroups.map({ group in
            Emojis(type: group.type,
                   iconKey: group.iconKey,
                   title: group.title,
                   source: group.source,
                   keys: group.entities.compactMap({
                guard meeting.service.emotion.imageByKey($0.key) != nil else { return nil }
                return .init(key: $0.key, selectedSkinKey: $0.selectSkinKey)
            }))
        })
        Util.runInMainThread {
            self.listeners.forEach { $0.allReactionsDidChange(reactions: self.allReactions) }
        }
    }

    private func notifyListenerImmediately(_ listener: FloatingInteractionViewModelDelegate) {
        listener.recentReactionsDidChange(reactions: recentReactions)
        listener.allReactionsDidChange(reactions: allReactions)
        listener.didChangeStatusReaction(info: lastStatusEmojiInfo)
    }

    private func updateShowingReactions(reactionMessage: ReactionMessage) {
        checkExpirations()
        if let message = pendingReactions.first(where: { $0.isEqual(reactionMessage) }) {
            message.count = (message.count + reactionMessage.count) % Int.max
            message.startTime = Date().timeIntervalSince1970
            message.duration = reactionDuration
            Util.runInMainThread {
                self.throttledReactionChangeNotify.call(message)
            }
        } else if pendingReactions.count < reactionQueueCapacity {
            reactionMessage.duration = reactionDuration
            pendingReactions.append(reactionMessage)
            Util.runInMainThread {
                self.listeners.forEach { $0.didReceiveNewReaction(reactionMessage: reactionMessage) }
            }
        }
    }

    private lazy var throttledReactionChangeNotify: _Throttle<ReactionMessage> = {
        _Throttle(interval: .milliseconds(100)) { [weak self] reaction in
            self?.listeners.forEach { $0.didReceiveNewReaction(reactionMessage: reaction) }
        }
    }()

    private func checkExpirations() {
        var expiredReactions: [ReactionMessage] = []
        for reaction in pendingReactions {
            if Date().timeIntervalSince1970 - reaction.startTime >= reactionDuration {
                expiredReactions.append(reaction)
            }
        }
        pendingReactions.removeAll(where: { pendingReaction in
            expiredReactions.firstIndex(where: { pendingReaction.isEqual($0) }) != nil
        })
    }

    private var reactionQueueCapacity: Int {
        switch meeting.setting.reactionDisplayMode {
        case .floating:
            return floatConfig.reactionQueueCapacity
        case .bubble:
            return bubbleConfig.reactionQueueCapacity
        }
    }

    private var reactionDuration: TimeInterval {
        switch meeting.setting.reactionDisplayMode {
        case .floating:
            return floatConfig.reactionAnimationDuration(for: pendingReactions.count)
        case .bubble:
            return bubbleConfig.reactionAnimationDuration(for: pendingReactions.count)
        }
    }

    private func getReactionImageSize(by key: String) -> CGSize {
        return emotion.sizeBy(key) ?? CGSize(width: 28, height: 28)
    }

    func setIsToolbarReactionHidden(_ isHidden: Bool) {
        isToolBarReactionHidden = isHidden
    }
}

extension FloatingInteractionViewModel: InteractionMessagePushObserver {
    func didReceiveInteractionMessage(_ message: VideoChatInteractionMessage, expiredMsgPosition: Int32?) {
        guard !context.isHiddenReactionBubble || message.fromUser.userID == meeting.userId, message.type == .reaction, message.meetingID == meeting.data.meetingIdForRequest else { return }
        let participantService = httpClient.participantService
        participantService.participantInfo(pid: message.fromUser, meetingId: meeting.meetingId) { [weak self] info in
            guard let self = self else { return }
            let userId = message.fromUser.userID
            let reactionMessage = ReactionMessage(userId: userId,
                                                  userName: info.name,
                                                  avatarInfo: .remote(key: message.fromUser.avatarKey, entityId: userId),
                                                  userType: message.fromUser.type,
                                                  userRole: message.fromUser.role,
                                                  reactionKey: message.reactionContent?.content ?? "")
            let count = message.reactionContent?.count ?? 0
            reactionMessage.count = max(count, 1)
            self.updateShowingReactions(reactionMessage: reactionMessage)
        }
    }
}

extension FloatingInteractionViewModel {
    func didReceiveEmojiPanelMessages(_ message: EmojiPanelPushMessages) {
        allReactions = message.emojiPanel.emojisOrder
        Util.runInMainThread {
            self.listeners.forEach { $0.allReactionsDidChange(reactions: message.emojiPanel.emojisOrder) }
        }
    }
}

extension FloatingInteractionViewModel: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .scope, let scope = userInfo as? InMeetViewScope, scope == .fullScreen {
            checkExpirations()
            Util.runInMainThread {
                for reaction in self.pendingReactions {
                    self.listeners.forEach { $0.didReceiveNewReaction(reactionMessage: reaction) }
                }
            }
        } else if change == .whiteboardOperateStatus, let isOpaque = userInfo as? Bool {
            listeners.forEach { $0.didChangeWhiteboardOperateStatus(isOpaque: isOpaque) }
        }
    }
}

extension FloatingInteractionViewModel {
    func didReceiveUserRecentEmojiEvent(_ event: UserRecentEmojiEvent) {
        guard event.userId == meeting.userId, !event.recentEmoji.isEmpty else { return }
        let recentEmoji = event.recentEmoji.filter({
            $0 != "" && !$0.hasPrefix("VC_") && meeting.service.emotion.imageByKey($0) != nil
        }).map({
            ReactionEntity(key: $0, selectSkinKey: "", skinKeys: self.emotion.skinKeysBy($0), size: self.getReactionImageSize(by: $0))
        })
        if recentEmoji.count >= 7 {
            recentReactions = recentEmoji
        } else {
            recentReactions = (recentEmoji + self.recentReactions).uniqued(by: { $0.key })
            updateRecentEmoji()
        }
    }
}

extension FloatingInteractionViewModel: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        guard let newInfo = myself.settings.conditionEmojiInfo, newInfo != oldValue?.settings.conditionEmojiInfo else {
            return
        }
        self.lastStatusEmojiInfo = newInfo
        Util.runInMainThread {
            self.listeners.forEach { $0.didChangeStatusReaction(info: newInfo) }
        }
    }
}

extension FloatingInteractionViewModel: MeetingSettingListener, MeetingComplexSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        Util.runInMainThread {
            switch key {
            case .allowSendMessage:
                self.listeners.forEach { $0.didChangePanelistPermission(isUpdateMessage: true) }
            case .allowSendReaction:
                self.listeners.forEach { $0.didChangePanelistPermission(isUpdateMessage: false) }
            default:
                break
            }
        }
    }

    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        if key == .handsUpEmojiKey, let setting = value as? String {
            Util.runInMainThread {
                self.listeners.forEach { $0.didUpdateHandsUpSkin(key: setting) }
            }
        }
    }
}

extension Logger {
    static let interaction = getLogger("Interaction")
}
