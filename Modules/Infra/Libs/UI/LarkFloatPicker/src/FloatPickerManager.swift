//
//  FloatPickerManager.swift
//
//  Created by liluobin on 2022/1/5.
//

import Foundation
import UIKit

public protocol FloatPickerManagerDelegate: AnyObject {
    /// 用户选择了idx
    func didSelectedIndex(_ seletcedIdx: Int, allItemCount: Int, selectedWay: SelectedWay)
    /// 用户下滑取消了选择
    func userDidCancelSeleted()
    /// 外界用来配置ItemView
    func itemViewWillAppearForIndexItem(_ indexItem: FloatPickerIndexItem,
                                        itemView: FloatPickerDisplayItemView)
    /// 选择浮层将要出现
    func floatPickerViewWillAppear()
    /// 选择浮层已经出现
    func floatPickerViewDidAppear()
    /// 选择浮层要将隐层
    func floatPickerViewWillDisappear()
    /// 选择浮层已经隐藏
    func floatPickerViewDidDisappear()
}
/// TODO: 李洛斌 这个的命名
extension FloatPickerManagerDelegate {
    public func didSelectedIndex(_ seletcedIdx: Int, allItemCount: Int, selectedWay: SelectedWay) {}
    public func floatPickerViewWillAppear() {}
    public func floatPickerViewDidAppear() {}
    public func floatPickerViewWillDisappear() {}
    public func floatPickerViewDidDisappear() {}
    public func userDidCancelSeleted() {}
}

/// 配置数据
public struct FloatPickerConfig {
    public enum InteractiveStyle {
        case slide
        case tapAndSlide
    }
    /// 基于当前屏幕上的，上下左右闪避范围
    let avoidInsets: UIEdgeInsets
    /// 当前Item的总数量
    let allItemCount: Int
    /// 当前选中的Idx
    let selectedItemIdx: Int
    /// 气泡偏移
    let contentOffset: CGFloat
    /// 交互方式
    let style: InteractiveStyle
    /// 交互热区
    let operationDistance: CGFloat
    /// 长按唤起面板之后的抖动距离(用户可能稍微移动)
    let jitterDistance: CGFloat
    /// 对应弹出的View，default is ges.View
    weak var sourceView: UIView?

    public init(avoidInsets: UIEdgeInsets,
                allItemCount: Int,
                selectedItemIdx: Int,
                interactiveStyle: InteractiveStyle,
                jitterDistance: CGFloat = 6,
                contentOffset: CGFloat = 0,
                operationDistance: CGFloat = 85,
                sourceView: UIView? = nil) {
        self.avoidInsets = avoidInsets
        self.allItemCount = allItemCount
        self.selectedItemIdx = selectedItemIdx
        self.style = interactiveStyle
        self.jitterDistance = jitterDistance
        self.contentOffset = contentOffset
        self.operationDistance = operationDistance
        self.sourceView = sourceView
    }
}

public final class FloatPickerManager {
    public let config: FloatPickerConfig
    /// 当前选中的Idx
    public var currentSelectIdx: Int = 0
    /// 长按中用户是否滑动
    private var userHadMove = false
    /// 用户取消选中
    private var userCancelOperation = false
    ///长按手势的起点
    private var startPoint: CGPoint = .zero

    public weak var floatView: FloatPickerView?
    private weak var maskView: FloatPickerBackgroundMaskView?
    private weak var delegate: FloatPickerManagerDelegate?

    private lazy var items: [FloatPickerIndexItem] = []

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public static func removeFloatPickerFromWindow(_ window: UIWindow?) {
        guard let window = window else {
            return
        }
        window.subviews.forEach { view in
            if (view as? FloatPickerView) != nil || (view as? FloatPickerBackgroundMaskView) != nil {
                view.removeFromSuperview()
            }
        }
    }
    
    public init(config: FloatPickerConfig,
         delegate: FloatPickerManagerDelegate?) {
        self.config = config
        self.delegate = delegate
        self.addObserver()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiverNotification),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    @objc
    private func receiverNotification() {
        self.hideFloatPickerView()
    }

    /// 长按的时候触发
    public func onLongPress(gesture: UILongPressGestureRecognizer) {
        let sourceView = self.config.sourceView ?? gesture.view
        guard let sourceView = sourceView else {
            assertionFailure("获取不到当前的LongPressView")
          return
        }

        let window: UIWindow? = sourceView.window ?? UIApplication.shared.keyWindow
        guard let window = window else {
            assertionFailure("获取不到当前的window")
          return
        }
        let state = gesture.state
        switch state {
        case .began:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.configItems()
            self.userHadMove = false
            self.userCancelOperation = false
            let bgView = FloatPickerBackgroundMaskView()
            bgView.frame = window.bounds
            window.addSubview(bgView)
            self.maskView = bgView
            self.startPoint = gesture.location(in: window)
            let frame = sourceView.convert(sourceView.bounds, to: window)
            self.delegate?.floatPickerViewWillAppear()
            /// 获取坐标信息
            self.showFloatPickerViewOn(view: window, centerAlignedRect: frame)
            self.delegate?.floatPickerViewDidAppear()
        case .changed:
            let location = gesture.location(in: window)
            self.onLongPressStausChange(location: location, floatView: self.floatView, window: window)
        case .ended:
            switch self.config.style {
            case .slide:
                self.onLongPressStausEnd()
            case .tapAndSlide:
                if self.userHadMove {
                    self.onLongPressStausEnd()
                } else {
                    self.maskView?.tapCallBack = { [weak self] in
                        self?.hideFloatPickerView()
                    }
                }
            }
            self.resetTempData()
        default:
            self.hideFloatPickerView()
            self.resetTempData()
        }
    }

