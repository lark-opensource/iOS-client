//
//  GroupChatterDetailHandler.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/3.
//

import UIKit
import Foundation
import LarkModel
import EENavigator
import Swinject
import LKCommonsLogging
import LarkCore
import LarkContainer
import LarkTag
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LKCommonsTracker
import UniverseDesignToast
import RxSwift
import Homeric
import RustPB
import LarkNavigator

final class GroupChatterDetailHandler: UserTypedRouterHandler {
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    private lazy var memberListNonDepartmentConfig: MemberListNonDepartmentConfig? = {
        return userGeneralSettings?.memberListNonDepartmentConfig
    }()

    private let logger = Logger.log(GroupChatterDetailHandler.self, category: "IM.GroupChatterDetailHandler")

    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupChatterDetailBody, req: EENavigator.Request, res: Response) throws {
        let startTimeStamp = CACurrentMediaTime()
        guard !body.chatId.isEmpty,
            let chat = try userResolver.resolve(assert: ChatAPI.self).getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }
        guard let memberListNonDepartmentConfig else { throw UserScopeError.disposed }

        let isOwner = chat.ownerId == userResolver.userID
        let isAdmin = chat.isGroupAdmin
        NewChatSettingTracker.imGroupMemberView(chat: chat,
                                                myUserId: userResolver.userID,
                                                isOwner: isOwner,
                                                isAdmin: isAdmin)
        let tracker = GroupChatDetailTracker(chat: chat)
        tracker.start(startTimeStamp)
        tracker.getLocalChatEnd()

        // FG是True，是部门群，是群主/群管理员; 则走新的逻辑
        if chat.isDepartment,
           memberListNonDepartmentConfig.showDepartment,
           isOwner || chat.isGroupAdmin {
            logger.info("enter specialized group member controller", additionalData: ["chatID": body.chatId])

            // 特化的群成员列表
            res.end(resource: try self.specializedGroupChattersController(chat: chat,
                                                                      isShowMulti: body.isShowMulti,
                                                                      tracker: tracker))
        } else {
            logger.info("enter normal group member controller", additionalData: ["chatID": body.chatId])

            // 通用的群成员列表
            let vc = try self.normalChatChatterController(
                chat: chat,
                isShowMulti: body.isShowMulti,
                isAccessToAddMember: body.isAccessToAddMember,
                isAbleToSearch: body.isAbleToSearch,
                useLeanCell: body.useLeanCell,
                tracker: tracker)
            res.end(resource: vc)
        }
    }

    private func normalChatChatterController(chat: Chat,
                                             isShowMulti: Bool,
                                             isAccessToAddMember: Bool,
                                             isAbleToSearch: Bool,
                                             useLeanCell: Bool,
                                             tracker: GroupChatDetailTracker) throws -> UIViewController {
        tracker.initViewStart()
        defer {
            tracker.initViewEnd()
        }
        let passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        let user = passportUserService.user
        // 通用的群成员列表
        let viewModel = try ChatChatterControllerVM(
            userResolver: userResolver,
            chat: chat,
            appendTagProvider: nil,
            pushChatChatterListDepartmentName: try userResolver.userPushCenter.observable(for: PushChatChatterListDepartmentName.self),
            useLeanCell: useLeanCell,
            isAbleToSearch: isAbleToSearch,
            supportShowDepartment: true
        )
        return GroupChatterViewController(
            viewModel: viewModel,
            chatPushWrapper: try userResolver.resolve(assert: ChatPushWrapper.self, argument: chat),
            isOwner: chat.ownerId == user.userID,
            isAccessToAddMember: isAccessToAddMember,
            displayMode: isShowMulti ? .multiselect : .display,
            tracker: tracker,
            navi: self.userResolver.navigator)
    }

    private func specializedGroupChattersController(chat: Chat,
                                                    isShowMulti: Bool,
                                                    tracker: GroupChatDetailTracker) throws -> UIViewController {
        tracker.initViewStart()
        defer {
            tracker.initViewEnd()
        }

        let viewModel = try GroupChattersSpecializedViewModel(
            userResolver: userResolver,
            chat: chat,
            supportShowDepartment: true)

        return GroupChattersSpecializedController(viewModel: viewModel,
                                                  displayMode: isShowMulti ? .multiselect : .display,
                                                  tracker: tracker)
    }
}

