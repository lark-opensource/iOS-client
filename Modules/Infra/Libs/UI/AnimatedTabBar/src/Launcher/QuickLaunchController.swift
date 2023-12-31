//
//  QuickLaunchController.swift
//  AnimatedTabBar
//
//  Created by ByteDance on 2023/4/26.
//

import UIKit
import FigmaKit
import LarkTab
import LarkStorage
import LarkFoundation
import LarkExtensions
import UniverseDesignIcon
import UniverseDesignMenu
import UniverseDesignColor
import UniverseDesignToast
import RxSwift
import LarkUIKit
import ByteWebImage
import LKCommonsTracker
import Homeric
import LarkSetting
import LarkEnv
import LarkReleaseConfig
import LarkBoxSetting
import LKCommonsLogging
import LarkContainer
import RustPB
import EENavigator

// 忽略魔法数检查
// nolint: magic number

/// QuickLaunchWindow 的 rootViewController，也可以用作独立 VC。
class QuickLaunchController: UIViewController, UserResolverWrapper {

    let userResolver: UserResolver

    static let logger = Logger.log(QuickLaunchController.self, category: "Module.AnimatedTabBar")

    // FG：CRMode数据统一
    public lazy var crmodeUnifiedDataDisable: Bool = {
        return fgService?.staticFeatureGatingValue(with: "lark.navigation.disable.crmode") ?? false
    }()

    /// 开平配置
    @ScopedInjectedLazy private var openPlatformConfig: OpenPlatformConfigService?

    @ScopedInjectedLazy var fgService: FeatureGatingService?

    /// 通过代理向外传递信息
    private weak var delegate: QuickLaunchControllerDelegate?
    private weak var tabBarVC: AnimatedTabBarController?

    // 是否显示「更多」tab，目前精简模式下不显示该tab
    private let moreTabEnabled: Bool

    // 是否已经播放过动画
    private var animationPlayed: Bool = false

    // iPad设备C模式主导航最多显示个数
    private let iPadCModeMaxMainCount: Int = 5

    private var showAnimationLock: Bool = false
    private var dismissAnimationLock: Bool = false

    private weak var scrollView: UIScrollView?

    // MARK: UI Components

