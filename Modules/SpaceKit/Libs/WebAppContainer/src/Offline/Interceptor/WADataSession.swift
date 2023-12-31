//
//  WADataSession.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/10/23.
//

import SKFoundation
import LarkWebViewContainer
import LarkRustHTTP
import LKCommonsLogging



protocol WADataSessionDelegate: AnyObject {
    
    var container: WAContainer? { get }
    
    var appConfig: WebAppConfig { get }
    
    func readData(for relativeFilePath: String) -> Data?
}

class WADataSession: NSObject {
    
    static let logger = Logger.log(WADataSession.self, category: WALogger.TAG)

    
    let key: String
    let request: URLRequest
    let filetype: [String]
    
    private static let removeLGWHeader = false
    private static let useRust = true
    
    private(set) var rustURLSession: RustHTTPSession?
    private(set) var urlSession: URLSession?
    private(set) weak var delegate: WADataSessionDelegate?
    
    private let requestQueue = DispatchQueue(label: "WebAppDataSession-\(UUID().uuidString)")
    
    init(request: URLRequest, sessionHanlder: WADataSessionHandler, delegate: WADataSessionDelegate?) {
        
        self.delegate = delegate
        self.filetype = delegate?.appConfig.resInterceptConfig?.filetype ?? []
        self.key = UUID().uuidString
        self.request = Self.modifyRequest(request)
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 10
        operationQueue.underlyingQueue = self.requestQueue
        super.init()
        if Self.useRust {
            rustURLSession = RustHTTPSession(configuration: RustHTTPSessionConfig.default,
                                             delegate: sessionHanlder,
                                             delegateQueue: operationQueue)
        } else {
            urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                    delegate: sessionHanlder,
                                    delegateQueue: operationQueue)
        }
    }
    
    func start(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        DispatchQueue.global().async { [weak self] in
            self?.innerStart(completionHandler: completionHandler)
        }
    }
    
    func finishTasksAndInvalidate() {
        self.urlSession?.finishTasksAndInvalidate()
        self.rustURLSession?.finishTasksAndInvalidate()
    }
    
    func invalidateAndCancel() {
        self.urlSession?.invalidateAndCancel()
        self.rustURLSession?.invalidateAndCancel()
    }
    
    private func innerStart(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let url = request.url else {
            completionHandler(nil, nil, WAError.offlineError(code: .invalidParam, msg: "url is invalid"))
            return
        }
        
        let isResRequest = Self.isResourceRequest(request)
        if isResRequest, let data = tryReadFromCache(url: url) {
            //资源请求先走本地缓存
            Self.logger.info("intercept, hit cache,\(url.lastPathComponent)", tag: LogTag.net.rawValue)
            //命中缓存，封装response
            var headers: [String: String] = [WAHttpDefine.Header.larkCacheFrom.rawValue: WAHttpDefine.Consts.local.rawValue,
                                             WAHttpDefine.Header.contentLength.rawValue: data.count.description,
                                             WAHttpDefine.Header.allowOrigin.rawValue: "*",
                                             WAHttpDefine.Header.allowMethods.rawValue: WAHttpDefine.Consts.allowMethods.rawValue,
                                             WAHttpDefine.Header.allowCredentials.rawValue: "true"]
            if let mimetype = Self.mimeTypeFor(request) {
                headers[WAHttpDefine.Header.contentType.rawValue] = mimetype
            } else {
                Self.logger.error("no minitype for:\(url.path)", tag: LogTag.net.rawValue)
            }
            
            let httpRsp = HTTPURLResponse(url: url,
                                          statusCode: DocsNetworkError.HTTPStatusCode.RequestSucceed.rawValue,
                                          httpVersion: WAHttpDefine.Consts.httpVersion.rawValue,
                                          headerFields: headers)
            completionHandler(data, httpRsp, nil)
            return
        }
        
        
        if isResRequest, self.delegate?.container?.isAttachOnPage != true {
            //预加载时，禁止资源请求
            Self.logger.error("Forbid downloading resources during preloading - mime:\(Self.mimeTypeFor(request)), \(url.urlForLog)")
            spaceAssertionFailure("must fix requestInPreload error")
            delegate?.container?.tracker.reportCommonError(errorType: .requestInPreload, msg: url.absoluteString)
            completionHandler(nil, nil, WAError.offlineError(code: .requestInPreload, msg: "Forbid downloading resources during preloading", url: url))
            return
        }
        
        //转为在线请求
        Self.logger.info("intercept, start get from remote, isRes:\(isResRequest), req:\(Self.getRequestInfo(request))")
        if Self.useRust {
            guard let rustURLSession = self.rustURLSession else {
                return
            }
            let task = rustURLSession.dataTask(with: request) { data, response, error in
                if let error {
                    Self.logger.error("request error,\(url.lastPathComponent)", tag: LogTag.net.rawValue, error: error)
                } else {
                    Self.logger.info("request finish,\(url.lastPathComponent)", tag: LogTag.net.rawValue)
                }
                completionHandler(data, response, error)
            }
            task.resume()
        } else {
            guard let urlSession = self.urlSession else {
                return
            }
            let task = urlSession.dataTask(with: request) { data, response, error in
                if let error {
                    Self.logger.error("request error,\(url.lastPathComponent)", tag: LogTag.net.rawValue, error: error)
                } else {
                    Self.logger.info("request finish,\(url.lastPathComponent)", tag: LogTag.net.rawValue)
                }
                completionHandler(data, response, error)
            }
            task.resume()
        }
    }
}


