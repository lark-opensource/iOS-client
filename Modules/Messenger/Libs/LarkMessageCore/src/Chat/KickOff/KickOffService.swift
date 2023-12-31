//
//  KickOffService.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/4/21.
//

import Foundation
import RxCocoa
import LarkModel
import LarkSDKInterface
import LarkContainer
import LarkCore
import RxSwift
import LKCommonsLogging
import LarkAccountInterface

public final class KickOffService: UserResolverWrapper {
    public let userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(KickOffService.self, category: "KickOffService")
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?

    private var localLeaveGroupStatus: LocalLeaveGroupStatus = .none
    private let chatWrapper: ChatPushWrapper
    private let pushLocalLeave: Driver<PushLocalLeaveGroupChannnel>
    private let pushRemoveMe: Driver<PushRemoveMeFromChannel>
    private let disposeBag: DisposeBag = DisposeBag()

    public init(chatWrapper: ChatPushWrapper,
                pushLocalLeave: Driver<PushLocalLeaveGroupChannnel>,
                pushRemoveMe: Driver<PushRemoveMeFromChannel>,
                userResolver: UserResolver) {
        self.chatWrapper = chatWrapper
        self.pushLocalLeave = pushLocalLeave
        self.pushRemoveMe = pushRemoveMe
        self.userResolver = userResolver
    }

    public func generatorKickOffDriver() -> Driver<String> {
        let wrapperChat = chatWrapper.chat.value

        self.pushLocalLeave
            .asObservable()
            .subscribe(onNext: { [weak self] (push) in
                self?.localLeaveGroupStatus = push.status
            }).disposed(by: disposeBag)

         //监听push
         let pushRemoveMe = self.pushRemoveMe
            .filter({ [weak self] deleteMeInfo -> Bool in
                guard let self = self else { return false }
                let chat = self.chatWrapper.chat.value
                Self.logger.info("chatTrace recive pushRemoveMe \(chat.id)")
                if chat.isTeamVisitorMode && !deleteMeInfo.isDissolved {
                    // 增加逃逸条件，后面的逻辑不再交给原有的逻辑处理了，而是交给handleSwitchTeamChatMode来处理
                    Self.logger.info("chatTrace/teamlog/deleteMe chatId: \(chat.id)")
                    return false
                }
                let result = [LocalLeaveGroupStatus.none, LocalLeaveGroupStatus.error].contains(self.localLeaveGroupStatus)
                Self.logger.info("chatTrace recive pushRemoveMe return \(chat.id) \(result)")
                return result
            })
            .flatMap({ [weak self] (_) -> Driver<String> in
                return self?.generatorKickOffReason() ?? .empty()
            })

        //本地数据可能不准，要远端拉取
        let fetchChat = self.chatAPI?.fetchChat(by: wrapperChat.id, forceRemote: true)
            .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
            .asDriver(onErrorRecover: { error in
                Self.logger.error("chatTrace generatorKickOffReason fetchChat fail \(wrapperChat.id)", error: error)
                return .just(wrapperChat)
            })
            .flatMap { [weak self] fetchChat -> Driver<String> in
                guard let self = self else {
                    return .empty()
                }
                let chat = fetchChat ?? wrapperChat
                if fetchChat == nil {
                    Self.logger.error("chatTrace generatorKickOffReason fetchChat return empty \(chat.id)")
                }
                if chat.isDissolved || (chat.role != .member && !chat.isTeamVisitorMode && !chat.hasVcChatPermission) {
                    //已经判断出不在群里，就不用再依赖push了，会快很多
                    Self.logger.info("chatTrace is not in chat generatorKickOffReason directly \(chat.id)")
                    return self.generatorKickOffReason()
                }
                Self.logger.info("chatTrace generatorKickOffReason fetchChat in chat return empty \(chat.id)")
                return .empty()
            } ?? .empty()
        //监听和拉取同时触发，先到先处理
        return Driver.merge([pushRemoveMe, fetchChat])
    }

    private func generatorKickOffReason() -> Driver<String> {
        let chat = chatWrapper.chat.value
        Self.logger.info("chatTrace in generatorKickOffReason \(chat.id)")
        var content: String = BundleI18n.LarkMessageCore.Lark_IM_YouAreNotInThisChat_Text
        if chat.isOncall {
            let currentAccountChatterId = self.userResolver.userID
            Self.logger.info("chatTrace generatorKickOffReason in onCall \(chat.id) \(currentAccountChatterId)")
            return self.chatterAPI?.fetchChatChatters(ids: [currentAccountChatterId], chatId: chat.id)
                .flatMap { [weak self] chatters -> Driver<String> in
                    guard let self = self else {
                        return .empty()
                    }
                    if let chatter = chatters[currentAccountChatterId] {
                        let role = chatter.chatExtra?.oncallRole ?? .unknown
                        switch role {
                        case .oncallHelper, .userHelper:
                            content = BundleI18n.LarkMessageCore.Lark_HelpDesk_EndedServiceTipforAgent(chat.name)
                        case .user, .unknown, .oncall:
                            break
                        @unknown default:
                            assert(false, "new value")
                        }
                        Self.logger.info("chatTrace generatorKickOffReason ohCall role \(chat.id) \(role.rawValue) \(currentAccountChatterId)")
                        return .just(content)
                    } else {
                        Self.logger.info("chatTrace generatorKickOffReason fetchChatChatters empty \(chat.id) \(currentAccountChatterId)")
                        return self.chatAPI?.getKickInfo(chatId: chat.id)
                            .timeout(.milliseconds(700), scheduler: MainScheduler.instance)
                            .asDriver(onErrorRecover: { error in
                                Self.logger.error("chatTrace generatorKickOffReason getKickInfo fail \(chat.id) \(currentAccountChatterId)", error: error)
                                return .just(content)
                            }) ?? .empty()
                    }
                }.asDriver(onErrorRecover: { error in
                    Self.logger.error("chatTrace generatorKickOffReason fetchChatChatters fail \(chat.id) \(currentAccountChatterId)", error: error)
                    return .just(content)
                }) ?? .empty()
        } else {
            //后面服务端会将所有被踢出场景原因都收敛到这个接口
            Self.logger.info("chatTrace generatorKickOffReason getKickInfo directly \(chat.id)")
            return self.chatAPI?.getKickInfo(chatId: chat.id)
                .timeout(.milliseconds(700), scheduler: MainScheduler.instance)
                .asDriver(onErrorRecover: { error in
                    Self.logger.error("chatTrace generatorKickOffReason getKickInfo fail \(chat.id)", error: error)
                    return .just(content)
                }) ?? .empty()
        }
    }
}
