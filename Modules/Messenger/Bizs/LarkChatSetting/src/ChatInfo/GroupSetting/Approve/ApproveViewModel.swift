//
//  ApproveViewModel.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/29.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import UniverseDesignToast
import LKCommonsLogging
import LarkSDKInterface
import RustPB
import LarkContainer
import LarkFeatureGating
import LarkAccountInterface
import LarkMessageCore

final class ApproveViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(ApproveViewModel.self, category: "LarkChat.ApproveViewModel")

    private let disposeBag = DisposeBag()
    let chat: Chat
    private let chatAPI: ChatAPI
    private(set) var isOn: Bool = false
    private(set) var hasMore: Bool = false
    private var cursor: String?
    private var isLoading: Bool = false
    private var currentChatterId: String { userResolver.userID }

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    var deleteItem: Driver<(ApproveItem, Int)> { return _deleteItem.asDriver(onErrorRecover: { _ in .empty() }) }
    private var _deleteItem = PublishSubject<(ApproveItem, Int)>()

    var datas: [ApproveItem] = []

    weak var targetViewController: UIViewController? // 用于 viewModel 中 hud 展示
    // 在列表头部展示描述信息
    var headerTitle: String? {
        guard Chat.isTeamEnable(fgService: self.userResolver.fg),
              chat.isAssociatedTeam else { return nil }
        if isOn || datas.isEmpty {
            return nil
        } else {
            return BundleI18n.LarkChatSetting.Project_T_MemberRequest_FollowingUserNeedApproval_Text(self.datas.count)
        }
    }

    init(chat: Chat, chatAPI: ChatAPI, userResolver: UserResolver) {
        self.chat = chat
        self.isOn = chat.addMemberApply == .needApply
        self.chatAPI = chatAPI
        self.userResolver = userResolver
    }

    func loadData(_ isMore: Bool = false) {
        guard !isLoading else { return }
        isLoading = true

        let chatId = chat.id
        let shouldCleanOldData = !isMore || self.cursor == nil
        chatAPI.getAddChatChatterApply(chatId: chat.id, cursor: isMore ? self.cursor : nil)
            .subscribe(onNext: { [weak self] (result) in
                self?.parserResult(result, shouldCleanOldData)
                self?.isLoading = false
            }, onError: { [weak self] (error) in
                self?.isLoading = false
                self?._reloadData.onNext(())
                DispatchQueue.main.async {
                    if let view = self?.targetViewController?.view {
                        UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: view, error: error)
                    }
                }
                ApproveViewModel.logger.error("get apply error", additionalData: ["chatId": chatId], error: error)
            }).disposed(by: disposeBag)
    }

    private func parserResult(_ result: RustPB.Im_V1_GetAddChatChatterApplyResponse, _ shouldCleanOldData: Bool) {
        hasMore = result.hasMore_p
        cursor = result.nextCursor

        let chatChatters = result.entity.chatChatters[chat.id]?.chatters
        func chatter(with id: String) -> Chatter? {
            guard let pbChatter = chatChatters?[id] ?? result.entity.chatters[id] else {
                ApproveViewModel.logger.error(
                    "get chatter error",
                    additionalData: [
                        "chatID": self.chat.id,
                        "chatterID": id
                    ]
                )
                return nil
            }

            return Chatter.transform(pb: pbChatter)
        }

        let items: [ApproveItem] = result.applies.compactMap {
            ApproveItem(pb: $0, invitee: chatter(with: $0.inviteeID), inviter: chatter(with: $0.inviterID))
        }

        self.datas = shouldCleanOldData ? items : datas + items
        _reloadData.onNext(())
    }

    private func updateStatus(_ status: RustPB.Basic_V1_AddChatChatterApply.Status, _ item: ApproveItem, tips: String) {
        let hud = targetViewController?.view.map { UDToast.showLoading(on: $0) }
        chatAPI.updateAddChatChatterApply(chatId: chat.id, inviteeId: item.id, status: status)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak hud] _ in
                guard let self = self, let index = self.datas.firstIndex(where: { $0.id == item.id }) else { return }
                if let view = self.targetViewController?.view {
                    hud?.showTips(with: tips, on: view, delay: 1)
                }
                self.datas.remove(at: index)
                self._deleteItem.onNext((item, index))
            }, onError: { [weak self, weak hud] (error) in
                guard let self = self else { return }
                ApproveViewModel.logger.error(
                    "update apply status error",
                    additionalData: ["chatID": self.chat.id],
                    error: error
                )
                hud?.remove()
                if let apiError = error.underlyingError as? APIError, let window = self.targetViewController?.currentWindow() {
                    switch apiError.type {
                    case .addChatChatterApplyAreadyProcessed(let message):
                        UDToast.showFailure(with: message, on: window, error: error)
                    default:
                        break
                    }
                }
            }).disposed(by: disposeBag)
    }

    func reject(_ item: ApproveItem?) {
        guard let item = item else { return }
        ChatSettingTracker.trackGroupApplicationReject()
        self.updateStatus(.refused, item, tips: BundleI18n.LarkChatSetting.Lark_Group_DeclineJoinGroupRequestToast)
        NewChatSettingTracker.trackJoinApplicationClick(chat: self.chat, approve: false)
    }

    func accept(_ item: ApproveItem?) {
        guard let item = item else { return }
        ChatSettingTracker.trackGroupApplicationPass()
        self.updateStatus(.approved, item, tips: BundleI18n.LarkChatSetting.Lark_Group_ApproveJoinGroupRequestToast)
        NewChatSettingTracker.trackJoinApplicationClick(chat: self.chat, approve: true)
    }

    func switchStatus(_ isOn: Bool) {
        ChatSettingTracker.newTrackApproveInvitationSetting(isOn, memberCount: Int(chat.userCount), chatId: chat.id)
        let chatId = chat.id
        imGroupManageClickTrack(clickType: "join_group_restriction",
                                extra: ["status": isOn ? "off_to_on" : "on_to_off"])
        chatAPI.updateChat(chatId: chatId, applyType: isOn ? .needApply : .noApply)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.isOn = isOn
                self?.loadData()
            }, onError: { [weak self] (error) in
                self?.isOn = !isOn
                self?._reloadData.onNext(())

                if let view = self?.targetViewController?.view {
                    UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: view, error: error)
                }
                ApproveViewModel.logger.error("update apply error", additionalData: ["chatId": chatId], error: error)
            })
            .disposed(by: disposeBag)
    }
}

private extension ApproveViewModel {
    func imGroupManageClickTrack(clickType: String, target: String = "none", extra: [String: String] = [:]) {
        var extra = extra
        extra["target"] = target
        NewChatSettingTracker.imGroupManageClick(
            chat: self.chat,
            myUserId: self.currentChatterId,
            isOwner: currentChatterId == chat.ownerId,
            isAdmin: chat.isGroupAdmin,
            clickType: clickType,
            extra: extra)
    }
}
