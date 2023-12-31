//
//  QuickTabBarItemView.swift
//  AnimatedTabBar
//
//  Created by Meng on 2019/10/15.
//

import Foundation
import UIKit
import LarkBadge
import LarkInteraction
import FigmaKit
import UniverseDesignIcon
import ByteWebImage
import RxSwift
import LarkTab
import LKCommonsLogging
import LarkContainer
import LarkSetting

extension QuickTabBarItemView {
    static let logger = Logger.log(QuickTabBarItemView.self, category: "Module.AnimatedTabBar")
    
    public enum Layout {
        static let iconSize: CGSize = CGSize(width: 48.0, height: 48.0)
        static let gridViewSize: CGSize = CGSize(width: 32.0, height: 32.0)
        static let iconImageSize: CGSize = CGSize(width: 28.0, height: 28.0)
        static let mainTabBarIconImageSize: CGSize = CGSize(width: 22.0, height: 22.0)
        public static let hSpacing: CGFloat = 8
        public static let mainTabBarHSpacing: CGFloat = 12.5
        public static let bottomSpacing: CGFloat = 4
        static let iconCornerRadius: CGFloat = 12
    }
    private enum Style {
        static let defaultTitleFont: UIFont = UIFont.systemFont(ofSize: 12.0)
        static let regularTitleFont: UIFont = UIFont.systemFont(ofSize: 10.0)
        static let defaultTitleColor: UIColor = UIColor.ud.textTitle
        static let iconBackgoundColor = UIColor.ud.N900.withAlphaComponent(0.05)
    }
}

public enum QuickItemEditEventType {
    // PM说之后还会扩展更多操作，所以设计成枚举类型，目前只有删除事件
    case delete(itemView: QuickTabBarItemView) // 删除该导航应用
}

public class QuickTabBarItemView: UICollectionViewCell {
    private var userResolver: UserResolver?
    private var editEvent: ((QuickItemEditEventType) -> Void)?
    private var canEdit: Bool = false   // 是否可以编辑
    public let iconContainerView = UIView(frame: .zero)  // 用来承接右上角的红点
    private let iconRootView = SquircleView(frame: .zero) // 膨胀矩形 灰色背景
    public let iconView = UIImageView(frame: .zero) // 图标
    private let deleteIconView = UIImageView(frame: .zero) // 删除图标
    private let deleteButton: UIButton = UIButton() // 删除按钮
    private let titleLabel = UILabel(frame: .zero)
    public var isInMainTabBar = false   // 是否位于主导航（为了统一处理这个控件可以位于快捷和主导航区域）
    public var isShowBadge = true   // 是否展示Badge，默认展示
    private let disposeBag = DisposeBag()

    private var mainTabBarIconSize: CGSize {
        if let item = self.item, item.tab == Tab.more {
            return Layout.gridViewSize
        }
        return CGSize(width: 22.0, height: 22.0)
    }

    public var item: AbstractTabBarItem? {
        didSet {
            oldValue?.remove(delegate: self)
            item?.add(delegate: self)
            refreshAll()
        }
    }

    public var navigationConfig: [String: Any]? {
        return try? self.userResolver?.resolve(assert: SettingService.self).setting(with: UserSettingKey.make(userKeyLiteral: "navigation_config"))
    }

    private var disableIconStyle: Bool {
        return self.userResolver?.fg.dynamicFeatureGatingValue(with: "lark.navigation.disable.quickiconstyle") ?? false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        addDownloadTabIconObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layout()
    }
    
