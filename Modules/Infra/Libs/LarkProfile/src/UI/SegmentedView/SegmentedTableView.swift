//
//  SegmentedTableView.swift
//  SegmentedTableView
//
//  Created by Hayden Wang on 2021/6/28.
//

import Foundation
import UIKit
import UniverseDesignTabs
import UniverseDesignColor
import LKCommonsTracker
import Homeric
import LarkUIKit

public protocol SegmentedTableViewDelegate: AnyObject {
    func numberOfTabs(in segmentedView: SegmentedTableView) -> Int
    func titleOfTabs(in segmentedView: SegmentedTableView) -> [String]
    func identifierOfTabs(in segmentedView: SegmentedTableView) -> [String]
    func segmentedView(_ segmentedView: SegmentedTableView, contentableForIndex index: Int) -> SegmentedTableViewContentable
    func segmentedViewDidScroll(_ scrollView: UIScrollView)
}

public extension SegmentedTableViewDelegate {
    func segmentedViewDidScroll(_ scrollView: UIScrollView) {}
}

public final class SegmentedTableView: UIView {

    enum ViewStatus {
        case normal
        case empty
        case noPermission
        case error(reload: () -> Void)
    }

    var viewStatus: ViewStatus = .normal {
        didSet {
            switch viewStatus {
            case .empty:
                emptyCell.state = .empty
            case .noPermission:
                emptyCell.state = .privacy
            case .error(let reloadHandler):
                emptyCell.state = .reload(handler: reloadHandler)
            case .normal:
                emptyCell.state = .none
            }
            tableView.reloadData()
        }
    }

    /// 顶部悬停区域的高度
    public var hoverHeight: CGFloat = 0 {
        didSet {
            tableView.reloadData()
        }
    }

    /// 记录上一个选中页面的index
    var lastSelectedIndexOfTabsView: Int?

    /// 用户的个人ID
    public var userID: String?

    public func setHeaderView(_ headerView: UIView) {
        tableView.setTableHeaderView(headerView: headerView)
        DispatchQueue.main.async {
            self.tableView.updateHeaderViewFrame()
        }
    }

    public func updateHeaderViewFrame() {
        DispatchQueue.main.async {
            self.tableView.updateHeaderViewFrame()
        }
    }

    /* LTSimple的scrollView上下滑动监听 */
    public weak var delegate: SegmentedTableViewDelegate?

    // configs
    private var titles: [String] {
        self.delegate?.titleOfTabs(in: self) ?? []
    }

    private var identifiers: [String] {
        self.delegate?.identifierOfTabs(in: self) ?? []
    }

    /// 记录当前展示的子 View
    private var currentSubScrollView: UIScrollView?

    // MARK: UI Elements

    /// SegmentedTableView 的 Tab 标题栏
    lazy var tabsTitleView: UDTabsTitleView = {
        let tabsView = UDTabsTitleView()
        let config = tabsView.getConfig()
        config.contentEdgeInsetLeft = 16
        config.contentEdgeInsetRight = 16
        config.isItemSpacingAverageEnabled = false
        config.titleNormalFont = UIFont.systemFont(ofSize: 16)
        config.titleSelectedFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        config.itemSpacing = 36
        config.itemMaxWidth = 250
        config.titleNumberOfLines = 1
        tabsView.backgroundColor = Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody
        tabsView.titles = titles
        tabsView.indicators = [CustomTabsIndicatorLineView()]
        tabsView.setConfig(config: config)
        tabsView.delegate = self
        tabsView.listContainer = tabsContainerView
        let divider = UIView()
        divider.backgroundColor = UIColor.ud.lineDividerDefault & .clear
        tabsView.insertSubview(divider, at: 0)
        divider.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return tabsView
    }()

    /// SegmentedTableView 的 VC 容器
    lazy var tabsContainerView: UDTabsListContainerView = {
        let containerView = UDTabsListContainerView(dataSource: self)
        containerView.delegate = self
        return containerView
    }()

    private var viewControllers: [SegmentedTableViewContentable?] = []

    lazy var tableView: UITableView = {
        let tableView = NestedTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }()

    private lazy var contentCell: UITableViewCell = {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        return cell
    }()

    private lazy var emptyCell = EmptyStateView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        debugPrint("SegmentedTableView deinit")
    }

    public func setDefaultSelected(index: Int) {
        LarkProfileDataProvider.logger.info("set default selected index:\(index), viewControllers:\(viewControllers.count)")
        self.tabsTitleView.defaultSelectedIndex = index
    }

    public func setIndex(_ index: Int) {
        guard index < viewControllers.count else {
            return
        }

        tabsTitleView.selectItemAt(index: index)
    }

    public func reloadData() {
        let count = self.delegate?.numberOfTabs(in: self) ?? 0

        viewControllers.forEach { vc in
            if let vc = vc {
                vc.listView().removeFromSuperview()
            }
        }

        self.viewControllers = [SegmentedTableViewContentable?](repeating: nil, count: count)

        if count <= 1 {
            tabsTitleView.isHidden = true
            tabsContainerView.snp.updateConstraints { update in
                update.top.equalToSuperview()
            }
        } else {
            tabsTitleView.isHidden = false
            tabsContainerView.snp.updateConstraints { update in
                update.top.equalToSuperview().offset(42)
            }
        }

        self.tabsTitleView.titles = self.titles
        self.tabsTitleView.reloadData()
        self.tabsContainerView.reloadData()
        self.tableView.reloadData()
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
//        reloadData()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        tableView.reloadData()
    }

    private func setupSubviews() {
        addSubview(tableView)
        contentCell.contentView.addSubview(tabsTitleView)
        contentCell.contentView.addSubview(tabsContainerView)
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tabsTitleView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(42)
        }
        tabsContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(42)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func updateTableHeaderView() {
        guard let headerView = self.tableView.tableHeaderView else {
            return
        }
        headerView.layoutIfNeeded()
        tableView.tableHeaderView = headerView
    }
}

