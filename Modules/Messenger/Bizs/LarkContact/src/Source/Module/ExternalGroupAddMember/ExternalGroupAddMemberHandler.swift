//
//  ExternalGroupAddMemberHandler.swift
//  LarkContact
//
//  Created by 姜凯文 on 2020/4/23.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSegmentedView
import EENavigator
import LarkMessengerInterface
import Swinject
import RxSwift
import LarkSDKInterface
import LarkAccountInterface
import LKCommonsLogging
import LarkCore
import LarkModel
import LarkFeatureGating
import LarkSearchCore
import LarkAlertController
import UniverseDesignCheckBox
import LarkKAFeatureSwitch
import LarkNavigator
import LarkSetting

public final class ExternalGroupAddMemberHandler: UserTypedRouterHandler {
    private struct Parameters {
        var chat: Chat
        var chatID: String
        var ownerID: String
        var chatChatterCount: Int
        var isCrypto: Bool
        var showSyncMessages: Bool
        var isCrossTenant: Bool
        var isCrossWithKa: Bool
        var isOwner: Bool
        var isAdmin: Bool
        var isPublic: Bool
        var chatType: MessengerChatType
        var source: AddMemberSource?
    }
    private static let logger = Logger.log(ExternalGroupAddMemberHandler.self, category: "Module.IM.Contact.ExternalGroupAddMember")

    private let disposeBag = DisposeBag()

    public func handle(_ body: ExternalGroupAddMemberBody, req: Request, res: Response) throws {
        guard let chat = try userResolver.resolve(assert: ChatAPI.self).getLocalChat(by: body.chatId) else {
            ExternalGroupAddMemberHandler.logger.error("chat fetch fail", additionalData: ["chatID": body.chatId])
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }
        guard let from = req.context.from()?.fromViewController else {
            res.end(error: RouterError.cannotPresent)
            return
        }

        Tracer.trackOpenPickerView(.group)
        let parameters = Parameters(
            chat: chat,
            chatID: body.chatId,
            ownerID: chat.ownerId,
            chatChatterCount: Int(chat.chatterCount),
            isCrypto: chat.isCrypto,
            showSyncMessages: chat.chatMode != .threadV2 && chat.enableRestricted(.forward),
            isCrossTenant: chat.isCrossTenant,
            isCrossWithKa: chat.isCrossWithKa,
            isOwner: userResolver.userID == chat.ownerId,
            isAdmin: chat.isGroupAdmin,
            isPublic: chat.isPublic,
            chatType: MessengerChatType.getTypeWithChat(chat),
            source: body.source
        )
        try self.showPicker(parameters, from: from)
    }

    private func presentAddContactAlert(chatId: String,
                                        isNotFriendContacts: [AddExternalContactModel],
                                        targetVC: UIViewController,
                                        task: (() -> Void)? = nil) {
        // 如果没有非好友直接结束引导加好友的流程, 走正常流程
        guard !isNotFriendContacts.isEmpty else {
            task?()
            return
        }
        // 人数为1使用单人alert
        if isNotFriendContacts.count == 1 {
            let contact = isNotFriendContacts[0]
            var source = Source()
            source.sourceType = .chat
            source.sourceID = chatId
            let addContactBody = AddContactApplicationAlertBody(userId: isNotFriendContacts[0].ID,
                                                                chatId: chatId,
                                                                source: source,
                                                                displayName: contact.name,
                                                                targetVC: targetVC,
                                                                businessType: .groupConfirm,
                                                                cancelCallBack: {
                                                                    task?()
                                                                },
                                                                dissmissBlock: {
                                                                    task?()
                                                                })
            userResolver.navigator.present(body: addContactBody, from: targetVC)
            return
        }
        // 人数大于1使用多人alert
        let dependecy = MSendContactApplicationDependecy(source: .chat)
        let addContactApplicationAlertBody = MAddContactApplicationAlertBody(contacts: isNotFriendContacts,
                                                                             source: .createGroup,
                                                                             dependecy: dependecy,
                                                                             businessType: .groupConfirm,
                                                                             cancelCallBack: {
                                                                                 task?()
                                                                             },
                                                                             sureCallBack: { (_, _) in
                                                                                 task?()
                                                                             })
        userResolver.navigator.present(body: addContactApplicationAlertBody, from: targetVC)
    }

