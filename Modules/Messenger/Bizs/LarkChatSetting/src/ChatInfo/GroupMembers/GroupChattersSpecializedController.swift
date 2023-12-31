//
//  GroupChattersSpecializedController.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/8/25.
//

import UIKit
import Foundation
import LarkUIKit
import RxCocoa
import RxSwift
import RxRelay
import LarkCore
import LarkModel
import LKCommonsLogging
import EENavigator
import LarkMessengerInterface
import LarkActionSheet
import UniverseDesignToast
import RustPB
import UniverseDesignActionPanel
import LarkContainer

// 特化的群成员列表，目前是部门群群主可以用到这个列表
// 命名为了和SDK一致
final class GroupChattersSpecializedController: BaseSettingController, GroupChattersSingleUIDependencyProtocol {
    var userResolver: UserResolver { viewModel.userResolver }
    private let disposeBag = DisposeBag()

    // MARK: - picker
    private var isRemove: Bool = false
    private lazy var rightItem: LKBarButtonItem = createRightItem()

    private lazy var selectedView = SelectedCollectionView()
    private lazy var pickerToolBar: DefaultPickerToolBar = self.createPickerToolBar()

    // MARK: - display
    private lazy var segmentView: SegmentView = self.createSegment()
    private var childrenTable: [GroupChattersSingleController] = []

    // MARK: - Search
    private lazy var searchWrapper = SearchUITextFieldWrapperView()
    private lazy var searchTextField: SearchUITextField = {
        searchWrapper.searchUITextField.placeholder = BundleI18n.LarkChatSetting.Lark_Legacy_SearchMember
        return searchWrapper.searchUITextField
    }()

    private let viewModel: GroupChattersSpecializedViewModel
    private var selectedItems: [ChatChatterItem] = [] {
        didSet { selectedItemsRelay.accept(selectedItems) }
    }

    let tracker: GroupChatDetailTracker

    // GroupChattersSingleUIDependencyProtocol
    private(set) var displayMode = BehaviorRelay<ChatChatterDisplayMode>(value: .display)
    private(set) var searchKey = BehaviorRelay<String?>(value: nil)
    private(set) var selectedItemsRelay = BehaviorRelay<[ChatChatterItem]>(value: [])

    init(viewModel: GroupChattersSpecializedViewModel,
         displayMode: ChatChatterDisplayMode,
         tracker: GroupChatDetailTracker) {
        self.viewModel = viewModel
        self.tracker = tracker
        super.init(nibName: nil, bundle: nil)
        self.displayMode.accept(displayMode)
        viewModel.targetViewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.searchWrapper)
        self.searchWrapper.snp.makeConstraints { $0.top.left.right.equalToSuperview() }

        self.view.addSubview(self.segmentView)
        self.segmentView.snp.makeConstraints {
            $0.top.equalTo(self.searchWrapper.snp.bottom).offset(0)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        self.createTable()
        self.setupSelectedCollectionView()

        self.title = getMemberString()
        if (viewModel.ownerID == viewModel.currentChatterID) || viewModel.isGroupAdmin {
            self.navigationItem.rightBarButtonItem = self.rightItem
            switch self.displayMode.value {
            case .multiselect:
                NewChatSettingTracker.imChatSettingDelMemberClick(chatId: viewModel.chatID, source: .listMore)
                switchToRemove()
                isRemove.toggle()
            case .display:
                break
            }
        }
        self.bindSearchEvent()
        tracker.viewDidLoadEnd()
    }

    private func getMemberString() -> String {
        return viewModel.isThread ?
            BundleI18n.LarkChatSetting.Lark_Groups_member :
            BundleI18n.LarkChatSetting.Lark_Legacy_GroupShowMemberTitle
    }

