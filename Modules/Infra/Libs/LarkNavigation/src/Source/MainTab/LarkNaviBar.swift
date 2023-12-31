//
//  LarkNaviBar.swift
//  LarkFeed
//
//  Created by PGB on 2019/10/8.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Swinject
import LarkTag
import LarkUIKit
import AnimatedTabBar
import LarkPerf
import LarkInteraction
import LarkFeatureGating
import UniverseDesignDrawer
import LarkResource
import UniverseDesignTheme
import LarkAccountInterface
import UniverseDesignColor
import RunloopTools
import LarkContainer

extension LarkNaviBar {
    enum Layout {
        static let buttonSize: CGFloat = 24.0
        static let buttonEdgeInset: CGFloat = -10.0
    }
}

public extension LarkNaviBar {
    static var viColor: UIColor? {
        var viColor: UIColor?
        if !Display.pad {
            // PAD上不支持导航栏变色
            viColor = ResourceManager.get(key: "suite_skin_vi_color", type: "color")
        }
        return viColor
    }

    static var viContentColor: UIColor? {
        var viContentColor: UIColor?
        if !Display.pad {
            // PAD上不支持导航栏变色
            viContentColor = ResourceManager.get(key: "suite_skin_vi_content_color", type: "color")
        }
        return viContentColor
    }

    static var titleColor: UIColor {
        if let vicc = viContentColor {
            // 如果有vi色，dark mode下不染vi色
            return vicc & UIColor.ud.textTitle
        }
        return UIColor.ud.textTitle
    }

    static var subTitleColor: UIColor {
        if let vicc = viContentColor {
            // 如果有vi色，dark mode下不染vi色
            return vicc & UIColor.ud.textPlaceholder
        }
        return UIColor.ud.textPlaceholder
    }

    static var buttonTintColor: UIColor {
        if let vicc = viContentColor {
            // 如果有vi色，dark mode下不染vi色
            return vicc & UIColor.ud.iconN1
        }
        return UIColor.ud.iconN1
    }

    static func bgNavibarColor(defaultColor: UIColor = UIColor.ud.bgBody) -> UIColor {
        if let vic = LarkNaviBar.viColor {
            return vic & defaultColor
        }
        return defaultColor
    }
}

public extension LarkNaviBar {
    // interfaces for displaying
    func setPresentation(show: Bool?, animated: Bool) {
        isShown = show ?? !isShown

        if animated {
            UIView.animate(withDuration: 0.25) {
                self.alpha = self.isShown ? 1 : 0
            }
        } else {
            self.alpha = isShown ? 1 : 0
        }
    }

