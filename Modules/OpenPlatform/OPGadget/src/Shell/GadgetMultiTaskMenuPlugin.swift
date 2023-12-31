//
//  GadgetMultiTaskMenuPlugin.swift
//  OPGadget
//
//  Created by yinyuan on 2021/3/15.
//

import LarkUIKit
import LarkSuspendable
import OPSDK
import TTMicroApp
import LarkOPInterface
import LKCommonsLogging
import LarkAppLinkSDK
import LarkGuide
import LarkFeatureGating
import UniverseDesignIcon
import OPFoundation

private let logger = Logger.oplog(GadgetMultiTaskMenuPlugin.self)

/// 多任务小程序支持
/// 产品责任人：hujunxiao@bytedance.com
/// 小程序多任务iOS技术负责人：yinyuan.0@bytedance.com
/// 小程序多任务技术调研：https://bytedance.feishu.cn/docs/doccn6hQFXEvkixwCu9r8qXqdYb#
/// 飞书多任务接入文档：https://bytedance.feishu.cn/wiki/wikcndNJcu1JC2rlAKA2B9IYTPb#
/// 飞书多任务需求文档：https://bytedance.feishu.cn/docs/doccnXBUpcw7EtchpYyYnZKkHUd
/// 小程序多任务测试用例：https://bytedance.feishu.cn/sheets/shtcnkZXbMiaEjXIK7xhNd8LtLc?sheet=PH94jI&table=tblJtse69kVTmvJh&view=vewqGEr0Wx Gadget-多任务章节
@objcMembers public final class GadgetMultiTaskMenuPlugin: NSObject, MenuPlugin {
    
    /// 插件ID
    public static var pluginID: String {
        "GadgetMultiTaskMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [AppMenuContext.self]
    }
    
    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// 插件Badge的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    static let badgeIdentifier = "gadgetFloating"
    /// 插件的优先级 产品要求「仅次于分享」
    private let menuItemPriority: Float = 80
    /// 红点引导 key
    private static let onboardingKey = "ecosystem_gadget_mutitask_badge"

    /// 避免 menu 循环引用的帮助类
    private class MenuItemModelWeakWrapper {
        weak var menuItemModel: MenuItemModel?
    }
    
    @objc public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        //  多任务插件只在非iPad生效
        guard !Display.pad else {
            logger.info("plugin not available for iPad")
            return nil
        }
        
        guard SuspendManager.isSuspendEnabled else {
            logger.info("SuspendManager is not available")
            return nil
        }
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.info("FeatureGating is not available, because there is no AppMenuContext")
            return nil
        }
        let uniqueID = appMenuContext.uniqueID
        guard !BDPAppMetaUtils.metaIsDebugMode(for: uniqueID.versionType) else {
            logger.info("debug can't show because app versionType isn't current")
            return nil
        }
        logger.info("GadgetMultiTaskMenuPlugin.uniqueID \(uniqueID)")
        self.menuContext = appMenuContext
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        let uniqueID = self.menuContext.uniqueID
        guard let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) else {
            logger.error("task is nil. \(uniqueID)")
            return
        }
        guard let _container = task.containerVC else {
            logger.error("container is nil")
            return
        }
        guard let container = _container as? ViewControllerSuspendable else {
            logger.error("container not confirm to ViewControllerSuspendable")
            return
        }
        
        //  仅需要引导的时候显示红点
        let showGuide = Self.shouldShowGuide()
        let badgeNumber: UInt = showGuide ? 1 : 0
        
        // 菜单icon和标题
        let title: String
        let image: UIImage
        // 根据是否已添加引导显示不同的icon
        let hasAddedFloating = SuspendManager.shared.contains(suspendID: container.suspendID)
        logger.info("hasAddedFloating: \(hasAddedFloating), showGuide:\(showGuide)")
        if hasAddedFloating {
            title = LarkSuspendable.BundleI18n.LarkSuspendable.Lark_Core_CancelFloating
            image = UDIcon.getIconByKey(UDIconType.unmultitaskOutlined)
        } else {
            title = LarkSuspendable.BundleI18n.LarkSuspendable.Lark_Core_FloatingWindow
            image = UDIcon.getIconByKey(UDIconType.multitaskOutlined)
        }

        /// 避免 menu 循环引用的帮助类
        let menuWrapper = MenuItemModelWeakWrapper()
        
        let menu = MenuItemModel(
            title: title,
            imageModel: MenuItemImageModel(normalForIPhoneLark: image),
            itemIdentifier: Self.badgeIdentifier,
            badgeNumber: badgeNumber,
            itemPriority: menuItemPriority,
            action: { [weak container, weak handler, weak self] _ in
                guard let container = container else {
                    logger.info("container released")
                    return
                }
                logger.info("menu action: \(hasAddedFloating)")

                // 产品埋点
                self?.itemActionReport(applicationID: uniqueID.appID, menuItemCode: .multiTaskButton)

                // 清理红点（注意：这里不能用 weak self，因为 action 时调用时，self 已经被释放）
                Self.didShowedGuide()

                if hasAddedFloating {
                    // 已经添加浮窗，取消浮窗
                    SuspendManager.shared.removeSuspend(viewController: container)
                } else {
                    // 未添加浮窗，添加浮窗

                    // 需要在退出小程序之前尝试添加多任务
                    SuspendManager.shared.addSuspend(viewController: container, shouldClose: false) {
                        if SuspendManager.shared.contains(suspendID: uniqueID.fullString) {
                            logger.info("SuspendManager exit gadget. \(uniqueID)")
                            // 需要退出小程序
                            // 新容器的退出
                            OPApplicationService.current.getContainer(uniuqeID: uniqueID)?.unmount(monitorCode: GDMonitorCode.add_to_floating_window)

                        } else {
                            // 多任务已满，不能再添加了，所以这里也不用退出小程序
                            logger.info("SuspendManager isFull")
                        }
                    }
                }
                
                /// 通知菜单消除红点
                if let menu = menuWrapper.menuItemModel {
                    menu.badgeNumber = 0
                    handler?.updateItemModels(for: [menu])
                } else {
                    logger.error("menu released")
                }
            }
        )
        menu.menuItemCode = .multiTaskButton
        menuWrapper.menuItemModel = menu
        handler.updateItemModels(for: [menu])
    }
}

extension GadgetMultiTaskMenuPlugin {
    
    /// Onboarding相关:是否需要引导
    private static func shouldShowGuide() -> Bool {
        guard let newGuideService = OPApplicationService.current.resolver?.resolve(NewGuideService.self) else {
            logger.error("has no NewGuideService, please contact ug team")
            return false
        }
        return newGuideService.checkShouldShowGuide(key: onboardingKey)
    }

    /// Onboarding相关:完成引导
    private static func didShowedGuide() {
        guard let newGuideService = OPApplicationService.current.resolver?.resolve(NewGuideService.self) else {
            logger.error("has no NewGuideService, please contact ug team")
            return
        }
        newGuideService.didShowedGuide(guideKey: onboardingKey)
    }
    
}





