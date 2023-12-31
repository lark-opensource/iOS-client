//
//  SuspendController.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/6.
//

import Foundation
import UIKit
import Homeric
import LKCommonsTracker
import LKWindowManager

protocol SuspendControllerDelegate: AnyObject {
    func suspendController(_ controller: SuspendController,
                           didSelectItem item: SuspendPatch)
    func suspendController(_ controller: SuspendController,
                           didDeleteItem item: SuspendPatch)
    func suspendControllerDidDeleteAllItems(_ controller: SuspendController)
    func suspendControllerDidHideDockList(_ controller: SuspendController)
}

public final class SuspendController: LKWindowRootController {

    weak var delegate: SuspendControllerDelegate?

    public override func loadView() {
        view = SuspendView()
    }

    private var watermarkView: UIView? {
        didSet {
            guard oldValue !== watermarkView else { return }
            oldValue?.removeFromSuperview()
            maskView?.removeFromSuperview()
            if let watermark = watermarkView {
                view.addSubview(watermark)
                watermark.isUserInteractionEnabled = false
                watermark.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                let maskView = UIView()
                maskView.frame = bubbleView.frame
                maskView.backgroundColor = .white
                watermark.mask = maskView
                self.maskView = maskView
            }
        }
    }

    private var maskView: UIView?

    private var didChangeBubbleViewFrame: Bool = false

    public lazy var bubbleView: SuspendBubbleView = {
        let view = SuspendBubbleView()
        view.frame = SuspendManager.getBubbleRect()
        view.alignment = .right
        return view
    }()

    private var customVCHolder: [String: UIViewController] = [:]

