//
//  MyGroupsVC.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/1/28.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkModel
import LarkSearchCore
import EENavigator
import UniverseDesignToast
import UniverseDesignEmpty
import LarkMessengerInterface
import Homeric
import LarkContainer

// 由外部去判断是否 disable，是否可选
protocol MyGroupsCheckSelectDeniedReason {
    func checkForWillSelected(_ chat: ChatterPickeSelectChatType, targetVC: UIViewController) -> Bool
    func checkForDisabledPick(with chat: ChatterPickeSelectChatType) -> Bool
}

final class MyGroupsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, HasSelectChannel, UserResolverWrapper {
    var selectChannel: SelectChannel {
        return .group
    }
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingPlaceholderView = LoadingPlaceholderView()
    private var groups: [Chat] = []
    private let disposeBag = DisposeBag()
    public var targetPreview: Bool = false
    weak var fromVC: UIViewController?

    let viewModel: GroupsViewModel
    weak var selectionSource: SelectionDataSource?
    private var checkSelectDeniedReason: MyGroupsCheckSelectDeniedReason

    struct Config {
        let selectedHandler: ((Int) -> Void)?
    }
    private let config: Config
    var userResolver: LarkContainer.UserResolver
    weak var delegate: PickerContactViewDelegate?

    deinit {
        ContactLogger.shared.info(module: .view, event: "\(self.classForCoder) deinit")
    }

    init(viewModel: GroupsViewModel, config: Config, selectionSource: SelectionDataSource, selectAbility: MyGroupsCheckSelectDeniedReason?, resolver: UserResolver) {
        let maxSize = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        viewModel.pageCount = Int(maxSize / 68 * 1.5 + 1)
        self.viewModel = viewModel
        self.selectionSource = selectionSource
        self.config = config
        self.checkSelectDeniedReason = selectAbility ?? DefaultMyGroupsCheckSelectDeniedReasonImp()
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.LarkContact.Lark_Groups_MyGroups
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBase
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 68
        tableView.register(SelectableGroupsTableViewCell.self, forCellReuseIdentifier: "SelectableGroupsTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = self.view.bounds

        loadingPlaceholderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingPlaceholderView.frame = view.bounds
        view.addSubview(loadingPlaceholderView)

        loadingPlaceholderView.isHidden = false
        self.viewModel
            .firstLoadManageGroup()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.loadingPlaceholderView.isHidden = true
            }, onError: { [weak self] _ in
                self?.loadingPlaceholderView.isHidden = true
            }, onCompleted: { [weak self] in
                self?.loadingPlaceholderView.isHidden = true
                self?.addDataEmptyViewIfNeed()
            }).disposed(by: self.disposeBag)

        self.viewModel
            .createdGroupsObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (groups) in
                guard let self = self else { return }
                self.groups = groups
                self.tableView.reloadData()
                self.bindTableViewLoadMore()
            }).disposed(by: disposeBag)

        selectionSource?.isMultipleChangeObservable.distinctUntilChanged().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        selectionSource?.selectedChangeObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        // Picker 埋点
        SearchTrackUtil.trackPickerManageGroupView()
    }

    private func bindTableViewLoadMore() {
        self.tableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            self.viewModel.loadMoreManageGroup()
                .asDriver(onErrorJustReturn: true)
                .drive(onNext: { [weak self] (isEnd) in
                    self?.tableView.enableBottomLoadMore(!isEnd)
                }).disposed(by: self.disposeBag)
        }
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SelectableGroupsTableViewCell") as? SelectableGroupsTableViewCell {
            cell.backgroundColor = UIColor.ud.bgBody
            let option = self.groups[indexPath.row]
            let status = contactCheckBoxStaus(with: option)
            let isDisable = status == .disableToSelect
            let props = SelectableGroupsCellProps(
                chat: self.groups[indexPath.row],
                currentUserType: viewModel.currentUserType,
                checkStatus: status,
                targetPreview: self.targetPreview && TargetPreviewUtils.canTargetPreview(chat: self.groups[indexPath.row]),
                isEnable: !isDisable
            )
            cell.setProps(props)
            cell.targetInfo.tag = indexPath.row
            cell.targetInfo.addTarget(self, action: #selector(presentPreviewViewController(button:)), for: .touchUpInside)
            return cell
        }
        return UITableViewCell()
    }

    @objc
    private func presentPreviewViewController(button: UIButton) {
        guard groups.count > button.tag, let fromVC = self.fromVC else { return }
        let chat = groups[button.tag]
        if !TargetPreviewUtils.canTargetPreview(chat: chat) {
            if let window = fromVC.view.window {
                UDToast.showTips(with: BundleI18n.LarkContact.Lark_IM_UnableToPreviewContent_Toast, on: window)
            }
        } else if TargetPreviewUtils.isThreadGroup(chat: chat) {
            //话题群
            let threadChatPreviewBody = ThreadPreviewByIDBody(chatID: chat.id)
            navigator.present(body: threadChatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
        } else {
            //会话
            let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: chat.id, title: chat.name)
            navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
        }
        let picker = selectionSource as? Picker
        SearchTrackUtil.trackPickerSelectClick(scene: picker?.scene, clickType: .chatDetail(target: "none"))
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)

        guard let selectionDataSource = selectionSource else { return }
        let chat = self.groups[indexPath.row]
        if let chatId = self.viewModel.chatId, chatId == chat.id {
            return
        }
        if !isSearchPicker() { // 新的SearchPicker不走这段逻辑, 完全由state控制
            if !self.checkSelectDeniedReason.checkForWillSelected(chat, targetVC: self) { return }
        }

        if selectionDataSource.toggle(option: chat,
                                      from: self,
                                      at: tableView.absolutePosition(at: indexPath),
                                      event: Homeric.PUBLIC_PICKER_SELECT_MANAGE_GROUP_CLICK,
                                      target: Homeric.PUBLIC_PICKER_SELECT_MANAGE_GROUP_VIEW),
           selectionDataSource.state(for: chat, from: self).selected {
            self.config.selectedHandler?(indexPath.row + 1)
        }
    }

    private func contactCheckBoxStaus(with chat: Chat) -> ContactCheckBoxStaus {
        // 使用新的SearchPicker时, 置灰行为统一由state函数承接
        if isSearchPicker() {
            if selectionSource?.isMultiple == true {
                if let state = self.selectionSource?.state(for: chat, from: self, category: .ownedGroup) {
                    return state.asContactCheckBoxStaus
                }
                return .unselected
            } else {
                return .invalid
            }
        }
        let multiStatusBlock: (Chat) -> ContactCheckBoxStaus = { chat in
            if let chatId = self.viewModel.chatId, chatId == chat.id {
                return .defaultSelected
            }
            let canSelected = self.checkSelectDeniedReason.checkForDisabledPick(with: chat)
            if canSelected { return .disableToSelect }
            if let state = self.selectionSource?.state(for: chat, from: self) {
                return state.asContactCheckBoxStaus
            }
            return .unselected
        }
        return selectionSource?.isMultiple == true ? multiStatusBlock(chat) : .invalid
    }
}

