//
//  ToolBarReactionItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/9/2.
//

import Foundation
import ByteViewSetting
import ByteViewNetwork

final class ToolBarReactionItem: ToolBarItem {
    private let reactions: [String]
    var showingReactions: [String] = []
    let interactionViewModel: FloatingInteractionViewModel
    private var longPressTimer: Timer?
    private static let pressTriggleTime: TimeInterval = 0.3
    private var comboCount = 0
    var allowSendReaction: Bool {
        didSet {
            if allowSendReaction != oldValue {
                notifyListeners()
            }
        }
    }

    private var fullScreenDetector: InMeetFullScreenDetector?
    private var blockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard blockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    override var itemType: ToolBarItemType {
        .reaction
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .emojiFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .emojiOutlined)
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.isWebinarAttendee ? .center : .left
    }

    required init(meeting: InMeetMeeting, provider: ToolBarServiceProvider?, resolver: InMeetViewModelResolver) {
        self.fullScreenDetector = resolver.viewContext.fullScreenDetector
        self.allowSendReaction = meeting.setting.allowSendReaction
        self.interactionViewModel = resolver.resolve()!
        if meeting.subType == .webinar {
            self.reactions = meeting.isWebinarAttendee ?
                ["APPLAUSE", "THUMBSUP", "FINGERHEART", "PARTY", "YouAreTheBest"] :
                ["APPLAUSE", "THUMBSUP", "PARTY"]
        } else {
            self.reactions = ["THUMBSUP", "OK", "JIAYI"]
        }
        self.showingReactions = self.reactions
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.setting.addListener(self, for: [.allowSendReaction])
        self.interactionViewModel.addListener(self)
    }

    override func clickAction() {
        guard let view = provider?.itemView(with: .reaction) as? PadToolBarReactionView else { return }
        if interactionViewModel.isReactionPanelExpanded {
            interactionViewModel.hideReactionPanel()
        } else {
            interactionViewModel.showReactionPanel(at: view.button)
        }
    }

    func updateViewHidden(_ isHidden: Bool) {
        interactionViewModel.setIsToolbarReactionHidden(isHidden)
    }

    private func stopLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

    private func sendReaction(_ key: String) {
        interactionViewModel.sendReaction(key)
    }

    private func generateImpactFeedback() {
        if Display.phone {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

extension ToolBarReactionItem: FloatingInteractionViewModelDelegate {
    func allReactionsDidChange(reactions: [Emojis]) {
        let showingReactions = self.reactions.map {
            let skinedKey = interactionViewModel.selectedSkinKey(for: $0) ?? ""
            return skinedKey.isEmpty ? $0 : skinedKey
        }
        if self.showingReactions != showingReactions {
            self.showingReactions = showingReactions
            notifyListeners()
        }
    }
}

extension ToolBarReactionItem: ReactionViewDelegate {
    func reactionView(_ view: ReactionView, didClickReaction reactionKey: String) {
        if interactionViewModel.isReactionPanelExpanded {
            interactionViewModel.hideReactionPanel()
            return
        }
        MeetingTracksV2.trackClickSendReaction(reactionKey, location: "toolbar", isRecent: false, isChangeSkin: interactionViewModel.isChangeSkin(reactionKey))
        sendReaction(reactionKey)
        generateImpactFeedback()
        interactionViewModel.updateRecentEmoji()
    }

    func reactionView(_ view: ReactionView, didBeginLongPress recognizer: UILongPressGestureRecognizer, with reactionKey: String) {
        if recognizer.state == .began {
            interactionViewModel.hideReactionPanel()
            blockFullScreenToken = fullScreenDetector?.requestBlockAutoFullScreen()
            stopLongPressTimer()
            // 因为长按手势的识别时延，响应时我们就设置 count 从 2 起，下面也会调用两次发送表情接口
            sendReaction(reactionKey)
            sendReaction(reactionKey)
            comboCount = 2
            longPressTimer = Timer.scheduledTimer(withTimeInterval: Self.pressTriggleTime, repeats: true, block: { [weak self] _ in
                guard let self = self else { return }
                self.sendReaction(reactionKey)
                MeetingTracksV2.trackClickSendReaction(reactionKey, location: "toolbar", isRecent: false, isChangeSkin: self.interactionViewModel.isChangeSkin(reactionKey))
                self.comboCount += 1
                self.generateImpactFeedback()
            })
        } else if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
            blockFullScreenToken = nil
            interactionViewModel.updateRecentEmoji()
            ChatTracks.trackReaction(key: reactionKey, comboCount: comboCount)
            stopLongPressTimer()
        }
    }
}

extension ToolBarReactionItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        Util.runInMainThread {
            if key == .allowSendReaction {
                self.allowSendReaction = isOn
            }
        }
    }
}