    init() {
        super.init(nibName: nil, bundle: nil)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupActionHandlers()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { _ in
            self.adjustBubblePosition(withAnimation: false)
        }
        super.viewWillTransition(to: size, with: coordinator)
    }

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        guard isViewLoaded else { return }
        if #available(iOS 13.0, *), newCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            return
        }
        coordinator.animate { _ in
            self.adjustBubblePosition(withAnimation: false)
        }
        super.willTransition(to: newCollection, with: coordinator)
    }

    private func setupSubviews() {
        view.addSubview(bubbleView)
    }

    private func setupActionHandlers() {
        // 悬浮窗拖拽事件
        let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(didDragBubbleView(_:))
        )
        bubbleView.addGestureRecognizer(panGesture)
        // 悬浮窗点击事件
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapBubbleView(_:))
        )
        bubbleView.bubbleContainer.addGestureRecognizer(tapGesture)
    }

    @objc
    private func didTapBubbleView(_ gesture: UITapGestureRecognizer) {
        // Dismiss keyboard
        topViewController()?.view.endEditing(true)
        // Show dock list
        showDockList(animated: true)
        // Analytics
        Tracker.post(TeaEvent(Homeric.TASKLIST_OPEN, params: [
            "view_num": SuspendManager.shared.count
        ]))
    }

    func reset() {
        didChangeBubbleViewFrame = false
    }

    func setBubblePositionIfNeeded(_ rect: CGRect) {
        guard didChangeBubbleViewFrame else { return }
        bubbleView.frame = rect
        maskView?.frame = rect
        adjustBubblePosition()
    }

    private var dockView: DockView?

    func showDockList(animated: Bool) {
        let dockView = DockView()
        if bubbleView.alignment == .left {
            dockView.direction = .left
        } else {
            dockView.direction = .right
        }
        dockView.delegate = self
        dockView.show(on: view, animated: animated)
        maskView?.frame = view.frame
        self.dockView = dockView
    }

    func hideDockList(animated: Bool, completion: (() -> Void)? = nil) {
        dockView?.dismiss(animated: animated, completion: completion)
    }

    // 记录手势拖动气泡起始的位置
    private var startPoint: CGPoint = .zero
    private var startCenter: CGPoint = .zero

    // 保存所有的受保护区域
    var protectedZones: [String: CGRect] = [:]

    // BubbleView 拖动时的初始位置是否被记录（解决横屏页面 bug）
    private var isStartPointRecorded = false

    @objc
    private func didDragBubbleView(_ gesture: UIPanGestureRecognizer) {
        guard let bubbleView = gesture.view else { return }
        let currentPoint = gesture.location(in: self.view)
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseInOut) {
                if bubbleView.frame.minX == 0 {
                    bubbleView.center.x += 10
                } else {
                    bubbleView.center.x -= 10
                }
                self.bubbleView.alignment = .center
            }
            if SuspendManager.shared.isBubbleRemovable {
                SuspendManager.shared.basketView.show()
            }
            // 在设备横屏时，偶现 currentPoint 坐标计算错误的问题，疑似是系统 bug，
            // 这里过滤掉有问题的数据，将第一个正确的数据作为起始位置。
            isStartPointRecorded = false
            if bubbleView.frame.contains(currentPoint) {
                startPoint = currentPoint
                startCenter = bubbleView.center
                isStartPointRecorded = true
            }
        case .changed:
            if !isStartPointRecorded {
                startPoint = currentPoint
                startCenter = bubbleView.center
                isStartPointRecorded = true
            }
            let moveX = currentPoint.x - startPoint.x
            let moveY = currentPoint.y - startPoint.y
            // Calculate new center
            let minCenterX = bubbleView.bounds.width / 2 + SuspendConfig.restrictedZone.left
            let maxCenterX = self.view.bounds.width - bubbleView.bounds.width / 2 - SuspendConfig.restrictedZone.right
            let centerX = (startCenter.x + moveX)
                .limit(between: minCenterX, and: maxCenterX)
            let minCenterY = bubbleView.bounds.height / 2 + SuspendConfig.restrictedZone.top
            let maxCenterY = self.view.bounds.height - bubbleView.bounds.height / 2 - SuspendConfig.restrictedZone.bottom
            let centerY = (startCenter.y + moveY)
                .limit(between: minCenterY, and: maxCenterY)
            bubbleView.center = CGPoint(x: centerX, y: centerY)
            maskView?.center = bubbleView.center
            if SuspendManager.shared.isBubbleRemovable {
                SuspendManager.shared.basketView.touchDidMove(toPoint: bubbleView.center)
            }
        default:
            if SuspendManager.shared.isBubbleRemovable &&
                SuspendManager.shared.basketView.isInsideBasket(point: bubbleView.center) {
                // 移除所有 suspendItem，目前暂不支持
                SuspendManager.shared.clearSuspendItems()
            } else {
                // 保证悬浮窗在安全范围之内，并贴边
                adjustBubblePosition()
            }
            if SuspendManager.shared.isBubbleRemovable {
                SuspendManager.shared.basketView.hide()
            }
        }
    }

    private func adjustBubblePosition(withAnimation animated: Bool = true) {
        let finalFrame = findFinalBubblePosition(start: bubbleView.frame)
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.bubbleView.frame = finalFrame
                self.maskView?.frame = finalFrame
                self.bubbleView.alignment = self.bubbleView.frame.minX == 0 ? .left : .right
            }, completion: { _ in
                SuspendManager.saveBubbleRect(rect: self.getBubbleFrame())
            })
        } else {
            self.bubbleView.frame = finalFrame
            self.maskView?.frame = finalFrame
            self.bubbleView.alignment = bubbleView.frame.minX == 0 ? .left : .right
            SuspendManager.saveBubbleRect(rect: self.getBubbleFrame())
        }

    }

    private func findFinalBubblePosition(start: CGRect) -> CGRect {
        let edgeRect = findAlignedBubblePosition(start: start)
        if checkPositionAvaibility(for: edgeRect) {
            return edgeRect
        } else {
            let candidates = getAllPossiblePosition(for: edgeRect)
            return findNearestValidPosition(from: candidates) ?? edgeRect
        }
    }

    /// 对 BubbleView 做贴边处理
    private func findAlignedBubblePosition(start: CGRect) -> CGRect {
        let screenSize = view.bounds
        let bubbleSize = start.size
        // 判断屏幕方向，bubbleView 躲避刘海
        let orientation = Utility.getCurrentInterfaceOrientation() ?? .portrait
        let bubbleInLeft = start.center.x < screenSize.width / 2
        // 调整 bubbleView 的 x 坐标，保证贴边, 且横屏时可以躲避刘海
        var endX: CGFloat = 0
    
        switch orientation {
        case .landscapeLeft:
            endX = 0
        case .landscapeRight:
            endX = screenSize.width - start.width
        default:
            endX = bubbleInLeft ? 0 : screenSize.width - start.width
        }
        
        // 调整 bubbleView 的 y 坐标，避开安全区域
        let endY = start.minY.limit(
            between: SuspendConfig.safeZone.top,
            and: screenSize.height - start.height - SuspendConfig.safeZone.bottom
        )
        return CGRect(origin: CGPoint(x: endX, y: endY), size: bubbleSize)
    }

    /// 获取所有可能的停靠位置
    private func getAllPossiblePosition(for rect: CGRect) -> [CGRect] {
        // 过滤掉另一侧的保护区
        let alignRect = CGRect(
            x: rect.minX == 0 ? 0 : view.bounds.width - rect.width,
            y: 0,
            width: rect.width,
            height: view.bounds.height
        )
        var candidates: [CGRect] = []
        // Align top and bottom of each protect zone
        for zone in protectedZones.values where zone.intersects(alignRect) {
            let top = CGRect(x: rect.minX, y: zone.minY - rect.height, width: rect.width, height: rect.height)
            let bottom = CGRect(x: rect.minX, y: zone.maxY, width: rect.width, height: rect.height)
            candidates.append(top)
            candidates.append(bottom)
        }
        return candidates.sorted(by: {
            abs($0.center.y - rect.center.y) < abs($1.center.y - rect.center.y)
        })
    }

    /// 检测停靠位置是否和保护区域冲突
    private func checkPositionAvaibility(for rect: CGRect) -> Bool {
        guard rect.minY >= SuspendConfig.safeZone.top,
              rect.maxY <= view.bounds.height - SuspendConfig.safeZone.bottom else {
            return false
        }
        return !protectedZones.values.contains { $0.intersects(rect) }
    }

    /// 获取最近的停靠位置
    private func findNearestValidPosition(from candidates: [CGRect]) -> CGRect? {
        for candidate in candidates where checkPositionAvaibility(for: candidate) {
            return candidate
        }
        return nil
    }

    /// 考虑到带 customView 情况 frame 会增大，此处要计算出原始气泡的位置
    private func getBubbleFrame() -> CGRect {
        let screenWidth = view.bounds.width
        let normalSize = SuspendConfig.bubbleSize
        let normalOrigin = CGPoint(
            x: bubbleView.alignment == .left ? 0 : screenWidth - normalSize.width,
            y: bubbleView.frame.maxY - normalSize.height
        )
        return CGRect(origin: normalOrigin, size: normalSize)
    }
}