    public func layout() {
        var x = (self.bounds.width - Layout.iconSize.width) / 2
        if isInMainTabBar {
            x = (self.bounds.width - mainTabBarIconSize.width) / 2
        }
        var y = Layout.hSpacing
        if isInMainTabBar {
            y = Layout.mainTabBarHSpacing
        }
        var width = Layout.iconSize.width
        var height = Layout.iconSize.height
        if isInMainTabBar {
            width = mainTabBarIconSize.width
            height = mainTabBarIconSize.height
        }
        iconContainerView.frame = CGRect(x: x, y: y, width: width, height: height)
        iconRootView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        var iconImageWidth = Layout.iconImageSize.width
        var iconImageHeight = Layout.iconImageSize.height
        if isInMainTabBar {
            iconImageWidth = mainTabBarIconSize.width
            iconImageHeight = mainTabBarIconSize.height
        }
        var isAS = false
        if let key = item?.tab.key, key == Tab.asKey {
            isAS = true
        }
        if !isAS && self.isLogoIconNeedTiled() {
            // 图标平铺
            iconView.frame = iconRootView.bounds
        } else {
            // 图标居中
            x = (iconRootView.bounds.width - iconImageWidth) / 2
            y = (iconRootView.bounds.height - iconImageHeight) / 2
            width = iconImageWidth
            height = iconImageHeight
            iconView.frame = CGRect(x: x, y: y, width: width, height: height)
        }
        x = 0.0
        y = iconContainerView.frame.bottom + Layout.hSpacing
        width = self.bounds.width
        if isInMainTabBar {
            height = 12
            y = self.bounds.height - Layout.mainTabBarHSpacing - height
        } else {
            let calSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            let calHeight = titleLabel.sizeThatFits(calSize).height
            height = calHeight
        }
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.frame =  CGRect(x: x, y: y, width: width, height: height)
        if isInMainTabBar || (!isAS && self.isLogoIconNeedTiled()) {
            iconRootView.backgroundColor = .clear
        } else {
            iconRootView.backgroundColor = UIColor.ud.bgFloat
        }
        // deleteButton是加在最外层的contentView上的
        width = 20//Layout.hSpacing * 2
        height = 20//Layout.hSpacing * 2
        x = iconContainerView.frame.origin.x + iconContainerView.bounds.size.width - width / 2
        y = iconContainerView.frame.origin.y - height / 2
        deleteButton.frame = CGRect(x: x, y: y, width: width, height: height)
        // deleteIconView是加在iconContainerView上的
        x = iconContainerView.bounds.size.width - width / 2
        y = 0 - height / 2
        deleteIconView.frame = CGRect(x: x, y: y, width: width, height: height)
        if let tab = item?.tab, tab.erasable, self.canEdit {
            // 可以被删除，并且在编辑模式
            deleteButton.isHidden = false
            deleteIconView.isHidden = false
        } else {
            deleteButton.isHidden = true
            deleteIconView.isHidden = true
        }
    }

    public func refreshAll() {
        guard let item = item else { return }
        tabBarItemDidChangeAppearance(item)
        tabBarItemDidUpdateBadge(type: item.badgeType, style: item.badgeStyle)
        tabBarItemDidAddCustomView(item)
        // 重建 view 之后，需要将 selected 状态同步到 view 上
        item.isSelected ? item.selectedState() : item.deselectedState()
    }

    public func configure(userResolver: UserResolver, enableEditMode: Bool = false, editEvent: ((QuickItemEditEventType) -> Void)? = nil) {
        self.userResolver = userResolver
        self.editEvent = editEvent
        self.canEdit = enableEditMode
        if let tab = item?.tab, self.canEdit, !tab.unmovable{
            // 处于编辑模式，并且可以移动
            startShaking()
        } else {
            stopShaking()
        }
    }

    // iPad 上键盘选中效果
    public override func didUpdateFocus(in context: UIFocusUpdateContext,
                                        with coordinator: UIFocusAnimationCoordinator) {
        guard #available(iOS 15, *) else { return }
        if context.nextFocusedItem === self {
            let effect = UIFocusHaloEffect(roundedRect: iconContainerView.frame,
                                           cornerRadius: Layout.iconCornerRadius,
                                           curve: .continuous)
            effect.referenceView = iconView
            effect.containerView = iconContainerView
            focusEffect = effect
        } else if context.previouslyFocusedItem === self {
            focusEffect = nil
        }
    }
}

// MARK: - QuickTabBarItemDelegate
extension QuickTabBarItemView: TabBarItemDelegate {
    public func tabBarItemDidUpdateBadge(type: LarkBadge.BadgeType, style: LarkBadge.BadgeStyle) {
        guard let badgeView = self.iconContainerView.uiBadge.badgeView, isShowBadge else { return }
        badgeView.type = type
        badgeView.style = style
        switch type {
        case .dot:
            badgeView.updateOffset(offsetToRight: 1.5, offsetToTop: -1.5)
        case .image, .label:
            badgeView.updateOffset(offsetToRight: 4.5, offsetToTop: -4.5)
        default:
            badgeView.updateOffset(offsetX: -2, offsetY: 2)
        }
    }

