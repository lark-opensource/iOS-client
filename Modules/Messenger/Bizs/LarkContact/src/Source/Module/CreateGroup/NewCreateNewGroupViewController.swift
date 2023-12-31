//
//  CreateNewGroupViewController.swift
//  LarkContact
//
//  Created by zc09v on 2020/12/9.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkKeyboardKit
import LarkSearchCore
import LarkContainer
import LarkAccountInterface
import RxSwift
import LarkFeatureGating
import UniverseDesignToast
import LarkAlertController
import LarkKeyCommandKit
import LarkCore
import LarkPrivacySetting
import UniverseDesignIcon

final class CreateNewGroupViewController: BaseUIViewController, PickerDelegate,
                                       CheckSearchChatterDeniedReason, ConvertOptionToSelectChatterInfo,
                                       GetSelectedUnFriendNum, UserResolverWrapper {
    private var createGroupHeaderView: CreateGroupHeaderView?
    private var createGroupFooterView: CreateGroupFooterView?
    /// 当前用户选择的对话模式：会话、话题、密聊
    private var modeType: ModelType = .chat
    /// 当前用户选择的群模式：私有、公开
    private var isPublic = false

    /// 能够创建哪些类型的群
    private let ability: CreateAbility

    private let request: CreateGroupPickBody
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?

    private var context: CreateGroupContext?
    private let picker: ChatterPicker
    private let tracker: PickerAppReciable
    // 最大可选中的未授权人数
    private lazy var maxUnauthExternalContactsSelectNumber: Int = {
        return userGeneralSettings?.contactsConfig.maxUnauthExternalContactsSelectNumber ?? 50
    }()

    private var selectedExternalChatterIds: [String] {
        var externalChatterIds: [String] = []
        let currentTenantID = passportUserService.userTenant.tenantID
        for item in self.picker.selected {
            if let chatterInfo = item as? ChatterPickerSelectedInfo,
               chatterInfo.isExternal(currentTenantId: currentTenantID) {
                externalChatterIds.append(chatterInfo.selectedInfoId)
            }
        }
        return externalChatterIds
    }

    private var _createConfirmButtonTitle: String?
    private lazy var createConfirmButtonTitle: String = {
        return _createConfirmButtonTitle ?? BundleI18n.LarkContact.Lark_Group_CreateGroup_CreateGroup_TypePublic_CreateButton
    }()
    private var customTitle: String?
    var userResolver: LarkContainer.UserResolver
    let passportUserService: PassportUserService
    // MARK: - Life Cycle
    init(ability: CreateAbility,
         request: CreateGroupPickBody,
         chatterPicker: ChatterPicker,
         tracker: PickerAppReciable,
         resolver: UserResolver,
         createConfirmButtonTitle: String? = nil,
         customTitle: String? = nil
         ) throws {
        self.ability = ability
        self.request = request
        self.picker = chatterPicker
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.picker.searchTextFieldAutoFocus = KeyboardKit.shared.keyboardType == .hardware && UIDevice.current.userInterfaceIdiom == .pad
        self.tracker = tracker
        self._createConfirmButtonTitle = createConfirmButtonTitle
        self.customTitle = customTitle
        super.init(nibName: nil, bundle: nil)
        self.picker.delegate = self
        tracker.initViewEnd()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let title = customTitle ?? BundleI18n.LarkContact.Lark_Legacy_CreategroupTitle
        self.navigationItem.titleView = PickerNavigationTitleView(
            title: title,
            observable: picker.selectedObservable,
            initialValue: []
        )

        let barItem = UIBarButtonItem(image: UDIcon.closeSmallOutlined, style: .plain, target: self, action: #selector(closeBtnTapped))
        self.navigationItem.leftBarButtonItem = barItem

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.confirmButton)

        view.addSubview(picker)
        picker.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        if self.ability != .none {
            // 点击会跳转到群类型界面
            createGroupInfoView()
        }

        self.tracker.firstRenderEnd()
        let source: String
        switch request.from {
        case .forward:
            source = "from_forward"
        case .p2pConfig:
            source = "from_p2p"
        case .plusMenu:
            source = "plus"
        case .internalToExternal:
            source = "from_inner_group"
        default:
            source = "none"
        }
        IMTracker.Group.Create.View(
            group: true,
            channel: self.ability.contains(.thread),
            history: navigationController?.toolbar is SyncMessageToolbar,
            transfer: self.request.from == .forward,
            source: source
        )
    }

    override func closeBtnTapped() {
        IMTracker.Group.Create.Click.Cancel()
        super.closeBtnTapped()
    }

    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + confirmKeyBinding
    }

    override func subProviders() -> [KeyCommandProvider] {
        return [picker]
    }
    private var confirmKeyBinding: [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .command,
                discoverabilityTitle:
                    self.createConfirmButtonTitle
            )
            .binding(handler: { [weak self] in
                guard let `self` = self else { return }
                self.finishSelected(targetVC: self)
            })
            .wraper
        ]
    }

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(didConfirm), for: .touchUpInside)
        button.setTitleColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle(self.createConfirmButtonTitle, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    @objc
    func didConfirm(_ button: UIButton) {
        self.finishSelected(targetVC: self)
    }

    func finishSelected(targetVC: UIViewController) {
        UIApplication.shared.sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)
        guard let nav = self.navigationController else {
            return
        }
        var context = CreateGroupContext()
        context.isPublic = self.isPublic
        switch self.modeType {
        case .chat:
            context.chatMode = .default
        case .thread:
            context.chatMode = .threadV2
        case .secret:
            context.chatMode = .default
            context.isCrypto = true
        case .privateChat:
            context.chatMode = .default
            context.isPrivateMode = true
        }
        self.context = context
        Tracer.tarckGroupIsPublic(isPublic: self.context?.isPublic ?? false)
        let source: String
        switch request.from {
        case .forward:
            source = "from_forward"
        case .p2pConfig:
            source = "from_p2p"
        case .plusMenu:
            source = "plus"
        case .internalToExternal:
            source = "from_inner_group"
        default:
            source = "none"
        }
        IMTracker.Group.Create.Click.Confirm(source: source,
                                             chatType: self.modeType == .thread ? "topic" : "group",
                                             public: self.isPublic,
                                             isPrivateMode: context.isPrivateMode,
                                             isSycn: false,
                                             leaveAMessage: false)

        let pickEntities = self.convertOptionToPickEntities(options: picker.selected)
        if self.context?.isPublic ?? false {
            self.showCreateGroupNameVC(navigationVC: nav,
                                       targetVC: targetVC,
                                       request: self.request,
                                       result: .pickEntities(pickEntities))

        } else {
            context.modeType = trackMode()
            context.count = self.picker.selected.count
            context.isExternal = self.hasSelectedExternalChatter()
            self.request.selectCallback?(self.context, .pickEntities(pickEntities), nav)
        }
    }

    private func trackMode() -> String {
        if modeType == .thread {
            return "topic"
        } else if modeType == .secret {
            return "secret"
        } else {
            return "classic"
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if size.width != self.view.bounds.width {
            self.createGroupHeaderView?.frame = CGRect(origin: .zero,
                                                       size: CGSize(width: size.width, height: CreateGroupHeaderView.viewHeight))
            self.createGroupFooterView?.frame = CGRect(origin: .zero,
                                                       size: CGSize(width: size.width, height: self.createGroupFooterView?.viewHeight ?? 0))
        }
    }

    private func createGroupInfoView() {
        let createGroupHeaderView = CreateGroupHeaderView(ability: self.ability, modeType: self.modeType)
        createGroupHeaderView.frame = CGRect(origin: .zero, size: CGSize(width: self.view.bounds.width, height: CreateGroupHeaderView.viewHeight))
        createGroupHeaderView.groupModeInfoView.tappedFunc = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.showGroupInfoVC()
            IMTracker.Group.Create.Click.GroupType()
        }

        let createGroupFooterView = CreateGroupFooterView()
        createGroupFooterView.frame = CGRect(origin: .zero, size: CGSize(width: self.view.bounds.width, height: createGroupFooterView.viewHeight))
        createGroupFooterView.faceToFaceGroupView?.tappedFunc = { [weak self] in
            guard let self = self else { return }
            if LarkLocationAuthority.checkAuthority() {
                let body = CreateGroupWithFaceToFaceBody(type: .createGroup)
                self.navigator.push(body: body, from: self)
                /// 进入面对面建群后清空数据源
                self.picker.selected = []
            } else {
                LarkLocationAuthority.showDisableTip(on: self.view)
            }
        }

        if let structureView = picker.defaultView as? StructureView {
            structureView.customTableViewHeader(customView: createGroupHeaderView)
            structureView.customTableViewFooter(customView: createGroupFooterView)
        }
        self.createGroupHeaderView = createGroupHeaderView
        self.createGroupFooterView = createGroupFooterView
    }

    private func hasSelectedExternalChatter() -> Bool {
        let currentTenantID = passportUserService.userTenant.tenantID
        for item in self.picker.selected {
            if item.asChatterPickerSelectedInfo()?.isExternal(currentTenantId: currentTenantID) ?? false {
                return true
            }
        }
        return false
    }

    /// 判断是否选了群/部门，创建密聊时不支持
    private func hasSelectedChatOrDepartment() -> Bool {
        for item in self.picker.selected {
            if item.optionIdentifier.type == OptionIdentifier.Types.chat.rawValue
                || item.optionIdentifier.type == OptionIdentifier.Types.department.rawValue {
                return true
            }
        }
        return false
    }

    private func showGroupInfoVC() {
        // 是否有选择外部用户
        let hasSelectedExternalChatter = self.hasSelectedExternalChatter()
        let body = GroupModeViewBody(
            modeType: self.modeType,
            ability: self.ability,
            hasSelectedExternalChatter: hasSelectedExternalChatter,
            hasSelectedChatOrDepartment: hasSelectedChatOrDepartment(),
            completion: { [weak self] modeType in
                guard let `self` = self else { return }

                self.modeType = modeType
                self.picker.includeOuterTenant = (modeType != .privateChat) && self.request.needSearchOuterTenant

                // 创群界面比较特殊，configuration.isCryptoModel需要动态调整，其他场景不需要
                self.picker.permissions = (self.modeType == .secret) ? [.inviteSameCryptoChat] : [.inviteSameChat]
                if let addChatterPicker = self.picker as? AddChatterPicker {
                    addChatterPicker.includeChat = self.modeType != .secret
                    addChatterPicker.includeDepartment = self.modeType != .secret
                }

                self.createGroupHeaderView?.groupModeInfoView.setProps(modeType: self.modeType)
            }
        )
        navigator.push(body: body, from: self)

        Tracer.trackGoupType()
    }

    private func showCreateGroupNameVC(navigationVC: UINavigationController,
                                       targetVC: UIViewController,
                                       request: CreateGroupPickBody,
                                       result: CreateGroupResult) {

        let isTopicGroup = ((self.context?.chatMode ?? Chat.ChatMode.default) == Chat.ChatMode.threadV2)
        guard let chatAPI = self.chatAPI else { return }
        let body = GroupNameVCBody(
            chatAPI: chatAPI,
            groupName: self.context?.name ?? "",
            isTopicGroup: isTopicGroup,
            nextFunc: { ( _, groupName ) in
                self.context?.name = groupName
                self.context?.modeType = self.trackMode()
                self.context?.count = self.picker.selected.count
                self.context?.isExternal = self.hasSelectedExternalChatter()
                request.selectCallback?(self.context, result, navigationVC)
            }
        )
        navigator.push(body: body, from: targetVC)
    }

    func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        if let meta = option.getSearchChatterMetaInContact() {
            return self.checkSearchChatterDeniedReasonForDisabledPick(meta)
        }
        if let v = option as? SearchResultType, case .chat(let meta) = v.meta {
            return meta.isCrossTenant
        }
        return false
    }

    func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        if let v = option as? SearchResultType, case .chat(let meta) = v.meta, meta.isCrossTenant {
            UDToast.showTips(with: BundleI18n.LarkContact.Lark_Group_UnableSelectExternalGroup, on: self.view)
            return false
        }
        if self.getSelectedUnFriendNum(self.picker.selected) >= maxUnauthExternalContactsSelectNumber {
            let alert = LarkAlertController()
            alert.setContent(text: BundleI18n.LarkContact.Lark_NewContacts_PermissionRequestSelectUserMax)
            alert.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
            present(alert, animated: true, completion: nil)
            return false
        }

        if picker.selected.contains(where: { $0.optionIdentifier == option.optionIdentifier }) {
            return true
        }

        if let chatterMeta = option.getSearchChatterMetaInContact() {
            let currentTenantID = passportUserService.userTenant.tenantID
            // 当前在创建公开群 + 选中外部联系人
            if chatterMeta.tenantID != currentTenantID, self.isPublic, let window = self.view.window {
                UDToast.showTips(with: BundleI18n.LarkContact.Lark_Chat_Add_Member_PublicChatAddExternalUser_ErrrorTip, on: window)
                return false
            }
            let checkResult = self.checkSearchChatterDeniedReasonForWillSelected(chatterMeta, on: self.view.window)
            if checkResult {
                Tracer.trackCreateGroupSelectMembers(.search)
            }
            return checkResult
        }
        return true
    }

    func unfold(_ picker: Picker) {
        let body = PickerSelectedBody(
            picker: self.picker,
            confirmTitle: self.confirmButton.titleLabel?.text ?? self.createConfirmButtonTitle,
            allowSelectNone: true,
            targetPreview: self.picker.targetPreview,
            completion: { [weak self] targetVC in
                guard let self = self else { return }
                self.finishSelected(targetVC: targetVC)
            }
        )
        navigator.push(body: body, from: self)
    }

    private func convertOptionToPickEntities(options: [Option]) -> CreateGroupResult.CreateGroupPickEntities {
        let chatterInfos = self.chatterInfos(from: options)
        var chatIds: [String] = []
        var departmentIds: [String] = []
        for i in options {
            let identifier = i.optionIdentifier
            switch identifier.type {
            case OptionIdentifier.Types.chat.rawValue:
                chatIds.append(identifier.id)
            case OptionIdentifier.Types.department.rawValue:
                departmentIds.append(identifier.id)
            default: break
            }
        }
        return CreateGroupResult.CreateGroupPickEntities(
            chatters: chatterInfos,
            chats: chatIds,
            departments: departmentIds
        )
    }
}
