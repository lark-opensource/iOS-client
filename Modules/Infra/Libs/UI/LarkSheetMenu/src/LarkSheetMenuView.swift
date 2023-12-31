//
//  LarkSheetMenuView.swift
//  LarkSheetMenu
//
//  Created by Zigeng on 2023/1/23.
//

import Foundation
import SnapKit
import UIKit
import UniverseDesignColor
import FigmaKit
import LarkBadge
import UniverseDesignIcon

enum MenuViewState {
    case home
    case more
}

final class LarkSheetMenuView: UIView {

    var layout: LarkSheetMenuLayout
    let style: LarkSheetMenuStyle

    var isScrollEnabled: Bool {
        get {
            self.tableView.isScrollEnabled
        }
        set {
            self.tableView.isScrollEnabled = newValue
        }
    }

    var possisionPoint: CGPoint?

    override func layoutSubviews() {
        // 系统在进入后台时会触发一次LayoutSubviews, 会导致frame的oringin变成(0,0),需要手动处理一下
        if let possisionPoint = self.possisionPoint, self.frame.origin != possisionPoint {
            self.frame.origin = possisionPoint
            super.layoutIfNeeded()
        } else {
            super.layoutSubviews()
        }
        if self.menuCoverView.superview != nil {
            self.bringSubviewToFront(self.menuCoverView)
            let y = self.topBar.frame.maxY
            self.menuCoverView.frame = CGRect(x: 0, y: y, width: bounds.width, height: bounds.height - y)
        }
        if self.tableView.frame.width > 0, self.needReLayoutHeader {
            self.reloadData()
        }
    }

    private lazy var backgroundView: BackgroundBlurView = {
        let blurView = BackgroundBlurView()
        blurView.fillColor = .ud.N100.withAlphaComponent(0.95)
        blurView.fillOpacity = 0.95
        blurView.blurRadius = 50
        return blurView
    }()

    private lazy var topBar: UIView = {
        let view = UIView()
        view.snp.makeConstraints { make in
            make.height.equalTo(4)
            make.width.equalTo(40)
        }
        view.layer.cornerRadius = 2
        view.backgroundColor = .ud.lineBorderCard
        return view
    }()