extension WADataSession {
    class func modifyRequest(_ req: URLRequest) -> URLRequest {
        var newReq = req
        
        if Self.removeLGWHeader, let headers = newReq.allHTTPHeaderFields {
            //带有这个头拦截会被rustsdk报错 https://bytedance.feishu.cn/wiki/KUGpwHSitit3TjkQ4HZc2RyLnze
            for (k, v) in headers {
                if k.hasPrefix("x-lgw") {
                    Self.logger.info("remove req.header for:\(k), \(v.prefix(5))****\(v.suffix(5))", tag: LogTag.net.rawValue)
                    newReq.setValue(nil, forHTTPHeaderField: k)
                }
            }
        }
        
        if newReq.allHTTPHeaderFields?.keys.compactMap({ return $0.lowercased() }).contains(WAHttpDefine.Header.xttLogId.rawValue) == false {
            //generate logid
            newReq.setValue(RequestConfig.generateTTLogid(), forHTTPHeaderField: WAHttpDefine.Header.xttLogId.rawValue)
        }
        if newReq.allHTTPHeaderFields?.keys.compactMap({ return $0.lowercased() }).contains(WAHttpDefine.Header.requestID.rawValue) == false {
            //generate requestID
            newReq.setValue(RequestConfig.generateRequestID(), forHTTPHeaderField: WAHttpDefine.Header.requestID.rawValue)
        }
        return newReq
    }
    
    class func getRequestInfo(_ req: URLRequest) -> String {
        guard let url = req.url else { return "empty url!" }
        var info = [String: String]()
        info["url"] = url.urlForLog
        info[ WAHttpDefine.Header.xttLogId.rawValue] = req.value(forHTTPHeaderField: WAHttpDefine.Header.xttLogId.rawValue) ?? ""
#if DEBUG
        info[WAHttpDefine.Header.cookie.rawValue] = req.value(forHTTPHeaderField: WAHttpDefine.Header.cookie.rawValue) ?? ""
#endif
        return info.toJSONString() ?? url.urlForLog
    }
    
    class func isResourceRequest(_ req: URLRequest) -> Bool {
        if let mimeType = mimeTypeFor(req), !mimeType.hasPrefix("*"), !mimeType.hasSuffix("json") {
            return true
        }
        return false
    }
}
