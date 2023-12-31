//
//  ToolBarPadViewController.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import UIKit

class ToolBarPadViewController: ToolBarViewController {
    private let toolbar = PadToolBar()

    private var leftItems: [ToolBarItemType] = []
    private var centerItems: [ToolBarItemType] = []
    private var rightItems: [ToolBarItemType] = []

    override func setupViews() {
        super.setupViews()

        view.backgroundColor = UIColor.ud.bgBody
        toolbar.backgroundColor = .clear
        view.addSubview(toolbar)
        toolbar.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        viewModel.setBridge(self, for: .toolbar)
        viewModel.addListener(self)
        initItemViews()
    }

    private func initItemViews() {
        leftItems = viewModel.padLeftItems.filter { shouldShowPadItem($0, on: .left) }
        toolbar.addItemViews(leftItems.map { viewModel.factory.padItemView(for: $0) }, on: .left)

        centerItems = viewModel.padCenterItems.filter { shouldShowPadItem($0, on: .center) }
        toolbar.addItemViews(centerItems.map { viewModel.factory.padItemView(for: $0) }, on: .center)

        rightItems = viewModel.padRightItems.filter { shouldShowPadItem($0, on: .right) }
        toolbar.addItemViews(rightItems.map { viewModel.factory.padItemView(for: $0) }, on: .right)
    }

    private func shouldShowPadItem(_ type: ToolBarItemType, on location: PadToolBar.ItemLocation) -> Bool {
        let itemLocation = viewModel.factory.item(for: type).desiredPadLocation
        switch (itemLocation, location) {
        case (.left, .left): return true
        case (.right, .right): return true
        case (.center, .center): return true
        default: return false
        }
    }

    private func currentLocation(of itemType: ToolBarItemType) -> PadToolBar.ItemLocation? {
        let index = [leftItems, centerItems, rightItems].firstIndex {
            $0.contains { $0 == itemType }
        }
        if let index = index {
            return [.left, .center, .right][index]
        } else {
            return nil
        }
    }

    override func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        if container.meetingLayoutStyle == .tiled {
            view.backgroundColor = UIColor.ud.bgBody
        } else {
            view.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.92)
        }
        if container.meetingLayoutStyle == .overlay {
            view.vc.addOverlayShadow(isTop: false)
        } else {
            view.vc.removeOverlayShadow()
        }
    }
}

extension ToolBarPadViewController: ToolBarViewModelDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        let itemType = item.itemType
        let combinedType = ToolBarFactory.combinedType(by: itemType)
        let oldLocation = currentLocation(of: itemType)
        // PadViewController 使用 desiredLocation 来确定一个 item 是否有可能显示在 toolbar 上
        // 至于实际是否显示，由 toolbar 内部布局时根据空间来决定
        let newLocation = item.desiredPadLocation
        switch (oldLocation, newLocation) {
        case (nil, .left):
            // 不在左边 -> 显示在左边
            let position = ToolBarFactory.insertPosition(of: item.itemType,
                                                         target: leftItems,
                                                         order: viewModel.padLeftItems)
            leftItems.insert(item.itemType, at: position)
            toolbar.insertItemView(viewModel.factory.padItemView(for: item.itemType),
                                   at: position,
                                   location: .left)
        case (nil, .center):
            // 不在中间 -> 显示在中间
            let position = ToolBarFactory.insertPosition(of: item.itemType,
                                                         target: centerItems,
                                                         order: viewModel.padCenterItems)
            centerItems.insert(item.itemType, at: position)
            toolbar.insertItemView(viewModel.factory.padItemView(for: item.itemType),
                                   at: position,
                                   location: .center)
        case (nil, .right):
            // 不在右边 -> 显示在右边
            let position = ToolBarFactory.insertPosition(of: item.itemType,
                                                         target: rightItems,
                                                         order: viewModel.padRightItems)
            rightItems.insert(item.itemType, at: position)
            toolbar.insertItemView(viewModel.factory.padItemView(for: item.itemType),
                                   at: position,
                                   location: .right)
        case (.left, let x) where x != .left:
            // 显示在左边 -> 显示在其他位置或隐藏
            if let index = leftItems.firstIndex(of: item.itemType) {
                leftItems.remove(at: index)
                toolbar.removeItemView(at: index, location: .left)
            }
        case (.center, let x) where x != .center:
            // 显示在中间 -> 显示在其他位置（隐藏或 more 内）
            if let index = centerItems.firstIndex(of: item.itemType) {
                centerItems.remove(at: index)
                toolbar.removeItemView(at: index, location: .center)
            }
        case (.right, let x) where x != .right:
            // 显示在右边 -> 显示在其他位置（隐藏或 more 内）
            if let index = rightItems.firstIndex(of: item.itemType) {
                rightItems.remove(at: index)
                toolbar.removeItemView(at: index, location: .right)
            }
        case (nil, .inCombined):
            // 复合型按钮 - 添加子视图
            if let combinedType = combinedType,
               let combinedView = toolbar.view(for: combinedType) as? PadToolBarCombinedView,
               let subItemView = combinedView.itemView(for: itemType) {
                toolbar.insertSubItemView(subItemView)
            }
        case (nil, .none):
            // 复合型按钮 - 移除子视图
            toolbar.removeSubItemView(itemType)
        default: return
        }
        (viewModel.factory.item(for: .more) as? ToolBarMoreItem)?.updateMoreBadge()
    }

    func toolbarItemSizeDidChange(_ item: ToolBarItem) {
        toolbar.setNeedsLayout()
    }
}

extension ToolBarPadViewController: ToolBarViewModelBridge {
    func toggleToolBarStatus(expanded: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func itemView(with type: ToolBarItemType) -> UIView? {
        if let view = toolbar.view(for: type), !view.isHidden {
            return view
        } else {
            return nil
        }
    }
}
