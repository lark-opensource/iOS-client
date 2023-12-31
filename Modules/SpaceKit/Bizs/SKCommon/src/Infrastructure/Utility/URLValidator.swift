//
//  URLValidator.swift
//  Docs
//
//  Created by weidong fu on 4/2/2018.
//

import Foundation
import SwiftyJSON
import SKFoundation
import LarkReleaseConfig
import SpaceInterface
import SKInfra

public struct URLValidator {

    public static let versionParam = "dmVyc2lvb"

    public static func pathAfterBaseUrl(_ url: URL) -> String? {
        spaceAssert(URLValidator.isDocsURL(url))
        if !URLValidator.isDocsURL(url) { return nil }
        if DomainConfig.isNewDomain,
            url.host == OpenAPI.DocsDebugEnv.legacyHost,
            !NetConfig.shared.busness.isEmpty {
            return "/" + NetConfig.shared.busness + url.path
        }
        return url.path
    }

    public static func canOpen(_ url: String) -> Bool {
        guard let testURL = URL(string: url), URLValidator.isDocsURL(testURL) else {
            return false
        }
        if DocsSDK.isInDocsApp == false, testURL.path.hasPrefix("/help/") {
            return false
        }

        if !checkCanOpenInSimpleMode(testURL) {
            return false
        }
        return true
    }

    /// 精简模式下拦截掉不允许出现的UI
    private static func checkCanOpenInSimpleMode(_ url: URL) -> Bool {
        guard !DocsConfigManager.isShowFolder else { return true }

        /*
            拦截url跳转，不让进入收藏、手动离线、文件夹，wiki首页，bitable首页.
            手动离线tab目前没有配置跳转逻辑
         */
        if !url.path.isEmpty,
            DocsUrlUtil.disableDestinationPathsInSimpleMode[(url.path + "/")] != nil {
            return false
        }
        let disableTypes: [DocsType] = [.folder]
        if let type = DocsUrlUtil.getFileType(from: url), disableTypes.contains(type) { return false }

        return true
    }

    /// 是否是合法的，可以被打开的Docs的URL
    ///
    /// - Parameters:
    ///   - url: 传入的url
    /// - Returns: 是否是合法的url
    public static func isDocsURL(_ url: URL) -> Bool {
        func isMatchPattern(_ pattern: String) -> Bool {
            let pattern = pattern.lowercased()
            guard let host = url.host else { return false }
            guard host.range(of: "..") == nil else { return false }
            var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponent?.query = nil
            urlComponent?.fragment = nil
            let urlToMatch = urlComponent?.url ?? url
            return !urlToMatch.absoluteString.matches(for: pattern).isEmpty
        }
        if url.absoluteString.contains("/sync/"), !DocsType.enableDocTypeDependOnFeatureGating(type: .sync) || url.queryParameters["routeFromSync"] == "true" {
            //FG不生效或query中有routeFromSync字段则不拦截，路由到网页容器打开，最终会重定向到源文档
            return false
        }
        if DomainConfig.validUrlPatternsV2.contains(where: { isMatchPattern($0) }) {
            return true
        }
        if url.docs.changeSchemeTo(OpenAPI.docs.currentNetScheme) == DocsUrlUtil.mainFrameTemplateURL() {
            return true
        }
        if isBitableAppURL(url) {
            return true
        }
        //处理历史和代理到前端的功能
        return DomainConfig.localValidHosts.contains { $0 == url.hostAndPort }
    }

