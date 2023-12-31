//
//  ChatPinAndTopNoticeViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/17.
//

import Foundation
import LKCommonsLogging
import LarkModel
import LarkMessageCore
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkContainer
import RustPB

struct ChatPinTopNoticeModel {
    let pbOperator: Chatter
    let message: Message?
    let pbModel: RustPB.Im_V1_ChatTopNotice
    let announcementSender: Chatter?
}

final class ChatPinAndTopNoticeViewModel: LarkContainer.UserResolverWrapper {
    var userResolver: UserResolver
    static private let logger = Logger.log(ChatPinAndTopNoticeViewModel.self, category: "Module.IM.ChatPin")

    private let disposeBag = DisposeBag()
    private let chatId: String
    private let topNoticeDataManger: ChatTopNoticeDataManager?
    @ScopedInjectedLazy private var pinAPI: PinAPI?

    private let refreshPublish: PublishSubject<Void> = PublishSubject<Void>()
    lazy var refreshDriver: Driver<Void> = {
        return refreshPublish
            .asDriver(onErrorRecover: { _ in Driver<Void>.empty() })
    }()

    var showOldPinEntryBehaviorRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var topNoticeBehaviorRelay: BehaviorRelay<ChatPinTopNoticeModel?> = BehaviorRelay<ChatPinTopNoticeModel?>(value: nil)

    private var userPushCenter: PushNotificationCenter? {
        return try? self.userResolver.userPushCenter
    }

    init(userResolver: UserResolver, chatId: String) {
        self.userResolver = userResolver
        self.chatId = chatId
        if let userPushCenter = try? userResolver.userPushCenter {
            self.topNoticeDataManger = ChatTopNoticeDataManager(chatId: chatId, pushCenter: userPushCenter, userResolver: userResolver)
        } else {
            self.topNoticeDataManger = nil
        }
    }

    private(set) var topNoticeModel: ChatPinTopNoticeModel? {
        didSet {
            self.refreshPublish.onNext(())
            if let topNoticeModel = topNoticeModel, !topNoticeModel.pbModel.closed {
                self.topNoticeBehaviorRelay.accept(topNoticeModel)
            } else {
                self.topNoticeBehaviorRelay.accept(nil)
            }
        }
    }

    private(set) var pinCount: Int = 0 {
        didSet {
            guard pinCount != oldValue else { return }
            self.refreshPublish.onNext(())
            self.showOldPinEntryBehaviorRelay.accept(pinCount != 0)
        }
    }

    func startFetchAndObservePush() {
        guard !self.userResolver.fg.staticFeatureGatingValue(with: "im.chat.pinned.msg") else { return }
        guard let chatID = Int64(self.chatId) else { return }
        self.userPushCenter?.observable(for: PushChatPinCount.self)
            .filter { $0.chatId == chatID }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                self?.pinCount = Int(push.count)
                Self.logger.info("chatOldPinTrace push count \(push.count) chatId: \(chatID)")
        }).disposed(by: self.disposeBag)

        self.pinAPI?.getChatPinCount(chatId: chatID, useLocal: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                self?.pinCount = Int(count)
                Self.logger.info("chatOldPinTrace get count Local \(count) chatId: \(chatID)")
        }).disposed(by: self.disposeBag)
        self.pinAPI?.getChatPinCount(chatId: chatID, useLocal: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                self?.pinCount = Int(count)
                Self.logger.info("chatOldPinTrace get count Server \(count) chatId: \(chatID)")
        }).disposed(by: self.disposeBag)

        self.topNoticeDataManger?.topNoticeDriver
            .drive(onNext: { [weak self] notice in
                self?.topNoticeModel = self?.transferTopNoticeModel(topNotice: notice)
            }).disposed(by: disposeBag)
        self.topNoticeDataManger?.startGetAndObserverTopNoticeData()

        self.userPushCenter?
            .driver(for: PushChannelNickname.self)
            .drive(onNext: { [weak self] nickNameInfo in
                guard let self = self,
                      nickNameInfo.channelId == self.chatId,
                      let topNoticeModel = self.topNoticeModel else { return }
                var chatterUpdated: Bool = false
                if topNoticeModel.message?.fromChatter?.id == nickNameInfo.chatterId {
                    topNoticeModel.message?.fromChatter?.chatExtra?.nickName = nickNameInfo.newNickname
                    chatterUpdated = true
                }
                if topNoticeModel.announcementSender?.id == nickNameInfo.chatterId {
                    topNoticeModel.announcementSender?.chatExtra?.nickName = nickNameInfo.newNickname
                    chatterUpdated = true
                }
                if topNoticeModel.pbOperator.id == nickNameInfo.chatterId {
                    topNoticeModel.pbOperator.chatExtra?.nickName = nickNameInfo.newNickname
                    chatterUpdated = true
                }
                if chatterUpdated {
                    self.refreshPublish.onNext(())
                }
            }).disposed(by: disposeBag)
    }

    private func transferTopNoticeModel(topNotice: ChatTopNotice?) -> ChatPinTopNoticeModel? {
        guard let topNotice = topNotice else {
            return nil
        }
        let chatterDic = topNotice.operator.chatChatters[chatId]
        let pbOperator = chatterDic?.chatters.first?.value
        guard let pbOperator = pbOperator else {
            return nil
        }
        let operateChatter: Chatter? = try Chatter.transform(pb: pbOperator)
        guard let operateChatter = operateChatter else {
            assertionFailure("OperateChatterNotObtained")
            return nil
        }
        let messageID = String(topNotice.content.messageID)
        var message: Message?
        if !messageID.isEmpty {
            do {
                message = try Message.transform(entity: topNotice.content.entity,
                                                id: messageID,
                                                currentChatterID: userResolver.userID)
            } catch {
                Self.logger.error("get Message miss messageID \(messageID)", error: error)
            }
        }
        let senderId = String(topNotice.content.senderID)
        let announcementSender: Chatter? = try? Chatter.transformChatChatter(entity: topNotice.content.entity,
                                                                             chatID: chatId,
                                                                             id: senderId)
        return ChatPinTopNoticeModel(
            pbOperator: operateChatter,
            message: message,
            pbModel: topNotice,
            announcementSender: announcementSender
        )
    }

}
