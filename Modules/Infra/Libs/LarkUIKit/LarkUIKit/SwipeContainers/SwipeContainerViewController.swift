//
//  SwipeContainerViewController.swift
//  LarkUIKit
//
//  Created by zc09v on 2017/6/14.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

extension UIViewController {
    public var swipContainerVC: SwipeContainerViewController? {
        var vc = self
        while vc.parent != nil {
            vc = vc.parent ?? UIViewController()
            if let swipContainerVC = vc as? SwipeContainerViewController {
                return swipContainerVC
            }
        }
        return nil
    }
}

public protocol SwipeContainerViewControllerDelegate: AnyObject {
    func startDrag()
    func dismissByDrag()
    func disablePanGestureViews() -> [UIView]
    func configSubviewOn(containerView: UIView)
}

extension SwipeContainerViewControllerDelegate {
    func startDrag() {}

    func dismissByDrag() {}

    func disablePanGestureViews() -> [UIView] {
        return []
    }

    func configSubviewOn(containerView: UIView) {}
}

open class SwipeContainerViewController: UIViewController {
    public weak var delegate: SwipeContainerViewControllerDelegate?
    /// 是否显示中间状态
    public var showMiddleState: Bool = false

    /// 手势关闭的范围取值（0.00底部 - 1.00顶部）（默认不传值是0.35）(在showMiddleState == false生效)
    public var gestureCloseRange: CGFloat?

    /// 拖动结束的时候响应速度
    public var useVelocity: Bool = false
    /// 在使用速度的时候的阻尼
    public var damp: CGFloat = 4

    fileprivate let baseAlpha: CGFloat = 0.3
    public var originY = UIApplication.shared.statusBarFrame.size.height
    fileprivate var subViewController: UIViewController
    fileprivate var outScrollView: UIScrollView?

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private let backgroundView: UIView = UIView()
    private var tapGesture: UITapGestureRecognizer?

    private var panGestureDisabled: Bool = false

    // 标记 subview 是否出现
    private var subVCDidAppear: Bool = false

    fileprivate lazy var containerView: ContainerView = {
        let view = ContainerView(
            frame: CGRect(
                x: 0,
                y: self.view.frame.height,
                width: self.view.frame.width,
                height: self.view.frame.height - self.originY
            )
        )
        return view
    }()

    public lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(ges:)))
        gesture.delegate = self
        return gesture
    }()

    public init(subViewController: UIViewController) {
        self.subViewController = subViewController
        super.init(nibName: nil, bundle: nil)
        self.addChild(subViewController)
        self.modalPresentationStyle = .overCurrentContext
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if let presentedVc = self.presentedViewController {
            if !presentedVc.isBeingDismissed {
                return presentedVc.preferredStatusBarStyle
            }
        }
        return .lightContent
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: 0.3, animations: {
            self.view.backgroundColor = UIColor(white: 0, alpha: self.baseAlpha)
            let height = self.view.frame.height - self.originY
            self.containerView.frame = CGRect(
                x: 0,
                y: self.originY + (self.showMiddleState ? height / 2 : 0),
                width: self.view.frame.width,
                height: height
            )
        }) { (_) in
            self.subVCDidAppear = true
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let height = self.view.bounds.height - self.originY

        /// 高度变化的时候, 重设高度
        if self.containerView.frame.height != height {
            var yPosition: CGFloat = 0
            if self.panGesture.state != .began &&
                self.panGesture.state != .changed {
                yPosition = self.originY + (self.containerView.frame.origin.y != self.originY ? height / 2 : 0)
            } else {
                /// 如果手势正在识别中，使用当前 frame y
                yPosition = self.containerView.frame.minY
            }
            self.containerView.frame = CGRect(
                x: 0,
                y: yPosition,
                width: self.view.bounds.width,
                height: height
            )
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard self.subVCDidAppear else { return }
        coordinator.animate(alongsideTransition: { (_) in
            let height = size.height - self.originY
            self.containerView.frame = CGRect(
                x: 0,
                y: self.originY + (self.containerView.frame.origin.y != self.originY ? height / 2 : 0),
                width: size.width,
                height: height
            )
        }, completion: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tapGesture = backgroundView.lu.addTapGestureRecognizer(action: #selector(handleTapGesture(ges:)), target: self)
        tapGesture?.isEnabled = false

        self.view.addSubview(containerView)
        containerView.addGestureRecognizer(panGesture)
        containerView.add(contentView: subViewController.view)
        self.delegate?.configSubviewOn(containerView: self.view)
    }

    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
    }

    public func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.frame.origin.y = self.view.frame.size.height
            self.view.backgroundColor = UIColor.clear
        }, completion: { (_) in
            self.dismiss(animated: false, completion: {
                completion?()
            })
        })
    }

    public func setHeight(height: CGFloat) {
        self.originY = self.view.frame.height - height
    }

    public func setTapSwitch(isEnable: Bool) {
        tapGesture?.isEnabled = isEnable
    }

    public func resetPosition() {
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.frame.origin.y = self.originY
            self.view.backgroundColor = UIColor(white: 0, alpha: self.baseAlpha)
        })
    }

    fileprivate func resetMiddlePosition() {
        let height = self.view.frame.height - self.originY
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.frame.origin.y = self.originY + (self.showMiddleState ? height / 2 : 0)
            self.view.backgroundColor = UIColor(white: 0, alpha: self.baseAlpha)
        })
    }

    private var panGestureBeginInScrollView: Bool = false
}