    // interfaces for custom avatar view
    func setCustomAvatarView(_ view: UIView) {
        for subview in avatarContainer.subviews {
            subview.removeFromSuperview()
        }
        avatarContainer.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // interfaces for custom focus view
    func setCustomFocusView(_ view: UIView) {
        for subview in focusContainer.subviews {
            subview.removeFromSuperview()
        }
        let subContainer = UIView()
        subContainer.clipsToBounds = true
        focusContainer.addSubview(subContainer)
        subContainer.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview().inset(10)
            make.height.equalTo(subContainer.snp.width)
        }
        subContainer.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(2)
            make.top.bottom.equalToSuperview()
            make.width.greaterThanOrEqualToSuperview()
        }
    }

    // interfaces for buttons
    func addButton(for type: LarkNaviButtonType, image: UIImage?) {
        guard let image = image else { return }
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(onButtonTapped(sender:)), for: .touchUpInside)
        if let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() {
            if type == .search, let isDefaultSearchButtonDisabled = dataSource?.isDefaultSearchButtonDisabled, isDefaultSearchButtonDisabled{
                button.isHidden = true
            }
        }
        self.addButton(for: type, button: button)
    }

    func addButton(for type: LarkNaviButtonType, button: UIButton) {
        // 统一约束Button大小
        if let buttonDelegate = button as? LarkNaviBarButtonDelegate {
            button.snp.makeConstraints({ (make) in
                make.height.equalTo(Layout.buttonSize)
                make.width.equalTo(buttonDelegate.larkNaviBarButtonWidth())
            })
        } else {
            button.snp.makeConstraints({ (make) in
                make.width.height.equalTo(Layout.buttonSize)
            })
        }

        button.hitTestEdgeInsets = UIEdgeInsets(top: Layout.buttonEdgeInset,
                                                left: Layout.buttonEdgeInset,
                                                bottom: Layout.buttonEdgeInset,
                                                right: Layout.buttonEdgeInset)
        if case .first = type {
            button.accessibilityIdentifier = SpotlightAccessoryIdentifier.navibar_first_button.rawValue
        }

        setButtonTintColor(button, type, default: LarkNaviBar.buttonTintColor)
        buttons[type] = button

        if #available(iOS 13.4, *) {
            button.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (CGSize(width: 44, height: 36), 8)
                }))
        }
        buttonContainer.addArrangedSubview(button)
    }

    // reload
    func reloadNaviBar() {
        let dataSource = self.dataSource
        self.dataSource = dataSource

        let delegate = self.delegate
        self.delegate = delegate
    }

    // provide source view for ipad
    func getTitleTappedSourceView() -> UIView {
        return titleView
    }

    // provide navibar button by type
    func getButtonByType(buttonType: LarkNaviButtonType) -> UIView? {
        return buttons[buttonType]
    }

    func getAvatarContainer() -> UIView {
        return avatarContainer
    }

    func getFocusContainer() -> UIView {
        return focusContainer
    }

    func onAvatarContainerTapped() {
        innerOnAvatarContainerTapped()
    }

    private func setButtonTintColorV2(_ button: UIButton, _ type: LarkNaviButtonTypeV2, default color: UIColor) {
        for state: UIControl.State in [.normal, .highlighted, .disabled, .selected, .focused, .application, .reserved] {
            let customColor = dataSource?.larkNaviBarV2(userDefinedColorOf: type, state: state) ?? color
            if let image = button.image(for: state) {
                button.setImage(image.ud.withTintColor(customColor), for: state)
            }
            if let setButtonTintColorDelegate = button as? LarkNaviBarButtonDelegate {
                setButtonTintColorDelegate.larkNaviBarSetButtonTintColor(color, for: state)
            }
        }
    }

    private func setButtonTintColor(_ button: UIButton, color: UIColor) {
        if let curImage = button.imageView?.image, curImage.renderingMode != .alwaysTemplate {
            button.imageView?.image = curImage.withRenderingMode(.alwaysTemplate)
        }
    }

    func showSideBar(completion: (() -> Void)?) {
        self.sideBarMenu?.showSideBar(avatarView: avatarContainer, completion: completion)
    }

    private func setButtonTintColor(_ button: UIButton, _ type: LarkNaviButtonType, default color: UIColor) {
        for state: UIControl.State in [.normal, .highlighted, .disabled, .selected, .focused, .application, .reserved] {
            let customColor = dataSource?.larkNaviBar(userDefinedColorOf: type, state: state) ?? color
            if let image = button.image(for: state) {
                button.setImage(image.ud.withTintColor(customColor), for: state)
            }
            if let setButtonTintColorDelegate = button as? LarkNaviBarButtonDelegate {
                setButtonTintColorDelegate.larkNaviBarSetButtonTintColor(color, for: state)
            }
        }
    }
}

