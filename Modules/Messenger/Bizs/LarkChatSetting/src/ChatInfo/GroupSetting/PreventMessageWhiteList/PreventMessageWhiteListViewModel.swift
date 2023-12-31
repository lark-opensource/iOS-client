//
//  PreventMessageWhiteListViewModel.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/5/9.
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

protocol PreventMessageWhiteListViewModelDelegate: AnyObject {
    func onChatterItemSelected(item: BanningSettingItem)
}

class PreventMessageWhiteListViewModel: UserResolverWrapper {
    public static let logger = Logger.log(PreventMessageWhiteListViewModel.self, category: "ChatSetting")
    enum SelectedType: Equatable {
        case noBody
        case ownerOrAdmin
        case whiteList
        case unknown
    }

    var userResolver: UserResolver
    private(set) var currentSelectType: SelectedType
    // 初始选项
    private let defaultSelectType: SelectedType
    private(set) var whiteListChatters: [Chatter] = []
    private(set) var chat: Chat

    private(set) var optionsSection = BanningSettingSection(type: .option)

    private lazy var editItem: BanningSettingEditItem = {
        return BanningSettingEditItem(icon: Resources.banning_edit,
                                      identifier: String(describing: BanningSettingEditCell.self))
    }()

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    private(set) var viewWidth: CGFloat = 0
    weak var delegate: PreventMessageWhiteListViewModelDelegate?

    // 初始的白名单ids
    let defaultWhiteListChatterIds: Set<String>
    // 本次选择的白名单ids
    private(set) var selectedChatterIds: Set<String>?
    private let disposeBag: DisposeBag = DisposeBag()

    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?

    init(chat: Chat, userResolver: UserResolver) {
        self.chat = chat
        self.userResolver = userResolver
        var tempDefaultWhiteListChatterIds: Set<String> = []
        switch self.chat.restrictedModeSetting.whiteListSetting.level {
        case .noMember:
            self.defaultSelectType = .noBody
        case .onlyAdminAndOwner:
            self.defaultSelectType = .ownerOrAdmin
        case .memberList:
            self.defaultSelectType = .whiteList
            tempDefaultWhiteListChatterIds = Set(self.chat.restrictedModeSetting.whiteListSetting.memberListUserIds.map({ return "\($0)" }))
        case .unknown:
            self.defaultSelectType = .unknown
        @unknown default:
            self.defaultSelectType = .unknown
        }
        self.defaultWhiteListChatterIds = tempDefaultWhiteListChatterIds
        self.currentSelectType = self.defaultSelectType
    }

    func setup(viewWidth: CGFloat) {
        self.viewWidth = viewWidth
        self.loadOptions()
        self.fetchDefaultWhiteListChatters()
    }

