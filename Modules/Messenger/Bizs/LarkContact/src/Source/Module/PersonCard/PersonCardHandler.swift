//
//  PersonCardHandler.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2018/4/19.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import Swinject
import EENavigator
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import LKCommonsLogging
import LarkFeatureSwitch
import LarkPerf
import LarkFeatureGating
import LarkProfile
import LarkAccountInterface
import LarkNavigator

/// 带UserProfile跳转个人卡片页面
final class ProfileCardHandler: UserTypedRouterHandler {

    func handle(_ body: ProfileCardBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        ClientPerf.shared.startSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                            logid: ContactLogKey.profile.rawValue)
        AppReciableTrack.userProfileLoadTimeStart()
        ProfileReciableTrack.userProfileLoadTimeStart()
        let userProfileTrackKey = AppReciableTrack.getUserProfileKey()
        let profileUserProfileTrackKey = ProfileReciableTrack.getUserProfileKey()
        if let userProfile = body.userProfile {
            var fromWhere: LarkUserProfileFromWhere = .none
            switch body.fromWhere {
            case .none:
                fromWhere = .none
            case .search:
                fromWhere = .search
            case .invitation:
                fromWhere = .invitation
            case .chat:
                fromWhere = .chat
            case .thread:
                fromWhere = .thread
            case .groupBotToRemove:
                fromWhere = .groupBotToRemove
            case .groupBotToAdd:
                fromWhere = .groupBotToAdd
            }

            let data = LarkProfileData(chatterId: userProfile.userId,
                                       chatterType: nil,
                                       contactToken: "",
                                       chatId: "",
                                       fromWhere: fromWhere)
            let factory = try userResolver.resolve(assert: ProfileFactory.self)
            let vc = factory.createProfile(by: data)
            res.end(resource: vc)
            AppReciableTrack.userProfileInitViewCostTrack()
            ProfileReciableTrack.userProfileInitViewCostTrack()
        } else {
            ClientPerf.shared.endSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                              logid: ContactLogKey.profile.rawValue)
            AppReciableTrack.userProfileLoadTimeEnd(key: userProfileTrackKey)
            ProfileReciableTrack.userProfileLoadTimeEnd(key: profileUserProfileTrackKey)
            res.end(error: RouterError.invalidParameters("userProfile"))
        }
    }
}

public protocol PersonCardHandlerDependency {
    func redirectToAppDetailBody(response: EENavigator.Response, botID: String, fromWhere: PersonCardFromWhere, chatID: String, extraParams: [String: String]?)
    func hasByteView() -> Bool
    func startByteViewFromRightUpCornerButton(userId: String)
    func startByteViewFromAddressBookCard(userId: String)
}

/// 带chatId&&chatterId跳转个人卡片页面
final class NewPersonCardHandler: UserTypedRouterHandler {
    private static var logger = Logger.log(NewPersonCardHandler.self, category: "NewPersonCardHandler")

    private let disposeBag = DisposeBag()

    func handle(_ body: PersonCardBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        ClientPerf.shared.startSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                            logid: ContactLogKey.profile.rawValue)
        AppReciableTrack.userProfileLoadTimeStart()
        ProfileReciableTrack.userProfileLoadTimeStart()
        let userProfileTrackKey = AppReciableTrack.getUserProfileKey()
        let profileUserProfileTrackKey = ProfileReciableTrack.getUserProfileKey()

