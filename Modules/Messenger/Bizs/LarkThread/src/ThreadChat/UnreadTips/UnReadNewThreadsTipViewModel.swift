//
//  DownUnReadThreadsTipViewModel.swift
//  LarkThread
//
//  Created by zc09v on 2019/2/25.
//

import Foundation
import LarkCore
import LarkModel
import LarkContainer
import RxSwift
import LarkMessageCore
import LarkSDKInterface
import LKCommonsLogging
import LarkFeatureGating
import RustPB

enum PreloadThreadsType: String {
    case fetchData
    case showUnReadAt
    case showUnReadMessages
}

final class UnReadNewThreadsTipViewModel: BaseUnreadMessagesTipViewModel {
    var lastReadPosition: Int32 = -1
    private static let threadLogger = Logger.log(UnReadNewThreadsTipViewModel.self, category: "LarkThread")
    private let updateChatPublish: PublishSubject<Chat> = PublishSubject<Chat>()
    private let pushChatObservable: Observable<Chat>
    private let threadAPI: ThreadAPI
    private let channelId: String
    private var preloadMessagePosition: Int32?
    private let requestCount: Int32
    private let redundancyCount: Int32
    private let pushThreadMessages: Observable<PushThreadMessages>
    // 存储未读的atAll消息，来源：pull和push
    private var unreadAtAllMessages: [ThreadMessage] = []

    init(
        userResolver: UserResolver,
        channelId: String,
        pushCenter: PushNotificationCenter,
        lastMessagePosition: Int32,
        requestCount: Int32,
        redundancyCount: Int32,
        threadAPI: ThreadAPI) {
        let pushChatOb: Observable<Chat> = pushCenter.observable(for: PushChat.self).filter { $0.chat.id == channelId }.map { $0.chat }
        let updateChatOb = updateChatPublish.asObservable()
        self.pushChatObservable = Observable.merge([pushChatOb, updateChatOb])
        self.pushThreadMessages = pushCenter.observable(for: PushThreadMessages.self)
        self.threadAPI = threadAPI
        self.channelId = channelId
        self.preloadMessagePosition = lastMessagePosition
        self.requestCount = requestCount
        self.redundancyCount = redundancyCount
        super.init(userResolver: userResolver)
        observeState()
        registerPush()
    }

    override func fetchDataWhenLoad() {
        if let preloadMessagePosition = preloadMessagePosition {
            self.preloadThreads(position: preloadMessagePosition,
                                type: .fetchData).subscribe().disposed(by: self.disposeBag)
            self.preloadMessagePosition = nil
        }
        self.fetchUnreadAtAllMessages()
    }

    private func observeState() {
        self.state
            .distinctUntilChanged { (state1, state2) -> Bool in
                return state1 == state2
            }
            .observeOn(self.dataScheduler)
            .flatMap { [weak self] (state) -> Observable<Void> in
                guard let self = self else { return .empty() }
                switch state {
                case .showUnReadAt(let message, _):
                    return self.preloadThreads(position: message.position,
                                               type: .showUnReadAt)
                case .showUnReadMessages:
                    if let preloadMessagePosition = self.preloadMessagePosition {
                        self.preloadMessagePosition = nil
                        return self.preloadThreads(position: preloadMessagePosition,
                                                   type: .showUnReadMessages)
                    }
                    return.empty()
                case .dismiss, .showToLastMessage:
                    return .empty()
                }
            }.subscribe().disposed(by: self.disposeBag)
    }

