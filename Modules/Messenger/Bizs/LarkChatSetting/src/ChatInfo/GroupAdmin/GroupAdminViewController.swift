//
//  GroupAdminViewController.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/4/23.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LarkCore
import LarkAlertController
import LKCommonsLogging
import LarkSDKInterface
import LarkKeyCommandKit
import LarkKeyboardKit
import UniverseDesignDialog
import UniverseDesignActionPanel
import LKCommonsTracker
import LarkMessengerInterface
import EENavigator
import UniverseDesignToast
import RxRelay
import RxSwift
import Homeric
import LarkContainer

/// 群管理员控制器
/// doc： https://bytedance.feishu.cn/docs/doccnZsr3c82ugHpvyvOH6ssZma#
public final class GroupAdminViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    static let logger = Logger.log(GroupAdminViewController.self, category: "Module.IM.LarkChatSetting")
    private let disposeBag = DisposeBag()

    private var selectedView = SelectedCollectionView()
    // 使用chatChatter的base tableView，如果后续支持搜索则可快速兼容
    private lazy var tableView: ChatChatterBaseTable = ChatChatterBaseTable(frame: .zero, style: .plain)
    private var pickerToolBar = DefaultPickerToolBar()
    private(set) var viewModel: GroupAdminViewModel
    public private(set) var selectedItems: [ChatChatterItem] = []
    private var reloadOb: Observable<Void> {
        viewModel.reloadOb
    }
    private var datas: [ChatChatterItem] {
        viewModel.datas
    }
    private var isViewDidApper: Bool = false
    public var showSelectedView: Bool = true
    public var displayMode = ChatChatterDisplayMode.display {
        didSet {
            guard isViewDidApper else { return }
            self.tableView.reloadData()
            if displayMode == .display {
                selectedView.removeSelectAllItems()
                selectedItems = []
                refreshUI(0)
            }
        }
    }

    // ... 按钮
    private lazy var rightMoreItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: Resources.icon_more_outlined, title: nil)
        item.addTarget(self, action: #selector(moreItemTapped), for: .touchUpInside)
        return item
    }()
    private var isRemove: Bool = false

    public init(viewModel: GroupAdminViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        // config UI
        self.configVC()
        self.configSelectedView()
        self.configTableView()
        self.configToolbar()

        // process data
        viewModel.observeData()
        self.reloadOb
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                // 暂时数据量少直接全量更新，后续数据量大可考虑diff
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)

        self.displayMode = viewModel.initDisplayMode
        switch self.displayMode {
        case .multiselect:
            switchToRemove()
            isRemove.toggle()
        case .display:
            break
        }
    }

    private func configToolbar() {
        pickerToolBar.setItems(pickerToolBar.toolbarItems(), animated: false)
        pickerToolBar.allowSelectNone = false
        pickerToolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in
            self?.patchAdmin(toDeleteUserIds: self?.selectedItems.map { $0.itemId } ?? [])
            self?.moreItemTapped()
        }
        pickerToolBar.isHidden = true
        self.view.addSubview(pickerToolBar)
        self.pickerToolBar.snp.makeConstraints {
            $0.height.equalTo(49)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(self.avoidKeyboardBottom)
        }
        self.view.bringSubviewToFront(pickerToolBar)
    }

    private func configVC() {
        self.title = viewModel.title
        navigationItem.rightBarButtonItem = self.rightMoreItem
    }

    @objc
    private func moreItemTapped() {
        let chat = self.viewModel.chat
        let myUserId = self.viewModel.myUserId
        if self.isRemove {
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
            actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_AddGroupAdmins_Mobile) { [weak self] in
                NewChatSettingTracker.imGroupAdminClick(chat: chat, myUserId: myUserId, isOwner: true, isAdmin: false, clickType: "assign_admin")
                self?.onTapAddNewAdmin()
            }
            actionSheet.addDestructiveItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_RemoveGroupAdmins) { [weak self] in
                NewChatSettingTracker.imGroupAdminClick(chat: chat, myUserId: myUserId, isOwner: true, isAdmin: false, clickType: "delete_admin")
                guard let `self` = self else { return }
                if !self.isRemove {
                    self.switchToRemove()
                    self.isRemove.toggle()
                }
            }
            actionSheet.setCancelItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel)
            self.present(actionSheet, animated: true, completion: nil)
        }
    }

    func patchAdmin(toAddUserIds: [String] = [],
                    toDeleteUserIds: [String] = []) {
        let chat = self.viewModel.chat
        self.viewModel.chatAPI?.patchChatAdminUsers(chatId: chat.id,
                                                   toAddUserIds: toAddUserIds,
                                                   toDeleteUserIds: toDeleteUserIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let window = self?.currentWindow() {
                    UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_RemovedToast, on: window)
                }
            }, onError: { [weak self] (error) in
                if let window = self?.currentWindow() {
                    UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAdminAddFailedToast, on: window, error: error)
                }
                Self.logger.error(
                    "patchChatAdminUsers failed!",
                    additionalData: ["chatId": chat.id,
                                     "toAddUserIds": toAddUserIds.joined(separator: ","),
                                     "toDeleteUserIds": toDeleteUserIds.joined(separator: ",")],
                    error: error
                )
            })
            .disposed(by: self.disposeBag)
    }

    private func onTapCell(item: ChatChatterItem) {
        let body = PersonCardBody(chatterId: item.itemId,
                                  chatId: self.viewModel.chatId,
                                  source: .chat)
        self.viewModel.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    func onTapAddNewAdmin() {
        let chat = self.viewModel.chat
        let body = GroupAddAdminBody(chatId: chat.id,
                                     chatCount: chat.userCount,
                                     defaultUnableCancelSelectedIds: self.datas.map({ $0.itemId }),
                                     controller: self)
        self.viewModel.navigator.push(body: body, from: self)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewDidApper = true
    }

    func switchToRemove() {
        self.tableView.setEditing(false, animated: true)
        ChatSettingTracker.trackRemoveMemberClick(chat: self.viewModel.chat)
        self.rightMoreItem.reset(title: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel, image: nil)
        title = BundleI18n.LarkChatSetting.Lark_Legacy_RemoveGroupAdmins
        self.pickerToolBar.isHidden = false

        tableView.snp.remakeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(pickerToolBar.snp.top)
        }
        self.displayMode = .multiselect
    }

    func switchToDisplay() {
        self.rightMoreItem.reset(title: nil, image: Resources.icon_more_outlined)
        title = self.viewModel.title

        self.pickerToolBar.isHidden = true
        self.pickerToolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        tableView.snp.remakeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.left.right.equalToSuperview()
            maker.bottom.left.right.equalToSuperview()
        }
        self.displayMode = .display
    }

    private func configSelectedView() {
        self.view.addSubview(selectedView)
        selectedView.setSelectedCollectionView(selectItems: [], didSelectBlock: { [weak self] (item) in
            self?.selectedViewSeleced(item)
        }, animated: false)
        selectedView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.left.right.equalToSuperview()
            maker.height.equalTo(44)
        }
    }

    private func configTableView() {
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = 68
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = UIColor.ud.bgBody
        tableView.sectionIndexColor = UIColor.ud.textTitle
        tableView.lu.register(cellSelf: ChatChatterCell.self)
        tableView.register(GroupAdminHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: GroupAdminHeaderView.self))
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.bottom.left.right.equalToSuperview()
        }
    }

    func selectedViewSeleced(_ item: SelectedCollectionItem) {
        selectedItems.removeAll { $0.itemId == item.id }
        onDeselected(total: selectedItems)

        tableView.visibleCells.forEach { (cell) in
            if var _cell = cell as? ChatChatterCellProtocol, _cell.item?.itemId == item.id {
                _cell.isCheckboxSelected = false
            }
        }
        if selectedItems.isEmpty {
            refreshUI()
        }
    }

    // 选人后刷新UI
    func refreshUI(_ duration: TimeInterval = 0.25) {
        let shouldSelectedViewShow = showSelectedView && !selectedItems.isEmpty
        self.tableView.snp.updateConstraints {
            $0.top.equalTo(self.selectedView.snp.top).offset(shouldSelectedViewShow ? 44 : 0)
        }

        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
        })
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        // 抹掉背景
        tableView.deselectRow(at: indexPath, animated: true)
        // 取出对应的Cell & Item
        guard var cell = tableView.cellForRow(at: indexPath) as? ChatChatterCellProtocol,
            let item = cell.item else { return }

        switch displayMode {
        case .display:
            onTapCell(item: item)
        case .multiselect:
            guard item.isSelectedable else { return }

            if selectedItems.contains(where: { $0.itemId == item.itemId }) {
                cell.isCheckboxSelected = false
                whenDeselected(item)
            } else {
               cell.isCheckboxSelected = true
                whenSelected(item)
            }
        }
    }

    // 多选模式下，点击Cell选择
    func whenSelected(_ item: ChatChatterItem) {
        selectedItems.append(item)
        onSelected(total: selectedItems)

        guard let item = item as? SelectedCollectionItem else { return }

        self.selectedView.addSelectItem(selectItem: item)
        if selectedItems.count == 1 {
            refreshUI()
        }
    }

    // 多选模式下，点击Cell取消选择
    func whenDeselected(_ item: ChatChatterItem) {
        selectedItems.removeAll { $0.itemId == item.itemId }
        onDeselected(total: selectedItems)

        guard let item = item as? SelectedCollectionItem else { return }

        self.selectedView.removeSelectItem(selectItem: item)
        if selectedItems.isEmpty {
            refreshUI()
        }
    }

    func onSelected(total: [ChatChatterItem]) {
        self.pickerToolBar.updateSelectedItem(
           firstSelectedItems: total,
           secondSelectedItems: [],
           updateResultButton: true)
    }

    func onDeselected(total: [ChatChatterItem]) {
        self.pickerToolBar.updateSelectedItem(
            firstSelectedItems: total,
            secondSelectedItems: [],
            updateResultButton: true)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < datas.count else { return 0 }
        return datas.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.section < datas.count, indexPath.row < datas.count {

            let item = datas[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: String(describing: item.itemCellClass),
                                                 for: indexPath)

            if var itemCell = cell as? ChatChatterCellProtocol {
                itemCell.set(item, filterKey: nil, userResolver: viewModel.userResolver)
                // 重置cell状态
                itemCell.setCellSelect(canSelect: true, isSelected: false, isCheckboxHidden: true)
                if displayMode == .multiselect {
                    // 处理默认选中无法点击的cell
                    if let id = itemCell.item?.itemId, viewModel.defaultUnableSelectedIds.contains(id) {
                        itemCell.setCellSelect(canSelect: false, isSelected: true, isCheckboxHidden: false)
                    } else {
                        itemCell.isCheckboxHidden = false
                        itemCell.isCheckboxSelected = selectedItems.contains(where: { $0.itemId == item.itemId })
                    }
                } else {
                    itemCell.isCheckboxHidden = true
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.lu.reuseIdentifier, for: indexPath)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: GroupAdminHeaderView.self)) as? GroupAdminHeaderView else {
            return nil
        }
        return header
    }
}

final class GroupAdminHeaderView: UITableViewHeaderFooterView {
    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 4, right: 23))
        }
        contentLabel.text = BundleI18n.LarkChatSetting.Lark_Legacy_GroupAdminDesc
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
