//
//  WorkplaceWebSceneConfig.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/6/8.
//

import Foundation
import LKCommonsLogging
import LarkSceneManager
import LarkUIKit
import ECOInfra
import LarkNavigator
import EENavigator
import LarkContainer
import WebBrowser
import LarkWorkplaceModel

/// Web容器多Scene
@available(iOS 13.0, *)
final class WorkplaceWebSceneConfig: SceneConfig {
    static let logger = Logger.log(WorkplaceWebSceneConfig.self)

    /// Web 多Scene区分业务的key
    static var key: String { WorkPlaceScene.sceneKey }
    /// Web 多Scene新窗口的icon
    static func icon() -> UIImage { Resources.mutil_scene_web_icon }

    static func createRootVC(
        scene: UIScene,
        session: UISceneSession,
        options: UIScene.ConnectionOptions,
        sceneInfo: Scene,
        localContext: AnyObject?
    ) -> UIViewController? {
        Self.logger.info("\(scene) \(session) \(options) \(sceneInfo)")
        /// sceneInfo.id 为新窗口打开的网页的地址，同时这个地址作为Web多scene业务下面区分某一个窗口的key
        /// LarkScene的框架会以这个id为key，来区分寻查找历史存在的同一个地址创建的window
        /// 如果在辅助窗口打开应用，需要dismiss掉常用应用的浮层
        let notiName = AppCenterNotification.activeAuxiliaryScene.name
        NotificationCenter.default.post(name: notiName, object: nil)
        /// 通过老的方式打开旧H5应用
        guard let itemJson = sceneInfo.userInfo[WorkPlaceScene.itemKey],
           let itemData = itemJson.data(using: .utf8) else {
            Self.logger.error("open \(sceneInfo.id) in new scene failed, itemJson to data fail")
            return nil
        }
        do {
            let item = try JSONDecoder().decode(WPAppItem.self, from: itemData)
            if let targetVC = openH5InNewScene(with: item) {
                return LkNavigationController(rootViewController: targetVC)
            }
        } catch {
            Self.logger.error("decode json to workplace item failed \(sceneInfo.id)", error: error)
        }
        Self.logger.error("open \(sceneInfo.id) in new scene failed")
        return nil
    }

    /// 在辅助窗口打开 H5 应用
    ///
    /// - Parameter info: appInfo
    /// - Returns: 辅助窗口 UIViewController
    static func openH5InNewScene(with info: WPAppItem) -> UIViewController? {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let navigator = userResolver.navigator
        let openService = try? userResolver.resolve(assert: WorkplaceOpenService.self)

        Self.logger.info("openH5InNewScene, resolve OpenService: \(openService != nil)")

        let monitor =
        OPMonitor(WPMWorkplaceCode.workplace_open_h5)
            .addCategoryValue(WPEventValueKey.item_id.rawValue, info.itemId)
            .addCategoryValue(WPEventValueKey.appname.rawValue, info.name)
            .addCategoryValue(WPEventValueKey.app_id.rawValue, info.appId ?? "")
            .addCategoryValue(WPEventValueKey.openh5_type.rawValue, #function)
        var navResponse: EENavigator.Response?
        do {
            try openService?.openH5Internal(with: info) { (body: WebBody?, url: URL?, _: [String: Any]?) in
                if let body = body {
                    var webBody = body
                    webBody.fromWebMultiScene = true
                    navResponse = navigator.response(for: webBody)
                } else if let url = url {
                    navResponse = navigator.response(for: url, context: ["forcePush": true, "fromWebMultiScene": true])
                }
            }
            _ = monitor.setResultTypeSuccess()
        } catch {
            _ = monitor.setError(error).setResultTypeFail()
        }
        monitor.flush()
        /// 业务埋点上报
        let context = WorkplaceOpenContext(
            isTemplate: false,
            appIsCommon: false,
            isAuxWindow: true,
            templateId: "",
            exposeUIType: nil
        )
        openService?.reportOpen(item: info, openType: .h5, context: context)
        return navResponse?.resource as? UIViewController
    }
}
