//
//  UDActionPanel.swift
//  UniverseDesignActionPanel
//
//  Created by 姚启灏 on 2020/10/29.
//

import Foundation
import UIKit

/// UDActionPanel UI Config
public struct UDActionPanelUIConfig {

    /// UDActionPanel originY
    public var originY: CGFloat

    /// Whether to show the intermediate state
    public var showMiddleState: Bool

    /// Response speed at the end of the drag
    public var useVelocity: Bool

    /// Damping when using speed
    public var damp: CGFloat

    /// ContainerView backgroundColor
    public var backgroundColor: UIColor?

    /// ContainerView can be dragged
    public var canBeDragged: Bool

    /// ContainerView show icon
    public var showIcon: Bool

    /// Start drag callback
    public var startDrag: (() -> Void)?

    /// Dismiss callback
    public var dismissByDrag: (() -> Void)?

    /// Non-dragable area
    public var disablePanGestureViews: (() -> [UIView])?

    /// init
    /// - Parameters:
    ///   - originY:
    ///   - useVelocity:
    ///   - damp:
    ///   - showMiddleState:
    ///   - canBeDragged:
    ///   - backgroundColor:
    ///   - startDrag:
    ///   - dismissByDrag:
    ///   - disablePanGestureViews:
    public init(originY: CGFloat = UIScreen.main.bounds.height * 0.4,
                useVelocity: Bool = false,
                damp: CGFloat = 4,
                showMiddleState: Bool = false,
                canBeDragged: Bool = true,
                showIcon: Bool = false,
                backgroundColor: UIColor? = UDActionPanelColorTheme.acPrimaryBgNormalColor,
                startDrag: (() -> Void)? = nil,
                dismissByDrag: (() -> Void)? = nil,
                disablePanGestureViews: (() -> [UIView])? = nil) {
        self.originY = originY
        self.useVelocity = useVelocity
        self.damp = damp
        self.showMiddleState = showMiddleState
        self.backgroundColor = backgroundColor
        self.canBeDragged = canBeDragged
        self.showIcon = showIcon
        self.startDrag = startDrag
        self.dismissByDrag = dismissByDrag
        self.disablePanGestureViews = disablePanGestureViews
    }
}

open class UDActionPanel: UIViewController {
    private let config: UDActionPanelUIConfig

    private let transition = UDActionPanelTransition()

    private var panGestureDisabled: Bool = false

    private let customViewController: UIViewController

    private var customView: UIView {
        return customViewController.view
    }

    private var outScrollView: UIScrollView?

    private lazy var containerView: UDActionPanelContainerView = {
        let height = self.view.frame.height - self.config.originY
        let view = UDActionPanelContainerView(
            frame: CGRect(
                x: 0,
                y: self.config.originY + (self.config.showMiddleState ? height / 2 : 0),
                width: self.view.frame.width,
                height: height
            )
        )
        return view
    }()

    private var tapGesture: UITapGestureRecognizer?

