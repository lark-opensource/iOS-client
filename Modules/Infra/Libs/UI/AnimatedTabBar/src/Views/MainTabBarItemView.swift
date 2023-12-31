//
//  MainTabBarItemView.swift
//  AnimatedTabBar
//
//  Created by Meng on 2019/10/14.
//

import Foundation
import UIKit
import LarkBadge
import LarkInteraction
import UniverseDesignIcon
import ByteWebImage
import RxSwift
import LKCommonsLogging
import LarkTab
import LarkContainer

extension MainTabBarItemView {
    enum Layout {
        static let iconSize: CGSize = CGSize(width: 22.0, height: 22.0)
        static let gridViewSize: CGSize = .square(28)

        static let height: CGFloat = 44.0
        static let hMargin: CGFloat = 5.0

        static let compactWidth: CGFloat = 48.0

        static let compactIconTop: CGFloat = 5.0
        static let compactTitleTop: CGFloat = 6.0

        static let regularIconLeading: CGFloat = 8.0
        static let regularTitleLeading: CGFloat = 8.0
        static let regularTitleTrailing: CGFloat = 8.0

        static let dotBadgeCenterYOffset: CGFloat = 2.0
        static let dotBadgeLeadingOffset: CGFloat = 8.0
        static let compactBadgeCenterYOffset: CGFloat = 4.0
        static let compactBadgeLeadingOffset: CGFloat = 8.0
        static let regularBadgeCenterYOffset: CGFloat = -1.0
        static let regularBadgeLeadingOffset: CGFloat = 10.0
    }
    enum Style {
        static let compactTitleFont: UIFont = UIFont.systemFont(ofSize: 10.0)
        static let regularTitleFont: UIFont = UIFont.systemFont(ofSize: 10.0)
    }
}

final class MainTabBarItemView: UIControl, UserResolverWrapper {
    public let userResolver: UserResolver

    static let logger = Logger.log(MainTabBarItemView.self, category: "AnimatedTabBar.MainTabBarItemView")

    private let disposeBag = DisposeBag()

    private let isCustomViewEnabled: Bool