extension MyGroupsVC {
    private func addDataEmptyViewIfNeed() {
        if self.groups.isEmpty {
            let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_Legacy_Emptymygroup)
            let emptyDataView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noGroup))
            self.view.addSubview(emptyDataView)
            emptyDataView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.tableView.isHidden = true
        }
    }

    func isSearchPicker() -> Bool {
        guard let picker = self.selectionSource else {
            return false
        }
        return picker is SearchPickerView
    }
}

// 以群建群的选择逻辑
struct DefaultMyGroupsCheckSelectDeniedReasonImp: MyGroupsCheckSelectDeniedReason {
    func checkForDisabledPick(with chat: ChatterPickeSelectChatType) -> Bool {
        /// 外部群暂不支持以群建群功能
        if chat.isCrossTenant { return true }
        return false
    }

    func checkForWillSelected(_ chat: ChatterPickeSelectChatType, targetVC: UIViewController) -> Bool {
        /// 外部群暂不支持以群建群功能
        if chat.isCrossTenant {
            UDToast.showTips(with: BundleI18n.LarkContact.Lark_Group_UnableSelectExternalGroup, on: targetVC.view)
            return false
        }
        return true
    }
}

// 由外部指定选择逻辑
struct MyGroupsCheckSelectDeniedReasonConfigurableImp: MyGroupsCheckSelectDeniedReason {
    private let checkForDisabledPick: ((ChatterPickeSelectChatType) -> Bool)?
    private let checkForWillSelected: ((ChatterPickeSelectChatType, UIViewController) -> Bool)?

    init(checkForDisabledPick: ((ChatterPickeSelectChatType) -> Bool)?, checkForWillSelected: ((ChatterPickeSelectChatType, UIViewController) -> Bool)?) {
        self.checkForDisabledPick = checkForDisabledPick
        self.checkForWillSelected = checkForWillSelected
    }

    func checkForWillSelected(_ chat: ChatterPickeSelectChatType, targetVC: UIViewController) -> Bool { return self.checkForWillSelected?(chat, targetVC) ?? true }
    func checkForDisabledPick(with chat: ChatterPickeSelectChatType) -> Bool { return self.checkForDisabledPick?(chat) ?? false }
}

// 有picker参数的逻辑来选择
struct PickerMyGroupsCheckSelectDeniedReasonImp: MyGroupsCheckSelectDeniedReason {
    private let behavior: ChatterPicker.ContactPickerBehaviour?

    init(behavior: ChatterPicker.ContactPickerBehaviour) {
        self.behavior = behavior
    }

    func checkForWillSelected(_ chat: ChatterPickeSelectChatType, targetVC: UIViewController) -> Bool {
        guard let behavior = self.behavior else { return true }
        let pickerItem = ContactPickerResultItem(chat: chat)
        if behavior.pickerItemCanSelect?(pickerItem) == false {
            let tip = behavior.pickerItemDisableReason?(pickerItem) ?? BundleI18n.LarkContact.Lark_Group_UnableSelectExternalGroup
            UDToast.showTips(with: tip, on: targetVC.view)
            return false
        }
        return true
    }
    func checkForDisabledPick(with chat: ChatterPickeSelectChatType) -> Bool {
        guard let `behavior` = behavior else { return false }
        let pickerItem = ContactPickerResultItem(chat: chat)
        if let canSelected = behavior.pickerItemCanSelect?(pickerItem) {
            return !canSelected
        }
        return false
    }
}
