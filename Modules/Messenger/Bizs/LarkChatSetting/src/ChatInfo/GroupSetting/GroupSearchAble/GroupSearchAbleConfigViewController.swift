//
//  GroupSearchAbleConfigViewController.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/6/9.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignEmpty
import EENavigator
import LarkAlertController
import UniverseDesignToast
import FigmaKit

// 群可被搜索开关设置页面
final class GroupSearchAbleConfigViewController: BaseSettingController, UITableViewDelegate, UITableViewDataSource,
                                                 CommonItemStyleFormat {
    private let disposeBag = DisposeBag()
    private let tableView = InsetTableView(frame: .zero)
    private let viewModel: GroupSearchAbleConfigViewModel

    init(viewModel: GroupSearchAbleConfigViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.controller = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        configTable()
        configNavigaiton()
        observeData()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private func configTable() {
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 50
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.lu.register(cellSelf: GroupInfoNameCell.self)
        tableView.lu.register(cellSelf: GroupInfoPhotoCell.self)
        tableView.lu.register(cellSelf: GroupInfoDescriptionCell.self)
        tableView.lu.register(cellSelf: ConfigGroupSearchAbleCell.self)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    private func configNavigaiton() {
        self.title = BundleI18n.LarkChatSetting.Lark_Group_FindGroupViaSearchTitle
        self.setBackItem()
        self.addRightButton()
    }

    private func observeData() {
        viewModel.reloadData
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
    }

    private func setBackItem() {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        btn.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        btn.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        btn.setTitleColor(UIColor.ud.colorfulBlue, for: .selected)
        btn.setTitle(BundleI18n.LarkChatSetting.Lark_Legacy_Cancel, for: .normal)
        let barItem = UIBarButtonItem(customView: btn)
        self.navigationItem.leftBarButtonItem = barItem
    }

    func addRightButton() {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        btn.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        btn.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        btn.setTitleColor(UIColor.ud.colorfulBlue, for: .selected)
        btn.setTitle(BundleI18n.LarkChatSetting.Lark_Legacy_Save, for: .normal)
        let barItem = UIBarButtonItem(customView: btn)
        self.navigationItem.rightBarButtonItem = barItem
    }

    @objc
    func leftButtonTapped() {
        self.popSelf()
    }

    @objc
    func rightButtonTapped() {
        NewChatSettingTracker.chatAllowToBeSearchedClickTrack(chat: self.viewModel.chatModel,
                                                              click: "confirm",
                                                              isModifyGroupAvatar: viewModel.isModifyAvatar,
                                                              isModifyGroupName: viewModel.isModifyName,
                                                              isAllowToSearch: true)
        // 未改变状态不做任何响应, 直接pop
        guard viewModel.switchControlIsChange else {
            self.popSelf()
            return
        }
        if viewModel.canSaveChange {
            self.viewModel.saveChange { [weak self] in
                self?.popSelf()
            }
        } else {
            let chat = self.viewModel.chatModel
            NewChatSettingTracker.imChatAllowToBeSearchedRemindViewTrack(chat: chat)
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.LarkChatSetting.Lark_Group_FillInGroupDetailsDialogTitle)
            alert.setContent(text: BundleI18n.LarkChatSetting.Lark_Group_FillInGroupDetailsDialogDesc)
            alert.addSecondaryButton(text: BundleI18n.LarkChatSetting.Lark_Group_ExitButton,
                                     dismissCompletion: { [weak self] in
                                NewChatSettingTracker.imChatAllowToBeSearchedRemindClickTrack(click: "cancel", target: "im_group_manage_click", chat: chat)
                self?.popSelf()
            })
            alert.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Group_FillInGroupDetailsDialogButton,
                                   dismissCompletion: {
                                NewChatSettingTracker.imChatAllowToBeSearchedRemindClickTrack(click: "confirm", target: "im_chat_allow_to_be_searched_view", chat: chat)
            })
            self.viewModel.navigator.present(alert, from: self)
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.items.numberOfSections
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionView.self)) as? GroupSettingSectionView else {
            return tableView.dequeueReusableHeaderFooterView(
                withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        }
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
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.numberOfRows(in: section)
    }

    // MARK: - UITableViewDataSource
    private func item<T>(for items: [T], at index: Int) -> T? {
        guard index > -1, index < items.count else { return nil }
        return items[index]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let section = self.item(for: self.viewModel.items, at: indexPath.section),
           var item = section.item(at: indexPath.row),
           var cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? CommonCellProtocol {
            item.style = style(for: item, at: indexPath.row, total: self.viewModel.items.count)
            cell.item = item
            return (cell as? UITableViewCell) ?? .init()
        } else {
            assert(false, "未找到对应的Item or cell")
        }
        return UITableViewCell()
    }
}
