//
//  GroupInfoViewModel.swift
//  Lark
//
//  Created by kongkaikai on 2018/5/6.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkUIKit
import EENavigator
import LarkCore
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkFeatureGating
import LKCommonsLogging
import LarkContainer
import LarkAppLinkSDK
import LarkAppConfig
import LarkEnv
import UniverseDesignDialog
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkAccountInterface
import LarkSetting
import LarkEMM
import LarkSensitivityControl
import ServerPB

final class GroupInfoViewModel: UserResolverWrapper {
    private static let logger = Logger.log(GroupInfoViewModel.self, category: "Module.IM.LarkChatSetting")

    var userResolver: LarkContainer.UserResolver

    private(set) var disposeBag = DisposeBag()
    private(set) var items: CommonDatasource!
    private var isOwner: Bool {
        return currentChatterId == chatModel.ownerId
    }

    private let chatWrapper: ChatPushWrapper
    private let chatAPI: ChatAPI
    private let currentChatterId: String
    private let isThread: Bool

    var chatModel: LarkModel.Chat

    weak var targetVC: UIViewController?

    private var hasAccess: Bool {
        return chatModel.isAllowPost && (isOwner || isGroupAdmin || !chatModel.offEditGroupChatInfo)
    }
    // 是否是群管理
    var isGroupAdmin: Bool {
        return chatModel.isGroupAdmin
    }

