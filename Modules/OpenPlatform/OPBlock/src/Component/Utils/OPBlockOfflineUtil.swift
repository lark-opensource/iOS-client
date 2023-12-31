import Foundation
import LarkSetting
import LarkWebViewContainer
import TTMicroApp
import WebBrowser
import LarkContainer
import OPBlockInterface

/// 灰度策略，最终将会演进为 wkHandler(>=iOS 12.2) + fallbackURL(<iOS 12.2) 的方案
enum OfflineType {
    case urlProtocol // 基于 urlProtocol 的拦截方案(未来会下掉)
    case fallbackURL // fallback 方案（兜底降级方案）
    case wkHandler   // 基于 wkHandler 的拦截方案(试验方案)
}

final class OPBlockOfflineUtil {
    private let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func resourceInterceptConfiguration(appID: String, delegate: OfflineResourceProtocol) -> (Set<String>, WKResourceInterceptProtocol)? {
        if offlineType(appID: appID) == .wkHandler {
            //  如果不使用fallback，直接开启拦截并加载离线资源
            return (offline_v2_schemes(), WKResourceInterceptAdapter(delegate: delegate))
        }
        // iOS 12.2 以下，或者使用fallback，不走这里的拦截方案
        return nil
    }
    
    /// 根据当前宿主环境组装 fallback url 列表
    func fallbackUrls(fallbackPathList: [String], mainPath: String) -> [URL] {
        let fallbackUrls: [URL] = fallbackPathList.compactMap { fallbackURL in
            var mainPath = mainPath
            if !fallbackURL.hasSuffix("/"), !mainPath.starts(with: "/") {
                mainPath = "/" + mainPath
            }
            let urlString = fallbackURL + mainPath
            if let url = URL(string: urlString) {
                return url
            }
            return nil
        }
        return fallbackUrls
    }
    
    /// 根据当前宿主环境选择拦截方案（支持按 appID 灰度）
    func offlineType(appID: String) -> OfflineType {
        if userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableOfflineWKURLSchemaHandler.key) {
            if #available(iOS 12.2, *), !offline_v2_useFallbackURLs(appID: appID) {
                return OfflineType.wkHandler
            }
            
            //  此FG只用于URLProtocol下线前，URLProtocol删除的时候删掉这行if以及else内的代码
            if userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableOfflineUseFallback.key) {
                return OfflineType.fallbackURL
            }
        }
        return OfflineType.urlProtocol
    }
    
    /// 强制切换 http 保障
    func fixedVHost(_ vHost: String) -> String {
        return convert_https_to_http() ? vHost.replaceFirst(of: "https://", with: "http://") : vHost
    }
    
    /// 根据当前宿主需求获取需要拦截的 schema 列表
    private func offline_v2_schemes() -> Set<String> {
        guard let offline_v2 = LarkWebSettings.shared.settings?["offline_v2"] as? [String: Any] else {
            return ["http"]
        }
        guard let schemes = offline_v2["schemes"] as? Set<String> else {
            return ["http"]
        }
        guard !schemes.isEmpty else {
            return ["http"]
        }
        return schemes
    }
    
    /// 根据当前宿主环境选择拦截方案（支持按 appID 灰度）
    private func offline_v2_useFallbackURLs(appID: String) -> Bool {
        guard let offline_v2 = LarkWebSettings.shared.settings?["offline_v2"] as? [String: Any] else {
            return false
        }
        guard let use_fallback = offline_v2["use_fallback"] as? Bool else {
            guard let fallback_appids = offline_v2["fallback_appids"] as? [String] else {
                return false
            }
            return fallback_appids.contains(appID)
        }
        return use_fallback
    }
    
    /// 离线拦截是否强制改 http
    private func convert_https_to_http() -> Bool {
        guard let offline_v2 = LarkWebSettings.shared.settings?["offline_v2"] as? [String: Any] else {
            return false
        }
        guard let convert_https_to_http = offline_v2["convert_https_to_http"] as? Bool else {
            return false
        }
        return convert_https_to_http
    }
}

fileprivate class WKResourceInterceptAdapter: WKResourceInterceptProtocol {
    
    private weak var delegate: OfflineResourceProtocol?
        
    fileprivate init(delegate: OfflineResourceProtocol) {
        self.delegate = delegate
    }
    
    func shouldInterceptRequest(webView: WKWebView, request: URLRequest, completionHandler: @escaping (Result<(URLResponse, Data), Error>?) -> Void) {
        guard let delegate = delegate else {
            completionHandler(nil)
            return
        }
        guard let browser = webView.wkWeakBindWebBrowser else {
            completionHandler(nil)
            return
        }
        guard delegate.browserCanIntercept(browser: browser, request: request) else {
            completionHandler(nil)
            return
        }
        delegate.browserFetchResources(browser: browser, request: request) { result in
            completionHandler(result)
        }
    }
    
    var jssdk: String = CommonComponentResourceManager().fetchJSWithSepcificKey(componentName: "js_for_schemehandler") ?? ""
    
}

extension String {
    func replaceFirst(of p: String, with r: String) -> String {
        if let range = range(of: p) {
            return replacingCharacters(in: range, with: r)
        } else {
            return self
        }
    }
}