        guard !body.chatterId.isEmpty else {
            res.end(error: RouterError.invalidParameters("chatterId"))
            ClientPerf.shared.endSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                              logid: ContactLogKey.profile.rawValue)
            AppReciableTrack.userProfileLoadTimeEnd(key: userProfileTrackKey)
            ProfileReciableTrack.userProfileLoadTimeEnd(key: profileUserProfileTrackKey)
            return
        }
        let factory = try userResolver.resolve(assert: ProfileFactory.self)
        let dependency = try self.userResolver.resolve(assert: ContactDependency.self)
        /// 挪用上述是否符合跳转条件的逻辑
        func pushCard(_ chatter: Chatter) {
            if !chatter.profileEnabled {
                res.end(error: nil)
                ClientPerf.shared.endSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                                  logid: ContactLogKey.profile.rawValue)
                AppReciableTrack.userProfileLoadTimeEnd(key: userProfileTrackKey)
                ProfileReciableTrack.userProfileLoadTimeEnd(key: profileUserProfileTrackKey)
                return
            }
            if chatter.type == .bot {
                dependency.redirectToAppDetailBody(response: res, botID: body.chatterId, fromWhere: body.fromWhere, chatID: body.chatId, extraParams: body.extraParams)
                ClientPerf.shared.endSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                                  logid: ContactLogKey.profile.rawValue)
                AppReciableTrack.userProfileLoadTimeEnd(key: userProfileTrackKey)
                ProfileReciableTrack.userProfileLoadTimeEnd(key: profileUserProfileTrackKey)
                return
            }

            // source增加了senderID，sourceID， 方便后续国际化
            var source = Source()
            source.sender = body.sender
            source.sourceType = body.source
            source.sourceName = body.sourceName
            source.senderID = body.senderID
            source.sourceID = body.sourceID
            source.subSourceType = body.subSourceType

            var vc: UIViewController?

            if chatter.type == .ai,
               let aiService = try? userResolver.resolve(type: MyAIService.self),
               !aiService.canOpenOthersAIProfile,           // 判断能否查看他人的 AI Profile
               aiService.info.value.id != chatter.id {      // 判断是否是他人的 AI
                return
            }

            let data = LarkProfileData(chatterId: body.chatterId,
                                       chatterType: chatter.type,
                                       contactToken: "",
                                       chatId: body.chatId,
                                       fromWhere: .chat,
                                       senderID: body.senderID,
                                       sender: body.sender,
                                       sourceID: body.sourceID,
                                       sourceName: body.sourceName,
                                       subSourceType: body.subSourceType,
                                       source: body.source,
                                       extraParams: body.extraParams,
                                       needToPushSetInformationViewController: body.needToPushSetInformationViewController)
            let tabVC = factory.createProfile(by: data)
            res.end(resource: tabVC)
            AppReciableTrack.userProfileInitViewCostTrack()
            ProfileReciableTrack.userProfileInitViewCostTrack()
        }

        let chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)

        // 删除同步接口
        res.wait()
        let observable: Observable<Chatter?>

        if body.chatId.isEmpty {
            observable = chatterAPI.getChatter(id: body.chatterId)
        } else {
            // user chatID to load more info
            // 匿名客服需有些信息不展示，需要先拉取远端的用户信息
            observable = try userResolver.resolve(assert: ChatAPI.self).fetchChat(by: body.chatId, forceRemote: false)
                .flatMap { (chat) -> Observable<Chatter?> in
                    if let chat = chat, chat.isOncall {
                        return chatterAPI.fetchChatChatters(ids: [body.chatterId], chatId: body.chatId)
                            .map({ $0[body.chatterId] })
                            .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                    }
                    return chatterAPI.getChatter(id: body.chatterId)
                }
        }

        observable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatter) in
                guard let chatter = chatter else {
                    res.end(error: RouterError.invalidParameters("chatterId"))
                    ClientPerf.shared.endSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                                      logid: ContactLogKey.profile.rawValue)
                    AppReciableTrack.userProfileLoadTimeEnd(key: userProfileTrackKey)
                    ProfileReciableTrack.userProfileLoadTimeEnd(key: profileUserProfileTrackKey)
                    return
                }
                // 匿名用户不允许被查看profile
                if chatter.isAnonymous {
                    return
                }

                guard chatter.profileEnabled else {
                    Self.logger.error(
                        "chatter profile enable false",
                        additionalData: [
                            "ChatID": body.chatId,
                            "ChatterID": body.chatterId
                        ],
                        error: nil)
                    res.end(resource: EmptyResource())
                    ClientPerf.shared.endSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                                      logid: ContactLogKey.profile.rawValue)
                    AppReciableTrack.userProfileLoadTimeEnd(key: userProfileTrackKey)
                    ProfileReciableTrack.userProfileLoadTimeEnd(key: profileUserProfileTrackKey)
                    return
                }

                pushCard(chatter)
            }, onError: { (error) in
                res.end(error: error)
            })
            .disposed(by: disposeBag)
    }
}