    // 前端判断是否允许有群邮箱地址
    private var groupEmailAddressEnable: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: "im.chat.setting.group.mail")
        && !chatModel.isCrypto // 密盾聊
        && !chatModel.isPrivateMode // 密聊
        && chatModel.chatMode != .threadV2 // 话题群
        && (!chatModel.isOncall || chatModel.oncallId.isEmpty || chatModel.oncallId == "0") // Oncall群
        && !chatModel.isCustomerService // 客服群
        && !chatModel.isCrossTenant // 外部群
        && !chatModel.isSuper // 超大群
    }
    // “群邮箱”功能是否应该展示
    // 租户没有域名等情况，前端无法感知，实现方案为：请求Mail后端接口后再决定是否展示
    private var groupEmailAddressShouldShow = false
    // 当前是否已获取群邮箱地址
    private var hasEmailAddress: Bool = false
    // 群邮箱地址
    private var groupEmailAddress: String = ""
    // 群邮箱权限（用于群邮箱点击后展示，普通群成员也需要展示）
    private var groupEmailSetting: ServerPB_Mail_entities_MailGroupSetting?

    let navigationTitle: String
    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()
    // 更新cell高度
    var updateHeight: Driver<Void> { return _updateHeight.asDriver(onErrorJustReturn: ()) }
    private(set) var _updateHeight = PublishSubject<Void>()

    var cannotEditAlert: Driver<Void> { return _cannotEditAlert.asDriver(onErrorJustReturn: ()) }
    private var _cannotEditAlert = PublishSubject<Void>()
    private var isShowChatBgImage = false

    init(resolver: UserResolver,
         chatWrapper: ChatPushWrapper,
         currentChatterId: String,
         chatAPI: ChatAPI) {
        self.chatWrapper = chatWrapper
        self.chatModel = chatWrapper.chat.value
        self.isThread = (chatWrapper.chat.value.chatMode == .threadV2)
        self.navigationTitle = self.isThread ?
            BundleI18n.LarkChatSetting.Lark_Groups_ChannelInfo :
            BundleI18n.LarkChatSetting.Lark_Legacy_GroupInfo
        self.currentChatterId = currentChatterId
        self.chatAPI = chatAPI
        self.userResolver = resolver
        self.items = structureItems()
        let chatId = chatModel.id
        let chatOb = chatWrapper.chat.filter { $0.id == chatId }.map({ $0 })
        chatOb.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                guard let `self` = self else { return }
                self.chatModel = chat
                self.refreshDataSource()
            }).disposed(by: self.disposeBag)

        // 群背景入口 拉取本地和远端结果
        self.chatAPI.getChatSwitchWithLocalAndServer(chatId: self.chatModel.id,
                                                     actionType: .groupChatTheme)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (value) in
                Self.logger.info("getGroupChatThemeSwitch info \(value)")
                guard let self = self, let value = value else { return }
                if value != self.isShowChatBgImage {
                    self.isShowChatBgImage = value
                    self.refreshDataSource()
                }
            }, onError: { error in
                Self.logger.error("getGroupChatThemeSwitch error", error: error)
            }).disposed(by: self.disposeBag)
    }

    private func structureItems() -> CommonDatasource {
        var items = CommonDatasource()

        let chatId = chatModel.id
        var firstSectionItems: [GroupSettingItemProtocol] = []
        var secondSectionItems: [GroupSettingItemProtocol] = []

        // Section 0
        let photo = GroupInfoPhotoItem(
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
            NewChatSettingTracker.imEditGroupInfoGroupAvatarClick(chat: buriedPointChat)
        }
        firstSectionItems.append(photo)

        let title = BundleI18n.LarkChatSetting.Lark_Legacy_GroupName
        let attributedTitle = NSAttributedString(string: title)
        let name = GroupInfoNameItem(
            type: .groupInfoName,
            cellIdentifier: GroupInfoNameCell.lu.reuseIdentifier,
            style: .auto,
            attributedTitle: attributedTitle,
            name: chatModel.displayName,
            hasAccess: hasAccess,
            isTapEnabled: chatModel.oncallId.isEmpty) { [weak self] _ in
                guard let vc = self?.targetVC else {
                    assertionFailure("缺少路由跳转的targetVC")
                    return
                }
                NewChatSettingTracker.imChatSsettingEditTitleClick(chatId: chatId, isAdmin: self?.isOwner ?? false)
                let body = ModifyGroupNameBody(chatId: chatId, title: title)
                self?.userResolver.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: vc,
                    prepare: { $0.modalPresentationStyle = .formSheet })
                guard let buriedPointChat = self?.chatModel else { return }
                NewChatSettingTracker.imEditGroupInfoGroupNameClick(chat: buriedPointChat)
        }
        firstSectionItems.append(name)

        // code_next_line tag CryptChat
        if !self.chatModel.isCrypto {
            let descriptionText = chatModel.description
            let title = BundleI18n.LarkChatSetting.Lark_Legacy_GroupDescription
            let attributedTitle = NSAttributedString(string: title)
            let description = GroupInfoDescriptionItem(
                type: .groupInfoDescription,
                cellIdentifier: GroupInfoDescriptionCell.lu.reuseIdentifier,
                style: .auto,
                attributedTitle: attributedTitle,
                description: descriptionText) { [weak self] _ in
                guard let vc = self?.targetVC else {
                    assertionFailure("缺少路由跳转的targetVC")
                    return
                }
                NewChatSettingTracker.imChatSettingEditDescriptionClick(chatId: chatId, isAdmin: self?.isOwner ?? false)
                let body = ModifyGroupDescriptionBody(chatId: chatId, title: title)
                self?.userResolver.navigator.present(body: body,
                                         wrap: LkNavigationController.self,
                                         from: vc,
                                         prepare: { $0.modalPresentationStyle = .formSheet },
                                         animated: true)
                guard let buriedPointChat = self?.chatModel else { return }
                NewChatSettingTracker.imEditGroupInfoDescriptionClick(chat: buriedPointChat)
            }
            firstSectionItems.append(description)
        }

        if groupEmailAddressShouldShow {
            let mailAddressItem = GroupInfoMailAddressItem(
                type: .groupInfoMailAddress,
                cellIdentifier: GroupInfoMailAddressCell.lu.reuseIdentifier,
                style: .auto,
                attributedTitle: NSAttributedString(string: BundleI18n.LarkChatSetting.Lark_GroupSettings_GroupEmail_Title),
                description: self.groupEmailAddress,
                tapHandler: { [weak self] cell in
                    guard let self = self else { return }
                    self.showGroupMailAddressAlertSheet(in: cell)
                    NewChatSettingTracker.imEditGroupInfoEmailClick(chat: self.chatModel)
                })
            firstSectionItems.append(mailAddressItem)
        }

        // Section 1
        if self.chatModel.chatCanBeShared(currentUserId: self.currentChatterId) {
            let qrCode = GroupInfoQRCodeItem(
                type: .groupInfoQRCode,
                cellIdentifier: GroupInfoQRCodeCell.lu.reuseIdentifier,
                style: .auto,
                title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupInfoGroupQrCode) { [weak self] _ in
                    guard let self = self else { return }
                    guard let vc = self.targetVC else {
                        assertionFailure("lose targetVC")
                        return
                    }
                    NewChatSettingTracker.imChatSettingQrcodePageView(chatId: chatId,
                                                                      isAdmin: self.isOwner,
                                                                      source: .qrCodeCell,
                                                                      chat: self.chatModel)
                    self.userResolver.navigator.push(body: GroupQRCodeBody(chatId: chatId), from: vc)
                    NewChatSettingTracker.imEditGroupInfoQRClick(chat: self.chatModel)
            }
            secondSectionItems.append(qrCode)
        }

        let groupBgImage = GroupInfoChatBgImageItem(
            type: .groupBgImage,
            cellIdentifier: GroupInfoChatBgImageCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_GroupWallpaper_Button,
            isShowIcon: false) { [weak self] _ in
                guard let `self` = self else { return }
                guard let vc = self.targetVC else {
                    assertionFailure("lose targetVC")
                    return
                }
                ChatSettingTracker.imChatSettingClickChatBackground(chat: self.chatModel)
                let body = ChatThemeBody(chatId: self.chatModel.id,
                                         title: BundleI18n.LarkChatSetting.Lark_IM_GroupWallpaper_Button,
                                         scene: .group)
                self.userResolver.navigator.push(body: body, from: vc)
        }

        let firstSection = CommonSectionModel(title: nil, items: firstSectionItems)
        let secondSection = CommonSectionModel(title: nil, items: secondSectionItems)
        let desc = BundleI18n.LarkChatSetting.Lark_IM_GroupWallpaper_Desc
        let personalChatBgImageSection = CommonSectionModel(title: nil,
                                                            description: desc,
                                                            items: [groupBgImage])
        items.append(firstSection)
        items.append(secondSection)
        // 密聊/密盾聊/话题群 不支持更换聊天背景
        // 群主/管理员才有权限
        if isShowChatBgImage,
            !self.chatModel.isCrypto,
            !self.chatModel.isPrivateMode,
            self.chatModel.chatMode != .threadV2,
            self.isOwner == true || self.isGroupAdmin {
            items.append(personalChatBgImageSection)
        }

        return items
    }

    func refreshDataSource() {
        self.items = self.structureItems()
        self._reloadData.onNext(())
    }
}

