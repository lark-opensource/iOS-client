//
//  IMChatViewModel.swift
//  ByteView
//
//  Created by 陈乐辉 on 2022/11/7.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI

protocol IMChatViewModelDelegate: AnyObject {

    func didReceiveMessagePreview(with item: ChatItem)

    func messageUnreadNumberDidUpdate(num: Int)

    func isMessageBubbleShow() -> Bool
}

extension IMChatViewModelDelegate {

    func didReceiveMessagePreview(with item: ChatItem) {}

    func messageUnreadNumberDidUpdate(num: Int) {}

    func isMessageBubbleShow() -> Bool {
        return false
    }
}

final class IMChatViewModel: InMeetMeetingProvider {

    static let logger = Logger.imChat

    let meeting: InMeetMeeting
    let context: InMeetViewContext

    @RwAtomic
    var groupId: String = "" {
        didSet {
            meeting.setChatId(groupId)
        }
    }
    @RwAtomic
    var lastMessagePosition: Int32 = 0
    @RwAtomic
    var foldId: Int64 = 0
    @RwAtomic
    var lastDigest: Digest = Digest()

    var isPhoneChatShow: Bool = false
    var isCreatingGroup: Bool = false

    let listeners = Listeners<IMChatViewModelDelegate>()
    weak var delegate: IMChatViewModelDelegate?

    weak var from: UIViewController?
    var viewControllerCount: Int = 1

    var sceneInfo: SceneInfo {
        return SceneInfo(key: .chat, id: groupId)
    }

    var httpClient: HttpClient { meeting.httpClient }
    var createGroupDuration: CFTimeInterval = 0
    var enterChatDuration: CFTimeInterval = 0
    var timestamp: CFTimeInterval = CACurrentMediaTime()
    var currentLayoutType: LayoutType = Display.pad ? .regular : .compact

    var unreadCount: Int = 0

    private weak var oldChatWindow: UIWindow?
    private weak var chatWindow: UIWindow?

    @RwAtomic
    var chatAction: VCManageResult.Action?

    init(meeting: InMeetMeeting, context: InMeetViewContext) {
        self.meeting = meeting
        self.context = context
        self.groupId = meeting.setting.bindChatId
        self.getChatLastPositionIfNeeded()
        meeting.router.addListener(self)
        meeting.push.combinedInfo.addObserver(self)
        meeting.push.vcManageResult.addObserver(self)
        meeting.addListener(self)
    }

    func addListener(_ listener: IMChatViewModelDelegate) {
        listeners.addListener(listener)
    }

    func goToChat(from entrance: Entrance, position: Int32? = nil) {
        func enter() {
            let now = CACurrentMediaTime()
            createGroupDuration = (now - timestamp) * 1000
            timestamp = now

            let position: Int32? = (entrance == .bubble && lastMessagePosition > 0) ? position : nil

            if #available(iOS 13, *), VCScene.supportsMultipleScenes {
                openChatScene(with: position)
            } else {
                if Display.pad {
                    switchToChat(with: position)
                } else {
                    if currentLayoutType.isPhoneLandscape, meeting.setting.canOrientationManually {
                        UIDevice.updateDeviceOrientationForViewScene(nil, to: .portrait, animated: false)
                    }
                    openPhoneChat(with: position) { [weak self] controller, _ in
                        self?.from = controller
                        self?.isPhoneChatShow = true
                    }
                }
            }
        }

        func createGroup() {
            let toast = Toast.showLoading(I18n.View_G_LoadMeetGroup_Toast)
            creatMeetingGroup { success in
                toast?.hideLoading()
                if success {
                    enter()
                }
            }
        }