// MARK: - 更新浮窗

extension SuspendController {

    func refresh(by items: [SuspendPatch], animated: Bool = true) {
        bubbleView.updateSuspendCount(items.count, animated: animated)
        // 添加项目之后，dockView 的高度会变化，也需要调整位置
        bubbleView.frame.size = bubbleView.bubbleSize
        didChangeBubbleViewFrame = true
        maskView?.frame = bubbleView.frame
        if !items.isEmpty {
            adjustBubblePosition()
        }
    }
}

// MARK: - 浮窗互斥

extension SuspendController {

    func addProtectedZone(_ rect: CGRect, forKey key: String) {
        // 添加保护区域时，直接为上下留出保护间距
        let newValue = rect.insetBy(
            dx: 0,
            dy: -SuspendConfig.protectedMargin
        )
        if let oldValue = protectedZones[key], oldValue == newValue {
            // value not changed, do nothing
        } else {
            protectedZones[key] = newValue
            adjustBubblePosition()
        }
    }

    func removeProtectedZone(forKey key: String) {
        protectedZones.removeValue(forKey: key)
    }
}

// MARK: - 多任务列表

extension SuspendController: DockViewDelegate {

    func dockView(_ view: DockView, didDeleteItem item: SuspendPatch) {
        self.delegate?.suspendController(self, didDeleteItem: item)
    }

