//
//  DocsUrlUtil.swift
//  SpaceKit
//
//  Created by Huang JinZhu on 2018/8/22.
//

import Foundation
import SwiftyJSON
import SKFoundation
import SpaceInterface
import SKInfra
//swiftlint:disable file_length line_length

public final class DocsUrlUtil {
    private struct Const {
        static let baseRecordPathPrefix = "/record/"
        static let baseAddPathPrefix = "/base/add/"
    }
    
    static func getFileInfoFrom(_ url: URL) -> (token: String?, type: DocsType?) {

        if H5UrlPathConfig.enable {
            return getFileInfoNewFrom(url)
        }

        guard let pattern = DocsUrlUtil.tokenPatternConfig["urlReg"],
            tokenPatternConfig["typeReg"] != nil, tokenPatternConfig["tokenReg"] != nil else {
                return (nil, nil)
        }
        let path = url.path
        var regex: NSRegularExpression!
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return (nil, nil)
        }
        var matched: [String: String] = [:]
        let nsrange = NSRange(path.startIndex..<path.endIndex, in: path)
        if let match = regex.firstMatch(in: path,
                                        options: [],
                                        range: nsrange) {
            for component in ["type", "token"] {
                var nsrange: NSRange = NSRange(location: NSNotFound, length: 0)
                nsrange = match.range(withName: component)
                if nsrange.location != NSNotFound,
                    let range = Range(nsrange, in: path) {
                    let str = path[range]
                    matched[component] = String(str)
                }
            }
        }
        return (matched["token"], matched["type"].flatMap { DocsType(name: $0) })
    }

    /// 3.10.0开始，使用新的url path 匹配和修改方式
    public static func getFileInfoNewFrom(_ url: URL) -> (token: String?, type: DocsType?) {

        let path = url.path
        guard let pathPattern = DocsUrlUtil.tokenPatternConfig["urlReg"],
              path.isMatch(for: pathPattern) else {
            DocsLogger.info("getFileInfoNewFrom match path failed")
            return (nil, nil)
        }

        let tokenPattern = H5UrlPathConfig.tokenPattern()
        let typePattern = H5UrlPathConfig.getTypePattern()

        let token = path.firstMatchedCaptureGroup(for: tokenPattern)
        // 从path中匹配
        guard let typeString = path.firstMatchedCaptureGroup(for: typePattern) else {
            return (token, nil)
        }
        // 根据配置中心下发的配置，映射对应的DocsType
        let (canOpen, type) = H5UrlPathConfig.getRealType(for: typeString)
        guard canOpen else {
            return (token, nil)
        }
        return (token, type)
    }

    public static func getFileType(from url: URL) -> DocsType? {
        return getFileInfoFrom(url).type
    }

    public static func getFileToken(from url: URL, with type: DocsType) -> String? {
        let fileInfo = getFileInfoFrom(url)
        guard fileInfo.type == type else {
            return nil
        }
        return fileInfo.token
    }

    public static func getFileToken(from url: URL) -> String? {
        return getFileInfoFrom(url).token
    }

    public static func getRenderPath(_ fileURL: URL, isAgentRepeatModuleEnable: Bool = OpenAPI.docs.isAgentRepeatModuleEnable ) -> String? {
        let fileInfo = getFileInfoFrom(fileURL)
        guard let type = fileInfo.type, let token = fileInfo.token,
            var urlComponent = URLComponents(url: fileURL, resolvingAgainstBaseURL: false),
            var hostRange = urlComponent.rangeOfHost else {
            return nil
        }
        //代理到前端情况下，如果url带有端口，需要截取端口后面部分的url
        //例如：http://192.169.0.10:3001/wiki，带有端口的url，这里截取出来是：3001/wiki，但期望结果是：/wiki 可以把这个也加入到注释里。
        if let portRange = urlComponent.rangeOfPort, isAgentRepeatModuleEnable {
            hostRange = portRange
        }
        urlComponent.path = url(type: type, token: token, originUrl: fileURL).path
        let strAfterHost = urlComponent.string?[hostRange.upperBound...]
        return strAfterHost.map { String($0) }
    }

    public static func changeUrl(_ url: URL, schemeTo scheme: String) -> URL {
        guard var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            DocsLogger.info("changeUrl Failed")
            return url
        }
        urlComponent.scheme = scheme
        return urlComponent.url ?? url
    }

    public static func getPath(type: DocsType, token: String, originURL: URL?, isPhoenixPath: Bool) -> String {
        let pathGenerator = pathGeneratorFor(type, isPhoenixPath: isPhoenixPath)
        var path = pathGenerator.replacingOccurrences(of: "${token}", with: token)
        if H5UrlPathConfig.enable, path.contains("/space") {
            path = path.replacingOccurrences(of: "/space", with: "") // 配合前端，如果传入space的情况，过滤掉
        }
        let productName = type.productName

        path = path.replacingOccurrences(of: "${type}", with: productName)

        // 表单分享链接 特殊处理，虽然是bitable类型，但是原来的share/base路径依然保留不替换
        if let originUrl = originURL, originUrl.path.contains("share/base") {
            path = originUrl.path
            if isPhoenixPath {
                path = "/" + H5UrlPathConfig.phoenixPathPrefix + path
            }
        }
        if let originUrl = originURL, isBaseRecordUrl(originUrl) {
            // record 分享链接，不要用 pathGenerator 进行替换
            path = originUrl.path
        }
        return path
    }

    // originUrl: 表单分享链接特殊处理，虽然是bitable类型，但是原来的share/base路径依然保留不替换，能拿到原始URL就都传入
    public static func url(type: DocsType, token: String, originUrl: URL? = nil, isPhoenixURL: Bool = false) -> URL {
        if !type.path.hasSuffix("/") {
            DocsLogger.warning("type:\(type) is not suffix with /, token:\(DocsTracker.encrypt(id: token))")
        }
        let path = getPath(type: type, token: token, originURL: originUrl, isPhoenixPath: isPhoenixURL)

        if let url = URL(string: OpenAPI.docs.baseUrlForDocs + path) {
            return url
        } else {
            var pathPreFix = ""
            if isPhoenixURL {
                // phoenix 优先级最高
                pathPreFix = "/" + H5UrlPathConfig.phoenixPathPrefix
            } else if type == .folder,
                      H5UrlPathConfig.enable {
                pathPreFix = "/" + H5UrlPathConfig.folderPathPrefix  // 3.10.0 版本开始, folder的path前缀为： /drive
            }
            let productName = type.productName
            guard let defaultUrl = URL(string: "https://" + DomainConfig.userDomainForDBDoc + pathPreFix + "/\(productName)/\(token)") else {
                DocsLogger.info("cannot gene default url, type is \(type.rawValue), token is \(DocsTracker.encrypt(id: token))")
                if DomainConfig.enableKADomain {
                    return URL(string: "https://\(DomainConfig.userDomainForDBDoc)")!
                }
                return URL(string: "https://www.feishu.cn")!
            }
            DocsLogger.info("cannot gene url, use default url")
            return defaultUrl
        }
    }
    
    public static func wikiSpaceURL(spaceID: String) -> URL? {
        var components = URLComponents()
        components.scheme = OpenAPI.docs.currentNetScheme
        components.host = DomainConfig.userDomainForDocs
        components.path =  "/wiki/space/" + spaceID
        let wikiSpaceURL = components.url

        return wikiSpaceURL
    }

    public static func mainFrameTemplateURL() -> URL {
        spaceAssert(mainFramePath.hasPrefix("/"))
        guard let mainURL = URL(string: OpenAPI.docs.baseUrlForDocs + mainFramePath) else {
            DocsLogger.info("get mainUrl Error, OpenAPI.docs.baseUrlForDocs is \(OpenAPI.docs.baseUrlForDocs), mainFramePath is \(mainFramePath)")

            let domain = OpenAPI.DocsDebugEnv.bdDocHostForNewMainlandDomain
            let defaultUrl = URL(string: "https://\(domain)/doc/blank")!
            return appendVersionParamForURL(defaultUrl)
        }
        return appendVersionParamForURL(mainURL)
    }
    
    public static func ssrFrameTemplateURL() -> URL? {
        let ssrTemplateUrl = URL(string: "\(DocSourceURLProtocolService.scheme)://\(DomainConfig.userDomainForDocs)/ssr_template")
        return ssrTemplateUrl
    }

    public static func appendVersionParamForURL(_ url: URL) -> URL {
        guard let version = OpenAPI.docs.apiVersion, version > 0 else { return url }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }

        let hasVerParam = components.queryItems?.contains { return $0.name == "v" }
        if hasVerParam != true {
            if components.queryItems == nil && components.path.last != "/" {
                components.path += "/"
            }

            var queryItems = components.queryItems ?? [URLQueryItem]()
            let queryItem = URLQueryItem(name: "v", value: "\(version)")
            queryItems.append(queryItem)
            components.queryItems = queryItems
        }
        return components.url ?? url
    }

    /// 前端传过来的url，可能需要修改host和path。处理这个逻辑
    ///    https://docs.bytedance.net/doc/6xt3w7IJSwtGbc4H2IVfyg?from=docs_feed
    ///
    /// - Parameter url: 转换前的url
    /// - Parameter webviewUrl: 当前网页的url
    /// - Returns: 转换后的url
    public static func changeUrlForNewDomain(_ url: URL, webviewUrl: URL?) -> URL {
        guard DomainConfig.isNewDomain else { return url }
        let needChange: Bool = {
            // 匹配图片请求
            if url.host == OpenAPI.DocsDebugEnv.legacyHost, url.path.hasPrefix("/file/f/") {
                return true
            }
            guard url.host == webviewUrl?.host else { return false }
            guard url.path.hasPrefix("/api/") else { return false }
            return true
        }()

        guard needChange else { return url }
        guard var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        urlComponent.host = DomainConfig.userDomainForRequest
        if !urlComponent.path.hasPrefix("/api") {
            urlComponent.path = "/api" + urlComponent.path
        }
        urlComponent.path = NetConfig.shared.busness.isEmpty ? urlComponent.path : ("/" + NetConfig.shared.busness + urlComponent.path)
        return urlComponent.url ?? url
    }

    public static func jumpDirectionfor(_ path: String) -> DocsSDK.DocsJumpDestination? {
        let components = path.lowercased().split(separator: "/")
        return pathDestinationMap[components]
    }

    /// 如果是各种类型的升级提示页，都统一转换成一种/space/app/upgrade，为了尽量少改旧逻辑
    public static func transformUpgradeUrl(_ url: URL) -> URL {
        guard url.path.contains("upgrade") else { return url }
        let map = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.domainConfigPathMap) ?? ""
        let destMap = generateBasePathDestinationMapFrom(map)
        let oriPath = url.path + "/"
        guard
            let path = destMap[oriPath],
            path == "upgrade" else {
            return url
        }

        guard var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        /*
         /drive/app/upgrade---->
         /app/upgrade ------>
         /space/app/upgrade
         */
        urlComponent.path = upgradePath

        guard let upgradeUrl = urlComponent.url else { return url }

        return upgradeUrl
    }

    public static func isDriveImageUrl(_ url: String) -> Bool {
        return url.contains(OpenAPI.APIPath.driveOriginalFileDownload) ||
        url.contains(OpenAPI.APIPath.driveFetchPreviewFile)
    }
    
    public static func isDriveImageUrlV2(_ url: String) -> Bool {
        return url.contains(OpenAPI.APIPath.driveOriginalFileDownload) ||
        url.contains(OpenAPI.APIPath.driveFetchPreviewFile) ||
        url.contains(OpenAPI.APIPath.thumbnailDownload)
    }
    
    public static func isBaseRecordUrl(_ url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        guard getFileType(from: url) == .bitable else {
            // Base 记录分享链接目前没有独立的文档类型，和 Bitable 使用了同一个类型
            // 后面支持独立类型之后，这个判断要去掉，改为直接判断类型即可
            return false
        }
        return url.path.hasPrefix(Const.baseRecordPathPrefix)
    }
    
    public static func isBaseAddUrl(_ url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        return getFileType(from: url) == .baseAdd
    }
    
    /// 返回文档 URL 的 Host，如果为空，则返回 Settings 下发 的 Host
    ///
    /// **注意**：如果是代理到前端了，返回 Settings 下发的 Host，而不是代理 Host
    public static func getHostFromDocsUrl(_ url: URL) -> String {
        if OpenAPI.docs.isAgentToFrontEndActive {
            return DomainConfig.userDomainForDocs
        }
        return getDocsCurrentUrlInfo(url).srcHost ?? DomainConfig.userDomainForDocs
    }
    
    public static func constructBaseRecordURL(_ token: String, host: String) -> URL? {
        return URL(string: "https://\(host)/record/\(token)")
    }
    
    public static func constructBaseAddURL(_ token: String, host: String, parameters: [String: String]? = nil) -> URL? {
        var url = URL(string: "https://\(host)/base/add/\(token)")
        if let parameters = parameters {
            url = url?.docs.addOrChangeEncodeQuery(parameters: parameters).url
        }
        return url
    }

    public static func getTokenFromDriveImageUrl(_ url: URL?) -> String? {
        guard let url = url, DocsUrlUtil.isDriveImageUrl(url.absoluteString) else {
            return nil
        }
        var token: String?
        if let t = url.path.components(separatedBy: "/").last {
            token = t
        } else if let t = url.absoluteString.components(separatedBy: "/").last?.components(separatedBy: "?").first {
            token = t
        }
        return token
    }
    
    public static func getTokenFromDriveImageUrlV2(_ url: URL?) -> String? {
        guard let url = url, DocsUrlUtil.isDriveImageUrlV2(url.absoluteString) else {
            return nil
        }
        var token: String?
        if let t = url.path.components(separatedBy: "/").last {
            token = t
        } else if let t = url.absoluteString.components(separatedBy: "/").last?.components(separatedBy: "?").first {
            token = t
        }
        return token
    }

    public static var mySpaceURL: URL {
        URL(string: "lark://ccm/space/me")!
    }
    
    public static var spaceFavoriteList: URL {
        URL(string: "lark://ccm/favorite/list")!
    }
    
    public static var cloudDriveMyFolderURL: URL {
        URL(string: "lark://ccm/cloudDrive/myFolder")!
    }

    // 判断url是否为订阅详情页
    public static func isSubscription(url: URL?) -> Bool {
        if let url = url, let subscription = url.docs.queryParams?["subscription"] {
            return subscription == "1"
        }
        return false
    }
}