// MARK: Handle scroll conflict

extension SegmentedTableView: UITableViewDelegate {

    /// TableHeader 的实际高度
    var headerHeight: CGFloat {
        if let header = tableView.tableHeaderView {
            return header.frame.height
        } else {
            return 0
        }
    }

    /// 父容器向上最大滚动距离（超出最大距离之后父容器不再滚动，内部子容器开始滚动）
    private var maxContainerOffset: CGFloat {
        headerHeight - hoverHeight
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.segmentedViewDidScroll(scrollView)
        let containerScrollView = tableView
        let containerOffset = containerScrollView.contentOffset.y

        guard scrollView == containerScrollView,
              let subScrollView = currentSubScrollView else { return }
        let maxContainerOffset = self.maxContainerOffset

        /*
        if subScrollView.contentSize.height <= (UIScreen.main.bounds.height - headerHeight) {
            containerScrollView.contentOffset.y = 0
        }
         */

        // TabsView 顶部驻停
        if subScrollView.contentOffset.y > 0 || containerOffset > maxContainerOffset {
            containerScrollView.contentOffset.y = maxContainerOffset
        }
        if containerOffset < maxContainerOffset {
            for viewController in viewControllers where viewController?.scrollableView != subScrollView {
                viewController?.scrollableView.contentOffset = .zero
            }
        }

    }

    private func setupScrollHandler(for subVC: SegmentedTableViewContentable) {
        subVC.contentViewDidScroll = { [weak self] subScrollView in
            guard let self = self else { return }
            let mainScrollView = self.tableView
            let maxContainerOffset = self.maxContainerOffset
            self.currentSubScrollView = subScrollView
            if ceil(mainScrollView.contentOffset.y) < floor(maxContainerOffset) {
                subScrollView.contentOffset = .zero
                // subScrollView.showsVerticalScrollIndicator = false
            } else {
                // subScrollView.showsVerticalScrollIndicator = true
            }
        }
    }
}

// MARK: Auto-Layout header

extension UITableView {

    /// Set table header view & add Auto layout.
    func setTableHeaderView(headerView: UIView) {
        headerView.translatesAutoresizingMaskIntoConstraints = false

        // Set first.
        self.tableHeaderView = headerView

        // Then setup AutoLayout.
        headerView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        headerView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    }

    /// Update header view's frame.
    func updateHeaderViewFrame() {
        guard let headerView = self.tableHeaderView else { return }

        // Update the size of the header based on its internal content.
        headerView.layoutIfNeeded()
        // ***Trigger table view to know that header should be updated.
        let header = self.tableHeaderView
        self.tableHeaderView = header
    }
}

// MARK: DataSource & Delegate

extension SegmentedTableView: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewStatus {
        case .normal:   return contentCell
        default:        return emptyCell
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch viewStatus {
        case .normal:   return tableView.bounds.height - hoverHeight
        default:        return 300
        }
    }
}

extension SegmentedTableView: UDTabsListContainerViewDataSource {

    public func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        self.delegate?.numberOfTabs(in: self) ?? 0
    }

    public func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        if let vc = self.delegate?.segmentedView(self, contentableForIndex: index) {

            vc.scrollableView.contentInsetAdjustmentBehavior = .never
            vc.scrollableView.showsVerticalScrollIndicator = false
            self.setupScrollHandler(for: vc)
            if index < viewControllers.count {
                viewControllers[index] = vc
            }
            return vc
        }

        return SegmentedTableViewContent()
    }
}

extension SegmentedTableView: UDTabsListContainerDelegate {
    public func tabsContainerWillBeginDragging(_ tabsContainer: UDTabsListContainerView) {
        tableView.isScrollEnabled = false
    }

    public func tabsContainerDidEndDragging(_ tabsContainer: UDTabsListContainerView) {
        tableView.isScrollEnabled = true
    }
}

extension SegmentedTableView: UDTabsViewDelegate {
    public func tabsViewWillBeginDragging(_ tabsView: UDTabsView) {
        tableView.isScrollEnabled = false
    }

    public func tabsViewDidEndDragging(_ tabsView: UDTabsView) {
        tableView.isScrollEnabled = true
    }

    public func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        if lastSelectedIndexOfTabsView == index {
            return
        }
        lastSelectedIndexOfTabsView = index
        // 埋点处理
        guard identifiers.count > index else {
            return
        }
        let identifier = identifiers[index]
        if identifier == "ProfileFieldTab" {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "basic_information_tab"
            params["target"] = "none"
            params["contact_type"] = LarkProfileTracker.userMap[userID ?? ""]?["contact_type"] ?? ""
            params["to_user_id"] = userID
            Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))
        } else if identifier == "moments_profile" {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "moments_tab"

            if let map = LarkProfileTracker.userMap[userID ?? ""],
               let contactType = map["contact_type"] {
                params["contact_type"] = contactType
            }
            params["to_user_id"] = userID
            params["target"] = "moments_profile_view"
            Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))
        }
    }
}

final class CustomTabsIndicatorLineView: UDTabsIndicatorLineView {
    override func commonInit() {
        super.commonInit()
        indicatorHeight = 2
    }

    override func refreshIndicatorState(model: UDTabsIndicatorParamsModel) {
        super.refreshIndicatorState(model: model)
        layer.cornerRadius = 2
        let preFrame = frame
        frame = CGRect(x: preFrame.minX, y: preFrame.minY, width: preFrame.width, height: 4)
    }
}
