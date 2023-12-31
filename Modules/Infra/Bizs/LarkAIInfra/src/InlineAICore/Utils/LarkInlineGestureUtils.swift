//
//  LarkInlineGestureUtils.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/8/31.
//  


import UIKit

protocol LarkInlineGestureUtilsDelegate: AnyObject {
    
    var isDragBarShow: Bool { get }

    var dragPanelNeedConfirm: Bool { get }
    
    var panGestureIsWorking: Bool { get  set }
    
    var lastPanelHeight: CGFloat { get  set }
    
    var isKeyboardShow: Bool { get }
    
    var keyBoardHeight: CGFloat { get }
    
    var keyboardMargin: CGFloat { get }
    
    var panelBottomOffset: CGFloat { get }
    
    var totalMinHeight: CGFloat { get }
    
    var totalMaxHeight: CGFloat { get }
    
    var defaultHeight: CGFloat { get }
    
    var contentRenderHeight: CGFloat { get }
    
    func setupLayout(_ height: CGFloat, topOffSet: CGFloat, animation: Bool)
    
    func getCurrentShowPanelHeight() -> CGFloat
    
    func disableContentAutolayout()
    
    var isGenerating: Bool { get }
    
    var setPanelToDefaultHeight: Bool { get set }
}

class LarkInlineGestureUtils {
    
    struct Metric {
        /// 快滑最小的速度
        static let minFlingValue: CGFloat = 1250
        
        static let minimumRationInKeyboardShow: CGFloat = 0.2
        static let defaultRatio: CGFloat = 0.6
        static let maxRatio: CGFloat = 0.7
    }

    enum Event {
        case dragPanelConfirm
        case closePanel
    }
    
    private var callback: ((Event) -> Void)

    weak var delegate: LarkInlineGestureUtilsDelegate?
    
    private var panelView: UIView
    
    private var containerView: UIView
    
    private var subViewPanBeginOffset: CGFloat?

    private var gestureBeginHeight: CGFloat = 0
    
    var isDraggingDragBar = false
    
    var currentRenderHeight: CGFloat?