    @objc
    private func moreItemTapped() {
        if self.isRemove {
            self.switchToDisplay()
            self.isRemove.toggle()
        } else {
            guard let moreItemView = rightItem.customView else {
                return
            }
            let actionSheet = UDActionSheet(
                config: UDActionSheetUIConfig(
                    isShowTitle: false,
                    popSource: UDActionSheetSource(
                        sourceView: moreItemView, sourceRect: moreItemView.bounds, arrowDirection: .up)))
            actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_IM_GroupMembersMobile_AddMembers_Button) { [weak self] in
                self?.addGroupMember()
            }
            if self.viewModel.isSupportAlphabetical {
                actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_IM_GroupMembersMobile_SortMembers_Button) { [weak self] in
                    guard let self = self else { return }
                    let vc = GroupChatterOrderSelectViewController(defaultType: self.childrenTable[0].sortType) { [weak self] order in
                        guard let self = self, order != self.childrenTable[0].sortType else { return }
                        if let view = self.view.window {
                            let text = BundleI18n.LarkChatSetting.Lark_IM_GroupMembers_SortingChanged_Toast
                            UDToast.showTips(with: text, on: view)
                        }
                        self.childrenTable[0].updateSortType(order)
                    }

                    self.present(LkNavigationController(rootViewController: vc), animated: true)
                }
            }
            let chat = self.viewModel.chat
            if self.viewModel.canExportMembers {
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
            actionSheet.addDestructiveItem(text: BundleI18n.LarkChatSetting.Lark_IM_GroupMembersMobile_RemoveMembers_Button) { [weak self] in
                guard let `self` = self else { return }
                if !self.isRemove {
                    NewChatSettingTracker.imChatSettingDelMemberClick(chatId: self.viewModel.chatID, source: .listMore)
                    self.switchToRemove()
                    self.isRemove.toggle()
                }
            }
            actionSheet.setCancelItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel)
            self.present(actionSheet, animated: true, completion: nil)
        }
    }

    private func addGroupMember() {
        let chat = viewModel.chat
        // 外部群 && 非密聊
        if  chat.isCrossTenant, !chat.isCrypto {
            let body = ExternalGroupAddMemberBody(chatId: chat.id, source: .listMore)
            self.viewModel.navigator.open(body: body, from: self)
        } else {
            let body = AddGroupMemberBody(chatId: chat.id, source: .listMore)
            self.viewModel.navigator.open(body: body, from: self)
        }
    }
}

// MARK: - create subview
private extension GroupChattersSpecializedController {
    func createRightItem() -> LKBarButtonItem {
        let item = LKBarButtonItem(image: Resources.icon_more_outlined, title: nil)
        item.addTarget(self, action: #selector(moreItemTapped), for: .touchUpInside)
        return item
    }

    func createSegment() -> SegmentView {
        let segment = StandardSegment()
        segment.height = 40
        segment.lineStyle = .adjust
        segment.titleFont = UIFont.systemFont(ofSize: 14)
        segment.titleNormalColor = UIColor.ud.N600
        let view = SegmentView(segment: segment)
        return view
    }

    func createChildrenTable(
        _ condition: RustPB.Im_V1_GetChatChattersRequest.Condition
    ) -> GroupChattersSingleController {
        let viewModel = GroupChattersSingleViewModel(
            userResolver: userResolver,
            dependency: self.viewModel,
            condition: condition,
            supportShowDepartment: self.viewModel.supportShowDepartment)
        let controller = GroupChattersSingleController(viewModel: viewModel, dependency: self)
        self.addChild(controller)
        return controller
    }

    func createTable() {
        let commonController = createChildrenTable(.noLimit)
        let nonDepartmentController = createChildrenTable(.nonDepartment)

        childrenTable.append(commonController)
        childrenTable.append(nonDepartmentController)

        self.segmentView.set(views: [
            (title: getMemberString(), view: commonController.view),
            (title: BundleI18n.LarkChatSetting.Lark_Group_NonDepartmentMembers_Mobile_Tab, view: nonDepartmentController.view)
        ])

        (self.segmentView.segment as? StandardSegment)?.selectedIndexDidChangeBlock = { _, newIndex in
            if newIndex == 1 {
                ChatSettingTracker.filterNonTeamMembers()
            }
        }
    }

    func setupSelectedCollectionView() {
        self.view.addSubview(selectedView)
        selectedView.setSelectedCollectionView(selectItems: [], didSelectBlock: { [weak self] (item) in
            self?.selectedViewTap(item: item)
        }, animated: false)

        selectedView.snp.makeConstraints { (maker) in
            maker.top.equalTo(searchWrapper.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(44)
        }
        selectedView.isHidden = true
    }

    func createPickerToolBar() -> DefaultPickerToolBar {
        let toolBar = DefaultPickerToolBar()
        toolBar.setItems(toolBar.toolbarItems(), animated: false)
        toolBar.allowSelectNone = false
        toolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        toolBar.confirmButtonTappedBlock = { [weak self] _ in self?.confirmRemove() }
        toolBar.isHidden = true
        self.view.addSubview(toolBar)

        toolBar.snp.makeConstraints {
            $0.height.equalTo(49)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(self.avoidKeyboardBottom)
        }
        return toolBar
    }
}

// MARK: - UI事件：移除按钮点击、SearchBar 输入、切换Segment、反选
private extension GroupChattersSpecializedController {
    func switchToRemove() {
        ChatSettingTracker.trackRemoveMemberClick(chat: self.viewModel.chat)
        self.rightItem.reset(title: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel, image: nil)
        title = BundleI18n.LarkChatSetting.Lark_Legacy_GroupSettingRemoveMembers
        self.pickerToolBar.isHidden = false

        segmentView.snp.remakeConstraints {
            $0.top.equalTo(self.searchWrapper.snp.bottom).offset(0)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(pickerToolBar.snp.top)
        }
        displayMode.accept(.multiselect)
    }

    func switchToDisplay() {
        // NavBar
        self.rightItem.reset(title: nil, image: Resources.icon_more_outlined)
        title = getMemberString()

        // picker bar
        self.pickerToolBar.isHidden = true
        self.pickerToolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)

        // 数据清理
        self.selectedItems.removeAll()
        self.selectedView.removeSelectAllItems()

        // segmentView & Selected View约束
        segmentView.snp.remakeConstraints {
            $0.top.equalTo(self.searchWrapper.snp.bottom).offset(0)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        refreshUI()

        // Table
        displayMode.accept(.display)
    }

    func toggleViewSelectStatus() {
        if isRemove {
            switchToDisplay()
        } else {
            switchToRemove()
        }
        isRemove.toggle()
    }

    func confirmRemove() {
        viewModel.removeChatters(with: selectedItems.map { $0.itemId })
        toggleViewSelectStatus()
    }

    func bindSearchEvent() {
        self.searchTextField.rx.text
            .skip(1)
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: self.searchKey)
            .disposed(by: disposeBag)
    }

    // 选人后刷新UI
    func refreshUI(_ duration: TimeInterval = 0.25) {
        let shouldSelectedViewShow = displayMode.value == .multiselect && !selectedItems.isEmpty
        self.selectedView.isHidden = !shouldSelectedViewShow
        self.segmentView.snp.updateConstraints {
            $0.top.equalTo(self.searchWrapper.snp.bottom).offset(shouldSelectedViewShow ? 44 : 0)
        }

        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
        })
    }

    // 顶部SelectedView 反选
    func selectedViewTap(item: SelectedCollectionItem) {
        self.selectedItems.removeAll(where: { $0.itemId == item.id })
    }
}