    public func tabBarItemDidAddCustomView(_ item: AbstractTabBarItem) {
        guard let customView = item.quickCustomView else { return }
        if customView.superview !== iconView {
            customView.removeFromSuperview()
            customView.snp.removeConstraints()
            iconView.addSubview(customView)
            iconView.sendSubviewToBack(customView)
        }
        var customViewSize = Layout.iconImageSize
        if item.tab == Tab.more {
            customViewSize = Layout.gridViewSize
            iconRootView.cornerRadius = 0
            iconRootView.clipsToBounds = false
        } else {
            iconRootView.cornerRadius = Layout.iconCornerRadius
            iconRootView.clipsToBounds = true
        }
        customView.snp.remakeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(customViewSize)
        }
        iconView.image = nil
    }

    public func tabBarItemDidChangeAppearance(_ item: AbstractTabBarItem) {
        // 设置显示的title
        titleLabel.text = item.title
        if isInMainTabBar {
            titleLabel.font = Style.regularTitleFont
            titleLabel.textColor = UIColor.ud.textCaption
            titleLabel.numberOfLines = 1
        } else {
            titleLabel.font = Style.defaultTitleFont
            titleLabel.textColor = item.stateConfig.quickTitleColor
            titleLabel.numberOfLines = 2
        }
        // 手动添加的item增加圆角
        let isCustomType = item.tab.isCustomType()
        iconView.layer.cornerRadius = isCustomType ? 7.0 : 0.0
        iconView.clipsToBounds = isCustomType
        // 统一处理各种类型的图标
        self.reloadTabIcon(item)
    }

    // TabIcon对应的图片下载成功通知
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
                    if let item = self.item, item.tab == Tab.more, let gridView = item.quickCustomView as? TabMoreGridView {
                        gridView.reloadData()
                    }
                }
            }).disposed(by: self.disposeBag)
    }

    // 根据数据模型更新Tab图标
    func reloadTabIcon(_ item: AbstractTabBarItem) {
        // 如果存在自定义customView的话不用设置iconView的图片
        if let _ = item.quickCustomView {
            return
        }
        // 打底图
        let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
        // 自定义应用的图片有多种格式，需要每一种都特殊处理
        // 而且还要区分选中和非选中状态，业务只传一张彩色的图，需要主框架这边来兜底统一处理（哎...）
        // 如果在快捷导航区域要用彩色的图，如果在主导航区域要用灰色的图（产品要求的）
        if isInMainTabBar {
            iconView.image = item.stateConfig.defaultIcon ?? placeHolder
            iconView.highlightedImage = item.stateConfig.defaultIcon ?? placeHolder
        } else {
            iconView.image = item.stateConfig.quickBarIcon ?? placeHolder
            iconView.highlightedImage = item.stateConfig.quickBarIcon ?? placeHolder
        }
    }
}

extension QuickTabBarItemView {
    private func setupViews() {
        contentView.addSubview(iconContainerView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(deleteButton)
        iconContainerView.addSubview(iconRootView)
        iconContainerView.addSubview(deleteIconView)
        iconRootView.addSubview(iconView)

        iconRootView.cornerRadius = Layout.iconCornerRadius
        iconRootView.clipsToBounds = true
        iconRootView.backgroundColor = UIColor.ud.bgFloat
        // 添加 iPad Pointer 效果
        iconRootView.addPointer(.lift)
        // 先注释掉，不要删了，因为产品可能会加回来
        //iconRootView.borderColor = UIColor.ud.lineBorderCard
        //iconRootView.borderWidth = 0.5

        titleLabel.font = Style.defaultTitleFont
        titleLabel.textColor = Style.defaultTitleColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        iconContainerView.uiBadge.addBadge(type: .label(.number(0)))
        iconContainerView.uiBadge.badgeView?.updateOffset(offsetToRight: 4.5, offsetToTop: -4.5)
        if #available(iOS 15, *) {
            self.focusEffect = nil
        }

        deleteButton.backgroundColor = .clear
        deleteButton.addTarget(self, action: #selector(didTapDeleteButton), for: .touchUpInside)
        deleteIconView.image = UDIcon.getIconByKey(.noFilled,
                                                   iconColor: UIColor.ud.iconN3,
                                                   size: CGSize(width: Layout.hSpacing * 2, height: Layout.hSpacing * 2))
    }
    @objc
    private func didTapDeleteButton() {
        editEvent?(.delete(itemView: self))
    }
}

extension QuickTabBarItemView {
    private func startShaking() {
            let shakeAnimation = CABasicAnimation(keyPath: "transform.rotation")
            shakeAnimation.duration = 0.2
            shakeAnimation.repeatCount = .infinity
            shakeAnimation.autoreverses = true
            shakeAnimation.fromValue = NSNumber(value: Double.pi / 180 * -4)
            shakeAnimation.toValue = NSNumber(value: Double.pi / 180 * 4)
            iconContainerView.layer.add(shakeAnimation, forKey: "shakeAnimation")
        }

