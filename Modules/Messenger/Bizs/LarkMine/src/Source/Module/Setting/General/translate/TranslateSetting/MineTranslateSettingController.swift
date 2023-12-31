//
//  MineTranslateSettingController.swift
//  Lark
//
//  Created by zhenning on 2020/02/11.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import FigmaKit

/// 翻译设置
final class MineTranslateSettingController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let disposeBag = DisposeBag()
    private lazy var tableView = self.createTableView()
    private let viewModel: MineTranslateSettingViewModel

    init(viewModel: MineTranslateSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        self.viewModel.targetVC = self
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkMine.Lark_NewSettings_ContentTranslationMobile
        /// 创建表格视图
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        self.tableView.contentInsetAdjustmentBehavior = .never

        /// 监听信号
        self.viewModel.refreshDriver.drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.estimatedSectionHeaderHeight = 14
        tableView.estimatedSectionFooterHeight = 14
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.lu.register(cellSelf: MineTranslateDetailCell.self)
        tableView.lu.register(cellSelf: MineTranslateDisplayCell.self)
        tableView.lu.register(cellSelf: MineTranslateSwitchCell.self)
        tableView.lu.register(cellSelf: MineTranslateCheckboxCell.self)
        tableView.lu.register(cellSelf: MineTranslateTitleCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section >= self.viewModel.footerViews.count {
            return nil
        }
        return self.viewModel.footerViews[section]()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section >= self.viewModel.headerViews.count {
            return nil
        }
        return self.viewModel.headerViews[section]()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= self.viewModel.items.count {
            return 0
        }
        return self.viewModel.items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section >= self.viewModel.items.count {
            return UITableViewCell()
        }
        if indexPath.row >= self.viewModel.items[indexPath.section].count {
            return UITableViewCell()
        }

        let item = self.viewModel.items[indexPath.section][indexPath.row]

        /// 复用会导致点击checkbox和reloadData时候出现混乱，这个列表个数有限，就不采用复用，避免交互使用的复用问题
        if item.cellIdentifier == MineTranslateCheckboxCell.lu.reuseIdentifier {
            let cell = MineTranslateCheckboxCell(style: .default, reuseIdentifier: "")
            cell.item = item
            cell.selectionStyle = .none
            return cell
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? MineTranslateBaseCell {
            cell.item = item
            if cell.isMember(of: MineTranslateSwitchCell.self) {
                cell.selectionStyle = .none
            }
            return cell
        }
        return UITableViewCell()
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? MineTranslateCheckboxCell else { return }
        cell.checkBoxTapHandle()
    }
    // swiftlint:enable did_select_row_protection
}
