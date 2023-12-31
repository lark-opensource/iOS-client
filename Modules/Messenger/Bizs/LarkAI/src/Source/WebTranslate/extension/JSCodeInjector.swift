//
//  JSBridgeInjector.swift
//  LarkAI
//
//  Created by liushuwei on 2020/11/23.
//

import Foundation
import OfflineResourceManager
import LKCommonsLogging
import WebBrowser
import LarkStorage

final class JSCodeInjector {
    static let logger = Logger.log(JSCodeInjector.self, category: "Module.AI")

    // 网页翻译热更新gecko相关配置
    private struct GeckoConfig {
        static let bizID = "webTranslate"
        static let accessKey = "c082f89962a36b39dadaf5b7b0c1c293"
        static let channel = "web-translate"
        static let plugin_gecko_file_name = "build.js"
    }
    // 网页翻译Local Resources相关配置
    private struct LocalResourceConfig {
        static let plugin_file_name = "web_translate_plugin"
        static let event_jsb_file_name = "web_translate_event_jsb"
        static let resouceType = "js"
    }
    private static var hasRegisteredGecko = false
    private var geckoJSPath: String? {
        guard let path = OfflineResourceManager.rootDir(forId: GeckoConfig.bizID) else { return nil }
        let jsPath = path + "/" + GeckoConfig.plugin_gecko_file_name
        return jsPath
    }

    let globalStore = KVStores.SearchDebug.globalStore
    var debugJsPluginHost: String {
        return globalStore[KVKeys.SearchDebug.lynxHostKey]
    }
    var debugEnable: Bool {
        return globalStore[KVKeys.SearchDebug.localDebugOn]
    }

    init() {
        /// 使用本地兜底，去掉动态下发能力
//        updateJSByGecko()
    }

    public func injectCode(api: WebBrowser) {
        guard let translateBundlePath = BundleConfig.LarkAIBundle.path(forResource: LocalResourceConfig.plugin_file_name, ofType: LocalResourceConfig.resouceType),
              let birdgeBundlePath = BundleConfig.LarkAIBundle.path(forResource: LocalResourceConfig.event_jsb_file_name, ofType: LocalResourceConfig.resouceType) else {
                Self.logger.info("can't get path while process webTranslate")
                return
        }

        if debugEnable {
            if let urlString = debugJsPluginHost.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
               let requestUrl = URL(string: urlString) {
                let request = URLRequest(url: requestUrl)
                let task = URLSession.shared.dataTask(with: request) { [weak self] (data, _, error) in
                    guard let data = data, let self = self, error == nil else {
                        return
                    }
                    guard let result = String(data: data, encoding: String.Encoding.utf8) else {
                        return
                    }
                    self.evaluateJsb(api: api, translateJS: result, birdgeBundlePath: birdgeBundlePath)
                }
                task.resume()
                return
            }
        }
        var tryTranslateJS: String?

        // 从Gecko获取热更新文件
        if let geckoJSPath = self.geckoJSPath {
            Self.logger.info("geckoJSPath is valuable")
            let url = URL(fileURLWithPath: geckoJSPath)
            // lint:disable:next lark_storage_check
            tryTranslateJS = try? String(contentsOf: url, encoding: .utf8)
        }
        // 如果热更新JS读取失败，则读取local resource中的JS
        if tryTranslateJS == nil {
            Self.logger.info("tryTranslateJS is valuable")
            let url = URL(fileURLWithPath: translateBundlePath)
            // lint:disable:next lark_storage_check
            tryTranslateJS = try? String(contentsOf: url, encoding: .utf8)
        }
        guard let translateJS = tryTranslateJS else { return }
        evaluateJsb(api: api, translateJS: translateJS, birdgeBundlePath: birdgeBundlePath)
    }

    func evaluateJsb(api: WebBrowser, translateJS: String, birdgeBundlePath: String) {
        let bridgeUrl = URL(fileURLWithPath: birdgeBundlePath)
        // lint:disable:next lark_storage_check
        guard let bridgeJS = try? String(contentsOf: bridgeUrl, encoding: .utf8) else { return }
        // 加载网页翻译的bridge JS
        api.webView.evaluateJavaScript(bridgeJS) { (_, error) in
            if error != nil {
                Self.logger.error("excuted bridgeJS error ", error: error)
                return
            }
            Self.logger.info("excuted bridgeJS succeed")
        }
        // 加载网页翻译服务的JS
        api.webView.evaluateJavaScript(translateJS) { (_, error) in
            if error != nil {
                Self.logger.error("excuted translateJS error ", error: error)
                return
            }
            Self.logger.info("excuted translateJS succeed")
        }
    }

    func updateJSByGecko() {
        // gecko只需要注册一次
        if !Self.hasRegisteredGecko {
            Self.hasRegisteredGecko = true
            let config = OfflineResourceBizConfig(bizID: GeckoConfig.bizID,
                                                  bizKey: GeckoConfig.accessKey,
                                                  subBizKey: GeckoConfig.channel)
            OfflineResourceManager.registerBiz(configs: [config])
            // 从服务端拉取JS
            OfflineResourceManager.fetchResource(byId: GeckoConfig.bizID, complete: { (isSucess, state) in
                Self.logger.info("fetchResource isSuccess = \(isSucess), state = \(state)")
            })
        }
    }
}
