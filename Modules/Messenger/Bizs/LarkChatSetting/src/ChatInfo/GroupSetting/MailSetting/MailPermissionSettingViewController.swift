//
//  MailPermissionSettingViewController.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/1/19.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import RxSwift
import EENavigator
import LarkMessengerInterface
import LarkNavigator
import LKCommonsLogging
import FigmaKit

final class MailPermissionSettingViewController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {
    private var disposeBag = DisposeBag()
    private lazy var tableView = InsetTableView(frame: .zero)
    private static let logger = Logger.log(
        MailPermissionSettingViewController.self,
        category: "Module.LarkChatSetting")

    private lazy var rightItem: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_LarkConfirm, fontStyle: .medium)
        item.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        item.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        item.addTarget(self, action: #selector(makeSure), for: .touchUpInside)
        return item
    }()

    private var viewModel: MailPermissionSettingViewModel

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: MailPermissionSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        self.title = BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_Email_Permission_Title
        self.view.addSubview(tableView)
        tableView.frame = self.view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.lu.register(cellSelf: MailPermissionSettingCell.self)
        tableView.register(
            GroupSettingSectionEmptyView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionEmptyView.self)
        )
        tableView.register(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")
        navigationItem.rightBarButtonItem = rightItem
        viewModel.reloadData.drive(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }

    @objc
    private func makeSure() {
        let window = self.view.window
        navigationController?.dismiss(animated: true)
        viewModel.confirmOption(on: window)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.indexDataArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: MailPermissionSettingCell.lu.reuseIdentifier) as? MailPermissionSettingCell {
            if viewModel.indexDataArray[indexPath.section].count - 1 == indexPath.row {
                cell.layoutSeparater(.none)
            } else {
                cell.layoutSeparater(.half)
            }
            cell.titleLabel.text = viewModel.indexText(indexPath: indexPath)
            cell.checkBox.isSelected = viewModel.isIndexSelected(indexPath: indexPath)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 防止越界
        guard section < viewModel.indexDataArray.count else {
            Self.logger.info("section: \(section) >= viewModel.indexDataArray.count: \(viewModel.indexDataArray.count)")
            return 0
        }
        return viewModel.indexDataArray[section].count
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        viewModel.setIndex(indexPath: indexPath)
    }
}
