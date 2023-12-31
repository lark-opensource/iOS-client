//
//  ChatChatterViewController.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/2/24.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import EENavigator
import LarkModel
import LKCommonsLogging
import LarkMessengerInterface
import LarkActionSheet
import LarkFeatureGating
import RxRelay
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkAlertController
import LarkSDKInterface
import LarkContainer
import RustPB
import LarkMessageCore

final class ChatChatterControllerLifeCircleImpl: ChatChatterControllerLifeCircle {
    private var isFirstLoad = false
    private let tracker: GroupChatDetailTracker
    private var map: [String: CFTimeInterval] = [:]
    private var removeStartTimeStamp: CFTimeInterval = 0

    init(_ tracker: GroupChatDetailTracker) {
        self.tracker = tracker
    }

    func onDataLoad(_ error: Error?) {
        if let error = error {
            tracker.error(error)
            return
        }
        if isFirstLoad {
            return
        }
        isFirstLoad = true
        tracker.sdkCostEnd()
        tracker.end()
    }

    func onSearchBegin(key: String) {
        map[key] = CACurrentMediaTime()
    }

    func onSearchResult(key: String?, _ error: Error?) {
        if let error = error {
            tracker.actionError(error, action: .search)
            return
        }
        if let start = map.removeValue(forKey: key ?? "") {
            tracker.actionCost(CACurrentMediaTime() - start, action: .search)
        }
    }

    func onRemoveBegin() {
        removeStartTimeStamp = CACurrentMediaTime()
    }

    func onRemoveEnd(_ error: Error?) {
        if let error = error {
            removeStartTimeStamp = 0
            tracker.actionError(error, action: .delete)
            return
        }
        if removeStartTimeStamp != 0 {
            tracker.actionCost(CACurrentMediaTime() - removeStartTimeStamp, action: .delete)
        }
    }
}

// 普通群群成员列表
final class GroupChatterViewController: BaseSettingController {
    static let logger = Logger.log(GroupChatterViewController.self, category: "Module.IM.GroupChatterViewController")

    private var table: ChatChatterController
    private var pickerToolBar = DefaultPickerToolBar()
    private var chatId: String {
        chat.id
    }

    private var isTransferMode: Bool {
        if case .transfer(_) = mode {
            return true
        }
        return false
    }
    private var mode: GroupChatterControllerMode
    private let isOwner: Bool

    // 是否是群管理
    var isGroupAdmin: Bool {
        chat.isGroupAdmin
    }

    // 移除按钮
    private lazy var rightRemoveItem: UIBarButtonItem = {
        return UIBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Remove,
                               style: .plain,
                               target: self,
                               action: #selector(toggleViewSelectStatus))
    }()