    private func resetTempData() {
        self.userHadMove = false
        self.userCancelOperation = false
    }

    private func configItems() {
        /// 手势开始, 配置selectedItemIdx
        self.currentSelectIdx = config.selectedItemIdx
        var itemArray: [FloatPickerIndexItem] = []
        for idx in 0..<self.config.allItemCount {
            itemArray.append(FloatPickerIndexItem(idx: idx, isSelected: idx == self.currentSelectIdx))
        }
        self.items = itemArray
    }

    public func showFloatPickerViewOn(view: UIView, centerAlignedRect: CGRect) {
        let layoutConfig = FlowPickerLayoutConfig(safeAreaInsets: view.safeAreaInsets,
                                                    centerAlignedRect: centerAlignedRect,
                                                    itemsCount: self.items.count,
                                                    limitedArea: view.bounds,
                                                    avoidInsets: self.config.avoidInsets,
                                                    contentOffset: self.config.contentOffset)
        let layout = FloatPickerViewLayout(layoutConfig: layoutConfig)
        let floatView = FloatPickerView(layout: layout, dataSource: self, delegate: self)
        floatView.updateLayout()
        view.addSubview(floatView)
        self.floatView = floatView
    }

    public func hideFloatPickerView() {
        if self.floatView != nil {
            self.delegate?.floatPickerViewWillDisappear()
            self.floatView?.removeFromSuperview()
            self.floatView = nil
            self.delegate?.floatPickerViewDidDisappear()
        }
        if self.maskView != nil {
            self.maskView?.removeFromSuperview()
            self.maskView = nil
        }
    }

    private func updateFloatViewStatusWith(location: CGPoint, floatView: FloatPickerView, window: UIWindow) {
        /// 获取当前cell的frame
        let frames = floatView.getSubViewFrame().map { rect -> CGRect in
            let origin = floatView.convert(rect.origin, to: window)
            return CGRect(origin: origin, size: rect.size)
        }
        /// 滑动时候更新数据
        let idx = self.getOptimalItemIndexWith(location: location, frames: frames)
        if idx < items.count, self.currentSelectIdx != items[idx].idx {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.currentSelectIdx = items[idx].idx
            self.updateSeletedItem()
        }
    }

    private func didSeletedIdx(_ idx: Int, selectedWay: SelectedWay) {
        self.delegate?.didSelectedIndex(idx, allItemCount: self.config.allItemCount, selectedWay: selectedWay)
        self.hideFloatPickerView()
    }

    /// 更新选中状态
    private func updateSeletedItem() {
        self.items.forEach { item in
            item.isSelected = item.idx == self.currentSelectIdx
        }
        self.floatView?.reloadData()
    }

    private func onLongPressStausChange(location: CGPoint, floatView: FloatPickerView?, window: UIWindow) {
        guard let floatView = floatView else {
            self.userHadMove = true
            return
        }
        let distance = self.config.jitterDistance
        if location.x - startPoint.x > distance || location.x - startPoint.x < -distance {
            self.userHadMove = true
        }
        if location.y < floatView.frame.minY - self.config.operationDistance {
            return
        }
        if location.y > floatView.frame.maxY + self.config.operationDistance {
            self.hideFloatPickerView()
            self.userCancelOperation = true
        } else {
            if self.userHadMove {
                self.updateFloatViewStatusWith(location: location, floatView: floatView, window: window)
            }
        }
    }

    private func onLongPressStausEnd() {
        if !self.userCancelOperation {
            self.didSeletedIdx(self.currentSelectIdx, selectedWay: .slide)
        } else {
            self.delegate?.userDidCancelSeleted()
            self.hideFloatPickerView()
        }
    }

    /// 最合适的Item 当前滑动的时候
    public func getOptimalItemIndexWith(location: CGPoint, frames: [CGRect]) -> Int {
        if frames.count <= 1 {
            return 0
        }
        let minx = frames[0].minX
        let maxX = frames[frames.count - 1].maxX

        if location.x < minx {
            return 0
        }

        if location.x > maxX {
            return frames.count - 1
        }
        return frames.firstIndex { location.x >= $0.minX && location.x <= $0.maxX } ?? 0
    }

}

extension FloatPickerManager: FloatPickerViewDataSource, FloatPickerViewDelegate {

    public func numberOfRowsInSection() -> Int {
        return self.items.count
    }

    public func itemViewForIndex(_ index: Int) -> FloatPickerBaseItemView {
        let item = self.items[index]
        let itemView = FloatPickerDisplayItemView(item: item)
        self.delegate?.itemViewWillAppearForIndexItem(item, itemView: itemView)
        return itemView
    }

    public func didClickItemViewAtIdx(_ idx: Int) {
        guard self.config.style == .tapAndSlide, idx < self.items.count else {
            return
        }
        let item = self.items[idx]
        self.currentSelectIdx = item.idx
        self.updateSeletedItem()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        /// 延时一下消失 有个选中效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.didSeletedIdx(item.idx, selectedWay: .tap)
        }
    }
}

// 长按 ReactionPanel 上的表情（如👍🏻图标）会出现「多肤色浮层」，选中多肤色的方式
public enum SelectedWay {
    case tap    // 点击
    case slide  // 长按出现「多肤色浮层」后，可以直接滑动手指的方式选择
}