    private func stopShaking() {
        iconContainerView.layer.removeAnimation(forKey: "shakeAnimation")
    }
}

extension QuickTabBarItemView {
    // 判断图标是否需要平铺：为了满足产品各种定制化的需求，不得不设计一个黑白名单机制
    private func isLogoIconNeedTiled() -> Bool {
        guard let tab = item?.tab else { return false }
        if let style = tab.iconStyle, style == .Tiled {
            return true
        }
        if !self.disableIconStyle && tab == .base && !isInMainTabBar {
            if let represent = TabRegistry.resolve(tab), let style = represent.quickIconStyle, style == .Tiled {
                return true
            }
        }
        var result = false
        if let config = self.navigationConfig, let whiteList = (config["app_icon_white_list"] as? Array<String>) {
            // 看是否在白名单内
            for whiteType in whiteList {
                let type = self.transformToAppType(type: whiteType)
                if tab.appType == type {
                    result = true
                    break
                }
            }
            // 看是否在黑名单内
            if let blackList = config["app_icon_black_list"] as? Array<[String: String]> {
                for black in blackList {
                    if let uniqueId = black["unique_id"], !uniqueId.isEmpty {
                        // 如果有settings里面有配置unique_id的话
                        if (tab.uniqueId ?? tab.key) == uniqueId {
                            result = false
                            break
                        }
                    } else {
                        // 没有配置unique_id的话需要自己根据biz_type和app_id生成
                        if let blackType = black["biz_type"], let appId = black["app_id"] {
                            let bizType = self.transformToBizType(type: blackType)
                            let generateId = Tab.generateAppUniqueId(bizType: bizType, appId: appId)
                            if (tab.uniqueId ?? tab.key) == generateId {
                                result = false
                                break
                            }
                        }
                    }
                }
            }
        } else {
            // 如果没有配置Settings的话，默认APP_TYPE_MINI、APP_TYPE_WEB、APP_TYPE_USER_OPEN_APP这三个类型要加白的
            if tab.appType == .gadget || tab.appType == .webapp || tab.appType == .appTypeOpenApp {
                result = true
            }
        }
        return result
    }

    private func transformToAppType(type: String) -> AppType {
        let appType: AppType
        if type == "APP_TYPE_LARK_NATIVE" {
            // 租户配置的官方应用
            appType = .native
        } else if type == "APP_TYPE_MINI" {
            // 租户配置的小程序
            appType = .gadget
        } else if type == "APP_TYPE_WEB" {
            // 租户配置的H5应用
            appType = .webapp
        } else if type == "APP_TYPE_CUSTOM_NATIVE" {
            // 租户配置的原生应用
            appType = .appTypeCustomNative
        } else if type == "APP_TYPE_USER_OPEN_APP" {
            // 用户手动添加的开放平台的网页、小程序
            appType = .appTypeOpenApp
        } else if type ==  "APP_TYPE_USER_URL" {
            // 用户手动添加的其他类型，比如纯网页链接、云文档链接、群聊链接等
            appType = .appTypeURL
        } else {
            // 默认都是官方应用
            appType = .native
        }
        return appType
    }

    private func transformToBizType(type: String) -> CustomBizType {
        let bizType: CustomBizType
        if type == "CCM" {
            // 文档
            bizType = .CCM
        } else if type == "MINI_APP" {
            // 开放平台：小程序
            bizType = .MINI_APP
        } else if type == "WEB_APP" {
            // 开放平台：网页应用
            bizType = .WEB_APP
        } else if type == "MEEGO" {
            // 开放平台：Meego
            bizType = .MEEGO
        } else if type == "WEB" {
            // 自定义H5网页
            bizType = .WEB
        } else {
            // 默认都是官方应用
            bizType = .UNKNOWN_TYPE
        }
        return bizType
    }
}

class TappableImageView: UIImageView {
    // 增加的点击热区大小
    var extendedTouchSize: CGFloat = 20
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = CGRect(x: bounds.origin.x - extendedTouchSize / 2,
                                    y: bounds.origin.y - extendedTouchSize / 2,
                                    width: bounds.width + extendedTouchSize,
                                    height: bounds.height + extendedTouchSize)
        return extendedBounds.contains(point)
    }
}
