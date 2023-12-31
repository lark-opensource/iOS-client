//
//  EdgeTabBar+Pin.swift
//  LarkNavigation
//
//  Created by yaoqihao on 2023/8/11.
//

import Foundation
import AnimatedTabBar
import LarkSwipeCellKit
import LarkUIKit

class HeaderPinView: UIView {
    private var needsUpdateItemViews: Bool = false

    var maxCount: Int = 1

    var progress: CGFloat = 1

    var tabbarLayoutStyle: EdgeTabBarLayoutStyle = .vertical {
        didSet {
            needsUpdateItemViews = true
            update(progress: 0)
        }
    }

    var tabItems: [AbstractTabBarItem] = [] {
        didSet {
            needsUpdateItemViews = true
            setNeedsLayout()
        }
    }

    var didSelectCallback: ((AbstractTabBarItem) -> Void)?

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.insetsContentViewsToSafeArea = false
        tableView.insetsLayoutMarginsFromSafeArea = false
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.alwaysBounceHorizontal = false
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.insetsContentViewsToSafeArea = false
        tableView.lu.register(cellWithClass: EdgeTabBarTableViewCell.self)
        tableView.contentInset = .zero
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()

    private var bottomBorder: UIView = {
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor.ud.lineDividerDefault
        return bottomBorder
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(tableView)
        self.addSubview(bottomBorder)
        self.backgroundColor = NewEdgeTabBar.bgColor

        bottomBorder.snp.remakeConstraints { make in
            make.height.equalTo(1)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalTo(-1)
        }

        updateTableViewConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateItemViewsIfNeeded()
        // 需要禁用动画并立即布局，避免图标的缩放效果
        UIView.performWithoutAnimation {
            layoutIfNeeded()
        }

        updateTableViewConstraints()
    }

    func update(progress: CGFloat) {
        guard progress != self.progress else { return }
        self.progress = progress > 1 ? 1 : progress

        updateTableViewConstraints()
    }

    func addTabItem(_ tabItem: AbstractTabBarItem) {

        guard self.tabItems.count < maxCount, !self.tabItems.contains(where: {
            $0.tab == tabItem.tab
        }) else {
            return
        }

        self.tabItems.append(tabItem)
    }

    func removeTabItem(_ tabItem: AbstractTabBarItem) {
        self.tabItems.removeAll {
            $0.tab == tabItem.tab
        }
        update(progress: 1)
    }

    private func updateItemViewsIfNeeded() {
        guard needsUpdateItemViews else { return }
        self.tableView.reloadData()
        self.needsUpdateItemViews = false
    }

    private func updateTableViewConstraints() {
        let count: CGFloat = CGFloat(tabItems.count) - 1 + progress

        let showBottom = progress == 1 && count > 0
        self.bottomBorder.isHidden = !showBottom

        let height = count * NewEdgeTabView.Layout.getHeightBy(self.tabbarLayoutStyle)
        let bottom = showBottom ? 8 : 0
        tableView.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(height)
            make.bottom.equalToSuperview().offset(-bottom)
        }
    }
}

// MARK: TableView

extension HeaderPinView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tabItems.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewEdgeTabView.Layout.getHeightBy(self.tabbarLayoutStyle)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < tabItems.count else { return }

        tableView.deselectRow(at: indexPath, animated: false)

        guard let cell = tableView.cellForRow(at: indexPath) as? EdgeTabBarTableViewCell,
              let item = cell.item else { return }
        self.didSelectCallback?(item)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < tabItems.count else { return UITableViewCell() }
        let tabCell = tableView.lu.dequeueReusableCell(withClass: EdgeTabBarTableViewCell.self, for: indexPath)
        tabCell.update(item: tabItems[indexPath.row], style: self.tabbarLayoutStyle)
        tabCell.selectionStyle = .none
        return tabCell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0.1
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0.1
    }
}

