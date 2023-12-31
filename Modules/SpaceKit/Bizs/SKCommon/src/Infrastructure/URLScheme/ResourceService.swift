//  Created by zenghao on 2018/8/27.

import SKFoundation
import LarkLocalizations
import SKUIKit
import SKResource
import RxRelay
import UniverseDesignFont
import UniverseDesignTheme
import SpaceInterface
import SKInfra
import LarkContainer


final class ResourceService {
    // 自定义资源根目录
    /// 资源根目录, 可配置(外部配置了，就优先取外部的，外部资源不完整，则按照内部的资源取)
    static var preferedRoot: String?
    private static var root: SKFilePath {
        SKFilePath(absPath: I18n.resourceBundle.bundlePath)
    }
    /// get resource with url
    class func resource(url: URL, identifyId: String? = "") -> Data? {
        if let subPageData = self.subpageIndexHtmlData(url: url) {
            return subPageData
        } else if let docsIndexHtmlData = self.docsIndexHtmlData(url: url, identifyId: identifyId ?? "") {
            return docsIndexHtmlData
        } else if let ssrIndexHtmlData = self.ssrIndexHtmlData(url: url, identifyId: identifyId ?? "") {
            return ssrIndexHtmlData
        } else if let data = self.resource(path: url.path) {
            return data
        } else {
            GeckoPackageManager.shared.markFileNotFound(filePath: url.path)
            return nil
        }
    }
}

// MARK: - api for load resource
extension ResourceService {
    static var isReadingLocalJSFile = BehaviorRelay<Bool>(value: false)
    
    private class func resource(path: String) -> Data? {
        isReadingLocalJSFile.accept(true); defer { isReadingLocalJSFile.accept(false) }
        if let geckoPath = GeckoPackageManager.shared.filesRootPath(for: GeckoChannleType.webInfo) {
            let filePath = geckoPath.appendingRelativePath(path)

            do {
                return try Data.read(from: filePath, options: .mappedIfSafe)
            } catch {
                return bundleData(path: path)
            }

        }
        return bundleData(path: path)
    }

    private class func bundleData(path: String) -> Data? {
        do {
            let filePath = self.root.appendingRelativePath(path)
            return try Data.read(from: filePath, options: .mappedIfSafe)
        } catch {
            return saviorData(path: path)
        }
    }

    private class func saviorData(path: String) -> Data? {
        let saviorPath = GeckoPackageManager.shared.getSaviorPkgPath()
        let fullPath = saviorPath.appendingRelativePath(path)
        do {
            return try Data.read(from: fullPath, options: .mappedIfSafe)
        } catch {
            return nil
        }
    }

    private static func shouldLoadTemplateFor(_ url: URL) -> Bool {
        if URLValidator.isMainFrameTemplateURL(url) {
            return true
        } else if let type = DocsUrlUtil.getFileType(from: url), DocsType.typesCanUseLocalResources.contains(type) {
            return true
        } else {
            DocsLogger.info("shouldLoadTemplateFor is false")
            return false
        }
    }
    