final class TransferGroupOwnerHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: TransferGroupOwnerBody, req: EENavigator.Request, res: Response) throws {
        let startTimeStamp = CACurrentMediaTime()
        guard !body.chatId.isEmpty,
              let chat = try userResolver.resolve(assert: ChatAPI.self).getLocalChat(by: body.chatId) else {
                res.end(error: RouterError.invalidParameters("chatId"))
                return
        }
        let tracker = GroupChatDetailTracker(chat: chat)
        tracker.start(startTimeStamp)
        tracker.getLocalChatEnd()

        let currentChatterId = userResolver.userID

        let viewModel = try ChatChatterControllerVM(
            userResolver: userResolver,
            chat: chat,
            chatterFliter: { $0.id != currentChatterId },
            isDefaultSupportAlphabetical: false
        )

        let controller = GroupChatterViewController(
            viewModel: viewModel,
            chatPushWrapper: try userResolver.resolve(assert: ChatPushWrapper.self, argument: chat),
            mode: .transfer(body.mode),
            isOwner: chat.ownerId == currentChatterId,
            isAccessToAddMember: false,
            tracker: tracker,
            navi: userResolver.navigator
        )

        controller.tranferLifeCycleCallback = body.lifeCycleCallback
        tracker.viewDidLoadEnd()

        res.end(resource: controller)
    }
}

final class GroupAddAdminHandler: UserTypedRouterHandler {
    private(set) var disposeBag = DisposeBag()
    private static let logger = Logger.log(GroupChatterSelectHandler.self, category: "IM.Module.LarkChatSetting")

    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupAddAdminBody, req: EENavigator.Request, res: Response) throws {
        var groupChatterSelectBody = GroupChatterSelectBody(chatId: body.chatId, allowSelectNone: false)
        let maxNumber = body.chatCount > 5000 ? 20 : 10
        let maxSelectNumber = maxNumber - body.defaultUnableCancelSelectedIds.count
        let selectLimitDescription = BundleI18n.LarkChatSetting.Lark_Legacy_MaxGroupAdmins(maxNumber)
        groupChatterSelectBody.maxSelectModel = (maxSelectNumber, selectLimitDescription)
        groupChatterSelectBody.defaultUnableCancelSelectedIds = body.defaultUnableCancelSelectedIds
        groupChatterSelectBody.title = BundleI18n.LarkChatSetting.Lark_Legacy_AddGroupAdmins_Mobile
        let controller = body.controller
        let chatId = body.chatId
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        groupChatterSelectBody.onSelected = { (chatters) in
            chatAPI.patchChatAdminUsers(chatId: chatId,
                                        toAddUserIds: chatters.map({ $0.id }),
                                        toDeleteUserIds: [])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                if let window = controller?.currentWindow() {
                    UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAdminAdded, on: window)
                }
            }, onError: { (error) in
                if let window = controller?.currentWindow() {
                    UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAdminAddFailedToast, on: window, error: error)
                }
                Self.logger.error(
                    "patchChatAdminUsers failed!",
                    additionalData: ["chatId": chatId, "chatterIds": chatters.map({ $0.id }).joined(separator: ",")],
                    error: error
                )
            })
            .disposed(by: self.disposeBag)
        }
        res.redirect(body: groupChatterSelectBody)
    }
}

final class GroupChatterSelectHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupChatterSelectBody, req: EENavigator.Request, res: Response) throws {
        guard !body.chatId.isEmpty, let chat = try userResolver.resolve(assert: ChatAPI.self).getLocalChat(by: body.chatId) else {
                res.end(error: RouterError.invalidParameters("chatId"))
                return
        }

        let viewModel = try ChatChatterControllerVM(
            userResolver: userResolver,
            chat: chat,
            isOwnerSelectable: body.isOwnerCanSelect,
            showSelectedView: body.showSelectedView,
            maxSelectModel: body.maxSelectModel)

        let ownerId = chat.ownerId
        if body.isOwnerCanSelect {
            viewModel.defaultSelectedIds = body.defaultSelectedChatterIds
            viewModel.defaultUnableCancelSelectedIds = body.defaultUnableCancelSelectedIds
        } else {
            // 群主无自主选择能力，内部会默认选中群主，且不可取消
            viewModel.defaultSelectedIds = body.defaultSelectedChatterIds.filter { $0 != ownerId }
            viewModel.defaultUnableCancelSelectedIds = body.defaultUnableCancelSelectedIds.filter { $0 != ownerId }
        }
        let controller = ChatChatterSelectViewController(viewModel: viewModel, allowSelectNone: body.allowSelectNone)
        controller.onSelect = body.onSelected
        if let title = body.title {
            controller.titleString = title
        }

        res.end(resource: controller)
    }
}

enum GroupChatterControllerMode {
    case transfer(TransferGroupOwnerMode)
    case `default`
}
