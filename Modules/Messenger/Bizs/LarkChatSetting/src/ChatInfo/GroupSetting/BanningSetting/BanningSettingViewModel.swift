//
//  BanningSettingViewModel.swift
//  BanningSettingController
//
//  Created by kongkaikai on 2019/3/8.
//  Copyright © 2019 kongkaikai. All rights reserved.
//

import UIKit
import Foundation
import LarkMessengerInterface
import RxSwift
import LarkModel
import RxCocoa
import LarkUIKit
import LKCommonsLogging
import LarkSDKInterface
import LarkCore
import EENavigator
import LarkFeatureGating
import LarkAccountInterface
import LarkContainer
import UniverseDesignToast

protocol BanningSettingViewModelDelegate: AnyObject {
    func onChatterItemSelected(item: BanningSettingItem)
}

final class BanningSettingViewModel: UserResolverWrapper {
    var userResolver: UserResolver

    private static let logger = Logger.log(
        BanningSettingViewModel.self,
        category: "LarkChat.BanningSettingViewModel")

    private var disposeBag = DisposeBag()

    private(set) var chat: Chat
    private var chatAPI: ChatAPI

    weak var delegate: BanningSettingViewModelDelegate?
    var viewWidth: CGFloat = 0 {
        didSet {
            refresh()
        }
    }

    // UI和选人需要的数据
    private(set) var datas: [BanningSettingSection] = []
    private var optionsSection = BanningSettingSection(type: .option)
    private var chatterSection = BanningSettingSection(type: .chatters)
    private var currentChatterId: String {
        userResolver.userID
    }

    private var chatters: [BanningSettingAvatarItem] = []
    private(set) var chatterIds: [String] = []

    // 下面是为了算Diff，defaultChatterIds是拉取的现有数据，不会变
    private(set) var defaultChatterIds: Set<String> = []
    private(set) var addChatterIds: Set<String> = []
    private(set) var removeChatterIds: Set<String> = []

    private var postType: Chat.PostType

    private lazy var editItem: BanningSettingEditItem = { self.createEditItem() }()
    private let ownerItem: BanningSettingItem
    var adminItems: [BanningSettingAvatarItem] = []

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()
    private let isThread: Bool

    weak var targetViewController: UIViewController? // 用于 viewModel 中 hud 展示

    init(chat: Chat, owner: Chatter, chatAPI: ChatAPI, userResolver: UserResolver) {
        self.chat = chat
        self.isThread = chat.chatMode == .threadV2
        self.ownerItem = BanningSettingAvatarItem(
            id: owner.id,
            avatarKay: owner.avatarKey,
            identifier: String(describing: BanningSettingAvatarCell.self))
        self.chatAPI = chatAPI
        self.userResolver = userResolver
        self.postType = chat.postType
        self.fetchChatAdminUsers()
    }

