//
//  SKWidgetViewController.swift
//  SpaceKit
//
//  Created by Ryan on 2019/2/17.
//
/*!
   负责转场动画的相关逻辑
   modalPresentationStyle默认是.overCurrentContext，是否展示动画通过系统presentAPI的参数animated决定（移除needAnimated参数）
   其他modalPresentationStyle需自己设置，对popover以及formSheet这两个modalPresentationStyle进行特殊处理交付系统处理。
   保留了旧逻辑，提供给WidgetViewController被包裹在LKNavigationController的情况去使用。
 */

// 此文件的改动请同步到 SKTranslucentWidgetController(毛玻璃版本) 上

import SKUIKit
import UniverseDesignColor
import SKFoundation

open class SKWidgetViewController: OverCurrentContextViewController, UIViewControllerTransitioningDelegate {

    public var contentHeight: CGFloat
    public var bottomSafeAreaHeight: CGFloat = 0
    public var topSafeAreaHeight: CGFloat = 0

    /// 是否执行了present转场动画
    private var didExecutePresentTransition = false
    private let animateDuration: Double = 0.3

    /// 当前是否在iPad全屏模式下
    private var isPadShow: Bool {
        return SKDisplay.pad && self.isMyWindowRegularSize()
    }

    private var canUseTransition: Bool {
        return self.navigationController == nil
    }

    public let watermarkConfig = WatermarkViewConfig()
    public lazy var contentView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        if isInPoperover {
            view.backgroundColor = UDColor.bgFloat
        } else {
            view.backgroundColor = UDColor.bgBody
        }
        watermarkConfig.add(to: view)
        return view
    }()

    // 不要在 bgView 上直接增加 subview，而是加在 contentView 上，避免迁移到毛玻璃上时出现异常
    public lazy var backgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        if isInPoperover {
            view.backgroundColor = UDColor.bgFloat
        } else {
            view.backgroundColor = UDColor.bgBody
        }
        return view
    }()

    public lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UDColor.bgMask
        button.addTarget(self, action: #selector(onDismissButtonClick), for: .touchUpInside)
        button.alpha = 0
        return button
    }()

    public init(contentHeight: CGFloat) {
        self.contentHeight = contentHeight
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
    }

    /// Only apply to update animation contentHeight
    public func resetHeight(_ height: CGFloat) {
        self.contentHeight = height
        contentView.snp.remakeConstraints { (make) in
            make.left.right.top.equalTo(self.backgroundView.safeAreaLayoutGuide)
            make.height.equalTo(contentHeight)
        }
        backgroundView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(0)
            make.height.equalTo(contentHeight + bottomSafeAreaHeight)
        }
    }
    
    public func resetHeightIgnoreBottomSafeArea(_ height: CGFloat) {
        self.contentHeight = height
        contentView.snp.remakeConstraints { (make) in
            make.left.right.top.equalTo(self.backgroundView)
            make.height.equalTo(contentHeight)
        }
        backgroundView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(0)
            make.height.equalTo(contentHeight)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupVisibleViews()
        layoutVisibleView()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let path = UIBezierPath(roundedRect: backgroundView.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: 12, height: 12))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        backgroundView.layer.mask = mask
    }

    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.topSafeAreaHeight = self.view.safeAreaInsets.top
        self.bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: Notification.Name.Docs.modalViewControllerWillAppear, object: nil)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ///兜底逻辑：若此时WidgetViewController被包裹在LKNavigationController中，不会触发转场动画，需要手动触发动画。
        ///BTW：这种情况其实不应该继承WidgetVC去实现。todo：移除这块逻辑，转场由外面LKNavigationController负责。
        if !canUseTransition, !didExecutePresentTransition, !isPadShow {
            animatedView(isShow: true, animate: true, compltetion: nil)
        } else if !didExecutePresentTransition {
            handleTransitioningEnd()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name.Docs.modalViewControllerWillDismiss, object: nil)
    }

    private func handleTransitioningEnd() {
        self.dismissButton.alpha = 1
        didExecutePresentTransition = true
    }

    private func setupVisibleViews() {
        if !(SKDisplay.pad && modalPresentationStyle == .popover || modalPresentationStyle == .formSheet) {
            view.addSubview(dismissButton)
        }
        view.addSubview(backgroundView)
        backgroundView.addSubview(contentView)
    }

    private func layoutVisibleView() {
        if !(SKDisplay.pad && (modalPresentationStyle == .popover || modalPresentationStyle == .formSheet)) {
            dismissButton.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        backgroundView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(contentHeight + bottomSafeAreaHeight)
            make.bottom.equalTo(0)
        }

        contentView.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(self.backgroundView.safeAreaLayoutGuide)
            make.height.equalTo(contentHeight)
        }
    }

    @objc
    open func onDismissButtonClick() {
        guard self.navigationController == nil else {
            animatedView(isShow: false, animate: true, compltetion: nil)
            return
        }
        self.dismiss(animated: true, completion: nil)
    }

    open func animatedView(isShow: Bool, animate: Bool, compltetion: (() -> Void)?) {
        guard isShow == false || didExecutePresentTransition == false else {
            spaceAssertionFailure("展示过程中不能执行显示动画")
            return
        }
        guard self.navigationController == nil else {
            _animation(isShow: isShow, animate: animate, completion: compltetion)
            return
        }
        self.dismiss(animated: true, completion: compltetion)
    }

    private func _animation(isShow: Bool, animate: Bool, completion: (() -> Void)?) {
        let completeCallback: (Bool) -> Void = { (finish: Bool) in
            if isShow {
                self.didExecutePresentTransition = true
                completion?()
            } else {
                self.dismiss(animated: false) {
                    completion?()
                }
            }
        }

        guard animate == true else {
            completeCallback(false)
            return
        }

        if isShow {
            backgroundView.snp.updateConstraints { (make) in
                make.bottom.equalTo(contentHeight + bottomSafeAreaHeight)
            }
            self.view.layoutIfNeeded()
        }

        let alpha: CGFloat = isShow ? 1 : 0
        let bottom = isShow ? 0 : contentHeight + bottomSafeAreaHeight
        backgroundView.snp.updateConstraints { (make) in
            make.bottom.equalTo(bottom)
        }
        UIView.animate(withDuration: animate ? 0.3 : 0, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5, options: [], animations: {
            self.dismissButton.alpha = alpha
            self.view.layoutIfNeeded()
        }, completion: completeCallback)
    }
// MARK: UIViewControllerTransitioningDelegate
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.modalPresentationStyle == .formSheet {
           // 当modalPresentationStyle为formSheet，转场动画交由系统负责
            return nil
        }
        return WidgetBrowserPresentTransitioning(animateDuration: self.animateDuration,
                                                 willPresent: { [weak self] in
                                                    guard let self = self else { return }
                                                    self.didExecutePresentTransition = true },
                                                 animation: nil,
                                                 completion: { [weak self] in
                                                    guard let self = self else { return }
                                                    self.handleTransitioningEnd()
        })
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.modalPresentationStyle == .formSheet {
           // 当modalPresentationStyle为formSheet，转场动画交由系统负责
            return nil
        }
        return WidgetBrowserDismissTransitioning(animateDuration: self.animateDuration,
                                                 willPresent: nil,
                                                 animation: nil,
                                                 completion: nil)
    }
}