//处理mg域名相关
extension DocsUrlUtil {
    
    //通过文档的链接，获取解析mg，返回当前文档mg对应的api相关信息
    public static func getDocsCurrentUrlInfo(_ url: URL) -> DocsUrlInfo {
        
        let urlInfo = DocsUrlInfo()
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            DocsLogger.info("getDocsCurrentUrlInfo url invalid: \(url)", component: LogComponents.version)
            return urlInfo
        }
        guard let host = components.host else {
            DocsLogger.info("getDocsCurrentUrlInfo host nil", component: LogComponents.version)
            return urlInfo
        }
        
        //host
        urlInfo.srcHost = host
        //文档url
        urlInfo.srcUrl = url.absoluteString
        //品牌
        let brandKey = self.matchingMgApiKeyWithRegex(host: host, regex: DomainConfig.ka.docsMgBrandRegex)
        urlInfo.brand = brandKey
        //所属mg
        let unitKey = self.matchingMgApiKeyWithRegex(host: host, regex: DomainConfig.ka.docsMgGeoRegex)
        urlInfo.unit = unitKey

        //文档api
        if let docsMgApiMap = DomainConfig.ka.docsMgApi,
           let brandMap = docsMgApiMap[brandKey],
           let mgApi = brandMap[unitKey],
              !mgApi.isEmpty {
            let docsApiPrefix = "https://" + mgApi + DomainConfig.pathPrefix
            urlInfo.docsApiPrefix = docsApiPrefix
        } else {
            DocsLogger.info("getDocsCurrentUrlInfo invalid,docsMgApi:\(String(describing: DomainConfig.ka.docsMgApi)),brandKey:\(brandKey),unitKey:\(unitKey)", component: LogComponents.version)
        }

