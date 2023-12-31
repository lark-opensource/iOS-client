//
//  BubbleContainerView.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/4/27.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewNetwork

class BubbleContainerView: UIView {
    private static let logger = Logger.ui
    var chatView: ChatMessageBubbleView
    private var reactionItems: [ReactionItem] = []
    private var reactionContainerView = UIView()

    lazy var chatContentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.clipsToBounds = true
        return v
    }()

    ///  防止超长名字的表情被截断
    lazy var reactionContentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private static let animationDuration: TimeInterval = 0.3
    private static let chatDuration: TimeInterval = 6
    private var bubbleOffset: CGFloat = 4
    private var reactionHeight: CGFloat { (40 + 4) * reactionCount }

    private var reactionCount: CGFloat = 6
    private var chatCount: Int { isPhoneLandscape && isKeyboardShow ? 2 : 3 }
    private var messageOffset: CGFloat = 0
    private let isUseImChat: Bool
    private var isKeyboardShow: Bool = false

    private var chatItems: [ChatItem] = []
    @RwAtomic
    private var showingChatViews: [ChatMessageBubbleView] = []
    private var reusableChatViews: [ChatMessageBubbleView] = []


    var isMessageBubbleShow: Bool { !showingChatViews.isEmpty }
    private let emotion: EmotionDependency

    private var chatContentHeight: CGFloat = 0

    init(isUseImChat: Bool, emotion: EmotionDependency) {
        self.emotion = emotion
        self.isUseImChat = isUseImChat
        chatView = ChatMessageBubbleView(isUseImChat: isUseImChat)
        super.init(frame: .zero)
        setupSubviews()
        addKeyboardObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 由于超出边界而消失的 reaction 是真的从视图层级上移除，且不会存在于 reactionItems 内
        let copied = reactionItems
        reactionItems = []
        for item in copied {
            let view = item.view
            if view.frame.minY < 0 {
                view.removeFromSuperview()
            } else {
                reactionItems.append(item)
            }
        }

        let oldH = chatContentHeight
        let newH = chatContentView.bounds.height
        chatContentHeight = newH
        if oldH != 0, oldH != newH {
            let delta = newH - oldH
            updateBubbleLayout(with: delta)
        }
        chatView.updateContentWidth(bounds.width - 7)
    }

    func addChat(with item: ChatItem) {
        Util.runInMainThread {
            self.chatItems.append(item)
            self.showChatInOrder()
        }
    }

    func hideChat() {
        showingChatViews.forEach { [weak self] chat in
            chat.removeFromSuperview()
            self?.reusableChatViews.append(chat)
        }
        showingChatViews = []
        chatItems = []
        messageOffset = 0
        chatContentView.bounds.origin.y = 0
        reactionContentView.bounds.origin.y = 0
        DispatchQueue.main.async {
            self.updateReactionContainerFrame()
        }
    }

    func updateUIStyle() {
        updateChatLayout()
        reusableChatViews.forEach { bubble in
            bubble.updateStyle()
        }
        chatView.updateStyle()
    }

    func addReaction(userID: String, sender: String, avatar: AvatarInfo, reactionKey: String, count: Int, duration: TimeInterval) {
        if let existed = reactionItems.first(where: { $0.userID == userID && $0.reactionKey == reactionKey }) {
            // 1. 如果是同一个用户发的同一个表情（连发），直接更新该表情的 count
            existed.view.update(senderName: sender, avatar: avatar, reactionKey: reactionKey, count: count)
            existed.showTime = Date().timeIntervalSince1970
            autohideReaction(existed, duration: duration)
            return
        } else if let hiddenReaction = reactionItems.first(where: { $0.isHidden }) {
            // 2. 如果当前页面上有可以复用的表情，拿来复用
            hiddenReaction.reuse(for: userID, reactionKey: reactionKey)
            hiddenReaction.view.isHidden = false
            hiddenReaction.view.update(senderName: sender, avatar: avatar, reactionKey: reactionKey, count: count)
            hiddenReaction.showTime = Date().timeIntervalSince1970
            showReaction(hiddenReaction, duration: duration)
            return
        }

        // 3. 不存在可复用的表情，尝试创建新表情。此时如果剩余可用空间不够，会在 layoutSubviews 中进行清理
        let reactionView = BubbleReactionView(emotion: self.emotion)
        reactionView.update(senderName: sender, avatar: avatar, reactionKey: reactionKey, count: count)
        reactionContainerView.addSubview(reactionView)
        reactionView.snp.makeConstraints { make in
            // 适配 iPad mini 上的超宽表情：将右边距扩展到整个屏幕右侧
            if let grandparentView = superview {
                make.right.lessThanOrEqualTo(grandparentView).inset(7)
            } else {
                make.right.lessThanOrEqualToSuperview()
            }
            if let last = reactionItems.last?.view {
                make.left.equalTo(last)
                make.bottom.equalTo(last.snp.top).offset(-bubbleOffset)
            } else {
                make.left.bottom.equalToSuperview()
            }
        }

        let reactionItem = ReactionItem(userID: userID, reactionKey: reactionKey, reactionView: reactionView)
        reactionItems.append(reactionItem)

        showReaction(reactionItem, duration: duration)

        // reactionView 被添加后，首先调用 reactionContainerView.layoutIfNeeded() 让其根据 autoLayout 计算好各子视图的位置
        // 然后调用 self.setNeedsLayout，触发自己的 layoutSubviews 方法里的过滤逻辑
        reactionContainerView.layoutIfNeeded()
        setNeedsLayout()
    }

    func hideOtherUserReaction(currentUserId: String) {
        reactionItems.forEach { reactionItem in
            if reactionItem.userID != currentUserId {
                let reactionView = reactionItem.view
                self.animateOutReaction(reactionView, completion: {
                    // 消失的表情并非真的从视图层级中移除，而只是隐藏，因为中间的位置要空出来，准备为后面的新表情所使用
                    reactionView.isHidden = true
                    if let index = self.reactionItems.firstIndex(of: reactionItem) {
                        self.reactionItems[index].prepareForReuse()
                    }
                })
            }
        }
    }

    // MARK: - Private

    private func setupSubviews() {
        addSubview(chatContentView)
        chatContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(reactionContentView)
        reactionContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        reactionContentView.addSubview(reactionContainerView)

        addSubview(chatView)
        chatView.isHidden = true
        updateUIStyle()
        DispatchQueue.main.async {
            self.updateReactionContainerFrame()
        }
    }

    private func updateChatLayout() {
        chatView.snp.remakeConstraints { make in
            make.left.equalTo(7)
            make.top.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
    }

    private func updateReactionContainerFrame() {
        let y: CGFloat
        if let first = showingChatViews.first {
            y = first.frame.minY - reactionHeight - bubbleOffset
        } else {
            let offset = messageOffset == 0 ? 0 : bubbleOffset
            y = chatContentView.bounds.height + messageOffset - reactionHeight - offset
        }
        reactionContainerView.frame = CGRect(x: 7, y: y, width: bounds.width - 7, height: reactionHeight)
    }

    private func updateBubbleLayout(with delta: CGFloat) {
        showingChatViews.forEach { bubble in
            bubble.frame.origin.y += delta
        }
        updateReactionContainerFrame()
    }

    private func dismissChat(_ chat: ChatMessageBubbleView) {
        UIView.animate(withDuration: Self.animationDuration, delay: 0) {
            chat.alpha = 0
            self.updateReactionContainerFrame()
        } completion: { _ in
            chat.removeFromSuperview()
            chat.prepareForReuse()
            self.reusableChatViews.append(chat)
        }
    }

    private func dismissChatLaterIfNeeded(_ chat: ChatMessageBubbleView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.chatDuration, execute: DispatchWorkItem(block: {
            if self.showingChatViews.first == chat {
                self.showingChatViews.removeFirst()
                self.dismissChat(chat)
            }
        }))
    }

    private func dismissFirstChatIfNeeded() {
        if showingChatViews.count > chatCount - 1 {
            dismissChat(showingChatViews.removeFirst())
        }
    }

    private func showChatInOrder() {
        if showingChatViews.count > chatCount - 1 { return }
        showChat()
    }

    private func showChat() {
        if chatItems.isEmpty { return }
        let item = chatItems.removeFirst()
        chatView.update(with: item)
        chatView.layoutIfNeeded()
        let size = chatView.bounds.size
        chatView.prepareForReuse()
        let bubble = reusableChatViews.popLast() ?? {
            let chat = ChatMessageBubbleView(isUseImChat: isUseImChat)
            chat.delegate = chatView.delegate
            chat.updateStyle()
            return chat
        }()
        let y = chatContentView.bounds.height + messageOffset
        messageOffset += size.height + 4
        bubble.frame = CGRect(x: 7, y: y, width: size.width, height: size.height)
        bubble.alpha = 1
        bubble.update(with: item)
        chatContentView.addSubview(bubble)
        showingChatViews.append(bubble)
        UIView.animate(withDuration: Self.animationDuration, delay: 0) {
            self.chatContentView.bounds.origin.y = self.messageOffset - 4
            self.reactionContentView.bounds.origin.y = self.messageOffset - 4
            self.updateReactionContainerFrame()
        } completion: { _ in
            self.showChat()
        }
        if showingChatViews.count == chatCount {
            dismissChat(showingChatViews.removeFirst())
        }
        dismissChatLaterIfNeeded(bubble)
    }

    private func showReaction(_ reactionItem: ReactionItem, duration: TimeInterval) {
        animateInReaction(reactionItem.view)
        autohideReaction(reactionItem, duration: duration)
    }

    private func autohideReaction(_ reactionItem: ReactionItem, duration: TimeInterval) {
        let reactionView = reactionItem.view
        let originalShowTime = reactionItem.showTime
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard originalShowTime == reactionItem.showTime else { return }
            self.animateOutReaction(reactionView, completion: {
                // 因为时间到了而消失的表情并非真的从视图层级中移除，而只是隐藏，因为中间的位置要空出来，准备为后面的新表情所使用
                reactionView.isHidden = true
                if let index = self.reactionItems.firstIndex(of: reactionItem) {
                    self.reactionItems[index].prepareForReuse()
                }
            })
        }
    }

    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide),
                                               name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    @objc
    private func keyboardWillShow() {
        isKeyboardShow = true
        dismissFirstChatIfNeeded()
    }

    @objc
    private func keyboardDidHide() {
        isKeyboardShow = false
    }

    private func animateInReaction(_ reactionView: BubbleReactionView) {
        reactionView.layoutIfNeeded()
        reactionView.transform = CGAffineTransform(translationX: -reactionView.frame.width, y: 0)
        UIView.animate(withDuration: Self.animationDuration, animations: {
            reactionView.transform = .identity
        })
    }

    private func animateOutReaction(_ reactionView: BubbleReactionView, completion: @escaping (() -> Void)) {
        UIView.animate(withDuration: Self.animationDuration, animations: {
            reactionView.transform = CGAffineTransform(translationX: 0, y: -reactionView.frame.height)
            reactionView.alpha = 0
        }, completion: { _ in
            reactionView.transform = .identity
            reactionView.alpha = 1
            completion()
        })
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let converted = convert(point, to: chatContentView)
        for bubble in showingChatViews {
            if bubble.frame.contains(converted) {
                let newPoint = chatContentView.convert(converted, to: bubble)
                return bubble.hitTest(newPoint, with: event)
            }
        }
        return nil
    }
}

private class ReactionItem: Equatable {
    var userID: String
    var reactionKey: String
    let view: BubbleReactionView
    var showTime: TimeInterval
    var isHidden = false

    init(userID: String, reactionKey: String, reactionView: BubbleReactionView) {
        self.userID = userID
        self.reactionKey = reactionKey
        self.showTime = Date().timeIntervalSince1970
        self.view = reactionView
    }

    func prepareForReuse() {
        isHidden = true
        userID = ""
        reactionKey = ""
    }

    func reuse(for userID: String, reactionKey: String) {
        isHidden = false
        self.userID = userID
        self.reactionKey = reactionKey
    }

    static func == (lhs: ReactionItem, rhs: ReactionItem) -> Bool {
        return lhs.userID == rhs.userID && lhs.reactionKey == rhs.reactionKey
    }
}
