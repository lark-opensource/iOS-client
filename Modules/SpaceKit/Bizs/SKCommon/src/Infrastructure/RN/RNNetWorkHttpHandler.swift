//
//  RNNetWorkHttpHandler.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2019/10/31.
//

import LarkRustHTTP
import SKFoundation
import SKInfra
import LarkContainer

@objc(RNNetWorkHttpHandler)
final class RNNetWorkHttpHandler: RCTHTTPRequestHandler {
    
    private var netWorkSession: RNNetWorkSession?

    private let lock = NSLock()

    override func handlerPriority() -> Float {
        return 9999.9
    }

    override class func requiresMainQueueSetup() -> Bool {
        return false
    }

    override func canHandle(_ request: URLRequest?) -> Bool {
        guard let scheme = request?.url?.scheme?.lowercased() else { return false }
        return scheme == "https" || scheme == "http"
    }

    override func cancelRequest(_ requestToken: Any?) {
        self.netWorkSession?.cancelRequest(requestToken)

    }

    override func invalidate() {
        self.netWorkSession?.invalidate()
    }

    private var requestId: String {
        let reqId = String.randomStr(len: 12) + "-" + (NetConfig.shared.userID ?? "")
        return reqId
    }

    override func send(_ request: URLRequest?, with delegate: RCTURLRequestDelegate?) -> Any? {
        guard var request = request, let delegate = delegate else {
            return nil
        }
        lock.lock()
        defer {
            lock.unlock()
        }

        if netWorkSession == nil {
            let operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.underlyingQueue = bridge.networking.methodQueue
            
            if UserScopeNoChangeFG.HZK.enableNetworkDirectConnectRust {
                netWorkSession = RNNetWorkRustSession(delegateQueue: operationQueue, lock: lock)
            } else {
                netWorkSession = RNNetWorkURLSession(delegateQueue: operationQueue, lock: lock)
            }
        }
        
        if request.allHTTPHeaderFields?[DocsCustomHeader.csrfToken.rawValue] == nil, let url = request.url {
            let csrfCookie = HTTPCookieStorage.shared.cookies(for: url)
            if let csrfCookie = csrfCookie?.first(where: { (cookie) -> Bool in
                guard let ame = cookie.properties?[HTTPCookiePropertyKey.name] as? String else { return false }
                return ame == DocsCookiesName.csrfToken.rawValue
            }) {
                let value = csrfCookie.value
                request.addValue(value, forHTTPHeaderField: DocsCustomHeader.csrfToken.rawValue)
            }
        }

        let reqIdCreated = self.requestId
        if request.allHTTPHeaderFields?[DocsCustomHeader.requestID.rawValue] == nil {
            request.setValue(reqIdCreated, forHTTPHeaderField: DocsCustomHeader.requestID.rawValue)
            request.setValue(reqIdCreated, forHTTPHeaderField: DocsCustomHeader.xttTraceID.rawValue)
        }
        
        if request.allHTTPHeaderFields?.keys.compactMap({ return $0.lowercased() }).contains(DocsCustomHeader.xttLogId.rawValue) == false {
            //本地生成logid
            request.setValue(RequestConfig.generateTTLogid(), forHTTPHeaderField: DocsCustomHeader.xttLogId.rawValue)
        }

        //发现有些请求没带UA,如果没有带这里补下UA
        if request.allHTTPHeaderFields?["User-Agent"] == nil, request.allHTTPHeaderFields?["user-agent"] == nil {
            request.setValue(UserAgent.defaultNativeApiUA, forHTTPHeaderField: "User-Agent")
        }

        if  OpenAPI.DocsDebugEnv.current == .preRelease {
            request.setValue("Pre_release", forHTTPHeaderField: DocsCustomHeader.env.rawValue)
        }

        if let url = request.url, let reqId = request.allHTTPHeaderFields?[DocsCustomHeader.requestID.rawValue] {
            let urlForLog = url.absoluteString.encryptToShort
            let logId = request.allHTTPHeaderFields?[DocsCustomHeader.xttLogId.rawValue] ?? ""
            DocsLogger.info("sknetinfo: docs_request_id=\(reqId), \(DocsCustomHeader.xttLogId.rawValue)=\(logId), url=\(urlForLog), fromRnNet", component: LogComponents.net)
        }

        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        request = DocsCustomHeader.addCookieHeaderIfNeed(request, userResolver: userResolver)
        let dataTask = netWorkSession?.dataTaskAndResume(with: request, delegate: delegate)
        return dataTask
    }
}