        // 长链
        if let docsMgApiMap = DomainConfig.ka.docsMgFrontier,
              let brandMap = docsMgApiMap[brandKey],
              let frontierArr = brandMap[unitKey],
              !frontierArr.isEmpty {
            urlInfo.frontierDomain = frontierArr
             
        } else {
            DocsLogger.info("getDocsCurrentUrlInfo invalid,frontierDomain:\(String(describing: DomainConfig.ka.docsMgFrontier)),brandKey:\(brandKey),unitKey:\(unitKey)", component: LogComponents.version)
        }
        return urlInfo
    }
    
    /** 正则匹配，通过host，匹配所属的品牌，geo
     @host  文档host
     @regex 品牌和geo匹配规则： .feishu.|.larksuit.    和   .sg.|.jp.
     @return 返回匹配到的字符串，匹配不到，返回""
     */
    private static func matchingMgApiKeyWithRegex(host: String, regex: String?) -> String {
        var unitStr = ""
        
        guard !host.isEmpty, let regexStr = regex, !regexStr.isEmpty else {
            DocsLogger.info("matchingMgApiKeyWithRegex host or regex nil: \(host),\(regex ?? "")", component: LogComponents.version)
            return unitStr
        }
        do {
            let regexRegular = try NSRegularExpression(pattern: regexStr)
            let range = NSRange(location: 0, length: host.count)
            let matches = regexRegular.matches(in: host, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)
            
            if let match = matches.first, let range = Range(match.range(at: 0), in: host) {
                unitStr = String(host[range])
                DocsLogger.info("matchingMgApiKeyWithRegex match unitStr: \(unitStr)", component: LogComponents.version)
                if unitStr.count > 2 { // 取出来是 .sg. 或者 .feishu. 需要去掉前面和后面的点
                    unitStr = unitStr.mySubString(begin: 1, end: unitStr.count - 1)
                }
            }
            return unitStr
        } catch {
            DocsLogger.info("matchingMgApiKeyWithRegex error: \(error)", component: LogComponents.version)
            return unitStr
        }
    }
}

