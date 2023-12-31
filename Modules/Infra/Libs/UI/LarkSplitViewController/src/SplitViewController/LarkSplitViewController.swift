//
//  SplitViewController.swift
//  SplitViewControllerDemo
//
//  Created by Yaoguoguo on 2022/8/15.
//

import AnimatedTabBar
import Foundation
import UIKit
import SnapKit
import LKCommonsLogging
import LarkFeatureGating
import LarkStorage
import RxSwift

extension SplitViewController {
    public static let SecondaryControllerChange: NSNotification.Name = NSNotification.Name("SplitViewController.SecondaryControllerChangeName")

    public static let SupportSingleColumnChange: NSNotification.Name = NSNotification.Name("SplitViewController.SupportSingleColumnChange")

    public static var supportSingleColumn: Bool {
        get {
            return supportSingleColumnRect.value
        }
        set {
            supportSingleColumnRect.value = .init(newValue)
            NotificationCenter.default.post(name: SplitViewController.SupportSingleColumnChange, object: nil)
        }
    }

    private static var supportSingleColumnRect: KVConfig<Bool> = {
        return .init(
            key: supportSingleColumnKey,
            default: false,
            store: KVStores.udkv(space: .global, domain: Domain.biz.core.child("SplitViewController"))
        )
    }()

    private static var supportSingleColumnKey: String = "supportSingleColumnKey"
}

extension SplitViewController {

    public var topMost: UIViewController? {
        return rawTopMost
    }

    public func cleanSecondaryViewController() {
        if let defaultVC = self.defaultVCProvider?().wrapVC() {
            self.setViewController(defaultVC, for: .secondary)
        }
    }

    public func subscribe(_ proxy: SplitViewControllerProxy) {
        /// 添加代理方法
        if !proxies.contains(proxy) {
            proxies.add(proxy)
        }
    }

    public func setViewController(_ vc: UIViewController,
                                  for column: SplitViewController.Column,
                                  refresh: Bool = true) {
        Self.logger.info("Split: \(self), Set ViewController: \(vc) for: \(column)")
        if let oldVC = self.childrenVC[column] {
            oldVC.view.removeFromSuperview()
            oldVC.removeFromParent()
        }

        if !self.children.contains(vc) {
            addChild(vc)
        }

        self.childrenVC[column] = vc
        switch column {
        case .primary, .supplementary:
            self.sideWrapperView.clearContent()
            self.sideWrapperView.contentView.addSubview(vc.view)

            if let navi = vc as? UINavigationController {
                sideWrapperNavigation?.dismiss(animated: false)
                sideWrapperNavigation = nil
                self.sideWrapperNavigation = navi
                for vc in navi.viewControllers {
                    // 使用Primary是为了不影响之前的逻辑
                    vc.childrenIdentifier = .init(identifier: [.initial, .primary])
                    vc.childrenIdentifier.splitViewController = self
                    SplitViewController.markChildrenTag(vc)
                }
            }
        case .secondary:
            self.contentView.clearContent()
            self.contentView.contentView.addSubview(vc.view)
            if isCollapsed {
                self.splitCompactAndSecondaryViewController()
                self.lastSplitMode = .twoBesideSecondary
            }
            if splitMode == .sideOnly {
                self.splitMode = .twoBesideSecondary
            }

            secondaryNavigation?.dismiss(animated: false)
            secondaryNavigation = nil

            if let navi = vc as? UINavigationController {
                self.secondaryNavigation = navi
                for vc in navi.viewControllers {
                    vc.childrenIdentifier = .init(identifier: [.initial, .secondary])
                    vc.childrenIdentifier.splitViewController = self
                    SplitViewController.markChildrenTag(vc)
                }
            } else if let wrapType = self.defaultVCProvider?().wrap {
                vc.removeFromParent()
                vc.view.removeFromSuperview()
                let wrapVC = wrapType.init(rootViewController: vc)
                vc.childrenIdentifier = .init(identifier: [.initial, .secondary])
                vc.childrenIdentifier.splitViewController = self
                SplitViewController.markChildrenTag(vc)
                self.childrenVC[column] = wrapVC
                addChild(wrapVC)
                self.contentView.contentView.addSubview(wrapVC.view)

                self.secondaryNavigation = wrapVC
            }

            if isViewLoaded, isCollapsed {
                mergeCompactAndSecondary()
            }
            NotificationCenter.default.post(name: SplitViewController.SecondaryControllerChange, object: self)
        case .compact:
            if isCollapsed {
                self.splitCompactAndSecondaryViewController()
            }
            compactNavigation = nil

            if let navi = vc as? UINavigationController {
                self.compactNavigation = navi
            }

            if isViewLoaded, isCollapsed {
                mergeCompactAndSecondary()
            }
        }

        self.markChildrenIdentifier()

        if self.isDidLoad {
            self.updateShowView(refresh, size: self.view.frame.size)
        }
    }

    public func removeViewController(for column: SplitViewController.Column) {
        guard let vc = self.childrenVC[column] else {
            return
        }

        vc.removeFromParent()
        vc.view.removeFromSuperview()
        self.childrenVC.removeValue(forKey: column)

        switch column {
        case .compact:
            self.compactNavigation = nil
        case .secondary:
            self.secondaryNavigation = nil
        case .primary:
            if let navi = self.supplementaryViewController as? UINavigationController {
                self.sideWrapperNavigation = navi
            } else {
                self.sideWrapperNavigation = nil
            }
        case .supplementary:
            if let navi = self.primaryViewController as? UINavigationController {
                self.sideWrapperNavigation = navi
            } else {
                self.sideWrapperNavigation = nil
            }
        }

        if self.isDidLoad {
            self.updateShowView(true, size: self.view.frame.size)
        }
    }

