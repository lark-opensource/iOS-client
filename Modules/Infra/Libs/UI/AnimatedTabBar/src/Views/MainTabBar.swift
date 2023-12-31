//
//  MainTabBar.swift
//  AnimatedTabBar
//
//  Created by Meng on 2019/9/29.
//

import UIKit
import Foundation
import SnapKit
import LarkInteraction
import LarkExtensions
import LarkTab
import Homeric
import LKCommonsTracker
import FigmaKit
import UniverseDesignTheme
import LarkContainer

protocol MainTabBarDelegate: AnyObject {
    func mainTabBar(_ mainTabBar: MainTabBar, didSelectItem tab: Tab)
    func mainTabBarDidTapMoreButton(_ mainTabBar: MainTabBar)
    func mainTabBar(_ mainTabBar: MainTabBar, didLongPressItem tab: Tab)
}

extension MainTabBar {
    enum Layout {
        static let defaultHeight: CGFloat = 65.0
        static let stackHeight: CGFloat = defaultHeight
        static var tabBarHeight: CGFloat {
            return defaultHeight
        }
        static let bottomOffset: CGFloat = 5.0
    }

    enum Tag {
        static let topBorderTag: Int = 1001
        static let effectViewTag: Int = 1002
    }
}

final class MainTabBar: UITabBar, UserResolverWrapper {
    public let userResolver: UserResolver

    weak var mainTabBarDelegate: MainTabBarDelegate?

    var intrinsicHeight: CGFloat {
        return Layout.defaultHeight
    }

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()

    var tabItems: [AbstractTabBarItem] = [] {
        didSet { setupItemViews() }
    }
    private var itemViews: [MainTabBarItemView] = []

    // UGLY: refactor later.
    var moreItem: AbstractTabBarItem? {
        didSet { moreView?.item = moreItem }
    }