    private func fetchDefaultWhiteListChatters() {
        guard !self.defaultWhiteListChatterIds.isEmpty else {
            return
        }
        self.chatterAPI?.fetchChatChatters(ids: Array(defaultWhiteListChatterIds), chatId: chat.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chatterMap in
                guard self?.selectedChatterIds == nil else {
                    // 在默认白名单拉取过程中，用户提早进入了选人页面，并完成了操作，默认拉取的数据就不处理了
                    Self.logger.info("preventMessageWhiteList trace fetchDefaultWhiteListChatters after selectedChatterIds \(self?.chat.id ?? "")")
                    return
                }
                var chatters: [Chatter] = []
                for chatterId in self?.defaultWhiteListChatterIds ?? [] {
                    if let chatter = chatterMap[chatterId] {
                        chatters.append(chatter)
                    } else {
                        Self.logger.error("preventMessageWhiteList trace fetchDefaultWhiteListChatters miss \(self?.chat.id ?? "") \(chatterId)")
                    }
                }
                self?.whiteListChatters = chatters
                self?.loadWhiteListOption()
                self?._reloadData.onNext(())
            }).disposed(by: self.disposeBag)
    }

    func setOption(_ selected: SelectedType) -> Bool {
        guard self.currentSelectType != selected else {
            return false
        }
        self.currentSelectType = selected
        loadOptions()
        return true
    }

    func updateSeletedChatters(_ chatters: [Chatter]) {
        self.selectedChatterIds = Set<String>(chatters.map({ return $0.id }))
        self.whiteListChatters = chatters
        self.loadWhiteListOption()
    }

    func beChanged() -> Bool {
        switch (self.currentSelectType, self.defaultSelectType) {
        case (.noBody, .noBody), (.ownerOrAdmin, .ownerOrAdmin), (.unknown, .unknown):
            return false
        case (.whiteList, .whiteList):
            if let selectedChatterIds = self.selectedChatterIds {
                // 选的人和之前一样
                if selectedChatterIds == self.defaultWhiteListChatterIds {
                    return false
                }
            } else {
                // 或者没选(没做任何操作)
                return false
            }
            return true
        default:
            return true
        }
    }

    func confirm(success: @escaping () -> Void, failed: @escaping (Error) -> Void, showLoadingIn: UIView?) {
        guard let chatAPI = chatAPI else {
            failed(APIError(type: APIError.TypeEnum.unknowError))
            return
        }
        var setting: Chat.RestrictedModeSetting = Chat.RestrictedModeSetting()
        switch self.currentSelectType {
        case .noBody:
            setting.whiteListSetting.level = .noMember
        case .ownerOrAdmin:
            setting.whiteListSetting.level = .onlyAdminAndOwner
        case .whiteList:
            setting.whiteListSetting.level = .memberList
            if let selectedChatterIds = self.selectedChatterIds {
                let removeChatterIds = self.defaultWhiteListChatterIds.subtracting(selectedChatterIds)
                let addChatterIds = selectedChatterIds.subtracting(self.defaultWhiteListChatterIds)
                setting.whiteListSetting.addUserIds = addChatterIds.compactMap({ Int64($0) })
                setting.whiteListSetting.delUserIds = removeChatterIds.compactMap({ Int64($0) })
            }
        case .unknown:
            failed(APIError(type: APIError.TypeEnum.unknowError))
            return
        }
        DelayLoadingObservableWraper.wraper(observable: chatAPI.updateChat(chatId: self.chat.id, restrictedModeSetting: setting),
                                            delay: 1,
                                            showLoadingIn: showLoadingIn)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                success()
            }, onError: { error in
                failed(error)
            }).disposed(by: self.disposeBag)
    }

    func update(viewWidth: CGFloat) {
        self.loadWhiteListOption()
    }

    func selectedEmptyWhiteList() -> Bool {
        if let selectedChatterIds = self.selectedChatterIds {
            //本次选过人
            if selectedChatterIds.isEmpty {
                //但谁都没选
                return true
            }
        } else if self.defaultWhiteListChatterIds.isEmpty {
            // 本次没选过，且之前也没有
            return true
        }
        return false
    }

    private func loadOptions() {
        let optionCellName = String(describing: BanningSettingOptionCell.self)

        let nobody = BanningSettingOptionItem<SelectedType>(
            isSelected: self.currentSelectType == .noBody,
            title: BundleI18n.LarkChatSetting.Lark_GroupManagement_BypassRestrictedMode_NoOne_Option,
            seletedType: .noBody,
            isSeparaterHidden: false,
            identifier: optionCellName)

        let ownerOrAdmin = BanningSettingOptionItem<SelectedType>(
            isSelected: self.currentSelectType == .ownerOrAdmin,
            title: BundleI18n.LarkChatSetting.Lark_GroupManagement_BypassRestrictedMode_OwnerAdmin_Option,
            seletedType: .ownerOrAdmin,
            isSeparaterHidden: false,
            identifier: optionCellName)

        let whiteList = BanningSettingOptionItem<SelectedType>(
            isSelected: self.currentSelectType == .whiteList,
            title: BundleI18n.LarkChatSetting.Lark_GroupManagement_BypassRestrictedMode_SelectedMembers_Option,
            seletedType: .whiteList,
            isSeparaterHidden: self.currentSelectType != .whiteList,
            identifier: optionCellName)

        self.optionsSection.items = [nobody, ownerOrAdmin, whiteList]

        self.loadWhiteListOption()
    }

    private func loadWhiteListOption() {
        if optionsSection.items.last is BanningSettingChattersItem {
            optionsSection.items.removeLast()
        }
        if self.currentSelectType == .whiteList {
            var chatters: [BanningSettingItem] = [self.editItem]
            let avatarItems = whiteListBanningSettingAvatarItems()
            if !avatarItems.isEmpty {
                chatters.append(contentsOf: avatarItems)
            }
            let chattersItem = BanningSettingChattersItem(identifier: String(describing: BanningSettingChattersCell.self),
                                                          chatters: chatters,
                                                          cellWidth: viewWidth - 32,
                                                          onItemSelected: { [weak self] (item) in
                self?.delegate?.onChatterItemSelected(item: item)
            })
            self.optionsSection.items.append(chattersItem)
        }
        self._reloadData.onNext(())
    }

    private func whiteListBanningSettingAvatarItems() -> [BanningSettingAvatarItem] {
        return self.whiteListChatters.map { chatter in
            return BanningSettingAvatarItem(id: chatter.id,
                                            avatarKay: chatter.avatarKey,
                                            identifier: String(describing: BanningSettingAvatarCell.self))
        }
    }
}