    public func viewController(for column: SplitViewController.Column) -> UIViewController? {
        return self.childrenVC[column]
    }

    public func show(for column: SplitViewController.Column) {
        guard column != .compact, !isCollapsed, self.childrenVC[column] != nil else {
            return
        }
        var newSplitMode = splitMode

        switch column {
        case .secondary, .compact:
            return
        case .primary:
            guard self.splitMode.rawValue > 0 else {
                return
            }
            newSplitMode = .twoBesideSecondary
        case .supplementary:
            guard self.splitMode == .secondaryOnly else {
                return
            }
            newSplitMode = .oneBesideSecondary
        }

        updateBehaviorAndSplitMode(behavior: splitBehavior,
                                   splitMode: newSplitMode,
                                   animated: false)
    }

    public func hide(for column: SplitViewController.Column) {
        guard column != .compact, !isCollapsed, self.childrenVC[column] != nil else {
            return
        }
        var newSplitMode = splitMode

        let hasSupplementary = childrenVC[.supplementary] != nil

        switch column {
        case .secondary, .compact:
            return
        case .supplementary:
            newSplitMode = .secondaryOnly
        case .primary:
            switch splitMode {
            case .secondaryOnly, .sideOnly:
                return
            case .oneBesideSecondary, .oneOverSecondary:
                guard !hasSupplementary else {
                    return
                }
                newSplitMode = .secondaryOnly
            case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
                newSplitMode = hasSupplementary ? .oneBesideSecondary : .secondaryOnly
            }
        }

        updateBehaviorAndSplitMode(behavior: splitBehavior,
                                   splitMode: newSplitMode,
                                   animated: false)
    }

    public func splitLayoutNeedsUpdate(_ size: CGSize) {
        currentSize = size
        updateSubViewFrame(behavior: splitBehavior, splitMode: splitMode)
    }
}

open class SplitViewController: UIViewController {

    public weak var delegate: SplitViewControllerDelegate?

    static let logger = Logger.log(SplitViewController.self,
                                   category: "LarkSplitViewController.SplitViewControllerLog")

    public var preferredSplitBehavior: SplitViewController.SplitBehavior = .tile {
        didSet {
            Self.logger.info("SplitViewControllerLog/UI/preferredSplitBehavior: didSet: \(preferredSplitBehavior.rawValue)")
            self.updateBehaviorAndSplitMode(behavior: preferredSplitBehavior, splitMode: self.splitMode)
        }
    }

    public private(set) var splitMode: SplitMode = .oneBesideSecondary {
        didSet {
            Self.logger.info("SplitViewControllerLog/UI/splitMode: didSet: \(splitMode.rawValue)")
            if splitMode != .secondaryOnly {
                beforeSecondaryOnlySplitMode = splitMode
            }
        }
    }

    /// 为了适配全局按钮展开后能够回到之前状态
    public private(set) var beforeSecondaryOnlySplitMode: SplitMode = .oneBesideSecondary

    public private(set) var isCollapsed: Bool {
        get {
            return supportSingleColumnSetting ? _isCollapsed || Self.supportSingleColumn : _isCollapsed
        }
        set {
            _isCollapsed = newValue
        }
    }

    private var _isCollapsed: Bool = false {
        didSet {
            Self.logger.info("SplitViewControllerLog/UI/isCollapsed: didSet: \(isCollapsed)")
        }
    }

    public var isShowPanGestureView: Bool = true {
        didSet {
            self.panGestureView.isHidden = !isShowPanGestureView
        }
    }

    public var isShowSidePanGestureView: Bool = true {
        didSet {
            self.sidePanGestureView.isHidden = !isShowSidePanGestureView
        }
    }

    public var sideWrapperNavigation: UINavigationController?

    public var secondaryNavigation: UINavigationController?

    public var compactNavigation: UINavigationController?

    public var preferredPrimaryColumnWidth: CGFloat = 320 

    public var preferredSupplementaryColumnWidth: CGFloat = 320

    public var preferredSecondaryColumnWidth: CGFloat = 375 {
        didSet {
            if splitStyle == .secondaryFixed && isDidLoad {
                updateShowView(size: self.view.frame.size, updateSplitMode: false)
            }
        }
    }

    /// 是否支持 side（primary+supplementary）全屏展示，默认 false
    public var supportSideOnly: Bool = false

    /// 默认展示页
    public var defaultVCProvider: (() -> DefaultVCResult)?

    var childrenVC: [Column: UIViewController] = [:]

    private let supportSingleColumnSetting: Bool

    private var showViews: [UIUserInterfaceSizeClass: [UIView]] = [:]

    private var isDidLoad = false

    private let minContentWidth: CGFloat = 312
    
    private let disposeBag = DisposeBag()

    let presentSemaphore = DispatchSemaphore(value: 1)

    var isHorizontal: Bool {
        return UIScreen.main.bounds.height < UIScreen.main.bounds.width
    }

    var lastSplitMode: SplitViewController.SplitMode = .oneBesideSecondary

    /// 用于标记每次动画，避免连续动画导致布局错乱
    var transitionTag: UUID = UUID()

    var maskView: SplitMaskView = SplitMaskView()

    /// 拖拽的View
    var panGestureView: SplitPanView = {
        let panGestureView = SplitPanView()
        panGestureView.highlightLineShouldHidden = false
        return panGestureView
    }()

