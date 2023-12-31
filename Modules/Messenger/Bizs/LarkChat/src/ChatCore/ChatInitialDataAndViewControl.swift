//
//  ChatInitialDataAndViewControl.swift
//  LarkChat
//
//  Created by zc09v on 2020/3/24.
//

import Foundation
import LarkModel
import LarkSDKInterface
import RxSwift
import LarkMessageCore
import LarkFeatureGating
import ThreadSafeDataStructure
import LarkContainer
import LarkMessengerInterface
import LKCommonsLogging
import RustPB

final class ChatTabsInitialDataControl {
    private let chatAPI: ChatAPI
    private var fetchDisposeBag = DisposeBag()
    private var pushDisposeBag = DisposeBag()
    private var pushTabs: SafeAtomic<(tabs: [RustPB.Im_V1_ChatTab], version: Int64)?> = nil + .readWriteLock

    private let tabPreLoadDataSignal: ReplaySubject<RustPB.Im_V1_GetChatTabsResponse> = ReplaySubject<RustPB.Im_V1_GetChatTabsResponse>.create(bufferSize: 1)
    public var tabPreLoadDataObservable: Observable<RustPB.Im_V1_GetChatTabsResponse> {
        return tabPreLoadDataSignal.asObservable()
    }

    init(userResolver: UserResolver, chatID: Int64, tabsPushObservable: Observable<PushChatTabs>) throws {
        chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.chatAPI
            .fetchChatTab(chatId: chatID, fromLocal: true)
            .flatMap { [weak self] (res) -> Observable<RustPB.Im_V1_GetChatTabsResponse> in
                guard let self = self else { return .empty() }
                self.tabPreLoadDataSignal.onNext(res)
                return self.chatAPI.fetchChatTab(chatId: chatID, fromLocal: false)
            }
            .subscribe(onNext: { [weak self] (res) in
                self?.tabPreLoadDataSignal.onNext(res)
            }, onError: { [weak self] (error) in
                self?.tabPreLoadDataSignal.onError(error)
            }, onCompleted: { [weak self] in
                self?.tabPreLoadDataSignal.onCompleted()
            }).disposed(by: self.fetchDisposeBag)
        tabsPushObservable
            .filter { $0.chatId == chatID }
            .subscribe(onNext: { [weak self] (push) in
                self?.pushTabs.value = (push.tabs, push.version)
            }).disposed(by: self.pushDisposeBag)
    }

    func getBufferPushTabs() -> (tabs: [RustPB.Im_V1_ChatTab], version: Int64)? {
        self.pushDisposeBag = DisposeBag()
        return self.pushTabs.value
    }
}

final class ChatInitialDataAndViewControl: InitialDataAndViewControl<(Chat, fetchChatCost: Int64, fetchChatterCost: Int64), GetChatMessagesResult> {
    private var disposeBag = DisposeBag()
    private var _pushMessages: SafeArray<Message> = [] + .semaphore
    let messageBurnService: MessageBurnService
    // 密聊不支持URL预览
    private var urlPreviewService: MessageURLPreviewService?
    static let logger = Logger.log(ChatInitialDataAndViewControl.self, category: "Business.Chat")
    private let chatID: String
    private let tabsDataControl: ChatTabsInitialDataControl

    var tabPreLoadDataObservable: Observable<RustPB.Im_V1_GetChatTabsResponse> {
        return self.tabsDataControl.tabPreLoadDataObservable
    }
    let tabsPushObservable: Observable<PushChatTabs>

    init(userResolver: UserResolver,
         chatID: String,
         urlPreviewService: MessageURLPreviewService?,
         messagePushObservable: Observable<PushChannelMessages>?,
         tabsPushObservable: Observable<PushChatTabs>,
         blockPreLoadData: Observable<(Chat, fetchChatCost: Int64, fetchChatterCost: Int64)>,
         otherPreLoadData: Observable<GetChatMessagesResult>? = nil
    ) throws {
        self.chatID = chatID
        self.messageBurnService = try userResolver.resolve(assert: MessageBurnService.self)
        self.tabsDataControl = try ChatTabsInitialDataControl(userResolver: userResolver, chatID: Int64(chatID) ?? 0, tabsPushObservable: tabsPushObservable)
        self.tabsPushObservable = tabsPushObservable
        self.urlPreviewService = urlPreviewService
        super.init(blockPreLoadData: blockPreLoadData, otherPreLoadData: otherPreLoadData)
        if let messagePushObservable = messagePushObservable {
            addMessagePushObserver(messagePushObservable, chatID: chatID)
        }
    }

    func getBufferPushTabs() -> (tabs: [RustPB.Im_V1_ChatTab], version: Int64)? {
        return self.tabsDataControl.getBufferPushTabs()
    }

    //首屏消息不为空时，可直接处理_pushMessages
    func bufferPushMessages(range: (minPosition: Int32, maxPosition: Int32)?) -> [Message] {
        self.disposeBag = DisposeBag()
        var bufferMessages = _pushMessages.getImmutableCopy()
        let positions = bufferMessages.reduce("") { (result, msg) -> String in
            return result + "\(msg.position) "
        }
        Self.logger.info("chatTrace bufferPushMessages positions: \(chatID) \(positions)")
        if let range = range {
            bufferMessages = self.bufferContinuousVaildMessages(messages: bufferMessages,
                                                                minPosition: range.minPosition,
                                                                maxPosition: range.maxPosition)
            let positions = bufferMessages.reduce("") { (result, msg) -> String in
                return result + "\(msg.position) "
            }
            Self.logger.info("chatTrace bufferPushMessages continuousVaild positions: \(chatID) \(positions) \(range.minPosition) \(range.maxPosition)")
        }
        _pushMessages.removeAll()
        return bufferMessages
    }

    //如果首屏消息为空时，_pushMessages需要进行规整，指定有效区间、取最大连续区间、且有效的数据
    private func bufferContinuousVaildMessages(messages: [Message], minPosition: Int32, maxPosition: Int32) -> [Message] {
        let bufferMessages = messages
            .filter { (msg) -> Bool in
                guard !msg.isDeleted, msg.isVisible, !messageBurnService.isBurned(message: msg) else { return false }
                return msg.position >= minPosition && msg.position <= maxPosition
            }
            .sorted(by: { $0.position < $1.position })
        var result: [Message] = []
        for msg in bufferMessages {
            if let last = result.last {
                if msg.position == last.position {
                    //替换
                    result[result.count - 1] = msg
                } else if msg.position == last.position + 1 {
                    //连续
                    result.append(msg)
                } else {
                    //重新设置区间
                    result = [msg]
                }
            } else {
                result.append(msg)
            }
        }
        return result
    }

    private func addMessagePushObserver(_ messagePushObservable: Observable<PushChannelMessages>, chatID: String) {
        Self.logger.info("chatTrace addMessagePushObserver \(chatID)")
        messagePushObservable
        .map({ (push) -> [Message] in
            return push.messages.filter({ (msg) -> Bool in
                return msg.channel.id == chatID
            })
        })
        .filter({ (msgs) -> Bool in
            return !msgs.isEmpty
        }).subscribe(onNext: { [weak self] (messages) in
            self?._pushMessages.append(contentsOf: messages)
            self?.urlPreviewService?.fetchMissingURLPreviews(messages: messages)
        }).disposed(by: self.disposeBag)
    }

}