    /// 背景遮罩
    private lazy var backgroundMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0)
        return view
    }()
    
    /// 指示条
    private lazy var indicateView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.2)
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        return view
    }()

    /// 模糊背景
    private lazy var containerView: UIView = {
        let blurView = VisualBlurView()
        blurView.fillColor = UIColor.ud.bgFloat
        blurView.blurRadius = 80.0
        blurView.fillOpacity = 0.85
        return blurView
    }()

    private lazy var addRecommandView: AddRecommandView = {
        let addView = AddRecommandView(frame: .zero, isDisplayBackground: true)
        addView.isHidden = true
        return addView
    }()

    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        return panGesture
    }()

    private lazy var didTapDismissBackView: UIView = {
        let view = UIView()
        let didTapGesture = UITapGestureRecognizer(target: self, action: #selector(didDismissBackTap))
        view.addGestureRecognizer(didTapGesture)
        return view
    }()

    var navigationAddlinkEnable: Bool {
        let addlinkEnable = userResolver.fg.dynamicFeatureGatingValue(with: AnimatedTabBarFeatureKey.navigationAddlinkEnable.key)
        Self.logger.info("navigation addlink enable: \(addlinkEnable)")
        return addlinkEnable
    }

    /// 总体的 CollectionView
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.clipsToBounds = true
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.lu.register(cellWithClass: RecentsListCell.self)
        collectionView.lu.register(cellWithClass: RecentsListMoreCell.self)
        collectionView.lu.register(cellWithClass: QuickTabBarItemView.self)
        collectionView.lu.register(cellWithClass: AddRecommandCell.self)
        collectionView.lu.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: TabEditFooterView.self)
        collectionView.lu.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: TabDividerFooterView.self)
        collectionView.lu.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: TabHeaderTitleView.self)
        collectionView.lu.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: TabHeaderEditView.self)
        return collectionView
    }()
    
    public var isOpenPlatformEntryEnable: Bool {
        if BoxSetting.isBoxOff() {
            return false
        }
        return FeatureGatingManager.shared.featureGatingValue(with: "lark.navigation.openplatform.entry")
    }

    /// 底部的假 TabBar
    private lazy var tabBar = QuickLaunchTabBar(moreTabEnabled: self.moreTabEnabled, userResolver: self.userResolver)

    /// 如果打开 QuickLauncher 时，有指定的 barHeight，记录下来，以便 dismiss 时使用
    private var initialBarHeight: CGFloat?

    /// 底部 TabBar 背后的模糊背景
    private lazy var tabBarMaskView = BottomMaskView()

    /// Tab 的总数据源
    var tabDataSource: AllTabBarItems {
        tabBarVC?.allTabBarItems ?? AllTabBarItems()
    }

    private func safeAreaMinY() -> CGFloat {
        return self.view.safeAreaInsets.top
    }

    /// 快捷导航的数据源
    var quickDataSource: [AbstractTabBarItem] {
        let allTabBarItems = tabBarVC?.allTabBarItems ?? AllTabBarItems()
        // CRMode数据统一GA后删除重复代码
        if !self.crmodeUnifiedDataDisable {
            var quick: [AbstractTabBarItem]
            if Display.pad {
                quick = Array(allTabBarItems.iPad.quick)
            } else {
                quick = Array(allTabBarItems.iPhone.quick)
            }
            let mainItems = allTabBarItems.iPad.main
            let mainCount = mainItems.count
            var quickItems = quick
            if mainCount > iPadCModeMaxMainCount {
                // 因为C模式下底部主导航最多只能显示5个，所以把截断的“拼到”快捷导航前面
                let mainSuffix = Array(mainItems[iPadCModeMaxMainCount..<mainCount])
                quickItems = mainSuffix + quick
            }
            if isOpenPlatformEntryEnable {
                var needAddAS = true
                let lastItemKey: String?
                if Display.pad {
                    lastItemKey = allTabBarItems.iPad.quick.last?.tab.key
                } else {
                    lastItemKey = allTabBarItems.iPhone.quick.last?.tab.key
                }
                if lastItemKey == Tab.asKey {
                    needAddAS = false
                }
                if needAddAS, let asTab = self.openPlatformConfig?.asTab {
                    // 需要在最后面加一个应用商城的item
                    let stateConfig = ItemStateConfig(defaultIcon: UDIcon.findAppOutlined, selectedIcon: UDIcon.findAppOutlined, quickBarIcon: UDIcon.findAppOutlined)
                    let item = TabBarItem(tab: asTab, title: BundleI18n.AnimatedTabBar.Lark_Navbar_More_Discovery_Button, stateConfig: stateConfig)
                    quickItems.append(item)
                    // 曝光埋点
                    Tracker.post(TeaEvent(Homeric.PUBLIC_TAB_CONTAINER_VIEW))
                }
            }
            return quickItems
        } else {
            var quick: [AbstractTabBarItem] = Array(allTabBarItems.bottom.quick)
            if isOpenPlatformEntryEnable {
                var needAddAS = true
                let lastItemKey = allTabBarItems.bottom.quick.last?.tab.key
                if lastItemKey == Tab.asKey {
                    needAddAS = false
                }
                if needAddAS, let asTab = self.openPlatformConfig?.asTab {
                    // 需要在最后面加一个应用商城的item
                    let stateConfig = ItemStateConfig(defaultIcon: UDIcon.addOutlined, selectedIcon: UDIcon.findAppOutlined, quickBarIcon: UDIcon.findAppOutlined)
                    let item = TabBarItem(tab: asTab, title: BundleI18n.AnimatedTabBar.Lark_Navbar_More_Discovery_Button, stateConfig: stateConfig)
                    quick.append(item)
                    // 曝光埋点
                    Tracker.post(TeaEvent(Homeric.PUBLIC_TAB_CONTAINER_VIEW))
                }
            }
            return quick
        }
    }

    private let disposeBag = DisposeBag()
    private let kvoDisposeBag = KVODisposeBag()

    /// 刷新所有数据源
    func reloadData() {
        // 更新快捷导航应用的ContentInset
//        self.updateCollectionViewContentInset()
        layout()
        // 刷新 Launcher 主页 UI
        collectionView.reloadData()
        // 刷新 TabBar UI
        // NOTE: 比较数据源，以免重复刷新相同数据，导致 TabBar 动画闪动
        if !self.crmodeUnifiedDataDisable {
            let mainTabItems: [AbstractTabBarItem]
            if Display.pad {
                mainTabItems = tabDataSource.iPad.main
            } else {
                mainTabItems = tabDataSource.iPhone.main
            }
            // C模式（主导航最多显示5个哦）
            let mainItems = Array(mainTabItems.prefix(iPadCModeMaxMainCount))
            if !tabBar.tabItems.isEqualTo(mainItems) {
                // 刷新 TabBar UI,重置选中状态
                tabBar.tabItems = mainItems
            }
        } else {
            // CRMode数据统一GA后删除重复代码
            if !tabBar.tabItems.isEqualTo(tabDataSource.bottom.main) {
                // 刷新 TabBar UI,重置选中状态
                tabBar.tabItems = tabDataSource.bottom.main
            }
        }
    }

    // 产品要求列表从下往上布局，这蜜汁操作我真是第一次见
    func updateCollectionViewContentInset() {
        // 计算快捷导航区域的高度
        let titleHeight = 48.0
        let quickCount = numberOfQuickTabCells
        let quickLines = (quickCount - 1) / QuickTabBarConfig.Layout.collectionMaxLineCount + 1
        let insetHeight = QuickTabBarConfig.Layout.collectionSectionInset.top + QuickTabBarConfig.Layout.collectionSectionInset.bottom
        let quickAreaHeight = CGFloat(quickLines) * QuickTabBarConfig.Layout.itemSize.height + CGFloat(quickLines - 1) * QuickTabBarConfig.Layout.itemSpacing + titleHeight + insetHeight
        // 计算添加区域的高度
        let recommandAreaHeight = 44.0 + 36.0
        
        // 整个显示区域的高度
        let displayHeight = self.view.safeAreaLayoutGuide.layoutFrame.height - Cons.tabBarHeight
        // 当前实际内容的高度
        let currentHeight = quickAreaHeight + recommandAreaHeight
        // 算出差值，根据delta计算inset
        let delta = displayHeight - currentHeight
        var top = 0.0
        var bottom = 0.0
        if delta > 0 {
            top = delta
            bottom = Cons.tabBarHeight
        } else {
            top = 0
            bottom = Cons.tabBarHeight * 2
        }
        // 设置新的contentInset
        self.collectionView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
    }

    func getContainViewContentHeight() -> CGFloat {
        let quickAreaHeight = getQuickAreaHeight()
        let isDisplayOutOfScreen = getDisplayOutOfScreen()
        // 计算添加区域的高度
        let recommandAreaHeight = Cons.addRecommandAreaHeight + Cons.addRecommandAreaInset
        let lessThanScreenheight = navigationAddlinkEnable ? (quickAreaHeight + recommandAreaHeight) : quickAreaHeight
        let currentHeight = isDisplayOutOfScreen ? quickAreaHeight : lessThanScreenheight
        return currentHeight
    }

    func getDisplayHeight() -> CGFloat {
        let displayHeight = self.view.safeAreaLayoutGuide.layoutFrame.height - Cons.tabBarHeight
        return displayHeight
    }

    func getDisplayCriticalOriginY() -> CGFloat {
        let criticalY = self.view.bounds.size.height - self.getContainViewContentHeight() - Cons.tabBarHeight - self.view.safeAreaInsets.bottom
        return criticalY
    }

    /// 是否超出一屏幕展示
    func getDisplayOutOfScreen() -> Bool {
        let quickAreaHeight = getQuickAreaHeight()
        let suppliedMaxHeight = self.getDisplayHeight()
        if (quickAreaHeight + Cons.addRecommandAreaInset) > suppliedMaxHeight {
            return true
        }
        return false
    }

    func getQuickAreaHeight() -> CGFloat {
        // 计算快捷导航区域的高度
        let indicateHeight = 12.0
        let titleHeight = 48.0
        let quickCount = numberOfQuickTabCells
        let quickLines = (quickCount - 1) / QuickTabBarConfig.Layout.collectionMaxLineCount + 1
        let insetHeight = QuickTabBarConfig.Layout.collectionSectionInset.top + QuickTabBarConfig.Layout.collectionSectionInset.bottom
        let quickAreaHeight = CGFloat(quickLines) * QuickTabBarConfig.Layout.itemSize.height + CGFloat(quickLines - 1) * QuickTabBarConfig.Layout.itemSpacing + indicateHeight + titleHeight + insetHeight
        return quickAreaHeight
    }

    // MARK: Life Cycle

    init(delegate: QuickLaunchControllerDelegate?, tabbarVC: AnimatedTabBarController?, userResolver: UserResolver, moreTabEnabled: Bool) {
        self.delegate = delegate
        self.tabBarVC = tabbarVC
        self.userResolver = userResolver
        self.moreTabEnabled = moreTabEnabled
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        Tracker.post(TeaEvent(Homeric.NAVIGATION_MORE_APP_VIEW))
    }

    private func setup() {
        self.panGesture.delegate = self
        self.containerView.addGestureRecognizer(self.panGesture)
        setupSubviews()
        setupConstraints()
        setupAppearance()
        makeCornerRadius()
    }

    @objc
    private func didDismissBackTap() {
        Self.logger.info("did dismiss back")
        delegate?.quickLaunchControllerDidTapCloseButton(self)
    }

    private func setupSubviews() {
        view.addSubview(didTapDismissBackView)
        view.addSubview(containerView)
        containerView.addSubview(indicateView)
        containerView.addSubview(collectionView)
        view.addSubview(addRecommandView)
        view.addSubview(tabBarMaskView)
        view.addSubview(tabBar)
    }

    // nolint: duplicated_code - 新实现
    private func setupConstraints() {
        indicateView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 40, height: 4))
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(indicateView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        tabBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Cons.tabBarHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        tabBarMaskView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(tabBar.snp.top)
            make.bottom.equalToSuperview()
        }
        addRecommandView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(tabBar.snp.top)
            make.height.equalTo(Cons.addRecommandViewHeight)
        }
    }

    private func addBackgroundMaskView() {
        view.window?.insertSubview(backgroundMaskView, at: 0)
        backgroundMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupAppearance() {
        // TabBar 上添加一个 "退出" 按钮
        // NOTE: 因为 TabBar 最后一个按钮是功能按钮，不会同步服务端，因此是端上自己创建的
        var quickTabBarItems: [AbstractTabBarItem] = []
        if !self.crmodeUnifiedDataDisable {
            let mainTabItems: [AbstractTabBarItem]
            if Display.pad {
                mainTabItems = tabDataSource.iPad.main
                let quickItems = tabDataSource.iPad.quick
                quickTabBarItems = quickItems
                let mainCount = mainTabItems.count
                if mainCount > iPadCModeMaxMainCount {
                    // 因为C模式下底部主导航最多只能显示5个，所以把截断的“拼到”快捷导航前面
                    let mainSuffix = Array(mainTabItems[iPadCModeMaxMainCount..<mainCount])
                    quickTabBarItems = mainSuffix + quickItems
                }
            } else {
                mainTabItems = tabDataSource.iPhone.main
                quickTabBarItems = tabDataSource.iPhone.quick
            }
            // C模式（主导航最多显示5个哦）
            tabBar.tabItems = Array(mainTabItems.prefix(iPadCModeMaxMainCount))
        } else {
            // CRMode数据统一GA后删除重复代码
            tabBar.tabItems = tabDataSource.bottom.main
            quickTabBarItems = tabDataSource.bottom.quick
        }
        tabBar.moreItem = {
            let item = TabBarItem(
                tab: Tab.more,
                title: BundleI18n.AnimatedTabBar.Lark_Core_More_Navigation,
                stateConfig: ItemStateConfig(
                    defaultIcon: nil,
                    selectedIcon: nil,
                    quickBarIcon: nil
                )
            )
            item.customView = TabMoreGridView(tabBarItems: quickTabBarItems)
            item.itemState = DefaultTabState()
            item.selectedState()
            return item
        }()
        // tabBar.moreItem = tabBarVC?.bottomMoreItem
        tabBar.delegate = self
        addRecommandView.addEvent = { [weak self] in
            guard let self = self else {
                return
            }
            self.addRecommand()
        }
    }

    deinit {
        print("QuickLaunchController deinit")
    }
}

