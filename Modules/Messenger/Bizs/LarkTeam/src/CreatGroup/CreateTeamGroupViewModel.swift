//
//  CreateTeamGroupViewModel.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/8.
//

import UIKit
import Foundation
import RustPB
import LarkTab
import RxSwift
import LarkCore
import RxCocoa
import LarkUIKit
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface

final class CreateTeamGroupViewModel: TeamBaseViewModel {
    var name = "CreateTeamGroupPage"
    var title = BundleI18n.LarkTeam.Project_T_NewGroupOptions
    var leftItemInfo: String? = BundleI18n.LarkTeam.Lark_Legacy_Cancel
    var rightItemInfo: (Bool, String) = (true, BundleI18n.LarkTeam.Project_T_CreateButton)
    // 决定navigaitonBar右边的按钮是否可点击的事件流
    var rightItemEnableRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    weak var fromVC: UIViewController?
    weak var targetVC: TeamBaseViewControllerAbility?
    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()
    private(set) var items: TeamSectionDatasource = []

    private let disposeBag = DisposeBag()
    private let teamAPI: TeamAPI
    // 重名校验接口的disposebag，单独是为了不对当前页面产生影响
    private(set) var checkNameDisposeBag = DisposeBag()
    private let teamId: Int64
    private let chatId: String
    private let isAllowAddTeamPrivateChat: Bool
    // 是否打开消息提醒
    private let isRemind = false
    private let initGroupMode: String = "thread"

    // 创建群的模式，default = chat，threadV2 = 话题群
    private var groupMode: Chat.ChatMode = .default
    // 创建群的类型，比如密聊
    private var ability: CreateAbility = CreateAbility.thread

    private var addMemberChat = true

    // 消息可见性设置
    private let isMessageEnabled = true
    private var isMessageVisible = false
    // 群可发现设置
    private var discoverableEnabled = true
    private var discoverable = true

    // 输入框cell的viewModel， 需要持有
    lazy var teamInputItem: TeamInputCellViewModel = {
        let attributedTitle = NSMutableAttributedString(string: BundleI18n.LarkTeam.Project_T_FieldGroupName)
        attributedTitle.append(NSAttributedString(string: " *", attributes: [.foregroundColor: UIColor.ud.colorfulRed]))
        return TeamInputCellViewModel(
            type: .input,
            cellIdentifier: TeamInputCell.lu.reuseIdentifier,
            style: .full,
            title: attributedTitle,
            maxCharLength: TeamConfig.inputMaxLength,
            placeholder: BundleI18n.LarkTeam.Project_T_NameYourGroup,
            errorToast: BundleI18n.LarkTeam.Project_T_GoupNameCannotEmpty,
            reloadWithAnimation: { [weak self] animated in
                self?.targetVC?.reloadWithAnimation(animated)
            },
            textFieldDidEndEditingTask: { [weak self] (text, checkNameTask) in
                guard let self = self else { return }
                self.checkNameDisposeBag = DisposeBag()
                // 调用重名校验接口
                self.teamAPI.checkNameAvailabilityRequest(name: text, checkType: .chat, identify: "\(self.teamId)")
                    .subscribe(onNext: { res in
                        checkNameTask(res.available, BundleI18n.LarkTeam.Project_T_AlreadyTakenChange)
                    }).disposed(by: self.checkNameDisposeBag)
            }
        )
    }()
    let navigator: EENavigator.Navigatable
    let userResolver: UserResolver
    init(teamId: Int64,
         chatId: String,
         isAllowAddTeamPrivateChat: Bool,
         teamAPI: TeamAPI,
         userResolver: UserResolver) {
        self.teamAPI = teamAPI
        self.teamId = teamId
        self.chatId = chatId
        self.isAllowAddTeamPrivateChat = isAllowAddTeamPrivateChat
        self.userResolver = userResolver
        self.navigator = userResolver.navigator
    }

    func viewDidLoadTask() {
        // 发射初始化信号
        self.items = structureItems()
        _reloadData.onNext(())
        startToObserve()
        trackPageView()
    }

