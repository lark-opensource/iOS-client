//
//  WPCategoryPageView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/6/22.
//

import UIKit
import LKCommonsLogging

/// 工作台-分类页面-分类选项下的视图（tableView+stateView）
final class WPCategoryPageView: UIView {
    static let logger = Logger.log(WPCategoryPageView.self)

    /// 绑定的ViewModel
    var viewModel: AppCategoryPageModel
    /// 注册的滚动事件
    var scrollEvent: (() -> Void)?
    /// 展示分类应用的tableView（+footerView）
    lazy var categoryPageTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.showsVerticalScrollIndicator = false
        tableView.register(
            WPCategoryPageViewCell.self,
            forCellReuseIdentifier: WPCategoryPageViewCell.CellConfig.cellID
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tableView
    }()
    /// 展示加载状态的stateView
    lazy var categoryPageStateView: WPCategoryPageStateView = {
        let stateView = WPCategoryPageStateView(
            frame: self.bounds,
            state: viewModel.pageState,
            retryCallback: viewModel.retryCallback
        )
        return stateView
    }()

    // MARK: 初始化
    init(frame: CGRect, viewModel: AppCategoryPageModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        setupViews()
        setOnStateChange()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 设置model-state变化的回调事件
    private func setOnStateChange() {
        viewModel.stateChangeCallback = {[weak self] in
            guard let self = self else {
                Self.logger.info("stateChangeCallback call but self released")
                return
            }
            self.setViewsVisibilityByState()
        }
    }

    /// reload data
    func reloadData(model: AppCategoryPageModel) {
        viewModel = model
        categoryPageStateView.retryCallback = model.retryCallback
        setOnStateChange()
        self.setViewsVisibilityByState()
        categoryPageTableView.reloadData()
    }
}

// MARK: 视图组合和布局
extension WPCategoryPageView {
    /// 视图组成
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(categoryPageStateView)
        addSubview(categoryPageTableView)
        setViewsVisibilityByState()
        setupConstraint()
        categoryPageTableView.estimatedRowHeight = 76.0
        categoryPageTableView.rowHeight = UITableView.automaticDimension
    }
    /// 布局约束
    private func setupConstraint() {
        categoryPageTableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        categoryPageStateView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        setNeedsUpdateConstraints()
    }
    /// 根据model状态设置视图可见性
    private func setViewsVisibilityByState() {
        Self.logger.debug("state change to \(viewModel.pageState)")
        if viewModel.pageState == .success {
            categoryPageStateView.isHidden = true
            categoryPageTableView.isHidden = false
            categoryPageTableView.reloadData()
        } else {
            categoryPageStateView.isHidden = false
            categoryPageTableView.isHidden = true
            categoryPageStateView.state = viewModel.pageState
        }
    }
}

// MARK: tableView-dataSource
extension WPCategoryPageView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let modelList = viewModel.appList else {
            Self.logger.error("CategoryPageView modelList is emtpy, show category page failed")
            return 0
        }
        return modelList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// 获取cell
        var cell: WPCategoryPageViewCell
        if let dequeueCell = tableView.dequeueReusableCell(
            withIdentifier: WPCategoryPageViewCell.CellConfig.cellID
        ) as? WPCategoryPageViewCell {
            cell = dequeueCell
        } else {
            cell = WPCategoryPageViewCell(
                style: .default,
                reuseIdentifier: WPCategoryPageViewCell.CellConfig.cellID
            )
        }
        /// 获取数据
        guard let itemList = viewModel.appList, indexPath.row < itemList.count else {
            Self.logger.error("get item info failed with indexPath:\(indexPath)")
            return cell
        }
        /// 刷新cell
        cell.refresh(model: itemList[indexPath.row], isHideSplit: false, keyword: viewModel.keyword)
        return cell
    }
}

extension WPCategoryPageView: UITableViewDelegate {
    /// footerView
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return WPCategoryPageViewFooter(frame: .zero)
    }
    /// footer高度
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.hasMore ? footerViewHeight : 0
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    /// 监听tableView的滚动事件
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollEvent?()
    }
}