// MARK: - GroupChattersSingleUIDependencyProtocol 中的方法部分
extension GroupChattersSpecializedController {
    /// 尝试结束搜索框的编辑态
    private func tryResignFirstResponder() {
        if self.searchTextField.canResignFirstResponder {
            self.searchTextField.resignFirstResponder()
        }
    }

    /// 当列表的某一项被点击
    /// - Parameter item: 被点击的Item
    /// - Parameter updateCell: 更新Cell选中态的回调
    func onTapItem(_ item: ChatChatterItem, updateCell: (_ isSelectd: Bool) -> Void) {
        self.tryResignFirstResponder()
        if displayMode.value == .display {
            let body = PersonCardBody(chatterId: item.itemId,
                                      chatId: viewModel.chatID,
                                      source: .chat)
            self.viewModel.navigator.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: self,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
            return
        }

        // 如果已被选中
        if let index = self.selectedItems.firstIndex(where: { $0.itemId == item.itemId }) {
            // 数据
            self.selectedItems.remove(at: index)

            // 顶部SelectedView
            if let selecteItem = item as? SelectedCollectionItem {
                self.selectedView.removeSelectItem(selectItem: selecteItem)
            }

            // cell
            updateCell(false)
        } else {
            self.selectedItems.append(item)
            if let selecteItem = item as? SelectedCollectionItem {
                self.selectedView.addSelectItem(selectItem: selecteItem)
            }
            updateCell(true)
        }

        // 底部Toolbar
        self.pickerToolBar.updateSelectedItem(
            firstSelectedItems: selectedItems,
            secondSelectedItems: [],
            updateResultButton: true)

        if selectedItems.count == 1 || selectedItems.isEmpty {
            refreshUI()
        }
    }

    func onTableDragging() {
        self.tryResignFirstResponder()
    }

    func isItemSelected(_ item: ChatChatterItem) -> Bool {
        return selectedItems.contains(where: { $0.itemId == item.itemId })
    }
}