    ///  根据URL，返回是否支持打开以及文档的类型信息
    ///
    /// - Parameter url: 需要判断的url
    /// - Returns: 元组，第一个变量是是否支持，第二个变量是文件类型, 第三个变量是文档的token
    public static func isSupportURLRawtype(url: URL) -> (Bool, type: DocsType, token: String) {
        if !isDocsURL(url) { return (false, .unknownDefaultType, "") }
        guard let fileType = DocsUrlUtil.getFileType(from: url),
            let token = DocsUrlUtil.getFileToken(from: url) else {
                return (false, .unknownDefaultType, "")
        }
        // 对wiki进行特殊处理，判断wiki对应的单品在当前版本是否支持用wiki打开
        if fileType == .wiki {
            return (true, fileType, token)
        }
        let ignoreTypes: [DocsType] = [.trash, .myFolder]
        guard fileType.isSupportedType, !ignoreTypes.contains(fileType) else {
            return (false, fileType, "")
        }

        // phoenix 进行特殊处理，根据 FG 进行屏蔽
        if url.path.starts(with: "/" + H5UrlPathConfig.phoenixPathPrefix) {
            guard LKFeatureGating.phoenixEnabled else {
                return (false, fileType, token)
            }
        }
        return (true, fileType, token)
    }

    ///  根据URL，返回是否支持打开以及文档的类型信息
    ///
    /// - Parameter url: 需要判断的url
    /// - Returns: 元组，第一个变量是是否支持，第二个变量是文件类型, 第三个变量是文档的token
    public static func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
        let (isSupported, type, token) = isSupportURLRawtype(url: url)
        return (isSupported, type.name, token)
    }

    /// 把url转为标准的url（域名有变化）不涉及scheme变化
    /// 仅可用在打开文档时！！！！
    /// - "docs.bytedance.net/xxx" -> "a.feishu.cn/space/xxx"
    /// - "b.feishu.cn/space/xxx" -> "a.feishu.cn/space/xxx"
    /// - "a.feishu.cn/space/xxx" -> "192.168.34.3:3001/space/xxx" 如果设置了前端代理
    /// - 'a.feishu.cn/space/xxx' -> 'doc-staging.bytedance.net/'  如果设置了staging环境
    ///
    /// - Parameter url: 转化前的url
    /// - Returns: 转换后的url
    public static func standardizeDocURL(_ url: URL) -> URL {
        spaceAssert(URLValidator.isDocsURL(url))
        if !URLValidator.isDocsURL(url) { return url }
        guard var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        // path
        let fileInfo = DocsUrlUtil.getFileInfoFrom(url)
        if let type = fileInfo.type, let token = fileInfo.token {
            urlComponent.path = DocsUrlUtil.url(type: type, token: token, originUrl: url).path
        }
        
        // mg域名优化，这里就不替换成userDomain，保持原来的域名
        if !UserScopeNoChangeFG.HZK.mgDomainOptimize {
            // host
            if DomainConfig.isNewDomain {
                urlComponent.host = DomainConfig.userDomain
            } else {
                urlComponent.host = OpenAPI.DocsDebugEnv.legacyHost
            }
        }
        
        //处理前端代理
        if OpenAPI.docs.isAgentToFrontEndActive {
            let subStrs = OpenAPI.docs.frontendHost.split(separator: ":")
            spaceAssert(subStrs.count == 2, "前端代理设置不正确")
            if let host = subStrs.first, let port = Int(String(subStrs.last!)) {
                urlComponent.host = String(host)
                urlComponent.port = port
            }
        }
        return urlComponent.url ?? url
    }

    ///  是否是预加载的url
    ///
    /// - Parameter url: url
    /// - Returns: true，是预加载的；false，不是预加载的
    public static func isMainFrameTemplateURL(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        if url.lastPathComponent == "blank", isDocsURL(url) {
            return true
        }
        return false
    }
    
    ///  是否是SSR模板的url
    ///
    /// - Parameter url: url
    public static func isSSRTemplateURL(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        if url.lastPathComponent == "ssr_template", url.scheme == DocSourceURLProtocolService.scheme {
            return true
        }
        return false
    }

    /// 是否是要打开点赞列表
    ///
    /// - Parameter url: 需要判断的url
    /// - Returns: yes，是最近打开；false，不是最近打开
    public static func isLikeListURL(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        guard URLValidator.isDocsURL(url) else { return false }
        if URLValidator.isMainFrameTemplateURL(url) {
            return false
        }
        if DocLikesType.likeTypeBy(url: url) == nil {
            return false
        }
        guard let queryInfos = url.docs.queryParams else { return false }
        if let likeMark = queryInfos["show_like_list"], likeMark.elementsEqual("1"),
           let fromSource = queryInfos["from"], fromSource.elementsEqual("single_innerlink") {
            // 仅当 URL 含有 show_like_list=1，且 from 是 "single_innerlink" 才能直接跳转点赞列表
            // 本来应该用 from=prise_notice, 但是IM 卡片会把 from 替换为 single_innerlink
            // 可能存在其他场景打开 from=single_innerlink 的 badcase
            return true
        }
        return false
    }

