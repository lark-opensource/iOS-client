//
//  PadController.swift
//  demodemo
//
//  Created by Zigeng on 2023/2/2.
//

import Foundation
import UIKit
import FigmaKit

final class LarkSheetMenuPadController: LarkSheetMenuController, UIPopoverPresentationControllerDelegate {
    override var style: LarkSheetMenuStyle {
        return .padPopover
    }

    lazy var arrow: UIView = {
        let arrow = Arrow()
        self.view.addSubview(arrow)
        return arrow
    }()

    private var expandFlag = false
    override var reactionOffsetYThreshold: CGFloat? { nil }
    override init(vm: LarkSheetMenuViewModel, source: LarkSheetMenuSourceInfo, layout: LarkSheetMenuLayout) {
        super.init(vm: vm, source: source, layout: layout)
        self.interface = self
        self.preferredContentSize = CGSize(width: 200, height: 400)
    }
    public override func viewDidLoad() {
        self.view.addSubview(menuView)
        menuView.layer.cornerRadius = 10
        self.hidePopover(animated: false, completion: nil)
        super.viewDidLoad()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showPopover()
        menuDelegate?.menuDidAppear(self)
    }

    override func updateMenuHeight(_ toHeight: CGFloat? = nil) {
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: PadPopover UI Layout
extension LarkSheetMenuPadController {

    /// 计算菜单Popover指向的实际目标Rect
    private func caculateTargetRect() -> CGRect {
        // 箭头指向的目标优先为指定的内容区域, 若无指定则箭头指向目标为消息整体
        let targetView = source.contentView ?? source.sourceView
        let targetRect = self.view.convert(targetView.frame, from: targetView.superview).insetBy(dx: -4, dy: -4)
        // 箭头指向需要根据容器大小进行调整
        let containerRect = self.view.frame
        /// 原fromRect可以完整放下,直接返回fromRect
        if targetRect.maxY < self.view.frame.maxY, targetRect.minY > self.view.frame.minY {
            return targetRect
        /// 原fromRect上下均超出,根据containerRect调整height
        } else if targetRect.maxY > containerRect.maxY, targetRect.minY < containerRect.minY {
            return CGRect(x: targetRect.minX, y: containerRect.minY, width: targetRect.width, height: containerRect.height)
        /// fromRect下边界超出
        } else if targetRect.maxY > containerRect.maxY {
            return CGRect(x: targetRect.minX, y: targetRect.minY, width: targetRect.width, height: containerRect.maxY - targetRect.minY)
        }
        /// fromRect上边界超出
        else if targetRect.minY < containerRect.minY {
            return CGRect(x: targetRect.minX, y: containerRect.minY, width: targetRect.width, height: targetRect.maxY - containerRect.minY)
        }
        return containerRect
    }

    // 用于计算计算ipad弹窗的位置偏移
    private static func caculateFrameInfo(popoverMaxSize: CGSize,
                                          popoverCurrentSize: CGSize,
                                          popoverArrowSize: CGSize,
                                          popoverSafePadding: CGFloat,
                                          targetRect: CGRect,
                                          superView: UIView,
                                          fallbackRecalulateFlag: Bool = false) -> (CGRect, UIPopoverArrowDirection, CGFloat) {
        var resRect: CGRect
        let direction: UIPopoverArrowDirection
        var arrowOffset: CGFloat = 0
        // 1. 箭头位于目标View中间,箭头朝上
        if targetRect.maxY + popoverMaxSize.height + popoverArrowSize.width < superView.frame.maxY - popoverSafePadding {
            let point = CGPoint(x: targetRect.midX - popoverCurrentSize.width / 2,
                                y: targetRect.maxY + popoverArrowSize.width)
            resRect = CGRect(origin: point, size: popoverCurrentSize)
            arrowOffset = resRect.adjustOffsetX(superView: superView, menuRect: resRect, safePadding: popoverSafePadding)
            direction = .up
        // 2. 箭头位于目标View中间,箭头朝下
        } else if targetRect.minY - popoverMaxSize.height - popoverArrowSize.width > popoverSafePadding {
            let point = CGPoint(x: targetRect.midX - popoverCurrentSize.width / 2,
                                y: targetRect.minY - popoverArrowSize.width - popoverCurrentSize.height)
            resRect = CGRect(origin: point, size: popoverCurrentSize)
            arrowOffset = resRect.adjustOffsetX(superView: superView, menuRect: resRect, safePadding: popoverSafePadding)
            direction = .down
        // 3. 箭头位于目标View中间,箭头朝左
        } else if targetRect.maxX + popoverMaxSize.width + popoverArrowSize.width < superView.frame.maxX - popoverSafePadding {
            let point = CGPoint(x: targetRect.maxX + popoverArrowSize.width,
                                y: targetRect.midY - popoverCurrentSize.height / 2 - popoverArrowSize.height / 2)
            resRect = CGRect(origin: point, size: popoverCurrentSize)
            arrowOffset = resRect.adjustOffsetY(superView: superView, menuRect: resRect, safePadding: popoverSafePadding)
            direction = .left
        // 4. 箭头位于目标View中间,箭头朝右
        } else if targetRect.minX - popoverMaxSize.width - popoverArrowSize.width > popoverSafePadding {
            let point = CGPoint(x: targetRect.minX - popoverCurrentSize.width - popoverArrowSize.width,
                                y: targetRect.midY - popoverCurrentSize.height / 2 - popoverArrowSize.height / 2)
            resRect = CGRect(origin: point, size: popoverCurrentSize)
            arrowOffset = resRect.adjustOffsetY(superView: superView, menuRect: resRect, safePadding: popoverSafePadding)
            direction = .right
        // 5.兜底逻辑处理badcase, fallbackRecalulateFlag为true且菜单当前高度与菜单可展开最大高度不一致时, 需要递归重新计算位置
        // 重新计算位置时, 不考虑popoverMaxSize, 使用popoverCurrentSize作为假定展开最大大小来规避badcase
        } else if fallbackRecalulateFlag && popoverCurrentSize.height != popoverMaxSize.height {
            (resRect, direction, arrowOffset) = Self.caculateFrameInfo(popoverMaxSize: popoverCurrentSize,
                                                                       popoverCurrentSize: popoverCurrentSize,
                                                                       popoverArrowSize: popoverArrowSize,
                                                                       popoverSafePadding: popoverSafePadding,
                                                                       targetRect: targetRect,
                                                                       superView: superView,
                                                                       fallbackRecalulateFlag: false)
        // 6.所有情况都无法放下菜单时,走最终兜底逻辑,菜单位于屏幕下方安全区内
        } else {
            let point = CGPoint(x: targetRect.midX - popoverCurrentSize.width / 2,
                                y: superView.frame.maxY - popoverCurrentSize.height - popoverArrowSize.height - popoverSafePadding)
            resRect = CGRect(origin: point, size: popoverCurrentSize)
            arrowOffset = resRect.adjustOffsetX(superView: superView, menuRect: resRect, safePadding: popoverSafePadding)
            direction = .up
        }
        return (resRect, direction, arrowOffset)
    }

    /// 根据当前状态计算ipad弹窗的位置偏移
    private func caculateFrameInfo(needExpand: Bool, toHeight: CGFloat) -> (CGRect, UIPopoverArrowDirection, CGFloat) {
        /// 为简化后续的弹窗大小变化的动画效果, 计算ipad弹窗位置时使用popover可以达到的最大大小计算.
        let hasHeader = {
            switch viewModel.header {
            case .invisible: return false
            default: return true
            }
        }()
        let layoutMaxSize = layout.popoverSize(self.view.traitCollection, containerSize: self.view.frame.size)
        let popoverMaxSize = CGSize(width: layoutMaxSize.width, height: hasHeader ? layoutMaxSize.height : toHeight)
        let popoverCurrentSize = needExpand ? popoverMaxSize : CGSize(width: popoverMaxSize.width, height: min(popoverMaxSize.height, toHeight))
        return Self.caculateFrameInfo(popoverMaxSize: popoverMaxSize,
                                      popoverCurrentSize: popoverCurrentSize,
                                      popoverArrowSize: layout.popoverArrowSize,
                                      popoverSafePadding: layout.popoverSafePadding,
                                      targetRect: self.caculateTargetRect(),
                                      superView: self.view,
                                      fallbackRecalulateFlag: true)
    }

    private func setPopoverFrame(toHeight adjustedContentHeght: CGFloat? = nil) {
        let contentHeight = adjustedContentHeght ?? self.menuView.contentHeight + 10
        let info = self.caculateFrameInfo(needExpand: expandFlag, toHeight: contentHeight)
        menuView.frame = info.0
        menuView.possisionPoint = info.0.origin
        self.updateArrowIfNeeded(direction: info.1, offset: info.2)
        self.view.layoutIfNeeded()
    }

    private func showPopover() {
        self.menuView.reloadData()
        setPopoverFrame()
        // 第一层页面无功能按钮时直接跳转至MoreView
        if self.viewModel.dataSource.flatMap { $0.sectionItems }.isEmpty && !self.isInMoreMode {
            self.isInMoreMode = true
            expandFlag = true
            self.setPopoverFrame()
            self.menuView.switchView(to: .more, animated: false)
        }
        self.menuView.alpha = 1
        self.arrow.alpha = 1
        self.arrow.setNeedsDisplay()
    }
    private func hidePopover(animated: Bool = true, completion: ((Bool) -> Void)?) {
        if animated {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                self.menuView.alpha = 0
                self.arrow.alpha = 0
                UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                    self.menuDelegate?.suggestVerticalOffset(self, offset: .end)
                })
            }) { finished in
                completion?(finished)
            }
        } else {
            self.menuView.alpha = 0
            self.arrow.alpha = 0
            completion?(true)
        }
    }
}

