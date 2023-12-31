//
//  BrowserMutilScene.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/6/29.
//

import EENavigator
import LarkSceneManager
import LarkUIKit
import LKCommonsLogging
import WebBrowser

// 下边的代码 code from lilun.ios 没有修改任何逻辑，仅代码迁移位置，文件作者不承担任何Oncall，咨询等相关责任
class BrowserMutilScene {
    /// 注册多Scene回调, 在独立窗口打开web页面
    static func assembleMutilScene() {
        if #available(iOS 13.4, *), SceneManager.shared.supportsMultipleScenes {
            SceneManager.shared.register(config: WebSceneConfig.self)
        }
    }
}
/// Web容器多Scene
@available(iOS 13.0, *)
class WebSceneConfig: SceneConfig {
    private static let logger = Logger.ecosystemWebLog(WebSceneConfig.self, category: "WebSceneConfig")
    /// Web 多Scene区分业务的key
    static var key: String { "Web" }
    /// Web 多Scene新窗口的icon
    static func icon() -> UIImage { BundleResources.WebBrowser.mutil_scene_web_icon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        Self.logger.info("\(scene) \(session) \(options) \(sceneInfo)")
        /// sceneInfo.id 为新窗口打开的网页的地址，同时这个地址作为Web多scene业务下面区分某一个窗口的key
        /// LarkScene的框架会以这个id为key，来区分寻查找历史存在的同一个地址创建的window
        if let _url = URL(string: sceneInfo.id) {
            let isAppLinkString = sceneInfo.userInfo["is_app_link"] ?? ""
            let useAppLink = isAppLinkString == "1"
            Self.logger.info("open \(sceneInfo.id) in new scene, useAppLink: \(useAppLink)")
            let navi = LkNavigationController()
            if useAppLink {
                Navigator.shared.push(// user:global
                    _url,
                    context: ["forcePush": true,"fromWebMultiScene": true],
                    from: navi
                )
            } else {
                let body = WebBody(url: _url)
                /// context需要携带forcePush标记，否则会命中主端路由组件EENavigator的bug
                /// 参见 https://bytedance.feishu.cn/docs/doccnIsfJs2ugescOJoILBIQcOf
                Navigator.shared.push(body: body,// user:global
                                      context: ["forcePush": true,"fromWebMultiScene": true],
                                      from: navi,
                                      animated: false) { (_, _) in
                    Self.logger.info("open \(_url) in new scene success")
                }
            }
            return navi
        }
        Self.logger.error("open \(sceneInfo.id) in new scene failed")
        return nil
    }
}