    /// 拖拽的View
    var sidePanGestureView: SplitPanView = {
        let sidePanGestureView = SplitPanView()
        sidePanGestureView.highlightLineShouldHidden = false
        sidePanGestureView.isRight = false
        return sidePanGestureView
    }()

    var contentView = SplitContentView()
    var sideWrapperView = SplitContentView()

    var currentSize: CGSize = .zero

    var proxies = NSHashTable<AnyObject>.weakObjects()

    /// 内部没有调用，不清楚外部是否会调用，目前先沿用逻辑
    var rawTopMost: UIViewController? {
        if isCollapsed {
            return self.viewController(for: .compact)
        }
        if self.splitMode == .sideOnly {
            return self.sideNavigationController
        }
        return self.viewController(for: .secondary)
    }

    var primaryWidth: CGFloat {
        return childrenVC[.primary] != nil ? self._primaryWidth : 0
    }

    private var _primaryWidth: CGFloat {
        let hasSupplementary = childrenVC[.supplementary] != nil
        if hasSupplementary {
            return preferredPrimaryColumnWidth
        }
        if splitMode == .sideOnly {
            return currentSize.width
        }
        if splitStyle == .secondaryFixed {
            return currentSize.width - preferredSecondaryColumnWidth
        }
        return preferredPrimaryColumnWidth
    }

    var supplementaryWidth: CGFloat {
        let hasSupplementary = childrenVC[.supplementary] != nil
        if !hasSupplementary {
            return 0
        }
        if splitStyle == .secondaryFixed, splitMode != .sideOnly {
            return currentSize.width - preferredPrimaryColumnWidth - preferredSecondaryColumnWidth
        }
        if splitMode == .sideOnly {
            return currentSize.width - preferredPrimaryColumnWidth
        }
        return self.preferredSupplementaryColumnWidth
    }

    var sideWrapperWidth: CGFloat {
        return self.splitMode == .sideOnly ? currentSize.width : primaryWidth + supplementaryWidth
    }

    var splitBehavior: SplitViewController.SplitBehavior = .tile

    /// 手势动画中，最新发起的动画的ID
    var panGestureAnimatedTag: UUID = UUID()
    /// 拖拽手势开始拖拽的位置，用于处理拖拽偏移误差
    var panStartLocationX: CGFloat = 0
    /// 拖拽起始的位置
    var panOriginLocationX: CGFloat = 0
    /// 拖拽起始的是否显示 Tabbar
    var panOriginTabbarShow: Bool?

    var panGestureViewMidX: CGFloat {
        return contentView.frame.origin.x - 16
    }

    var sidePanGestureViewMidX: CGFloat {
        return sideWrapperView.frame.origin.x + primaryWidth - 36
    }

