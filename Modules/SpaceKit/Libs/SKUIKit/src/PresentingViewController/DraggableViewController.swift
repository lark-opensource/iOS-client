//
//  DraggableViewController.swift
//  SpaceKit
//
//  Created by Ryan on 2018/11/20.
//

import UIKit
import SKFoundation

private let GestureSpeed: CGFloat = 1000

open class DraggableViewController: OverCurrentContextViewController {
    public let watermarkConfig = WatermarkViewConfig()
    public var contentViewEndedY: CGFloat = 0
    private var lastViewSize: CGSize = .zero

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let selfViewSize = self.view.frame.size
        if lastViewSize.equalTo(selfViewSize) == false {
            tryUpdateContentViewConstraint()
            lastViewSize = selfViewSize
        }
    }

    public var contentView: UIView = .init() {
        didSet {
            contentViewDidSet = true
            watermarkConfig.add(to: contentView)
        }
    }

    private var contentViewDidSet: Bool = false

    public enum GapState {
        case full   // 面板拉到最高，顶部贴在 SafeAreaLayoutGuide.top 上
        case max    // 面板较高
        case min    // 面板较低
        case bottom // 面板不展示
        case adaptive // 面板自适应，iPad的popover形式下使用
    }

    public var syncGap: GapState?
    public var disableDrag = false
    public var contentViewCanBeDragged: Bool {
        (self.modalPresentationStyle == .custom || self.modalPresentationStyle == .overCurrentContext) && !disableDrag
    }

    open var gapState = GapState.max {
        didSet {
            guard contentViewDidSet, contentViewCanBeDragged else { return }

            tryUpdateContentViewConstraint()

            if lastGapState != oldValue {
                lastGapState = oldValue
            }
        }
    }

    func tryUpdateContentViewConstraint() {
        guard contentViewDidSet, selfViewHeight > 0,
              contentViewCanBeDragged else {
            return
        }
        var endedY: CGFloat = 0
        switch gapState {
        case .max:
            endedY = contentViewMaxY
        case .min:
            endedY = contentViewMinY
        case .bottom:
            endedY = selfViewHeight
        case .full:
            endedY = view.safeAreaInsets.top
        case .adaptive:
            endedY = 0
            return
        }
        contentViewEndedY = endedY
        self.contentView.snp.updateConstraints({ (make) in
            make.top.equalTo(contentViewEndedY)
        })
    }

    var topMargin: CGFloat = 0 {
        didSet {
            self.contentView.snp.updateConstraints({ (make) in
                make.top.equalTo(topMargin)
            })
        }
    }

    public lazy var lastGapState = gapState

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let state = syncGap {
            gapState = state
            syncGap = nil
        }
    }

    var selfViewHeight: CGFloat {
        let height = self.view.frame.size.height
        spaceAssert(height > 0, "高度异常，检查下时机")
        return height
    }
    
    /// 页面内容的最小高度（内容 height）
    public var contentViewMinHeight: CGFloat?

    /// 页面展示最小高度（坐标Y值），实际对应的是页面内容height最小
    private var _contentViewMaxY: CGFloat?
    public var contentViewMaxY: CGFloat {
        get {
            if let contentViewMinHeight = contentViewMinHeight {
                return selfViewHeight - contentViewMinHeight
            } else if let customValue = _contentViewMaxY {
                return customValue
            } else {
                return (1 - 0.63) * selfViewHeight
            }
        }
        set {
            _contentViewMaxY = newValue
        }
    }

    /// 页面展示最大高度（坐标Y值），实际对应的是页面内容height最大
    private var _contentViewMinY: CGFloat?
    public var contentViewMinY: CGFloat {
        get {
            if let customValue = _contentViewMinY {
                return customValue
            } else {
                return 64
            }
        }
        set {
            _contentViewMinY = newValue
        }
    }

    /// 页面展示中间高度
    var contentViewMiddle: CGFloat {
        return (contentViewMaxY + contentViewMinY) / 2
    }
    
    /// 触发页面关闭的高度(不同于contentViewMaxY)
    public var contentViewCloseY: CGFloat {
        return (selfViewHeight + contentViewMaxY) / 2
    }

    /// 拖动手势，加到你自己的业务的 view 上面
    public lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        return panGestureRecognizer
    }()

    @objc
    open func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        let state = gestureRecognizer.state

        let yTranslation = -gestureRecognizer.translation(in: view).y
        gestureRecognizer.setTranslation(.zero, in: view)

        // 0. comment view 不能超过屏幕底部
        let newContentViewY = contentView.frame.minY - yTranslation
        if newContentViewY < contentViewMinY {
            return
        } else if newContentViewY > contentViewMaxY {

        }

        contentView.snp.updateConstraints { (make) in
            make.top.equalTo(newContentViewY)
        }

        // 3. 超过一半的时候上去
        // 没超过就下来
        if state == .ended {
            // 3.1 先判断速度
            let speed = gestureRecognizer.velocity(in: view).y
            if speed <= -GestureSpeed { // 向上滑动速度
                let distance = newContentViewY - contentViewMinY
                let duration = distance / speed
                updateContentViewConstraints(duration: TimeInterval(duration), lastPositionY: contentViewMinY)
            } else if speed >= GestureSpeed { // 向下滑动速度
                let distance = contentViewMaxY - newContentViewY
                let duration = distance / speed

                if newContentViewY > contentViewMaxY { // 下滑收起，从feed进入屏蔽功能
                    updateContentViewConstraints(duration: TimeInterval(duration), lastPositionY: selfViewHeight)
                } else {
                    updateContentViewConstraints(duration: TimeInterval(duration), lastPositionY: contentViewMaxY)
                }
            } else {
                // 3.2 速度不符合判断位置
                updateContentViewConstraints(duration: 0.2, lastPositionY: newContentViewY)
            }
        }
    }
    /// 记录滚动前的上一次偏移位置，用于在禁止ScrollView内部滚动时重置滚动偏移位置
    private var lastScrollViewContentOffsetY: CGFloat = 0
    private var handleScrolling = false    // 避免在设置 contentOffset 时触发 handleScrollViewDidScroll 引发无限递归
    /// 用于支持内容时 scrollview 的情况，内容滚动也触发整体面板拖动，需要子类主动触发
    public func handleScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !handleScrolling,
                scrollView.panGestureRecognizer.numberOfTouches > 0 else {
            // 手指不在屏幕上就不再执行跟随移动的逻辑了
            lastScrollViewContentOffsetY = scrollView.contentOffset.y
            return
        }
        
        // 开始处理滚动
        handleScrolling = true
        defer {
            // 结束处理滚动
            handleScrolling = false
        }
        
        let contentOffsetY = scrollView.contentOffset.y
        let moveOffset = contentOffsetY - lastScrollViewContentOffsetY

        let currentContentViewY = contentView.frame.minY
        let newContentViewY = max(currentContentViewY - moveOffset, contentViewMinY)

        let topBaseY = -scrollView.contentInset.top
        if moveOffset > 0, currentContentViewY > contentViewMinY {
            // 向上滚动
            // scrollView 内部不滚动
            scrollView.contentOffset.y = lastScrollViewContentOffsetY
            // 面板向上移动
            contentView.snp.updateConstraints { make in
                make.top.equalTo(newContentViewY)
            }
        } else if moveOffset < 0, lastScrollViewContentOffsetY <= topBaseY {
            // 向下滚动
            // scrollView 内部不滚动
            scrollView.contentOffset.y = topBaseY
            // 面板向下移动
            contentView.snp.updateConstraints { make in
                make.top.equalTo(newContentViewY)
            }
        }
        lastScrollViewContentOffsetY = scrollView.contentOffset.y
    }
    
    public func handleScrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard contentViewCanBeDragged else {
            return
        }
        let newContentViewY = contentView.frame.minY
        if ceil(newContentViewY) == ceil(contentViewMinY) || ceil(newContentViewY) == ceil(contentViewMaxY) {
            return
        }
        let speed = scrollView.panGestureRecognizer.velocity(in: scrollView).y
        let topBaseY = -scrollView.contentInset.top
        if speed < -GestureSpeed {
            // 向上速度，直接滚动到最高位置
            updateContentViewConstraints(duration: TimeInterval(0.2), lastPositionY: contentViewMinY)
        } else if speed > GestureSpeed {
            // 向下速度
            // 根据当前的位置将面板移动到对应的位置
            updateContentViewConstraints(duration: TimeInterval(0.2), lastPositionY: newContentViewY > contentViewMaxY ? selfViewHeight : contentViewMaxY)
        } else {
            // 手松开时候，主动找到对应的位置移动面板
            updateContentViewConstraints(duration: TimeInterval(0.2), lastPositionY: newContentViewY)
        }
    }
    
    open func dragDismiss() {
        //抽象方法, 留给子类实现
    }
    
    open func dragFinish() {
        //抽象方法, 留给子类实现
    }

    fileprivate func updateContentViewConstraints(duration: TimeInterval, lastPositionY: CGFloat) {
        let closeY = contentViewCloseY
        if lastPositionY > closeY { // 超过下半部分
            gapState = .bottom
        } else if lastPositionY > contentViewMiddle && lastPositionY <= closeY { // 在下半部分
            gapState = .max
        } else { // 在上半部分
            gapState = .min
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
            self.contentView.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.dragFinish()
            if lastPositionY > closeY {
                self.dragDismiss()
            }
        })
    }
}
