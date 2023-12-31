//
//  FeedFilterSettingViewController.swift
//  LarkFeed
//
//  Created by liuxianyu on 2021/8/22.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkModel
import EENavigator
import FigmaKit

/// 消息筛选设置
final class FeedFilterSettingViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let viewModel: FeedFilterSettingViewModel

    private let disposeBag = DisposeBag()
    /// 表格视图
    private let tableView: UITableView = InsetTableView(frame: .zero)

    init(viewModel: FeedFilterSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkFeed.Lark_Feed_FeedFilterSettingsTitle

        /// 初始化表格视图
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        self.tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        self.tableView.estimatedRowHeight = 68
        self.tableView.estimatedSectionFooterHeight = 10
        self.tableView.estimatedSectionHeaderHeight = 10
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.sectionFooterHeight = UITableView.automaticDimension
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.separatorColor = UIColor.ud.lineDividerDefault
        self.tableView.backgroundColor = UIColor.ud.bgFloatBase
        registerTableViewCells(self.tableView)
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        self.tableView.contentInsetAdjustmentBehavior = .never

        viewModel.delegate = self
        viewModel.getFilters(on: self.view.window)
        viewModel.reloadDataDriver.drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        viewModel.showFailureDriver.drive(onNext: { [weak self] errorInfo in
            guard !errorInfo.isEmpty, let window = self?.view.window else { return }
            UDToast.showFailure(with: errorInfo, on: window)
        }).disposed(by: disposeBag)
    }

    override func closeBtnTapped() {
        // 特化场景：当从 FeedFilterSortViewController present 过来时，回退时跳过不展示该控制器
        if let nav = self.presentingViewController as? LkNavigationController,
           let rootVC = nav.viewControllers.first as? FeedFilterSortViewController,
           let presentingVC = nav.presentingViewController {
            presentingVC.dismiss(animated: true, completion: nil)
            return
        }
        super.closeBtnTapped()
    }

    private func registerTableViewCells(_ tableView: UITableView) {
        tableView.lu.register(cellSelf: FeedFilterSettingSwitchCell.self)
        tableView.lu.register(cellSelf: FeedFilterSettingFeedFilterCell.self)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

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

        let item: FeedFilterSettingItemProtocol = viewModel.items[indexPath.section][indexPath.row]

        /// 其他的情况默认处理即可
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? FeedFilterSettingBaseCell {
            cell.item = item
            return cell
        }

        return UITableViewCell()
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let viewBulilder = self.viewModel.footerViews[section] else { return nil }
        return viewBulilder()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
          return 8
      }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard self.viewModel.footerViews[section] != nil else { return 0 }
        return UITableView.automaticDimension
    }
}

extension FeedFilterSettingViewController: FeedFilterSettingViewModelDelegate {}