    // ... 按钮
    private lazy var rightMoreItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: Resources.icon_more_outlined, title: nil)
        item.addTarget(self, action: #selector(moreItemTapped), for: .touchUpInside)
        return item
    }()

    // 添加按钮
    private lazy var rightAddItem: UIBarButtonItem = {
        return UIBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Add,
                               style: .plain,
                               target: self,
                               action: #selector(addItemTapped))
    }()

    private var chat: Chat {
        chatPushWrapper.chat.value
    }
    private let chatPushWrapper: ChatPushWrapper
    private var isRemove: Bool = false
    private let isThread: Bool
    private let tracker: GroupChatDetailTracker
    private let lifeCircle: ChatChatterControllerLifeCircleImpl
    private let navi: Navigatable

    var tranferLifeCycleCallback: ((TransferGroupOwnerLifeCycle) -> Void)?
    var canSildeRelay = BehaviorRelay<Bool>(value: true)
    var displayMode: ChatChatterDisplayMode?
    var isAccessToAddMember: Bool
    let viewModel: ChatChatterControllerVM
    init(viewModel: ChatChatterControllerVM,
         chatPushWrapper: ChatPushWrapper,
         mode: GroupChatterControllerMode = .default,
         isOwner: Bool = false,
         isAccessToAddMember: Bool,
         displayMode: ChatChatterDisplayMode? = nil,
         tracker: GroupChatDetailTracker,
         navi: Navigatable) {
        self.viewModel = viewModel
        self.navi = navi
        self.chatPushWrapper = chatPushWrapper
        self.isThread = viewModel.isThread
        self.displayMode = displayMode
        self.table = ChatChatterController(viewModel: viewModel, canSildeRelay: canSildeRelay)
        self.lifeCircle = ChatChatterControllerLifeCircleImpl(tracker)
        self.table.lifeCircle = self.lifeCircle
        self.mode = mode
        self.isOwner = isOwner
        self.tracker = tracker
        self.isAccessToAddMember = isAccessToAddMember
        super.init(nibName: nil, bundle: nil)
        self.addChild(table)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tracker.sdkCostStart()

        pickerToolBar.setItems(pickerToolBar.toolbarItems(), animated: false)
        pickerToolBar.allowSelectNone = false
        pickerToolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in
            self?.confirmRemove()
            guard let buriedPointChat = self?.chat else { return }
            NewChatSettingTracker.imGroupMemberDelClick(chat: buriedPointChat)
        }
        pickerToolBar.isHidden = true
        self.view.addSubview(pickerToolBar)
        self.pickerToolBar.snp.makeConstraints {
            $0.height.equalTo(49)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(self.avoidKeyboardBottom)
        }

        self.view.addSubview(table.view)
        table.view.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.bottom.left.right.equalToSuperview()
        }

        self.view.bringSubviewToFront(pickerToolBar)

        let memberTitle: String
        if isTransferMode {
            if isThread {
                memberTitle = BundleI18n.LarkChatSetting.Lark_Groups_LeaveCircleDialogAssignNewOwnerButton
            } else {
                memberTitle = BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwner
            }
        } else {
            if isThread {
                memberTitle = BundleI18n.LarkChatSetting.Lark_Groups_member
            } else {
                memberTitle = BundleI18n.LarkChatSetting.Lark_Legacy_GroupShowMemberTitle
            }
        }
        title = memberTitle

        // 转让群主模式不显示右边的item
        if isTransferMode || !isAccessToAddMember {
            navigationItem.rightBarButtonItem = nil
        } else {
            // 群主/群管理员展示“...”按钮, 非群主展示“添加”按钮
            navigationItem.rightBarButtonItem = (isGroupAdmin ||
                                                 isOwner ||
                                                 self.viewModel.isSupportAlphabetical) ? self.rightMoreItem : self.rightAddItem
        }
        bandingTableEvent()
        tracker.viewDidLoadEnd()
        if let model = displayMode {
            switch model {
            case .multiselect:
                NewChatSettingTracker.imChatSettingDelMemberClick(chatId: chatId, source: .sectionDel)
                switchToRemove()
                isRemove.toggle()
            case .display:
                break
            }
        }
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.viewModel.clearOrderedChatChatters()

        super.dismiss(animated: flag, completion: completion)
    }

    @objc
    private func moreItemTapped() {
        if self.isRemove {
            NewChatSettingTracker.imGroupMemberDelClickCancel(chat: self.chat)
            self.switchToDisplay()
            self.isRemove.toggle()
        } else {
            guard let moreView = self.rightMoreItem.customView else {
                return
            }
            let actionSheet = UDActionSheet(
                config: UDActionSheetUIConfig(
                    isShowTitle: false,
                    popSource: UDActionSheetSource(sourceView: moreView, sourceRect: moreView.bounds, arrowDirection: .up)))
            actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_IM_GroupMembersMobile_AddMembers_Button) { [weak self] in
                self?.addGroupMember()
            }
            if self.viewModel.isSupportAlphabetical {
                actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_IM_GroupMembersMobile_SortMembers_Button) { [weak self] in
                    guard let self = self else { return }
                    let vc = GroupChatterOrderSelectViewController(defaultType: self.viewModel.sortType) { [weak self] order in
                        guard let self = self, order != self.viewModel.sortType else { return }
                        if let view = self.view.window {
                            let text = BundleI18n.LarkChatSetting.Lark_IM_GroupMembers_SortingChanged_Toast
                            UDToast.showTips(with: text, on: view)
                        }
                        self.table.reset()
                        self.viewModel.updateSortType(order)
                    }

                    self.present(LkNavigationController(rootViewController: vc), animated: true)
                }
            }
            if self.viewModel.canExportMembers {
                let chat = self.viewModel.chat
                actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_IM_ViewGroupMemberProfileData_Button) { [weak self] in
                    self?.viewModel.exportMembers(delay: 0.5, showLoadingIn: self?.view, loadingText: nil)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: {
                            UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_IM_ViewGroupMemberProfileData_Generating_Toast, on: self?.view ?? UIView())
                            NewChatSettingTracker.imGroupMemberExportClick(chat: chat, success: true)
                        }, onError: { [weak self] error in
                            UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: self?.view ?? UIView(), error: error)
                            NewChatSettingTracker.imGroupMemberExportClick(chat: chat, success: false)
                        })
                        .disposed(by: self?.viewModel.disposeBag ?? DisposeBag())
                }
                NewChatSettingTracker.imGroupMemberExportView(chat: chat)
            }
            if chat.userCount > 1, isGroupAdmin || isOwner {
                actionSheet.addDestructiveItem(text: BundleI18n.LarkChatSetting.Lark_IM_GroupMembersMobile_RemoveMembers_Button) { [weak self] in
                    guard let self = self else { return }
                    if !self.isRemove {
                        NewChatSettingTracker.imChatSettingDelMemberClick(chatId: self.chatId, source: .listMore)
                        self.switchToRemove()
                        self.isRemove.toggle()
                    }
                }
            }

            actionSheet.setCancelItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel) {
            }
            self.present(actionSheet, animated: true, completion: nil)
        }
    }

    private func addGroupMember() {
        guard isOwner || isGroupAdmin || chat.addMemberPermission == .allMembers else {
            if let view = self.view.window {
                let text = BundleI18n.LarkChatSetting.Lark_Group_OnlyGroupOwnerAdminInviteMembers
                UDToast.showTips(with: text, on: view)
            }
            return
        }

        // 外部群 && 非密聊
        if chat.isCrossTenant, !chat.isCrypto {
            let body = ExternalGroupAddMemberBody(chatId: chat.id, source: .listMore)
            self.navi.open(body: body, from: self)
        } else {
            let body = AddGroupMemberBody(chatId: chat.id, source: .listMore)
            self.navi.open(body: body, from: self)
        }
    }

    @objc
    private func addItemTapped() {
        self.addGroupMember()
    }

    @objc
    private func toggleViewSelectStatus() {
        if isRemove {
            switchToDisplay()
        } else {
            NewChatSettingTracker.imChatSettingDelMemberClick(chatId: chatId, source: .listMore)
            switchToRemove()
        }
        isRemove.toggle()
    }
}