// 配置
extension DocsUrlUtil {
    private static let utilLock = NSLock()

    public static func updateConfig(_ config: JSON) {
        DocsLogger.info("updateConfig", component: LogComponents.net)
        let pathPrefix = config["h5PathPrefix"].string
        CCMKeyValue.globalUserDefault.set(pathPrefix, forKey: UserDefaultKeys.domainConfigH5PathPrefix)
        DocsLogger.info("h5PathPrefix become \(String(describing: pathPrefix))")

        let tokenTypePatternStr = config["tokenPattern"].rawString()
        CCMKeyValue.globalUserDefault.set(tokenTypePatternStr, forKey: UserDefaultKeys.domainConfigTokenTypePattern)
        let pathGeneratorStr = config["pathGenerator"].rawString()
        CCMKeyValue.globalUserDefault.set(pathGeneratorStr, forKey: UserDefaultKeys.domainConfigPathGenerator)
        let pathMapStr = config["pathMap"].rawString()
        CCMKeyValue.globalUserDefault.set(pathMapStr, forKey: UserDefaultKeys.domainConfigPathMap)

        utilLock.lock()
        _privatePathDestinationMap = nil
        _privateTokenPatternConfig = nil
        _privateDocPathGeneratorConfig = nil
        utilLock.unlock()
    }