    var panGesture: LarkSplitPanGestureRecognizer = {
        let ges = LarkSplitPanGestureRecognizer()
        if #available(iOS 13.4, *) {
            ges.allowedScrollTypesMask = [.continuous]
        }
        return ges
    }()

    var sidePanGesture: LarkSplitPanGestureRecognizer = {
        let ges = LarkSplitPanGestureRecognizer()
        if #available(iOS 13.4, *) {
            ges.allowedScrollTypesMask = [.continuous]
        }
        return ges
    }()

    /// 分屏样式，支持左侧固定宽度（sideFixed）、右侧固定宽度（secondaryFixed），默认 sideFixed
    public private(set) var splitStyle: SplitViewController.SplitStyle = .sideFixed

    public convenience init(splitStyle: SplitViewController.SplitStyle = .sideFixed,
                            supportSingleColumnSetting: Bool = false) {
        self.init(supportSingleColumnSetting: supportSingleColumnSetting)
        self.splitStyle = splitStyle
    }

    public init(supportSingleColumnSetting: Bool) {
        self.supportSingleColumnSetting = supportSingleColumnSetting
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !(panGestureView.dragging || sidePanGestureView.dragging) else { return }

        let realSize = calculateEdgeRealSize()

        if let tab = self.animatedTabBarController, !tab.showEdgeTabbar {
            if self.splitMode == .secondaryOnly {
                tab.setEdgeTabbar(show: false, from: self, animation: false)
            } else {
                tab.setEdgeTabbar(show: true, from: self,animation: false)
            }
        }

        let sizeGroup = self.calculateSubViewSize(realSize, behavior: self.splitBehavior, splitMode: splitMode)
        let originGroup = self.calculateSubViewOrigin(realSize, behavior: self.splitBehavior, splitMode: splitMode)

        if self.contentView.frame.size != sizeGroup.0 {
            self.contentView.frame.size = sizeGroup.0
        }

        if self.sideWrapperView.frame.size != sizeGroup.1 {
            self.sideWrapperView.frame.size = sizeGroup.1
        }

        self.childrenVC.forEach { (_, vc) in
            vc.view.layoutIfNeeded()
        }

        self.sideWrapperView.layoutIfNeeded()
        self.contentView.layoutIfNeeded()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        Self.logger.info("SplitViewControllerLog/Life/viewDidLoad")
        self.uiLog()

        if self.viewController(for: .secondary) == nil, !supportSideOnly, let defaultVC = self.defaultVCProvider?().wrapVC() {
            self.setViewController(defaultVC, for: .secondary)
        }
        isCollapsed = self.traitCollection.horizontalSizeClass == .compact
        panGesture.delegate = self
        sidePanGesture.delegate = self
        panGestureView.addGestureRecognizer(panGesture)
        sidePanGestureView.addGestureRecognizer(sidePanGesture)
        view.addSubview(panGestureView)
        view.addSubview(sidePanGestureView)
        panGesture.addTarget(self, action: #selector(handlePan(ges:)))
        sidePanGesture.addTarget(self, action: #selector(handlePan(ges:)))

        contentView.addSubview(maskView)

        panGestureView.isHidden = true
        sidePanGestureView.isHidden = true

        maskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        maskView.alpha = 0
        maskView.lu.addTapGestureRecognizer(action: #selector(tapMaskView), target: self, touchNumber: 1)

        isDidLoad = true

        // 监听 split 切换 detail 页面信号
        NotificationCenter.default.rx
            .notification(SplitViewController.SupportSingleColumnChange).subscribe(onNext: { [weak self] (_) in
                if self?.supportSingleColumnSetting ?? false {
                    if self?.isCollapsed ?? false {
                        self?.mergeCompactAndSecondary()
                    } else {
                        self?.splitCompactAndSecondaryViewController()
                    }

                    self?.updateShowView(true, size: self?.view.frame.size ?? .zero)
                    self?.markChildrenIdentifier()
                }
        }).disposed(by: disposeBag)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Self.logger.info("Split: \(self) SplitViewControllerLog/Life/viewWillAppear")
        self.childrenVC.values.forEach { vc in
            vc.beginAppearanceTransition(true, animated: animated)
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isCollapsed = self.traitCollection.horizontalSizeClass == .compact

        Self.logger.info("SplitViewControllerLog/Life/viewDidAppear")
        let isMax = self.rootWindow()?.frame.width ?? 0 >= EdgeTabBarLayoutStyle.maxViewWidth
        currentSize = self.view.frame.size

        if let tab = self.animatedTabBarController, tab.tabbarStyle == .edge, let edgeTab = tab.edgeTab {
            if !tab.showEdgeTabbar {
                currentSize.width -= edgeTab.tabbarWidth
            } else if isMax || edgeTab.tabbarLayoutStyle == .horizontal {
                let edgeWidth = isMax ? max(EdgeTabBarLayoutStyle.vertical.width,
                                            min(edgeTab.frame.width, EdgeTabBarLayoutStyle.horizontal.width)) : EdgeTabBarLayoutStyle.vertical.width
                currentSize.width += (edgeWidth - EdgeTabBarLayoutStyle.vertical.width)
            }
        }

        checkTile()
        updateShowView(true, size: self.view.frame.size)

        self.childrenVC.values.forEach { vc in
            vc.endAppearanceTransition()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        Self.logger.info("SplitViewControllerLog/Life/viewWillDisappear")
        self.childrenVC.values.forEach { vc in
            vc.beginAppearanceTransition(false, animated: animated)
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        Self.logger.info("SplitViewControllerLog/Life/viewDidDisappear")
        self.childrenVC.values.forEach { vc in
            vc.endAppearanceTransition()
        }
    }

    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        // 添加拖拽手势
        if let tab = parent as? AnimatedTabBarController {
            tab.updateEdgeTabGesture(pan: panGesture)
        }
    }

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        if (self.traitCollection.verticalSizeClass != newCollection.verticalSizeClass)
            || (self.traitCollection.horizontalSizeClass != newCollection.horizontalSizeClass) {
            isCollapsed = newCollection.horizontalSizeClass == .compact
        }
        super.willTransition(to: newCollection, with: coordinator)

        self.childrenVC.values.forEach { vc in
            vc.willTransition(to: newCollection, with: coordinator)
        }

        Self.logger.info("Split: \(self) SplitViewControllerLog/Life/willTransition")
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        Self.logger.info("Split: \(self) SplitViewControllerLog/Life/traitCollectionDidChange")

        isCollapsed = self.traitCollection.horizontalSizeClass == .compact

        self.childrenVC.values.forEach { vc in
            vc.traitCollectionDidChange(previousTraitCollection)
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        Self.logger.info("Split: \(self) SplitViewControllerLog/Life/viewWillTransition")

        self.uiLog()
        let transitionTag = UUID()
        self.transitionTag = transitionTag


        var edgeWidth: CGFloat = 0
        if let tab = self.animatedTabBarController, tab.tabbarStyle == .edge, let edgeTab = tab.edgeTab {
            edgeWidth = edgeTab.tabbarWidth
        }

        let isMax = size.width + edgeWidth >= EdgeTabBarLayoutStyle.maxViewWidth
        currentSize = size
        if let tab = self.animatedTabBarController, tab.tabbarStyle == .edge, let edgeTab = tab.edgeTab {
            if !tab.showEdgeTabbar {
                currentSize.width -= EdgeTabBarLayoutStyle.vertical.width
            } else if isMax || edgeTab.tabbarLayoutStyle == .horizontal {
                let edgeWidth = isMax ? max(EdgeTabBarLayoutStyle.vertical.width,
                                            min(edgeTab.frame.width, EdgeTabBarLayoutStyle.horizontal.width)) : edgeTab.tabbarWidth
                currentSize.width += (edgeWidth - EdgeTabBarLayoutStyle.vertical.width)
            }
        }

        if isCollapsed {
            self.mergeCompactAndSecondary()
        } else {
            self.splitCompactAndSecondaryViewController()
        }

        checkTile()

        updateShowView(false, size: size)
        markChildrenIdentifier()

        if isCollapsed {
            self.compactViewController?.viewWillTransition(to: size, with: coordinator)
            self.delegate?.splitViewControllerDidCollapse(self)
            for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                proxy.splitViewControllerDidCollapse(self)
            }
        } else {
            self.primaryViewController?.viewWillTransition(to: CGSize(width: primaryWidth, height: size.height), with: coordinator)
            self.supplementaryViewController?.viewWillTransition(to: CGSize(width: supplementaryWidth, height: size.height), with: coordinator)
            self.secondaryViewController?.viewWillTransition(to: contentView.frame.size, with: coordinator)

            self.delegate?.splitViewControllerDidExpand(self)
            for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                proxy.splitViewControllerDidExpand(self)
            }
        }
    }

    public override func size(forChildContentContainer container: UIContentContainer,
                              withParentContainerSize parentSize: CGSize) -> CGSize {
        if container === self.childrenVC[.secondary], !isCollapsed {
            let size = self.calculateSubViewSize(parentSize,
                                                 behavior: self.splitBehavior,
                                                 splitMode: splitMode).0
            return size
        }
        return parentSize
    }

    public override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        Self.logger.info("SplitViewControllerLog/api/showDetailViewController")
        self.setViewController(vc, for: .secondary, refresh: self.isCollapsed)
    }

    func getCompactVC() -> UIViewController? {
        var colum: Column = .compact
        if let newColum = delegate?.splitViewController(self,
                                                        topColumnForCollapsingToProposedTopColumn: .compact) {
            colum = newColum
        }

        var vc: UIViewController?
        if let columVC = self.childrenVC[colum] {
            vc = columVC
        } else if let secondaryVC = self.childrenVC[.secondary] {
            vc = secondaryVC
        } else if let primaryVC = self.childrenVC[.primary] {
            vc = primaryVC
        } else if let supplementaryVC = self.childrenVC[.supplementary] {
            vc = supplementaryVC
        }

        return vc
    }

    func markChildrenIdentifier() {
        SplitViewController.checkVCTag(split: self, navi: sideWrapperNavigation)
        SplitViewController.checkVCTag(split: self, navi: secondaryNavigation)
    }

    /// 检测当前 master/detail 是否在进行转场
    /// 如果在转场则返回 true
    func checkNavigationInTransition(completion: @escaping () -> Void) -> Bool {
        let transitionTag = self.transitionTag
        let coordinator = self.secondaryNavigation?.transitionCoordinator ?? self.sideWrapperNavigation?.transitionCoordinator
        if let coordinator = coordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
                /// Navgation 转场结束后仍然会调用一次 setViewControllerss
                /// 这里添加一次 async
                DispatchQueue.main.async {
                    if self?.transitionTag == transitionTag {
                        completion()
                    }
                }
            }
            return true
        }
        return false
    }

    @objc private func tapMaskView() {
        self.updateSplitMode(.oneBesideSecondary, animated: true)
    }

    private func checkTile() {
        guard self.view.frame.width > 0, self.view.frame.height > 0 else { return }
        let realSize = calculateEdgeRealSize()
        let contentSize = calculateSubViewSize(realSize, behavior: .tile, splitMode: .twoBesideSecondary).0
        if !isCollapsed, self.preferredSplitBehavior == .tile {
            if self.splitMode == .secondaryOnly {
                self.updateBehaviorAndSplitMode(behavior: contentSize.width <= minContentWidth ? .displace : .tile, splitMode: .secondaryOnly)
                return
            }
            if contentSize.width <= minContentWidth, self.splitMode != .sideOnly {
                self.updateBehaviorAndSplitMode(behavior: .displace, splitMode: .oneBesideSecondary)
            } else {
                self.updateBehaviorAndSplitMode(behavior: .tile,
                                                splitMode: isHorizontal ?  lastSplitMode : self.splitMode)
            }
        }
    }

    private func updateShowView(_ refresh: Bool = false, size: CGSize, updateSplitMode: Bool = true) {
        panGesture.isEnabled = !isCollapsed

        if isCollapsed {
            self.panGestureView.isHidden = true
            self.sidePanGestureView.isHidden = true

            self.delegate?.splitViewController(self, willShow: .compact)
            for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                proxy.splitViewController(self, willShow: .compact)
            }
            if self.showViews[.compact] == nil || refresh {
                self.showViews[.regular]?.forEach { view in
                    view.removeFromSuperview()
                }

                self.showViews.removeValue(forKey: .regular)

                if let view = self.getCompactVC()?.view {
                    self.view.addSubview(view)
                    self.showViews[.compact] = [view]
                } else {
                    self.showViews[.compact] = []
                }
            }
            self.showViews[.compact]?.first?.snp.remakeConstraints({ make in
                make.edges.equalToSuperview()
            })

            if let presentedViewController = self.compactNavigation?.presentedViewController,
               presentedViewController.childrenIdentifier.splitViewController == self,
               !presentedViewController.isBeingPresented {
                self.compactNavigation?.dismiss(animated: false, completion: {
                    self.compactNavigation?.present(presentedViewController, animated: false)
                })
            }
        } else {
            if self.showViews[.regular] == nil || refresh {

                self.childrenVC.forEach { (_, vc) in
                    vc.view.removeFromSuperview()
                    vc.view.snp.removeConstraints()
                }
                self.showViews.removeValue(forKey: .compact)
                let views = [contentView, sideWrapperView]
                views.forEach { view in
                    self.view.addSubview(view)
                }

                self.showViews[.regular] = views
            }

            if let secondary = self.childrenVC[.secondary]?.view {
                contentView.contentView.addSubview(secondary)
                secondary.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }

                panGestureView.isHidden = !isShowPanGestureView
                panGestureView.frame = CGRect(x: panGestureViewMidX, y: 0, width: 56, height: size.height)
            }

            var hasSupplementary = false
            var hasPrimary = false

            if let primary = self.childrenVC[.primary]?.view {
                sideWrapperView.contentView.addSubview(primary)

                hasPrimary = true

                primary.snp.remakeConstraints { make in
                    make.top.bottom.left.equalToSuperview()
                    make.right.lessThanOrEqualToSuperview()
                    make.width.greaterThanOrEqualTo(self.primaryWidth)
                }
            }

            if let supplementary = self.childrenVC[.supplementary]?.view {
                sideWrapperView.contentView.addSubview(supplementary)

                hasSupplementary = true

                supplementary.snp.remakeConstraints { make in
                    make.top.bottom.right.equalToSuperview()
                    make.width.equalTo(self.supplementaryWidth)
                    if let view = self.childrenVC[.primary]?.view {
                        make.left.equalTo(view.snp.right)
                    } else {
                        make.left.equalToSuperview()
                    }
                }
            }

            if hasSupplementary, hasPrimary {
                sidePanGestureView.isHidden = !isShowSidePanGestureView
                sidePanGestureView.frame = CGRect(x: sidePanGestureViewMidX, y: 0, width: 56, height: size.height)
            }

            if let presentedViewController = self.sideWrapperNavigation?.presentedViewController,
               presentedViewController.childrenIdentifier.splitViewController == self,
               !presentedViewController.isBeingPresented,
                presentedViewController.childrenIdentifier.contains(.primary) {
                self.sideWrapperNavigation?.dismiss(animated: false, completion: {
                    self.sideWrapperNavigation?.present(presentedViewController, animated: false)
                })
            }

            if let presentedViewController = self.secondaryNavigation?.presentedViewController,
                presentedViewController.childrenIdentifier.splitViewController == self,
               !presentedViewController.isBeingPresented,
                presentedViewController.childrenIdentifier.contains(.secondary) {
                self.secondaryNavigation?.dismiss(animated: false, completion: {
                    self.secondaryNavigation?.present(presentedViewController, animated: false)
                })
            }

            self.contentView.bringSubviewToFront(maskView)
            self.view.bringSubviewToFront(panGestureView)
            self.view.bringSubviewToFront(sidePanGestureView)

            if updateSplitMode {
                updateBehaviorAndSplitMode(behavior: self.splitBehavior, splitMode: self.splitMode, animated: false)
            }
        }
    }

    private func isDefaultDetailController(vc: UIViewController?) -> Bool {
        guard let vc = vc else { return false }
        if vc is UIViewController.DefaultDetailController {
            return true
        }
        if let nav = vc as? UINavigationController {
            if let controller = nav.topViewController {
                if controller is UIViewController.DefaultDetailController {
                    return true
                }
            }
        }
        return false
    }

    func updateBehaviorAndSplitMode(behavior: SplitViewController.SplitBehavior,
                                    splitMode: SplitViewController.SplitMode,
                                    animated: Bool = false) {
        Self.logger.info("SplitViewControllerLog/api/updateBehaviorAndSplitMode, behavior: \(behavior.rawValue), splitMode: \(splitMode.rawValue)")

        self.splitBehavior = behavior
        let hasprimary = childrenVC[.primary] != nil
        let hasSupplementary = childrenVC[.supplementary] != nil

        let oldSplitMode = self.splitMode
        var newSplitMode = splitMode
        let secondaryVC = self.viewController(for: .secondary)
        if supportSideOnly, (secondaryVC == nil || isDefaultDetailController(vc: secondaryVC)) {
            newSplitMode = .sideOnly
        }

        switch newSplitMode {
        case .sideOnly:
            if oldSplitMode != .sideOnly {
                self.mergeSideAndAndSecondary()
            }
            self.splitMode = .sideOnly
            switch oldSplitMode {
            case .sideOnly:
                break
            case .secondaryOnly:
                self.mergePresentedViewController()

                self.delegate?.splitViewController(self, willHide: .secondary)
                self.delegate?.splitViewController(self, willShow: .supplementary)
                self.delegate?.splitViewController(self, willShow: .primary)

                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willHide: .secondary)
                    proxy.splitViewController(self, willShow: .supplementary)
                    proxy.splitViewController(self, willShow: .primary)
                }
            case .oneBesideSecondary, .oneOverSecondary:
                self.delegate?.splitViewController(self, willHide: hasSupplementary ? .supplementary : .primary)
                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willHide: hasSupplementary ? .supplementary : .primary)
                }
            case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
                self.delegate?.splitViewController(self, willHide: .primary)
                self.delegate?.splitViewController(self, willHide: .supplementary)
                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willHide: .primary)
                    proxy.splitViewController(self, willHide: .supplementary)
                }
            }
        case .secondaryOnly:
            self.splitMode = .secondaryOnly
            switch oldSplitMode {
            case .sideOnly:
                self.splitSideAndSecondaryViewController()
                self.delegate?.splitViewController(self, willHide: .primary)
                self.delegate?.splitViewController(self, willHide: .supplementary)
                self.delegate?.splitViewController(self, willShow: .secondary)
                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willHide: .primary)
                    proxy.splitViewController(self, willHide: .supplementary)
                    proxy.splitViewController(self, willShow: .secondary)
                }
            case .secondaryOnly:
                break
            case .oneBesideSecondary, .oneOverSecondary:
                self.delegate?.splitViewController(self, willHide: hasSupplementary ? .supplementary : .primary)
                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willHide: hasSupplementary ? .supplementary : .primary)
                }
            case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
                self.delegate?.splitViewController(self, willHide: .primary)
                self.delegate?.splitViewController(self, willHide: .supplementary)
                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willHide: .primary)
                    proxy.splitViewController(self, willHide: .supplementary)
                }
            }
        case .oneBesideSecondary, .oneOverSecondary:
            if !(hasprimary || hasSupplementary) {
                self.splitMode = .secondaryOnly
                break
            }
            switch self.splitBehavior {
            case.tile, .displace:
                self.splitMode = .oneBesideSecondary
            case .overlay:
                self.splitMode = .oneOverSecondary
            }

            switch oldSplitMode {
            case .sideOnly:
                self.splitSideAndSecondaryViewController()
                self.delegate?.splitViewController(self, willShow: .secondary)
                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willShow: .secondary)
                }
            case .secondaryOnly:
                self.delegate?.splitViewController(self, willShow: hasSupplementary ? .supplementary : .primary)
                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willShow: hasSupplementary ? .supplementary : .primary)
                }
            case .oneBesideSecondary, .oneOverSecondary:
                break
            case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
                self.delegate?.splitViewController(self, willHide: .primary)
                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willHide: .primary)
                }
            }
        case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
            let hasSideWrapper = hasprimary && hasSupplementary

            switch self.splitBehavior {
            case.tile:
                if hasSideWrapper {
                    self.splitMode = .twoBesideSecondary
                } else {
                    self.splitMode = .oneBesideSecondary
                }
            case .displace:
                if hasSideWrapper {
                    self.splitMode = .twoDisplaceSecondary
                } else {
                    self.splitMode = .oneBesideSecondary
                }
            case .overlay:
                if hasSideWrapper {
                    self.splitMode = .twoOverSecondary
                } else {
                    self.splitMode = .oneOverSecondary
                }
            }

            switch oldSplitMode {
            case .sideOnly:
                self.splitSideAndSecondaryViewController()
                self.delegate?.splitViewController(self, willShow: .secondary)
                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willShow: .secondary)
                }
            case .secondaryOnly:
                self.delegate?.splitViewController(self, willShow: .supplementary)
                self.delegate?.splitViewController(self, willShow: .primary)

                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willShow: .supplementary)
                    proxy.splitViewController(self, willShow: .primary)
                }
            case .oneBesideSecondary, .oneOverSecondary:
                self.delegate?.splitViewController(self, willShow: .primary)

                for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                    proxy.splitViewController(self, willShow: .primary)
                }
            case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
                break
            }
        }

        if isHorizontal {
            self.lastSplitMode = self.splitMode
        }

        self.delegate?.splitViewController(self, willChangeTo: self.splitMode)
        for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
            proxy.splitViewController(self, willChangeTo: self.splitMode)
        }

        updateSubViewFrame(behavior: self.splitBehavior, splitMode: self.splitMode, animated: animated)

        for item in self.sideWrapperNavigation?.viewControllers ?? [] {
            self.updateSubViewSplitMode(item)
        }

        for item in self.secondaryNavigation?.viewControllers ?? [] {
            self.updateSubViewSplitMode(item)
        }

        self.delegate?.splitViewController(self, didChangeTo: self.splitMode)
        for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
            proxy.splitViewController(self, didChangeTo: self.splitMode)
        }
    }

    private func updateSubViewSplitMode(_ vc: UIViewController) {
        vc.children.forEach { child in
            self.updateSubViewSplitMode(child)
        }
        vc.splitSplitMode = self.splitMode
        vc.splitVCSplitModeChange(split: self)
        vc.splitSplitModeChange(splitMode: self.splitMode)
    }

    func updateSubViewFrame(behavior: SplitViewController.SplitBehavior,
                            splitMode: SplitViewController.SplitMode,
                            animated: Bool = false) {

        let realSize = calculateEdgeRealSize()
        
        if let tab = self.animatedTabBarController, !tab.showEdgeTabbar {
            if self.splitMode == .secondaryOnly {
                tab.setEdgeTabbar(show: false, from: self, animation: false)
            } else {
                tab.setEdgeTabbar(show: true, from: self,animation: false)
            }
        }

        let sizeGroup = self.calculateSubViewSize(realSize, behavior: behavior, splitMode: splitMode)
        let originGroup = self.calculateSubViewOrigin(realSize, behavior: behavior, splitMode: splitMode)

        if self.contentView.frame.size != sizeGroup.0 {
            self.contentView.frame.size = sizeGroup.0
        }

        if self.sideWrapperView.frame.size != sizeGroup.1 {
            self.sideWrapperView.frame.size = sizeGroup.1
        }

        panGestureView.frame = CGRect(x: panGestureViewMidX, y: 0, width: 56, height: realSize.height)
        sidePanGestureView.frame = CGRect(x: sidePanGestureViewMidX, y: 0, width: 56, height: realSize.height)

        self.layoutIfNeeded()
        
        let time: TimeInterval = animated ? 0.2 : 0
        UIView.animate(withDuration: time, animations: {
            if self.contentView.frame.origin != originGroup.0 {
                self.contentView.frame.origin = originGroup.0
            }

            if self.sideWrapperView.frame.origin != originGroup.1 {
                self.sideWrapperView.frame.origin = originGroup.1
            }

            self.updatePanGestureViewOrigin()

            self.maskView.alpha = (self.splitMode == .twoDisplaceSecondary || self.splitMode == .twoOverSecondary || self.splitMode == .oneOverSecondary) ? 1 : 0
        })
    }

    private func layoutIfNeeded() {
        self.childrenVC.forEach { (_, vc) in
            vc.view.layoutIfNeeded()
        }

        self.sideWrapperView.layoutIfNeeded()
        self.contentView.layoutIfNeeded()
        self.view.layoutIfNeeded()
    }

    private func calculateEdgeRealSize() -> CGSize {
        guard let tab = self.animatedTabBarController, tab.tabbarStyle == .edge, let edgeTab = tab.edgeTab else { return currentSize }
        var realSize = currentSize
        let isMax = self.rootWindow()?.frame.width ?? 0 >= EdgeTabBarLayoutStyle.maxViewWidth

        if !tab.showEdgeTabbar {
            realSize.width += EdgeTabBarLayoutStyle.vertical.width
        } else if isMax {
            let edgeWidth = max(EdgeTabBarLayoutStyle.vertical.width, min(edgeTab.frame.width, EdgeTabBarLayoutStyle.horizontal.width))
            realSize.width -= (edgeWidth - EdgeTabBarLayoutStyle.vertical.width)
        }

        return realSize
    }

    private func calculateSubViewSize(_ size: CGSize,
                                      behavior: SplitViewController.SplitBehavior,
                                      splitMode: SplitViewController.SplitMode) -> (CGSize, CGSize) {
        var contentSize = size
        var sideWrapperSize = CGSize(width: sideWrapperWidth, height: size.height)
        switch behavior {
        case .tile:
            switch splitMode {
            case .sideOnly:
                sideWrapperSize.width = size.width
                contentSize = CGSize(width: 0, height: size.height)
            case .secondaryOnly:
                break
            case .oneBesideSecondary:
                var width: CGFloat = 0
                if supplementaryWidth != 0 {
                    width = size.width - supplementaryWidth
                } else {
                    width = size.width - primaryWidth
                }
                contentSize = CGSize(width: width, height: size.height)
            case .twoBesideSecondary:
                contentSize = CGSize(width: size.width - sideWrapperWidth, height: size.height)
            default:
                break
            }
        case .displace:
            switch splitMode {
            case .sideOnly:
                sideWrapperSize.width = size.width
                contentSize = size
            case .oneBesideSecondary, .twoDisplaceSecondary:
                var width: CGFloat = 0
                if supplementaryWidth != 0 {
                    width = size.width - supplementaryWidth
                } else {
                    width = size.width - primaryWidth
                }
                contentSize = CGSize(width: width, height: size.height)
            default:
                break
            }
        case .overlay:
            switch splitMode {
            case .sideOnly:
                sideWrapperSize.width = size.width
                contentSize = size
            default:
                break
            }
        }
        Self.logger.info("SplitViewControllerLog/api/calculateSubViewSize, contentSize: \(contentSize), sideWrapperSize: \(sideWrapperSize)")

        return (contentSize, sideWrapperSize)
    }

    private func calculateSubViewOrigin(_ size: CGSize,
                                        behavior: SplitViewController.SplitBehavior,
                                        splitMode: SplitViewController.SplitMode) -> (CGPoint, CGPoint) {

        self.sideWrapperView.frame.origin.y = 0
        self.contentView.frame.origin.y = 0

        var sideWrapperOrigin: CGPoint = CGPoint(x: 0, y: 0)
        var contentOrigin: CGPoint = CGPoint(x: 0, y: 0)

        switch splitMode {
        case .sideOnly:
            sideWrapperOrigin.x = 0
            contentOrigin.x = currentSize.width
        case .secondaryOnly:
            sideWrapperOrigin.x = -sideWrapperWidth
            contentOrigin.x = 0
        case .oneBesideSecondary, .oneOverSecondary:
            var width: CGFloat = 0
            if supplementaryWidth != 0 {
                width = primaryWidth
            }
            sideWrapperOrigin.x = -width
            contentOrigin.x = sideWrapperWidth - width
        case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
            sideWrapperOrigin.x = 0
            contentOrigin.x = sideWrapperWidth
        }
        Self.logger.info("SplitViewControllerLog/api/calculateSubViewOrigin, contentOrigin: \(contentOrigin), sideWrapperOrigin: \(sideWrapperOrigin)")

        return (contentOrigin, sideWrapperOrigin)
    }

    func calculateSideDisplayWidth() -> CGFloat {
        switch splitMode {
        case .sideOnly:
            return currentSize.width
        case .secondaryOnly:
            return 0
        case .oneBesideSecondary, .oneOverSecondary:
            return supplementaryWidth == 0 ? primaryWidth : supplementaryWidth
        case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
            return sideWrapperWidth
        }
    }

    private func uiLog() {
        Self.logger.info("SplitViewControllerLog/UI/horizontalSizeClass: \(traitCollection.horizontalSizeClass.rawValue)")
        Self.logger.info("SplitViewControllerLog/UI/verticalSizeClass: \(traitCollection.verticalSizeClass.rawValue)")
        if #available(iOS 12.0, *) {
            Self.logger.info("SplitViewControllerLog/UI/userInterfaceStyle: \(traitCollection.userInterfaceStyle.rawValue)")
        }
        Self.logger.info("SplitViewControllerLog/UI/frame: \(self.view.frame)")
    }

    open func isCustomShowTabBar(_ viewController: UIViewController) -> Bool? {
        if self.isCollapsed {
            return nil
        }

        switch self.splitMode {
        case .twoOverSecondary, .twoBesideSecondary, .twoDisplaceSecondary:
            return true
        default:
            return nil
        }
    }
}
