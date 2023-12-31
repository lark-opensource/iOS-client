//
//  FeedHeaderView+Layout.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import UIKit
import Foundation
import LarkOpenFeed

extension FeedHeaderView {

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshSubViewsWidth()
    }

    /// 通知 子view 宽度变了
    func refreshSubViewsWidth(_ isForced: Bool = false) {
        if isForced || oldWidth != bounds.width {
            oldWidth = bounds.width
            for view in sortedSubViews {
                let oldFrame = view.frame
                view.frame = CGRect(x: oldFrame.minX, y: oldFrame.minY, width: bounds.width, height: oldFrame.height)
            }
            viewModels.forEach { (viewModel) in
                viewModel.fireWidth(bounds.width)
            }
        }
    }

    // MARK: 更新header高度
    func fireViewHeight(viewModel: FeedHeaderItemViewModelProtocol) {
        let newStyle = getUpdateFrameStyle(viewModel)
        let newHeight = headerHeight
        let oldHeight = updateHeightRelay.value.0
        let oldStyle = updateHeightRelay.value.1
        if newHeight == oldHeight && newStyle == oldStyle {
            return
        }
        FeedContext.log.info("feedlog/header/outputHeight. \(viewModel.type)'display = \(viewModel.display), 'viewHeight = \(viewModel.viewHeight), totalHeight = \(newHeight), style = \(newStyle)")
        updateHeightRelay.accept((newHeight, newStyle))
    }

    func layout() {
        // 这里用frame来做，比autolayout来做要更加方便修改，避免不同view之间有关联
        // 校验条件: vm和view的count不相等
        guard sortedSubViews.count == visibleViewModels.count else {
            // 不会走到这，因为前面生产sortedSubViews和visibleViewModels是一起构造出来的
            return
        }

        var lastFrame = CGRect(x: 0,
                               y: 0,
                               width: self.bounds.size.width,
                               height: 0)
        for index in 0..<sortedSubViews.count {
            let view = sortedSubViews[index]
            let viewModel = visibleViewModels[index]
            let frame = CGRect(x: lastFrame.origin.x,
                               y: lastFrame.maxY,
                               width: lastFrame.width,
                               height: viewModel.viewHeight)
            view.frame = frame
            lastFrame = frame
        }
        shortcutsView?.normalLayout()
    }

    /// 获取Header高度
    private var headerHeight: CGFloat {
        var height: CGFloat = 0
        visibleViewModels.forEach { height += $0.viewHeight }
        return height
    }

    private func getUpdateFrameStyle(_ viewModel: FeedHeaderItemViewModelProtocol) -> HeaderUpdateHeightStyle {
        var updateHeightStyle: HeaderUpdateHeightStyle = .normal
        if viewModel.type == .shortcut {
            guard let shortcutsViewModel = self.shortcutsViewModel else {
                // shortcut 销毁的时候走的逻辑
                return updateHeightStyle
            }
            switch shortcutsViewModel.expandCollapseType {
            case .expandByScroll:
                // 通过滑动进行展开操作（下拉）
                updateHeightStyle = .expandByScrollForShortcut
            case .collapseByScroll:
                // 通过滑动进行收起操作（上滑）
                updateHeightStyle = .collapseByScrollForShortcut
            case .expandByClick, .collapseByClick:
                // 通过点击进行展开/收起操作
                updateHeightStyle = .expandCollapseByClickForShortcut
            default:
                break
            }
            shortcutsViewModel.expandCollapseType = .none // 消费完重置
        }
        return updateHeightStyle
    }
}
