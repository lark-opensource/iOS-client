//
//  ChatMessageViewModel.swift
//  ByteView
//
//  Created by wulv on 2020/12/14.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import Action
import RxSwift
import RxRelay
import RxCocoa
import ByteViewNetwork
import ByteViewSetting

final class ChatMessageViewModel: InMeetMeetingProvider {
    static let logger = Logger.chatMessage

    enum LoadDirection {
        case up
        case down

        var isPrevious: Bool {
            switch self {
            case .up:
                return true
            case .down:
                return false
            }
        }
    }

    // MARK: - Input

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    let isCalendarMeeting: Bool
    var messagesStore: ChatMessageStore
    let listeners = Listeners<ChatMessageViewModelDelegate>()

    let disposeBag = DisposeBag()
    var defaultAutoScrollPosition: Int?
    var lastNonsequenceItem: [NonsequenceItem: Int] = [:] // 前次请求次数
    var isNonsequenceRequesting: Bool = false
    var updatePlaceholderClosure: ((String, Bool) -> Void)?

    var historyEnable: Bool { meeting.setting.isChatHistoryEnabled }
    var profileEnable: Bool { meeting.setting.isBrowseUserProfileEnabled }
    private(set) var topic: String = ""

    lazy var translateService: VCTranslateService = {
        let service = VCTranslateService(meeting: meeting)
        service.delegate = self
        return service
    }()

    // MARK: - Output

    // 消息页是否正在展示
    var isChatMessageViewShowing = false {
        didSet {
            Util.runInMainThread {
                self.listeners.forEach { $0.chatMessageViewShowingDidChange(isShowing: self.isChatMessageViewShowing) }
            }
        }
    }

    let unreadCountRelay = BehaviorRelay<Int>(value: 0)
    var unreadCountObservable: Observable<Int> {
        unreadCountRelay.asObservable()
    }

    let frontLoadingRelay = BehaviorRelay<Bool>(value: false)
    var frontLoadingDriver: Driver<Bool> {
        frontLoadingRelay.asDriver(onErrorJustReturn: false)
    }

    let backLoadingRelay = BehaviorRelay<Bool>(value: false)
    var backLoadingDriver: Driver<Bool> {
        backLoadingRelay.asDriver(onErrorJustReturn: false)
    }

    lazy private(set) var willDisplayCellObserver: AnyObserver<IndexPath> = {
        AnyObserver<IndexPath> { [weak self] event in
            guard let self = self else { return }
            if case let .next(indexPath) = event, let message = self.messagesStore.message(at: indexPath.row) {
                self.detectAutoTranslate(message)
            }
        }
    }()

    lazy private(set) var triggerLoadMoreObserver: AnyObserver<LoadDirection> = {
        AnyObserver<LoadDirection> { [weak self] event in
            guard let self = self, case let .next(direction) = event else { return }
            let isLoading = direction == .up ? self.frontLoadingRelay : self.backLoadingRelay
            if isLoading.value {
                return
            }

            self.loadMoreMessages(direction: direction, onSubscribe: {
                isLoading.accept(true)
            }, afterNext: { _ in
                isLoading.accept(false)
            })
        }
    }()

    /// (是否成功，翻译内容，翻译语言)
    let triggerTranslatioinContentRelay = PublishRelay<(Bool, [String], String)>()

    // MARK: - Initialize

    init(meeting: InMeetMeeting, context: InMeetViewContext) {
        self.meeting = meeting
        self.context = context
        self.isCalendarMeeting = meeting.isCalendarMeeting
        self.messagesStore = ChatMessageStore(storage: meeting.storage, meetingID: meeting.meetingId)
        bindNotifications()
        meeting.push.chatMessage.addObserver(self)
        self.messagesStore.delegate = self
        meeting.data.addListener(self)
        meeting.setting.addListener(self, for: [.allowSendMessage])
        meeting.webinarManager?.addListener(self, fireImmediately: false)
        DispatchQueue.global().async { [weak self] in
            self?.pullLatestMessage()
        }
    }

    // MARK: - Public

    var meetingID: String {
        meeting.meetingId
    }

    var messageSortRule: (ChatMessageCellModel, ChatMessageCellModel) -> Bool {
        return { (lhs, rhs) -> Bool in
            return lhs.position < rhs.position
        }
    }

    var positionForLastMessage: Int? { messagesStore.lastPosition }

