//
//  GroupChattersSpecializedViewModel.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/8/26.
//

import UIKit
import Foundation
import LarkModel
import RxCocoa
import RxSwift
import RxRelay
import LKCommonsLogging
import UniverseDesignToast
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureGating
import LarkContainer
import LarkSetting
import RustPB
import LarkCore

final class GroupChattersSpecializedViewModel: GroupChattersSingleDependencyProtocol, UserResolverWrapper, ExportChatMembersAbility {
    var userResolver: LarkContainer.UserResolver

    private let logger = Logger.log(
           GroupChattersSpecializedController.self,
           category: "IM.GroupChattersSpecializedController")
    let disposeBag = DisposeBag()

    private(set) var ownerID: String
    private(set) var tenantID: String
    private(set) var currentChatterID: String
    private(set) var chatID: String
    private(set) var chat: Chat
    private(set) var currentUserType: AccountUserType
    private(set) var pushChatChatter: Observable<PushChatChatter>
    private(set) var pushChatAdmin: Observable<PushChatAdmin>
    private(set) var pushChatChatterListDepartmentName: Observable<PushChatChatterListDepartmentName>?

    private(set) var chatAPI: ChatAPI
    private(set) var chatterAPI: ChatterAPI
    private(set) var serverNTPTimeService: ServerNTPTimeService

    private(set) var isOwnerSelectable: Bool = false
    private(set) var supportShowDepartment: Bool

    private var _removeChatters = PublishSubject<[String]>()
    var removeChatters: Observable<[String]> { return _removeChatters.asObservable() }
    let isThread: Bool
    weak var targetViewController: UIViewController? // 用于 viewModel 中 hud 展示
    // 是否是群管理
    var isGroupAdmin: Bool {
        chat.isGroupAdmin
    }

    var currentUserId: String {
        return self.userResolver.userID
    }

    private(set) var canExportMembers: Bool = false

    var isSupportAlphabetical: Bool {
        // imChatMemberListFg：当前租户是否开启了FG
        let key = FeatureGatingManager.Key(stringLiteral: FeatureGatingKey.imChatMemberList.rawValue)
        // canBeSortedAlphabetically： 群是否支持首字母排序
        return userResolver.fg.dynamicFeatureGatingValue(with: key) && chat.canBeSortedAlphabetically && !chat.isSuper
    }

    init(userResolver: UserResolver,
         chat: Chat,
         supportShowDepartment: Bool = false
    ) throws {
        self.userResolver = userResolver
        let passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        let user = passportUserService.user

        self.ownerID = chat.ownerId
        self.tenantID = user.tenant.tenantID
        self.currentChatterID = user.userID
        self.chatID = chat.id
        self.chat = chat
        self.isThread = chat.chatMode == .threadV2
        self.currentUserType = .init(user.type)
        self.pushChatChatter = try userResolver.userPushCenter.observable(for: PushChatChatter.self)
        self.pushChatAdmin = try userResolver.userPushCenter.observable(for: PushChatAdmin.self)
        self.pushChatChatterListDepartmentName = try userResolver.userPushCenter.observable(for: PushChatChatterListDepartmentName.self)
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        self.serverNTPTimeService = try userResolver.resolve(assert: ServerNTPTimeService.self)
        self.supportShowDepartment = supportShowDepartment
        self.fetchData()
    }

    private func fetchData() {
        self.fetchExportMembersPermission(fg: self.userResolver.fg)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
            self?.canExportMembers = result
        }).disposed(by: self.disposeBag)
    }

    func removeChatters(with chatterIds: [String]) {
        self.chatAPI.deleteChatters(chatId: chatID, chatterIds: chatterIds, newOwnerId: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?._removeChatters.onNext(chatterIds)
            }, onError: { [weak self] (error) in
                self?.logger.error(
                    "remove chat chatter error",
                    additionalData: [
                        "chatID": self?.chatID ?? "",
                        "chatterIds": chatterIds.joined(separator: ",")
                    ],
                    error: error)

                guard let targetVC = self?.targetViewController else {
                    return
                }
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .noSecretChatPermission(let message):
                        UDToast.showFailure(with: message, on: targetVC.view, error: error)
                    case .targetExternalCoordinateCtl, .externalCoordinateCtl:
                        UDToast.showFailure(
                            with: BundleI18n.LarkChatSetting
                                .Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission,
                            on: targetVC.view,
                            error: error
                        )
                    default:
                        UDToast().showFailure(
                            with: BundleI18n.LarkChatSetting.Lark_Legacy_GroupDeleteMemberFailTip,
                            on: targetVC.view,
                            error: error
                        )
                    }
                    return
                }
                UDToast().showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_GroupDeleteMemberFailTip, on: targetVC.view, error: error)
            }).disposed(by: disposeBag)
    }
}
