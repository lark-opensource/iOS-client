//
//  WhiteboardView.swift
//  Whiteboard
//
//  Created by helijian on 2022/2/28.
//

import Foundation
import UIKit
import WbLib
import SnapKit
import ByteViewNetwork
import UniverseDesignColor
import ByteViewCommon
import UniverseDesignIcon
import UniverseDesignToast

public enum DataType {
    // 需要应用到白板 Snapshot 中的数据，比如图形的增减
    case drawData
    // 不需要应用到白板 Snapshot 中的数据，比如创建图形时的数据更新
    case syncData
}

protocol WhiteboardViewTouchEventDelegate: AnyObject {
    func whiteboardViewIsZoomingOrDragging(isZoomingOrDragging: Bool)
    func didTapMenuButton()
}

extension WhiteboardViewTouchEventDelegate {
    func whiteboardViewIsZoomingOrDragging(isZoomingOrDragging: Bool) {}
    func didTapMenuButton() {}
}

class WhiteboardView: UIView {
    static var displayScale: CGFloat = 1.0
    var touchScaleX: CGFloat = 1.0
    var touchScaleY: CGFloat = 1.0
    // 有缩放或者移动时进行位置记录
    var lastCenter: CGPoint?
    var lastOrigin: CGPoint?
    var lastContentOffset: CGPoint?

    var lastPointInBoard: CGPoint?
    // 是否在绘制状态，需要代理出去给外界做透明度改变以及隐藏视图。
    var drawing = false {
        didSet {
            if !oldValue, drawing {
                viewModel.delegate?.changeDrawingState(isDrawing: true)
                viewModel.dependencies?.setNeedChangeAlphaOfSuspensionComponent(isOpaque: false)
            } else if oldValue, !drawing {
                viewModel.delegate?.changeDrawingState(isDrawing: false)
                viewModel.dependencies?.setNeedChangeAlphaOfSuspensionComponent(isOpaque: true)
            }
        }
    }

    var scrollViewBgColor: UIColor? {
        get {
            scrollView.backgroundColor
        }
        set {
            scrollView.backgroundColor = newValue
        }
    }

    var zoomScale: CGFloat = 1.0 {
        didSet {
            updateTextScale()
        }
    }

    var sketchRect: CGRect {
        CGRect(origin: .zero, size: self.viewModel.drawBoard.canvasSize)
    }

    var toolBarRect: CGRect {
        if let toolBarPoint = toolBarPoint {
            let convertedPoint = self.convert(toolBarPoint, to: containerView)
            return CGRect(origin: .zero, size: CGSize(width: convertedPoint.x * touchScaleX, height: convertedPoint.y * touchScaleY))
        }
        return .zero
    }

    weak var touchEventDelegate: WhiteboardViewTouchEventDelegate?
    var gesture: WhiteboardGestRecognizer?
    var viewStyle: WhiteboardViewStyle
    private let viewModel: WhiteboardViewModel
    private var containerView: UIView = UIView(frame: .zero)
    private var scrollView: UIScrollView = UIScrollView(frame: .zero)
    private var doubleTapZoomScale: CGFloat = 2.0
    // ipad上工具栏的右下角点，用于确定绘制区域
    private var toolBarPoint: CGPoint?
    private(set) weak var doubleTapGestureRecognizer: UITapGestureRecognizer?
    private var canvasSize: CGSize {
        didSet {
            viewModel.canvasSize = canvasSize
            setNeedsLayout()
        }
    }

