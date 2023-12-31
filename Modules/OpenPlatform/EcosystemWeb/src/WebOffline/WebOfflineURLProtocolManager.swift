import LarkWebViewContainer
import LKCommonsLogging
import Foundation

/**
 Web 离线化 URLProtocol 拦截管理器
 请在主线程调用
 */
final class WebOfflineURLProtocolManager {
    
    static let logger = Logger.ecosystemWebLog(WebOfflineURLProtocolManager.self, category: "WebOfflineURLProtocolManager")
    
    /// 开启离线化业务的itemID列表
    private var offlineItemIDSet = Set<String>()
    
    /// 单例
    static let shared = WebOfflineURLProtocolManager()
    
    /// 单例
    private init() {}
    
    //  请使用方保障调用了start后一定要在准确时机调用stop，千万不要调用了start而不调用stop，否则需要revert代码，写case study，做复盘，承担事故责任
    func startOffline(with itemID: String) {
        assert(Thread.isMainThread, "please use WebOfflineURLProtocolManager in main thread, 如果在非主线程调用导致事故，需要revert代码，写case study，做复盘，承担事故责任")
        guard !offlineItemIDSet.contains(itemID) else {
            Self.logger.info("has marked \(itemID) offline")
            return
        }
        if offlineItemIDSet.isEmpty {
            Self.logger.info("offlineItemIDSet is empty, start register URLProtocol open ajax/fetch hook, and mark \(itemID) start offline")
            LarkWebView.register(scheme: "http")
            LarkWebView.register(scheme: "https")
            URLProtocol.registerClass(WebOfflineURLProtocol.self)
            URLProtocol.registerClass(BodyRecoverURLProtocol.self)
            ajaxFetchHookFG = true
        } else {
            Self.logger.info("offlineItemIDSet is not empty, mark \(itemID) start offline")
        }
        offlineItemIDSet.insert(itemID)
    }
    
    func stopOffline(with itemID: String) {
        assert(Thread.isMainThread, "please use WebOfflineURLProtocolManager in main thread, 如果在非主线程调用导致事故，需要revert代码，写case study，做复盘，承担事故责任")
        guard offlineItemIDSet.contains(itemID) else {
            Self.logger.info("offlineItemIDSet not contains \(itemID)")
            return
        }
        offlineItemIDSet.remove(itemID)
        if offlineItemIDSet.isEmpty {
            Self.logger.info("offlineItemIDSet is empty, unregister URLProtocol close ajax/fetch hook, and mark \(itemID) stop offline")
            LarkWebView.unregister(scheme: "http")
            LarkWebView.unregister(scheme: "https")
            URLProtocol.unregisterClass(WebOfflineURLProtocol.self)
            URLProtocol.unregisterClass(BodyRecoverURLProtocol.self)
            ajaxFetchHookFG = false
        } else {
            Self.logger.info("offlineItemIDSet is not empty, mark \(itemID) stop offline")
        }
    }
}
