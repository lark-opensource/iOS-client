//
//  BadgeSettingViewController.swift
//  Todo
//
//  Created by wangwanxin on 2021/6/4.
//
//  Included OSS: WXNavigationBar
//  Copyright (c) 2020 alexiscn.
//  spdx license identifier: MIT

import Foundation
import LarkExtensions
import LarkUIKit
import LarkContainer

/// Home - Setting - Badge Setting
final class BadgeSettingViewController: BaseViewController, UserResolverWrapper, UITableViewDelegate, UITableViewDataSource {
    var userResolver: LarkContainer.UserResolver
    let viewModel: BadgeSettingViewModel
    private let tableView = UITableView(frame: .zero, style: .grouped)

    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.viewModel = BadgeSettingViewModel(resolver: resolver)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        viewModel.setup { [weak self] in
            self?.tableView.reloadData()
        }
        title = I18N.Todo_Settings_BadgeCountTitle
        Setting.Track.viewBadgeSetting()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private func setupSubviews() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.ctf.register(cellType: SettingCheckMarkCell.self)
        tableView.ctf.register(cellType: SettingSwitchCell.self)
        tableView.ctf.register(headerViewType: SettingHeaderView.self)
        tableView.estimatedRowHeight = 48
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.rowHeight = UITableView.automaticDimension
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = .zero
        }
        #endif
        tableView.tableHeaderView = .init(frame: .init(x: 0, y: 0, width: 0, height: 16))
        tableView.tableFooterView = UIView()
    }

    // MARK: UITableViewDelegate, UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataSource[section].items.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 36.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
         return .leastNormalMagnitude
     }

     func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
         return UIView()
     }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.ctf.dequeueReusableHeaderView(
            SettingHeaderView.self
        ) else {
            return UITableViewHeaderFooterView()
        }
        header.titleLabel.text = viewModel.headerTitle(in: section)
        return header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let itemData = viewModel.itemData(at: indexPath) else {
            return UITableViewCell()
        }
        switch itemData.accessType {
        case .switchType(let isOn):
            guard let cell = tableView.ctf.dequeueReusableCell(
                SettingSwitchCell.self,
                for: indexPath
            ) else {
                return UITableViewCell()
            }
            cell.clipsToBounds = true
            cell.layer.cornerRadius = 10
            cell.layer.masksToBounds = true
            cell.contentCell.setup(title: itemData.title, description: itemData.subTitle, isOn: isOn)
            cell.contentCell.valueChangedHandler = { [weak self] isOn in
                guard let self = self else { return }
                self.viewModel.updateSettingEnable(
                    isOn: isOn,
                    onError: self.showErrorToast
                )
            }
            return cell
        case .checkMark(let isChecked):
            guard let cell = tableView.ctf.dequeueReusableCell(
                SettingCheckMarkCell.self,
                for: indexPath
            ) else {
                return UITableViewCell()
            }
            cell.titleLabel.text = itemData.title
            cell.isChecked = isChecked
            cell.isShowSeparteLine = true
            if indexPath.row == 0 {
                cell.lu.addCorner(
                    corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
                    cornerSize: CGSize(width: 10, height: 10)
                )
            } else if indexPath.row == viewModel.itemCount(in: indexPath.section) - 1 {
                cell.lu.addCorner(
                    corners: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner],
                    cornerSize: CGSize(width: 10, height: 10)
                )
                cell.isShowSeparteLine = false
            } else {
                cell.lu.addCorner(
                    corners: [],
                    cornerSize: .zero
                )
            }
            cell.clipsToBounds = true
            return cell
        default:
            assertionFailure("badge setting have other access type")
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        viewModel.updateType(at: indexPath, onError: showErrorToast)
    }

    private func showErrorToast() {
        Utils.Toast.showError(with: I18N.Todo_Task_FailedToSet, on: view)
    }
}