//    public static func isTemplateCenterURL(_ url: URL?) -> Bool {
//        guard let url = url else { return false }
//        guard URLValidator.isDocsURL(url) else { return false }
//        return url.path == "/drive/template-center"
//    }

    /// 仅对KA有效，V3.35，2020-11-27新增，用来判断url的path中是否能匹配出type(docs/sheet...) 和token，不校验域名，是为了跨租户打开匿名文档
    /// - Parameter url: 目标url
    /// - Returns: 是否是Doc文档类url
    public static func isDocsTypeUrlInKA(url: URL) -> Bool {
        guard ReleaseConfig.isPrivateKA else {
            return false
        }

        let urlStr = url.absoluteString
        let (token, type) = DocsUrlUtil.getFileInfoFrom(url)
        guard let realToken = token, !realToken.isEmpty,
              let realType = type, realType != .unknown(realType.rawValue) else { return false }

        return true
    }

    /// V3.35 新增，判断在KA中是否能打开Saas 的docs类文档url, 临时方案，后台未做互通，移动端都没有做打开其他租户【可匿名访问文档】的功能
    /// - Parameter url: 目标url
    /// - Returns: 如果可以打开，返回true，后续使用SaverWebViewController打开
    public static func checkIfCanOpenSaasURLInKA(url: URL) -> Bool {
        guard ReleaseConfig.isPrivateKA,
              isDocsTypeUrlInKA(url: url) // 如果是docs文档url
        else {
            return false
        }

        // KA 暂时没有海外版一说，所以就临时方案而言，判断 suiteMainDomain 一个就行，但是是另外租户的domain，就判断能打开，使用SaverWebViewController
        if let suiteMainDomain = DomainConfig.ka.suiteMainDomain,
           !suiteMainDomain.isEmpty,
           let host = url.host,
           !host.hasSuffix(suiteMainDomain) {
            return true
        }

        return false
    }

    /// 是否是文件夹路径。如果是，返回文件夹的token，否则返回nil
    ///
    /// - Parameter url: 传递来的url
    /// - Returns: 文件夹的token
    public static func getFolderPath(url: URL?) -> String? {
        guard let url = url else { return nil }
        guard URLValidator.isDocsURL(url) else { return nil }
        let fileInfo = DocsUrlUtil.getFileInfoFrom(url)
        guard fileInfo.type == DocsType.folder else {
            return nil
        }
        return fileInfo.token
    }

    public static func isWikiHomePath(url: URL?) -> Bool {
        guard let url = url else { return false }
        guard URLValidator.isDocsURL(url) else { return false }
        guard let path = pathAfterBaseUrl(url),
            let dest = DocsUrlUtil.jumpDirectionfor(path) else {
                return false
        }
        return dest == .wikiHome
    }

    public static func isBitableAppURL(_ url: URL) -> Bool {
        // 检查 host 是否是 bitable 飞书域名
        guard url.host == "bitable.feishu.cn" else { return false }
        // path 就是完整 token，对完整的 path 进行正则匹配
        let token = url.path
        do {
            // 注意 path 有一个先导 / 符号
            let tokenPattern = try NSRegularExpression(pattern: "^/app(\\w{24}|\\w{19})$")
            guard tokenPattern.firstMatch(in: token, range: NSRange(location: 0, length: (token as NSString).length)) != nil else {
                // path 不符合 token 模式
                return false
            }
            return true
        } catch {
            DocsLogger.error("bitable app expression pattern error", error: error)
            return false
        }
    }

    public static func isWikiSpacePath(url: URL?) -> Bool {
        guard let url = url else { return false }
        guard URLValidator.isDocsURL(url) else { return false }
        guard let path = pathAfterBaseUrl(url) else {
            return false
        }
        let allowList = ["wiki/space", "wiki/settings"]
        guard allowList.first(where: path.contains) != nil else {
            return false
        }
        return true
    }
    public static func isWikiTrashPath(url: URL?) -> Bool {
        guard let url = url else { return false }
        guard URLValidator.isDocsURL(url) else { return false }
        guard let path = pathAfterBaseUrl(url),
              path.contains("wiki/trash") else {
                return false
        }
        return true
    }
    /// 是否命中黑名单的Path，名单内的Path不进入native兜底页，使用WebView兜底
    public static func isBlackPath(url: URL) -> Bool {
        guard let pattern = DomainConfig.blackPathPattern else {
            return false
        }
        return !url.path.matches(for: pattern).isEmpty
    }
    // 文档版本格式：https://bytedance.us.feishu.cn/docx/[源DocX Token]?edition_id=[版本号]
    public static func isDocsVersionUrl(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        guard URLValidator.isDocsURL(url) else { return false }
        if URLValidator.isMainFrameTemplateURL(url) {
            return false
        }
        guard let query = url.docs.queryParams?["edition_id"] else { return false }
        return true
    }
    
    // 打开文档url替换处理
    public static func replaceOriginUrlIfNeed(originUrl: URL, domainConfig: [String: Any]? = SettingConfig.domainConfig) -> URL? {
        
        // 取出文档url host
        guard var components = URLComponents(url: originUrl, resolvingAgainstBaseURL: false),
              let originHost = components.host else {
            DocsLogger.error("components init failure", component: LogComponents.replaceDocOriginUrl)
            return nil
        }
        
        // 获取下发的匹配url正则： "(bytedance(\\.(sg|us|jp))?)\\.feishu\\.cn"
        guard let regexPattern = domainConfig?[DomainConfigKey.previousDomainReg.rawValue] as? String,
              !regexPattern.isEmpty else {
            DocsLogger.info("setting previousDomainReg is nil", component: LogComponents.replaceDocOriginUrl)
            return nil
        }
        
        // 获取下发的替换url正则："$1.larkoffice.com"
        guard let previousDomainReg = domainConfig?[DomainConfigKey.newDomainReplacement.rawValue] as? String,
              !previousDomainReg.isEmpty else {
            DocsLogger.info("setting newDomainReplacement is nil", component: LogComponents.replaceDocOriginUrl)
            return nil
        }
        
        do {
            // 正则匹配
            let regex = try NSRegularExpression(pattern: regexPattern)
            let range = NSRange(originHost.startIndex..<originHost.endIndex, in: originHost)
            guard let result = regex.firstMatch(in: originHost, range: range) else {
                DocsLogger.info("did not match", component: LogComponents.replaceDocOriginUrl)
                return nil
            }
            
            // 匹配到则替换host
            let modifiedHost = regex.stringByReplacingMatches(in: originHost, range: result.range, withTemplate: previousDomainReg)
            components.host = modifiedHost
            
            guard let replaceUrl = components.url else {
                DocsLogger.error("match success，but replace host failure", component: LogComponents.replaceDocOriginUrl)
                return nil
            }
            DocsLogger.info("replace success", component: LogComponents.replaceDocOriginUrl)
            return replaceUrl
        } catch {
            DocsLogger.error("regular matching failure：\(error)", component: LogComponents.replaceDocOriginUrl)
            return nil
        }
        
    }
    

    public static func getVersionNum(_ url: URL?) -> String? {
        guard let url = url else { return nil }
        guard URLValidator.isDocsURL(url) else { return nil }
        if URLValidator.isMainFrameTemplateURL(url) {
            return nil
        }
        guard let query = url.docs.queryParams?["edition_id"] else { return nil }
        return query
    }

    public static func isInnerVersionUrl(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        guard URLValidator.isDocsURL(url) else { return false }
        if URLValidator.isMainFrameTemplateURL(url) {
            return false
        }
        guard let query = url.docs.queryParams?[versionParam] else { return false }
        return true
    }

    public static func isVCFollowUrl(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        guard URLValidator.isDocsURL(url) else { return false }
        if URLValidator.isMainFrameTemplateURL(url) {
            return false
        }
        guard let query = url.docs.queryParams?["from"] else { return false }
        if query == "vcFollow" {
            return true
        }
        return false
    }
}