        if entrance == .toolbar {
            let isCreat = isGroupIdInvalid() ? "true" : "false"
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "chat", .target: "im_chat_main_view", "if_create_group": isCreat])
        }

        if let action = chatAction {
            if action == .inMeetingChatEnable {
                OnthecallReciableTracker.startEnterImChat()
                timestamp = CACurrentMediaTime()
                if isGroupIdInvalid() {
                    createGroup()
                } else {
                    getMessagePosition { success in
                        if success {
                            enter()
                        }
                    }
                }
                Self.logger.info("chatAction is enable")
            } else {
                Toast.show(I18n.View_G_GroupMeetingMemberOnly)
                Self.logger.info("chatAction is disable")
            }
        } else {
            OnthecallReciableTracker.startEnterImChat()
            timestamp = CACurrentMediaTime()
            createGroup()
            Self.logger.info("chatAction is nil")
        }
    }


    func getChatLastPositionIfNeeded() {
        if isGroupIdInvalid() {
            addPushObserver()
            return
        }
        httpClient.getResponse(GetChatsRequest(chatIds: [groupId])) { [weak self] result in
            switch result {
            case .success(let resp):
                let chats = resp.chats
                let lastPosition = chats.sorted {
                    $0.lastMessagePosition < $1.lastMessagePosition
                }.last?.lastMessagePosition
                if let position = lastPosition {
                    self?.lastMessagePosition = position
                    Self.logger.info("getChatsPosition: \(position)")
                }
            case .failure:
                Self.logger.info("getChatsPosition failure")
            }
            self?.addPushObserver()
        }
    }

    func createMeetingGroupIfNeeded() {
        guard meeting.setting.isUseImChat else { return }
        if chatAction == nil || isGroupIdInvalid() {
            creatMeetingGroup(success: nil)
        }
    }

    func sendText(_ text: String) {
        if isGroupIdInvalid() { return }
        self.service.messenger.sendText(text, chatId: groupId, completion: { messageId in
            if let mid = messageId {
                VCTracker.post(name: .vc_meeting_chat_success_status, params: ["type": "send_message", "location": "onthecall_fold_button", "msg_id": mid])
            }
        })
    }

    func isChatEnabled() -> Bool {
        if chatAction == .inMeetingChatDisable {
            Toast.show(I18n.View_G_GroupMeetingMemberOnly)
            return false
        } else {
            return true
        }
    }


    private func creatMeetingGroup(success: ((Bool) -> Void)?) {
        if isCreatingGroup { return }
        isCreatingGroup = true
        httpClient.getResponse(CreateMeetingGroupRequest(meetingId: meeting.meetingId)) { [weak self] res in
            switch res {
            case .success(let resp):
                let info = resp.meetingGroupInfo
                self?.groupId = info.groupId
                Self.logger.info("creatMeetingGroup success: (groupId-\(info.groupId))")
                self?.chatAction = .inMeetingChatEnable
                Util.runInMainThread {
                    success?(true)
                    self?.isCreatingGroup = false
                }
            case .failure(let error):
                Self.logger.info("creatMeetingGroup failure: \(error)")
                OnthecallReciableTracker.enterImChatError(meetingId: self?.meeting.meetingId ?? "", errorCode: error.toErrorCode() ?? 0, errorMessage: "\(error)")
                Util.runInMainThread {
                    success?(false)
                    self?.isCreatingGroup = false
                }
            }
        }
    }

    private func getMessagePosition(success: @escaping ((Bool) -> Void)) {
        httpClient.getResponse(GetMessagePositionRequest()) { res in
            switch res {
            case .success:
                Util.runInMainThread {
                    success(true)
                }
            case .failure(let error):
                Self.logger.info("getMessagePosition failure: \(error)")
                Util.runInMainThread {
                    success(false)
                    Toast.show(I18n.View_VM_ErrorTryAgain)
                }
            }
        }
    }

    private func addPushObserver() {
        guard meeting.setting.isUseImChat else { return }
        meeting.push.messagePreviews.addObserver(self) { [weak self] in
            self?.didReceiveMessagePreviews($0)
        }
    }

    private func isGroupIdInvalid() -> Bool {
        groupId.isEmpty || groupId == "0"
    }

    @available(iOS 13, *)
    private func openChatScene(with position: Int32?, completion: (() -> Void)? = nil) {
        var info = SceneInfo(key: .chat, id: groupId)
        info.windowType = "group"
        info.createWay = "button"
        if let pos = position {
            info.userInfo = ["position": String(pos)]
        }
        info.extraInfo["closeAction"] = { [weak self] in
            self?.trackCloseChat()
            Self.logger.info("Close VC chat scene")
        }
        info.extraInfo["messageRenderBlock"] = { [weak self] in
            guard let self = self else { return }
            self.endEnterChat()
            self.trackChatIsOpen(true)
        }
        info.extraInfo["messageDeinitBlock"] = { [weak self] in
            guard let self = self else { return }
            self.trackChatIsOpen(false)
        }
        router.window?.isIgnoringSetFloatingActions = true
        router.openByteViewScene(sceneInfo: info, actionCallback: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .floatingVC, .reopen, .close, .none:
            self.router.window?.isIgnoringSetFloatingActions = false
            default:
                break
            }
        }, completion: { [weak self] w, _ in
            guard let self = self else { return }
            self.chatWindow = w
            completion?()
            self.router.window?.isIgnoringSetFloatingActions = false
        })
        Self.logger.info("Open VC chat scene")
    }

    private func openPhoneChat(with position: Int32?, animated: Bool = true, completion: ((UIViewController, Int) -> Void)? = nil) {
        var body = ChatBody(chatId: groupId, position: position, showNormalBack: true, isGroup: true, switchFeedTab: false, isPresent: true, animated: animated, setFromWhere: true)
        let router = meeting.router
        body.messageCloseBlock = { [weak self] in
            guard let self = self else { return }
            router.setWindowFloating(false)
            self.trackCloseChat()
        }
        body.messageRenderBlock = { [weak self] in
            guard let self = self else { return }
            self.endEnterChat()
            self.trackChatIsOpen(true)
        }
        body.messageDeinitBlock = { [weak self] in
            guard let self = self else { return }
            self.trackChatIsOpen(false)
        }
        router.setWindowFloating(true)
        meeting.larkRouter.gotoChat(body: body, completion: completion)
        Self.logger.info("Push VC chat")
    }

    private func switchToChat(with position: Int32?) {
        let body = ChatBody(chatId: groupId, position: position, isGroup: true, switchFeedTab: true, setFromWhere: true)
        meeting.router.setWindowFloating(true)
        meeting.larkRouter.gotoChat(body: body)
        Self.logger.info("Switch to chat tab")
    }

    private func upgradeGroupIfNeeded() {
        timestamp = CACurrentMediaTime()
        if Display.pad {
            upgradePadGroup()
        } else {
            upgradePhoneGroup()
        }
    }

    private func upgradePadGroup() {
        if #available(iOS 13, *), let ws = self.oldChatWindow?.windowScene, ws.activationState == .foregroundActive {
           Toast.show(I18n.View_G_UpgradingToExGroup)
            openChatScene(with: nil) { [weak self] in
                self?.closeOldScene()
            }
        }
    }

    private func upgradePhoneGroup() {
        if isPhoneChatShow {
            Toast.show(I18n.View_G_UpgradingToExGroup)
            openPhoneChat(with: nil, animated: false)
        }
    }

    private func trackCloseChat() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "close_chat_window", .target: "vc_meeting_onthecall_view"])
    }

    private func trackChatIsOpen(_ isOpen: Bool) {
        let status = isOpen ? "open" : "close"
        VCTracker.post(name: .vc_meeting_im_status, params: ["status": status])
    }

    private func endEnterChat() {
        enterChatDuration = (CACurrentMediaTime() - timestamp) * 1000
        OnthecallReciableTracker.endEnterImChat(isGroupExist: createGroupDuration == 0, meetingId: meeting.meetingId, meetingType: getMeetingType(), networkRequest: Int(createGroupDuration), openImWindow: Int(enterChatDuration))
        createGroupDuration = 0
        enterChatDuration = 0
    }

    private func getMeetingType() -> Int {
        if meeting.subType == .webinar {
            return 3
        } else {
            return meeting.isCalendarMeeting ? 1 : 0
        }
    }

    private func closeOldScene() {
        if #available(iOS 13, *), let ws = self.oldChatWindow?.windowScene {
            VCScene.closeScene(ws)
            Logger.window.info("closing old chat scene: \(ws)")
        }
        self.oldChatWindow = nil
    }

    private func closeCurrentScene() {
        if #available(iOS 13, *), let ws = self.chatWindow?.windowScene {
            VCScene.closeScene(ws)
            Logger.window.info("closing current chat scene: \(ws)")
        }
        self.chatWindow = nil
    }
}