    private static func docsIndexHtmlData(url: URL, identifyId: String = "") -> Data? {
        guard shouldLoadTemplateFor(url) else {
            return nil
        }
        guard let str = getInjectHtmlData(url, templatePath: "mobile_index.html", identifyId: identifyId) else {
            
            if !UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
                DocsLogger.info("inject docsIndexHtmlData nil", component: LogComponents.fileOpen)
                
                //出现异常场景，下次重启进行重新解压资源包
                GeckoPackageManager.shared.clearResourcePkgIfNeed()
                //上报埋点：资源包异常埋点"fe_pkg_manage_bad_case_dev"
                GeckoPackageManager.shared.logBadCase(code: .unzipAbnormal, msg: "mobile_index_error")
            }
            
            return nil
        }
        DocsLogger.info("inject docsIndexHtmlData", component: LogComponents.fileOpen)
        return str.data(using: .utf8)
    }
    
    private static func ssrIndexHtmlData(url: URL, identifyId: String = "") -> Data? {
        guard URLValidator.isSSRTemplateURL(url) else { return nil }
        guard let str = getInjectHtmlData(url, templatePath: "mobile_ssr_standalone.html", identifyId: identifyId) else {
            //返回空白页面，避免路由到在线兜底页
            return "<html></html>".data(using: .utf8)
        }
        DocsLogger.info("[ssr] inject ssr IndexHtmlData", component: LogComponents.fileOpen)
        return str.data(using: .utf8)
    }
    
    private static func getInjectHtmlData(_ url: URL, templatePath: String, identifyId: String = "") -> String? {
        guard let data = ResourceService.resource(resourceName: templatePath) else {
            spaceAssertionFailure("Failed to get hmlIndexData for \(templatePath)")
            DocsLogger.error("Failed to get hmlIndexData", extraInfo: ["path": templatePath], error: nil, component: nil)
            return nil
        }

        //注入语言
        let jsFileName: String = "\(I18n.currentLanguageIdentifier()).js"
        
        var localLangFilePath: String
        if let path = GeckoPackageManager.shared.filesRootPath(for: .webInfo),
            let langFilePath = GeckoPackageManager.shared.getRelativeFilePath(at: path, of: jsFileName) {
            localLangFilePath = langFilePath
        } else {
            DocsLogger.error("Failed to get lang js file")
            /// 兜底逻辑，不应该走到这里来
            localLangFilePath = "eesz/resource/bear/lang/"  + jsFileName
        }
        let scmVersion = GeckoPackageManager.shared.currentVersion(type: .webInfo)
        // cdnhost后续应该要改成动态从lark获取的
        let langJsFilePath = "//sf3-scmcdn2-cn.feishucdn.com/" + localLangFilePath + "?v=\(scmVersion)"

        guard var str = String(data: data, encoding: .utf8) else {
            return nil
        }
        guard let userID = User.current.info?.userID,
              let tenantID = User.current.info?.tenantID else {
            DocsLogger.info("not loggin return default data")
            return str
        }
        //获取当前主题
        var theme = "light"
        if #available(iOS 13.0, *) {
            let currentTheme = UDThemeManager.getRealUserInterfaceStyle()
            if currentTheme == .dark {
                theme = "dark"
            }
        }
        let darkmodeEnabled = LKFeatureGating.webviewDarkmodeEnabled ? "True" : "False"
        
        var map = [
            ("{{ user_id }}", userID),
            ("{{ tenant_id }}", tenantID),
            ("{{ iframeJsbCheck }}", identifyId),
            ("{{ anonymous_access }}", User.current.basicInfo?.isGuest == true ? "True" : "False"),
            ("{{ can_create_sheet }}", "1"),
            ("{{ departmentId }}", "0"),
            ("{{client_vars|safe}}", "null"),
            ("{{navigator_env}}", OpenAPI.DocsDebugEnv.nameForH5),
            ("\"{{ app_config }}\"", DocsSDK.appConfigForFrontEndStr),
            ("{{lang_cdn}}", langJsFilePath),
            ("{{ theme }}", theme),
            ("{{ language }}", I18n.currentLanguage().languageIdentifier),
            ("{{ enable_et_test }}", CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.enableEtTest) ? "true" : "false"),
            ("{{ darkmode_enable }}", darkmodeEnabled),
            ("{{ comment_disable_rn }}", "True"),
            ("{{ disk_crypto_enable }}", CacheService.isDiskCryptoEnable() ? "True" : "False")
        ]
        DocsLogger.info("darkmode.service --- inject template darkmode_enable \(darkmodeEnabled), current theme: \(theme), iframeJsbCheck: \(identifyId) ")

        if let globalConfigStr = DomainConfig.globalConfigStr, !globalConfigStr.isEmpty {
            map.append(("\"{{ domain_characteristic_config }}\"", globalConfigStr))
            DocsLogger.debug("web inject template domain_characteristic_config：\(globalConfigStr)")
        }
        
        var globalKaConfig: String = "{}"
        if let config = DocsSDK.getDynamicFeatureConfig(for: "/Hybrid_Material.json"), !config.isEmpty {
            globalKaConfig = config
            DocsLogger.info("web inject template globalKaConfig(from lark), length is \(globalKaConfig.count)")
        } else {
            DocsLogger.info("web inject template globalKaConfig(use default empty json)：\(globalKaConfig)")
        }
        map.append(("\"{{ globalKaConfig }}\"", globalKaConfig))

        // 注入本地的调试信息
        let debugConfig = ["isDebug": OpenAPI.docs.shouldShowFileOpenBasicInfo]
        let debugConfigStr = debugConfig.jsonString
        map.append(("\"{{ app_debug_config }}\"", debugConfigStr ?? "{}"))
        map.append(("\"{{ device_info }}\"", "{\"platform\": \(SKDisplay.phone ? "1" : "2"), \"baseFontSize\": \"\(UDZoom.currentZoom.name)\"}"))
        
        if DomainConfig.isNewDomain {
            map.append(("{{navigator_path_prefix}}", DocsUrlUtil.h5PathPrefix))
            var apiPrefix = ""
            if let docsApiDomain = DomainConfig.ka.docsApiDomain, !docsApiDomain.isEmpty { //docsApiDomain不为空才注入
                apiPrefix = "https://" + docsApiDomain + DomainConfig.pathPrefix
            }
            map.append(("{{navigator_api_prefix}}", apiPrefix))
            DocsLogger.info("navigator_path_prefix is \(DocsUrlUtil.h5PathPrefix), navigator_api_prefix is \(apiPrefix)")
        }
        
        if UserScopeNoChangeFG.LJY.templateInjectFg || UserScopeNoChangeFG.LJY.injectTXTProfileFg {
            let fgValues = Container.shared.getCurrentUserResolver().resolve(WebFeatureGating.self)?.getWebFGJsonString() ?? "{}"
            map.append(("\"{{ mobile_fg_dictionary }}\"", fgValues))
        }
        
        map.forEach { (oldValue, newValue) in
            str = str.replacingOccurrences(of: oldValue, with: newValue)
        }
        ["{{ user_id }}",
         "{{ sz }}",
         "{{ host }}",
         "{{ ws_server }}",
         "{{ language }}",
         "{{ suid }}",
         "{{ tenant_id }}",
         "{{ department_id }}",
         "{{ ws_ticket }}",
         "{{ user_agent }}",
         "{{client_vars|safe}}"].forEach { (oldValue) in
            str = str.replacingOccurrences(of: oldValue, with: "")
        }
        return str
    }
    
    private static func subpageIndexHtmlData(url: URL) -> Data? {
        guard url.absoluteString.contains("mobile_subpage.html") else { return nil }
        guard let data = ResourceService.resource(resourceName: "mobile_subpage.html") else {
            DocsLogger.error("Failed to get mobile_subpage.html data")
            return nil
        }
        let jsFileName: String = "\(I18n.currentLanguageIdentifier()).js"
        var localLangFilePath: String
        if let path = GeckoPackageManager.shared.filesRootPath(for: .webInfo),
           let langFilePath = GeckoPackageManager.shared.getRelativeFilePath(at: path, of: jsFileName) {
            localLangFilePath = langFilePath
        } else {
            DocsLogger.error("Failed to get lang js file")
            localLangFilePath = "eesz/resource/bear/lang/"  + jsFileName
        }
        let scmVersion = GeckoPackageManager.shared.currentVersion(type: .webInfo)
        let langJsFilePath = "//sf3-scmcdn2-cn.feishucdn.com/" + localLangFilePath + "?v=\(scmVersion)"
        guard var str = String(data: data, encoding: .utf8),
              let userID = User.current.info?.userID,
              let tenantID = User.current.info?.tenantID else {
            DocsLogger.info("not loggin return default data")
            return data
        }
        var theme = "light"
        if #available(iOS 13.0, *) {
            let currentTheme = UDThemeManager.getRealUserInterfaceStyle()
            if currentTheme == .dark {
                theme = "dark"
            }
        }
        var map = [
            ("{{ user_id }}", userID),
            ("{{ tenant_id }}", tenantID),
            ("{{ anonymous_access }}", User.current.basicInfo?.isGuest == true ? "True" : "False"),
            ("{{ can_create_sheet }}", "1"),
            ("{{ departmentId }}", "0"),
            ("{{client_vars|safe}}", "null"),
            ("{{navigator_env}}", OpenAPI.DocsDebugEnv.nameForH5),
            ("\"{{ app_config }}\"", DocsSDK.appConfigForFrontEndStr),
            ("{{lang_cdn}}", langJsFilePath),
            ("{{ theme }}", theme),
            ("{{ language }}", I18n.currentLanguage().languageIdentifier),
            ("{{ enable_et_test }}", CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.enableEtTest) ? "true" : "false"),
            ("{{ darkmode_enable }}", "True"),
            ("{{ comment_disable_rn }}", "True"),
            ("{{ disk_crypto_enable }}", CacheService.isDiskCryptoEnable() ? "True" : "False")
        ]
        DocsLogger.info("darkmode.service theme: \(theme)")
        if let globalConfigStr = DomainConfig.globalConfigStr, !globalConfigStr.isEmpty {
            map.append(("\"{{ domain_characteristic_config }}\"", globalConfigStr))
            DocsLogger.debug("web fe domain_characteristic_config：\(globalConfigStr)")
        }
        var globalKaConfig: String = "{}"
        if let config = DocsSDK.getDynamicFeatureConfig(for: "/Hybrid_Material.json"), !config.isEmpty {
            globalKaConfig = config
            DocsLogger.info("web fe globalKaConfig(from lark), length is \(globalKaConfig.count)")
        } else {
            DocsLogger.info("web fe globalKaConfig(use default empty json)：\(globalKaConfig)")
        }
        map.append(("\"{{ globalKaConfig }}\"", globalKaConfig))
        let debugConfig = ["isDebug": OpenAPI.docs.shouldShowFileOpenBasicInfo]
        let debugConfigStr = debugConfig.jsonString
        map.append(("\"{{ app_debug_config }}\"", debugConfigStr ?? "{}"))
        map.append(("\"{{ device_info }}\"", "{\"platform\": \(SKDisplay.phone ? "1" : "2"), \"baseFontSize\": \"\(UDZoom.currentZoom.name)\"}"))
        
        if DomainConfig.isNewDomain {
            map.append(("{{navigator_path_prefix}}", DocsUrlUtil.h5PathPrefix))
            var apiPrefix = ""
            if let docsApiDomain = DomainConfig.ka.docsApiDomain, !docsApiDomain.isEmpty {
                apiPrefix = "https://" + docsApiDomain + DomainConfig.pathPrefix
            }
            map.append(("{{navigator_api_prefix}}", apiPrefix))
            DocsLogger.info("navigator_path_prefix is \(DocsUrlUtil.h5PathPrefix), navigator_api_prefix is \(apiPrefix)")
        }
        map.forEach { (oldValue, newValue) in
            str = str.replacingOccurrences(of: oldValue, with: newValue)
        }
        ["{{ user_id }}",
         "{{ sz }}",
         "{{ host }}",
         "{{ ws_server }}",
         "{{ language }}",
         "{{ suid }}",
         "{{ tenant_id }}",
         "{{ department_id }}",
         "{{ ws_ticket }}",
         "{{ user_agent }}",
         "{{client_vars|safe}}"].forEach { (oldValue) in
            str = str.replacingOccurrences(of: oldValue, with: "")
        }
        return str.data(using: .utf8)
    }
}