// MARK: - 根据当前环境返回不同的域名
/// 个人认为这些域名判断逻辑应该放到DomainConfig中去，DomainConfig调用OpenAPI.DocsDebugEnv来判断该用哪个域名，现在由OpenAPI.DocsDebugEnv来管理域名判断逻辑，这个职责划分是不对的
extension OpenAPI.DocsDebugEnv {
    static var hostForNewMainlandDomain: String {
        switch Self.current {
        case .preRelease, .release: return DomainConfig.NewDomainHost.mainLandDomainRelease
        case .staging: return DomainConfig.NewDomainHost.mainLandDomainStaging
        }
    }

    static var hostForNewOverSeaDomain: String {
        switch Self.current {
        case .preRelease, .release: return DomainConfig.NewDomainHost.overSeaDomainRelease
        case .staging: return DomainConfig.NewDomainHost.overSeaDomainStaging
        }
    }

    //bytedance 帮助文档国内域名
    static var bdDocHostForNewMainlandDomain: String {
        switch Self.current {
        case .preRelease, .release: return judge(ka: DomainConfig.ka.docsHelpDomain,
                                                           old: "bytedance.feishu.cn")
        case .staging:                        return judge(ka: DomainConfig.ka.docsHelpDomainStaging,
                                                           old: "bytedance.feishu-staging.cn")
        }
    }