    init(clientConfig: WhiteboardClientConfig, viewStyle: WhiteboardViewStyle, whiteboardInfo: WhiteboardInfo?) {
        self.canvasSize = clientConfig.canvasSize
        self.viewStyle = viewStyle
        self.viewModel = WhiteboardViewModel(clientConfig: clientConfig, whiteboardInfo: whiteboardInfo)
        super.init(frame: .zero)
        Self.displayScale = self.vc.displayScale
        setupUI()
        bindViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var lastBounds: CGRect = .zero

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        Self.displayScale = self.vc.displayScale
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = self.bounds
        updateContainerView()
        let equalSize = createEqualSize(containerView.bounds.size, rootLayerSize: viewModel.drawBoard.rootLayer.bounds.size)
        updateTouchTransform(equalSize)
        let scaleX = equalSize.width / viewModel.drawBoard.rootLayer.bounds.size.width
        let scaleY = equalSize.height / viewModel.drawBoard.rootLayer.bounds.size.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let updateAction: () -> Void = {
            self.viewModel.drawBoard.rootLayer.setAffineTransform(transform)
        }
        if let animation = self.layer.animation(forKey: "bounds.size") {
            CATransaction.begin()
            CATransaction.setAnimationDuration(animation.duration)
            CATransaction.setAnimationTimingFunction(animation.timingFunction)
            updateAction()
            CATransaction.commit()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            updateAction()
            CATransaction.commit()
        }
        if viewStyle == .phone, (Display.pad || !isPhoneLandscape), lastBounds.size.width == self.bounds.size.width {
            let centerY = containerView.center.y
            // 恢复之前的缩放比例以及位置
            if let lastOrigin = lastOrigin {
                containerView.frame.origin = lastOrigin
                self.lastOrigin = nil
            } else {
                let oldOrigin = containerView.frame.origin
                containerView.frame.origin = CGPoint(x: oldOrigin.x > 0 ? oldOrigin.x : 0, y: oldOrigin.y > 0 ? oldOrigin.y : 0)
            }
            if let lastCenter = lastCenter {
                containerView.center.x = lastCenter.x
                self.lastCenter = nil
            }
            if let lastContentOffset = lastContentOffset {
                scrollView.contentOffset = lastContentOffset
                self.lastContentOffset = nil
            }
            containerView.center.y = centerY
            if containerView.frame.origin.y < 0 {
                containerView.frame.origin.y = 0
            }
        } else {
            // 每次切换都对画板进行重置
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        }
        if lastBounds.size.width != self.bounds.size.width {
            lastCenter = nil
            lastOrigin = nil
            lastContentOffset = nil
        }
        lastBounds = self.bounds
        self.drawing = false
    }

    func receiveWhiteboardInfo(_ info: WhiteboardInfo) {
        if info.whiteboardSettings.canvasSize != canvasSize {
            canvasSize = info.whiteboardSettings.canvasSize
        }
        viewModel.receiveWhiteboardInfo(info: info)
    }

    @objc func didTapMenuButton() {
        touchEventDelegate?.didTapMenuButton()
    }

