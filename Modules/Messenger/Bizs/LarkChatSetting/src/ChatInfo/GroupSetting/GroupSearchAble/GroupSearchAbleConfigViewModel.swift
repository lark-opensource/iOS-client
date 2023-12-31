//
//  GroupSearchAbleConfigViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/6/9.
//

import UIKit
import Foundation
import LKCommonsLogging
import LarkSDKInterface
import LarkContainer
import LarkMessengerInterface
import LarkAccountInterface
import LarkFeatureGating
import UniverseDesignToast
import LarkUIKit
import EENavigator
import LarkModel
import LarkCore
import RxSwift
import RxCocoa

final class GroupSearchAbleConfigViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(GroupSearchAbleConfigViewModel.self, category: "LarkChatSetting")
    private(set) var items: CommonDatasource!
    private let disposeBag = DisposeBag()
    weak var controller: UIViewController?
    private(set) lazy var chatModel: LarkModel.Chat = {
        chatWrapper.chat.value
    }()
    var canSaveChange: Bool {
        if self.switchControlIsOn {
            return !self.chatModel.avatarKey.isEmpty && !self.chatModel.name.isEmpty &&
                !self.chatModel.description.isEmpty
        }
        return true
    }
    private let originAvatarKey: String
    private let originName: String
    var isModifyName: Bool {
        originName == self.chatModel.name
    }
    var isModifyAvatar: Bool {
        originAvatarKey == self.chatModel.avatarKey
    }
    private let scheduler = SerialDispatchQueueScheduler(qos: .default)
    var reloadData: Driver<Void> { _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    private let chatWrapper: ChatPushWrapper
    var switchControlIsChange = false
    private var switchControlIsOn: Bool {
        didSet {
            guard oldValue != switchControlIsOn else { return }
            switchControlIsChange = true
            self.items = self.structureItems()
            self._reloadData.onNext(())
        }
    }
    private weak var control: UIView?
    private var isOwner: Bool {
        return currentChatterId == chatModel.ownerId
    }
    private var currentChatterId: String {
        return self.userResolver.userID
    }
    private var hasAccess: Bool {
        return chatModel.isAllowPost && (isOwner || isGroupAdmin || !chatModel.offEditGroupChatInfo)
    }
    // 是否是群管理
    var isGroupAdmin: Bool {
        return chatModel.isGroupAdmin
    }

    init(resolver: UserResolver, chatWrapper: ChatPushWrapper) {
        self.chatWrapper = chatWrapper
        self.originName = chatWrapper.chat.value.name
        self.originAvatarKey = chatWrapper.chat.value.avatarKey
        self.switchControlIsOn = chatWrapper.chat.value.isPublic
        self.userResolver = resolver
        self.items = self.structureItems()
        self.fetchData()
    }

    func fetchData() {
        let chatId = chatModel.id
        let fetchRemoteChat: Observable<Chat> = chatAPI?.fetchChat(by: chatId, forceRemote: true)
            .compactMap { $0 } ?? .empty()
        // 拉取chat
        Observable.merge([fetchRemoteChat, chatWrapper.chat.asObservable()])
            .observeOn(scheduler)
            .filter { $0.id == chatId }
            .subscribe(onNext: { [weak self] (chat) in
                guard let `self` = self else { return }
                self.chatModel = chat
                self.items = self.structureItems()
                self._reloadData.onNext(())
            }).disposed(by: self.disposeBag)
    }

    func structureItems() -> CommonDatasource {
        let sections: CommonDatasource = [
            self.configGroupSearchAbleSection(),
            self.groupCardSettingSection()
        ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        return sections
    }

    func saveChange(_ completion: @escaping () -> Void) {
        self.switchGroupPublicEnable(newStatus: switchControlIsOn, completion: completion)
    }
}

extension GroupSearchAbleConfigViewModel {
    func switchGroupPublicEnable(switchControl: LoadingSwitch? = nil,
                                 newStatus: Bool,
                                 completion: @escaping () -> Void) {
        let chatId = chatModel.id
        chatAPI?.updateChat(chatId: chatModel.id,
                           isPublic: newStatus,
                           addMemberPermission: newStatus ? .allMembers : nil,
                           shareCardPermission: newStatus ? .allowed : nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let window = self?.controller?.view.window else {
                    assertionFailure("lose window to jump")
                    return
                }
                UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_Group_SavedToast, on: window)
                completion()
            }, onError: { [weak self] error in
                Self.logger.error("updateChat isPublic failed", additionalData: ["chatId": chatId], error: error)
                switchControl?.setOn(!newStatus, animated: true)
                guard let window = self?.controller?.view.window else {
                    assertionFailure("lose window to jump")
                    return
                }
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .newVersionFeature(let message):
                        UDToast.showFailure(with: message, on: window, error: error)
                    default:
                        UDToast.showFailure(
                            with: BundleI18n.LarkChatSetting.Lark_Legacy_NetworkOrServiceError,
                            on: window,
                            error: error
                        )
                    }
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_NetworkOrServiceError,
                                        on: window)
                }
            }).disposed(by: self.disposeBag)
    }
}

// section 组装的扩展
private extension GroupSearchAbleConfigViewModel {
    // 群可被搜索Seciton
    func configGroupSearchAbleSection() -> CommonSectionModel {
        CommonSectionModel(
            title: nil,
            items: [
                configGroupSearchAbleItem()
                ].compactMap { $0 }
        )
    }