    func fetchChatAdminUsers() {
        let chatId = self.chat.id
        chatAPI.fetchChatAdminUsersWithLocalAndServer(chatId: chatId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                self.adminItems = res.map({ (chatter) -> BanningSettingAvatarItem in
                    BanningSettingAvatarItem(id: chatter.id,
                                             avatarKay: chatter.avatarKey,
                                             identifier: String(describing: BanningSettingAvatarCell.self))
                })
                self.refresh()
            }, onError: { (error) in
                Self.logger.error("fetchChatAdminUsers error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    // MARK: 以下数据加载
    private func refresh() {
        if optionsSection.items.last is BanningSettingChattersItem {
            optionsSection.items.removeLast()
        }
        if postType == .whiteList {
            let filterAdmins = filterDuplicates(chatters + adminItems)
            let section2 = [editItem, ownerItem] + filterAdmins
            let chattersItem = createChattersItem(chatters: section2, cellWidth: viewWidth - 32) // iOS15表格风格后，减去两边间距
            optionsSection.items.append(chattersItem)
        }
        datas = [optionsSection]
        _reloadData.onNext(())
    }

    func filterDuplicates(_ old: [BanningSettingAvatarItem]) -> [BanningSettingAvatarItem] {
        var new: [BanningSettingAvatarItem] = []
        var set = Set<String>()
        for i in old where !set.contains(i.id) {
            new.append(i)
            set.insert(i.id)
        }
        return new
    }

    private func createChattersItem(chatters: [BanningSettingItem], cellWidth: CGFloat) -> BanningSettingChattersItem {
        return BanningSettingChattersItem(
            identifier: String(describing: BanningSettingChattersCell.self),
            chatters: chatters,
            cellWidth: cellWidth,
            onItemSelected: { [weak self] (item) in
                self?.delegate?.onChatterItemSelected(item: item)
            })
    }

    private func createEditItem(with icon: UIImage? = Resources.banning_edit) -> BanningSettingEditItem {
        return BanningSettingEditItem(icon: icon, identifier: String(describing: BanningSettingEditCell.self))
    }

    func loadData() {
        loadOptions()
        refresh()

        let chatId = chat.id
        self.loadChatters()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.postType == .whiteList else { return }
                self.refresh()
            }, onError: { (error) in
                BanningSettingViewModel.logger.error(
                    "banning setting get 'whiteList' error",
                    additionalData: ["chatId": chatId],
                    error: error)
            }).disposed(by: disposeBag)
    }

    private func loadOptions() {
        let optionCellName = String(describing: BanningSettingOptionCell.self)

        let anyone = BanningSettingOptionItem<Chat.PostType>(
            isSelected: postType == .anyone,
            title:
                BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup,
            seletedType: .anyone,
            isSeparaterHidden: false,
            identifier: optionCellName)
        let onlyAdminTitle =
            BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin

        let onlyAdmin = BanningSettingOptionItem<Chat.PostType>(
            isSelected: postType == .onlyAdmin,
            title: onlyAdminTitle,
            seletedType: .onlyAdmin,
            isSeparaterHidden: false,
            identifier: optionCellName)

        let selectedMembers = BanningSettingOptionItem<Chat.PostType>(
            isSelected: postType == .whiteList,
            title: isThread ?
                BundleI18n.LarkChatSetting.Lark_Group_Topic_GroupSettings_MsgRestriction_SelectedMember :
                BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_MsgRestriction_SelectedMember,
            seletedType: .whiteList,
            isSeparaterHidden: postType != .whiteList,
            identifier: optionCellName)

        self.optionsSection.items = [anyone, onlyAdmin, selectedMembers]
    }

    private func loadChatters() -> Observable<Void> {
        let avatarCellName = String(describing: BanningSettingAvatarCell.self)

        let ownerId = chat.ownerId
        let currentChatterId = self.currentChatterId
        let adminItems = adminItems
        return self.chatAPI.fetchChatPostChatterIds(chatId: chat.id)
            .observeOn(MainScheduler.instance)
            .map({ [weak self] (chatterIds, chatterMaps) -> Void in
                // 群主和管理员默认发言，这里需要过滤掉
                let chatterIds = chatterIds.filter { id in
                    let isAdmin = adminItems.contains(where: { $0.id == id })
                    let isOwner = id == ownerId
                    return !isOwner && !isAdmin
                }
                self?.chatterIds = chatterIds
                self?.defaultChatterIds = Set(chatterIds)
                self?.chatters = chatterIds.compactMap { chatterMaps[$0] }
                    .map { BanningSettingAvatarItem(id: $0.id, avatarKay: $0.avatarKey, identifier: avatarCellName) }
            })
    }

    // MARK: 事件处理
    func setOption(_ postType: Chat.PostType) {
        ChatSettingTracker.groupSettingPermission(chatID: chat.id, type: postType, chatType: chat.chatMode)
        self.postType = postType
        loadOptions()
        refresh()
    }

    func updateSeletedChatters(_ chatters: [Chatter]) {
        let avatarCellName = String(describing: BanningSettingAvatarCell.self)
        let items = chatters.map { BanningSettingAvatarItem(id: $0.id, avatarKay: $0.avatarKey, identifier: avatarCellName) }
        let chatterIds = items.map { $0.id }

        removeChatterIds = removeChatterIds.union(defaultChatterIds.subtracting(chatterIds))
        addChatterIds = addChatterIds.union(Set(chatterIds).subtracting(defaultChatterIds))

        self.chatterIds = chatterIds
        self.chatters = items
        refresh()
    }

    func confirmOption() {
        if self.postType == chat.postType, self.addChatterIds.isEmpty, self.removeChatterIds.isEmpty { return }

        ChatSettingTracker.newBanningSettingType(postType,
                                                 memberCount: Int(chat.userCount),
                                                 enabledMbrCount: self.addChatterIds.count,
                                                 chatId: chat.id)
        let chatId = self.chat.id
        let postType = self.postType
        var addChatterIds = Array(self.addChatterIds)
        var removeChatterIds = Array(self.removeChatterIds)
        let ownerId = chat.ownerId
        let adminIds = adminItems.map({ $0.id })
        // 接口兜底：添加和要删除的人员里移除掉群主和管理员
        removeChatterIds.removeAll(where: { id in id == ownerId || adminIds.contains(where: { $0 == id }) })
        addChatterIds.removeAll(where: { id in id == ownerId || adminIds.contains(where: { $0 == id }) })
        NewChatSettingTracker.messageRestrictionClickTrack(postType: postType,
                                                           chat: chat,
                                                           myUserId: currentChatterId,
                                                           isOwner: chat.ownerId == currentChatterId)
        chatAPI.updateChatPostChatters(chatId: chatId,
                                       postType: postType,
                                       addChatterIds: addChatterIds,
                                       removeChatterIds: removeChatterIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.loadData()
            }, onError: { (error) in
                BanningSettingViewModel.logger.error(
                    "banning setting update post type  error",
                    additionalData: [
                        "chatId": chatId,
                        "postType": "\(postType)",
                        "addChatterIds": self.addChatterIds.joined(separator: ","),
                        "removeChatterIds": self.removeChatterIds.joined(separator: ",")],
                    error: error)
                if let apiError = error.underlyingError as? APIError, let window = self.targetViewController?.currentWindow() {
                    switch apiError.type {
                    case .noPermission(let message):
                        UDToast.showFailure(with: message, on: window, error: error)
                    default:
                        break
                    }
                }
            }).disposed(by: disposeBag)
    }
}