extension ResourceService {
    enum PkgType {
        /// 当前locator指向的资源包类型
        case curUsing
        /// 内嵌包解压的资源包
        case bundleUnzip
        /// 兜底用的资源包
        case savior
    }

    class func resource(resourceName: String) -> Data? {
        isReadingLocalJSFile.accept(true); defer { isReadingLocalJSFile.accept(false) }
            guard !resourceName.isEmpty else { return nil }

        /// 为了实现 找不到就“降级”去其他目录找的兜底逻辑，不要轻易修改
        if let filePath = checkIfExist(resourceName: resourceName, pkgType: .curUsing),
            let data = readDataFromDisk(at: filePath) {
            return data
        }

        //加个fg去掉这里的兜底
        if UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
            if  let filePath = checkIfExist(resourceName: resourceName, pkgType: .bundleUnzip),
                let data = readDataFromDisk(at: filePath) {
                return data
            }
        }
        if let filePath = checkIfExist(resourceName: resourceName, pkgType: .savior),
            let data = readDataFromDisk(at: filePath) {
            return data
        }
        return nil
    }

    private static func checkIfExist(resourceName: String, pkgType: PkgType) -> SKFilePath? {
        // 后续需要考量性能耗时问题
        let mgr = GeckoPackageManager.shared
        var folder: SKFilePath
        switch pkgType {
        case .curUsing:
            folder = mgr.filesRootPath(for: GeckoChannleType.webInfo) ?? SKFilePath.absPath("")
        case .bundleUnzip:
            folder = self.root
        case .savior:
            folder = mgr.getSaviorPkgPath()
        }
        guard !folder.isEmpty else { return nil }

        return mgr.checkIfExist(feResourceName: resourceName, in: folder)
    }

    private static func readDataFromDisk(at filePath: SKFilePath) -> Data? {
        do {
            return try Data.read(from: filePath, options: .mappedIfSafe)
        } catch {
            return nil
        }
    }

}