public final class LarkNaviBar: UIView, NaviBarProtocol, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    /// 用于标记 navbar 是否需要显示头像
    /// iPad 侧栏出现的时候，头像会被添加到 tabbar 上
    public var showAvatarView: Bool = true {
        didSet {
            self.avatarContainer.removeFromSuperview()
            if showAvatarView {
                leftContainer.addSubview(avatarContainer)
                avatarContainer.snp.remakeConstraints { (make) in
                    make.centerY.equalToSuperview()
                    make.size.equalTo(CGSize(width: 36, height: 36)).priority(.required)
                    make.left.equalToSuperview().offset(16)
                }
                self.layoutTitleAndGroup()
            } else {
                self.layoutTitleAndGroup()
            }
        }
    }

    public var isTitleViewArrowFolded: Bool {
        get {
            assert(!useCustomTitleArrowView, "shouldn't call this function since customTitleArrowView exist.")
            return self.titleView.isFolded
        }
        set {
            assert(!useCustomTitleArrowView, "shouldn't call this function since customTitleArrowView exist.")
            self.titleView.isFolded = newValue
        }
    }

    public func setArrowPresentation(folded: Bool?, animated: Bool) {
        if useCustomTitleArrowView { return }
        self.titleView.setArrowPresentation(folded: folded, animated: animated)
    }

    public var avatarKey: PublishSubject<(entityId: String, key: String)> = PublishSubject()
    public var groupNameText: PublishSubject<String> = PublishSubject()
    public var shouldShowGroup: PublishSubject<Bool> = PublishSubject()
    public var avatarShouldNoticeNewVersion: PublishSubject<Bool> = PublishSubject()
    public var avatarInLeanMode: PublishSubject<Bool> = PublishSubject()
    private let accountInfoDisposeBag = DisposeBag()
    public var avatarNewBadgeCount: PublishSubject<Int> = PublishSubject()
    public var avatarDotBadgeShow: PublishSubject<Bool> = PublishSubject()
    public var isNeedShowBadge: Bool = false {
        didSet {
            self.avatarView.isNeedShowBadgeIcon = self.isNeedShowBadge
        }
    }
    public var isShown: Bool

    private var disposeBag: DisposeBag = DisposeBag()

    public weak var delegate: LarkNaviBarDelegate?
    public weak var dataSource: LarkNaviBarDataSource? {
        didSet {
            if let dataSource = self.dataSource, dataSource.isDrawerEnabled {
                sideBarMenu?.addDrawerEdgeGesture(to: dataSource.view)
            }

            self.isHidden = true
            self.isLoading = false

            if let dataSource = dataSource, dataSource.isNaviBarEnabled {
                loadAvatarView(customAvatarView: dataSource.usingCustomAvatarView())
                subscribeDataSource()
                layoutTitleAndGroup()
                setupButtons(with: dataSource)
                self.isHidden = !dataSource.isNaviBarEnabled
                setPresentation(show: dataSource.isNaviBarEnabled, animated: false)
                titleView.setArrowPresentation(folded: true, animated: false)
                // Set focus status view from datasource
                if dataSource.showPad3BarNaviStyle.value == true,
                   let focusView = dataSource.userFocusStatusView() {
                    self.setCustomFocusView(focusView)
                } else {
                    titleView.setFocusView(dataSource.userFocusStatusView())
                }
                let customTitleArrowView = dataSource.customTitleArrowView(titleColor: LarkNaviBar.titleColor)
                self.useCustomTitleArrowView = customTitleArrowView != nil
                titleView.setCustomTitleArrowView(customTitleArrowView)
                var bgColor = dataSource.larkNavibarBgColor() ?? UIColor.ud.bgBody
                bgColor = LarkNaviBar.bgNavibarColor(defaultColor: bgColor)
                self.backgroundColor = bgColor
                self.topMask.backgroundColor = bgColor
            }
        }
    }

    private var useCustomTitleArrowView: Bool = false

    private func isFirstVC(dataSource: LarkNaviBarDataSource?) -> Bool {
        return navigationService.isFirstTab(tab: dataSource?.tabRootViewController?.tab)
    }

    private func setupButtons(with dataSource: LarkNaviBarDataSource) {
        buttonContainer.subviews.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        if let naviButtonView = dataSource.naviButtonView {
            buttonContainer.addSubview(naviButtonView)
            naviButtonView.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
        } else if dataSource.useNaviButtonV2 {
            setupButtonV2(with: dataSource)
        } else {
            setupButton(with: dataSource, for: .search)
            setupButton(with: dataSource, for: .first)
            setupButton(with: dataSource, for: .second)
        }
    }

    private func setupButtonV2(with dataSource: LarkNaviBarDataSource) {
        LarkNaviButtonTypeV2.allCases.forEach {
            // 统一约束Button大小
            if let button = dataSource.larkNaviBarV2(userDefinedButtonOf: $0) {
                if let buttonDelegate = button as? LarkNaviBarButtonDelegate {
                    button.snp.makeConstraints({ (make) in
                        make.height.equalTo(Layout.buttonSize)
                        make.width.equalTo(buttonDelegate.larkNaviBarButtonWidth())
                    })
                } else {
                    button.snp.makeConstraints({ (make) in
                        make.width.height.equalTo(Layout.buttonSize)
                    })
                }

                button.hitTestEdgeInsets = UIEdgeInsets(top: Layout.buttonEdgeInset,
                                                        left: Layout.buttonEdgeInset,
                                                        bottom: Layout.buttonEdgeInset,
                                                        right: Layout.buttonEdgeInset)

                if #available(iOS 13.4, *) {
                    button.lkPointerStyle = PointerStyle(
                        effect: .highlight,
                        shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                            return (CGSize(width: 44, height: 36), 8)
                        }))
                }

                setButtonTintColorV2(button, $0, default: LarkNaviBar.buttonTintColor)
                buttonContainer.addArrangedSubview(button)
            }
        }
    }

    private func setupButton(with dataSource: LarkNaviBarDataSource, for type: LarkNaviButtonType) {
        var isDefaultSearchButtonDisabled: Bool
        if let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() {
            isDefaultSearchButtonDisabled = false
        } else {
            isDefaultSearchButtonDisabled = dataSource.isDefaultSearchButtonDisabled
        }
        if let button = dataSource.larkNaviBar(userDefinedButtonOf: type) {
            addButton(for: type, button: button)
        } else if let image = dataSource.larkNaviBar(imageOfButtonOf: type) {
            addButton(for: type, image: image)
        } else if type == .search && !isDefaultSearchButtonDisabled {
            // Default
            addButton(for: type, image: Resources.LarkNavigation.navibar_button_search)
        }
    }

    private lazy var leftContainer = UIView()

    private lazy var springView = UIView()

    private var avatarContainer: UIView = {
        return UIView()
    }()

    private var focusContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.6)
        view.layer.cornerRadius = 12
        return view
    }()

    public lazy var avatarView: LarkNaviAvatarView = {
        let avatarView = LarkNaviAvatarView()
        if #available(iOS 13.4, *) {
            avatarView.addLKInteraction(PointerInteraction(style: .init(effect: .lift)))
        }
        return avatarView
    }()

    public lazy var titleView: LarkNaviTitleView = {
        return LarkNaviTitleView()
    }()

    private var topMask = UIView()

    private lazy var groupNameLabel: UILabel = {
        let groupNameLabel = UILabel(frame: .zero)
        groupNameLabel.font = UIFont.systemFont(ofSize: 10)
        groupNameLabel.textAlignment = .left
        groupNameLabel.textColor = LarkNaviBar.subTitleColor
        groupNameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        return groupNameLabel
    }()

    private lazy var buttonContainer: UIStackView = {
        let buttonContainer = UIStackView()
        buttonContainer.axis = .horizontal
        buttonContainer.alignment = .center
        buttonContainer.distribution = .fill
        buttonContainer.spacing = 20
        buttonContainer.layoutMargins = UIEdgeInsets(top: -Layout.buttonEdgeInset,
                                                     left: -Layout.buttonEdgeInset,
                                                     bottom: -Layout.buttonEdgeInset,
                                                     right: -Layout.buttonEdgeInset)
        buttonContainer.isLayoutMarginsRelativeArrangement = true
        return buttonContainer
    }()

    private lazy var navigationDependency: NavigationDependency? = {
        return try? self.userResolver.resolve(assert: NavigationDependency.self)
    }()

    private var showGroupEnable: Bool = true
    private let navigationService: NavigationService
    private var passportUserService: PassportUserService?
    private let sideBarMenu: SideBarMenu?
    public init(navigationService: NavigationService, userResolver: UserResolver, sideBarMenu: SideBarMenu?) {
        self.userResolver = userResolver
        self.navigationService = navigationService
        self.passportUserService = try? userResolver.resolve(assert: PassportUserService.self)
        self.sideBarMenu = sideBarMenu
        isShown = true
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgBody

        addSubview(leftContainer)
        addSubview(springView)
        leftContainer.addSubview(avatarContainer)
        leftContainer.addSubview(groupNameLabel)
        leftContainer.addSubview(titleView)
        addSubview(buttonContainer)

        // 遮住X系列刘海
        topMask.backgroundColor = UIColor.ud.bgBody
        addSubview(topMask)
        topMask.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.snp.top)
            make.height.equalTo(60)
        }
        
        if let user = self.passportUserService?.user {
            /// user 里的avatar同步不及时，这里先取 currentAccount，在修改头像时候能及时变更
            let currentAccount = AccountServiceAdapter.shared.currentAccountInfo
            self.avatarView.setAvatar(entityId: user.userID, avatarKey: currentAccount.avatarKey, medalKey: getMedalKey())
        }
        self.groupNameLabel.text = self.passportUserService?.userTenant.localizedTenantName

        layoutViews()

        DispatchQueue.main.async {
            self.avatarKey.asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (entityId, avatarKey) in
                    guard let self = self else { return }
                    self.avatarView.setAvatar(entityId: entityId, avatarKey: avatarKey, medalKey: self.getMedalKey())
                }).disposed(by: self.accountInfoDisposeBag)
            self.groupNameText.asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (groupNameText) in
                    self?.groupNameLabel.text = groupNameText
                }).disposed(by: self.accountInfoDisposeBag)
            self.shouldShowGroup.asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (shouldShowGroup) in
                    self?.showGroupEnable = shouldShowGroup
                    self?.layoutTitleAndGroup()
                }).disposed(by: self.accountInfoDisposeBag)
            self.updateMedal()

            self.avatarShouldNoticeNewVersion.asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (upgrade) in
                    self?.avatarView.props.badge = upgrade ? .icon(BundleResources.LarkNavigation.navibar_avatar_upgrade_icon) : .iconNone
                }).disposed(by: self.accountInfoDisposeBag)

            // 导航栏头像添加红点引导，优先级低于avatarNewBadgeCount
            // 保证combineLast 具有初始值
            let avatarNewBadgeCountOb = self.avatarNewBadgeCount.asObservable().startWith(0)
            let avatarDotBadgeShowOb = self.avatarDotBadgeShow.asObservable().startWith(false)
            Observable.combineLatest(avatarNewBadgeCountOb, avatarDotBadgeShowOb)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (badgeCount, showDotBadge) in
                    var badge: NaviBarAvatarViewBadge = .unknown
                    if badgeCount > 0 {
                        // pm规定一律显示红点
                        badge = .dot(.pin)
                    } else if showDotBadge {
                        badge = .dot(.pin)
                    } else {
                        badge = .dotNone
                    }
                    self?.avatarView.props.badge = badge
                }).disposed(by: self.accountInfoDisposeBag)

            self.avatarInLeanMode.asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {[weak self] (status) in
                    self?.avatarView.setLeanModeStatus(status: status)
                }).disposed(by: self.accountInfoDisposeBag)
        }

        titleView.titleTapArea.addTarget(self, action: #selector(onTitleViewTapped), for: .touchUpInside)
        titleView.titleTapArea.hitTestEdgeInsets = UIEdgeInsets(
            top: Layout.buttonEdgeInset,
            left: 0,
            bottom: Layout.buttonEdgeInset,
            right: Layout.buttonEdgeInset
        )

        tapGesture.addTarget(self, action: #selector(tapGestureAction))
        let avatarContainerTapGesture = UITapGestureRecognizer(target: self, action: #selector(innerOnAvatarContainerTapped))
        avatarContainer.addGestureRecognizer(avatarContainerTapGesture)
    }

    private let tapGesture = UITapGestureRecognizer()

    private func subscribeDataSource() {
        disposeBag = DisposeBag()
        dataSource?.titleText.subscribe(onNext: { [weak self] (title) in
            guard let `self` = self else { return }
            self.titleView.titleText = title
            }).disposed(by: disposeBag)

        dataSource?.needShowTitleArrow.subscribe(onNext: { [weak self] (showArrow) in
            guard let `self` = self else { return }
            self.titleView.isArrowShown = showArrow
            self.titleView.titleTapArea.isEnabled = showArrow
            if showArrow {
                self.leftContainer.removeGestureRecognizer(self.tapGesture)
            } else {
                self.leftContainer.addGestureRecognizer(self.tapGesture)
            }
        }).disposed(by: disposeBag)

        dataSource?.subFilterTitleText.subscribe(onNext: { [weak self] (subFilter) in
            guard let `self` = self else { return }
            self.titleView.subFilterText = subFilter
        }).disposed(by: disposeBag)

        dataSource?.isNaviBarLoading.subscribe(onNext: { [weak self] (isLoading) in
            guard let `self` = self else { return }
            self.isLoading = isLoading
        }).disposed(by: disposeBag)

    }

    private func loadAvatarView(customAvatarView: UIView?) {
        avatarContainer.subviews.forEach { $0.removeFromSuperview() }
        if let customAvatarView = customAvatarView {
            avatarContainer.addSubview(customAvatarView)
            customAvatarView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        } else {
            avatarContainer.addSubview(avatarView)
            avatarView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    private func layoutViews() {
        avatarContainer.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 36, height: 36)).priority(.required)
            make.left.equalToSuperview().offset(16)
        }

        loadAvatarView(customAvatarView: nil)

        leftContainer.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
        }

        springView.snp.makeConstraints { make in
            make.left.equalTo(leftContainer.snp.right)
            make.right.lessThanOrEqualTo(buttonContainer.snp.left).offset(-20)
            make.width.equalTo(999).priority(1)
        }

        titleView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(34)
            make.left.equalTo(avatarContainer.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview()
        }

        buttonContainer.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16 - Layout.buttonEdgeInset)
        }

        self.snp.makeConstraints { (make) in
            make.height.equalTo(LarkNaviBarConsts.naviHeight)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() else { return }
        if buttons.keys.contains(.search), let isDefaultSearchButtonDisabled = dataSource?.isDefaultSearchButtonDisabled, isDefaultSearchButtonDisabled {
            buttons[.search]?.isHidden = self.traitCollection.horizontalSizeClass != .compact
        }
    }

    private func layoutTitleAndGroup() {
        var showGroup = self.showGroupEnable

        // 满足可以显示多租户的条件下，只有第一个Tab显示多租户
        if showGroup {
            showGroup = self.isFirstVC(dataSource: dataSource) == true || self.dataSource?.bizScene == .workplace
        }

        titleView.relayoutSubviews(singleTenantStyle: !showGroup)
        if showGroup {
            titleView.snp.remakeConstraints { (make) in
                make.height.equalTo(18)
                if self.showAvatarView {
                    make.top.equalTo(avatarContainer)
                    make.left.equalTo(avatarContainer.snp.right).offset(8)
                } else {
                    make.top.equalTo(leftContainer.snp.centerY).offset(-16)
                    make.left.equalTo(16)
                }
                make.right.lessThanOrEqualToSuperview()
            }
            groupNameLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(titleView)
                make.top.greaterThanOrEqualTo(titleView.snp.bottom).offset(4)
                make.right.lessThanOrEqualToSuperview()

                if self.showAvatarView {
                    make.bottom.equalTo(avatarContainer).priority(.medium)
                } else {
                    make.bottom.equalToSuperview().offset(-16).priority(.medium)
                }
            }
        } else {
            titleView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.height.equalTo(34)
                if self.showAvatarView {
                    make.left.equalTo(avatarContainer.snp.right).offset(8)
                } else {
                    make.left.equalTo(16)
                }
                make.right.lessThanOrEqualToSuperview()
            }
            groupNameLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(titleView)
                make.height.equalTo(0)
            }
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // is loading animations
    var loadingDotCount = 0
    public var isLoading: Bool = false {
        didSet {
            guard isLoading != oldValue else {
                return
            }
            if isLoading {
                loadingDotCount = 0
                CoreEventMonitor.MainTabLoadingCost.start()
                startLoadingAnimation()
            } else {
                CoreEventMonitor.MainTabLoadingCost.end()
                stopLoadingAnimation()
            }
        }
    }

    @objc
    private func startLoadingAnimation() {
        if isLoading, let currentTitle = dataSource?.titleText.value {
            titleView.isArrowShown = false
            loadingDotCount += 1
            titleView.titleText = currentTitle + String(repeating: ".", count: loadingDotCount % 4)
            perform(#selector(startLoadingAnimation), with: nil, afterDelay: 0.3)
        }
    }

    private func stopLoadingAnimation() {
        titleView.isArrowShown = dataSource?.needShowTitleArrow.value ?? false
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if let currentTitle = dataSource?.titleText.value {
            titleView.titleText = currentTitle
        }
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }

    // implementation for buttons
    private var buttons: [LarkNaviButtonType: UIButton] = [:]

    // delegate implementation
    @objc
    func onButtonTapped(sender: UIButton) {
        for (type, button) in buttons where button == sender {
            delegate?.onButtonTapped(on: button, with: type)
            break
        }
    }

    @objc
    func onTitleViewTapped() {
        guard !isLoading else { return }
        delegate?.onTitleViewTapped()
    }

    @objc
    func tapGestureAction() {
        if dataSource?.showPad3BarNaviStyle.value == true { return }
        innerOnAvatarContainerTapped()
    }

    @objc
    func innerOnAvatarContainerTapped() {
        if dataSource?.isDrawerEnabled == true {
            self.sideBarMenu?.showSideBar(avatarView: avatarContainer, completion: nil)
        }
        delegate?.onDefaultAvatarTapped()
    }

    private func getMedalKey() -> String {
        return (self.navigationService as? NavigationServiceImpl)?.getMedalKey() ?? ""
    }

    private func updateMedal() {
        //传闭包
        (self.navigationService as? NavigationServiceImpl)?.medalUpdate = { [weak self] (entityID, avatarKey, medalKey) in
            guard let self = self else { return }
            self.avatarView.setAvatar(entityId: entityID, avatarKey: avatarKey, medalKey: medalKey)
        }
        //订阅
        (self.navigationService as? NavigationServiceImpl)?.updateMedalAvatar()
    }
}

