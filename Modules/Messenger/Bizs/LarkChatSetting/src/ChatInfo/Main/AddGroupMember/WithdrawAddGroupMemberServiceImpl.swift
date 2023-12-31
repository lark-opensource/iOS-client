//
//  WithdrawAddGroupMemberServiceImpl.swift
//  LarkChat
//
//  Created by zc09v on 2019/6/25.
//
import UIKit
import Foundation
import EENavigator
import Swinject
import LKCommonsLogging
import RxSwift
import LarkActionSheet
import LarkUIKit
import UniverseDesignToast
import LarkAlertController
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignActionPanel
import LarkContainer
import LarkCore

final class WithdrawAddGroupMemberServiceImpl: WithdrawAddGroupMemberService {
    enum WithdrawEntityStatus {
        case other
        case onlyChatters([String]) /// 要撤销的只有人
        case onlyChats([String]) /// 要撤销的只有群
        case onlyDepartments([String]) /// 要撤销的只有部门
    }

    func checkWithdrawEntity(_ entity: WithdrawEntity) -> WithdrawEntityStatus {
        let chatterIds = entity.chatterIds
        let chatIds = entity.chatIds
        let departmentIds = entity.departmentIds

        if !chatterIds.isEmpty, chatIds.isEmpty, departmentIds.isEmpty {
            return .onlyChatters(Array(entity.chatterNames.values))
        }
        if chatterIds.isEmpty, !chatIds.isEmpty, departmentIds.isEmpty {
            return.onlyChats(Array(entity.chatNames.values))
        }
        if chatterIds.isEmpty, chatIds.isEmpty, !departmentIds.isEmpty {
            return .onlyDepartments(Array(entity.departmentNames.values))
        }
        return .other
    }

    static let logger = Logger.log(WithdrawAddGroupMemberServiceImpl.self, category: "Module.IM.Chat")
    private let chatAPI: ChatAPI
    private let chatterAPI: ChatterAPI
    private let withdrawExpirationByHour: Int32?
    private let disposeBag: DisposeBag = DisposeBag()
    private var withdrawing: Bool = false
    private let userResolver: UserResolver

    init(userResolver: UserResolver, chatAPI: ChatAPI, chatterAPI: ChatterAPI, withdrawExpirationByHour: Int32?) {
        self.userResolver = userResolver
        self.chatAPI = chatAPI
        self.chatterAPI = chatterAPI
        self.withdrawExpirationByHour = withdrawExpirationByHour
    }

    func withdrawMembers(chatId: String,
                         isThread: Bool,
                         entity: WithdrawEntity,
                         messageId: String,
                         messageCreateTime: TimeInterval,
                         way: AddMemeberWay,
                         from: NavigatorFrom,
                         sourveView: UIView?) {
        if self.withdrawIsExpired(createTime: messageCreateTime) {
            self.showTipConfirm(text: self.generateExpiredTip(), from: from)
            return
        }
        if entity.chatterIds.isEmpty, entity.chatIds.isEmpty, entity.departmentIds.isEmpty {
            WithdrawAddGroupMemberServiceImpl.logger.error("撤回群加人，没有有效 chatterIds/chatIds/departmentIds \(chatId)")
            return
        }
        switch way {
        case .viaQrCode, .viaLink, .viaShare:
            // 选择撤销邀请，还是停用分享
            self.showActionSheet(chatId: chatId,
                                 isThread: isThread,
                                 entity: entity,
                                 messageId: messageId,
                                 way: way,
                                 from: from,
                                 sourceView: sourveView)
        case .viaInvite:
            // 撤销
            self.withdrawMembers(chatId: chatId,
                                 isThread: isThread,
                                 entity: entity,
                                 from: from)
        }
    }

    // 过期判断
    private func withdrawIsExpired(createTime: TimeInterval) -> Bool {
        if let withdrawExpirationByHour = withdrawExpirationByHour {
            return Int(Date().timeIntervalSince1970 - createTime) > 3600 * withdrawExpirationByHour
        }
        WithdrawAddGroupMemberServiceImpl.logger.error("撤回群加人，没有有效的过期时间")
        return true
    }

    private func generateExpiredTip() -> String {
        guard let hours = self.withdrawExpirationByHour else {
            return ""
        }
        if hours <= 24 {
            return hours == 1 ? BundleI18n.LarkChatSetting.Lark_Group_RevokeTimeOutOneHour(hours) : BundleI18n.LarkChatSetting.Lark_Group_RevokeTimeOutHours(hours)
        } else {
            let day = Int(hours) / 24
            return day == 1 ? BundleI18n.LarkChatSetting.Lark_Group_RevokeTimeOutOneDay(day) : BundleI18n.LarkChatSetting.Lark_Group_RevokeTimeOutDays(day)
        }
    }

