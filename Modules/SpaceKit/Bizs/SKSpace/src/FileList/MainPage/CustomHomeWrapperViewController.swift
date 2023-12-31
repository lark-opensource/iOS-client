//
//  WikiHomePageWrapperViewController.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/7/13.
//

import RxSwift
import RxCocoa
import SKUIKit
import SKFoundation
import SKCommon

public protocol CustomHomeWrappee where Self: UIViewController {
    // 提供导航栏能力
    var navigationBarItems: [SKBarButtonItem] { get }
    // 提供列表滚动的回调，对接滑动列表隐藏导航栏的逻辑
    var scrollView: UIScrollView? { get }
    // 提供列表shouldScrollToTop的回调
    var scrollViewShouldScrollToTop: Observable<Bool>? { get }
    // 提供创建按钮
    var createButton: UIButton? { get }
    // 提供公共埋点参数(module、sub_module 等)
    var commonTrackParams: [String: String] { get }
    /// 提供更新导航栏能力
    var trailingBarButtonItemsUpdate: Driver<[SKBarButtonItem]>? { get }
}

public extension CustomHomeWrappee {
    var createButton: UIButton? {
        return nil
    }
    
    var trailingBarButtonItemsUpdate: Driver<[SKBarButtonItem]>? {
        return nil
    }
}

public protocol TipsViewDependency {
    var tipsView: UIView { get }
    func viewHeight(with superWidth: CGFloat) -> CGFloat
}

public final class DefaultTipsViewImp: TipsViewDependency {
    public init() {}

    public var tipsView: UIView = NetInterruptTipView.defaultView()

    public func viewHeight(with superWidth: CGFloat) -> CGFloat {
        let size = CGSize(width: superWidth, height: .infinity)
        return tipsView.sizeThatFits(size).height
    }
}

// DocsTab 通用 Wrapper
// 提供导航栏相关通用底层逻辑
public final class CustomHomeWrapperViewController: DocsHomeBaseViewController {
    override var navTitle: String {
        return customTitle
    }

    private let childViewController: CustomHomeWrappee
    private let customTitle: String
    private let tipsViewDependency: TipsViewDependency
    private let bag = DisposeBag()

    private lazy var networkBannerView: UIView = {
        return tipsViewDependency.tipsView
    }()

    private var bannerHeight: CGFloat {
        DocsNetStateMonitor.shared.isReachable ?
            0 :
            tipsViewDependency.viewHeight(with: self.view.bounds.width)
    }
    // create button 在disable后点击事件会透传下去，因此添加在这个view上防止透传
    private var createButtonBackgroudView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // 给外部设置navibar高度的机会，如果没有设置使用默认实现
    public var naviBarSizeType: SKNavigationBar.SizeType?
    private let keyboard = Keyboard()
    private let disposeBag = DisposeBag()

    public override var commonTrackParams: [String: String] {
        return childViewController.commonTrackParams
    }

    public init(wrappee: CustomHomeWrappee,
                title: String,
                tipsViewDependency: TipsViewDependency = DefaultTipsViewImp()) {
        self.childViewController = wrappee
        self.customTitle = title
        self.tipsViewDependency = tipsViewDependency
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupChildVC(childViewController)
        setupBottomRightCreateButton()
        setupDefaultRightNavigationBarItems()
        setupScrollEvent()
        setupNetworkBanner()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.updateBannerView()
        self.childViewController.scrollView?.setContentOffset(CGPoint(x: 0, y: -(self.navigationBar.intrinsicHeight + self.bannerHeight)), animated: false)
    }

    private func setupChildVC(_ viewController: UIViewController) {
        addChild(viewController)
        viewController.beginAppearanceTransition(true, animated: false)
        view.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        viewController.didMove(toParent: self)
        viewController.endAppearanceTransition()
    }

    // MARK: - setup navibar
    private func setupDefaultRightNavigationBarItems() {
        // space demo
        navigationBar.title = navTitle
        if let sizeType = self.naviBarSizeType {
            navigationBar.sizeType = sizeType
        }
        navigationBar.trailingBarButtonItems = childViewController.navigationBarItems

        animator.navBar = navigationBar
        animator.delegate = self
        animator.forceShow(animated: true)
        animator.navigationBarChanged = {[weak self] isHidden in
            guard let self = self else { return }
            if isHidden {
                UIView.animate(withDuration: 0.25) {
                    self.childViewController.scrollView?.contentInset.top = 0 + self.bannerHeight
                    self.networkBannerView.snp.updateConstraints { (make) in
                        make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                    }
                    self.view.layoutIfNeeded()
                }
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.childViewController.scrollView?.contentInset.top = self.navigationBar.intrinsicHeight + self.bannerHeight
                    self.networkBannerView.snp.updateConstraints { (make) in
                        make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(self.navigationBar.intrinsicHeight)
                    }
                    self.view.layoutIfNeeded()
                }
            }
        }
        