    init(containerView: UIView, panelView: UIView, callback: @escaping ((Event) -> Void)) {
        self.containerView = containerView
        self.panelView = panelView
        self.callback = callback
    }

    
    /// 处理面板滑动手势
    /// - Parameters:
    ///   - gestureRecognizer:
    ///   - offset: 滑动内容非dragbar时，按压点距离panel顶部的高度
    ///   - maxHeight: 面板最大允许拉伸高度
    ///   - isDragBar: 是否拖动dragBar
    private func _handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer,
                                             offset: CGFloat,
                                             maxHeight: CGFloat? = nil,
                                             isDragBar: Bool = true) {
        guard let delegate else { return }

        defer {
            switch gestureRecognizer.state {
            case .ended, .cancelled, .failed:
                subViewPanBeginOffset = nil
                gestureBeginHeight = 0
                currentRenderHeight = nil
            default:
                break
            }
        }
        self.isDraggingDragBar = isDragBar
        
        let totalMaxHeight = delegate.contentRenderHeight

        /// dragBar顶部和容器顶部之间的距离
        let fingerY = gestureRecognizer.location(in: containerView).y - offset
        // fingerHeight: dragBar顶部距离容器底部的高度
        var fingerHeight = containerView.bounds.height - fingerY
        
        
        if gestureBeginHeight == 0 || gestureRecognizer.state == .began {
            gestureBeginHeight = fingerHeight
        }
        if !isDragBar,
           gestureBeginHeight > 0,
           fingerHeight <= gestureBeginHeight { // 没有到极限
            // 阻尼
            
            fingerHeight = InlineAIDampingControl.dampingFunction(current: fingerHeight - delegate.keyBoardHeight,
                                                                  max: gestureBeginHeight - delegate.keyBoardHeight)
        }

        let state = gestureRecognizer.state
        LarkInlineAILogger.debug("gesture \(gestureRecognizer.state.rawValue) offset:\(offset) fingerHeight:\(fingerHeight) maxHeight:\(String(describing: maxHeight))")
        let panelHeight = panelView.frame.size.height
        
        let isKeyboardShow = delegate.isKeyboardShow
        switch state {
        case .began, .changed:
            delegate.panGestureIsWorking = true
            gestureMove(isKeyboardShow: isKeyboardShow,
                        isDragBar: isDragBar,
                        panelHeight: panelHeight,
                        totalMaxHeight: totalMaxHeight,
                        fingerY: fingerY,
                        fingerHeight: fingerHeight,
                        maxHeight: maxHeight)
            
        case .ended, .cancelled, .failed:
            delegate.panGestureIsWorking = false
            gestureEnd(isKeyboardShow: isKeyboardShow,
                       isDragBar: isDragBar,
                       panelHeight: panelHeight,
                       totalMaxHeight: totalMaxHeight,
                       fingerY: fingerY,
                       fingerHeight: fingerHeight,
                       maxHeight: maxHeight,
                       offset: offset,
                       gestureRecognizer: gestureRecognizer,
                       state: state)
        default:
            let containerHeight = panelView.frame.size.height
            setupLayout(containerHeight, animation: true)
        }
    }

    
    /// 手势滚动中的处理
    /// - Parameters:
    ///   - isKeyboardShow: 键盘是否正在展示
    ///   - isDragBar: 是否由dragbar拖动
    ///   - panelHeight: 面板高度
    ///   - totalMaxHeight: 面板自身可自适应最大高度
    ///   - fingerY: dragBar顶部和容器顶部之间的距离
    ///   - fingerHeight: dragBar顶部距离容器底部的高度
    ///   - maxHeight: 面板最大允许拉伸高度
    func gestureMove(isKeyboardShow: Bool, isDragBar: Bool, panelHeight: CGFloat, totalMaxHeight: CGFloat, fingerY: CGFloat, fingerHeight: CGFloat, maxHeight: CGFloat?) {
        guard let delegate else { return }
        var containerHeight: CGFloat = 0
        // 键盘展示，高度不支持压缩，只支持拖动
        if isKeyboardShow {
            let topOffSet = max(self.containerView.frame.size.height - delegate.keyBoardHeight - delegate.keyboardMargin - panelHeight, fingerY)
            setupLayout(panelHeight, topOffSet: topOffSet)
        } else {
            if !isDragBar {
                let topOffSet = max(self.containerView.frame.size.height - delegate.panelBottomOffset - panelHeight, fingerY)
                setupLayout(panelHeight, topOffSet: topOffSet)
            } else {
                // 不超过屏幕高度的80%，如果已经全部展示完，用最高高度
                let maxFingerHeight = totalMaxHeight + delegate.panelBottomOffset
                let realFingerHeight = min(fingerHeight, maxFingerHeight)
                // 如果到40%，高度不再变小，面板整体高度下移
                var topOffSet: CGFloat = 0
                if realFingerHeight <= delegate.totalMinHeight + delegate.panelBottomOffset {
                    topOffSet = containerView.frame.size.height - realFingerHeight
                    containerHeight = delegate.totalMinHeight
                } else {
                    containerHeight = realFingerHeight - delegate.panelBottomOffset
                }
                let limit = maxHeight ?? CGFloat.greatestFiniteMagnitude
                let panelHeight = min(containerHeight, limit)
                setupLayout(panelHeight, topOffSet: topOffSet)
            }
        }
    }
    
    
    /// 手势滚动结束的处理
    /// - Parameters:
    ///   - isKeyboardShow: 键盘是否正在展示
    ///   - isDragBar: 是否由dragbar拖动
    ///   - panelHeight: 面板高度
    ///   - totalMaxHeight: 面板自身可自适应最大高度
    ///   - fingerY: dragBar顶部和容器顶部之间的距离
    ///   - fingerHeight: dragBar顶部距离容器底部的高度
    ///   - maxHeight: 面板最大允许拉伸高度
    ///   - offset: 滑动内容非dragbar时，按压点距离panel顶部的高度
    func gestureEnd(isKeyboardShow: Bool, isDragBar: Bool, panelHeight: CGFloat, totalMaxHeight: CGFloat, fingerY: CGFloat, fingerHeight: CGFloat, maxHeight: CGFloat?, offset: CGFloat, gestureRecognizer: UIPanGestureRecognizer, state: UIGestureRecognizer.State) {
        guard let delegate else { return }
        var containerHeight: CGFloat = 0
        let dragPanelNeedConfirm = delegate.dragPanelNeedConfirm
        let speed = gestureRecognizer.velocity(in: self.panelView)
        var flingToClose = false
        if state == .ended, speed.y > Metric.minFlingValue, offset > 0 {
            flingToClose = true
        }
        
        // 当面板本身高度很小时，手势结束回到原始位置，也会触发展示高度小于容器20%或者30%的逻辑。

        let minThreshold: CGFloat = 60
        var isBeyondThreshold = false
        if gestureBeginHeight > 0 {
            isBeyondThreshold = gestureBeginHeight - fingerHeight >= minThreshold
        }

        // 键盘展示时如果UI上展示的高度>=容器的20%，回弹；如果<20%，下掉
        if isKeyboardShow {
            let panelHeight = panelView.frame.size.height
            let topOffSet = max(self.containerView.frame.size.height - delegate.keyBoardHeight - delegate.keyboardMargin - panelHeight, fingerY)
            let currentShowHeight = self.containerView.frame.size.height - delegate.keyBoardHeight - delegate.keyboardMargin - topOffSet
            var shouldClose = currentShowHeight < (self.containerView.frame.size.height - containerView.safeAreaInsets.top ) * Metric.minimumRationInKeyboardShow
            
            shouldClose = shouldClose && isBeyondThreshold
     
            if shouldClose || flingToClose {
                // 需要二次确认，弹回初始位置
                if dragPanelNeedConfirm {
                    setupLayout(panelHeight, topOffSet: self.containerView.frame.size.height - delegate.keyBoardHeight - delegate.keyboardMargin - panelHeight, animation: true)
                    callback(.dragPanelConfirm)
                    return
                } else {
                    //通知前端下掉面板
                    callback(.closePanel)
                    return
                }
            }
            setupLayout(panelHeight, topOffSet: self.containerView.frame.size.height - delegate.keyBoardHeight - delegate.keyboardMargin - panelHeight, animation: true)
        } else {
            let translation = gestureRecognizer.translation(in: containerView)
            let panUp = translation.y < 0
    
            let realHeight = min(fingerHeight, totalMaxHeight + delegate.panelBottomOffset)
            let isReachMax = realHeight == totalMaxHeight + delegate.panelBottomOffset
            let triggerMinClose = (realHeight < delegate.totalMinHeight + delegate.panelBottomOffset) && isBeyondThreshold
            
            // 拖动停止位置超过了屏高的70%，认为要最大化
            let maxCriticalPoint: CGFloat = Metric.maxRatio
            if delegate.isGenerating || realHeight >= containerView.frame.size.height * maxCriticalPoint || isReachMax {
                containerHeight = totalMaxHeight
                // 如果是delegate.isGenerating导致的还需要恢复setPanelToDefaultHeight
                if delegate.isGenerating {
                    delegate.setPanelToDefaultHeight = true
                }
            } else if realHeight >= containerView.frame.size.height * Metric.defaultRatio, realHeight < containerView.frame.size.height * Metric.maxRatio  {
                containerHeight = delegate.defaultHeight
            } else if !panUp, triggerMinClose || flingToClose {
                // 需要二次确认，弹回初始位置
                if dragPanelNeedConfirm {
                    containerHeight = delegate.defaultHeight
                    callback(.dragPanelConfirm)
                } else {
                    //通知前端下掉面板
                    callback(.closePanel)
                    return
                }
                
            } else {
                delegate.lastPanelHeight = delegate.defaultHeight
                containerHeight = delegate.lastPanelHeight
            }
            if !isDragBar {
                let topOffSet = containerView.frame.size.height - delegate.panelBottomOffset - panelHeight
                setupLayout(panelHeight, topOffSet: topOffSet, animation: true)
            } else {
                let limit = maxHeight ?? CGFloat.greatestFiniteMagnitude
                let panelHeight = min(containerHeight, limit)
                delegate.lastPanelHeight = panelHeight
                setupLayout(panelHeight, animation: true)
            }
        }
    }
    
    private func setupSubViewPanBeginOffset(_ gestureRecognizer: UIPanGestureRecognizer) {
        if subViewPanBeginOffset == nil || gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: containerView)
            let mainPanelPoint = containerView.convert(point, to: self.panelView)
            subViewPanBeginOffset = mainPanelPoint.y
        }
    }
    
    private func setupLayout(_ height: CGFloat, topOffSet: CGFloat = 0, animation: Bool = false) {
        self.delegate?.setupLayout(height, topOffSet: topOffSet, animation: animation)
    }
}