    @objc func handleDoubleTap(sender: UITapGestureRecognizer) {
        let aspectFillZoomScale = max(self.scrollView.bounds.width / canvasSize.width, self.scrollView.bounds.height / canvasSize.height)
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            // 缩小到1.0
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            if aspectFillZoomScale > 2 * scrollView.minimumZoomScale {
                // AspectFill
                scrollView.setZoomScale(aspectFillZoomScale, animated: true)
            } else {
                // 放大到doubleTapZoomScale
                scrollView.setZoomScale(doubleTapZoomScale * scrollView.minimumZoomScale / aspectFillZoomScale, animated: true)
            }
        }
    }

    // 撑大绘制区域到整个屏幕
    func setLayerScale(_ isSharer: Bool = false) {
        DispatchQueue.main.async {
            // 部分机型如iPhone12 Promax反算的时候，可能会出现极小的小数，直接四舍五入
            let width = (self.viewModel.drawBoard.rootLayer.bounds.width / self.touchScaleX).rounded()
            let height = (self.viewModel.drawBoard.rootLayer.bounds.height / self.touchScaleY).rounded()
            var scale: CGFloat
            if self.frame.width == width {
                scale = self.frame.height / height
            } else {
                scale = self.frame.width / width
            }
            self.scrollView.setZoomScale(scale, animated: false)
        }
    }

    func setMiniScale() {
        self.lastCenter = nil
        self.lastOrigin = nil
        self.lastContentOffset = nil
        DispatchQueue.main.async {
            self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: false)
        }
    }

    func setToolBarPoint(point: CGPoint? = nil) {
        self.toolBarPoint = point
    }

    func setWhiteboardMenuDisplayStatus(to newStatus: Bool, isUpdate: Bool) {
        viewModel.dependencies?.setWhiteboardMenuDisplayStatus(to: newStatus, isUpdate: isUpdate)
    }

    func reConfigGesture(shouldReceive: Bool) {
        cleanGesture()
        if shouldReceive {
            let gesture = WhiteboardGestRecognizer()
            gesture.touchDelegate = self
            gesture.delegate = self
            self.addGestureRecognizer(gesture)
            self.gesture = gesture
        }
    }

    // MARK: private
    private func bindViewModel() {
        viewModel.configWbClientNotificationDelegate()
        configGesture()
    }

    private func cleanGesture() {
        if let gesture = self.gesture {
            gesture.delegate = nil
            gesture.touchDelegate = nil
            self.removeGestureRecognizer(gesture)
        }
        self.gesture = nil
    }

    private func configGesture() {
        self.gesture = WhiteboardGestRecognizer()
        gesture!.touchDelegate = self
        gesture!.delegate = self
        self.addGestureRecognizer(gesture!)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        self.doubleTapGestureRecognizer = doubleTap
    }

    private func setupUI() {
        addSubview(scrollView)
        scrollView.frame = self.bounds
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.backgroundColor = UIColor.red
        containerView.layer.addSublayer(viewModel.drawBoard.rootLayer)
        scrollView.addSubview(containerView)
        updateContainerView()
    }

    private func updateContainerView() {
        let canvasRate = canvasSize.height > 0 ? canvasSize.width / canvasSize.height : 1
        let scrollRate = bounds.height > 0 ? bounds.width / bounds.height : 1
        if canvasRate > scrollRate {
            containerView.bounds = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.height / canvasRate * scrollRate))
        } else {
            containerView.bounds = CGRect(origin: .zero, size: CGSize(width: bounds.width / scrollRate * canvasRate, height: bounds.height))

        }
        containerView.center = CGPoint(x: max(scrollView.bounds.width,
                                              containerView.bounds.width) * 0.5,
                                       y: max(scrollView.bounds.height,
                                              containerView.bounds.height) * 0.5)
    }

    private func updateTextScale() {
        guard zoomScale != 0 else {
            return
        }
        let transform = CGAffineTransform(scaleX: touchScaleX / zoomScale, y: touchScaleY / zoomScale)
        viewModel.drawBoard.textScale = transform
    }

    private func createEqualSize(_ size: CGSize, rootLayerSize: CGSize) -> CGSize {
        var equalSize: CGSize = .zero
        let isWidthLarger = rootLayerSize.width > rootLayerSize.height
        if isWidthLarger {
            equalSize.width = size.width
            equalSize.height = size.width * (rootLayerSize.height / rootLayerSize.width)
        } else {
            equalSize.height = size.height
            equalSize.width = size.height * (rootLayerSize.width / rootLayerSize.height)
        }
        return equalSize
    }

    private func updateTouchTransform(_ size: CGSize) {
        if size.width == 0 {
            self.touchScaleX = 0
        } else {
            self.touchScaleX = viewModel.drawBoard.rootLayer.bounds.width / size.width
        }
        if size.height == 0 {
            self.touchScaleY = 0
        } else {
            self.touchScaleY = viewModel.drawBoard.rootLayer.bounds.height / size.height
        }
        self.updateTextScale()
    }
}

