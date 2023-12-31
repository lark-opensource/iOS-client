//
//  PadToolBar.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import UIKit

class PadToolBar: UIView {
    enum ItemLocation {
        case left
        case center
        case right
    }

    private var leftViews: [PadToolBarBaseView] = []
    private var centerViews: [PadToolBarBaseView] = []
    private var rightViews: [PadToolBarBaseView] = []
    /// 正在展示的 itemView, 包含复合型按钮的子 itemView
    private var viewMap: [ToolBarItemType: PadToolBarBaseView] = [:]

    func view(for type: ToolBarItemType) -> UIView? {
        viewMap[type]
    }

    // nolint-next-line: cyclomatic complexity
    override func layoutSubviews() {
        super.layoutSubviews()

        let rightCollapsePriority = ToolBarConfiguration.rightCollapsePriority
        let itemHeight = ToolBarItemLayout.padItemHeight
        let itemSpacing: CGFloat = 12
        let itemY: CGFloat = (TiledLayoutGuideHelper.bottomBarHeight - itemHeight) / 2

        [leftViews, centerViews, rightViews].flatMap { $0 }.forEach {
            $0.reset()
        }

        var completed = false

        log("======== Layout begin ========")

        // 逐步更新，查找能够放得下所有 item 的规则
        layoutLoop: while !completed {
            let leftShowingViews = leftViews.filter { !$0.isCollapsed }
            let rightShowingViews = rightViews.filter { !$0.isCollapsed }
            let centerShowingViews = centerViews.filter { !$0.isCollapsed }

            // 计算左侧、中间、右侧三部分视图的 intrinsic width
            let leftWidth = leftShowingViews.map { $0.itemWidth }.reduce(0, +) + CGFloat(leftShowingViews.count - 1) * itemSpacing
            let centerWidth = centerShowingViews.filter { !$0.isCollapsed }.map { $0.itemWidth }.reduce(0, +) + CGFloat(centerShowingViews.count - 1) * itemSpacing
            let rightWidth = rightShowingViews.filter { !$0.isCollapsed }.map { $0.itemWidth }.reduce(0, +) + CGFloat(rightShowingViews.count - 1) * itemSpacing

            let viewWidth = frame.width
            let leftStart: CGFloat = 12
            let centerStart = (viewWidth - centerWidth) / 2
            let rightStart = viewWidth - rightWidth - 12
            // 用于判断是否需要收纳的间距，当左侧与中间、中间与右侧间距小于此值时，将应用收纳规则
            let margin: CGFloat = 40

            let leftMargin = centerStart - (leftStart + leftWidth) - margin
            let rightMargin = rightStart - (centerStart + centerWidth) - margin
            let collapseLeft = leftMargin < rightMargin

            if leftMargin >= 0 && rightMargin >= 0 {
                log("Sectioned layout")
                // 左右间距满足需求，执行布局
                var x = leftStart
                for leftView in leftShowingViews {
                    leftView.frame = CGRect(x: x, y: itemY, width: leftView.itemWidth, height: itemHeight)
                    x += leftView.itemWidth + itemSpacing
                }

                x = centerStart
                for centerView in centerShowingViews {
                    centerView.frame = CGRect(x: x, y: itemY, width: centerView.itemWidth, height: itemHeight)
                    x += centerView.itemWidth + itemSpacing
                }

                x = rightStart
                for rightView in rightShowingViews {
                    rightView.frame = CGRect(x: x, y: itemY, width: rightView.itemWidth, height: itemHeight)
                    x += rightView.itemWidth + itemSpacing
                }

                completed = true
                break
            } else if collapseLeft {
                // 左侧、中间（含复合型按钮）文案隐藏
                for type in ToolBarConfiguration.centerTitleCollapsePriority {
                    if let titleView = viewMap[type] as? PadToolBarTitledView, titleView.showTitle {
                        log("hide center title for \(type)")
                        titleView.toggleTitle(show: false)
                        continue layoutLoop
                    }
                }

                // 收纳表情
                if let targetView = viewMap[.reaction] {
                    if targetView.collapseStep() {
                        log("Use fallback layout")
                        // 左侧间距不足 40，表情已经无法再收纳，按照兜底布局
                        fallbackLayout(leftShowingViews: leftShowingViews,
                                       centerShowingViews: centerShowingViews,
                                       rightShowingViews: rightShowingViews)
                        completed = true
                        break
                    } else {
                        log("hide reaction")
                    }
                    continue
                }
            } else {
                // 右侧文案隐藏
                for type in ToolBarConfiguration.rightTitleCollapsePriority {
                    if let titleView = viewMap[type] as? PadToolBarTitledView, titleView.showTitle {
                        Logger.ui.debug("[PadToolbar] hide right title for \(type)")
                        titleView.toggleTitle(show: false)
                        continue layoutLoop
                    }
                }

                // 收纳右侧
                if let target = rightCollapsePriority.first(where: { viewMap[$0]?.isCollapsed == false }), let targetView = viewMap[target] {
                    Logger.ui.debug("[PadToolbar] collapse right item for \(targetView.itemType)")
                    targetView.isCollapsed = true
                    targetView.isHidden = true
                    continue
                }
            }

            // 相应位置收纳完毕，无法继续靠收纳解决，此时异化布局，整体居中
            fallbackLayout(leftShowingViews: leftShowingViews,
                           centerShowingViews: centerShowingViews,
                           rightShowingViews: rightShowingViews)
            completed = true
        }
        log("======== Layout end ========")

        if let moreView = viewMap[.more], let moreItem = moreView.item as? ToolBarMoreItem {
            moreItem.updateMoreBadge()
        }

        NotificationCenter.default.post(name: .padToolBarFinishedLayout, object: nil)
    }