extension IMChatViewModel {
    func didReceiveMessagePreviews(_ previews: VCMessagePreviews) {
        chatAction = .inMeetingChatEnable
        if meeting.data.isInBreakoutRoom { return }
        if previews.previews.isEmpty { return }
        let isBubbleShow = delegate?.isMessageBubbleShow() ?? false
        let prevs = previews.previews.sorted { $0.chatData.lastMessagePosition > $1.chatData.lastMessagePosition }
        let firstChat = prevs[0].chatData
        processUnreadCount(firstChat.unreadCount)
        guard let preview = prevs.first(where: { $0.chatData.lastMessageType != .system }), preview.messageDisplay else { return }
        let chatData = preview.chatData
        if chatData.lastMessagePosition < lastMessagePosition { return }
        if chatData.lastMessageIsFold, foldId == chatData.lastMessageFoldID, lastDigest == chatData.digest { return }
        if chatData.lastMessagePosition == lastMessagePosition, (lastDigest == chatData.digest || !isBubbleShow) { return }
        lastMessagePosition = chatData.lastMessagePosition
        foldId = chatData.lastMessageFoldID
        lastDigest = chatData.digest
        processMessage(with: preview)
    }

    private func processUnreadCount(_ count: Int32) {
        Util.runInMainThread {
            self.unreadCount = Int(count)
            self.listeners.forEach {
                $0.messageUnreadNumberDidUpdate(num: Int(count))
            }
        }
    }

