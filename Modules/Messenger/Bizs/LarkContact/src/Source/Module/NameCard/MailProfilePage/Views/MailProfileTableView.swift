//
//  SegmentedTableView.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/29.
//

import Foundation
import UniverseDesignTabs
import UniverseDesignColor
import UIKit

public protocol MailProfileTableViewInnerAble: UIView {
    var scrollableView: UIScrollView { get }
    var contentViewDidScroll: ((UIScrollView) -> Void)? { get set }
}

public protocol MailProfileTableViewDelegate: AnyObject {
    func profileTableViewDidScroll(_ scrollView: UIScrollView)
}

public extension MailProfileTableViewDelegate {
    func profileTableViewDidScroll(_ scrollView: UIScrollView) {}
}

public final class MailProfileTableView: UIView {

    enum ViewStatus {
        case normal
        case empty
        case error(reload: () -> Void)
    }

    var viewStatus: ViewStatus = .normal {
        didSet {
            switch viewStatus {
            case .empty:
                emptyCell.state = .empty
                tableView.backgroundColor = UIColor.ud.bgBody
            case .error(let reloadHandler):
                emptyCell.state = .reload(handler: reloadHandler)
                tableView.backgroundColor = UIColor.ud.bgBody
            case .normal:
                emptyCell.state = .none
                tableView.backgroundColor = UIColor.ud.bgBase
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

    public func setupInnerViewController(_ vc: MailProfileTableViewInnerAble) {
        vc.scrollableView.contentInsetAdjustmentBehavior = .never
        vc.scrollableView.showsVerticalScrollIndicator = false

        tableView.reloadData()
    }

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
    public weak var delegate: MailProfileTableViewDelegate?

    // MARK: UI Elements

    private let innerView: MailProfileTableViewInnerAble

    lazy var tableView: UITableView = {
        let tableView = NestedTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }()

    private lazy var contentCell: UITableViewCell = {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.ud.bgBody
        return cell
    }()

    private lazy var emptyCell = MailEmptyStateView()

    init(innerView: MailProfileTableViewInnerAble) {
        self.innerView = innerView
        super.init(frame: CGRect.zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        debugPrint("SegmentedTableView deinit")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(tableView)
        contentCell.contentView.addSubview(innerView)
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        innerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupAppearance() {
        backgroundColor = UIColor.ud.bgBody
        setupScrollHandler(for: innerView)
    }
}

// MARK: Handle scroll conflict

extension MailProfileTableView: UITableViewDelegate {
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
        delegate?.profileTableViewDidScroll(scrollView)

        let containerScrollView = tableView
        let containerOffset = containerScrollView.contentOffset.y

        guard scrollView == containerScrollView else { return }
        let maxContainerOffset = self.maxContainerOffset
        let subScrollView = innerView.scrollableView

        // TabsView 顶部驻停
        if subScrollView.contentOffset.y > 0 || containerOffset > maxContainerOffset {
            containerScrollView.contentOffset.y = maxContainerOffset
        }
    }

    private func setupScrollHandler(for innerView: MailProfileTableViewInnerAble) {
        innerView.contentViewDidScroll = { [weak self] subScrollView in
            guard let self = self else { return }
            let mainScrollView = self.tableView
            let maxContainerOffset = self.maxContainerOffset
            if ceil(mainScrollView.contentOffset.y) < floor(maxContainerOffset) {
                subScrollView.setContentOffset(.zero, animated: false)
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

extension MailProfileTableView: UITableViewDataSource {

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
        default:        return tableView.bounds.height - hoverHeight
        }
    }
}

extension MailProfileTableView: UDTabsViewDelegate {
    public func tabsViewWillBeginDragging(_ tabsView: UDTabsView) {
        tableView.isScrollEnabled = false
    }

    public func tabsViewDidEndDragging(_ tabsView: UDTabsView) {
        tableView.isScrollEnabled = true
    }
}

final class CustomTabsIndicatorLineView: UDTabsIndicatorLineView {
    override func commonInit() {
        super.commonInit()
        indicatorHeight = 2
    }

    public override func refreshIndicatorState(model: UDTabsIndicatorParamsModel) {
        super.refreshIndicatorState(model: model)
        layer.cornerRadius = 2
        let preFrame = frame
        frame = CGRect(x: preFrame.minX, y: preFrame.minY, width: preFrame.width, height: 4)
    }
}

final class NestedTableView: UITableView, UIGestureRecognizerDelegate {

    // swiftlint:disable all
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) && otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self)
    }
    // swiftlint:enable all
}
