//
//  GadgetMenuMonitorMenuPlugin.swift
//  OPGadget
//
//  Created by yinyuan on 2021/6/20.
//

import LarkUIKit
import TTMicroApp
import ECOProbe
import LKCommonsLogging
import OPFoundation

private let logger = Logger.oplog(GadgetMenuMonitorMenuPlugin.self)

/// 小程序菜单埋点
public final class GadgetMenuMonitorMenuPlugin: MenuPlugin {
    
    public static var pluginID: String = "GadgetMenuMonitorMenuPlugin"
    
    public static var enableMenuContexts: [MenuContext.Type] = [AppMenuContext.self]
    
    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext
    
    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.info("FeatureGating is not available, because there is no AppMenuContext")
            return nil
        }
        let uniqueID = appMenuContext.uniqueID
        logger.info("GadgetMenuMonitorMenuPlugin.uniqueID \(uniqueID)")
        self.menuContext = appMenuContext
    }
    
    public func menuDidShow(handler: MenuPluginOperationHandler) {
        /// update: 这边放到BDPToolBarView中上报
//        let common = BDPCommonManager.shared()?.getCommonWith(menuContext.uniqueID)
//        // 产品埋点：分享链路 https://bytedance.feishu.cn/sheets/shtcnxrXP8G9GjHbZ7qE9FGAG0b?sheet=196nOL
//        OPMonitor("openplatform_mp_container_menu_view")
//            .setUniqueID(menuContext.uniqueID)
//            .addCategoryValue("application_id", OPSafeObject(menuContext.uniqueID.appID, "none"))
//            .addCategoryValue("scene_type", OPSafeObject(common?.schema.scene, "none"))
//            .addCategoryValue("solution_id", "none")
//            .setPlatform([.tea, .slardar])
//            .flush()
    }
    
}