// MARK: scroolViewDelegate
extension WhiteboardView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        containerView.center = CGPoint(x: max(scrollView.bounds.width,
                                              scrollView.contentSize.width) * 0.5,
                                       y: max(scrollView.bounds.height,
                                              scrollView.contentSize.height) * 0.5)
        zoomScale = scrollView.zoomScale
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        touchEventDelegate?.whiteboardViewIsZoomingOrDragging(isZoomingOrDragging: false)
        viewModel.dependencies?.setNeedChangeAlphaOfSuspensionComponent(isOpaque: true)
        lastCenter = containerView.center
        lastOrigin = containerView.frame.origin
        lastContentOffset = scrollView.contentOffset
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        touchEventDelegate?.whiteboardViewIsZoomingOrDragging(isZoomingOrDragging: true)
        viewModel.dependencies?.setNeedChangeAlphaOfSuspensionComponent(isOpaque: false)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        touchEventDelegate?.whiteboardViewIsZoomingOrDragging(isZoomingOrDragging: true)
        viewModel.dependencies?.setNeedChangeAlphaOfSuspensionComponent(isOpaque: false)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        touchEventDelegate?.whiteboardViewIsZoomingOrDragging(isZoomingOrDragging: false)
        viewModel.dependencies?.setNeedChangeAlphaOfSuspensionComponent(isOpaque: true)
        lastCenter = containerView.center
        lastOrigin = containerView.frame.origin
        lastContentOffset = scrollView.contentOffset
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        lastCenter = containerView.center
        lastOrigin = containerView.frame.origin
        lastContentOffset = scrollView.contentOffset
    }
}

// MARK: Touch Event
extension WhiteboardView: WhiteboardTouchDelegate {

    func whiteboardTouchLocation(touch: UITouch) -> CGPoint {
        let pos = touch.location(in: containerView)
        let boardPoint = CGPoint(x: (pos.x * touchScaleX).rounded(), y: (pos.y * touchScaleY).rounded())
        return boardPoint
    }

    func whiteboardTouchesBegan(location: CGPoint) {
        if self.window == nil {
            logger.error("SketchView is receiving touch events when not attatched to a window")
        }
        if posInsideSketch(pos: location) {
            viewModel.wbClient.handleTouchDown(x: location.wbPoint.x, y: location.wbPoint.y, id: 0)
            drawing = true
        }
        lastPointInBoard = location
    }

    func whiteboardTouchesMoved(locations: [CGPoint]) {
        locations.forEach(handlingTouch(_:))
    }

    func whiteboardTouchesEnded(location: CGPoint) {
        if let lastPointInBoard = lastPointInBoard,
            let clipedEndPoint = sketchRect.intersection(with: lastPointInBoard,
                                                         endPoint: location).1,
            drawing {
            viewModel.wbClient.handleTouchLifted(x: clipedEndPoint.wbPoint.x, y: clipedEndPoint.wbPoint.y, id: 0)
            drawing = false
        } else if drawing {
            viewModel.wbClient.handleTouchLifted(x: location.wbPoint.x, y: location.wbPoint.y, id: 0)
            drawing = false
        }
        lastPointInBoard = nil
    }

    func whiteboardTouchesCancelled() {
        if let lastPointInBoard = lastPointInBoard {
            viewModel.wbClient.handleTouchLifted(x: lastPointInBoard.wbPoint.x, y: lastPointInBoard.wbPoint.y, id: 0)
        }
    }

    private func handlingTouch(_ location: CGPoint) {
        guard let lastPointInBoard = lastPointInBoard else {
            return
        }
        var toolBarClipedPoints: (CGPoint?, CGPoint?) = (nil, nil)
        if Display.pad, toolBarRect != .zero {
            toolBarClipedPoints = self.toolBarRect.intersection(with: lastPointInBoard, endPoint: location)
        }
        let clipedPoints = self.sketchRect.intersection(with: lastPointInBoard,
                                                        endPoint: location)
        var clipedStartPoint: CGPoint?
        var clipedEndPoint: CGPoint?
        if let point = toolBarClipedPoints.1 {
            clipedStartPoint = point
        } else if let point = clipedPoints.0 {
            clipedStartPoint = point
        }
        if let point = toolBarClipedPoints.0 {
            clipedEndPoint = point
        } else if let point = clipedPoints.1 {
            clipedEndPoint = point
        }
        if let clipedStartPoint = clipedStartPoint, !drawing {
            drawing = true
            viewModel.wbClient.handleTouchDown(x: clipedStartPoint.wbPoint.x, y: clipedStartPoint.wbPoint.y, id: 0)
            self.lastPointInBoard = location
            return
        }
        if let clipedEndPoint = clipedEndPoint, drawing {
            viewModel.wbClient.handleTouchMoved(x: clipedEndPoint.wbPoint.x, y: clipedEndPoint.wbPoint.y, id: 0)
            viewModel.wbClient.handleTouchLifted(x: clipedEndPoint.wbPoint.x, y: clipedEndPoint.wbPoint.y, id: 0)
            drawing = false
            return
        }
        if posInsideSketch(pos: location), drawing {
            viewModel.wbClient.handleTouchMoved(x: location.wbPoint.x, y: location.wbPoint.y, id: 0)
        }
        self.lastPointInBoard = location
    }