    public static func resetConfig() {
        DocsLogger.info("reset url config", component: LogComponents.net)
        updateConfig(JSON())
        H5UrlPathConfig.reset()
    }

    static var h5PathPrefix: String {
        if H5UrlPathConfig.enable { return "" }
        return CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.domainConfigH5PathPrefix) ?? defaultH5PathPrefix
    }

    //tokenPatterns
    private static var _privateTokenPatternConfig: [String: String]?
    private static var tokenPatternConfig: [String: String] {
        utilLock.lock()
        defer {
            utilLock.unlock()
        }
        if _privateTokenPatternConfig == nil {
            let configStr = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.domainConfigTokenTypePattern) ?? ""
           _privateTokenPatternConfig = generateTokenPatternConfigFrom(configStr)
            DocsLogger.info("tokenPatternConfig become \(_privateTokenPatternConfig ?? [:])")
        }
        return _privateTokenPatternConfig ?? [:]
    }

    private static func generateTokenPatternConfigFrom(_ configStr: String) -> [String: String] {
        guard let tokenPatternConfig = JSON(parseJSON: configStr).dictionaryObject as? [String: String], !tokenPatternConfig.isEmpty else {
            return defaultTokenPattern
        }
        return tokenPatternConfig
    }

    //pathGenerator
    private static func pathGeneratorFor(_ type: DocsType, isPhoenixPath: Bool) -> String {
        if isPhoenixPath, let path = docPathGeneratorConfig["phoenix"] {
            return path
        }
        return docPathGeneratorConfig[type.name] ?? docPathGeneratorConfig["default"]!
    }

    private static var mainFramePath: String {
        return docPathGeneratorConfig["blank"] ?? "/space/blank/"
    }

    static var upgradePath: String {
        return docPathGeneratorConfig["upgrade"] ?? "/space/app/upgrade"
    }

    private static var _privateDocPathGeneratorConfig: [String: String]?
    private static var docPathGeneratorConfig: [String: String] {
        utilLock.lock()
        defer {
            utilLock.unlock()
        }
        if _privateDocPathGeneratorConfig == nil {
            let configStr = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.domainConfigPathGenerator) ?? ""
           _privateDocPathGeneratorConfig = generateDocPathGeneratorConfigFrom(configStr)
            DocsLogger.info("docPathGeneratorConfig become \(_privateDocPathGeneratorConfig ?? [:])")
        }
        return _privateDocPathGeneratorConfig ?? [:]
    }


    private static func generateDocPathGeneratorConfigFrom(_ configStr: String) -> [String: String] {
        guard let pathGenerator = JSON(parseJSON: configStr).dictionaryObject as? [String: String] else {
                return defaultPathGenerator
        }
        return pathGenerator
    }

    //pathDestinationMap
    private static var _privatePathDestinationMap: [[Substring]: DocsSDK.DocsJumpDestination]?
    private static var pathDestinationMap: [[Substring]: DocsSDK.DocsJumpDestination] {
        utilLock.lock()
        defer {
            utilLock.unlock()
        }
        if _privatePathDestinationMap == nil {
            let configStr = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.domainConfigPathMap) ?? ""
            _privatePathDestinationMap = generatePathDestinationMapFrom(configStr)
            DocsLogger.info("pathDestinationMap become \(_privatePathDestinationMap ?? [:])")
        }
        return _privatePathDestinationMap ?? [:]
    }

    private static func generateBasePathDestinationMapFrom(_ configStr: String) -> [String: String] {
        var dict = defaultPathDestinationMap
        if let map = JSON(parseJSON: configStr).dictionaryObject as? [String: String] {
            dict = map
        }
        return dict
    }
    private static func generatePathDestinationMapFrom(_ configStr: String) -> [[Substring]: DocsSDK.DocsJumpDestination] {
        let dict = generateBasePathDestinationMapFrom(configStr)

        var map: [[Substring]: DocsSDK.DocsJumpDestination] = [:]
        dict.forEach { (path, dest) in
            if let jumpDest = DocsSDK.DocsJumpDestination(rawValue: dest) {
                map[path.lowercased().split(separator: "/")] = jumpDest
            }
        }
        return map
    }

    //default configs
    private static let defaultPathGenerator: [String: String] = [
                                                            "default": "/${type}/${token}", // type没有命中，就用这个来匹配
                                                            "blank": "/blank/", //模板url
                                                            "upgrade": "/space/app/upgrade",
                                                            "baseAdd": "/base/add/${token}",
                                                            "phoenix": "/workspace/${type}/${token}"
    ]

    private static let defaultPathDestinationMap: [String: String] = [
                                            "/space/": "recent",
                                            "/space/home/recents/": "recent",
                                            "/space/home/": "recent",
                                            "/space/home/share/files/": "share",
                                            "/space/home/star/": "star",
                                            "/space/folder/": "folder",
                                            "/space/share/folders/": "share_root",
                                            "/space/shared/folders/": "share_root",
                                            "/space/native/newyearsurvey/": "newyear_survey",

                                            "/drive/": "recent",
                                            "/drive/home/": "recent",
                                            "/drive/home/recents/": "recent",
                                            "/drive/home/share/files/": "share",
                                            "/drive/home/star/": "star",
                                            "/drive/folder/": "folder",
                                            "/drive/share/folders/": "share_root",
                                            "/drive/shared/folders/": "share_root",
                                            "/drive/shared/": "share_root",
                                            "/drive/native/newyearsurvey/": "newyear_survey",
                                            "/drive/app/upgrade/": "upgrade",
                                            "/drive/help": "help",
                                            "/drive/help/doc/": "help",

                                            "/space/wiki/": "wiki_home",
                                            "/wiki/": "wiki_home",
                                            
                                            "/space/bitable/": "bitable_home",
                                            "/bitable/": "bitable_home"
    ]

    private static let defaultTokenPattern: [String: String] = [
                                    "tokenReg": "/([\\w]{10,})",
                                    "typeReg": "/(doc|docs|docx|sheet|sheets|mindnote|mindnotes|slide|slides|file|base/add|bitable|base|folder|wiki)/",
                                    "urlReg": "^(/space)?/(?<type>(doc|docs|docx|sheet|sheets|mindnote|mindnotes|slide|slides|file|base/add|bitable|base|folder|wiki))/(?<token>[^\\/]+)"]

    private static let defaultH5PathPrefix = ""

    public static let disableDestinationPathsInSimpleMode: [String: String] = [
                                            "/space/home/star/": "star",
                                            "/space/folder/": "folder",
                                            "/drive/home/star/": "star",
                                            "/drive/folder/": "folder",
                                            "/space/wiki/": "wiki_home",
                                            "/wiki/": "wiki_home",
                                            "/space/bitable/": "bitable_home",
                                            "/bitable/": "bitable_home"
    ]
}

