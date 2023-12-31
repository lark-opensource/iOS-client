//
//  TabRepresentable.swift
//  LarkNavigation
//
//  Created by KT on 2020/1/23.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import AnimatedTabBar
import LarkTab
import LarkResource
import UniverseDesignColor
import UniverseDesignIcon
import ByteWebImage
import LKCommonsLogging
import LarkContainer
// 文档这边的设计很不合理，基础模块这边要依赖业务的实现，这值得商榷，应该参考ByteWebImage的设计和实现
import LarkDocsIcon

public typealias DecorateItem = (itemConfig: ItemStateConfig, defaultColor: UIColor, selectColor: UIColor)

private let logger = Logger.oplog(Tab.self, category: "LarkNavigation.Tab")

public extension TabRepresentable {
    func makeTabItem(userResolver: UserResolver) -> AbstractTabBarItem {
        let item = tab.makeTabItem(userResolver: userResolver)
        if let customQuickView = customQuickView {
            item.quickCustomView = customQuickView
        }
        if let customView = customView {
            // 转为 Calendar Tab 做的特化逻辑，不易维护，应解耦到 Calendar 模块中实现
            item.itemState = CalendarTabState()
            item.customView = customView
        } else {
            item.itemState = DefaultTabState()
        }
        return item
    }
}

public extension Tab {

    func makeTabItem(userResolver: UserResolver) -> AbstractTabBarItem {
        // TODO: @wanghaidong 不一定要从 TabConfig 中取，可以直接从 Tab 中获得
        // 梳理这里的逻辑
        let tabConfig = TabConfig.defaultConfig(for: self.key, of: self.appType)
        let (stateConfig, defaultColor, selectedColor) = Tab.decorateNativeTab(defaultConfig: tabConfig)
        var item = TabBarItem(tab: self, title: tabConfig.name ?? self.name ?? "", stateConfig: stateConfig)
        if self.appType != .native {
            item = self.decorateNonNativeTab(userResolver: userResolver, item: item, defaultColor: defaultColor, selectedColor: selectedColor)
        }
        if self == .moment, let remoteName = self.remoteName {
            item.title = remoteName
        }
        item.setupAccessoryIdentifier()
        return item
    }

    private static func getVIColor() -> UIColor? {
        return ResourceManager.get(key: "suite_skin_vi_icon_color", type: "color")
    }

    /// 修饰官方应用：对图标的 暗黑模式 & 品牌染色处理收敛到一起
    static func decorateNativeTab(defaultConfig: TabConfig?) -> DecorateItem {
        var selectedColor = UIColor.ud.primaryContentDefault
        var selectedIcon = defaultConfig?.selectedIcon
        if let viColor = Tab.getVIColor() {
            selectedColor = viColor & UIColor.ud.primaryContentDefault
            /// 处理配置品牌主题色，主导航在dark mode下不进行染色
            if let lightIcon = defaultConfig?.icon?.colorImage(viColor),
               let darkIcon = defaultConfig?.selectedIcon {
                selectedIcon = UIImage.dynamic(light: lightIcon, dark: darkIcon)
            } else {
                selectedIcon = defaultConfig?.icon?.ud.withTintColor(selectedColor)
            }
        }
        let defaultColor = UIColor.ud.iconN3
        let defaultTitleColor = UIColor.ud.staticBlack70 & UIColor.ud.staticWhite80
        let defaultIcon = defaultConfig?.icon?.ud.withTintColor(defaultColor)
        let stateConfig = ItemStateConfig(defaultIcon: defaultIcon,
                                          selectedIcon: selectedIcon,
                                          quickBarIcon: defaultConfig?.quickTabIcon,
                                          defaultTitleColor: defaultTitleColor,
                                          selectedTitleColor: selectedColor)
        return (stateConfig, defaultColor, selectedColor)
    }