    func structureItems() -> TeamSectionDatasource {
        let sections = [
            self.teamConfigSection(),
            self.teamInputSection(),
            self.addTeamMemberChatSection(),
            self.privacySection()
        ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        return sections
    }

    private func teamInputSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            teamInputItem
        ].compactMap({ $0 }))
    }

    private func teamConfigSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            teamGroupModeItem()
        ].compactMap({ $0 }))
    }

    private func addTeamMemberChatSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            addTeamMemberChatItem()
        ].compactMap({ $0 }))
    }

    private func privacySection() -> TeamSectionModel? {
        guard Feature.teamChatPrivacy(userID: self.userResolver.userID) else { return nil }
        var sectionVM = TeamSectionModel(items: [
            messageVisibleItem(),
            chatVisibleItem()
        ].compactMap({ $0 }))
        sectionVM.headerTitle = BundleI18n.LarkTeam.Project_T_PrivacySettingsInTeam_Title
        return sectionVM
    }

    private func startToObserve() {
        let teamNameEnableOb = teamInputItem.rightItemEnableOb.asObservable()
        teamNameEnableOb
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isShow in
                self?.rightItemEnableRelay.accept(isShow)
            }, onError: { error in
                TeamMemberViewModel.logger.error("teamlog/teamInputItem fail, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    // navitionbar close按钮点击事件
    func closeItemClick() {
        trackCancelClick()
        guard teamInputItem.text?.isChecked ?? false else {
            self.targetVC?.dismiss(animated: true, completion: nil)
            return
        }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_MV_QuitCreatTeam_PopupWindow)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_MV_Close_Button,
                                dismissCompletion: { [weak self] in
            self?.targetVC?.dismiss(animated: true, completion: nil)
        })
        if let vc = self.targetVC {
            navigator.present(dialog, from: vc)
        }
    }

    func rightItemClick() {
        let targetVC = self.targetVC
        let window = targetVC?.view.window
        if let window = window {
            UDToast.showLoading(with: BundleI18n.LarkTeam.Project_MV_Creating, on: window)
        }
        // 调用创建团队群接口
        TeamTracker.trackCreateChatClick(isAddChatDesc: false)
        let isDiscoverable: Bool?
        if Feature.teamChatPrivacy(userID: self.userResolver.userID) {
            isDiscoverable = self.discoverable
        } else {
            isDiscoverable = nil
        }
        let teamChatType: TeamChatType
        if isMessageVisible {
            teamChatType = .open
        } else {
            teamChatType = .private
        }
        teamAPI.createTeamChatRequest(teamId: teamId,
                                      mode: self.groupMode,
                                      groupName: teamInputItem.text?.removeCharSpace ?? "",
                                      isRemind: self.isRemind,
                                      teamChatType: teamChatType,
                                      addMemberChat: addMemberChat,
                                      isDiscoverable: isDiscoverable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                if let window = window {
                    UDToast.showSuccess(with: BundleI18n.LarkTeam.Project_MV_CreatedSuccessfullyToast, on: window)
                }
                self.trackCreateClick(teamId: String(self.teamId), chatId: res.chat.id)
                targetVC?.dismiss(animated: true, completion: { [weak self] in
                    self?.openAddMemberPage(chatId: res.chat.id)
                })
            }, onError: { error in
                if let window = window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Project_MV_UnableToCreateToast, on: window, error: error)
                }
            }).disposed(by: self.disposeBag)
    }
}

// cellViewModel 组装的扩展
extension CreateTeamGroupViewModel {
    // 团队群模式
    private func teamGroupModeItem() -> TeamCellViewModelProtocol? {
        return TeamInfoCellViewModel(type: .groupMode,
                                     cellIdentifier: TeamInfoCell.lu.reuseIdentifier,
                                     style: .half,
                                     isShowDescription: true,
                                     isShowArrow: true,
                                     title: BundleI18n.LarkTeam.Project_T_GroupTypeTitle,
                                     description: groupMode.getDescription()) { [weak self] _ in
            guard let self = self else { return }
            let modeType: ModelType
            // 跳转团队模式设置页面
            switch self.groupMode {
            case .default:
                modeType = .chat
            case .threadV2:
                modeType = .thread
            case .thread:
                modeType = .thread
            case .unknown:
                modeType = .chat
            }
            let body = GroupModeViewBody(
                modeType: modeType,
                ability: self.ability,
                hasSelectedExternalChatter: false,
                hasSelectedChatOrDepartment: false,
                completion: { [weak self] modeType in
                    guard let self = self else { return }
                    switch modeType {
                    case .chat:
                        self.groupMode = .default
                    case .thread:
                        self.groupMode = .threadV2
                    case .secret, .privateChat:
                        break
                    }
                    self.items = self.structureItems()
                    self._reloadData.onNext(())
                }
            )
            if let vc = self.targetVC {
                self.navigator.push(body: body, from: vc)
            }
        }
    }