// MARK: - Animation

extension QuickLaunchController {

    func playShowAnimation(fromInitialBarHeight barHeight: CGFloat? = nil,
                           completion: (() -> Void)? = nil) {
        // 等最近使用数据加载完毕后再播放动画
        self.animationPlayed = false
        // 先要设置collectionView的contentInset否则会向下跳一下的
        updateCollectionViewContentInset()
        // 计算好偏移量后再播放动画
        playAnimationIfNeeded()
    }

    func playAnimationIfNeeded() {
        // 确保只有主动进入页面的时候才播放一次动画
        guard !self.animationPlayed else {
            return
        }
        let initialBarHeight = Cons.tabBarHeight
        view.layoutIfNeeded()
        containerView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        containerView.alpha = 0.0
        self.tabBar.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
        }
        self.tabBar.transform = .identity.translatedBy(x: 0, y: Cons.tabBarHeight - initialBarHeight)
        self.tabBarMaskView.alpha = 0
        self.tabBar.alpha = 0
        self.tabBar.layer.masksToBounds = true
        self.tabBar.playShowAnimation()
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.transform = .identity
            self.containerView.alpha = 1
            self.tabBarMaskView.alpha = 1
            self.tabBar.alpha = 1
            self.tabBar.layer.cornerRadius = 12
            self.tabBar.transform = .identity.translatedBy(x: 0, y: -Cons.tabBarRasingOffset)
            self.tabBar.layoutIfNeeded()
        }) { [weak self] _ in
            self?.animationPlayed = true
            self?.reloadData()
        }
    }

    /// 新展示动画样式
    func playShowAnimationV2(fromInitialContentViewY contentViewY: CGFloat? = nil,
                             completion: (() -> Void)? = nil) {
        
        let contentViewTargetOriginY = max(getDisplayCriticalOriginY(), safeAreaMinY())
        let initialContentViewY = contentViewY ?? self.getDisplayHeight()
        guard initialContentViewY != contentViewTargetOriginY else {
            return
        }

        addBackgroundMaskView()
        updateCollectionViewContentInsetV2()

        updateContentViewSize()
        self.updateContentViewY(initialContentViewY)

        guard !showAnimationLock else { return }
        showAnimationLock = true
        configAddRecommandViewDisplay()

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.updateContentViewY(contentViewTargetOriginY)
            self.backgroundMaskView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(QuickTabBarConfig.Style.alphaPercent)
        } completion: { _ in
            self.reloadData()
            completion?()
            self.showAnimationLock = false
        }
    }

    func playDismissAnimation(fromInitialBarHeight barHeight: CGFloat? = nil,
                              completion: (() -> Void)? = nil) {
        let initialBarHeight = barHeight ?? initialBarHeight ?? Cons.tabBarHeight
        self.tabBar.translatesAutoresizingMaskIntoConstraints = true
        self.tabBar.snp.updateConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        self.tabBar.playDismissAnimation()
        NotificationCenter.default.post(name: .lkQuickLaunchWindowWillDismiss, object: nil)
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.containerView.alpha = 0
            self.tabBarMaskView.alpha = 0
            self.tabBar.alpha = 0
            self.tabBar.layer.cornerRadius = 0
            self.tabBar.transform = .identity.translatedBy(x: 0, y: Cons.tabBarHeight - initialBarHeight)
            self.tabBar.layoutIfNeeded()
        }, completion: { _ in
            self.tabBar.layer.masksToBounds = false
            completion?()
        })
    }

    func playDismissAnimationV2(completion: (() -> Void)? = nil) {
        NotificationCenter.default.post(name: .lkQuickLaunchWindowWillDismiss, object: nil)
        guard !dismissAnimationLock else { return }
        dismissAnimationLock = true
        UIView.animate(withDuration: 0.15) {
            self.updateContentViewY(self.getDisplayHeight() + Cons.tabBarHeight)
            self.backgroundMaskView.backgroundColor = UIColor.ud.bgMask.withAlphaComponent(0)
        } completion: { _ in
            self.dismissAnimationLock = false
            self.containerView.alpha = 0
            self.tabBarMaskView.alpha = 0
            self.tabBar.alpha = 0
            self.tabBar.layoutIfNeeded()
            completion?()
        }
    }

    private func updateContentViewY(_ contentViewY: CGFloat) {
        var contentFrame = self.containerView.frame
        // contentView不能高于容器
        let minY = safeAreaMinY()
        contentFrame.origin.y = max(contentViewY, minY)
        self.containerView.frame = contentFrame
        self.didTapDismissBackView.frame = CGRect(x: 0, y: 0, width: contentFrame.size.width, height: contentFrame.origin.y)

        let criticalY = getDisplayCriticalOriginY()
        let progress = 1 - (self.containerView.frame.origin.y - criticalY) / self.getContainViewContentHeight()
        updateToProgress(progress)
    }

    private func updateContentViewSize() {
        var contentFrame = self.containerView.frame
        let originContentWidth = contentFrame.size.width
        contentFrame.size.width = self.view.frame.size.width
        guard self.delegate != nil else { return }
        let contentHeight = self.getContainViewContentHeight()
        let suppliedMaxHeight = self.getDisplayHeight()
        contentFrame.size.height = min(contentHeight, suppliedMaxHeight)
        self.containerView.frame = contentFrame
        if originContentWidth != self.view.frame.size.width {
            Self.logger.info("update content view size")
            makeCornerRadius()
            view.setNeedsDisplay()
            view.layoutIfNeeded()
        }
    }

    private func updateToProgress(_ progress: CGFloat) {
        Self.logger.info("progress: \(progress)")
    }

    private func changeScrollEnabled(_ enabled: Bool) {
        self.scrollView?.panGestureRecognizer.isEnabled = enabled
    }

    private func showOrDismissWhenPanEnd() {
        let height = self.getDisplayHeight()
        let height1 = containerView.frame.size.height * QuickTabBarConfig.Style.autoAnimationPercent
        let criticalY = height - height1
        Self.logger.info("showOrDismissWhenPanEnd  \(containerView.frame.origin.y) \(criticalY)")
        if self.containerView.frame.origin.y > criticalY {
            playDismissAnimationV2 { [weak self] in
                guard let self = self else {
                    return
                }
                self.delegate?.quickLaunchControllerDidTapCloseButton(self)
            }
        } else {
            scrollHidingAddRecommandView(by: true)
            playShowAnimationV2(fromInitialContentViewY: self.containerView.frame.origin.y)
        }
    }

    func layout() {
        // 重新对contentView进行布局。常见case：当contentView的数据发生变化时，对height和y值进行刷新
        configAddRecommandViewDisplay()
        updateCollectionViewContentInsetV2()
        updateContentViewSize()
        updateContentViewY(getDisplayCriticalOriginY())
    }

    private func configAddRecommandViewDisplay() {
        scrollHidingAddRecommandView(by: getDisplayOutOfScreen())
    }

    /// 超出一屏时需要修改bottomInset，留出空间展示底部应用
    func updateCollectionViewContentInsetV2() {
        guard navigationAddlinkEnable else {
            return
        }
        let addRecommandViewIsHidden = !getDisplayOutOfScreen()
        if addRecommandViewIsHidden {
            self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Cons.addRecommandViewHeight, right: 0)
        }
    }

    /// 绘制圆角
    private func makeCornerRadius() {
        let maxScreenLength = max(self.view.frame.size.height, self.view.frame.size.width)
        let maskBounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: maxScreenLength)
        let maskPath = UIBezierPath(
            roundedRect: maskBounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 12, height: 12)
        )
        let maskLayer = CAShapeLayer()
        maskLayer.frame = containerView.bounds
        maskLayer.path = maskPath.cgPath
        containerView.layer.mask = maskLayer
    }

    // nolint: duplicated_code - 新实现
    @objc
    func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        let contentViewTargetOriginY = max(getDisplayCriticalOriginY(), safeAreaMinY())
        let scrollViewContentOffsetY = scrollView?.contentOffset.y ?? 0
        if self.containerView.frame.origin.y > contentViewTargetOriginY {
            //兜底处理panGesture没有回调ended问题
            scrollHidingAddRecommandView(by: false)
        }
        let translation = panGesture.translation(in: containerView)
        let point = panGesture.location(in: self.scrollView)
        let isOperScrollView = self.scrollView?.layer.contains(point) ?? false
        if isOperScrollView {
            // 当手指在scrollView滑动时
            guard let scrollView = self.scrollView else { return }
            if scrollViewContentOffsetY <= 0 {
                // 当scrollView在最顶部时
                if translation.y > 0 {
                    // 向下拖拽
                    changeScrollEnabled(false)
                    scrollView.contentOffset = .zero
                    let contentViewY = self.containerView.frame.origin.y + translation.y
                    updateContentViewY(contentViewY)
                } else if translation.y < 0 {
                    // 向上拖拽
                    guard self.containerView.frame.origin.y != contentViewTargetOriginY else {
                        changeScrollEnabled(true)
                        return
                    }
                    changeScrollEnabled(false)
                    scrollView.contentOffset = .zero
                    let contentY = self.containerView.frame.origin.y
                    if contentY > contentViewTargetOriginY {
                        let contentViewY = max(contentY + translation.y, contentViewTargetOriginY)
                        updateContentViewY(contentViewY)
                    }
                }
            }
        } else {
            if translation.y > 0 {
                // 向下拖拽
                let contentViewY = self.containerView.frame.origin.y + translation.y
                updateContentViewY(contentViewY)
            } else if translation.y < 0 {
                // 向上拖拽
                let contentMinY = self.getDisplayHeight() - self.containerView.frame.size.height + Cons.tabBarHeight
                let contentY = self.containerView.frame.origin.y
                if contentY > contentMinY {
                    let contentViewY = max(contentY + translation.y, contentMinY)
                    updateContentViewY(contentViewY)
                }
            }
        }
        Self.logger.info("panGesture state:\(panGesture.state) \(self.containerView.frame.origin.y) \(contentViewTargetOriginY)")
        if panGesture.state == .ended {
            changeScrollEnabled(true)
            // 手指离开屏幕时，进行展示/收起contentView
            showOrDismissWhenPanEnd()
        } else if panGesture.state == .changed, self.containerView.frame.origin.y <= contentViewTargetOriginY, scrollViewContentOffsetY == 0 {
            //有点坑，兜底处理panGesture没有回调ended问题
            scrollHidingAddRecommandView(by: true)
        }
        // 复位
        panGesture.setTranslation(.zero, in: containerView)
    }

    private func scrollToLastest(animated: Bool) {
        if numberOfQuickTabCells > 1 {
            collectionView.scrollToItem(at: IndexPath(item: numberOfQuickTabCells - 1, section: 0), at: .bottom, animated: animated)
        }
    }

    private func scrollHidingAddRecommandView(by isShow: Bool) {
        guard navigationAddlinkEnable, getDisplayOutOfScreen() else {
            self.addRecommandView.isHidden = true
            return
        }
        if isShow {
            self.addRecommandView.isHidden = false
        } else {
            self.addRecommandView.isHidden = true
        }
    }
}