    /// 修饰非官方应用：租户配置或者用户配置的，不同类型应用图标的处理都不一样，最特殊的当属CCM的文档图标，文档那边设计不符合规范，太业务化了！
    func decorateNonNativeTab(userResolver: UserResolver, item: TabBarItem, defaultColor: UIColor, selectedColor: UIColor) -> TabBarItem {
        if let name = self.remoteName {
            item.title = name
        }
        // 租户配置的应用，为了兼容之前产品的逻辑：之前租户配置的应用图标有一套很复杂的规则，先不要动这块逻辑
        if let defaultIcon = self.mobileRemoteDefaultIcon, !defaultIcon.isEmpty,
           let selectedIcon = self.mobileRemoteSelectedIcon, !selectedIcon.isEmpty {
            // select原图展示（彩色图），default需要置灰处理
            self.retriveImage(key: defaultIcon) { img in
                // 新导航因为支持自定义应用，所以要求default置灰处理
                if let resultImage = UIImage.transformToGrayImage(img) {
                    item.stateConfig.defaultIcon = resultImage
                } else {
                    item.stateConfig.defaultIcon = img
                }
            }

            self.retriveImage(key: selectedIcon) { img in
                item.stateConfig.selectedIcon = img
                item.stateConfig.quickBarIcon = img
            }
        } else if let icon = self.remoteSupportTintColorIcon, !icon.isEmpty {
            /// 开放平台自建应用支持染色图片，适配darkmode & ka主题色自定义
            ///  历史逻辑，仅兼容旧数据
            self.retriveImage(key: icon) { (img) in
                item.stateConfig.defaultIcon = img.ud.withTintColor(defaultColor)
                item.stateConfig.selectedIcon = img.ud.withTintColor(selectedColor)
                item.stateConfig.quickBarIcon = img.ud.withTintColor(selectedColor)
            }
        } else {
            /// 历史逻辑，仅兼容旧数据
            if let icon = self.remoteIcon {
                self.retriveImage(key: icon) { img in
                    item.stateConfig.defaultIcon = img
                }
            }
            if let icon = self.remoteSelectedIcon {
                self.retriveImage(key: icon) { img in
                    item.stateConfig.selectedIcon = img
                    item.stateConfig.quickBarIcon = img
                }
            }
        }
        // 新导航用户配置的自定义应用
        if let tabIcon = self.tabIcon {
            let key = self.key
            let uniqueId = self.uniqueId ?? key
            logger.info("<NAVIGATION_BAR> load icon image for tab: key = \(key), uniqueId = \(uniqueId), icon = \(tabIcon)")
            self.loadImage(userResolver: userResolver, tabIcon: tabIcon) { img in
                // 产品要求没有选中状态图片需要统一置灰处理
                if let resultImage = UIImage.transformToGrayImage(img) {
                    item.stateConfig.defaultIcon = resultImage
                } else {
                    item.stateConfig.defaultIcon = img
                }
                item.stateConfig.selectedIcon = img
                item.stateConfig.quickBarIcon = img
                // 数据模型变化的时候需要通知给上层业务刷新控件或者页面
                NotificationCenter.default.post(name: .LKTabDownloadIconSucceedNotification, object: ["key": key, "uniqueId": uniqueId], userInfo: nil)
            }
        }
        return item
    }
}

// remote value
extension Tab {
    // 根据图标类型加载图片，注意基本都是异步获取，所以要考虑数据模型变化的时候如何通知业务刷新UI
    func loadImage(userResolver: UserResolver, tabIcon: TabCandidate.TabIcon, success: @escaping (UIImage) -> Void) {
        let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
        switch tabIcon.type {
        case .iconInfo:
            // 如果是ccm iconInfo图标
            if let docsService = try? userResolver.resolve(assert: DocsIconManager.self) {
                docsService.getDocsIconImageAsync(iconInfo: tabIcon.content, url: self.urlString, shape: .SQUARE)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (image) in
                        success(image)
                    }, onError: { error in
                        logger.error("<NAVIGATION_BAR> get docs icon image error", error: error)
                    }).disposed(by: self.disposeBag)
            } else {
                logger.error("<NAVIGATION_BAR> can't resolver DocsIconManager")
            }
        case .udToken:
            // 如果是UD图片
            let image = UDIcon.getIconByString(tabIcon.content) ?? placeHolder
            success(image)
        case .byteKey, .webURL:
            // 如果是ByteImage或者网络图片
            var resource: LarkImageResource
            if tabIcon.type == .byteKey {
                let (key, entityId) = tabIcon.parseKeyAndEntityID()
                resource = .avatar(key: key ?? "", entityID: entityId ?? "")
            } else {
                resource = .default(key: tabIcon.content)
            }
            // 获取图片资源
            LarkImageService.shared.setImage(with: resource, completion:  { (imageResult) in
                var image = placeHolder
                switch imageResult {
                case .success(let r):
                    if let img = r.image {
                        image = img
                    } else {
                        logger.error("<NAVIGATION_BAR> LarkImageService get image result is nil!!! tabIcon content = \(tabIcon.content)")
                    }
                case .failure(let error):
                    logger.error("<NAVIGATION_BAR> LarkImageService get image failed!!! tabIcon content = \(tabIcon.content), error = \(error)")
                    break
                }
                success(image)
            })
        @unknown default:
            break
        }
    }

    func retriveImage(key: String, success: @escaping (UIImage) -> Void) {
        guard let url = URL(string: key) else { return }
        ImageManager.default.requestImage(url, completion: { (requestResult) in
            guard case .success(let imageResult) = requestResult, let image = imageResult.image else { return }
            success(image)
        })
    }
}

private extension AbstractTabBarItem {

    func setupAccessoryIdentifier() {
        switch tab {
        case .feed:
            accessoryIdentifier = SpotlightAccessoryIdentifier.tab_feed.rawValue
        case .calendar:
            accessoryIdentifier = SpotlightAccessoryIdentifier.tab_calendar.rawValue
        case .doc:
            accessoryIdentifier = SpotlightAccessoryIdentifier.tab_drive.rawValue
        case .appCenter:
            accessoryIdentifier = SpotlightAccessoryIdentifier.tab_workspace.rawValue
        case .byteview:
            accessoryIdentifier = SpotlightAccessoryIdentifier.tab_video.rawValue
        case .mail:
            accessoryIdentifier = SpotlightAccessoryIdentifier.tab_mail.rawValue
        default:
            break
        }
    }
}