public final class LarkNaviTitleView: UIControl {
    public var isArrowShown: Bool = false {
        didSet {
            currentTitleArrowView.isHidden = !isArrowShown
        }
    }

    public var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
            titleContainer.setNeedsLayout()
        }
    }

    public var subFilterText: String? {
        didSet {
            subFilterTag.isHidden = subFilterText?.isEmpty ?? true
            subFilterTag.text = subFilterText
        }
    }

    private lazy var contentStack: UIStackView = {
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.distribution = .fill
        container.spacing = 8
//        container.isUserInteractionEnabled = false
        return container
    }()

    lazy var titleTapArea = UIControl()

    private lazy var titleContainer: UIStackView = {
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.distribution = .fill
        container.spacing = 4
        container.isUserInteractionEnabled = false
        return container
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        titleLabel.textColor = LarkNaviBar.titleColor
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return titleLabel
    }()

    private lazy var subFilterTag: PaddingUILabel = {
        let subFilterTag = PaddingUILabel(frame: .zero)
        subFilterTag.paddingLeft = 6
        subFilterTag.paddingRight = 6
        subFilterTag.paddingTop = 2
        subFilterTag.paddingBottom = 2
        subFilterTag.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subFilterTag.layer.cornerRadius = 4
        subFilterTag.layer.masksToBounds = true
        subFilterTag.textAlignment = .center
        subFilterTag.setContentHuggingPriority(.required, for: .horizontal)
        subFilterTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        subFilterTag.color = Style.blue.backColor
        subFilterTag.textColor = Style.blue.textColor
        return subFilterTag
    }()

    private var arrowImageViewInit = false
    private lazy var arrowImageView: UIImageView = {
        arrowImageViewInit = true
        let image = Resources.LarkNavigation.navibar_title_arrow.withRenderingMode(.alwaysTemplate)
        let arrowImageView = UIImageView(image: image)
        arrowImageView.tintColor = LarkNaviBar.buttonTintColor
        arrowImageView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        arrowImageView.setContentHuggingPriority(.required, for: .horizontal)
        arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return arrowImageView
    }()

    public var isFolded: Bool {
        get {
            assert(customTitleArrowView == nil, "shouldn't call this function since customTitleArrowView exist.")
            return _isFolded
        }
        set {
            assert(customTitleArrowView == nil, "shouldn't call this function since customTitleArrowView exist.")
            _isFolded = newValue
        }
    }

    private var _isFolded: Bool = true

    init() {
        super.init(frame: CGRect.zero)
        addSubview(contentStack)
        titleTapArea.addSubview(titleContainer)
        contentStack.addArrangedSubview(titleTapArea)
        titleContainer.addArrangedSubview(titleLabel)
        titleContainer.addArrangedSubview(subFilterTag)
        titleContainer.addArrangedSubview(arrowImageView)
        contentStack.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        titleContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func relayoutSubviews(singleTenantStyle: Bool) {
        if singleTenantStyle {
            titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            subFilterTag.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            subFilterTag.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setArrowPresentation(folded: Bool?, animated: Bool) {
        if customTitleArrowView != nil { return }
        guard arrowImageViewInit else { return }
        _isFolded = folded ?? !_isFolded

        let angle: CGFloat = _isFolded ? (.pi / 2) : -(.pi / 2)
        if animated {
            arrowImageView.transform = CGAffineTransform(rotationAngle: -angle)
            UIView.animate(withDuration: 0.2) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: angle)
            }
        } else {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: angle)
        }
    }

    private var focusView: UIView?

    public func setFocusView(_ focusView: UIView?) {
        self.focusView?.removeFromSuperview()
        self.focusView = nil
        if let view = focusView {
            self.focusView = view
            self.contentStack.addArrangedSubview(view)
        }
    }

    private var currentTitleArrowView: UIView {
        customTitleArrowView ?? arrowImageView
    }

    private var customTitleArrowView: UIView?

    public func setCustomTitleArrowView(_ view: UIView?) {
        self.customTitleArrowView?.removeFromSuperview()
        self.customTitleArrowView = nil
        var spacing: CGFloat = 4 // 默认间距
        if let v = view {
            self.customTitleArrowView = v
            self.titleContainer.addArrangedSubview(v)
            spacing = 6 // 新需求设计师要求
            v.isHidden = !isArrowShown
            arrowImageView.isHidden = true
        }
        self.titleContainer.setCustomSpacing(spacing, after: subFilterTag.isHidden ? titleLabel : subFilterTag)
    }
}
public protocol LarkNaviBarButtonDelegate: AnyObject {
    func larkNaviBarSetButtonTintColor(_ tintColor: UIColor, for state: UIControl.State)
    func larkNaviBarButtonWidth() -> CGFloat
}

public extension LarkNaviBarButtonDelegate {
    func larkNaviBarButtonWidth() -> CGFloat {
        return LarkNaviBar.Layout.buttonSize
    }
}