public extension DocsSDK {
    enum DocsJumpDestination: String, Equatable {
        case home = "home"
        case shareFiles = "share"
        case recents = "recent"
        case star
        case folder
        case shareFolders = "share_root"
        case newYearSurvey = "newyear_survey"
        case favorites // 3.7开始被产品独立成一个大空间，FG控制
        case manualOffline // 3.8新增，FG控制

        case wikiHome = "wiki_home"
        
        case bitableHome = "bitable_home"

        // 避免wiki首页、bitable首页跳转到docs tab
        public var isInDocsTab: Bool {
            switch self {
            case .wikiHome, .bitableHome:
                return false
            default:
                return true
            }
        }
    }
}

public enum H5UrlPathConfig {
    // 配置中心的key是：url_path_change_config
    public static func saveToLocal(_ configDict: [String: Any]) {
        guard let configString = JSON(configDict).rawString(),
            !configString.isEmpty else {
                return
        }
        CCMKeyValue.globalUserDefault.set(configString, forKey: UserDefaultKeys.h5UrlPathConfig)
        ioLock.lock()
        curH5UrlPathConfig = nil
        ioLock.unlock()
    }
    private static func generateConfig(with configString: String) -> JSON {
        guard !configString.isEmpty else {
            return defaultH5UrlPathConfig
        }
        if curH5UrlPathConfig == nil {
            curH5UrlPathConfig = JSON(parseJSON: configString)
        }
        return curH5UrlPathConfig ?? defaultH5UrlPathConfig
    }
    private static var configJson: JSON {
        ioLock.lock()
        var json: JSON?
        if curH5UrlPathConfig == nil {
            let configStr = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.h5UrlPathConfig) ?? ""
            json = generateConfig(with: configStr)
        } else {
            json = curH5UrlPathConfig
        }
        ioLock.unlock()