    /// 调用选人，并解析结果
    private func showPicker(_ parameters: Parameters, from: UIViewController) throws {
        let tracker = PickerAppReciable(pageName: "LKContactPickerViewController", fromType: .addGroupMember)
        let chat = parameters.chat
        let dataOptions: DataOptions = [.external]
        // (不是密聊 或 本身为外部群) 才可选外部成员
        let needSearchOuterTenant = (parameters.isCrossTenant || !parameters.isCrypto)

        let selectedCallback: ((UIViewController?, ContactPickerResult) -> Void)? = { [weak self] controller, contactPickerResult in
            guard let self = self, let controller = controller else { return }
            let notFriendContacts = contactPickerResult.chatterInfos
                .filter { $0.isNotFriend }
                .map { info in
                    AddExternalContactModel(
                        ID: info.ID,
                        name: info.name,
                        avatarKey: info.avatarKey
                    )
                }
            let friendIDs = contactPickerResult.chatterInfos
                .filter { !$0.isNotFriend }
                .map { $0.ID }

            /// 「互通」群直接走加人逻辑
            if parameters.isCrossWithKa {
                self.addGroupMember(
                    controller,
                    parameters: parameters,
                    isFriendChatterIds: friendIDs,
                    isNotFriendContacts: notFriendContacts,
                    chatIds: contactPickerResult.chatInfos.map { $0.id },
                    departmentIds: contactPickerResult.departmentIds,
                    from: from
                )
                return
            }
            /// 需要判断所选 chatter 是否跨 Unit
            self.onSelected(
                controller: controller,
                friendIDs: friendIDs,
                notFriendContacts: notFriendContacts,
                parameters: parameters,
                chatIds: contactPickerResult.chatInfos.map { $0.id },
                departmentIds: contactPickerResult.departmentIds,
                from: from
            )
        }
        let shareQRCodeVC = try userResolver.resolve(assert: ShareGroupQRCodeController.self, arguments: chat, false, false)
        let groupLinkSwitchisOpen = userResolver.fg.staticFeatureGatingValue(with: "share_link_enable")
        let shareGroupLinkVC = try userResolver.resolve(assert: ShareGroupLinkController.self, arguments: chat, false)
        let passportUserService = try resolver.resolve(assert: PassportUserService.self)
        let params = AddChatterPicker.InitParam()
        params.includeOuterTenant = needSearchOuterTenant
        params.isMultiple = true
        params.forceSelectedInChatId = parameters.chatID
        if chat.isCrypto {
            params.permissions = [.inviteSameCryptoChat]
        } else if chat.isCrossTenant {
            params.permissions = [.inviteSameCrossTenantChat]
        } else {
            params.permissions = [.inviteSameChat]
        }
        if passportUserService.userTenant.isCustomer {
            let pushDriver = try userResolver.userPushCenter.driver(for: PushExternalContacts.self)
            let router = try userResolver.resolve(assert: CustomerSelectRouter.self)
            let rootVC = NewExternalGroupCustomerSelectController(navTitle: "",
                                                                  picker: ChatterPicker(resolver: self.userResolver, frame: .zero, params: params),
                                                                  isShowGroup: false,
                                                                  allowSelectNone: false,
                                                                  limitInfo: nil,
                                                                  pushDriver: pushDriver,
                                                                  router: router,
                                                                  resolver: userResolver,
                                                                  tracker: tracker,
                                                                  confirmCallBack: selectedCallback)
            let containerVC = ExternalGroupAddMemberContainerViewController(
                subViewControllers: [rootVC, groupLinkSwitchisOpen ? shareGroupLinkVC : nil, shareQRCodeVC].compactMap { $0 },
                addMemberTypes: [.contact, groupLinkSwitchisOpen ? .link : nil, .QRcode].compactMap { $0 }
            )
            rootVC.inputNavigationItem = containerVC.navigationItem
            containerVC.modalPresentationStyle = .fullScreen
            let nav = LkNavigationController(rootViewController: containerVC)
            userResolver.navigator.present(nav, from: from, prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        } else {
            params.supportUnfold = true
            var structureViewDependencyConfig = StructureViewDependencyConfig()
            structureViewDependencyConfig.enableExternal = dataOptions.contains(.external)
            structureViewDependencyConfig.enableGroup = false
            structureViewDependencyConfig.enableRelatedOrganizations = true
            structureViewDependencyConfig.isCrossTenantChat = chat.isCrossTenant

            let disableSelectDepartmentPermission = userResolver.fg.staticFeatureGatingValue(with: "im.chat.depart_group_permission")
            structureViewDependencyConfig.enableGroup = true
            structureViewDependencyConfig.supportSelectGroup = true
            structureViewDependencyConfig.enableOrganization = true
            structureViewDependencyConfig.supportSelectOrganization = true
            params.includeChatForAddChatter = true
            params.includeDepartmentForAddChatter = !disableSelectDepartmentPermission
            let chatterPicker = AddChatterPicker(resolver: self.userResolver, frame: .zero, params: params)
            chatterPicker.searchPlaceholder = disableSelectDepartmentPermission ? BundleI18n.LarkContact.Lark_IM_SelectDepartmentForGroupChat :
            BundleI18n.LarkContact.Lark_Group_SearchContactsDepartmentsMyGroups
            let structureView = StructureView(frame: .zero,
                                              dependency: DefaultStructureViewDependencyImpl(r: userResolver,
                                                                                             picker: chatterPicker,
                                                                                             config: structureViewDependencyConfig),
                                              resolver: userResolver)
            chatterPicker.defaultView = structureView

            let pickerNavigationTitleView = PickerNavigationTitleView(
                title: BundleI18n.LarkContact.Lark_Groups_GroupAddMemberTitle,
                observable: chatterPicker.selectedObservable,
                initialValue: chatterPicker.selected
            )

            let rootVC = try NewExternalGroupTopStructureSelectViewController(navTitle: "",
                                                             chatterPicker: chatterPicker,
                                                             style: .multi,
                                                             allowSelectNone: false,
                                                             allowDisplaySureNumber: false,
                                                             limitInfo: nil,
                                                             tracker: tracker,
                                                             selectedCallback: selectedCallback,
                                                             resolver: userResolver)
            let containerVC = ExternalGroupAddMemberContainerViewController(
                subViewControllers: [rootVC, groupLinkSwitchisOpen ? shareGroupLinkVC : nil, shareQRCodeVC].compactMap { $0 },
                addMemberTypes: [.contact, groupLinkSwitchisOpen ? .link : nil, .QRcode].compactMap { $0 },
                navTitleView: pickerNavigationTitleView
            )
            containerVC.externalGroupItemSelectBlock = {(_ addMemberTypes: AddMemberType) in
                Tracer.imGroupMemberAddClickGroupMemberType(addMemberTypes, chat: parameters.chat)
            }
            rootVC.inputNavigationItem = containerVC.navigationItem
            containerVC.modalPresentationStyle = .fullScreen
            let nav = LKToolBarNavigationController(rootViewController: containerVC)
            userResolver.navigator.present(nav, from: from, prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        }
    }

    private func onSelected(controller: UIViewController,
                            friendIDs: [String],
                            notFriendContacts: [AddExternalContactModel],
                            parameters: Parameters,
                            chatIds: [String],
                            departmentIds: [String],
                            from: UIViewController) {
        if friendIDs.isEmpty {
            /// 直接走加人逻辑
            self.addGroupMember(
                controller,
                parameters: parameters,
                isFriendChatterIds: [],
                isNotFriendContacts: notFriendContacts,
                chatIds: chatIds,
                departmentIds: departmentIds,
                from: from
            )
            return
        }
        guard let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self),
                let passportUserService = try? resolver.resolve(assert: PassportUserService.self) else { return }
        let currentTenantId = passportUserService.userTenant.tenantID
        chatterAPI.getChatters(ids: friendIDs)
            .map { (chatterDic) -> [String] in
                var tenantIdSet: Set<String> = [currentTenantId]
                tenantIdSet.formUnion(chatterDic.values.map { $0.tenantId })
                return Array(tenantIdSet)
            }
            .flatMap({ [weak self] (tenantIds) -> Observable<Bool> in
                guard let self = self else { return .empty() }
                if tenantIds.count == 1 { return .just(false) }
                guard let externalContactsAPI = try? self.userResolver.resolve(assert: ExternalContactsAPI.self) else {
                    Self.logger.info("onSelected get externalContactsAPI failure")
                    return .empty()
                }
                return externalContactsAPI
                    .getTenant(tenantIds: tenantIds)
                    .map { (tenants) -> (Bool) in
                        let unitLeagueSet: Set<String> = Set(tenants.map { $0.unitLeague }.filter { !$0.isEmpty })
                        if unitLeagueSet.count > 1 {
                            return true
                        }
                        return false
                    }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (crossUnit) in
                /// 所选 chatter 跨 Unit
                if crossUnit {
                    self?.addCrossUnitMember(
                        controller,
                        parameters: parameters,
                        isFriendChatterIds: friendIDs,
                        isNotFriendContacts: notFriendContacts,
                        chatIds: chatIds,
                        departmentIds: departmentIds
                    )
                    return
                }
                self?.addGroupMember(
                    controller,
                    parameters: parameters,
                    isFriendChatterIds: friendIDs,
                    isNotFriendContacts: notFriendContacts,
                    chatIds: chatIds,
                    departmentIds: departmentIds,
                    from: from
                )
            }, onError: { (error) in
                ExternalGroupAddMemberHandler.logger.error(
                    "fetch chatters or tenants error",
                    error: error
                )
            }).disposed(by: disposeBag)
    }

    // 直接加人
    private func addGroupMember(_ controller: UIViewController,
                                parameters: Parameters,
                                isFriendChatterIds: [String],
                                isNotFriendContacts: [AddExternalContactModel],
                                chatIds: [String],
                                departmentIds: [String],
                                from: UIViewController) {
        let currentChatterId = userResolver.userID
        if let source = parameters.source {
            Tracer.imChatSettingAddMemberClick(chatId: parameters.chatID,
                                               isAdmin: parameters.isOwner,
                                               count: isFriendChatterIds.count,
                                               isPublic: parameters.isPublic,
                                               chatType: parameters.chatType,
                                               source: source)
        }
        // dismiss后present加好友弹窗
        controller.dismiss(animated: true) { [weak self] in
            self?.presentAddContactAlert(chatId: parameters.chatID,
                                         isNotFriendContacts: isNotFriendContacts,
                                         targetVC: from) {
                let body = JoinGroupApplyBody(
                    chatId: parameters.chatID,
                    way: .viaInvitation(inviterId: currentChatterId,
                                        inviterIsAdminOrOwner: parameters.isAdmin || parameters.isOwner,
                                        isFriendChatterIds: isFriendChatterIds,
                                        chatIds: chatIds,
                                        departmentIds: departmentIds,
                                        jumpChat: false)
                )
                self?.userResolver.navigator.open(body: body, from: from)
            }
        }

    }

    // 添加跨 Unit 成员
    private func addCrossUnitMember(_ controller: UIViewController,
                                    parameters: Parameters,
                                    isFriendChatterIds: [String],
                                    isNotFriendContacts: [AddExternalContactModel],
                                    chatIds: [String],
                                    departmentIds: [String]) {
        guard let userAppConfig = try? userResolver.resolve(assert: UserAppConfig.self) else {
            Self.logger.info("addCrossUnitMember get userAppConfig failure")
            return
        }
        let checkCount = userAppConfig
            .appConfig?
            .chatConfig
            .maxOriginGroupChatUserCount4CreateExternalChat ?? 100

        if parameters.chatChatterCount > checkCount, parameters.ownerID != userResolver.userID {
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkContact.Lark_Chat_AddExternalMembersAlertTitle)
            alertController.setContent(text: BundleI18n.LarkContact.Lark_Chat_AddExternalMembers)
            alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ShareAlertOK)
            userResolver.navigator.present(alertController, from: controller)

            return
        }
        let topmostFrom = WindowTopMostFrom(vc: controller)
        let (view, syncMsgCheckBox) = createAddOuterConfirmView(showSyncMessages: parameters.showSyncMessages)
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_Group_CreateConnectGroup)
        alertController.setContent(view: view)
        alertController.addCancelButton()
        alertController.addPrimaryButton(
            text: BundleI18n.LarkContact.Lark_Group_CreateGroup_CreateGroup_TypePublic_CreateButton,
            dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                let body = CreateGroupWithRecordBody(
                    groupChatId: parameters.chatID,
                    selectedChatterIds: isFriendChatterIds,
                    selectedChatIds: chatIds,
                    selectedDepartmentIds: departmentIds,
                    pickerController: controller,
                    syncMessage: syncMsgCheckBox?.isSelected ?? false
                )
                self.userResolver.navigator.open(body: body, from: controller) { [weak self] (_, _) in
                    guard let targetVC = topmostFrom.fromViewController else {
                        assertionFailure()
                        return
                    }
                    self?.presentAddContactAlert(
                        chatId: parameters.chatID,
                        isNotFriendContacts: isNotFriendContacts,
                        targetVC: targetVC
                    )
                }
            })

        userResolver.navigator.present(alertController, from: controller)
    }

    // 创建添加跨unit的人的确认弹窗
    private func createAddOuterConfirmView(showSyncMessages: Bool) -> (UIView, UDCheckBox?) {
        let contentView = UIView()
        // create external group promat message
        let createCrossUnitGroupPromatLabel = UILabel()
        var syncMsgCheckBox: UDCheckBox?

        contentView.addSubview(createCrossUnitGroupPromatLabel)
        let tips = BundleI18n.LarkContact.Lark_Group_CreateConnectGroupBasedOnExistingGroupDialogContent
        let attributedString = NSMutableAttributedString(
            string: tips,
            attributes: [
                .foregroundColor: UIColor.ud.N900,
                .font: UIFont.systemFont(ofSize: 14)
            ]
        )

        /// 查找需要标红的子串的range
        if let range = tips.range(of: BundleI18n.LarkContact.Lark_Group_NewConnectGroup) {
            attributedString.addAttributes([.foregroundColor: UIColor.ud.colorfulRed], range: NSRange(range, in: tips))
        }

        createCrossUnitGroupPromatLabel.numberOfLines = 0
        createCrossUnitGroupPromatLabel.attributedText = attributedString

        if showSyncMessages {
            createCrossUnitGroupPromatLabel.snp.makeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                maker.width.equalTo(263).priority(.required)
            }
            let checkBox = UDCheckBox(boxType: .multiple)
            checkBox.tapCallBack = { [weak self] (box) in
                self?.checkBoxTapHandle(checkBox: box)
            }
            contentView.addSubview(checkBox)
            checkBox.snp.makeConstraints { (maker) in
                maker.top.equalTo(createCrossUnitGroupPromatLabel.snp.bottom).offset(10)
                maker.left.equalTo(createCrossUnitGroupPromatLabel)
                maker.bottom.equalTo(0)
                maker.size.equalTo(LKCheckbox.Layout.iconSmallSize)
            }
            let tipsButton = UIButton() /// 复选框后面的提示文字，也要支持点击事件，所以用Button
            contentView.addSubview(tipsButton)
            tipsButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.checkBoxTapHandle(checkBox: checkBox)
            }).disposed(by: disposeBag)
            tipsButton.setTitle(BundleI18n.LarkContact.Lark_Chat_SyncMessage, for: .normal)
            tipsButton.setTitleColor(UIColor.ud.N900, for: .normal)
            tipsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            tipsButton.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(checkBox)
                maker.left.equalTo(checkBox.snp.right).offset(6.5)
                maker.right.lessThanOrEqualToSuperview()
            }

            syncMsgCheckBox = checkBox
        } else {
            createCrossUnitGroupPromatLabel.snp.makeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                maker.width.equalTo(263).priority(.required)
                maker.bottom.equalToSuperview()
            }
        }
        return (contentView, syncMsgCheckBox)
    }

    func checkBoxTapHandle(checkBox: UDCheckBox) {
        checkBox.isSelected = !checkBox.isSelected
    }
}

extension LarkAccountInterface.Tenant {
    var isCustomer: Bool {
        return tenantID == "0"
    }
}

extension PassportService {
    var isOversea: Bool {
        return !isFeishuBrand
    }
}