    var numberOfMessages: Int { messagesStore.numberOfMessages }

    var unreadMessage: ChatMessageCellModel? { messagesStore.unreadMessage }

    var isFrozen: Bool { messagesStore.isFrozen }

    var autoScrollPosition: Int? {
        if let position = defaultAutoScrollPosition {
            return position
        } else if !messagesStore.messagesAllUnread {
            return messagesStore.currentScanningPosition
        } else {
            return nil
        }
    }

    var allowSendMessage: Bool {
        meeting.setting.allowSendMessage
    }

    func messageIndex(for position: Int) -> Int? {
        messagesStore.messageIndex(for: position)
    }

    func message(at index: Int) -> ChatMessageCellModel? {
        messagesStore.message(at: index)
    }

    func message(for id: String) -> ChatMessageCellModel? {
        messagesStore.message(for: id)
    }

    func isScanningLastMessage(currentIndexPath indexPath: IndexPath?) -> Bool {
        guard let index = indexPath?.row else { return true }
        // 这里控制的是滚动按钮的显示隐藏逻辑，因此判断的是新消息到来之后，是否仍然是浏览最后一行，所以是 -1
        return index >= (messagesStore.numberOfMessages + messagesStore.numberOfFrozenMessages) - 1
    }

    /// 基于当前用户浏览的位置，是否在新消息到来时需要自动滚动
    func shouldAutoScrollToBottom(scanningIndexPath indexPath: IndexPath?) -> Bool {
        guard let index = indexPath?.row else { return false }
        // 由于先数据更新后UI更新，此时新消息已经被添加到数据源，因此这里实际上判断的是“新消息到来之前是否在浏览最后一行”，所以是 -2
        return index >= messagesStore.numberOfMessages - 2
    }

    func reset() {
        defaultAutoScrollPosition = nil
        lastNonsequenceItem = [:]
        isNonsequenceRequesting = false
        isChatMessageViewShowing = false

        frontLoadingRelay.accept(false)
        backLoadingRelay.accept(false)

        messagesStore = ChatMessageStore(storage: meeting.storage, meetingID: meeting.data.meetingIdForRequest, delegate: self)
        translateService.clearAll()
        unfreezeMessages()

        pullLatestMessage()
    }

    func recordUnSendText(_ text: String) {
        context.chatRecordText = text.trimmingCharacters(in: .whitespaces)
    }

    func updateReadMessage(for indexPath: IndexPath) {
        messagesStore.updateReadMessage(at: indexPath)
    }

    func freezeMessages() {
        messagesStore.freezeMessages()
    }

    func unfreezeMessages() {
        messagesStore.unfreezeMessages()
    }

    func addListener(_ listener: ChatMessageViewModelDelegate) {
        listeners.addListener(listener)
    }

    // MARK: - Actions

    lazy private(set) var closeAction: CocoaAction = {
        return Action(workFactory: { [weak self] _ in
            self?.meeting.router.dismissTopMost()
            return .empty()
        })
    }()

    lazy private(set) var openLinkAction: Action<URL, Void> = {
        return Action(workFactory: { [weak self] url in
            guard let httpUrl = Self.toHttpUrl(url) else { return .empty() }
            self?.meeting.router.dismissTopMost(animated: false) {
                self?.meeting.router.setWindowFloating(true)
                self?.meeting.larkRouter.push(url, context: ["from": "byteView"], forcePush: true)
            }
            return .empty()
        })
    }()

    lazy private(set) var openProfileAction: Action<String, Void> = {
        return Action(workFactory: { [weak self] userId in
            self?.meeting.router.dismissTopMost(animated: false) { [weak self] in
                if let meeting = self?.meeting {
                    InMeetUserProfileAction.show(userId: userId, meeting: meeting)
                }
            }
            return .empty()
        })
    }()

    // MARK: - Private

    private func bindNotifications() {
        NotificationCenter.default.rx
            .notification(ChatMessageViewController.viewAppearNotification)
            .map { $0.userInfo?[ChatMessageViewController.viewAppearKey] as? Bool ?? false }
            .subscribe(onNext: { [weak self] in
                self?.isChatMessageViewShowing = $0
            })
            .disposed(by: disposeBag)
    }

