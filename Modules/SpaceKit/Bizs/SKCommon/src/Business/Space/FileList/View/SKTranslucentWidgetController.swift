//
//  SKTranslucentWidgetController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/8/30.
//


import SKUIKit
import UniverseDesignColor
import SKFoundation

// 此文件的改动请同步到 SKWidgetController(非毛玻璃版本) 上

open class SKTranslucentWidgetController: OverCurrentContextViewController, UIViewControllerTransitioningDelegate {

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
        // 毛玻璃效果上的所有 view 一般设为透明
        view.backgroundColor = .clear
        watermarkConfig.add(to: view)
        return view
    }()

    public lazy var backgroundView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let view = UIVisualEffectView(effect: blurEffect)
        view.contentView.backgroundColor = .clear
        view.clipsToBounds = true
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

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupVisibleViews()
        layoutVisibleView()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let path = UIBezierPath(roundedRect: backgroundView.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: 12, height: 12))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        backgroundView.layer.mask = mask
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.topSafeAreaHeight = self.view.safeAreaInsets.top
        self.bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: Notification.Name.Docs.modalViewControllerWillAppear, object: nil)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ///兜底逻辑：若此时WidgetViewController被包裹在LKNavigationController中，不会触发转场动画，需要手动触发动画。
        ///BTW：这种情况其实不应该继承WidgetVC去实现。todo：移除这块逻辑，转场由外面LKNavigationController负责。
        if !canUseTransition, !didExecutePresentTransition, !isPadShow {
            animatedView(isShow: true, animate: true, compltetion: nil)
        } else if !didExecutePresentTransition {
            handleTransitioningEnd()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
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
        backgroundView.contentView.addSubview(contentView)
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
    public func onDismissButtonClick() {
        guard self.navigationController == nil else {
            animatedView(isShow: false, animate: true, compltetion: nil)
            return
        }
        self.dismiss(animated: true, completion: nil)
    }

    public func animatedView(isShow: Bool, animate: Bool, compltetion: (() -> Void)?) {
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
