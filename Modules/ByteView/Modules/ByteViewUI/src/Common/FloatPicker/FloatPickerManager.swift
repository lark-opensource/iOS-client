//
//  FloatPickerManager.swift
//  ByteViewUI
//
//  Created by lutingting on 2022/12/16.
//

import Foundation

public protocol FloatPickerManagerDelegate: AnyObject {
    /// 用户最终选择了idx
    func didPickOutItem(at index: Int, selectMode: SelectMode)
    /// 用户下滑取消了选择
    func didCancelSelection()
    /// 外界用来配置ItemView
    func cellForItem(at index: Int) -> UIImage?
}

extension FloatPickerManagerDelegate {
    public func didPickOutItem(at index: Int, selectMode: SelectMode) {}
    public func didCancelSelection() {}
}

/// 配置数据
public struct FloatPickerConfig {
    public enum InteractiveMode {
        case slide
        case tapAndSlide
    }
    public let itemCount: Int
    public var selectedItemIdx: Int
    public let viewSize: CGSize
    public let itemViewSize: CGSize

    public var contentInset: UIEdgeInsets = .zero
    /// 交互方式
    public var mode: InteractiveMode = .slide
    /// 交互热区
    public var operationDistance: CGFloat = 72
    /// 长按唤起面板之后的抖动距离(用户可能稍微移动)
    public var jitterDistance: CGFloat = 6
    public var direction: GuideDirection = .top
    /// 三角箭头离sourceView的距离
    public var distance: CGFloat = 4
    /// 对应弹出的View，default is ges.View
    public weak var sourceView: UIView?

    public init(itemCount: Int, selectedItemIdx: Int, viewSize: CGSize, itemViewSize: CGSize, sourceView: UIView? = nil) {
        self.itemCount = itemCount
        self.selectedItemIdx = selectedItemIdx
        self.viewSize = viewSize
        self.itemViewSize = itemViewSize
        self.sourceView = sourceView
    }
}

public final class FloatPickerManager {
    public var config: FloatPickerConfig
    /// 当前选中的Idx
    private var currentSelectedIdx: Int = 0
    /// 长按中用户是否滑动
    private var hadMove = false
    /// 用户取消选中
    private var cancelOperation = false
    ///长按手势的起点
    private var startPoint: CGPoint = .zero

    private weak var floatView: FloatPickerView?
    private var ghostSourceView: UIView?
    private weak var delegate: FloatPickerManagerDelegate?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public init(config: FloatPickerConfig, delegate: FloatPickerManagerDelegate?) {
        self.config = config
        self.delegate = delegate
        self.bindNotification()
    }

    private func bindNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    /// 长按的时候触发
    public func onLongPress(gesture: UILongPressGestureRecognizer) {
        let sourceView = self.config.sourceView ?? gesture.view
        guard let sourceView = sourceView else {
            assertionFailure("can't get current LongPressView")
            return
        }

        guard let window = sourceView.window else {
            assertionFailure("can't get current window")
            return
        }
        let state = gesture.state
        switch state {
        case .began:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.currentSelectedIdx = config.selectedItemIdx
            self.hadMove = false
            self.cancelOperation = false
            self.startPoint = gesture.location(in: window)
            let frame = sourceView.convert(sourceView.bounds, to: window)
            /// 获取坐标信息
            self.showFloatPickerView(on: window, sourceView: UIView(frame: frame))
            updateSeletedItem()
        case .changed:
            let location = gesture.location(in: window)
            self.onLongPressStausChange(location: location, window: window)
        case .ended:
            switch self.config.mode {
            case .slide:
                self.onLongPressStausEnd()
            case .tapAndSlide:
                if hadMove {
                    onLongPressStausEnd()
                } else {
                    floatView?.tapCallBack = { [weak self] in
                        self?.hideFloatPickerView()
                    }
                }
            }
            self.reset()
        default:
            self.hideFloatPickerView()
            self.reset()
        }
    }

