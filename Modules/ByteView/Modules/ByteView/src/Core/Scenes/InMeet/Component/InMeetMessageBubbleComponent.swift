//
//  InMeetMessageBubbleComponent.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/11/6.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewNetwork

/// 显示聊天气泡的一段区域，依当前横竖屏、是否是沉浸态等不同而不同
///     - 提供 LayoutGuide: messageBubble
final class InMeetMessageBubbleComponent: InMeetViewComponent {
    let componentIdentifier: InMeetViewComponentIdentifier = .messageBubble
    private weak var container: InMeetViewContainer?
    let bubbleContainerView: BubbleContainerView
    private let containerView: UIView
    private let chatViewModel: ChatMessageViewModel
    private let imChatViewModel: IMChatViewModel
    private let toolbarViewModel: ToolBarViewModel

    private let meeting: InMeetMeeting
    private var flowGuideToken: MeetingLayoutGuideToken?

    private let messageBubbleGuide = UILayoutGuide()
    // 适配 iPad 键盘最小化时聊天输入框、表情气泡与键盘之间的约束
    private var isShowingFullKeyboard = false {
        didSet {
            if oldValue != isShowingFullKeyboard {
                updateMessageBubbleGuide()
            }
        }
    }

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        #if DEBUG
        messageBubbleGuide.identifier = "messageBubbleGuide"
        #endif
        container.view.addLayoutGuide(messageBubbleGuide)
        self.bubbleContainerView = BubbleContainerView(isUseImChat: viewModel.setting.isUseImChat, emotion: viewModel.service.emotion)
        self.container = container
        self.meeting = viewModel.meeting
        self.containerView = container.loadContentViewIfNeeded(for: .messageBubble)
        self.chatViewModel = viewModel.resolver.resolve()!
        self.imChatViewModel = viewModel.resolver.resolve()!
        self.toolbarViewModel = viewModel.resolver.resolve()!
        self.bubbleContainerView.chatView.delegate = self
        self.chatViewModel.addListener(self)
        self.imChatViewModel.addListener(self)
        self.imChatViewModel.delegate = self
        self.imChatViewModel.currentLayoutType = layoutContext.layoutType
        meeting.push.translateResults.addObserver(self)
        viewModel.viewContext.addListener(self, for: [.hideMessageBubble, .hideReactionBubble] )
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
    }

    func setupConstraints(container: InMeetViewContainer) {
        flowGuideToken = container.layoutContainer.requestLayoutGuide { anchor, ctx in
            InMeetOrderedLayoutGuideQuery(topAnchor: .topSafeArea,
                                          bottomAnchor: .reactionButton,
                                          specificInsets: [.reactionButton: 4])
            .verticalRelationWithAnchor(anchor, context: ctx)
        } horizontal: { anchor, ctx in
            var leftAnchor: InMeetLayoutAnchor = .leftSafeArea
            var leftInset: CGFloat = 0.0
            if Display.phone && ctx.isLandscapeOrientation {
                if Display.iPhoneXSeries {
                    let isTopOnLeft = ctx.interfaceOrientation == .landscapeRight
                    if isTopOnLeft {
                        leftInset = -7
                    } else {
                        leftAnchor = .left
                    }
                } else {
                    leftAnchor = .left
                    leftInset = 9
                }
            }
            let query = InMeetOrderedLayoutGuideQuery(leftAnchor: leftAnchor,
                                                      specificInsets: [leftAnchor: leftInset])
            return query.horizontalRelationWithAnchor(anchor, context: ctx)
        }

        containerView.addSubview(bubbleContainerView)
        updateMessageBubbleGuide()
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        imChatViewModel.currentLayoutType = newContext.layoutType
        if newContext.layoutChangeReason.isOrientationChanged || newContext.layoutChangeReason == .refresh {
            if Display.phone {
                updateMessageBubbleGuide()
            }
            bubbleContainerView.hideChat()
            bubbleContainerView.updateUIStyle()
        } else if oldContext.layoutType != newContext.layoutType {
            updateMessageBubbleGuide()
        }
    }

    func updateMessageBubbleGuide() {
        guard let token = flowGuideToken, let container = container else { return }
        let layoutGuide = token.layoutGuide
        bubbleContainerView.snp.remakeConstraints { make in
            make.top.left.equalTo(layoutGuide)
            if isShowingFullKeyboard {
                make.bottom.lessThanOrEqualTo(container.chatInputKeyboardGuide).inset(7)
                make.bottom.equalTo(layoutGuide).priority(.high)
            } else {
                make.bottom.equalTo(layoutGuide)
            }
            if Display.pad {
                make.width.equalTo(container.contentGuide).multipliedBy(containerView.isRegular ? 0.25 : 0.4)
            } else {
                make.width.equalTo(container.contentGuide).multipliedBy(containerView.isPhonePortrait ? 0.66 : 0.5)
            }
        }
    }

    private func processNewMessage(_ message: ChatMessageCellModel) {
        if chatViewModel.isChatMessageViewShowing {
            return
        }
        if chatViewModel.translateService.isVCAutoTranslationOn && message.model.deviceID != chatViewModel.meeting.account.deviceId {
            chatViewModel.translateService.detectAutoTranslateMessage(messageId: message.id, displayArea: .popup)
        } else {
            showChatMessage(message: message, content: message.model.content)
        }
    }

    private func showChatMessage(message: ChatMessageCellModel, content: MessageRichText) {
        guard !chatViewModel.context.isHiddenMessageBubble, let avatar = message.avatar else { return }
        let attributedText = chatViewModel.getChatAttributeText(with: content)
        let item = ChatItem(name: message.displayName, avatar: avatar, content: attributedText, position: message.position)
        bubbleContainerView.addChat(with: item)
    }

    // MARK: - Notifications

    @objc
    private func handleKeyboardShow(_ notification: Notification) {
        guard let info = notification.userInfo, let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        // 100: magic number，按照日志里打印的收起状态键盘高度应该是 69，这里随便使用了一个数字
        isShowingFullKeyboard = endFrame.height > 100
    }

    @objc
    private func handleKeyboardHide(_ notification: Notification) {
        isShowingFullKeyboard = false
    }
}