extension LarkInlineGestureUtils {
    func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        setupSubViewPanBeginOffset(gestureRecognizer)
        // 不能滚动到高于手势之前的位置
        _handlePanGestureRecognizer(gestureRecognizer, offset: subViewPanBeginOffset ?? 0)
    }
}

extension LarkInlineGestureUtils: InlineAIViewPanGestureDelegate {

    func panGestureRecognizerDidReceive(_ gestureRecognizer: UIPanGestureRecognizer, in view: UIView) {
        guard let delegate = self.delegate,
              delegate.isDragBarShow == true else { return }
        setupSubViewPanBeginOffset(gestureRecognizer)
        // 不能滚动到高于手势之前的位置
        _handlePanGestureRecognizer(gestureRecognizer, offset: subViewPanBeginOffset ?? 0, maxHeight: delegate.lastPanelHeight, isDragBar: false)
    }

    func panGestureRecognizerDidFinish(_ gestureRecognizer: UIPanGestureRecognizer, in view: UIView) {
        currentRenderHeight = nil
        guard let delegate = self.delegate else { return }
        delegate.panGestureIsWorking = false
        var isScrollEnabled = false
        if let scrollView = gestureRecognizer.view as? UIScrollView {
            isScrollEnabled = scrollView.isScrollEnabled
        }
        if !isScrollEnabled {
            _handlePanGestureRecognizer(gestureRecognizer, offset: subViewPanBeginOffset ?? 0, maxHeight: delegate.lastPanelHeight, isDragBar: false)
        }
        self.subViewPanBeginOffset = nil
    }
}