    /// 如果不知道scheme或者scheme不合规范，则转换成http(s)协议url。
    private static func toHttpUrl(_ url: URL) -> URL? {
        let newUrl = url.absoluteString
        /// scheme not nil
        if let scheme = url.scheme {
            if scheme.isEmpty {
                return URL(string: "http\(newUrl)")
            }
            let ipv4Regex = try? NSRegularExpression(
                pattern: #"^((\d|([1-9]\d)|(1\d\d)|(2[0-4]\d)|(25[0-5]))\.){3}(\d|([1-9]\d)|(1\d\d)|(2[0-4]\d)|(25[0-5]))$"#,
                options: NSRegularExpression.Options.caseInsensitive
            )
            if let ipv4Regex = ipv4Regex, !ipv4Regex.matches(scheme).isEmpty {
                return URL(string: "http://\(newUrl)")
            }
            return url
        }

        let emailRegex = try? NSRegularExpression(
            pattern: "^[+a-zA-Z0-9_.!#$%&'*\\/=?^`{|}~-]+@([a-zA-Z0-9-]+\\.)+[a-zA-Z0-9]{2,63}$",
            options: NSRegularExpression.Options.caseInsensitive
        )
        /// scheme nil
        if let emailRegex = emailRegex {
            var matchUrl = newUrl
            matchUrl = emailRegex.stringByReplacingMatches(
                in: newUrl,
                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                range: NSRange(location: 0, length: newUrl.count),
                withTemplate: "mailto:\(newUrl)"
            )
            if newUrl != matchUrl {
                return URL(string: matchUrl)
            }
        }
        if newUrl.starts(with: "//") {
            return URL(string: "http:\(newUrl)")
        }
        if newUrl.starts(with: "/") {
            return URL(string: "http:/\(newUrl)")
        }
        return URL(string: "http://\(newUrl)")
    }

    func getChatAttributeText(with content: MessageRichText) -> NSAttributedString {
        let mutableAttributedString = self.service.messenger.richTextToString(content)
        let attrStr = self.service.emotion.parseEmotion(mutableAttributedString)
        let mutableStr = NSMutableAttributedString(attributedString: attrStr)
        mutableStr.addAttributes(IMChatViewModel.Cons.attributes, range: NSRange(location: 0, length: attrStr.length))
        return mutableStr
    }
}

extension ChatMessageViewModel: WebinarRoleListener {
    func webinarDidChangeRehearsal(isRehearsing: Bool, oldValue: Bool?) {
        if let oldValue = oldValue,
           oldValue && !isRehearsing {
            DispatchQueue.main.async {
                // 彩排结束时，拉一下最新消息，刷新未读消息计数
                self.pullLatestMessage()
            }
        }
    }
}

extension ChatMessageViewModel: InMeetDataListener {
    func didChangeCalenderInfo(_ calendarInfo: CalendarInfo?, oldValue: CalendarInfo?) {
        if isCalendarMeeting {
            let topic = meetingTopicByCalendarInfo(calendarInfo)
            if self.topic != topic {
                self.topic = topic
                updatePlaceholderClosure?(allowSendMessage ? topic : I18n.View_G_BanAllFromMessage, allowSendMessage)
            }
        }
    }

    func didChangeInMeetingInfo(_ info: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if !isCalendarMeeting, !info.meetingSettings.topic.isEmpty {
            let title = meeting.data.roleStrategy.displayTopic(topic: info.meetingSettings.topic)
            let topic = I18n.View_G_MessageMeetingTitle(title)
            if self.topic != topic {
                self.topic = topic
                updatePlaceholderClosure?(allowSendMessage ? topic : I18n.View_G_BanAllFromMessage, allowSendMessage)
            }
        }
    }

    private func meetingTopicByCalendarInfo(_ info: CalendarInfo?) -> String {
        guard let info = info else { return "" }
        if info.topic.isEmpty {
            if let topic = self.meeting.data.inMeetingInfo?.meetingSettings.topic, !topic.isEmpty {
                return self.meeting.data.roleStrategy.displayTopic(topic: topic)
            }
            return I18n.View_G_ServerNoTitle
        }
        return I18n.View_G_MessageMeetingTitle(info.topic)
    }
}

extension ChatMessageViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        switch key {
        case .allowSendMessage:
            let banText = meeting.subType == .webinar ? I18n.View_G_MessageBanned : I18n.View_G_BanAllFromMessage
            updatePlaceholderClosure?(isOn ? topic : banText, isOn)
        default:
            break
        }
    }
}
