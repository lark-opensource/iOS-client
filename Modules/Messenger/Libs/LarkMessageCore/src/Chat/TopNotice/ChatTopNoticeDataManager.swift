//
//  ChatTopNoticeDataManager.swift
//  LarkMessageCore
//
//  Created by bytedance on 2021/11/11.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import RxCocoa
import RustPB
import LarkContainer
import LarkSetting
import LarkSDKInterface
import LKCommonsLogging
import LarkAccountInterface
import LarkMessengerInterface

/// 获取&监听置顶信息,维护最新版本
public final class ChatTopNoticeDataManager: UserResolverWrapper {

    static let logger = Logger.log(ChatTopNoticeDataManager.self, category: "ChatTopNoticeDataManager")

    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var userActionService: TopNoticeUserActionService?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?

    lazy var chatTopMesssageDriver: Driver<PushChatTopNotice> = {
        let chatId = self.chatId
        return pushCenter.driver(for: PushChatTopNotice.self)
            .filter({ (push) -> Bool in
                return String(push.chatId) == chatId
            })
    }()

    lazy var pushMessageDriver: Driver<PushChannelMessage> = {
        let chatId = self.chatId
        return pushCenter.driver(for: PushChannelMessage.self)
            .filter({ (push) -> Bool in
                return push.message.channel.id == chatId
            })
    }()
    private let chatId: String
    private let pushCenter: PushNotificationCenter
    private var topNoticeInfo: RustPB.Im_V1_ChatTopNotice?
    private let topNoticeSubject: BehaviorSubject<ChatTopNotice?> = BehaviorSubject(value: nil)
    lazy public var topNoticeDriver: Driver<ChatTopNotice?> = {
        return topNoticeSubject.asDriver(onErrorJustReturn: nil)
            .do(onNext: { [weak self] (notice) in
                for listener in self?.topNoticeListener ?? [] {
                    listener(notice)
                }
        })
    }()

    private var topNoticeListener: [((ChatTopNotice?) -> Void)] = []
    public let userResolver: UserResolver
    public init(chatId: String, pushCenter: PushNotificationCenter, userResolver: UserResolver) {
        self.chatId = chatId
        self.pushCenter = pushCenter
        self.userResolver = userResolver
    }

    public func startGetAndObserverTopNoticeData() {
        self.getTopNoticeBannerInfo()
        self.addObserver()
    }

    public func addObserver() {
        chatTopMesssageDriver.drive(onNext: { [weak self] response in
            self?.updateTopNoticeIfNeed(chatID: response.chatId,
                                              noticeInfo: response.info)
        }).disposed(by: disposeBag)

        userActionService?.updatePublishSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] info in
                self?.updateTopNoticeIfNeed(chatID: info.1, noticeInfo: info.0)
            }).disposed(by: disposeBag)
    }

    private func updateTopNoticeIfNeed(chatID: Int64, noticeInfo: RustPB.Im_V1_ChatTopNotice) {
        /// 同一个chat再更新
        guard String(chatID) == self.chatId else {
            return
        }
        guard self.needUpdateLocalNoticeWith(noticeInfo) else {
            return
        }
        /// 当前版本新于本地版本 需要更新
        self.topNoticeInfo = noticeInfo
        /// 如果没有content或者content的类型为unknown 不处理
        if self.isInvalid(topNotice: noticeInfo) {
            ///  隐藏视图
            self.topNoticeSubject.onNext(nil)
        } else {
            /// 更新一下视图
            self.topNoticeSubject.onNext(noticeInfo)
        }
    }

    public func getTopNoticeBannerInfo() {
        let chatId = Int64(self.chatId) ?? 0
        self.chatAPI?.getChatTopNoticeWithChatId(chatId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                self?.updateTopNoticeIfNeed(chatID: chatId, noticeInfo: response.topNoticeInfo)
            }, onError: { error in
                Self.logger.error("getTopNoticeBannerInfo error: \(error)")
            }).disposed(by: disposeBag)
    }
    func isInvalid(topNotice: RustPB.Im_V1_ChatTopNotice) -> Bool {
        return !topNotice.hasContent || topNotice.content.type == .unknown
    }

    public func addTopNotice(listener: @escaping ((ChatTopNotice?) -> Void)) {
        if let notice = try? self.topNoticeSubject.value() {
            //每次加入监听时，会返回之前缓存结果，保证后加入监听，也能拿到已有状态
            listener(notice)
        }
        self.topNoticeListener.append(listener)
    }

    private func needUpdateLocalNoticeWith(_ responseInfo: RustPB.Im_V1_ChatTopNotice) -> Bool {
        guard let topNoticeInfo = self.topNoticeInfo else {
            return true
        }
        if responseInfo.noticeVersion > topNoticeInfo.noticeVersion {
            return true
        }

        /// 如果推送来的,版本一样的话:
        if responseInfo.noticeVersion == topNoticeInfo.noticeVersion {
            //这种情况可以判断那个是最新的。本地是打开的，远端是关闭的(关闭后无法打开)
            if responseInfo.closed,
               !topNoticeInfo.closed {
                return true
            }
            //二次编辑的情况
            if let oldMessage = topNoticeInfo.content.entity.messages["\(topNoticeInfo.content.messageID)"],
               let newMessage = responseInfo.content.entity.messages["\(responseInfo.content.messageID)"],
               newMessage.editVersion > oldMessage.editVersion {
                return true
            }
        }
        return false
    }
}