    //bytedance 帮助文档国外域名
    static var bdDocHostForNewOverSeaDomain: String {

        switch Self.current {
        case .preRelease, .release: return judge(ka: DomainConfig.ka.docsHelpDomain,
                                                           old: "bytedance.larksuite.com")
        case .staging:                        return judge(ka: DomainConfig.ka.docsHelpDomainOverSeaStaging,
                                                           old: "bytedance.larksuite-staging.com")
        }
    }

    static func judge(ka: String?, old defaultDomain: String) -> String {
        return DomainConfig.judgeToUse(ka: ka, or: defaultDomain)
    }

    static var docsLongConDomain: [String] {
        if let longDomainArray = DomainConfig.ka.longConDomain, !longDomainArray.isEmpty {
            return longDomainArray
        } else {
            DocsLogger.error("检查下，要求必须传入docsLongConDomain")
            assertionFailure()
            return []
        }
    }

    static var suiteMainDomain: String {
        switch Self.current {
        case .preRelease, .release:
            return judge(domain: DomainConfig.ka.suiteMainDomain, default: "feishu.cn")
        case .staging:
            return judge(domain: DomainConfig.ka.suiteMainDomain, default: "feishu-staging.cn")
        }
    }

    static var docsHomeDomain: String {
        switch Self.current {
        case .preRelease, .release:
            return judge(domain: DomainConfig.ka.docsHomeDomain, default: "bytedance.feishu.cn")
        case .staging:
            return judge(domain: DomainConfig.ka.docsHomeDomain, default: "bytedance.feishu-staging.cn")
        }
    }

    static private func judge(domain: String?, default deDomain: String) -> String {
        guard let domain = domain, !domain.isEmpty else {
            DocsLogger.info("检查下，要求必须传入domain，不能用default!!")
            assertionFailure()
            return deDomain
        }
        return domain
    }
}