// MARK: - CollectionView Delegate

extension QuickLaunchController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        switch indexPath.section {
        case quickTabSectionIndex:
            // 更多应用
            guard indexPath.item < self.quickDataSource.count else {
                Self.logger.info("did select item out range")
                return
            }
            let tab = self.quickDataSource[indexPath.item].tab
            delegate?.quickLaunchController(self, didSelectItemInPinView: tab)
        case addRecommandSectionIndex:
            // 推荐应用
            print("Recommand")
        default:
            break
        }
    }

    /// 添加推荐
    func addRecommand() {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_MAIN_CLICK, params: ["click": "add_app"]))
        let recommandController = NaviRecommandViewController(userResolver: self.userResolver, tabBarVC: self.tabBarVC, cancelCallback: {
            Self.logger.info("recommand vc cancel callback")
        }, addRecommandCallback: { [weak self] in
            guard let self = self else {
                return
            }
            self.scrollToLastest(animated: false)
        })
        userResolver.animatedNavigator.present(recommandController, wrap: LkNavigationController.self, from: self)
    }
}

// MARK: - CollectionView DataSource

extension QuickLaunchController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSections
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case quickTabSectionIndex:
            return numberOfQuickTabCells
        case addRecommandSectionIndex:
            return numberOfAddRecommandCells
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case quickTabSectionIndex:
            guard indexPath.item < self.quickDataSource.count else { return UICollectionViewCell() }
            let quickTabCell = collectionView.lu.dequeueReusableCell(withClass: QuickTabBarItemView.self, for: indexPath)
            let item = quickDataSource[indexPath.item]
            quickTabCell.item = item
            quickTabCell.configure(userResolver: userResolver)
            let longPressGes = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(gesture:)))
            longPressGes.minimumPressDuration = 0.5
            longPressGes.numberOfTouchesRequired = 1
            quickTabCell.addGestureRecognizer(longPressGes)
            return quickTabCell
        case addRecommandSectionIndex:
            let addRecommandCell = collectionView.lu.dequeueReusableCell(withClass: AddRecommandCell.self, for: indexPath)
            addRecommandCell.configure { [weak self] in
                guard let self = self else { return }
                self.addRecommand()
            }
            return addRecommandCell
        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard (UICollectionView.elementKindSectionFooter == kind || UICollectionView.elementKindSectionHeader == kind) else { return UICollectionReusableView() }
        if UICollectionView.elementKindSectionFooter == kind {
            switch indexPath.section {
            case quickTabSectionIndex:
                return UICollectionReusableView()
            default:
                return UICollectionReusableView()
            }
        } else if UICollectionView.elementKindSectionHeader == kind {
            switch indexPath.section {
            case quickTabSectionIndex:
                let editHeaderView = collectionView.lu.dequeueReusableSupplementaryView(
                    ofKind: UICollectionView.elementKindSectionHeader,
                    withClass: TabHeaderEditView.self,
                    for: indexPath)
                editHeaderView.editHandler = { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.quickLaunchControllerDidTapEditButton(self)
                }
                return editHeaderView
            default:
                return UICollectionReusableView()
            }
        }
        return UICollectionReusableView()
    }

    @objc
    private func longPressed(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let itemView = gesture.view as? QuickTabBarItemView else { return }
        guard let tabItem = itemView.item else { return }
        // 编辑
        let editAction = UDMenuAction(title: BundleI18n.AnimatedTabBar.Lark_Core_NavbarAppAction_Reorder_Button, icon: UDIcon.sortOutlined, tapHandler: { [weak self] in
            guard let self = self else { return }
            // show edit vc
            self.tabBarVC?.showTabEditController(on: self)
        })
        // 重命名
        let renameAction = UDMenuAction(title: BundleI18n.AnimatedTabBar.Lark_Core_NavbarAppAction_Rename_Button, icon: UDIcon.editOutlined, tapHandler: { [weak self] in
            guard let self = self, let hudOn = self.view else { return }
            self.delegate?.quickLaunchController(self, shouldRenameItemInQuickLaunchArea: tabItem, success: {
                //
            }, fail: {
                UDToast.showFailure(with: BundleI18n.AnimatedTabBar.Lark_Legacy_NetworkError, on: hudOn)
            })
        })
        // 删除
        let removeAction = UDMenuAction(title: BundleI18n.AnimatedTabBar.Lark_Core_NavbarAppAction_Remove_Button, icon: UDIcon.noOutlined, tapHandler: { [weak self] in
            guard let self = self, let hudOn = self.view else { return }
            let hud = UDToast.showLoading(with: BundleI18n.AnimatedTabBar.Lark_Legacy_BaseUiLoading, on: hudOn, disableUserInteraction: true)
            self.delegate?.quickLaunchController(self, shouldDeleteItemInQuickLaunchArea: tabItem.tab, success: {
                hud.remove()
            }, fail: {
                hud.remove()
                UDToast.showFailure(with: BundleI18n.AnimatedTabBar.Lark_Legacy_NetworkError, on: hudOn)
            })
        })
        var actions = [editAction]
        // 租户的不能重命名，用户自定义的可以
        if tabItem.tab.source == .userSource {
            actions.append(renameAction)
        }
        // 是否可删除
        if tabItem.tab.erasable {
            actions.append(removeAction)
        }
        // 显示弹出菜单
        UDMenu(actions: actions).showMenu(sourceView: itemView.iconView, sourceVC: self)
    }
}