    /// 容器View，提供基础的的show,hide的动画方法，业务放自行替换内容
    /// 会在当前的Menu上方提供一个从左至右推出的容器
    private lazy var menuCoverView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBase
        view.isHidden = true
        return view
    }()

    private var header: UIView?
    private var moreView: UIView?

    private var state: MenuViewState = .home

    func switchView(to newState: MenuViewState, animated: Bool = false) {
        guard newState != state else { return }
        self.state = newState
        switch state {
        case .home:
            setLayout()
        case .more:
            setMoreViewLayout(animated: animated)
        }
        self.layoutIfNeeded()
    }

    func switchToExpand() {
        let rightGradientView = UIView()
        rightGradientView.layer.addSublayer(rightGradientLineLayer)
        let leftGradientView = UIView()
        leftGradientView.layer.addSublayer(leftGradientLineLayer)
        tipView.addSubview(leftGradientView)
        tipView.addSubview(tipTextLabel)
        tipView.addSubview(rightGradientView)
        tipView.frame.size = CGSize(width: self.bounds.width, height: 76)

        tipTextLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(76)
        }
        leftGradientView.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.width.equalTo(40)
            make.left.greaterThanOrEqualToSuperview().offset(16)
            make.right.equalTo(tipTextLabel.snp.left).offset(-20)
            make.centerY.equalTo(tipTextLabel.snp.centerY)
        }

        rightGradientView.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.width.equalTo(40)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.left.equalTo(tipTextLabel.snp.right).offset(20)
            make.centerY.equalTo(tipTextLabel.snp.centerY)
        }

        /// 展开之后提示“没有更多了”
        self.tableView.tableFooterView = tipView
        self.tableView.reloadData()
    }

    lazy var gridView: LarkMenuGridView = {
        let view = LarkMenuGridView()
        return view
    }()

    private var needReLayoutHeader = false

    private var contentTopMarginSpace: CGFloat {
        return 4 + (style == .sheet ? layout.hotZoneSpace : 0)
    }

    private var contentBottomMarginSpace: CGFloat {
        return style == .sheet ? 14 : 0
    }

    private var gridHeaderHeight: CGFloat {
        return viewModel.headerData.isEmpty ? 0 : 70
    }
    /// 当前列表页面的内容
    private var currentTableContentHeight: CGFloat {
        return contentTopMarginSpace + gridHeaderHeight + layout.headerHeight + self.tableView.contentSize.height + contentBottomMarginSpace
    }

    var contentHeight: CGFloat {
        let height = currentTableContentHeight
        if self.menuCoverView.isHidden {
            return height
        } else {
           let view = self.menuCoverView.subviews.first { subView in
                return (subView as? FoldDetailViewProtocol) != nil
            } as? FoldDetailViewProtocol

            let foldHeight = (view?.contentHeight ?? 0) + contentTopMarginSpace
            MenuViewModel.logger.info("contentHeight foldHeight: \(foldHeight)- currentHeight: \(height)")
            return max(height, foldHeight)
        }
    }

    lazy var tableView: InsetTableView = {
        let view = InsetTableView()
        view.contentInsetAdjustmentBehavior = .never
        view.alwaysBounceHorizontal = false
        view.alwaysBounceVertical = false
        // iPhone界面需要TableView下方加入14px contentInset
        view.contentInset = .init(top: 0, left: 0, bottom: style == .sheet ? 14 : -18, right: 0)
        view.estimatedSectionFooterHeight = 0
        view.estimatedSectionHeaderHeight = 8
        view.tableFooterView = UIView(frame: .zero)
        view.separatorColor = .ud.lineDividerDefault
        view.separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        view.backgroundColor = .clear
        /// tableView的高度动态计算
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 48
        return view
    }()

    lazy var leftGradientLineLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.type = .axial
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 40, height: 1)
        gradientLayer.colors = [UIColor.ud.lineDividerDefault.withAlphaComponent(0).cgColor, UIColor.ud.lineDividerDefault.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        return gradientLayer
    }()
    lazy var rightGradientLineLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.type = .axial
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 40, height: 1)
        gradientLayer.colors = [UIColor.ud.lineDividerDefault.cgColor, UIColor.ud.lineDividerDefault.withAlphaComponent(0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        return gradientLayer
    }()
    lazy var tipTextLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.LarkSheetMenu.Lark_IM_MessageActionListEnd_Text
        return label
    }()

    lazy var tipView: UIView = UIView()
    let viewModel: MenuViewModel
    var dismissCallBack: (() -> Void)?
    var updateMenuHeightCallBack: ((CGFloat) -> Void)?

    public init(layout: LarkSheetMenuLayout,
                style: LarkSheetMenuStyle,
                viewModel: MenuViewModel,
                header: UIView?,
                moreView: UIView?,
                updateMenuHeightCallBack: ((CGFloat) -> Void)?,
                dismissCallBack: (() -> Void)?) {
        self.layout = layout
        self.style = style
        self.header = header
        self.moreView = moreView
        self.viewModel = viewModel
        self.dismissCallBack = dismissCallBack
        self.updateMenuHeightCallBack = updateMenuHeightCallBack
        super.init(frame: .zero)
        self.layer.cornerRadius = 10
        self.isMultipleTouchEnabled = false
        self.clipsToBounds = true
        self.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        self.addSubview(topBar)
        if style == .sheet {
            topBar.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(layout.hotZoneSpace)
                make.centerX.equalToSuperview()
            }
        } else {
            topBar.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(2)
                make.centerX.equalToSuperview()
            }
            topBar.alpha = 0
        }
        tableView.register(LarkSheetMenuCell.self, forCellReuseIdentifier: LarkSheetMenuCell.reuseIdentifier)
        tableView.register(LarkSheetMenuFoldCell.self, forCellReuseIdentifier: LarkSheetMenuFoldCell.reuseIdentifier)
        updateTableViewHeader()
        setLayout()
        self.tableView.reloadData()
    }

    func reloadData() {
        self.updateTableViewHeader()
        self.tableView.reloadData()
    }

    private func updateTableViewHeader()  {
        if !viewModel.headerData.isEmpty {
            let width = self.tableView.tableContentViewWidth()
            guard width > 0 else {
                tableView.tableHeaderView = nil
                needReLayoutHeader = true
                return
            }
            self.needReLayoutHeader = false
            gridView.layoutForData(viewModel.headerData, width: width)
            tableView.tableHeaderView = gridView
            gridView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalTo(width)
                make.centerX.equalToSuperview()
            }
            tableView.tableHeaderView?.layoutIfNeeded()
        } else {
            tableView.tableHeaderView = nil
        }
    }

    /// 切换至菜单主面板
    private func setLayout() {
        moreView?.snp.removeConstraints()
        moreView?.removeFromSuperview()
        // iPad 底部始终空出margin
        let bottomOffset = style == .padPopover ? -14 : 0
        if let header = header {
            self.addSubview(header)
            header.snp.remakeConstraints { make in
                make.top.equalTo(topBar.snp.bottom)
                make.height.equalTo(52)
                make.width.equalToSuperview()
                make.centerX.equalToSuperview()
            }

            self.addSubview(tableView)
            tableView.snp.remakeConstraints { make in
                make.top.equalTo(header.snp.bottom)
                make.bottom.equalToSuperview().offset(bottomOffset)
                make.width.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        } else {
            self.addSubview(tableView)
            tableView.snp.remakeConstraints { make in
                make.top.equalTo(topBar.snp.bottom).offset(4)
                make.bottom.equalToSuperview().offset(bottomOffset)
                make.width.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        }
        self.addSubview(backgroundView)
        backgroundView.frame = self.bounds
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.sendSubviewToBack(backgroundView)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            /// 更新渐变layer的颜色
            rightGradientLineLayer.colors = [UIColor.ud.lineDividerDefault.cgColor, UIColor.ud.lineDividerDefault.withAlphaComponent(0).cgColor]
            leftGradientLineLayer.colors = [UIColor.ud.lineDividerDefault.withAlphaComponent(0).cgColor, UIColor.ud.lineDividerDefault.cgColor]
        }
    }

    private func switchOperation() {
        header?.alpha = 0
        tableView.alpha = 0
        moreView?.alpha = 1
    }

    private func layoutMoreView() {
        guard let moreView = moreView else { return }
        let bottomOffset = style == .padPopover ? -10 : 0
        self.addSubview(moreView)
        moreView.snp.remakeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(bottomOffset)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }

    private func removeMainView() {
        header?.removeFromSuperview()
        tableView.removeFromSuperview()
    }

    /// 切换至更多面板
    private func setMoreViewLayout(animated: Bool) {
        guard let moreView = moreView else { return }
        if animated {
            moreView.alpha = 0
            layoutMoreView()
            UIView.animate(withDuration: 0.15, delay: 0, animations: { [weak self] in
                self?.switchOperation()
            }, completion: { [weak self] _ in
                self?.removeMainView()
            })
        } else {
            removeMainView()
            layoutMoreView()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 弹出Menu的coverView
    /// - Parameter displayView: 需要在coverView上展示的UI
    /// 弹出使用frame的UIView.animate动画，动画之调用layoutIfNeeded
    func showMenuCoverView(_ displayView: FoldDetailViewProtocol) {
        self.binderViewCoverView(displayView)
        /// 如果次级的内容大于当前展示的内容，更新一下高度 兜底逻辑
        self.menuCoverView.layoutIfNeeded()
        self.menuCoverView.isHidden = false
        addSubview(self.menuCoverView)
        let displayViewHeight = displayView.contentHeight + contentTopMarginSpace
        if displayViewHeight > currentTableContentHeight {
            self.updateMenuHeightCallBack?(displayViewHeight)
            MenuViewModel.logger.info("updateMenuHeight displayViewHeight: \(displayViewHeight)- currentHeight: \(currentTableContentHeight)")
        }
        let y = self.topBar.frame.maxY
        self.menuCoverView.frame = CGRect(x: bounds.width, y: y, width: bounds.width, height: bounds.height - y)
        UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction]) { [weak self] in
            guard let self = self else { return }
            self.menuCoverView.frame = CGRect(x: 0,
                                              y: self.topBar.frame.maxY,
                                              width: self.bounds.width,
                                              height: self.bounds.height - y)
        }completion: { _ in }
    }

    private func binderViewCoverView(_ view: UIView) {
        self.menuCoverView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 收起CoverView 会自动移除其所有subView
    func hideMenuCoverView() {
        let y = self.topBar.frame.maxY
        UIView.animate(withDuration: 0.25, delay: 0) { [weak self] in
            guard let self = self else { return }
            self.menuCoverView.frame = CGRect(x: self.bounds.width,
                                              y: y,
                                              width: self.bounds.width,
                                              height: self.bounds.height - y)
        }completion: { [weak self] _ in
            self?.menuCoverView.removeFromSuperview()
            self?.menuCoverView.isHidden = true
            self?.menuCoverView.subviews.forEach({ subView in
                subView.removeFromSuperview()
            })
        }
    }
}

extension LarkSheetMenuView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: Tableview Delegate & Datasource & Gesture
extension LarkSheetMenuView: UITableViewDelegate, UITableViewDataSource {

    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.dataSource.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.dataSource[section].sectionItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard viewModel.dataSource.count > indexPath.section,
              viewModel.dataSource[indexPath.section].sectionItems.count > indexPath.row else {
            assertionFailure("may be some things error")
            return UITableViewCell()
        }
        let item = viewModel.dataSource[indexPath.section].sectionItems[indexPath.row]
        var baseCell: LarkSheetMenuBaseCell?
        if item.subItems.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: LarkSheetMenuCell.reuseIdentifier, for: indexPath) as? LarkSheetMenuCell
            cell?.setCell(item)
            baseCell = cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: LarkSheetMenuFoldCell.reuseIdentifier, for: indexPath) as? LarkSheetMenuFoldCell
            cell?.setFoldCell(item, foldItemAction: { [weak self] item in
                if let item = item {
                    /// 点击返回按钮 隐藏Menu
                    let saveToView = LarkMenuFoldDetailView(foldItem: item) { [weak self] in
                        self?.hideMenuCoverView()
                    }
                    self?.showMenuCoverView(saveToView)
                }
            })
            baseCell = cell
        }
        baseCell?.layer.cornerRadius = 10
        return baseCell ?? UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return layout.sectionInterval
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            addTableViewPanGesture(scrollView: scrollView)
        }
    }

    public func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        removeTableViewPanGesture(scrollView: scrollView)
    }

    /// 滑动到顶继续滑动关闭菜单
    private func addTableViewPanGesture(scrollView: UIScrollView) {
        guard style == .sheet else { return }
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleTableViewDismissPanGesuture(gesture:)))
    }

    private func removeTableViewPanGesture(scrollView: UIScrollView) {
        guard style == .sheet else { return }
        scrollView.panGestureRecognizer.removeTarget(self, action: #selector(handleTableViewDismissPanGesuture(gesture:)))
    }

    @objc
    private func handleTableViewDismissPanGesuture(gesture: UIPanGestureRecognizer) {
        guard let superview = gesture.view?.superview else { return }
        if gesture.state == .ended, gesture.translation(in: superview).y >= 0 {
            self.dismissCallBack?()
        }
    }
}