    // 是否显示「更多」tab，目前精简模式下不显示该tab
    private let moreTabEnabled: Bool
    public lazy var moreView: MainTabBarItemView? = {
        guard moreTabEnabled else { return nil }
        let itemView = MainTabBarItemView(userResolver: userResolver)
        itemView.item = moreItem
        itemView.tapArea.addTarget(self, action: #selector(handleTapMoreButton), for: .touchUpInside)
        return itemView
    }()

    init(moreTabEnabled: Bool, translucent: Bool, userResolver: UserResolver) {
        self.userResolver = userResolver
        self.moreTabEnabled = moreTabEnabled
        super.init(frame: .zero)
        self.isTranslucent = translucent
        setupSubviews()
        setupTabBarShadow()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleQuickLaunchWindowWillDismiss),
                                               name: .lkQuickLaunchWindowWillDismiss,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    convenience init(moreTabEnabled: Bool, userResolver: UserResolver) {
        self.init(moreTabEnabled: moreTabEnabled, translucent: false, userResolver: userResolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var fitSize = super.sizeThatFits(size)
        fitSize.height = intrinsicHeight
        fitSize.height += safeAreaInsets.bottom
        return fitSize
    }

    func tabWindowRect(for index: Int) -> CGRect? {
        guard 0..<itemViews.count ~= index else { return nil }
        let itemView = itemViews[index]
        return itemView.convert(itemView.bounds, to: nil)
    }

    func moreTabWindowRect() -> CGRect? {
        if moreView?.superview != nil, let moreView = moreView {
            return moreView.convert(moreView.bounds, to: nil)
        }
        return nil
    }

    /// 通过index切换main tab
    /// index: start from 0
    func switchMainTab(to index: Int) {
        // moreView未加入mainTabViews，而是特化拼接在后面
        if index == itemViews.count {
            guard moreView?.superview != nil, !(moreView?.isHidden ?? true) else { return }
            moreView?.tapArea.sendActions(for: .touchUpInside)
        } else if index >= 0, index < itemViews.count {
            let itemView = itemViews[index]
            itemView.tapArea.sendActions(for: .touchUpInside)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        NotificationCenter.default.post(name: .lkTabbarDidMoveToWindow, object: nil)
    }

    private func setupSubviews() {
        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.defaultHeight)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }

        let topBorder = UIView()
        topBorder.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.trailing.leading.width.equalToSuperview()
            make.height.equalTo(0.5)
            make.top.equalToSuperview().offset(0.2)
        }

        if self.isTranslucent {
            self.backgroundImage = Resources.AnimatedTabBar.bgTabClear
            self.shadowImage = Resources.AnimatedTabBar.bgTabClear
            // add custom blur view
            let visualView = VisualBlurView()
            visualView.fillColor = UIColor.ud.bgFloat
            visualView.fillOpacity = 0.85
            visualView.blurRadius = 40
            visualView.frame = self.bounds
            visualView.autoresizingMask = .flexibleWidth
            self.insertSubview(visualView, at: 0)
            visualView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    private func setupItemViews() {
        // Remove previous item views.
        moreView?.removeFromSuperview()
        itemViews.forEach({ $0.removeFromSuperview() })
        // Re-add item views.
        itemViews = tabItems.enumerated().map({ offset, item in
            let itemView = MainTabBarItemView(userResolver: userResolver)
            itemView.item = item
            itemView.tag = offset
            itemView.tapArea.addTarget(self, action: #selector(handleTapItemView(_:)), for: .touchUpInside)
            itemView.containerHorizontalSizeClass = traitCollection.horizontalSizeClass
            stackView.addArrangedSubview(itemView)
            
            let longPressGes = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(gesture:)))
            longPressGes.minimumPressDuration = 0.5
            longPressGes.numberOfTouchesRequired = 1
            itemView.addGestureRecognizer(longPressGes)
            return itemView
        })
        if let moreView = moreView {
            stackView.addArrangedSubview(moreView)
            moreView.containerHorizontalSizeClass = traitCollection.horizontalSizeClass
        }
    }
    
    func setupTabBarShadow() {
        DispatchQueue.main.async {
            let shadowImage = Resources.AnimatedTabBar.bgTabClear
            #if canImport(CryptoKit)
            //https://stackoverflow.com/questions/58062613/cant-set-tab-bar-shadow-image-in-ios-13
            if !self.isTranslucent {
                if #available(iOS 15, *) {
                    let appearance = self.standardAppearance.copy()
                    appearance.shadowImage = shadowImage
                    appearance.shadowColor = .clear
                    appearance.backgroundColor = UIColor.ud.bgFloat
                    self.standardAppearance = appearance
                    #if swift(>=5.5)
                    self.scrollEdgeAppearance = appearance
                    #endif
                } else if #available(iOS 13, *) {
                    let appearance = self.standardAppearance.copy()
                    appearance.shadowImage = shadowImage
                    appearance.shadowColor = .clear
                    appearance.backgroundColor = UIColor.ud.bgFloat
                    self.standardAppearance = appearance
                } else {
                    self.shadowImage = shadowImage
                    self.backgroundColor = UIColor.ud.bgFloat
                }
            }
            #else
            self.shadowImage = shadowImage
            self.backgroundColor = UIColor.ud.bgFloat
            #endif
            self.layer.masksToBounds = false
        }
    }

    func clearShadow() {
        self.layer.masksToBounds = true
    }

    /// 用于刷新 tabar customView
    func refreshTabbarCustomView() {
        itemViews.forEach({ $0.refreshCustomView() })
    }

    /// 播放更多按钮动画
    func playHideMoreViewAnimation() {
        // 设置缩放比例
        let scaleTransform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        // 动画持续时间
        let duration = 0.3
        // 使用动画缩放视图
        UIView.animate(withDuration: duration, animations: {
            self.moreView?.transform = scaleTransform
        }) { (finished) in
            if finished {
                // 延迟一段时间后恢复原始大小
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.moreView?.transform = CGAffineTransform.identity
                }
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        itemViews.forEach({ itemView in
            itemView.containerHorizontalSizeClass = traitCollection.horizontalSizeClass
        })
        if let moreView = moreView {
            moreView.containerHorizontalSizeClass = traitCollection.horizontalSizeClass
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.subviews
            .filter { $0.isKind(of: NSClassFromString("UITabBarButton")!) }
            .forEach { $0.isHidden = true }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in self.subviews {
            /// 确保在tabbar上的子view能正确响应点击事件，尽管可能超出tabbar的frame
            if CGRectContainsPoint(view.frame, point) {
                return true
            }
        }
        return false
    }
}

// MARK: - TabEventHandler
extension MainTabBar: TabEventHandler {

    func handleTapEvent(for gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: stackView)
        func contains(_ view: MainTabBarItemView, point: CGPoint) -> Bool {
            let convertedPoint = view.tapArea.convert(point, from: stackView)
            return view.tapArea.bounds.contains(convertedPoint)
        }
        // Tap on bar item
        if let targetView = itemViews.first(where: { contains($0, point: location) }) {
            targetView.sendActions(for: .touchUpInside)
        }
        // Tap on more item
        if let moreView = moreView {
            if contains(moreView, point: location) {
                moreView.sendActions(for: .touchUpInside)
            }
        }
    }

    @objc private func handleTapItemView(_ sender: UIControl) {
        guard let itemView = sender.superview as? MainTabBarItemView else { return }
        guard itemView.isEnabled, var tab = itemView.item?.tab else { return }
        // 增加source上报字段
        tab.extra[TabItemClickSource.tabItemSourceKey] = TabItemClickSource.launcherTab.rawValue
        mainTabBarDelegate?.mainTabBar(self, didSelectItem: tab)
        if let tabName = itemView.item?.title {
            Tracker.post(TeaEvent(Homeric.NAVIGATION, params: [
                "navigation_type": 1,
                "tabkey": tabName,
                "position": itemView.tag
            ]))
        }
    }

    @objc private func handleTapMoreButton() {
        mainTabBarDelegate?.mainTabBarDidTapMoreButton(self)
        playHideMoreViewAnimation()
        Tracker.post(TeaEvent(Homeric.NAVIGATION_MAIN_CLICK, params: ["click": "more"]))
    }
    
    @objc private func longPressed(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let itemView = gesture.view as? MainTabBarItemView else { return }
        guard itemView.isEnabled, let tab = itemView.item?.tab else { return }
        mainTabBarDelegate?.mainTabBar(self, didLongPressItem: tab)
    }

    @objc
    private func handleQuickLaunchWindowWillDismiss(notification: Notification) {
        self.moreView?.playIconViewSpringAnimation()
    }
}

extension Notification.Name {
    public static let lkQuickLaunchWindowAddRecommandDidShow = Notification.Name(rawValue: "lkQuickLaunchWindowAddRecommandDidShow")
    public static let lkTabbarDidMoveToWindow = Notification.Name(rawValue: "lkTabbarDidMoveToWindow")
    public static let lkQuickLaunchWindowWillDismiss = Notification.Name(rawValue: "lkQuickLaunchWindowWillDismiss")
}