    // 群名片设置section
    func groupCardSettingSection() -> CommonSectionModel {
        guard switchControlIsOn else {
            return CommonSectionModel(items: [])
        }
        return CommonSectionModel(
            title:
                BundleI18n.LarkChatSetting.Lark_Group_GroupDetailsTitle,
            items: [groupInfoPhotoItem(),
                    groupInfoNameItem(),
                    groupInfoDescriptionItem()].compactMap { $0 }
        )
    }

    func configGroupSearchAbleItem() -> GroupSettingItemProtocol {
        return ConfigGroupSearchAbleItem(
            type: .groupSearchAble,
            cellIdentifier: ConfigGroupSearchAbleCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Group_FindGroupViaSearchTitle,
            detail:
                BundleI18n.LarkChatSetting.Lark_Group_FindGroupViaSearchDesc,
            status: self.switchControlIsOn
        ) { [weak self] (_, isOn) in
            guard let self = self else { return }
            self.switchControlIsOn = isOn
        }
    }

    private func groupInfoPhotoItem() -> GroupSettingItemProtocol? {
        let chatId = chatModel.id
        let item = GroupInfoPhotoItem(
            type: .groupInfoPhoto,
            cellIdentifier: GroupInfoPhotoCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupPhoto,
            chatID: chatModel.id,
            avatarKey: chatModel.avatarKey,
            isTapEnabled: chatModel.oncallId.isEmpty) { [weak self] _ in
            self?.previewAvatar()
            guard let buriedPointChat = self?.chatModel else { return }
            NewChatSettingTracker.imChatSettingEditAvatarClick(chatId: chatId, isAdmin: self?.isOwner ?? false, chat: buriedPointChat)
        }
        return item
    }

    private func groupInfoNameItem() -> GroupSettingItemProtocol? {
        let chatId = chatModel.id
        let attributedTitle = NSMutableAttributedString(string: BundleI18n.LarkChatSetting.Lark_Legacy_GroupName)
        attributedTitle.append(NSAttributedString(string: " *", attributes: [.foregroundColor: UIColor.ud.colorfulRed]))

        let item = GroupInfoNameItem(
            type: .groupSearchInfoName,
            cellIdentifier: GroupInfoNameCell.lu.reuseIdentifier,
            style: .auto,
            attributedTitle: attributedTitle,
            name: chatModel.displayName,
            hasAccess: true,
            isTapEnabled: chatModel.oncallId.isEmpty) { [weak self] _ in
                guard let vc = self?.controller else {
                    assertionFailure("缺少路由跳转的targetVC")
                    return
                }
                NewChatSettingTracker.imChatSsettingEditTitleClick(chatId: chatId, isAdmin: self?.isOwner ?? false)
                self?.userResolver.navigator.push(body: ModifyGroupNameBody(chatId: chatId, title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupName), from: vc)
        }
        return item
    }

    private func groupInfoDescriptionItem() -> GroupSettingItemProtocol? {
        let chatId = chatModel.id
        if !self.chatModel.isCrypto {
            let descriptionText = chatModel.description
            let title = BundleI18n.LarkChatSetting.Lark_Legacy_GroupDescription
            let attributedTitle = NSMutableAttributedString(string: title)
            attributedTitle.append(NSAttributedString(string: " *", attributes: [.foregroundColor: UIColor.ud.colorfulRed]))

            let description = GroupInfoDescriptionItem(
                type: .groupSearchInfoDescription,
                cellIdentifier: GroupInfoDescriptionCell.lu.reuseIdentifier,
                style: .auto,
                attributedTitle: attributedTitle,
                description: descriptionText) { [weak self] _ in
                guard let vc = self?.controller else {
                    assertionFailure("缺少路由跳转的targetVC")
                    return
                }
                self?.userResolver.navigator.push(body: ModifyGroupDescriptionBody(chatId: chatId,
                                                                       title: title
                ), from: vc)
            }
            return description
        }
        return nil
    }
}

extension GroupSearchAbleConfigViewModel {
    // 群头像编辑
    func previewAvatar() {
        guard let vc = self.controller else {
            assertionFailure("缺少路由跳转的targetVC")
            return
        }

        if hasAccess {
            self.userResolver.navigator.present(body: CustomizeGroupAvatarBody(chat: chatModel, avatarDrawStyle: .transparent), wrap: LkNavigationController.self, from: vc) { vc in
                vc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            }
            ChatSettingTracker.trackGroupProfileNameEnter(chat: chatModel)
        } else {
            let asset = LKDisplayAsset.createAsset(avatarKey: chatModel.avatarKey, chatID: chatModel.id).transform()
            let body = PreviewImagesBody(assets: [asset],
                                         pageIndex: 0,
                                         scene: .normal(assetPositionMap: [:], chatId: nil),
                                         shouldDetectFile: chatModel.shouldDetectFile,
                                         canShareImage: false,
                                         canEditImage: false,
                                         canTranslate: userResolver.fg.staticFeatureGatingValue(with: .init(key: .imageViewerInOtherScenesTranslateEnable)),
                                         translateEntityContext: (nil, .other))
            self.userResolver.navigator.present(body: body, from: vc)
        }
    }
}
