//
//  ASGeckoManager.swift
//  LarkSearchCore
//
//  Created by bytedance on 2021/10/26.
//

import Foundation
import LarkFoundation
import OfflineResourceManager
import LarkContainer
import LarkEnv
import LKCommonsLogging
import MapKit
import Lynx
import LarkAccountInterface
import LarkStorage

public final class ASTemplateManager: NSObject {
    static let globalStore = KVStores.SearchDebug.globalStore
    static var DEBUG_TEMPLATE_HOST: String {
        return globalStore[KVKeys.SearchDebug.lynxHostKey]
    }
    static var DEBUG_ENABLE: Bool {
        return globalStore[KVKeys.SearchDebug.localDebugOn]
    }

    static let logger = Logger.log(ASTemplateManager.self, category: "Module.SearchCore")
    public static let FEISHU_ACCESS_KEY_BOE = "285fded323223388f4aedf68b975d216"
    public static let FEISHU_ACCESS_KEY_PRE = "80f3d6f8eb94aad0dc181ca3a881adcc"
    public static let FEISHU_ACCESS_KEY_ONLINE = "f2e97c8d28fd14414ce871534b57db7e"
    public static let LARK_ACCESS_KEY_BOE = "2b1172275ce1d4df5e6c993a651e80ad"
    public static let LARK_ACCESS_KEY_PRE = "006b1e876ef90fef9e373ee7a0e8601b"
    public static let LARK_ACCESS_KEY_ONLINE = "3c2fec1517974f15d2acc29b8d9da298"
    public static let SearchChannel = "mobile_search"
    public static let EnterpriseWordChannel = "mobile_cyclopedia"

    private static var hasRegisteredGecko = false

    public func initGecko(resolver: LarkContainer.UserResolver) {
        // gecko只需要注册一次
        if !Self.hasRegisteredGecko {
            Self.hasRegisteredGecko = true
            var accessKey = Self.FEISHU_ACCESS_KEY_ONLINE
            let passportService = try? resolver.resolve(assert: PassportService.self)
            let isFeishu = passportService?.isFeishuBrand ?? true
            switch (EnvManager.env.type, isFeishu) {
            case (.release, true):
                accessKey = Self.FEISHU_ACCESS_KEY_ONLINE
            case (.staging, true):
                accessKey = Self.FEISHU_ACCESS_KEY_BOE
            case (.preRelease, true):
                accessKey = Self.FEISHU_ACCESS_KEY_PRE
            case (.release, false):
                accessKey = Self.LARK_ACCESS_KEY_ONLINE
            case (.staging, false):
                accessKey = Self.LARK_ACCESS_KEY_BOE
            case (.preRelease, false):
                accessKey = Self.LARK_ACCESS_KEY_PRE
            @unknown default:
                accessKey = Self.FEISHU_ACCESS_KEY_ONLINE
                break
            }
            let configForSearch = OfflineResourceBizConfig(bizID: ASTemplateManager.SearchChannel,
                                                           bizKey: accessKey,
                                                           subBizKey: ASTemplateManager.SearchChannel)

            let configFocyClopedia = OfflineResourceBizConfig(bizID: ASTemplateManager.EnterpriseWordChannel,
                                                              bizKey: accessKey,
                                                              subBizKey: ASTemplateManager.EnterpriseWordChannel)
            OfflineResourceManager.registerBiz(configs: [configForSearch, configFocyClopedia])
            // 从服务端拉取JS
            OfflineResourceManager.fetchResource(byId: ASTemplateManager.SearchChannel, complete: { (isSucess, state) in
                Self.logger.info("fetch \(ASTemplateManager.SearchChannel) Resource isSuccess = \(isSucess), state = \(state)")
            })
            OfflineResourceManager.fetchResource(byId: ASTemplateManager.EnterpriseWordChannel, complete: { (isSucess, state) in
                Self.logger.info("fetch \(ASTemplateManager.EnterpriseWordChannel) Resource isSuccess = \(isSucess), state = \(state)")
            })
        }
    }

    public static func loadTemplateWithData(templateName: String,
                                            channel: String,
                                            initData: LynxTemplateData?,
                                            lynxView: LynxView?,
                                            resultCallback: ((Data?) -> Void)?) {
        Self.logger.info("loadTemplateWithData \(templateName) channel \(channel)")
        #if DEBUG || INHOUSE
            Self.logger.info("loadTemplateON \(self.DEBUG_ENABLE) host \(self.DEBUG_TEMPLATE_HOST)")
        #endif
        if Self.DEBUG_ENABLE {
            lynxView?.loadTemplate(fromURL: Self.DEBUG_TEMPLATE_HOST + templateName, initData: initData)
            resultCallback?(Data())
        } else {
            Self.loadTemplate(templateName: templateName, channel: channel) { templateData in
                guard let templateData = templateData, let initData = initData else {
                    resultCallback?(nil)
                    return
                }
                lynxView?.loadTemplate(templateData, withURL: "", initData: initData)
                resultCallback?(templateData)
            }
        }
    }

    public static func loadTemplate(templateName: String, channel: String, resultCallback: ((Data?) -> Void)?) {
        Self.logger.info("loadTemplate \(templateName) channel \(channel)")
        let data = loadTemplateSync(templateName: templateName, channel: channel)
        resultCallback?(data)
    }

    /// 从Gecko加载模板
    public static func loadTemplateSync(templateName: String, channel: String) -> Data? {
        Self.logger.info("loadTemplateSync \(templateName) channel \(channel)")
        guard OfflineResourceManager.fileExists(id: channel, path: templateName) else {
            let data = Self.loadTemplateFromResource(templateName)
            return data
        }
        let data = OfflineResourceManager.data(forId: channel, path: templateName)
        Self.logger.info("loadTemplateSync \(templateName) from gecko, data:\(data)")
        return data
    }

    /// 从Gecko加载模板，现已不再使用
    public static func getTemplateFromGecko(templateName: String, channel: String) -> String? {
        Self.logger.info("getTemplateFromGecko \(templateName) channel \(channel)")
        guard let path = OfflineResourceManager.rootDir(forId: channel) else { return nil }
        let jsPath = path + "/" + templateName
        return jsPath
    }

    /// 从本地加载模板
    private static func loadTemplateFromResource(_ template: String) -> Data? {
        Self.logger.info("loadTemplateFromResource \(template)")
        var segments = template.split(separator: "/")
        var path: String?
        if segments.isEmpty {
            path = BundleConfig.LarkSearchCoreBundle.path(forResource: template, ofType: nil)
        } else {
            var name = segments.last
            var dir = segments.first
            Self.logger.info("loadTemplateFromResource \(template), name: \(name), dir: \(dir)")
            // 首先尝试加载KA的模板
            if let url = BundleConfig.SelfBundle.url(forResource: "KALynxTemplate", withExtension: "bundle"),
               let KABundle = Bundle(url: url) {
                path = KABundle.path(forResource: String(name ?? ""), ofType: nil, inDirectory: String(dir ?? ""))
            } else {
                path = BundleConfig.LarkSearchCoreBundle.path(forResource: String(name ?? ""), ofType: nil, inDirectory: String(dir ?? ""))
            }
        }

        if let path {
            Self.logger.info("loadTemplateFromResource \(template), path: \(path)")
            // lint:disable:next lark_storage_check
            let template = try? Data(contentsOf: URL(fileURLWithPath: path))
            return template
        }
        return nil
    }
}
