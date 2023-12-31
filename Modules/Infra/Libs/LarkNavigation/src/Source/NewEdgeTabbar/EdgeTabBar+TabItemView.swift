//
//  EdgeTabBar+TabItemView.swift
//  LarkNavigation
//
//  Created by Yaoguoguo on 2023/6/21.
//

import UIKit
import Foundation
import LarkBadge
import AnimatedTabBar
import LarkInteraction
import UniverseDesignIcon
import ByteWebImage
import RxSwift
import LarkTab
import LKCommonsLogging

final class NewEdgeTabView: UIView {
    static let logger = Logger.log(NewEdgeTabView.self, category: "LarkNavigation.NewEdgeTabView")

    private let disposeBag = DisposeBag()

    enum Layout {
        static var vMargin: CGFloat { 10 }
        static var iconSize: CGSize { .square(20) }
        static var gridViewSize: CGSize { .square(28) }
        static var iconRadius: CGFloat { 5 }
        static var zeroFloat: CGFloat { 0 }
        static var iconTitleSpacing: CGFloat { 4 }
        static var labelPadding: CGFloat { 4 }
        static var closeRadius: CGFloat { 6 }
        static var closeSize: CGSize { .square(24) }
        static var closeIconSize: CGSize { .square(18) }
        static var moreTitleSize: CGSize { CGSize(width: 56, height: 18) }
        static var titleSize: CGSize { CGSize(width: 56, height: 16) }

        static func getHeightBy(_ tabbarLayoutStyle: EdgeTabBarLayoutStyle) -> CGFloat {
            switch tabbarLayoutStyle {
            case .horizontal:
                return 44
            case .vertical:
                return 64
            }
        }
    }

    enum Style {
        static let titleFont: UIFont = UIFont.systemFont(ofSize: 10)
        static let titleHorizontalFont: UIFont = UIFont.systemFont(ofSize: 16)
        static let titleSelectedFont: UIFont = UIFont.boldSystemFont(ofSize: 10)
        static let titleHorizontalSelectedFont: UIFont = UIFont.boldSystemFont(ofSize: 16)
    }