    func dockView(_ view: DockView, didSelectItem item: SuspendPatch) {
        self.delegate?.suspendController(self, didSelectItem: item)
    }

    func dockViewDidDismiss(_ view: DockView) {
        self.bubbleView.alpha = 1
        self.dockView = nil
    }

    func dockViewDidClearItems(_ view: DockView) {
        self.delegate?.suspendControllerDidDeleteAllItems(self)
    }
}

// MARK: - 添加/删除自定义视图

extension SuspendController {

    /// 向悬浮窗上方添加自定义视图
    /// - Parameters:
    ///   - view: 自定义视图
    ///   - size: 自定义视图大小，用以调整悬浮窗的尺寸
    func addCustomView(_ view: UIView,
                       size: CGSize,
                       level: UInt8,
                       forKey key: String,
                       isBackgroundOpaque: Bool,
                       tapHandler: (() -> Void)? = nil) {
        let prevFrame = bubbleView.frame
        bubbleView.addCustomView(view,
                                 size: size,
                                 level: level,
                                 forKey: key,
                                 isBackgroundOpaque: isBackgroundOpaque,
                                 tapHandler: tapHandler)
        bubbleView.frame.size = bubbleView.bubbleSize
        didChangeBubbleViewFrame = true
        if prevFrame.size != .zero {
            bubbleView.frame.origin.y = prevFrame.minY - size.height - 8 * 2
        }
        adjustBubblePosition(withAnimation: true)
    }

    func addCustomViewController(_ viewController: UIViewController, forKey key: String) {
        if let previousCustomVC = customVCHolder[key] {
            previousCustomVC.willMove(toParent: nil)
            previousCustomVC.removeFromParent()
            previousCustomVC.beginAppearanceTransition(false, animated: false)
        }
        customVCHolder[key] = viewController
        if viewController.rootWindow() == nil {
            addChild(viewController)
            viewController.didMove(toParent: self)
            viewController.beginAppearanceTransition(true, animated: false)
        }
    }

    /// 移除悬浮窗上方的自定义视图
    /// - Returns: 被移除的自定义视图
    @discardableResult
    func removeCustomView(forKey key: String) -> UIView? {
        let prevFrame = bubbleView.frame
        let view = bubbleView.removeCustomView(forKey: key)
        bubbleView.frame.size = bubbleView.bubbleSize
        if !bubbleView.bubbleContainer.isHidden {
            bubbleView.frame.origin.y = prevFrame.minY + prevFrame.height - bubbleView.frame.height
        }
        adjustBubblePosition(withAnimation: true)
        return view
    }

    @discardableResult
    func removeCustomViewController(forKey key: String) -> UIViewController? {
        guard let viewController = customVCHolder[key] else {
            return nil
        }
        viewController.willMove(toParent: nil)
        viewController.removeFromParent()
        customVCHolder[key] = nil
        return viewController
    }
}

fileprivate extension CGFloat {

    func limit(between value1: CGFloat, and value2: CGFloat) -> CGFloat {
        let lowerBound = CGFloat.minimum(value1, value2)
        let upperBound = CGFloat.maximum(value1, value2)
        return CGFloat.minimum(CGFloat.maximum(self, lowerBound), upperBound)
    }
}

// MARK: - 添加/更新自定义水印

extension SuspendController {

    /// 添加/更新自定义水印
    func updateWatermark(_ view: UIView) {
        self.watermarkView = view
    }

    func removeWatermark() {
        self.watermarkView = nil
    }
}