private extension GroupChatterViewController {
    func confirmRemove() {
        table.removeSelectedItems()
        toggleViewSelectStatus()
    }

    func switchToRemove() {
        canSildeRelay.accept(false)
        self.table.cancelEditting()
        ChatSettingTracker.trackRemoveMemberClick(chat: self.chat)
        self.rightMoreItem.reset(title: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel, image: nil)
        title = BundleI18n.LarkChatSetting.Lark_Legacy_GroupSettingRemoveMembers
        self.pickerToolBar.isHidden = false

        table.view.snp.remakeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.bottom.equalTo(pickerToolBar.snp.top)
        }

        table.displayMode = .multiselect
    }

    func switchToDisplay() {
        canSildeRelay.accept(true)
        self.rightMoreItem.reset(title: nil, image: Resources.icon_more_outlined)
        title = BundleI18n.LarkChatSetting.Lark_Legacy_GroupShowMemberTitle

        self.pickerToolBar.isHidden = true
        self.pickerToolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        table.view.snp.remakeConstraints { (maker) in
            maker.top.bottom.left.right.equalToSuperview()
        }

        table.displayMode = .display
    }

    func bandingTableEvent() {
        table.onSelected = { [weak self] (_, items) in
             self?.pickerToolBar.updateSelectedItem(
                firstSelectedItems: items,
                secondSelectedItems: [],
                updateResultButton: true)
        }

        table.onDeselected = { [weak self] (_, items) in
            self?.pickerToolBar.updateSelectedItem(
                firstSelectedItems: items,
                secondSelectedItems: [],
                updateResultButton: true)
        }

        table.onTap = { [weak self] (item) in
            //目标预览场景的群成员列表不支持点击
            guard let self = self, let chatter = item.itemUserInfo as? Chatter, !self.viewModel.useLeanCell else { return }
            if case .transfer(let mode) = self.mode {
                let titleString: String
                let messageString: String
                if self.isThread {
                    titleString = BundleI18n.LarkChatSetting.Lark_Groups_LeaveCircleDialogAssignNewOwnerButton
                    messageString = BundleI18n.LarkChatSetting.Lark_Groups_AssignNewCircleOwnerDialogContentMobile(item.itemName)
                } else {
                    titleString = BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwner
                    messageString = BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoTransferSure(item.itemName)
                }
                self.showAlert(
                    title: titleString,
                    message: messageString,
                    sureHandler: { [weak self] _ in
                        guard let `self` = self else { return }
                        self.tranferLifeCycleCallback?(.before)
                        self.transferGroupOwner(chatId: self.chatId, ownerId: chatter.id, mode: mode)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { [weak self] _ in
                                self?.tranferLifeCycleCallback?(.success)
                            }, onError: { [weak self] (error) in
                                self?.table.reloadData()
                                self?.tranferLifeCycleCallback?(.failure(error, chatter.id))
                            })
                            .disposed(by: self.viewModel.disposeBag)

                    },
                    cancelHandler: nil
                )
            } else {
                let body = PersonCardBody(chatterId: chatter.id,
                                          chatId: self.chatId,
                                          source: .chat)
                self.navi.presentOrPush(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepareForPresent: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            }
        }

        table.onClickSearch = { [weak self] in
            guard let chat = self?.chat else {
                return
            }
            ChatSettingTracker.trackFindMemberClick(chat: chat)
        }
    }

    private func transferGroupOwner(chatId: String,
                                    ownerId: String,
                                    mode: TransferGroupOwnerMode) -> Observable<Void> {
        switch mode {
        case .assign:
            return viewModel.chatAPI.transferGroupOwner(chatId: chatId, ownerId: ownerId).map { _ in }
        case .leaveAndAssign:
            return viewModel.chatAPI.deleteChatters(chatId: chatId, chatterIds: [viewModel.currentChatterId], newOwnerId: ownerId).map { _ in }
        }
    }
}