    lazy var iconContainView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Style.titleFont
        label.textAlignment = .center
        return label
    }()

    lazy var horizontalLabel: UILabel = {
        let label = UILabel()
        label.font = Style.titleHorizontalFont
        label.textAlignment = .left
        return label
    }()

    lazy var badgeView: BadgeView = {
        let badgeView = BadgeView(with: .none)
        badgeView.setMaxNumber(to: 999)
        badgeView.isHidden = true
        return badgeView
    }()

    lazy var closeIcon: UIImageView = {
        let iconColor = UIColor.ud.iconN2
        let image = UDIcon.getContextMenuIconBy(key: .closeBoldOutlined, iconColor: iconColor).ud.resized(to: Self.Layout.closeIconSize)
        let closeIcon = UIImageView(image: image)
        closeIcon.contentMode = .center
        closeIcon.layer.cornerRadius = Self.Layout.closeRadius
        closeIcon.isHidden = true
        if #available(iOS 13.4, *) {
            let info: PointerInfo = .hover
            let style = info.style
            let pointer = PointerInteraction(style: style)
            closeIcon.addLKInteraction(pointer)
        }
        return closeIcon
    }()

    var isEnabled: Bool = false {
        didSet {
            iconView.alpha = isEnabled ? 1.0 : 0.5
            titleLabel.alpha = isEnabled ? 1.0 : 0.5
            horizontalLabel.alpha = isEnabled ? 1.0 : 0.5
        }
    }

    var canclose: Bool = false {
        didSet {
            print(1)
        }
    }

    var closeCallback: ((AbstractTabBarItem?) -> Void)?

    var item: AbstractTabBarItem? {
        didSet {
            oldValue?.remove(delegate: self)
            item?.add(delegate: self)
            refreshAll()
        }
    }

    weak var delegate: TabBarItemDelegate?

    var layoutProgress: CGFloat = 0 {
        didSet {
            self.updateStyle()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(iconContainView)
        iconContainView.addSubview(iconView)
        self.addSubview(titleLabel)
        self.addSubview(badgeView)
        self.addSubview(closeIcon)
        self.addSubview(horizontalLabel)

        iconContainView.uiBadge.addBadge(type: .label(.number(0)))
        closeIcon.lu.addTapGestureRecognizer(action: #selector(close), target: self, touchNumber: 1)
        if #available(iOS 13.0, *) {
            let hover = UIHoverGestureRecognizer(target: self, action: #selector(hovering(_:)))
            self.addGestureRecognizer(hover)

            let iconHover = UIHoverGestureRecognizer(target: self, action: #selector(iconHovering(_:)))
            closeIcon.addGestureRecognizer(iconHover)
        }
        self.updateStyle()
        addDownloadTabIconObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if self.layoutProgress < 1, !closeIcon.isHidden {
            updateClose(show: false)
        }
        updateUI()
    }

    @objc
    private func close() {
        guard let item = self.item else { return }
        self.closeCallback?(item)
    }

    @available(iOS 13.0, *)
    @objc
    func hovering(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            updateClose(show: true)
        case .ended:
            if !(self.item?.isSelected ?? false) {
                updateClose(show: false)
            }
        default:
            if !(self.item?.isSelected ?? false) {
                updateClose(show: false)
            }
        }
    }

    @available(iOS 13.0, *)
    @objc
    func iconHovering(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            closeIcon.backgroundColor = .ud.fillHover
        case .ended:
            closeIcon.backgroundColor = .clear
        default:
            closeIcon.backgroundColor = .clear
        }
    }

    private func updateClose(show: Bool) {
        guard let item = self.item,
              canclose,
              self.layoutProgress == 1,
              item.tab.isCustomType() else {
            closeIcon.isHidden = true
            return
        }
        closeIcon.backgroundColor = .clear
        closeIcon.isHidden = !show

        var badgeSize = BadgeView.computeSize(for: badgeView.type, style: badgeView.style, maxNumber: 999)

        var sizeWidth = badgeSize.width
        if !closeIcon.isHidden {
            sizeWidth = closeIcon.frame.size.width + badgeSize.width + (badgeSize.width == 0 ? 0 : 8)
        }
        horizontalLabel.frame.size = CGSize(width: 166 - sizeWidth - 8, height: 22)
    }

    private func updateStyle() {
        if self.layoutProgress < 1 {
            updateClose(show: false)
        } else {
            updateClose(show: (self.item?.isSelected ?? true))
        }
        updateUI()

        removeExistedPointers()
        if #available(iOS 13.4, *), !(self.item?.isSelected ?? true) {
            let info: PointerInfo = .hover
            let style = info.style
            let pointer = PointerInteraction(style: style)
            self.addLKInteraction(pointer)
        }
    }

    private func refreshAll() {
        guard let item = item else { return }
        tabBarItemDidChangeAppearance(item)
        tabBarItemDidUpdateBadge(type: item.badgeType, style: item.badgeStyle)
        tabBarItemDidAddCustomView(item)
        // 重建 view 之后，需要将 selected 状态同步到 view 上
        item.isSelected ? item.selectedState() : item.deselectedState()
        self.updateStyle()

        if item.tab.isCustomType() && item.tab != Tab.more {
            iconView.layer.cornerRadius = Layout.iconRadius
            iconView.clipsToBounds = true
            iconView.layer.masksToBounds = true
            iconView.contentMode = .scaleToFill
        } else {
            iconView.layer.cornerRadius = Layout.zeroFloat
            iconView.clipsToBounds = false
            iconView.layer.masksToBounds = false
            iconView.contentMode = .scaleAspectFit
        }
    }

    func refreshCustomView() {
        guard let item = item else { return }
        tabBarItemDidAddCustomView(item)
    }
}

extension NewEdgeTabView {
    func updateUI() {
        let horizontalAlpha = max(0, min(1, (layoutProgress - 0.5) * 2))
        let verticalAlpha = max(0, min(1, -(layoutProgress - 0.5) * 2))

        iconContainView.frame.origin.y = 12 - 4 * verticalAlpha
        iconContainView.frame.origin.x = 10 + 6 * verticalAlpha
        iconContainView.frame.size = Layout.iconSize
        iconView.frame = iconContainView.bounds
        iconContainView.uiBadge.badgeView?.alpha = verticalAlpha

        titleLabel.frame.centerX = iconContainView.frame.centerX
        if item?.tab == Tab.more {
            titleLabel.frame.origin.y = iconContainView.frame.maxY + 8
            titleLabel.frame.size = Layout.moreTitleSize
        } else {
            titleLabel.frame.origin.y = iconContainView.frame.maxY + 4
            titleLabel.frame.size = Layout.titleSize
        }
        titleLabel.textAlignment = .center
        titleLabel.alpha = verticalAlpha

        closeIcon.frame.size = Layout.closeSize
        closeIcon.frame.centerY = iconContainView.frame.centerY
        closeIcon.frame.origin.x = self.frame.width - 6 - Layout.closeSize.width

        var badgeSize = BadgeView.computeSize(for: badgeView.type, style: badgeView.style, maxNumber: 999)
        var badgeX = self.frame.width - 8 - badgeSize.width

        var sizeWidth = badgeSize.width
        if !closeIcon.isHidden {
            sizeWidth = closeIcon.frame.size.width + badgeSize.width + (badgeSize.width == 0 ? 0 : 8)
            badgeX = self.frame.width - 8 - badgeSize.width - closeIcon.frame.size.width - 8
        }

        badgeView.frame = CGRect(x: badgeX, y: iconContainView.frame.minY, width: badgeSize.width, height: badgeSize.height)
        badgeView.frame.centerY = iconContainView.frame.centerY
        badgeView.alpha = horizontalAlpha

        horizontalLabel.frame.size = CGSize(width: 166 - sizeWidth - 8, height: 22)
        horizontalLabel.frame.origin = CGPoint(x: iconContainView.frame.maxX + 10, y: 11)
        horizontalLabel.alpha = horizontalAlpha
    }
}