// MARK: - CollectionView FlowLayout

extension QuickLaunchController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case quickTabSectionIndex:
            return QuickTabBarConfig.Layout.collectionSectionInset
        case addRecommandSectionIndex:
            return .zero
        default:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch section {
        case quickTabSectionIndex:
            return QuickTabBarConfig.Layout.itemSpacing
        case addRecommandSectionIndex:
            return 0
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case quickTabSectionIndex:
            // QuickTabCell
            return QuickTabBarConfig.Layout.realItemSize(forWidth: collectionView.bounds.width)
        case addRecommandSectionIndex:
            // 添加推荐应用入口
            return CGSize(width: collectionView.bounds.width, height: Cons.addRecommandAreaHeight)
        default:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        switch section {
        case quickTabSectionIndex:
            // 编辑按钮移到Header了，但是你不能保证哪天PM又要加回来
            return .zero
        default:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case quickTabSectionIndex:
            // 标题更多 + 编辑按钮
            return CGSize(width: collectionView.frame.width, height: 48)
        default:
            return .zero
        }
    }
}

// MARK: - TabBar Delegate

extension QuickLaunchController: QuickLaunchTabBarDelegate {
    func tabBar(_ tabBar: QuickLaunchTabBar, didSelectItem tab: LarkTab.Tab) {
        delegate?.quickLaunchController(self, didSelectItemInBarView: tab)
    }