    private func showActionSheet(chatId: String,
                                 isThread: Bool,
                                 entity: WithdrawEntity,
                                 messageId: String,
                                 way: AddMemeberWay,
                                 from: NavigatorFrom,
                                 sourceView: UIView?) {
        let title = isThread ? BundleI18n.LarkChatSetting.Lark_Groups_RevokeCircleInviteButton : BundleI18n.LarkChatSetting.Lark_Group_RevokeConfirmation
        var disableShareText = ""
        if way == .viaQrCode {
            disableShareText = BundleI18n.LarkChatSetting.Lark_Group_RevokeQRCode
        } else if way == .viaLink {
            disableShareText = BundleI18n.LarkChatSetting.Lark_Chat_DeactivateGroupLink
        } else {
            disableShareText = isThread ? BundleI18n.LarkChatSetting.Lark_Groups_DeactivateCircleCardButton : BundleI18n.LarkChatSetting.Lark_Group_RevokeGroupCard
        }
        guard let sourceView = sourceView else {
            return
        }
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(
                                        isShowTitle: false,
                                        popSource: UDActionSheetSource(
                                            sourceView: sourceView,
                                            sourceRect: CGRect(x: sourceView.bounds.width / 2, y: sourceView.bounds.height, width: 0, height: 0),
                                            preferredContentWidth: 200,
                                            arrowDirection: .up)))
        actionSheet.addDefaultItem(text: title) { [weak self] in
               self?.withdrawMembers(chatId: chatId,
                                     isThread: isThread,
                                     entity: entity,
                                     from: from)
        }
        actionSheet.addDefaultItem(text: disableShareText) {[weak self] in
            self?.disableChatShared(messageId: messageId, view: from.fromViewController?.viewIfLoaded)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkChatSetting.Lark_Group_RevokeConfirmationCancel)
        self.userResolver.navigator.present(actionSheet, from: from)
    }

    // 停用分享
    private func disableChatShared(messageId: String, view: UIView?) {
        let hud = view.map { UDToast.showLoading(on: $0) }
        chatAPI.disableChatShared(messageId: messageId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak view] (_) in
                if let view = view {
                    hud?.showTips(with: BundleI18n.LarkChatSetting.Lark_Group_RevokeExpireToast, on: view)
                }
            }, onError: { [weak view] (error) in
                if let apiError = error.underlyingError as? APIError, let view = view {
                    hud?.showFailure(with: apiError.displayMessage, on: view, error: error)
                } else {
                    hud?.remove()
                }
            }).disposed(by: self.disposeBag)
    }

    // 撤销邀请
    private func withdrawMembers(chatId: String,
                                 isThread: Bool,
                                 entity: WithdrawEntity,
                                 from: NavigatorFrom) {
        guard !withdrawing else {
            return
        }
        withdrawing = true

        DelayLoadingObservableWraper
            .wraper(observable: chatAPI.checkChattersChatsDepartmentsInChat(chatterIds: entity.chatterIds,
                                                                            chatIds: entity.chatIds,
                                                                            departmentIds: entity.departmentIds,
                                                                            chatId: chatId),
                    showLoadingIn: from.fromViewController?.viewIfLoaded,
                    loadingText: BundleI18n.LarkChatSetting.Lark_Legacy_BaseUiLoading)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (results) in
                guard let self = self else { return }
                self.withdrawing = false

                let results = results.filter({ $0.value })
                if results.isEmpty {
                    // 都不在群里了
                    let status = self.checkWithdrawEntity(entity)
                    let text: String
                    switch status {
                    case .onlyChatters(let names):
                        text = names.count > 1 ? BundleI18n.LarkChatSetting.Lark_Group_RevokeMoreMemberNotExist : BundleI18n.LarkChatSetting.Lark_Group_RevokeOneMemberNotExist
                    case .onlyChats(let names):
                        text = names.count > 1 ? BundleI18n.LarkChatSetting.Lark_Server_AllGroupsMembersNoLongerInTheGroup
                            : BundleI18n.LarkChatSetting.Lark_Server_GroupMemberNoLongerInTheGroup
                    case .onlyDepartments(let names):
                        text = names.count > 1 ? BundleI18n.LarkChatSetting.Lark_Server_AllDepartmentsMembersNoLongerInTheGroup
                            : BundleI18n.LarkChatSetting.Lark_Server_DepartmentMemberNoLongerInTheGroup
                    case .other:
                        text = BundleI18n.LarkChatSetting.Lark_Group_RevokeMoreMemberNotExist
                    }
                    self.showTipConfirm(text: text, from: from)
                } else if results.count == 1, let withdrawId = results.keys.first {
                    // 只有1个人/群/部门还在群里
                    let type: WithdrawItemType
                    if entity.chatterIds.contains(withdrawId) {
                        type = .chatter
                    } else if entity.chatIds.contains(withdrawId) {
                        type = .chat
                    } else if entity.departmentIds.contains(withdrawId) {
                        type = .department
                    } else {
                        assertionFailure("id is not exist")
                        return
                    }

                    self.showConfirmToWithdraw(
                        chatId: chatId,
                        withdrawId: withdrawId,
                        withdrawItemType: type,
                        from: from
                    )
                } else {
                    let withdrawIds = Set(results.keys)
                    let chatterIds = entity.chatterIds.filter({ withdrawIds.contains($0) })
                    let chatIds = entity.chatIds.filter({ withdrawIds.contains($0) })
                    let departmentNames = entity.departmentNames.filter({ withdrawIds.contains($0.key) })
                    self.showWithdrawMembersViewController(
                        chatId: chatId,
                        isThread: isThread,
                        chatterIds: chatterIds,
                        chatIds: chatIds,
                        departmentNames: departmentNames,
                        from: from
                    )
                }
            }, onError: { [weak self] (error) in
                if let view = from.fromViewController?.viewIfLoaded {
                    UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Group_RevokeGeneralError, on: view, error: error)
                }
                WithdrawAddGroupMemberServiceImpl.logger.error("checkChattersChatsDepartmentsInChat发生错误 \(chatId)", error: error)
                self?.withdrawing = false
            }).disposed(by: self.disposeBag)
    }

    private func showWithdrawMembersViewController(chatId: String,
                                                   isThread: Bool,
                                                   chatterIds: [String],
                                                   chatIds: [String],
                                                   departmentNames: [String: String],
                                                   from: NavigatorFrom) {
        var hud: UDToast?
        var dataReturn = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !dataReturn, let view = from.fromViewController?.viewIfLoaded { // 500ms内不显示loading
                hud = UDToast.showLoading(on: view)
            }
        }

        let chattersObservable = chatterAPI.getChatters(ids: chatterIds)
        let chatsObservable = chatAPI.fetchChats(by: chatIds, forceRemote: false)
        Observable.zip(chattersObservable, chatsObservable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatterMap, chatMap) in
                dataReturn = true
                hud?.remove()
                guard let self = self else { return }

                var withdrawDataSource: [WithdrawItemCellPropsProtocol] = []
                withdrawDataSource += chatterMap.values.map { WithdrawItemCellProps(id: $0.id, avatarKey: $0.avatarKey, name: $0.displayName, type: .chatter, backupImage: nil) }
                withdrawDataSource += chatMap.values.map { WithdrawItemCellProps(id: $0.id, avatarKey: $0.avatarKey, name: $0.name, type: .chat, backupImage: nil) }
                withdrawDataSource += departmentNames.map { WithdrawItemCellProps(id: $0.key, avatarKey: "", name: $0.value, type: .department, backupImage: Resources.department_picker_default_icon) }

                let vc = WithdrawMembersViewController(
                    chatId: chatId,
                    isThread: isThread,
                    dataSource: withdrawDataSource,
                    chatAPI: self.chatAPI,
                    navi: self.userResolver.navigator
                )
                self.userResolver.navigator.present(
                    LkNavigationController(rootViewController: vc),
                    from: from,
                    prepare: { $0.modalPresentationStyle = .fullScreen }
                )
            }, onError: { (error) in
                dataReturn = true
                if let view = from.fromViewController?.viewIfLoaded {
                    hud?.showFailure(with: BundleI18n.LarkChatSetting.Lark_Group_RevokeGeneralError, on: view, error: error)
                }
                WithdrawAddGroupMemberServiceImpl.logger.error("showWithdrawMembersVC获取群成员失败 \(chatId)", error: error)
            }).disposed(by: self.disposeBag)
    }

    private func showConfirmToWithdraw(chatId: String,
                                       withdrawId: String,
                                       withdrawItemType: WithdrawItemType,
                                       from: NavigatorFrom) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChatSetting.Lark_Group_RevokeConfirmationTitle)
        alertController.setContent(text: BundleI18n.LarkChatSetting.Lark_Groups_CancelInvite)
        alertController.addSecondaryButton(text: BundleI18n.LarkChatSetting.Lark_Group_RevokeConfirmationCancel)
        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Groups_Revoke, dismissCompletion: {
            let hud = from.fromViewController?.viewIfLoaded.map { UDToast.showLoading(on: $0) }

            var chatterIds: [String] = []
            var chatIds: [String] = []
            var departmentIds: [String] = []
            switch withdrawItemType {
            case .chatter:
                chatterIds = [withdrawId]
            case .chat:
                chatIds = [withdrawId]
            case .department:
                departmentIds = [withdrawId]
            }
            self.chatAPI.withdrawAddChatters(chatId: chatId, chatterIds: chatterIds, chatIds: chatIds, departmentIds: departmentIds)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_) in
                    if let view = from.fromViewController?.viewIfLoaded {
                        hud?.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Group_RevokeSuccess, on: view)
                    }
                }, onError: { [weak self] (error) in
                    if let apiError = error.underlyingError as? APIError {
                        hud?.remove()
                        self?.showTipConfirm(text: apiError.displayMessage, from: from)
                    } else if let view = from.fromViewController?.viewIfLoaded {
                        hud?.showFailure(with: BundleI18n.LarkChatSetting.Lark_Group_RevokeGeneralError, on: view, error: error)
                    } else {
                        assertionFailure()
                        hud?.remove()
                    }
                }).disposed(by: self.disposeBag)
        })
        self.userResolver.navigator.present(alertController, from: from)
    }

    private func showTipConfirm(text: String, from: NavigatorFrom) {
        let alertController = LarkAlertController()
        alertController.setContent(text: text)
        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Group_RevokeIKnow)
        self.userResolver.navigator.present(alertController, from: from)
    }
}