    // 拉取未读的atAll消息
    private func fetchUnreadAtAllMessages() {
        var quary = GetUnreadAtMessagesRequestQuary()
        quary.chatID = Int64(channelId) ?? 0
        quary.atType = .all
        threadAPI.fetchUnreadAtMessages(quaries: quary, ignoreBadged: false, needResponse: true)
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else { return }
                //接口返回前，可能通过pushmsg加入了unreadAt,要merge
                let unreadAtAllMessages = self.unreadAtAllMessages.lf_mergeUnique(array: result,
                                                                            comparable: { (msg1, msg2) -> Int in
                                                                                return Int(msg1.position - msg2.position)
                                                                            },
                                                                            equitable: { (msg1, msg2) -> ThreadMessage? in
                                                                                return (msg1.thread.id == msg2.thread.id) ? msg1 : nil
                                                                            },
                                                                            sequence: .ascending)
                self.unreadAtAllMessages = unreadAtAllMessages.sorted(by: { $0.position < $1.position })
                switch self.state.value {
                case .showToLastMessage, .dismiss:
                    break
                case .showUnReadAt(let currentUnReadAtMsg, let readPosition):
                    if let unreadAtAllMessage = unreadAtAllMessages.first(where: { (message) -> Bool in
                        return message.position > readPosition && message.position < currentUnReadAtMsg.position
                    }) {
                        self.state.accept(.showUnReadAt(unreadAtAllMessage, readPosition))
                    }
                case .showUnReadMessages(_, let readPosition):
                    if let unreadAtAllMessage = unreadAtAllMessages.first(where: { (message) -> Bool in
                        return message.position > readPosition
                    }) {
                        self.state.accept(.showUnReadAt(unreadAtAllMessage, readPosition))
                    }
                }
        }).disposed(by: disposeBag)
    }

    // 目前话题群向下电梯有两种形态： 未读消息 和 atAll
    // 未读消息根据PushChat上的badge来判断显示，atAll根据pull和push的message来判断显示
    private func registerPush() {
        // 监听chat更新处理未读消息的电梯显示和电梯的隐藏
        pushChatObservable
            .delay(
                .milliseconds(Int(CommonTable.scrollToBottomAnimationDuration * 1000 )),
                scheduler: self.dataScheduler)
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (chat) in
                let badge = chat.threadBadge
                let readPosition = chat.readThreadPosition
                // 当chat上的已读position比当前大时才去更新电梯
                if readPosition >= self?.lastReadPosition ?? -1 {
                    self?.lastReadPosition = readPosition
                    // 有未读的消息
                    if badge > 0 {
                        let unreadAtAllMessages = self?.unreadAtAllMessages ?? []
                        // 根据readPosition和unreadAtAllMessages判断是否还有未读的at
                        for unreadAtAllMessage in unreadAtAllMessages where unreadAtAllMessage.position > readPosition {
                            self?.state.accept(.showUnReadAt(unreadAtAllMessage, readPosition))
                            return
                        }
                        self?.state.accept(.showUnReadMessages(badge, readPosition))
                        Self.logger.info("lark thread UnReadNewThreadsTipViewModel showUnReadMessages badge: \(badge), readPosition \(readPosition)")
                    } else {
                        // 重置电梯
                        self?.state.accept(.dismiss)
                    }
                }
            }).disposed(by: disposeBag)

        // 监听Thread消息（话题根消息）更新处理未读atAll的电梯显示
        self.pushThreadMessages
            .compactMap({ push -> ThreadMessage? in
                let threadMessages = push.messages.filter({ $0.channel.id == self.channelId })
                // 只处理未读的atALl消息
                guard let threadMessage = threadMessages.first,
                      threadMessage.rootMessage.isAtAll,
                      !threadMessage.rootMessage.meRead,
                      threadMessage.position > self.lastReadPosition else {
                    return nil
                }
                return threadMessage
            })
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (threadMessage) in
                guard let `self` = self else { return }
                let maxPostion = self.unreadAtAllMessages.last?.position
                if threadMessage.position > maxPostion ?? -1 {
                    self.unreadAtAllMessages.append(threadMessage)
                }
                switch self.state.value {
                case .showUnReadAt:
                    break
                case .dismiss, .showToLastMessage:
                    self.state.accept(.showUnReadAt(threadMessage, self.lastReadPosition))
                case .showUnReadMessages(_, let readPosition):
                    self.state.accept(.showUnReadAt(threadMessage, readPosition))
                }
            }).disposed(by: self.disposeBag)
    }

    public func update(chat: Chat) {
        updateChatPublish.onNext(chat)
    }

    // MARK: - fetch data
    private func preloadThreads(position: Int32,
                                type: PreloadThreadsType) -> Observable<Void> {
        var channel = RustPB.Basic_V1_Channel()
        channel.id = channelId
        channel.type = .chat
        Self.logger.info("preloadThreads track UnReadNewThreadsTipViewModel \(type.rawValue) chatId:\(self.channelId) position \(position)")
        return self.threadAPI.fetchThreads(
            channel: channel,
            scene: .specifiedPosition(position),
            redundancyCount: redundancyCount,
            count: requestCount,
            needReplyPrompt: false
        ).map({ (_) -> Void in return })
    }

    override func unReadTip(count: Int32) -> String {
        return count == 1 ? BundleI18n.LarkThread.Lark_TopicChannel_OneNewTopicIOS : BundleI18n.LarkThread.Lark_TopicChannel_XNewTopicIOS
    }
}