extension InMeetMessageBubbleComponent: ChatMessageViewModelDelegate {
    func didReceiveNewUnreadMessage(_ unreadMessage: ChatMessageCellModel) {
        processNewMessage(unreadMessage)
    }

    func didSendMessage(_ message: ChatMessageCellModel) {
        if imChatViewModel.chatAction == .inMeetingChatDisable { return }
        processNewMessage(message)
    }

    func chatMessageViewShowingDidChange(isShowing: Bool) {
        if isShowing {
            bubbleContainerView.hideChat()
        }
    }
}

extension InMeetMessageBubbleComponent: IMChatViewModelDelegate {

    func didReceiveMessagePreview(with item: ChatItem) {
        guard !chatViewModel.context.isHiddenMessageBubble else { return }
        bubbleContainerView.addChat(with: item)
    }

    func isMessageBubbleShow() -> Bool {
        return bubbleContainerView.isMessageBubbleShow
    }
}

extension InMeetMessageBubbleComponent: TranslateResultsPushObserver {
    func didReceiveTranslateResults(_ infos: [TranslateInfo]) {
        guard let info = infos.last, let message = chatViewModel.message(for: info.messageID), info.displayArea == .popup else { return }
        let content: MessageRichText
        if info.errCode != .unknown || info.displayRule == .noTranslation || info.textContent == nil {
            content = message.model.content
        } else {
            // 只有翻译无错误并且应该展示译文时才从 info 中取内容，否则从 message.model 中取原文
            // 上面已经判断了 textContent 为空的情况
            content = info.textContent!.content
        }
        Util.runInMainThread { [weak self] in
            self?.showChatMessage(message: message, content: content)
        }
    }
}

extension InMeetMessageBubbleComponent: ChatMessageBubbleViewDelegate {
    func messageBubbleViewDidClick(item: ChatItem) {
        if meeting.setting.isUseImChat {
            imChatViewModel.goToChat(from: .bubble, position: Int32(item.position))
            bubbleContainerView.hideChat()
            VCTracker.post(name: .vc_meeting_chat_pop_click, params: [.click: "open", .target: "im_chat_main_view"])
        } else {
            toolbarViewModel.shrinkToolBar(completion: {})
            chatViewModel.defaultAutoScrollPosition = item.position
            let controller = ChatMessageViewController(viewModel: chatViewModel)
            controller.fromSource = "onthecall_message_show"
            meeting.router.presentDynamicModal(controller,
                                              regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                              compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
            VCTracker.post(name: .vc_meeting_chat_send_message_click,
                           params: [.click: "onthecall_message_show",
                                    "target": "vc_meeting_chat_send_message_view"])
        }
    }
}

extension InMeetMessageBubbleComponent: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .hideReactionBubble:
            bubbleContainerView.hideOtherUserReaction(currentUserId: meeting.userId)
        case .hideMessageBubble:
            bubbleContainerView.hideChat()
        default:
            break
        }
    }
}