        // 监听配置 trailingBarButtonItems 的更新
        childViewController.trailingBarButtonItemsUpdate?.drive(onNext: { [weak self] items in
            self?.navigationBar.trailingBarButtonItems = items
        }).disposed(by: bag)
    }

    private func setupBottomRightCreateButton() {
        guard let createButton = self.childViewController.createButton else {
            DocsLogger.info("do not have create button")
            return
        }
        view.addSubview(createButtonBackgroudView)
        createButtonBackgroudView.addSubview(createButton)
        createButtonBackgroudView.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.width.height.equalTo(48)
        }
        createButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(48)
        }
        createButton.layer.cornerRadius = 24
        setupKeyboardMonitor()
    }

    private func setupScrollEvent() {
        enum State: Int {
            case began
            case changed
            case ended
        }
        guard let scrollView = self.childViewController.scrollView else {
            return
        }
        scrollView.contentInset.top = navigationBar.intrinsicHeight
        let beganScroll = scrollView.rx.willBeginDragging.map({ State.began })
        let didScroll = scrollView.rx.didScroll.map({ State.changed })
        let endedScroll = scrollView.rx.didEndDragging.map({ _ in State.ended })
        Observable
            .merge(beganScroll, didScroll, endedScroll)
            .map({ ($0, scrollView) })
            .scan((0, 0, .began), accumulator: {[weak self] (result, arg1) -> (CGFloat, CGFloat, State) in
                guard let self = self else { return (0, 0, .began) }
                // diff the old value and new value
                let (state, scrollView) = arg1
                let newY = scrollView.panGestureRecognizer.translation(in: self.view).y

                if state == .began {
                    return (0, 0, .began)
                } else {
                    return (result.1, newY, state)
                }
            })
            .subscribe(onNext: {[weak self] (oldY, newY, state) in
                guard let self = self else { return }
                let transY = newY - oldY
                switch state {
                case .began: break
                case .changed:
                    self.animator.update(by: transY, animated: true, statusBarInherentHeight: self.safeArea.top)
                case .ended: self.animator.autoAdjust(animated: true, statusBarInherentHeight: self.safeArea.top)
                }
            }).disposed(by: bag)

        childViewController
            .scrollViewShouldScrollToTop?
            .subscribe(onNext: {[weak self] shouldScrollToTop in
                guard let self = self, shouldScrollToTop else { return }
                self.animator.forceShow(animated: false, completion: {
                    scrollView.setContentOffset(CGPoint(x: 0, y: -self.navigationBar.intrinsicHeight), animated: true)
                })
            }).disposed(by: bag)
    }

    private func setupNetworkBanner() {
        view.addSubview(networkBannerView)
        self.networkBannerView.isHidden = DocsNetStateMonitor.shared.isReachable
        networkBannerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(navigationBar.intrinsicHeight)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        DocsNetStateMonitor.shared.addObserver(self) {[weak self] (_, isReachable) in
            guard let self = self else { return }
            self.networkBannerView.isHidden = isReachable
            self.updateBannerView()
            if !isReachable,
               var currentOffset = self.childViewController.scrollView?.contentOffset {
                currentOffset.y -= self.bannerHeight
                self.childViewController.scrollView?.contentOffset = currentOffset
            }
        }
    }

    private func updateBannerView() {
        let bannerTopOffset: CGFloat = animator.isNavigationBarHide ? 0 : navigationBar.intrinsicHeight
        self.childViewController.scrollView?.contentInset.top = bannerTopOffset + bannerHeight
        self.networkBannerView.snp.updateConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(bannerTopOffset)
            make.height.equalTo(bannerHeight)
        }
    }
}

extension CustomHomeWrapperViewController: DocsHomeAnimatorDelegate {
    public func canHiddenNavBar(_ animator: DocsHomeAnimator) -> Bool {
        if let scrollView = childViewController.scrollView {
            return scrollView.contentOffset.y >= 0
        } else {
            return false
        }
    }

    // switchBar 应该从 DocsHomeAnimator 解耦出来
    public func canPinSwitchTab(_ animator: DocsHomeAnimator) -> Bool {
        return false
    }

    public func switchBarMinY(_ animator: DocsHomeAnimator) -> CGFloat {
        return 0
    }

    public func floatSwitchTab(_ animator: DocsHomeAnimator) -> Bool {
        return true
    }

    public func pinSwitchTab(_ animator: DocsHomeAnimator) -> Bool {
        return true
    }
}

private extension CustomHomeWrapperViewController {
    func setupKeyboardMonitor() {
        guard SKDisplay.pad else { return }
        keyboard.on(event: .willShow) { [weak self] opt in
            self?.updateCreateButtonIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didShow) { [weak self] opt in
            self?.updateCreateButtonIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .willHide) { [weak self] opt in
            self?.resetCreateButton(animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didHide) { [weak self] _ in
            self?.resetCreateButton(animationDuration: nil)
        }
        keyboard.start()
    }

    private func updateCreateButtonIfNeed(keyboardFrame: CGRect, animationDuration: Double?) {
        guard childViewController.createButton != nil else { return }
        let safeAreaViewFrame = view.safeAreaLayoutGuide.layoutFrame
        let buttonX = safeAreaViewFrame.maxX - 16 - 48
        let buttonY = safeAreaViewFrame.maxY - 16 - 48
        let originButtonFrame = CGRect(x: buttonX, y: buttonY, width: 48, height: 48)
        let buttonFrameOnWindow = view.convert(originButtonFrame, to: nil)
        let accessoryViewHeight = UIResponder.sk.currentFirstResponder?.inputAccessoryView?.frame.height ?? 0
        let keyboardMinY = keyboardFrame.minY - accessoryViewHeight
        if buttonFrameOnWindow.intersects(keyboardFrame), keyboardMinY > buttonFrameOnWindow.minY {
            // 仅当键盘与创建按钮有交集，且键盘高度不足以完全遮挡创建按钮时，抬高创建按钮的高度
            let inset = buttonFrameOnWindow.maxY - keyboardFrame.origin.y - accessoryViewHeight + 16
            let realInset = max(inset, 16)
            createButtonBackgroudView.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(realInset)
            }
        } else {
            createButtonBackgroudView.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            }
        }
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }
    }

    func resetCreateButton(animationDuration: Double?) {
        guard childViewController.createButton != nil else { return }
        createButtonBackgroudView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }
}