    private func posInsideSketch(pos: CGPoint) -> Bool {
        sketchRect.contains(pos)
    }
}

extension WhiteboardView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}

// MARK: 配置SDK及回传配置到会议中
extension WhiteboardView {
    func setPenStroke(brush: BrushType) {
        viewModel.wbClient.setStrokeWidth(brush.brushValue)
        viewModel.dependencies?.didChangePenBrush(brush: brush)
    }

    func setPenColor(color: ColorType) {
        viewModel.wbClient.setColor(color)
        viewModel.dependencies?.didChangePenColor(color: color)
    }

    func setHightlighterStroke(brush: BrushType) {
        viewModel.wbClient.setStrokeWidth(brush.brushValue)
        viewModel.dependencies?.didChangeHighlighterBrush(brush: brush)
    }

    func setHightlighterColor(color: ColorType) {
        viewModel.wbClient.setColor(color)
        viewModel.dependencies?.didChangeHighlighterColor(color: color)
    }

    func setShapeType(shape: ActionToolType) {
        viewModel.wbClient.setTool(shape.wbTool)
        viewModel.dependencies?.didChangeShapeType(shape: shape)
    }

    func setShapeColor(color: ColorType) {
        viewModel.wbClient.setColor(color)
        viewModel.dependencies?.didChangeShapeColor(color: color)
    }

}

// MARK: 和SDK进行数据交互
extension WhiteboardView {

    var hasMultiBoards: Bool {
        viewModel.hasMultiBoards
    }

    func configDependencies(_ dependencies: Dependencies? = nil) {
        self.viewModel.configDependencies(dependencies)
    }

    func isSelfSharing() -> Bool {
        self.viewModel.isSelfSharing
    }

    func clearMine() {
        viewModel.wbClient.clearMine()
    }

    func clearAll() {
        viewModel.wbClient.clearAll()
    }

    func clearOthers() {
        viewModel.wbClient.clearOthers()
    }

    func saveCurrent() {
        viewModel.saveCurrentSnapshot { _ in }
    }

    func saveAll() {
        viewModel.saveAllSnapshot { _ in }
    }

    @available(iOS 13.0, *)
    func changeTheme(theme: UIUserInterfaceStyle? = nil) {
        viewModel.changeTheme(theme: theme)
    }

    /// client 实际的状态
    var currentTool: WbTool? {
        viewModel.wbClient.currentTool
    }

    func setTool(tool: WbTool) {
        viewModel.wbClient.setTool(tool)
        if Display.pad, tool != .Move {
            doubleTapGestureRecognizer?.isEnabled = false
        } else if Display.pad {
            doubleTapGestureRecognizer?.isEnabled = true
        }
    }

    func setStrokeWidth(_ width: UInt32) {
        viewModel.wbClient.setStrokeWidth(width)
    }

    func setFillColor(_ color: ColorType? = nil) {
        viewModel.wbClient.setFillColor(color)
    }

    func setColor(_ color: ColorType) {
        viewModel.wbClient.setColor(color)
    }

    func didTapRedo() {
        viewModel.wbClient.redo()
    }

    func didTapUndo() {
        viewModel.wbClient.undo()
    }

    func setWhiteboardViewDelegate(delegate: WhiteboardViewDelegate) {
        self.viewModel.delegate = delegate
    }

    func setWhiteboardDataDelegate(delegate: WhiteboardDataDelegate) {
        self.viewModel.dataDelegate = delegate
    }

    func getMultiPageInfo() {
        viewModel.getMultiPageInfo()
    }

    func getSnapshotItems() -> [WhiteboardSnapshotItem] {
        return viewModel.getSnapshotItems()
    }
}