    func tabBarDidTapMoreButton(_ tabBar: QuickLaunchTabBar) {
        // 点击了“退出”按钮
        delegate?.quickLaunchControllerDidTapCloseButton(self)
    }

    func tabBar(_ tabBar: QuickLaunchTabBar, didLongPressItem tab: LarkTab.Tab) {
        delegate?.quickLaunchController(self, didLongPressItemInBarView: tab)
    }
}

extension QuickLaunchController {

    private var numberOfSections: Int {
        guard navigationAddlinkEnable else { return 1 }
        let isDisplayOutOfScreen = getDisplayOutOfScreen()
        Self.logger.info("isDisplay outOf screen: \(isDisplayOutOfScreen)")
        return isDisplayOutOfScreen ? 1 : 2
    }

    private var quickTabSectionIndex: Int {
        0
    }

    private var addRecommandSectionIndex: Int {
        1
    }

    private var numberOfQuickTabCells: Int {
        quickDataSource.count
    }

    private var numberOfAddRecommandCells: Int {
        1
    }
}

extension QuickLaunchController: UIGestureRecognizerDelegate {
    // 控制手势识别器是否应该开始解析触摸事件
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        self.scrollView = nil
        if gestureRecognizer == self.panGesture {
            var touchView = touch.view
            while touchView != nil {
                if let touchView1 = touchView as? UIScrollView {
                    self.scrollView = touchView1
                    return true
                }
                if let next = touchView?.next, let nextView = next as? UIView {
                    touchView = nextView
                } else {
                    touchView = nil
                }
            }
        }
        return true
    }

    // 是否允许两个手势同时存在
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let scrollView = self.scrollView else { return false }
        let result = (gestureRecognizer == self.panGesture) && (otherGestureRecognizer == scrollView.panGestureRecognizer)
        return result
    }
}

// MARK: - Utils

extension QuickLaunchController {

    /// 一些布局相关的常量定义在这里，不要在代码中使用魔法数字
    enum Cons {
        /// TabBar 的高度，此高度应与外部 MainTabBar 的高度一致
        static var tabBarHeight: CGFloat { MainTabBar.Layout.stackHeight }
        /// TabBar 从贴底状态到悬浮状态，上升的距离
        static var tabBarRasingOffset: CGFloat { 5 }
        /// 添加固定视图高度
        static var addRecommandViewHeight: CGFloat = 108
        /// 添加滚动时底部视图高度
        static var addRecommandAreaHeight: CGFloat = 76
        /// 添加滚动时底部视图 Inset
        static var addRecommandAreaInset: CGFloat = 32
    }
}

extension Array where Element == AbstractTabBarItem {

    func isEqualTo(_ anotherArray: [AbstractTabBarItem]) -> Bool {
        guard count == anotherArray.count else { return false }
        for (index, item) in enumerated() {
            let anotherItem = anotherArray[index]
            if item.tab != anotherItem.tab {
                return false
            }
        }
        return true
    }
}
