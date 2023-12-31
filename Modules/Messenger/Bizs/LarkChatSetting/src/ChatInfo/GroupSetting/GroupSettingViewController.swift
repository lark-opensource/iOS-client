//
//  GroupSettingViewController.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/1/19.
//

import Foundation
import UIKit
import LarkUIKit
import LKCommonsLogging
import LarkModel
import RxSwift
import EENavigator
import LarkAlertController
import FigmaKit

final class GroupSettingViewController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {
    private(set) var disposeBag = DisposeBag()
    private let tableView: InsetTableView = InsetTableView(frame: .zero)
    private(set) var viewModel: GroupSettingViewModel
    private var scrollToBottom: Bool
    private var openSettingCellType: CommonCellItemType?

    /// 标记是否已经 pop self
    private var hadPopSelf: Bool = false
    private var maxWidth: CGFloat?
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    init(viewModel: GroupSettingViewModel) {
        self.viewModel = viewModel
        self.scrollToBottom = viewModel.scrollToBottom
        self.openSettingCellType = viewModel.openSettingCellType
        super.init(nibName: nil, bundle: nil)
        self.configViewModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        commInit()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updatePosition(tableView: self.tableView, scrollToBottom: self.scrollToBottom)
        self.scrollToBottom = false
        self.scrollAndOpenSettingIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if Display.pad && UIApplication.shared.applicationState == .background { return }
        self.maxWidth = size.width
        self.tableView.reloadData()
    }

    func updatePosition(tableView: UITableView, scrollToBottom: Bool) {
        let section = tableView.numberOfSections - 1
        let row = tableView.numberOfRows(inSection: section) - 1
        if scrollToBottom && row >= 0 && section >= 0 {
            let indexPath = IndexPath(row: row, section: section)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    private func scrollAndOpenSettingIfNeeded() {
        var row: Int?
        if let type = self.openSettingCellType,
           let section = viewModel.items.firstIndex(where: {
               row = $0.items.firstIndex(where: { $0.type == type })
               return row != nil
           }),
           let row = row,
           section < tableView.numberOfSections,
           row < tableView.numberOfRows(inSection: section) {
            let index = IndexPath(row: row, section: section)
            tableView.scrollToRow(at: index, at: .middle, animated: true)
            // 滑动稳定后再选择cell，防止iPad上显示popover错位
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else { return }
                self.tableView.selectRow(at: index, animated: true, scrollPosition: .none)
                self.tableView.deselectRow(at: index, animated: true)
            }
            self.openSettingCellType = nil // 滑动过后设置为 nil，防止进入其他页面后回来再次滑动
        }
    }

    private func commInit() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        commInitNavi()
        commTableView()
        self.viewModel.observeData()
        self.viewModel.fetchData()
    }

    private func commInitNavi() {
        title = BundleI18n.LarkChatSetting.Lark_Legacy_GroupManagementSetting
    }

    private func commTableView() {
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66
        tableView.estimatedSectionHeaderHeight = 30
        tableView.estimatedSectionFooterHeight = 0
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        tableView.lu.register(cellSelf: ChatAdminMemberCell.self)
        tableView.lu.register(cellSelf: GroupSettingShareCell.self)
        tableView.lu.register(cellSelf: GroupSettingEditCell.self)
        tableView.lu.register(cellSelf: GroupSettingAtAllCell.self)
        tableView.lu.register(cellSelf: GroupSettingJoinNotifyCell.self)
        tableView.lu.register(cellSelf: GroupSettingLeaveNotifyCell.self)
        tableView.lu.register(cellSelf: GroupSettingTransferCell.self)
        tableView.lu.register(cellSelf: GroupSettingAddNewCell.self)
        tableView.lu.register(cellSelf: GroupSettingDisbandCell.self)
        tableView.lu.register(cellSelf: GroupSettingApproveCell.self)
        tableView.lu.register(cellSelf: GroupSettingToNormalGroupCell.self)
        tableView.lu.register(cellSelf: GroupSettingMailPermissionCell.self)
        tableView.lu.register(cellSelf: GroupSettingAllowGroupSearchedCell.self)
        tableView.lu.register(cellSelf: MessagePreventLeakCell.self)
        tableView.lu.register(cellSelf: MessagePreventLeakSubSwitchCell.self)
        tableView.lu.register(cellSelf: ChatInfoModeChangeCell.self)
        tableView.lu.register(cellSelf: MessagePreventLeakBurnTimeCell.self)
        tableView.lu.register(cellSelf: MessagePreventLeakWhiteListCell.self)
        tableView.lu.register(cellSelf: HideUserCountCell.self)

        tableView.register(
            GroupSettingSectionView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionView.self))
        tableView.register(
            GroupSettingSectionEmptyView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        tableView.register(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")
    }

    // MARK: - UITableViewDelegate
    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionView.self)) as? GroupSettingSectionView else {
            return tableView.dequeueReusableHeaderFooterView(
                withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        }
        header.setTitleTopMargin(14)
        if let title = viewModel.items.sectionHeader(at: section) {
            header.titleLabel.text = title
            header.titleLabel.isHidden = false
        } else {
            header.titleLabel.isHidden = true
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard viewModel.items.sectionHeader(at: section) != nil else {
            return 16
        }
        return 36
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard viewModel.items.sectionFooter(at: section) != nil else {
            return 0.01
        }
        return 36
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionView.self)) as? GroupSettingSectionView else {
            return tableView.dequeueReusableHeaderFooterView(
                withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        }
        header.setTitleTopMargin(4)
        if let title = viewModel.items.sectionFooter(at: section) {
            header.titleLabel.text = title
            header.titleLabel.isHidden = false
        } else {
            header.titleLabel.isHidden = true
        }
        return header
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.items.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = viewModel.items.item(at: indexPath),
            var cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? CommonCellProtocol {
            cell.updateAvailableMaxWidth(self.maxWidth ?? self.view.bounds.width)
            cell.item = item
            return (cell as? UITableViewCell) ?? UITableViewCell()
        }
        return UITableViewCell()
    }
}

// viewModel config
private extension GroupSettingViewController {
    func configViewModel() {
        viewModel.controller = self

        viewModel.reloadData
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.tableView.reloadData()
                if self.viewModel.isOwner == false && self.viewModel.isGroupAdmin == false &&
                    !self.hadPopSelf {
                    self.hadPopSelf = true
                    self.popSelf()
                }
            }).disposed(by: disposeBag)

        viewModel.showAlert = { [weak self] (title, message) in
            guard let `self` = self else { return }
            let alertController = LarkAlertController()
            alertController.setTitle(text: title)
            alertController.setContent(text: message)
            alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_Sure)
            self.viewModel.navigator.present(alertController, from: self)
        }
    }
}