    private var isAlert: Bool {
        var traitCollection = self.traitCollection
        if let trait = self.view.superview?.traitCollection {
            traitCollection = trait
        }
        if let window = presentingViewController?.view.window {
            return window.traitCollection.horizontalSizeClass == .regular
        } else {
            return UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular
        }
    }

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(ges:)))
        gesture.delegate = self
        return gesture
    }()

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if let presentedVc = self.presentedViewController {
            if !presentedVc.isBeingDismissed {
                return presentedVc.preferredStatusBarStyle
            }
        }
        return .lightContent
    }
    
    @available(iOS 13.0, *)
    open override var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        didSet {
            self.transition.dimmingView.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
        }
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    /// init
    /// - Parameters:
    ///   - customViewController: Content Custom ViewController
    ///   - config: UI Config
    public init(customViewController: UIViewController, config: UDActionPanelUIConfig) {
        self.customViewController = customViewController
        self.config = config

        super.init(nibName: nil, bundle: nil)

        self.addChild(customViewController)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transition
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateSubView()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.addTapGesture()
        self.view.addSubview(containerView)
        containerView.addGestureRecognizer(panGesture)
        containerView.add(contentView: customView, showIcon: config.showIcon)

        containerView.backgroundColor = config.backgroundColor
        panGesture.isEnabled = config.canBeDragged
    }

    /// Reset container view position
    open func resetPosition() {
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.frame.origin.y = self.config.originY
        })
    }

    /// Reset container view position
    open func resetMiddlePosition() {
        let height = self.view.frame.height - self.config.originY
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.frame.origin.y = self.config.originY + (self.config.showMiddleState ? height / 2 : 0)
        })
    }

    open override func viewWillLayoutSubviews() {
         super.viewWillLayoutSubviews()

        updateSubView()
    }

    private func updateSubView() {
        if isAlert {
            self.containerView.frame = self.view.bounds
            self.panGesture.isEnabled = false
            self.containerView.showIcon = false
        } else {
            let height = self.view.frame.height - self.config.originY
            containerView.frame = CGRect(
                x: 0,
                y: self.config.originY + (self.config.showMiddleState ? height / 2 : 0),
                width: self.view.frame.width,
                height: height
            )
            self.panGesture.isEnabled = true
            self.containerView.showIcon = config.showIcon
        }
    }
}

extension UDActionPanel {
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] (_) in
            guard let `self` = self else { return }
            self.updateSubView()
        }, completion: nil)
    }
}

extension UDActionPanel {
    /// Set whether the tap gesture can be triggered
    /// - Parameter isEnable: isEnable
    open func setTapSwitch(isEnable: Bool) {
        tapGesture?.isEnabled = isEnable
    }

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.isEnabled = true
        self.tapGesture = tapGesture
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc
    private func handleTapGesture(_ sender: UITapGestureRecognizer) {
        if !self.containerView.frame.contains(sender.location(in: self.view)) {
            self.dismiss(animated: true) {
                self.config.dismissByDrag?()
            }
        }
    }
}

extension UDActionPanel: UIGestureRecognizerDelegate {

    @objc
    func handlePanGesture(ges: UIPanGestureRecognizer) {
        defer {
            ges.setTranslation(CGPoint(x: 0, y: 0), in: self.view)
        }
        /// 手势开始是判断是否位于 disablePanGestureViews 中
        /// 如果为 true, 本次手势的生命周期内，不处理任何拖拽逻辑
        if case .began = ges.state {
            if let views = self.config.disablePanGestureViews?(), !views.isEmpty {
                let locationPoint = ges.location(in: customView)
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

    private func handleGestureBegan(_ ges: UIPanGestureRecognizer) {
        config.startDrag?()
    }

    private func handleGestureChanged(_ ges: UIPanGestureRecognizer) {
        let translation = ges.translation(in: self.view)
        changeContainerViewFrame(byTranslation: translation)
    }

    private func handleGestureEnded(_ ges: UIPanGestureRecognizer) {
        let velocity = ges.velocity(in: ges.view)
        let lastY = containerView.frame.origin.y + (self.config.useVelocity ? velocity.y / self.config.damp : 0)

        let height = self.view.frame.height - self.config.originY

        if self.config.canBeDragged {
            if lastY <= self.config.originY {
                self.resetPosition()
            } else if lastY <= (self.config.originY + (self.config.showMiddleState ? height / 2 : 0)) {
                self.resetMiddlePosition()
            } else {
                self.dismiss(animated: true) {
                    self.config.dismissByDrag?()
                }
            }
        } else {
            if lastY <= 0.35 * self.view.frame.size.height {
                self.resetPosition()
            } else {
                self.dismiss(animated: true) {
                    self.config.dismissByDrag?()
                }
            }
        }
    }

    private func changeContainerViewFrame(byTranslation translation: CGPoint) {
        let newY = containerView.frame.minY + translation.y
        if newY >= config.originY {
            containerView.frame.origin = CGPoint(x: containerView.frame.origin.x, y: newY)
        } else {
            containerView.frame.origin = CGPoint(x: containerView.frame.origin.x, y: config.originY)
        }
    }
}
