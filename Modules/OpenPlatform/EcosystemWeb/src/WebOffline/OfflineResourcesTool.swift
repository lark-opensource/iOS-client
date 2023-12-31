import ECOInfra
import LKCommonsLogging
import OPWebApp
import WebBrowser

final class OfflineResourcesTool {
    
    static let logger = Logger.ecosystemWebLog(OfflineResourcesTool.self, category: "OfflineResourcesManager")
    
    static let shared = OfflineResourcesTool()
    
    /// 是否需要拦截请求
    /// - Returns: 是否拦截
    class func canIntercept(with request: URLRequest) -> Bool {
        let result = OPWebAppManager.sharedInstance.canInterceptWith(request)
        Self.logger.info("\(request.url?.safeURLString) canIntercept value is \(result)")
        return result
    }
    
    /// 获取资源
    class func fetchResources(with request: URLRequest, completionHandler: @escaping (Result<(URLResponse, Data), Error>) -> Void) {
        Self.logger.info("start fetch resources \(request.url?.safeURLString) from pkg resource manager")
        OPWebAppManager.sharedInstance.fetchResourceWith(request) { model in
            switch model {
            case .responseAndData(let uRLResponse, let data):
                Self.logger.info("recieve resources \(uRLResponse.url?.safeURLString) and type is \(uRLResponse.mimeType)")
                completionHandler(.success((uRLResponse, data)))
            case .fallbackRequest(let uRLRequest):
                // TODO: 等做fallback补充
                let msg = "fetch resources \(request.url?.safeURLString) from pkg resource manager need fallback to \(uRLRequest.url?.safeURLString) and backend has not support fallback"
                assertionFailure(msg)
                Self.logger.error(msg)
            case .error(let error):
                Self.logger.error("fetch resources \(request.url?.safeURLString) from pkg resource manager error", error: error)
                completionHandler(.failure(error))
            }
        }
    }
}

extension OfflineResourcesTool: OfflineResourceProtocol {
    
    func browserCanIntercept(browser: WebBrowser, request: URLRequest) -> Bool {
        return OfflineResourcesTool.canIntercept(with: request)
    }
    
    func browserFetchResources(browser: WebBrowser, request: URLRequest, completionHandler: @escaping (Result<(URLResponse, Data), Error>) -> Void) {
        OfflineResourcesTool.fetchResources(with: request) { result in
            completionHandler(result)
        }
    }
}