/// 带token跳转个人卡片页面
final class NewAddFriendHandler: UserTypedRouterHandler {
    func handle(_ body: AddFriendBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        ClientPerf.shared.startSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                            logid: ContactLogKey.profile.rawValue)
        AppReciableTrack.userProfileLoadTimeStart()
        ProfileReciableTrack.userProfileLoadTimeStart()
        let userProfileTrackKey = AppReciableTrack.getUserProfileKey()
        let profileUserProfileTrackKey = ProfileReciableTrack.getUserProfileKey()
        if !body.token.isEmpty {
            var source = Source()
            source.sender = body.sender
            source.sourceType = body.source
            source.sourceName = body.sourceName

            var vc: UIViewController?
            let data = LarkProfileData(chatterId: "",
                                       chatterType: nil,
                                       contactToken: body.token,
                                       chatId: "",
                                       fromWhere: .none,
                                       senderID: "",
                                       sender: body.sender,
                                       sourceID: "",
                                       sourceName: body.sourceName,
                                       subSourceType: "",
                                       source: body.source)
            let factory = try userResolver.resolve(assert: ProfileFactory.self)
            vc = factory.createProfile(by: data)
            res.end(resource: vc)
            AppReciableTrack.userProfileInitViewCostTrack()
            ProfileReciableTrack.userProfileInitViewCostTrack()
        } else {
            ClientPerf.shared.endSlardarEvent(service: ContactMetricKey.profile.rawValue,
                                              logid: ContactLogKey.profile.rawValue)
            AppReciableTrack.userProfileLoadTimeEnd(key: userProfileTrackKey)
            ProfileReciableTrack.userProfileLoadTimeEnd(key: profileUserProfileTrackKey)
            res.end(error: RouterError.invalidParameters("token"))
        }
    }
}

///link跳转个人卡片页面
final class PersonCardLinkHandler: UserTypedRouterHandler {

    func handle(_ body: PersonCardLinkBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        if !body.uid.isEmpty {
            res.redirect(body: PersonCardBody(chatterId: body.uid,
                                              chatId: body.chatId,
                                              fromWhere: .none,
                                              sender: body.sender,
                                              sourceName: body.sourceName,
                                              source: body.source))
        } else if !body.token.isEmpty {
            res.redirect(body: AddFriendBody(token: body.token,
                                             sender: body.sender,
                                             sourceName: body.sourceName,
                                             source: body.source))
        } else {
            res.end(error: RouterError.invalidParameters("token || uid"))
        }
    }
}

/// namecard跳转个人卡片页面
final class NameCardProfileHandler: UserTypedRouterHandler {

    func handle(_ body: NameCardProfileBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let viewModel = MailProfileViewModelImp(namecardID: body.namecardId,
                                                email: body.email,
                                                accountID: body.accountId,
                                                resolver: userResolver,
                                                userName: body.userName,
                                                callback: body.callback)
        let vc = MailProfileViewController(viewModel: viewModel, resolver: userResolver)

        res.end(resource: vc)
    }
}

/// namecard跳转个人卡片页面
final class MedalHandler: UserTypedRouterHandler {
    func handle(_ body: MedalVCBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        var userID = try userResolver.userID
        if !body.userID.isEmpty {
            userID = body.userID
        }
        let vc = MedalViewController(resolver: self.userResolver, viewModel: MedalViewModel(resolver: userResolver, userID: userID))
        res.end(resource: vc)
    }
}

final class ApplyCommunicationPermissionHandler: UserTypedRouterHandler {
    func handle(_ body: ApplyCommunicationPermissionBody, req: EENavigator.Request, res: EENavigator.Response) throws {

        let vc = try LarkProfileApplyCommunicationViewController(userResolver: self.userResolver, userId: body.userId, dismissCallback: body.dismissCallBack)
        res.end(resource: vc)
    }
}