// MARK: LarkSheetMenuController Public Interface
extension LarkSheetMenuPadController: LarkSheetMenuInterface {
    func updateMenuWith(_ data: [LarkSheetMenuActionSection]?, willShowInPartial: Bool?) {
        if let data = data {
            self.viewModel.dataSource = data
        }
        if let isInPartial = willShowInPartial {
            self.isInPartial = isInPartial
        }
    }

    public var triggerView: UIView {
        return source.sourceView
    }

    // 是否可以把触摸传递到下一层视图
    public var enableTransmitTouch: Bool {
        get { return self._enableTransmitTouch }
        set { self._enableTransmitTouch = newValue }
    }

    // 下层是否直接响应手势 如果返回 true 则 menuVC 不会响应 hittest
    // 优先级高于 handleTouchView
    public var handleTouchArea: ((CGPoint, UIViewController) -> Bool)? {
        get { return self._handleTouchArea }
        set { self._handleTouchArea = newValue }
    }

    // 返回响应 hitTest 的 view
    public var handleTouchView: ((CGPoint, UIViewController) -> UIView?)? {
        get { return self._handleTouchView }
        set { self._handleTouchView = newValue }
    }

    public func show(in vc: UIViewController) {
        guard let gestureTargetView = vc.view else { return }
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
        self.fatherView = vc.view
        dismissOthers(in: vc)
        self.addDismissTap(view: gestureTargetView)
        vc.present(self, animated: false)
    }

