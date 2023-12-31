//
//  QuickLaunchTabBar.swift
//  AnimatedTabBar
//
//  Created by Hayden on 2023/5/9.
//

import UIKit
import FigmaKit
import Homeric
import LarkTab
import LKCommonsTracker
import LarkContainer

protocol QuickLaunchTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: QuickLaunchTabBar, didSelectItem tab: Tab)
    func tabBar(_ tabBar: QuickLaunchTabBar, didLongPressItem tab: Tab)
    func tabBarDidTapMoreButton(_ tabBar: QuickLaunchTabBar)
}

/// 一个轻量化的 `MainTabBar`，方便用来做动画，和 `MainTabBar` 使用相同类型的数据。
/// - NOTE: `MainTabBar` 由于继承自 `UITabBar`，用来做动画比较重，所以创建一个几乎一模一样的 `QuickLaunchTabBar`。
final class QuickLaunchTabBar: UIView, UserResolverWrapper {
    public let userResolver: UserResolver

    weak var delegate: QuickLaunchTabBarDelegate?

    var intrinsicHeight: CGFloat {
        return MainTabBar.Layout.defaultHeight
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
    private lazy var moreView: MainTabBarItemView? = {
        guard moreTabEnabled else { return nil }
        let itemView = MainTabBarItemView(userResolver: userResolver)
        itemView.item = moreItem
        itemView.tapArea.addTarget(self, action: #selector(handleTapMoreButton), for: .touchUpInside)
        return itemView
    }()

    init(moreTabEnabled: Bool, 
         userResolver: UserResolver) {
        self.userResolver = userResolver
        self.moreTabEnabled = moreTabEnabled
        super.init(frame: .zero)
        setupSubviews()
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
    }

    private func setupSubviews() {
        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(MainTabBar.Layout.defaultHeight)
            make.centerY.equalToSuperview()
        }

        // add custom blur view
//        let visualView = VisualBlurView()
//        visualView.fillColor = UIColor.ud.bgFloatBase
//        visualView.fillOpacity = 0.7
//        visualView.blurRadius = 80
//        visualView.frame = self.bounds
//        visualView.autoresizingMask = .flexibleWidth
//        self.insertSubview(visualView, at: 0)
//        visualView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
    }

    // nolint: duplicated_code - 新实现
    private func setupItemViews() {
        // Remove previous item views.
        moreView?.removeFromSuperview()
        itemViews.forEach({ $0.removeFromSuperview() })
        // Re-add item views.
        itemViews = tabItems.enumerated().map({ offset, item in
            item.isSelected = false
            let itemView = MainTabBarItemView(enableCustomView: false, userResolver: userResolver)
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

    /// 用于刷新 tabar customView
    func refreshTabbarCustomView() {
        itemViews.forEach({ $0.refreshCustomView() })
    }

    func playShowAnimation() {
        // 设置旋转角度
        let pi = -3.14
        let rotationAngle: CGFloat = pi / 2
        self.moreView?.playIconViewRotationAnimation(rotationAngle: rotationAngle)
    }

    func playDismissAnimation() {
        // 设置旋转角度
        let pi = 3.14
        let rotationAngle: CGFloat = pi / 2
        self.moreView?.playIconViewRotationAnimation(rotationAngle: rotationAngle)
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

    //swiftlint:disable all
    override func layoutSubviews() {
        super.layoutSubviews()
        self.subviews
            .filter {
                guard let className = NSClassFromString("UITabBarButton") else {
                    return false
                }
                return $0.isKind(of: className)
            }
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
extension QuickLaunchTabBar: TabEventHandler {

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
        guard itemView.isEnabled, let tab = itemView.item?.tab else { return }
        delegate?.tabBar(self, didSelectItem: tab)
        if let tabName = itemView.item?.title {
            Tracker.post(TeaEvent(Homeric.NAVIGATION, params: [
                "navigation_type": 1,
                "tabkey": tabName,
                "position": itemView.tag
            ]))
        }
    }

    @objc private func handleTapMoreButton() {
        delegate?.tabBarDidTapMoreButton(self)
    }

    @objc private func longPressed(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let itemView = gesture.view as? MainTabBarItemView else { return }
        guard itemView.isEnabled, let tab = itemView.item?.tab else { return }
        delegate?.tabBar(self, didLongPressItem: tab)
    }
}
