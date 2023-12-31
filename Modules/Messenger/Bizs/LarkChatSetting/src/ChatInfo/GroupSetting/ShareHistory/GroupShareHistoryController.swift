//
//  GroupShareHistoryController.swift
//  Action
//
//  Created by kongkaikai on 2019/7/23.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import EENavigator
import LarkMessengerInterface
import UniverseDesignEmpty
import FigmaKit

final class GroupShareHistoryController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {
    private let disposeBag = DisposeBag()

    private lazy var emptyView: UIView = {
        let desc = UDEmptyConfig.Description(descriptionText: self.viewModel.emptyDataContent())
        let config = UDEmptyConfig(description: desc, type: .defaultPage)
        let view = UDEmptyView(config: config)
        return view
    }()

    // 使用 grouped 避免SectionHeader悬停
    private let table = InsetTableView(frame: .zero)
    private let rightItem = LKBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Chat_DeactivateShare)
    private lazy var pickerToolBar = self.createPickerToolBar()

    private var isDispaly: Bool = true
    private let viewModel: GroupShareHistoryViewModel
    private var datas: [GroupShareHistoryListItem] = []
    private var selectedIDs = Set<String>()

    private var _errorView: LoadFailPlaceholderView?
    private lazy var errorView: LoadFailPlaceholderView = {
        let view = LoadFailPlaceholderView()
        self.view.addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview() }
        view.isHidden = true
        view.text = BundleI18n.LarkChatSetting.Lark_Legacy_LoadingFailed
        _errorView = view
        return view
    }()

    init(viewModel: GroupShareHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.table)
        self.table.snp.makeConstraints { $0.edges.equalToSuperview() }
        self.table.separatorStyle = .none
        self.table.delegate = self
        self.table.dataSource = self
        self.table.showsVerticalScrollIndicator = false
        self.table.rowHeight = UITableView.automaticDimension
        self.table.estimatedRowHeight = 100
        self.table.sectionHeaderHeight = 5
        self.table.sectionFooterHeight = 0
        self.table.backgroundColor = UIColor.ud.bgFloatBase
        var frame = self.view.frame
        frame.size.height = 0.01
        self.table.tableFooterView = UIView(frame: frame)
        self.table.lu.register(cellSelf: GroupShareHistoryListCell.self)

        self.rightItem.setProperty(alignment: .right)
        self.rightItem.button.setTitleColor(UIColor.ud.N900, for: .normal)
        self.rightItem.button.addTarget(self, action: #selector(toggleViewStatus), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = rightItem

        viewModel.dataSource
            .drive(onNext: { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let datas):
                    self.datas = datas
                    self.setDispalyView()
                    self.reloadTableStatus()
                case .failure:
                    if self.datas.isEmpty {
                        self.errorView.isHidden = false
                        self.rightItem.button.isHidden = true
                    }
                }
            }).disposed(by: disposeBag)

        viewModel.loadData()
        self.loadingPlaceholderView.isHidden = false
    }

    private func setDispalyView() {
        // 隐藏loading 和 errorView
        self.loadingPlaceholderView.isHidden = true
        self._errorView?.isHidden = true

        if self.datas.isEmpty {
            self.rightItem.button.isHidden = true
            self.view.addSubview(emptyView)
            emptyView.backgroundColor = UIColor.ud.bgFloatBase
            emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else {
            self.rightItem.button.isHidden = false
        }
    }

    private func reloadTableStatus() {
        self.table.reloadData()
        self.table.removeBottomLoadMore()
        if self.viewModel.hasMore {
            self.table.addBottomLoadMoreView { [weak self] in
                self?.viewModel.loadData()
            }
        }
    }

    private func confirmDisable() {
        self.viewModel.disableShare(with: Array(self.selectedIDs))
        self.toggleViewStatus()
    }

    private func createPickerToolBar() -> DefaultPickerToolBar {
        let toolbar = DefaultPickerToolBar()
        toolbar.setItems(toolbar.toolbarItems(), animated: false)
        toolbar.allowSelectNone = false
        toolbar.confirmButtonTappedBlock = { [weak self] _ in self?.confirmDisable() }
        toolbar.isHidden = true
        self.view.addSubview(toolbar)
        toolbar.snp.makeConstraints {
            $0.height.equalTo(49)
            $0.left.right.equalToSuperview()
            if #available(iOS 11, *) {
                $0.bottom.equalTo(self.view.safeAreaLayoutGuide)
            } else {
                $0.bottom.equalToSuperview()
            }
        }
        return toolbar
    }

    /// 切换view显示状态: Deactivate Or Dispaly
    @objc
    private func toggleViewStatus() {
        self.isDispaly.toggle()
        if self.isDispaly {
            self.switchToDisplay()
        } else {
            self.switchToDeactivate()
        }
    }

    // 切换到操作态
    private func switchToDeactivate() {
        rightItem.button.setTitle(BundleI18n.LarkChatSetting.Lark_Legacy_Cancel, for: .normal)
        table.reloadData()
        table.snp.remakeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(pickerToolBar.snp.top)
        }
        pickerToolBar.isHidden = false
        updateToolBar()
    }

    // 切换到显示态
    private func switchToDisplay() {
        rightItem.button.setTitle(BundleI18n.LarkChatSetting.Lark_Chat_DeactivateShare, for: .normal)
        table.reloadData()
        pickerToolBar.isHidden = true
        table.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        selectedIDs.removeAll()
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    // 由于DefaultPickerToolBar写死了选中文案且不符合这里需求，故重设一次
    private func updateToolBar() {
        guard let button = self.pickerToolBar.selectedResultButtonItem.customView as? UIButton else { return }
        pickerToolBar.updateSelectedItem(
            firstSelectedItems: Array(self.selectedIDs),
            secondSelectedItems: [],
            updateResultButton: true)

        button.setTitle("\(BundleI18n.LarkChatSetting.Lark_Legacy_HasSelected)\(self.selectedIDs.count)", for: .normal)
        button.sizeToFit()
        self.pickerToolBar.selectedResultButtonItem.width = button.frame.size.width
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 1. cell 是GroupShareHistoryListCell
        // 2. item 有值
        // 3. 显示态则直接显示分享者群卡片
        guard let cell = (tableView.cellForRow(at: indexPath) as? GroupShareHistoryListCell),
            let item = cell.item,
            !self.isDispaly else {
            return
        }

        // 4. item 有效才可以选中
        guard item.isVailed else { return }
        if cell.isCheckboxOn {
            selectedIDs.remove(item.id)
            cell.isCheckboxOn = false
        } else {
            selectedIDs.insert(item.id)
            cell.isCheckboxOn = true
        }

        self.updateToolBar()
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: GroupShareHistoryListCell.lu.reuseIdentifier,
            for: indexPath)

        if let historyCell = cell as? GroupShareHistoryListCell {
            var item = datas[indexPath.row]
            item.isShowBorderLine = indexPath.row != datas.count - 1
            historyCell.item = item
            historyCell.isCheckboxOn = self.selectedIDs.contains(item.id)
            historyCell.isInSelectedMode = !self.isDispaly
            historyCell.navi = self.viewModel.navigator
            historyCell.showSharerCardAction = { [weak self] (item) in
                guard let self = self else { return }
                // 显示态则直接显示分享者群卡片
                let body = PersonCardBody(chatterId: item.sharerID,
                                          chatId: self.viewModel.chatID,
                                          source: .chat)
                self.viewModel.navigator.presentOrPush(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepareForPresent: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            }
            historyCell.from = self
        }
        return cell
    }
}