    public func showMenu(animated: Bool = true) {
        if isInPartial {
            showPartial()
        } else {
            showPopover()
        }
    }

    public func hide(animated: Bool = true,
                     completion: ((Bool) -> Void)?) {
        if isInPartial {
            self.hidePartialView(completion: completion)
        } else {
            self.hidePopover(animated: animated, completion: completion)
        }
    }

    public func switchToMoreView() {
        guard !isInMoreMode else { return }
        self.isInMoreMode = true
        self.expandFlag = true
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut], animations: { [weak self] in
            self?.setPopoverFrame()
        })
        self.menuView.switchView(to: .more, animated: true)
    }

    public func dismiss(completion: (() -> Void)? = nil) {
        if hadDismiss { return }
        hadDismiss = true
        menuDelegate?.menuWillDismiss(self)
        self.hide(animated: true) { _ in
            self.dismissAfterAnimation(completion: completion)
        }
    }
}

final class Arrow: UIView {
    /// UX提供的自定义弧度的popover小箭头svg数据
    static var arrowPathDataString: String {
        "M12.9981 47C12.9981 45.2875 13.0066 43.5755 12.988 41.863C12.97 40.224 12.9445 38.3896 12.343 36.7945C11.6929 35.0716 10.5563 33.9309 9.2186 32.7832C8.25648 31.957 6.20374 30.334 5.21262 29.5437C4.40002 28.8969 2.79383 27.6308 2.01674 26.9395C1.03912 26.0692 -9.61932e-07 24.9936 -1.02724e-06 23.4995C-1.09255e-06 22.0054 1.03912 20.9303 2.01574 20.0605C2.79233 19.3692 4.39952 18.1031 5.21162 17.4558C6.20274 16.6665 8.25548 15.0435 9.2176 14.2168C10.5553 13.0671 11.6919 11.9284 12.342 10.206C12.942 8.61043 12.969 6.77548 12.987 5.13747C13.0055 3.42448 12.997 1.71249 12.997 1.28928e-10"
    }
    var arrowSize: CGSize { CGSize(width: 13, height: 47) }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.addSubview(blurView)
        blurView.frame = self.frame
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private lazy var blurView = {
        let blurView = BackgroundBlurView()
        blurView.fillColor = .ud.N100.withAlphaComponent(0.95)
        blurView.fillOpacity = 0.95
        blurView.blurRadius = 50
        return blurView
    }()
    override func draw(_ rect: CGRect) {
        let trianglePath = UIBezierPath(svgPath: Self.arrowPathDataString)
        let triangleLayer = CAShapeLayer()
        triangleLayer.path = trianglePath.cgPath
        blurView.layer.mask = triangleLayer
    }
}