    private func processMessage(with preview: VCMessagePreview) {
        let attributedText = getOriginalDigest(preview.chatData.digest)
        if attributedText.length == 0 { return }
        let userData = preview.userData
        let avatar = ChatAvatarView.Content.key(userData.avatarKey, userId: userData.userID, backup: nil)
        let item = ChatItem(name: userData.name, avatar: avatar, content: attributedText, position: Int(preview.chatData.lastMessagePosition))
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if #available(iOS 13, *), let scene = self.chatWindow?.windowScene,
               scene.activationState == .foregroundActive {
                return
            }
            self.listeners.forEach {
                $0.didReceiveMessagePreview(with: item)
            }
        }
    }
}

extension IMChatViewModel: VideoChatCombinedInfoPushObserver {
    func didReceiveCombinedInfo(inMeetingInfo: ByteViewNetwork.VideoChatInMeetingInfo, calendarInfo: ByteViewNetwork.CalendarInfo?) {
        if groupId == inMeetingInfo.meetingSettings.bindChatId { return }
        self.oldChatWindow = self.chatWindow
        groupId = inMeetingInfo.meetingSettings.bindChatId
        lastMessagePosition = 0
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.upgradeGroupIfNeeded()
        }
    }
}

extension IMChatViewModel: RouterListener {
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        if let from = from, !isFloating {
            from.dismiss(animated: true)
        }
        from = nil
        if !isFloating {
            isPhoneChatShow = false
        }
    }
}

extension IMChatViewModel: InMeetMeetingListener {
    func didReleaseInMeetMeeting(_ meeting: InMeetMeeting) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.closeCurrentScene()
        }
    }
}

extension IMChatViewModel: VCManageResultPushObserver {
    func didReceiveManageResult(_ result: ByteViewNetwork.VCManageResult) {
        if result.type == .inMeetingChatChange {
            chatAction = result.action
        }
    }
}

extension IMChatViewModel {
    enum Cons {

        static let contentLineHeight: CGFloat = 18

        static let contentFont = UIFont.systemFont(ofSize: 12, weight: .medium)

        static var emojiHeight: CGFloat {
            contentFont.rowHeight - 2.auto()
        }

        static var attributes: [NSAttributedString.Key: Any] = {
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = contentLineHeight
            style.maximumLineHeight = contentLineHeight
            style.alignment = .left
            let offset = (contentLineHeight - contentFont.lineHeight) / 4.0
            return [.paragraphStyle: style,
                    .baselineOffset: offset,
                    .font: contentFont,
                    .foregroundColor: UIColor.ud.primaryOnPrimaryFill]
        }()
    }

    enum Entrance {
        case toolbar
        case bubble
    }

    struct ChatParticipantId: ParticipantIdConvertible {
        let userId: String
        var participantId: ByteViewNetwork.ParticipantId {
            return ParticipantId(id: userId, type: .larkUser)
        }
        init(userId: String) {
            self.userId = userId
        }
    }
}

struct ChatItem {
    let name: String
    let avatar: ChatAvatarView.Content
    let content: NSAttributedString
    let position: Int
}