    // 团队群模式
    // 普通成员添加群的权限
    private func addTeamMemberChatItem() -> TeamCellViewModelProtocol? {
        let desc = addMemberChat ? BundleI18n.LarkTeam.Project_T_TeamAccessSwitchOn : BundleI18n.LarkTeam.Project_T_TeamAccessSwitchOff
        return TeamConfigCellViewModel(type: .default,
                                           cellIdentifier: TeamConfigCell.lu.reuseIdentifier,
                                           style: .auto,
                                           title: BundleI18n.LarkTeam.Project_T_AddGroupToTeamPC,
                                           descContent: desc,
                                           status: self.addMemberChat,
                                           cellEnable: true) { [weak self] (_, status) in
            guard let self = self else { return }
            self.addMemberChat = status
            self.items = self.structureItems()
            self._reloadData.onNext(())
        }
    }

    private func messageVisibleItem() -> TeamCellViewModelProtocol? {
        let title = isMessageVisible ? BundleI18n.LarkTeam.Project_T_GroupPrivacy_Public_Title : BundleI18n.LarkTeam.Project_T_GroupPrivacy_Private_Title
        let desc = isMessageVisible ? BundleI18n.LarkTeam.Project_T_GroupPrivacy_Public_Desc : BundleI18n.LarkTeam.Project_T_GroupPrivacy_Private_Desc
        return TeamInfoCellViewModel(type: .groupMode,
                                     cellIdentifier: TeamInfoCell.lu.reuseIdentifier,
                                     style: .half,
                                     isShowDescription: true,
                                     isShowArrow: true,
                                     title: title,
                                     description: desc) { [weak self] _ in
            guard let self = self,
                 let targetVC = self.targetVC else { return }
            let vc = MessageVisibleVC(isMessageVisible: self.isMessageVisible,
                                     isMessageEnabled: self.isMessageEnabled,
                                     messageVisibility: true,
                                     errorTips: nil)
            self.navigator.push(vc, from: targetVC)
            vc.selectedCallback = { [weak self] isMessageVisible in
               guard let self = self else { return }
               self.isMessageVisible = isMessageVisible
               if isMessageVisible {
                   self.discoverable = isMessageVisible
               }
               self.discoverableEnabled = !isMessageVisible
               self.items = self.structureItems()
               self._reloadData.onNext(())
            }
        }
    }

    private func chatVisibleItem() -> TeamCellViewModelProtocol? {
        let title = BundleI18n.LarkTeam.Project_T_GroupPrivacy_MakeDiscoverable_Checkbox
        return TeamConfigCellViewModel(type: .default,
                                           cellIdentifier: TeamConfigCell.lu.reuseIdentifier,
                                           style: .auto,
                                           title: title,
                                           descContent: "",
                                           status: self.discoverable,
                                       cellEnable: self.discoverableEnabled,
                                       switchHandler: { [weak self] (_, status) in
            guard let self = self else { return }
            self.discoverable = status
            self.items = self.structureItems()
            self._reloadData.onNext(())
        }, switchunUseHandler: { [weak self] in
            guard let self = self else { return }
            let targetVC = self.targetVC
            let window = targetVC?.view.window
            if let window = window {
                UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_GroupPrivacy_MakeDiscoverable_PublicGroupCantEdit_Hover, on: window)
            }
        })
    }
}

// MARK: tool
extension CreateTeamGroupViewModel {
    private func trackPageView() {
        TeamTracker.trackImTeamCreateChatView(groupMode: initGroupMode)
    }

    private func trackCreateClick(teamId: String, chatId: String) {
        TeamTracker.trackImTeamCreateChatClick(click: "create",
                                               target: "none",
                                               teamId: teamId,
                                               isAddAsMember: "false",
                                               chatId: chatId)
    }

    private func trackCancelClick() {
        TeamTracker.trackImTeamCreateChatClick(click: "cancel",
                                               target: "none")
    }
}

// MARK: handler
extension CreateTeamGroupViewModel {
    // 跳转添加成员pick
    private func openAddMemberPage(chatId: String) {
        guard let fromVC = self.fromVC else { return }
        // 创建成功后跳转聊天页面
        let body = ChatControllerByIdBody(chatId: chatId)
        navigator.showAfterSwitchIfNeeded(
            tab: Tab.feed.url,
            body: body,
            wrap: LkNavigationController.self,
            from: fromVC)
        let chatMemberBody = AddGroupMemberBody(chatId: chatId, source: .listMore)
        navigator.open(body: chatMemberBody, from: fromVC)
    }
}

extension Chat.ChatMode {
    func getDescription() -> String {
        switch self {
        case .default:
            return BundleI18n.LarkTeam.Project_T_ChatSwitch
        case .thread, .threadV2:
            return BundleI18n.LarkTeam.Project_T_TopicSwitch
        case .unknown:
            assertionFailure("type unknown")
            return ""
        @unknown default:
            assertionFailure("type error")
            return ""
        }
    }
}