    private func onLongPressStausChange(location: CGPoint, window: UIWindow) {
        guard let floatView = floatView else {
            hadMove = true
            return
        }
        let view = floatView.anchorView.contentView
        let frame = view.convert(view.bounds, to: window)
        let distance = config.jitterDistance
        if location.x - startPoint.x > distance || location.x - startPoint.x < -distance {
            hadMove = true
        }
        if location.y < frame.minY - config.operationDistance {
            return
        }
        if location.y > frame.maxY + config.operationDistance {
            hideFloatPickerView()
            cancelOperation = true
        } else {
            if hadMove {
                updateFloatViewStatus(with: location, floatView: floatView, window: window)
            }
        }
    }

    private func onLongPressStausEnd() {
        if !cancelOperation {
            pickOutItemAt(currentSelectedIdx, selectMode: .slide)
        } else {
            delegate?.didCancelSelection()
            hideFloatPickerView()
        }
    }

    private func showFloatPickerView(on view: UIView, sourceView: UIView) {
        var layoutConfig = FlowPickerLayoutConfig(sourceView: sourceView, viewSize: config.viewSize)
        layoutConfig.contentInset = config.contentInset
        layoutConfig.contentBGColor = .ud.bgFloat
        layoutConfig.borderWidth = 1
        layoutConfig.borderColor = .ud.lineBorderCard
        layoutConfig.cornerRadius = 8

        let floatView = FloatPickerView(layoutConfig: layoutConfig)
        floatView.dataSource = self
        floatView.delegate = self
        view.addSubview(floatView)
        floatView.addSubview(sourceView)
        floatView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        floatView.updateLayout()
        self.floatView = floatView
        self.ghostSourceView = sourceView
    }

    private func hideFloatPickerView() {
        if self.floatView != nil {
            self.floatView?.removeFromSuperview()
            self.floatView = nil
        }
        if ghostSourceView != nil {
            self.ghostSourceView?.removeFromSuperview()
            self.ghostSourceView = nil
        }
    }

    private func reset() {
        hadMove = false
        cancelOperation = false
    }

    private func updateFloatViewStatus(with location: CGPoint, floatView: FloatPickerView, window: UIWindow) {
        /// 获取当前cell的frame
        let frames = floatView.getSubViewFrame(on: window)
        /// 滑动时候更新数据
        let idx = getItemIndex(by: location, frames: frames)
        if idx < config.itemCount, currentSelectedIdx != idx {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            currentSelectedIdx = idx
            updateSeletedItem()
        }
    }

    private func pickOutItemAt(_ index: Int, selectMode: SelectMode) {
        self.delegate?.didPickOutItem(at: index, selectMode: selectMode)
        self.hideFloatPickerView()
    }

    /// 更新选中状态
    private func updateSeletedItem() {
        floatView?.selectItemAt(currentSelectedIdx)
    }

    /// 最合适的Item 当前滑动的时候
    private func getItemIndex(by location: CGPoint, frames: [CGRect]) -> Int {
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

    @objc
    private func orientationDidChange() {
        self.hideFloatPickerView()
    }
}

extension FloatPickerManager: FloatPickerViewDataSource, FloatPickerViewDelegate {
    public func numberOfItemsInSection() -> Int {
        return config.itemCount
    }

    public func cellForItem(at index: Int) -> UIImage? {
        return delegate?.cellForItem(at: index)
    }

    public func didSelectItem(at index: Int) {
        guard self.config.mode == .tapAndSlide, index < config.itemCount else {
            return
        }

        self.currentSelectedIdx = index
        self.updateSeletedItem()

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        /// 延时一下消失 有个选中效果
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.pickOutItemAt(index, selectMode: .tap)
        }
    }
}

public enum SelectMode {
    case tap
    case slide
}

extension UIView {
    //返回该view所在VC
    func firstViewController() -> UIViewController? {
        for view in sequence(first: self.superview, next: { $0?.superview }) {
            if let responder = view?.next {
                if responder.isKind(of: UIViewController.self) {
                    return responder as? UIViewController
                }
            }
        }
        return nil
    }
}
