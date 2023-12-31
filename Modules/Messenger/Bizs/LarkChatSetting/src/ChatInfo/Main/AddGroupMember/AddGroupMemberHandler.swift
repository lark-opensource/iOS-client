//
//  AddGroupMemberHandler.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/5/16.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Swinject
import LarkCore
import LarkModel
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LKCommonsLogging
import LarkFeatureGating
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignCheckBox
import Homeric
import LKCommonsTracker
import LarkNavigator

final class AddGroupMemberHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    private struct Parameters {
        var chatID: String
        var ownerID: String
        var chatChatterCount: Int
        var isCrypto: Bool
        // show sync messages check box
        var showSyncMessagesCheckBox: Bool
        var isCrossTenant: Bool
        var isCrossWithKa: Bool
        // 是不是密盾群
        var isPrivateMode: Bool
        // 是否是群主
        var isOwner: Bool
        //是否是管理员
        var isAdmin: Bool
        var isPublic: Bool
        var chatType: MessengerChatType
        var source: AddMemberSource?
        var chatTrackCommonInfo: [AnyHashable: Any]
    }
    private var currentChatterId: String {
        return (try? self.userResolver.resolve(assert: PassportUserService.self).user.userID) ?? ""
    }

    private typealias PickerHandler = (_ controller: UIViewController,
                                       _ isFriendChatterInfos: [SelectChatterInfo],
                                       _ isNotFriendContacts: [AddExternalContactModel],
                                       _ chatIds: [String],
                                       _ departmentIds: [String]) -> Void

    static let logger = Logger.log(AddGroupMemberHandler.self, category: "Module.IM.ChatInfo")

    private let disposeBag = DisposeBag()

    func handle(_ body: AddGroupMemberBody, req: EENavigator.Request, res: Response) throws {
        guard let chat = try self.userResolver.resolve(assert: ChatAPI.self).getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }

        let parameters = Parameters(
            chatID: body.chatId,
            ownerID: chat.ownerId,
            chatChatterCount: Int(chat.chatterCount),
            isCrypto: chat.isCrypto,
            // thread and secret chat don't show sync message checkbox
            showSyncMessagesCheckBox: (chat.chatMode != .threadV2 && !chat.isCrypto && !chat.enableRestricted(.forward)),
            isCrossTenant: chat.isCrossTenant,
            isCrossWithKa: chat.isCrossWithKa,
            isPrivateMode: chat.isPrivateMode,
            isOwner: self.currentChatterId == chat.ownerId,
            isAdmin: chat.isGroupAdmin,
            isPublic: chat.isPublic,
            chatType: MessengerChatType.getTypeWithChat(chat),
            source: body.source,
            chatTrackCommonInfo: IMTracker.Param.chat(chat)
        )

        guard let from = req.context.from() else {
            assertionFailure("缺少 From")
            return
        }

        self.showPicker(parameters, from: from) { [weak self] (controller, isFriendChatterInfos, isNotFriendContacts, chatIds, departmentIds) in
            let isFriendChatterIds = isFriendChatterInfos.map { $0.ID }
            /// 「互通」群直接加人
            if chat.isCrossWithKa {
                self?.addGroupMember(
                    controller,
                    parameters: parameters,
                    from: from,
                    isFriendChatterIds: isFriendChatterIds,
                    isNotFriendContacts: isNotFriendContacts,
                    chatIds: chatIds,
                    departmentIds: departmentIds
                )
                return
            }
            /// 需要判断所选 chatter 是否跨租户与跨 Unit
            self?.onSelected(
                controller,
                parameters: parameters,
                from: from,
                isFriendChatterIds: isFriendChatterIds,
                isNotFriendContacts: isNotFriendContacts,
                chatIds: chatIds,
                departmentIds: departmentIds
            )
        }

        res.end(resource: EmptyResource())
    }

    /// 调用选人，并解析结果
    private func showPicker(_ parameters: Parameters, from: NavigatorFrom, handler: @escaping PickerHandler) {
        var body = ChatterPickerBody()
        body.checkInvitePermission = true
        body.isCrossTenantChat = parameters.isCrossTenant
        body.isCryptoModel = parameters.isCrypto
        if !parameters.isCrypto {
            body.supportSelectGroup = true
            body.supportSelectOrganization = true
            body.checkGroupPermissionForInvite = true
            body.checkOrganizationPermissionForInvite = !userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.disableSelectDepartmentPermission))
        }
        body.dataOptions = [.external]
        body.title = BundleI18n.LarkChatSetting.Lark_Legacy_AddMembers
        body.supportCustomTitleView = true
        body.supportUnfoldSelected = true
        body.allowDisplaySureNumber = false
        body.allowSelectNone = false
        body.forceSelectedChatId = parameters.chatID
        body.needSearchOuterTenant = !parameters.isPrivateMode
        body.source = .addGroupMember
        body.selectedCallback = { controller, contactPickerResult in
            guard let controller = controller else { return }
            // 不是好友关系的外部联系人
            let isNotFriendContacts = contactPickerResult.chatterInfos
                .filter { $0.isNotFriend }
                .map { info in
                    AddExternalContactModel(
                        ID: info.ID,
                        name: info.name,
                        avatarKey: info.avatarKey
                    )
                }
            let isFriendContacts = contactPickerResult.chatterInfos.filter { !$0.isNotFriend }
            handler(controller, isFriendContacts, isNotFriendContacts, contactPickerResult.chatInfos.map { $0.id }, contactPickerResult.departmentIds)
        }
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_ADD_VIEW, params: parameters.chatTrackCommonInfo))
        self.userResolver.navigator.present(body: body,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }

    /// 选人结束后
    private func onSelected(_ controller: UIViewController,
                            parameters: Parameters,
                            from: NavigatorFrom,
                            isFriendChatterIds: [String],
                            isNotFriendContacts: [AddExternalContactModel],
                            chatIds: [String],
                            departmentIds: [String]) {
        if isFriendChatterIds.isEmpty {
            /// 直接走加人逻辑
            self.addGroupMember(
                controller,
                parameters: parameters,
                from: from,
                isFriendChatterIds: [],
                isNotFriendContacts: isNotFriendContacts,
                chatIds: chatIds,
                departmentIds: departmentIds
            )
            return
        }

        let currentTenantId = (try? self.userResolver.resolve(assert: PassportUserService.self).userTenant.tenantID) ?? ""
        let chatterAPI = try? self.userResolver.resolve(assert: ChatterAPI.self)
        chatterAPI?.getChatters(ids: isFriendChatterIds)
            .map { (chatterDic) -> [String] in
                var tenantIdSet: Set<String> = [currentTenantId]
                tenantIdSet.formUnion(chatterDic.values.map { $0.tenantId })
                return Array(tenantIdSet)
            }
            .flatMap({ [weak self] (tenantIds) -> Observable<(Bool, Bool)> in
                guard let self = self else { return .empty() }
                if tenantIds.count == 1 { return .just((false, false)) }

                return try self.userResolver.resolve(assert: ExternalContactsAPI.self)
                    .getTenant(tenantIds: tenantIds)
                    .map { (tenants) -> (Bool, Bool) in
                        let unitLeagueSet: Set<String> = Set(tenants.map { $0.unitLeague }.filter { !$0.isEmpty })
                        if unitLeagueSet.count > 1 {
                            return (true, true)
                        }
                        return (true, false)
                    }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (crossTenant, crossUnit) in
                // - crossTenant: 当前用户和所选用户是否存在跨租户
                // - crossUnit： 当前用户和所选用户是否存在跨 Unit
                /// 创建互通群
                if crossUnit {
                    self?.addOuterMember(controller,
                                         parameters: parameters,
                                         isFriendChatterIds: isFriendChatterIds,
                                         isNotFriendContacts: isNotFriendContacts,
                                         chatIds: chatIds,
                                         departmentIds: departmentIds,
                                         crossUnit: true
                    )
                    return
                }
                /// 跨租户但是群本身已是外部群
                if crossTenant, parameters.isCrossTenant {
                    self?.addGroupMember(
                        controller,
                        parameters: parameters,
                        from: from,
                        isFriendChatterIds: isFriendChatterIds,
                        isNotFriendContacts: isNotFriendContacts,
                        chatIds: chatIds,
                        departmentIds: departmentIds
                    )
                    return
                }
                /// 跨租户创建外部群
                if crossTenant {
                    self?.addOuterMember(controller,
                                         parameters: parameters,
                                         isFriendChatterIds: isFriendChatterIds,
                                         isNotFriendContacts: isNotFriendContacts,
                                         chatIds: chatIds,
                                         departmentIds: departmentIds,
                                         crossUnit: false
                    )
                    return
                }
                self?.addGroupMember(
                    controller,
                    parameters: parameters,
                    from: from,
                    isFriendChatterIds: isFriendChatterIds,
                    isNotFriendContacts: isNotFriendContacts,
                    chatIds: chatIds,
                    departmentIds: departmentIds
                )
            }, onError: { (error) in
                AddGroupMemberHandler.logger.error(
                    "fetch chatters or tenants error",
                    error: error
                )
            }).disposed(by: disposeBag)
    }

    /// 直接加人
    private func addGroupMember(_ controller: UIViewController,
                                parameters: Parameters,
                                from: NavigatorFrom,
                                isFriendChatterIds: [String],
                                isNotFriendContacts: [AddExternalContactModel],
                                chatIds: [String],
                                departmentIds: [String]) {
        let currentChatterId = self.userResolver.userID
        if let source = parameters.source {
            NewChatSettingTracker.imChatSettingAddMemberClick(chatId: parameters.chatID,
                                                              isAdmin: parameters.isOwner,
                                                              count: isFriendChatterIds.count,
                                                              isPublic: parameters.isPublic,
                                                              chatType: parameters.chatType,
                                                              source: source)
        }
        controller.dismiss(animated: true) { [weak self] in
            self?.presentAddContactAlert(chatId: parameters.chatID,
                                         isNotFriendContacts: isNotFriendContacts,
                                         from: from) {
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

    private func presentAddContactAlert(chatId: String,
                                        isNotFriendContacts: [AddExternalContactModel],
                                        from: NavigatorFrom,
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
                                                                targetVC: from.fromViewController,
                                                                businessType: .groupConfirm,
                                                                cancelCallBack: {
                                                                    task?()
                                                                },
                                                                dissmissBlock: {
                                                                    task?()
                                                                })
            self.userResolver.navigator.present(body: addContactBody, from: from)
            return
        }
        // 人数大于1使用多人alert
        let dependecy = MSendContactApplicationDependecy(source: .chat)
        let addContactApplicationAlertBody = MAddContactApplicationAlertBody(
            contacts: isNotFriendContacts,
            source: .createGroup,
            dependecy: dependecy,
            businessType: .groupConfirm,
            cancelCallBack: {
                task?()
            },
            sureCallBack: { (_, _) in
                task?()
            })
        self.userResolver.navigator.present(body: addContactApplicationAlertBody, from: from)
    }

    /// 添加外部人员,需要引导创建外部群
    ///
    /// 二期优化： https://bytedance.feishu.cn/space/doc/doccnjOfirw7nbSzgzPxh2AyQie#
    /// 1. 当群成员≤`checkCount`时，在内部群添加群成员处，选择了外部成员后，出现的弹框中“新的外部群”字样标红显示，强化提示；
    /// 2. 当群成员>`checkCount`时，选择了外部成员后，弹框提示无法添加：所选成员包含外部成员，仅群主可添加，请联系群主操作；
    /// - Parameters:
    ///   - crossUnit: 创建互通群还是普通外部群
    private func addOuterMember(_ controller: UIViewController,
                                parameters: Parameters,
                                isFriendChatterIds: [String],
                                isNotFriendContacts: [AddExternalContactModel],
                                chatIds: [String],
                                departmentIds: [String],
                                crossUnit: Bool) {
        let checkCount = (try? self.userResolver.resolve(assert: UserAppConfig.self))?
            .appConfig?
            .chatConfig
            .maxOriginGroupChatUserCount4CreateExternalChat ?? 100

        if parameters.chatChatterCount > checkCount, parameters.ownerID != self.currentChatterId {
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkChatSetting.Lark_Chat_AddExternalMembersAlertTitle)
            alertController.setContent(text: BundleI18n.LarkChatSetting.Lark_Chat_AddExternalMembers)
            alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_ShareAlertOK)
            self.userResolver.navigator.present(alertController, from: controller)

            return
        }

        let (view, syncMsgCheckBox) = createAddOuterConfirmView(showSyncMessages: parameters.showSyncMessagesCheckBox, crossUnit: crossUnit)
        let alertController = LarkAlertController()
        alertController.setTitle(text: crossUnit ? BundleI18n.LarkChatSetting.Lark_Group_CreateConnectGroup : BundleI18n.LarkChatSetting.Lark_Chat_CreateExternalGroup)
        alertController.setContent(view: view)
        alertController.addCancelButton()
        alertController.addPrimaryButton(
            text: BundleI18n.LarkChatSetting.Lark_Group_CreateGroup_CreateGroup_TypePublic_CreateButton,
            dismissCompletion: {
                let body = CreateGroupWithRecordBody(
                    groupChatId: parameters.chatID,
                    selectedChatterIds: isFriendChatterIds,
                    selectedChatIds: chatIds,
                    selectedDepartmentIds: departmentIds,
                    pickerController: controller,
                    syncMessage: syncMsgCheckBox?.isSelected ?? false
                )
                self.userResolver.navigator.open(body: body, from: controller) { [weak self] (_, _) in
                    self?.presentAddContactAlert(
                        chatId: parameters.chatID,
                        isNotFriendContacts: isNotFriendContacts,
                        from: controller
                    )
                }
            })

        self.userResolver.navigator.present(alertController, from: controller)
    }

    // 创建添加群外的人的确认弹窗
    private func createAddOuterConfirmView(showSyncMessages: Bool, crossUnit: Bool) -> (UIView, UDCheckBox?) {
        let contentView = UIView()
        // create external group promat message
        let createExternalGroupPromatLabel = UILabel()
        var syncMsgCheckBox: UDCheckBox?

        contentView.addSubview(createExternalGroupPromatLabel)
        let tips = crossUnit ? BundleI18n.LarkChatSetting.Lark_Group_CreateConnectGroupBasedOnExistingGroupDialogContent : BundleI18n.LarkChatSetting.Lark_Chat_CreateExternalGroupTips
        let attributedString = NSMutableAttributedString(
            string: tips,
            attributes: [
                .foregroundColor: UIColor.ud.N900,
                .font: UIFont.systemFont(ofSize: 14)
            ]
        )

        // 查找需要标红的子串的range
        if let range = tips.range(of: crossUnit ? BundleI18n.LarkChatSetting.Lark_Group_NewConnectGroup : BundleI18n.LarkChatSetting.Lark_Chat_AddExternalMembersAlert) {
            attributedString.addAttributes([.foregroundColor: UIColor.ud.colorfulRed], range: NSRange(range, in: tips))
        }

        createExternalGroupPromatLabel.numberOfLines = 0
        createExternalGroupPromatLabel.attributedText = attributedString

        if showSyncMessages {
            createExternalGroupPromatLabel.snp.makeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                maker.width.equalTo(263).priority(.required)
            }
            let checkBox = UDCheckBox(boxType: .multiple)
            checkBox.tapCallBack = { [weak self] (box) in
                self?.checkBoxTapHandle(checkBox: box)
            }
            contentView.addSubview(checkBox)
            checkBox.snp.makeConstraints { (maker) in
                maker.top.equalTo(createExternalGroupPromatLabel.snp.bottom).offset(10)
                maker.left.equalTo(createExternalGroupPromatLabel)
                maker.bottom.equalTo(0)
            }
            let tipsButton = UIButton() // 复选框后面的提示文字，也要支持点击事件，所以用Button
            contentView.addSubview(tipsButton)
            tipsButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.checkBoxTapHandle(checkBox: checkBox)
            }).disposed(by: disposeBag)
            tipsButton.setTitle(BundleI18n.LarkChatSetting.Lark_Chat_SyncMessage, for: .normal)
            tipsButton.setTitleColor(UIColor.ud.N900, for: .normal)
            tipsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            tipsButton.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(checkBox)
                maker.left.equalTo(checkBox.snp.right).offset(6.5)
                maker.right.lessThanOrEqualToSuperview()
            }

            syncMsgCheckBox = checkBox
        } else {
            createExternalGroupPromatLabel.snp.makeConstraints { (maker) in
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