extension SwipeContainerViewController: UIGestureRecognizerDelegate {
    @objc
    func handlePanGesture(ges: UIPanGestureRecognizer) {
        defer {
            ges.setTranslation(CGPoint(x: 0, y: 0), in: self.view)
        }
        /// 手势开始是判断是否位于 disablePanGestureViews 中
        /// 如果为 true, 本次手势的生命周期内，不处理任何拖拽逻辑
        if case .began = ges.state {
            if let views = self.delegate?.disablePanGestureViews() {
                let locationPoint = ges.location(in: subViewController.view)
                for view in views {
                    if view.frame.contains(locationPoint) {
                        self.panGestureDisabled = true
                        return
                    }
                }
            }
            self.panGestureDisabled = false
        } else if panGestureDisabled {
            return
        }

        switch ges.state {
        case .began:
            self.handleGestureBegan(ges)
        case .changed:
            self.handleGestureChanged(ges)
        case .ended, .cancelled, .failed:
            self.handleGestureEnded(ges)
        default: break
        }
    }

    @objc
    func handleTapGesture(ges: UITapGestureRecognizer) {
        self.dismiss(completion: {
            self.delegate?.dismissByDrag()
        })
    }

    private func handleGestureBegan(_ ges: UIPanGestureRecognizer) {
        self.delegate?.startDrag()
        if let scrollView = outScrollView {
            let point = ges.location(in: scrollView)
            if scrollView.bounds.contains(point) {
                panGestureBeginInScrollView = true
            }
        }
    }

    private func handleGestureChanged(_ ges: UIPanGestureRecognizer) {
        let translation = ges.translation(in: self.view)
        if let scrollView = outScrollView, panGestureBeginInScrollView {
            if translation.y < 0 {
                if containerView.frame.minY > originY {
                    scrollView.contentOffset = CGPoint.zero
                    changeContainerViewFrame(byTranslation: translation)
                }
            } else if translation.y > 0 {
                if scrollView.contentOffset.y <= 0 {
                    scrollView.contentOffset = CGPoint.zero
                    changeContainerViewFrame(byTranslation: translation)
                }
            }
        } else {
            changeContainerViewFrame(byTranslation: translation)
        }
        let currentAlpha = (1 - containerView.frame.minY / self.view.frame.size.height) * baseAlpha
        self.view.backgroundColor = UIColor(white: 0, alpha: currentAlpha)
    }

    private func handleGestureEnded(_ ges: UIPanGestureRecognizer) {
        panGestureBeginInScrollView = false
        let velocity = ges.velocity(in: ges.view)
        let y = containerView.frame.origin.y + (self.useVelocity ? velocity.y / self.damp : 0)

        if self.showMiddleState {
            if y <= 0.25 * self.view.frame.size.height {
                self.resetPosition()
            } else if y <= 0.65 * self.view.frame.size.height {
                self.resetMiddlePosition()
            } else {
                self.dismiss(completion: {
                    self.delegate?.dismissByDrag()
                })
            }
        } else {
            let boundaryRange: CGFloat = self.gestureCloseRange ?? 0.35
            if y <= boundaryRange * self.view.frame.size.height {
                self.resetPosition()
            } else {
                self.dismiss(completion: {
                    self.delegate?.dismissByDrag()
                })
            }
        }
    }

    private func changeContainerViewFrame(byTranslation translation: CGPoint) {
        let newY = containerView.frame.minY + translation.y
        if newY >= originY {
            containerView.frame.origin = CGPoint(x: containerView.frame.origin.x, y: newY)
        } else {
            containerView.frame.origin = CGPoint(x: containerView.frame.origin.x, y: originY)
        }
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
            self.outScrollView = scrollView
            return true
        }
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        if #available(iOS 13.4, *) {
            // 由于手势冲突问题，关掉触控板的滑动响应
            // 详见：https://bytedance.feishu.cn/wiki/wikcnqnKvov5HkfppyRVCja63Ic#8c2zbB
            return event.buttonMask.rawValue == 0
        }
        return true
    }
}

private final class ContainerView: UIView {
    override var frame: CGRect {
        didSet {
            self.updateMaskLayer()
        }
    }

    let maskLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = true
        self.addMaskLayer()
    }

    func add(contentView: UIView) {
        self.addSubview(contentView)
        contentView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func addMaskLayer() {
        self.updateMaskLayer()
        self.layer.mask = maskLayer
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateMaskLayer() {
        // 取最大屏幕宽 避免转屏是黑边
        let maxScreenLength = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        let maskBounds = CGRect(x: 0, y: 0, width: self.bounds.width, height: maxScreenLength)
        if maskBounds == maskLayer.frame { return }
        let maskPath = UIBezierPath(
            roundedRect: maskBounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 9, height: 9)
        )
        maskLayer.frame = maskBounds
        maskLayer.path = maskPath.cgPath
    }
}