extension GroupInfoViewModel {
    // 群头像编辑
    func previewAvatar() {
        guard let vc = self.targetVC else {
            assertionFailure("缺少路由跳转的targetVC")
            return
        }

        if hasAccess {
            let body = CustomizeGroupAvatarBody(chat: chatModel, avatarDrawStyle: .transparent)
            self.userResolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: vc) { vc in
                vc.modalPresentationStyle = .formSheet
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

// MARK: 群邮箱
extension GroupInfoViewModel {
    // 拉取群邮箱地址及设置信息
    func getGroupMailAddress() {
        // 前端能判断的情况直接过滤，减少请求次数
        guard groupEmailAddressEnable else { return }
        self.chatAPI.getChatGroupAddress(chatId: self.chatModel.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                self.groupEmailSetting = res.groupSetting
                switch res.status {
                case .exist:
                    self.groupEmailAddressShouldShow = true
                    self.updateGroupMailAddress(address: res.address)
                case .notExist:
                    self.groupEmailAddressShouldShow = true
                    self.refreshDataSource()
                case .noPerm:
                    return
                @unknown default:
                    assertionFailure("Unknown status type")
                }
            }, onError: { (error) in
                GroupInfoViewModel.logger.error("getGroupMailAddress error", error: error)
            }).disposed(by: self.disposeBag)
    }

    // 点击群邮箱展示action sheet
    private func showGroupMailAddressAlertSheet(in sourceView: UIView) {
        guard let vc = self.targetVC else {
            assertionFailure("reduce targetVC to jump")
            return
        }

        let sourceRect: CGRect = CGRect(origin: .zero, size: sourceView.bounds.size)
        let popSource = UDActionSheetSource(sourceView: sourceView,
                                            sourceRect: sourceRect)
        var title: String = ""
        if let setting = self.groupEmailSetting {
            if setting.enableMailSend {
                switch setting.sendPermission {
                case .groupAdmin:
                    title = BundleI18n.LarkChatSetting.Lark_GroupSettings_EmailAddress_OnlyOwnerAdminCanEmail_Text
                case .groupMembers:
                    title = BundleI18n.LarkChatSetting.Lark_GroupSettings_EmailAddress_OnlyGroupMembersCanEmail_Text
                case .organizationMembers:
                    title = BundleI18n.LarkChatSetting.Lark_GroupSettings_EmailAddress_OnlyOrgMembersCanEmail_Text
                case .all:
                    title = BundleI18n.LarkChatSetting.Lark_GroupSettings_EmailAddress_EveryoneCanEmail_Text
                case .unknown:
                    assertionFailure("Wrong permission type")
                @unknown default:
                    assertionFailure("Unknown permission type")
                }
            } else {
                title = BundleI18n.LarkChatSetting.Lark_GroupSettings_EmailAddress_NoOneCanEmail_Text
            }
        }
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: !title.isEmpty, popSource: popSource))
        actionSheet.setTitle(title)
        if self.hasEmailAddress {
            actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_GroupSettings_CopyEmailAddress_Mobile_Button) { [weak self] in
                guard let self = self else { return }
                let config = PasteboardConfig(token: Token("LARK-PSDA-messenger_group_mail_copy_address"))
                do {
                    try SCPasteboard.generalUnsafe(config).string = self.groupEmailAddress
                    UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_GroupSettings_EmailAddressCopied_Toast, on: vc.view)
                } catch {
                    UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_GroupSettings_EmailUnableToCopy_Toast, on: vc.view)
                }
                NewChatSettingTracker.imEditGroupInfoEmailCopyClick(chat: self.chatModel)
            }
        } else {
            actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_GroupSettings_GetGroupEmail_Button) { [weak self] in
                guard let self = self else { return }
                let hud = UDToast.showLoading(with: BundleI18n.LarkChatSetting.Lark_IM_GeneratingEmailAddress_Toast,
                                              on: vc.view,
                                              disableUserInteraction: true)
                self.chatAPI.createChatGroupAddress(chatId: self.chatModel.id)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (res) in
                        guard let self = self else { return }
                        hud.remove()
                        if !res.address.isEmpty {
                            self.updateGroupMailAddress(address: res.address)
                            UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_GroupSettings_GetEmailAddress_AddressGenerated_Toast, on: vc.view)
                        }
                    }, onError: { (error) in
                        hud.remove()
                        UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_GroupSettings_EmailAddressUnableGenerate_Toast, on: vc.view)
                        GroupInfoViewModel.logger.error("createGroupMailAddress error", error: error)
                    }).disposed(by: self.disposeBag)
                NewChatSettingTracker.imEditGroupInfoGetEmailClick(chat: self.chatModel)
            }
        }
        if !chatModel.isFrozen, self.isOwner || self.isGroupAdmin {
            actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_GroupSettings_ChangePermissions_Mobile_Button) { [weak self] in
                guard let self = self else { return }
                self.userResolver.navigator.push(body: GroupSettingBody(chatId: self.chatModel.id,
                                                                        openSettingCellType: .mailPermission),
                                                 from: vc)
                NewChatSettingTracker.imEditGroupInfoEmailPermissionClick(chat: self.chatModel)
            }
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel)
        self.userResolver.navigator.present(actionSheet, from: vc)
    }

    // 更新展示的群邮箱地址
    private func updateGroupMailAddress(address: String) {
        self.hasEmailAddress = true
        self.groupEmailAddress = address
        self.refreshDataSource()
    }
}