extension UIBezierPath {
    convenience init(svgPath: String) {
        self.init()
        let scanner = Scanner(string: svgPath)
        var currentPoint = CGPoint.zero

        while !scanner.isAtEnd {
            var command: NSString?
            scanner.scanCharacters(from: .letters, into: &command)

            if let command = command {
                switch command {
                case "M":
                    var x: Double = 0
                    var y: Double = 0
                    scanner.scanDouble(&x)
                    scanner.scanDouble(&y)
                    currentPoint = CGPoint(x: x, y: y)
                    self.move(to: currentPoint)
                case "C":
                    var x1: Double = 0, y1: Double = 0, x2: Double = 0, y2: Double = 0, x: Double = 0, y: Double = 0
                    scanner.scanDouble(&x1)
                    scanner.scanDouble(&y1)
                    scanner.scanDouble(&x2)
                    scanner.scanDouble(&y2)
                    scanner.scanDouble(&x)
                    scanner.scanDouble(&y)
                    let controlPoint1 = CGPoint(x: x1, y: y1)
                    let controlPoint2 = CGPoint(x: x2, y: y2)
                    currentPoint = CGPoint(x: x, y: y)
                    self.addCurve(to: currentPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
                default:
                    assertionFailure("Unhandled command: \(command)")
                }
            }
        }
    }
}

extension LarkSheetMenuPadController {
    func updateArrowIfNeeded(direction: UIPopoverArrowDirection,
                                      offset: CGFloat) {
        arrow.isHidden = false
        let size: CGSize
        let pointX: CGFloat
        let pointY: CGFloat
        let angle: CGFloat
        switch direction {
        case .up:
            size = CGSize(width: 47, height: 13)
            pointX = self.menuView.frame.width / 2 - size.width / 2 + offset
            pointY = -size.height
            angle = .pi / 2
        case .down:
            size = CGSize(width: 47, height: 13)
            pointX = self.menuView.frame.width / 2 - size.width / 2 + offset
            pointY = self.menuView.frame.height
            angle = -.pi / 2
        case .left:
            size = CGSize(width: 13, height: 47)
            pointX = -size.width
            pointY = self.menuView.frame.height / 2 + offset
            angle = 0
        case .right:
            size = CGSize(width: 13, height: 47)
            pointX = self.menuView.frame.width
            pointY = self.menuView.frame.height / 2 + offset
            angle = .pi
        default:
            return
        }

        arrow.transform = CGAffineTransform(rotationAngle: angle)
        let targetPoint = self.menuView.convert(CGPoint(x: pointX, y: pointY), to: self.view)
        arrow.frame = CGRect(origin: targetPoint, size: size)
    }
}

extension CGRect {
    mutating func adjustOffsetX(superView: UIView, menuRect: CGRect, safePadding: CGFloat) -> CGFloat {
        let offset: CGFloat
        let arrowOffsetPadding: CGFloat = 20
        // 箭头偏移量始终不能超出菜单
        let maxOffsetAbs = menuRect.width / 2 - arrowOffsetPadding
        if self.minX < safePadding {
            let menuOffset = safePadding - self.minX
            self = self.offsetBy(dx: menuOffset, dy: 0)
            offset = min(menuOffset, maxOffsetAbs)
        } else if superView.frame.width - self.maxX < safePadding {
            let menuOffset = superView.frame.width - safePadding - self.maxX
            self = self.offsetBy(dx: menuOffset, dy: 0)
            offset = max(menuOffset, -maxOffsetAbs)
        } else {
            offset = 0
        }
        return -offset
    }

    mutating func adjustOffsetY(superView: UIView, menuRect: CGRect, safePadding: CGFloat) -> CGFloat {
        let offset: CGFloat
        let arrowOffsetPadding: CGFloat = 20
        // 箭头偏移量始终不能超出菜单
        let maxOffsetAbs = menuRect.height / 2 - arrowOffsetPadding
        if self.minY < safePadding {
            offset = min(safePadding - self.minY, maxOffsetAbs)
            self = self.offsetBy(dx: 0, dy: offset)
        } else if superView.frame.height - self.maxY < safePadding {
            offset = max(superView.frame.height - safePadding - self.maxY, -maxOffsetAbs)
            self = self.offsetBy(dx: 0, dy: offset)
        } else {
            offset = 0
        }
        return -offset
    }
}