        return json ?? defaultH5UrlPathConfig

    }

    static var enable: Bool {
        return configJson["newPathEnable"].boolValue
    }

    static func latestName(of type: DocsType) -> String {
        var name = ""
        switch type {
        case .doc, .sheet, .bitable, .slides, .mindnote, .file, .wiki, .folder, .docX, .wikiCatalog, .whiteboard, .sync, .baseAdd:
            name = latestMap[type.name] ?? ""
        case .mediaFile:
            name = latestMap[DocsType.file.name] ?? ""
        case .trash, .myFolder, .unknown, .minutes, .imMsgFile:
            DocsLogger.warning("不能走到这里来，不认这种类型的文件")
        }
        if name.isEmpty {
            name = type.name
        }
        return name
    }

    static func getTypePattern() -> String {
        guard let typePattern = configJson["tokenPattern"]["typeReg"].string, !typePattern.isEmpty else {
            return "/(doc|docs|docx|sheet|sheets|base/add|bitable|base|slide|slides|mindnote|mindnotes|file|folder|wiki)/"
        }
        return typePattern

//        let typePatterns = productMap.keys.joined(separator: "|")
//        if typePatterns.isEmpty {
//            spaceAssertionFailure("namePatterns can't be empty, set default latestMap to defaultH5UrlPathConfig ")
//            return "/(doc|docs|docx|sheet|sheets|bitable|base|slide|slides|mindnote|mindnotes|file|folder|wiki)/"
//        }
//        return "/(" + typePatterns + ")/"
    }

    private static func matchRealType(for latestTypeName: String) -> String? {
        var realTypeName: String?
        // 由于配合安卓临时改配置，这个方法暂时写成这样，兼容各种情况的map
        for (key, value) in latestMap where value == latestTypeName {
            realTypeName = key
        }

        if realTypeName == nil {
            for (key, value) in oldDefaultLatestMap where value == latestTypeName {
                realTypeName = key
            }
        }

        return realTypeName
    }

    static func getRealType(for typeName: String) -> (canOpen: Bool, realType: DocsType) {

        guard enable, !typeName.isEmpty else {
            return (false, .unknownDefaultType)
        }

        guard
            let latestTypeName = productMap[typeName],
            let uniqueTypeName = matchRealType(for: latestTypeName),
            let type = DocsType(name: uniqueTypeName)
            else {
            return (false, .unknownDefaultType)
        }

        return (true, type)
        /*
         productMap的结构如下：
         result["productMap"]["docs"]       = "doc"
         result["productMap"]["doc"]        = "doc"
         result["productMap"]["sheet"]      = "sheet"
         result["productMap"]["sheets"]     = "sheet"
         */

    }

    static var latestMap: [String: String] {
        var map = [String: String]()
        if let latestMapLo = configJson["lateastMap"].dictionaryObject as? [String: String] {
            map = latestMapLo
        } else if let defaultMap = defaultH5UrlPathConfig["lateastMap"].dictionaryObject as? [String: String] {
            map = defaultMap
        }
        return map
    }

    static var productMap: [String: String] {
        var map = [String: String]()
        if let latestMapLo = configJson["productMap"].dictionaryObject as? [String: String] {
            map = latestMapLo
        } else if let defaultMap = defaultH5UrlPathConfig["productMap"].dictionaryObject as? [String: String] {
            map = defaultMap
        }
        return map
    }

    static func tokenPattern() -> String {
        guard let tokenPattern = configJson["tokenReg"].string else {
            return defaultH5UrlPathConfig["tokenReg"].stringValue
        }
        return tokenPattern
    }
    
    

    static var folderPathPrefix: String {
        guard let folderPathPrefix = configJson["folderPathPrefix"].string else {
            return defaultH5UrlPathConfig["folderPathPrefix"].stringValue
        }
        return folderPathPrefix
    }

    static var phoenixPathPrefix: String {
        guard let folderPathPrefix = configJson["phoenixPathPrefix"].string else {
            return defaultH5UrlPathConfig["phoenixPathPrefix"].stringValue
        }
        return folderPathPrefix
    }

    static func getWhitePathList() -> [String]? {
        return configJson["whitePathList"].arrayObject as? [String]
    }

    static func getBlackPathList() -> [String]? {
        return configJson["blackPathList"].arrayObject as? [String]
    }

    static func reset() {
        CCMKeyValue.globalUserDefault.removeObject(forKey: UserDefaultKeys.h5UrlPathConfig)
        ioLock.lock()
        curH5UrlPathConfig = nil
        ioLock.unlock()
    }
}
// MARK: - 配置中心下发配置的默认值，用户退出登录的时候会设置为这些值
extension H5UrlPathConfig {
    private static let ioLock = NSLock()
    private static var curH5UrlPathConfig: JSON?
    static var defaultH5UrlPathConfig: JSON {
        var result = [String: Any]()

        result["enable"] = false
        let latestMap: [String: String] = ["doc": "docs",
                                           "docx": "docx",
                                           "sheet": "sheets",
                                           "baseAdd": "baseAdd",
                                           "bitable": "base",
                                           "slides": "slides",
                                           "mindnote": "mindnotes",
                                           "file": "file",
                                           "folder": "folder",
                                           "wiki": "wiki"
                                            ]
        result["lateastMap"] = latestMap

        let productMap: [String: String] = ["docs": "doc",
                                            "doc": "doc",
                                            "docx": "docx",
                                            "sheet": "sheet",
                                            "sheets": "sheet",
                                            "base/add": "baseAdd",
                                            "bitable": "bitable",
                                            "base": "bitable",
                                            "slide": "slide",
                                            "slides": "slides",
                                            "mindnote": "mindnote",
                                            "mindnotes": "mindnote",
                                            "file": "file",
                                            "folder": "folder",
                                            "wiki": "wiki"
                                            ]

        result["productMap"] = productMap
        result["tokenReg"]                       = "/([\\w]{14,})"
        result["folderPathPrefix"]               = "drive"
        result["phoenixPathPrefix"]              = "workspace"
        return JSON(result)
    }

    private static var oldDefaultLatestMap: [String: String] {
        let latestMap: [String: String] = ["doc": "doc",
                                           "docx": "docx",
                                           "sheet": "sheet",
                                           "bitable": "bitable",
                                           "slide": "slide",
                                           "mindnote": "mindnote",
                                           "file": "file",
                                           "folder": "folder",
                                           "wiki": "wiki"
                                            ]

        return latestMap
    }
}