    // MARK: - Public

    func addItemViews(_ itemViews: [PadToolBarBaseView], on location: ItemLocation) {
        for (i, itemView) in itemViews.enumerated() {
            insertItemView(itemView, at: i, location: location)
        }
    }

    func insertSubItemView(_ subItemView: PadToolBarBaseView) {
        if viewMap[subItemView.itemType] == nil {
            viewMap[subItemView.itemType] = subItemView
        }
    }

    func insertItemView(_ itemView: PadToolBarBaseView, at position: Int, location: ItemLocation) {
        guard itemView.superview == nil, canInsert(at: position, location: location) else {
            return
        }
        viewMap[itemView.item.itemType] = itemView
        if let combinedView = itemView as? PadToolBarCombinedView {
            combinedView.itemViews.forEach { viewMap[$0.itemType] = $0 }
        }
        switch location {
        case .left:
            leftViews.insert(itemView, at: position)
            addSubview(itemView)
        case .center:
            centerViews.insert(itemView, at: position)
            addSubview(itemView)
        case .right:
            rightViews.insert(itemView, at: position)
            addSubview(itemView)
        }
    }

    func removeItemView(at position: Int, location: ItemLocation) {
        switch location {
        case .left:
            leftViews = safeRemoveItem(at: position, from: leftViews)
        case .center:
            centerViews = safeRemoveItem(at: position, from: centerViews)
        case .right:
            rightViews = safeRemoveItem(at: position, from: rightViews)
        }
    }

    func removeSubItemView(_ subItemType: ToolBarItemType) {
        if viewMap[subItemType] != nil {
            viewMap.removeValue(forKey: subItemType)
        }
    }

    // MARK: - Private

    private func canInsert(at position: Int, location: ItemLocation) -> Bool {
        switch location {
        case .left: return position <= leftViews.count
        case .center: return position <= centerViews.count
        case .right: return position <= rightViews.count
        }
    }

    private func safeRemoveItem(at position: Int, from views: [PadToolBarBaseView]) -> [PadToolBarBaseView] {
        guard position < views.count else { return views }
        let view = views[position]
        if let subTypes = ToolBarConfiguration.combination[view.itemType] {
            subTypes.forEach { viewMap.removeValue(forKey: $0) }
        }
        viewMap.removeValue(forKey: view.itemType)
        view.removeFromSuperview()
        var result = views
        result.remove(at: position)
        return result
    }

    private func fallbackLayout(leftShowingViews: [PadToolBarBaseView],
                                centerShowingViews: [PadToolBarBaseView],
                                rightShowingViews: [PadToolBarBaseView]) {
        let moreCollapsePriority = ToolBarConfiguration.centerCollapsePriority
        let rightCollapsePriority = ToolBarConfiguration.rightCollapsePriority
        let viewWidth = frame.width
        let itemHeight = ToolBarItemLayout.padItemHeight
        let itemY: CGFloat = (TiledLayoutGuideHelper.bottomBarHeight - itemHeight) / 2

        log("Fallback layout")
        let interaction: [ToolBarItemType] = [.chat, .reaction]
        let fallbackMargin: CGFloat = 8
        let collapsePriority = [rightCollapsePriority, moreCollapsePriority].flatMap { $0 }
        let fallbackViews = [leftShowingViews, centerShowingViews, rightShowingViews].flatMap { $0 }.filter { !interaction.contains($0.itemType) }
        let fallbackViewMap = Dictionary(fallbackViews.map { ($0.itemType, $0) }) { $1 }

        fallbackViews
            .compactMap { $0 as? PadToolBarTitledView }
            .forEach { $0.toggleTitle(show: false) }
        for type in interaction {
            if let view = viewMap[type] {
                view.isCollapsed = true
                view.isHidden = true
            }
        }

        var fallbackWidth = fallbackViews.map { $0.itemWidth }.reduce(0, +) + CGFloat(fallbackViews.count - 1) * 10 + 2 * fallbackMargin

        // 如果整体居中宽度超过屏幕，则按照顺序逐一隐藏，直到屏幕内能放得下
        for current in collapsePriority {
            if fallbackWidth <= viewWidth {
                break
            }
            if let view = fallbackViewMap[current] {
                view.isCollapsed = true
                view.isHidden = true
                fallbackWidth -= (view.itemWidth + 10)
            } else if let parentType = ToolBarFactory.combinedType(by: current), let parentView = fallbackViewMap[parentType] as? PadToolBarCombinedView, let view = parentView.itemView(for: current) {
                view.isCollapsed = true
                view.isHidden = true
                fallbackWidth -= (view.itemWidth)
                if parentView.itemViews.allSatisfy({ $0.isHidden }) {
                    parentView.isCollapsed = true
                    parentView.isHidden = true
                }
            }
        }

        var fallbackStart = (viewWidth - fallbackWidth) / 2 + fallbackMargin
        for view in fallbackViews where !view.isHidden {
            view.frame = CGRect(x: fallbackStart, y: itemY, width: view.itemWidth, height: itemHeight)
            fallbackStart += view.itemWidth + 10
        }
    }

    private func log(_ string: String) {
        Logger.ui.debug("[PadToolbar] \(string)")
    }
}

extension Notification.Name {
    static let padToolBarFinishedLayout = Notification.Name("padToolBarFinishedLayout")
}