    // The area that respond to tap event.
    lazy var tapArea: UIControl = UIControl()

    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        return stack
    }()

    // 用来承接右上角的红点
    private let iconContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = Style.regularTitleFont
        label.textAlignment = .center
        return label
    }()

    func configure(icon: UIImage?, text: String, iconInfo: TabCandidate.TabIcon? = nil) {
        if let icon = icon {
            iconView.layer.cornerRadius = 0.0
            iconView.clipsToBounds = false
            iconView.image = icon
        } else {
            iconView.layer.cornerRadius = 5.0
            iconView.clipsToBounds = true
            // 新版编辑页面已经不会走到下面的逻辑，等FG全量后这个configure方法可以彻底删除了
            let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
            iconView.image = placeHolder
        }
        titleLabel.text = text
    }

    var item: AbstractTabBarItem? {
        didSet {
            oldValue?.remove(delegate: self)
            item?.add(delegate: self)
            refreshAll()
        }
    }

    var containerHorizontalSizeClass: UIUserInterfaceSizeClass = .compact {
        didSet { remakeForCurrentContainerSizeClass() }
    }

    override var isEnabled: Bool {
        didSet {
            iconView.alpha = isEnabled ? 1.0 : 0.5
            titleLabel.alpha = isEnabled ? 1.0 : 0.5
        }
    }

    init(enableCustomView: Bool = true, userResolver: UserResolver) {
        self.userResolver = userResolver
        self.isCustomViewEnabled = enableCustomView
        super.init(frame: .zero)

        addSubview(tapArea)
        tapArea.snp.makeConstraints { make in
            make.center.height.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.width.equalTo(tapArea.snp.height).priority(.low)
        }

        tapArea.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        // iconContainerView用来承接右上角的红点，所以需要把iconView再包一下
        stack.addArrangedSubview(iconContainerView)
        iconContainerView.snp.remakeConstraints { (make) in
            make.size.equalTo(Layout.iconSize)
        }
        // 用iconContainerView把iconView包一下
        iconContainerView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalToSuperview()
        }
        stack.addArrangedSubview(titleLabel)

        stack.bringSubviewToFront(iconView)

        remakeForCurrentContainerSizeClass()

        addDownloadTabIconObserver()

        if #available(iOS 13.4, *) {
            let action = PointerInteraction(
                style: PointerStyle(effect: .highlight, shape: .roundedFrame({(interaction, _) -> (CGRect, CGFloat) in
                    guard let view = interaction.view else { return (.zero, 0) }
                    return (CGRect(x: view.frame.origin.x - 2, y: 8, width: view.bounds.width + 4, height: view.bounds.height), 8)
                })))
            tapArea.addLKInteraction(action)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MainTabBarItemView: TabBarItemDelegate {
    func refreshAll() {
        guard let item = item else { return }
        tabBarItemDidChangeAppearance(item)
        tabBarItemDidUpdateBadge(type: item.badgeType, style: item.badgeStyle)
        tabBarItemDidAddCustomView(item)
        // 重建 view 之后，需要将 selected 状态同步到 view 上
        item.isSelected ? item.selectedState() : item.deselectedState()
    }

    /// 刷新当前 tab customView
    func refreshCustomView() {
        guard let item = item else { return }
        tabBarItemDidAddCustomView(item)
    }

    func tabBarItemDidChangeAppearance(_ item: AbstractTabBarItem) {
        titleLabel.text = item.title
        var needSelect = item.isSelected
        if item.tab.isCustomType() && item.tab.openMode == .pushMode {
            // 如果是用户自定义类型并且用push方式打开的，那么就没有选中状态
            needSelect = false
        } else if item.tab.appType == .appTypeURL {
            // 如果是url类型都是用push方式打开的，那么就没有选中状态
            needSelect = false
        }
        titleLabel.textColor = needSelect ?
        item.stateConfig.selectedTitleColor :
        item.stateConfig.defaultTitleColor
        // 手动添加的Item，icon增加圆角
        let isCustomType = item.tab.isCustomType()
        iconView.layer.cornerRadius = isCustomType ? 5.0 : 0.0
        iconView.clipsToBounds = isCustomType
        // 统一处理各种类型的图标
        self.reloadTabIcon(item)

        accessibilityIdentifier = item.accessoryIdentifier
    }

    func tabBarItemDidUpdateBadge(type: LarkBadge.BadgeType, style: LarkBadge.BadgeStyle) {
        if iconContainerView.uiBadge.badgeView == nil { iconContainerView.uiBadge.addBadge(type: .none) }
        iconContainerView.uiBadge.badgeView?.type = type
        iconContainerView.uiBadge.badgeView?.style = style
    }

    func tabBarItemDidAddCustomView(_ item: AbstractTabBarItem) {
        guard isCustomViewEnabled else {
            // QuickLaunchWindow底下那个假的TabBar也需要使用日历控件，因为不能同时加在两个view上，所以用截图的方式来实现
            if item.tab.key == Tab.calendar.key, let customView = item.customView, let image = customView.getScreenShotImage(), let grayImage = UIImage.transformToGrayImage(image)  {
                iconView.image = grayImage
            }
            return
        }
        guard let customView = item.customView else { return }
        if customView.superview !== iconView {
            customView.removeFromSuperview()
            customView.snp.removeConstraints()
            iconView.addSubview(customView)
            iconView.sendSubviewToBack(customView)
        }
        var customViewSize = Layout.iconSize
        if item.tab == Tab.more {
            customViewSize = Layout.gridViewSize
        }
        customView.snp.remakeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(customViewSize)
        }
        iconView.image = nil
    }

    func selectedUserEvent(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {
        let isCustomType = item.tab.isCustomType()
        guard isCustomType == false else {
            return
        }
        itemState.selectedUserEvent(icon: iconView, title: titleLabel, config: item.stateConfig)
    }

    func selectedState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {
        self.isSelected = true
        let isCustomType = item.tab.isCustomType()
        guard isCustomType == false else {
            return
        }
        itemState.selectedState(icon: iconView, title: titleLabel, config: item.stateConfig)
    }

    func deselectState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {
        self.isSelected = false
        let isCustomType = item.tab.isCustomType()
        guard isCustomType == false else {
            return
        }
        itemState.deselectState(icon: iconView, title: titleLabel, config: item.stateConfig)
    }

    // TabIcon对应的图片下载成功通知
    // nolint: duplicated_code - 非重复代码
    func addDownloadTabIconObserver() {
        // 企业自定义表情图片下载成功通知
        NotificationCenter
            .default
            .rx
            .notification(.LKTabDownloadIconSucceedNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (notification) in
                guard let `self` = self else { return }
                guard let notificationInfo = notification.object as? [String: Any] else { return }
                if let uniqueId = notificationInfo["uniqueId"] as? String {
                    Self.logger.info("<NAVIGATION_BAR> tab: uniqueId = \(uniqueId) download image succeed, reload data")
                    if let item = self.item, let tabId = item.tab.uniqueId, tabId == uniqueId {
                        // 根据uniqueId只更新自己的图标
                        self.reloadTabIcon(item)
                    }
                    if let item = self.item, item.tab == Tab.more, let gridView = item.customView as? TabMoreGridView {
                        gridView.reloadData()
                    }
                }
            }).disposed(by: self.disposeBag)
    }

    // 根据数据模型更新Tab图标
    func reloadTabIcon(_ item: AbstractTabBarItem) {
        // 如果存在自定义customView的话不用设置iconView的图片
        if let _ = item.customView, isCustomViewEnabled {
            return
        }
        // 打底图
        let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
        // 图片的话直接从数据源里面拿，数据源会保证里面图片的异步更新
        var needSelect = item.isSelected
        if item.tab.isCustomType() && item.tab.openMode == .pushMode {
            // 如果是用户自定义类型并且用push方式打开的，那么就没有选中状态
            needSelect = false
        } else if item.tab.appType == .appTypeURL {
            // 如果是url类型都是用push方式打开的，那么就没有选中状态
            needSelect = false
        }
        let image = needSelect ? item.stateConfig.selectedIcon : item.stateConfig.defaultIcon
        iconView.image = image ?? placeHolder
        iconView.highlightedImage = item.stateConfig.selectedIcon ?? placeHolder
    }

    // 播放iconView的旋转动画
    func playIconViewRotationAnimation(rotationAngle: CGFloat) {
        // 动画持续时间
        let duration = 0.5
        UIView.animate(withDuration: duration, animations: {
            self.iconView.transform = CGAffineTransformMakeRotation(rotationAngle)
        }) { (finished) in
            if finished {
                // 延迟一段时间后恢复原始大小
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.iconView.transform = CGAffineTransform.identity
                }
            }
        }
    }

    // 播放iconView的弹簧动画
    func playIconViewSpringAnimation() {
        // 将 UIView 缩小到原来的一半大小
        self.iconView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        self.iconView.alpha = 0.8
        // 放大动画
        UIView.animate(withDuration: 0.3, animations: {
            self.iconView.transform = CGAffineTransform.identity
            self.iconView.alpha = 1
        })
    }

    func setIconViewRotationAngle(angle: CGFloat) {
        self.iconView.transform = CGAffineTransformMakeRotation(angle)
    }
}

// MARK: - layout

extension MainTabBarItemView {

    func remakeForCurrentContainerSizeClass() {
        titleLabel.font = Style.compactTitleFont
        stack.axis = .vertical
        stack.spacing = Layout.compactTitleTop

        /// 暂时不使用横版的布局，因为发现在 push 的时候，traitCollection 会发生变化，从 regular 变成 compact，
        /// 因此造成 ItemView 闪动。此处修改范围较大，留作后期优化。
        /*
        if containerHorizontalSizeClass == .regular {
            titleLabel.font = Style.regularTitleFont
            container.axis = .horizontal
            container.spacing = Layout.regularTitleLeading
        } else {
            titleLabel.font = Style.compactTitleFont
            container.axis = .vertical
            container.spacing = Layout.compactTitleTop
        }
        */
    }
}