extension NewEdgeTabView: TabBarItemDelegate {

    func tabBarItemDidChangeAppearance(_ item: AbstractTabBarItem) {
        titleLabel.text = item.title
        horizontalLabel.text = item.title
        let textColor = item.isSelected ? item.stateConfig.selectedTitleColor : item.stateConfig.defaultTitleColor
        horizontalLabel.textColor = textColor
        titleLabel.textColor = textColor
        titleLabel.font = item.isSelected ? Style.titleSelectedFont : Style.titleFont
        horizontalLabel.font = item.isSelected ? Style.titleHorizontalSelectedFont : Style.titleHorizontalFont
        accessibilityIdentifier = item.accessoryIdentifier
        // 统一处理各种类型的图标
        reloadTabIcon(item)
        self.delegate?.tabBarItemDidChangeAppearance(item)
    }

    func tabBarItemDidUpdateBadge(type: LarkBadge.BadgeType, style: BadgeStyle) {
        self.iconContainView.uiBadge.badgeView?.type = type
        self.iconContainView.uiBadge.badgeView?.style = style
        self.badgeView.type = type
        self.badgeView.style = style
        self.delegate?.tabBarItemDidUpdateBadge(type: type, style: style)
    }

    func tabBarItemDidAddCustomView(_ item: AbstractTabBarItem) {
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
        self.delegate?.tabBarItemDidAddCustomView(item)
    }

    func selectedUserEvent(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {
        itemState.selectedUserEvent(icon: iconView, title: titleLabel, config: item.stateConfig)
        reloadTabIcon(item)
        titleLabel.font = item.isSelected ? Style.titleSelectedFont : Style.titleFont
        horizontalLabel.font = item.isSelected ? Style.titleHorizontalSelectedFont : Style.titleHorizontalFont
        self.delegate?.selectedUserEvent(item, itemState: itemState)
    }

    func selectedState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {
        itemState.selectedState(icon: iconView, title: titleLabel, config: item.stateConfig)
        updateStyle()
        reloadTabIcon(item)
        titleLabel.font = item.isSelected ? Style.titleSelectedFont : Style.titleFont
        horizontalLabel.font = item.isSelected ? Style.titleHorizontalSelectedFont : Style.titleHorizontalFont
        self.delegate?.selectedState(item, itemState: itemState)
    }

    func deselectState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {
        itemState.deselectState(icon: iconView, title: titleLabel, config: item.stateConfig)
        updateStyle()
        reloadTabIcon(item)
        titleLabel.font = item.isSelected ? Style.titleSelectedFont : Style.titleFont
        horizontalLabel.font = item.isSelected ? Style.titleHorizontalSelectedFont : Style.titleHorizontalFont
        self.delegate?.deselectState(item, itemState: itemState)
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
        // 文本颜色也要更新下
        let textColor = item.isSelected ? item.stateConfig.selectedTitleColor : item.stateConfig.defaultTitleColor
        horizontalLabel.textColor = textColor
        // 如果存在自定义customView的话不用设置iconView的图片
        if let _ = item.customView {
            return
        }
        // 打底图
        let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
        // 图片的话直接从数据源里面拿，数据源会保证里面图片的异步更新
        var image = item.isSelected ? item.stateConfig.selectedIcon : item.stateConfig.defaultIcon
        if item.tab.isCustomType() {
            image = item.stateConfig.selectedIcon
        }
        iconView.image = image ?? placeHolder
        iconView.highlightedImage = item.stateConfig.selectedIcon ?? placeHolder
    }
}
