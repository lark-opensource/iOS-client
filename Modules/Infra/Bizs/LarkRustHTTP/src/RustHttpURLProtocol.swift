//
//  RustHttpURLProtocol.swift
//  LarkRustClient
//
//  Created by SolaWing on 2018/11/25.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import LKCommonsLogging
import RustPB
import HTTProtocol

/// http protocol, 替换优化底层实现。上层尽量和系统原生兼容。
open class RustHttpURLProtocol: BaseHTTProtocol, HTTProtocolHandler {
    override open var handler: HTTProtocolHandler { return self }
    // swiftlint:enable identifier_name
    override public init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        self.metrics = RustHttpMetrics(request: request)
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }

    @objc
    public convenience init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        // canInit那里都取了currentRequest, 这里为什么还可能是nil?
        guard let request = task.currentRequest else {
            logger.error("task currentRequest is nil. why? caninit should guard scheme! fallback to report error")
            let errorURL = URL(string: "about:error") ?? URL(fileURLWithPath: "about:error")
            self.init(request: URLRequest(url: errorURL), cachedResponse: cachedResponse, client: client)
            return
        }
        self.init(request: request, cachedResponse: cachedResponse, client: client)
        // session is a internal property. just a guard to ensure session selector is valid.
        if task.responds(to: NSSelectorFromString("session")) {
            task.add(metric: metrics)
            _task = task
        } else {
            assertionFailure("session can't get from task, need to fix code!!")
            logger.error("session can't get from task, need to fix code!!")
        }
    }
    // MARK: - 状态属性管理
    public let metrics: RustHttpMetrics
    var _task: URLSessionTask? // swiftlint:disable:this identifier_name

    open override var task: URLSessionTask? { return _task }
    /// NOTE: 和Task相关的调用应该收敛到这个类上来. 方便根据Task做不同的扩展
    var context: RustHttpURLProtocolContext { TaskContext(base: self) }
    private var rustTask: RustHttpManager.Task? {
        willSet {
            // cancel before release previous rust task
            if let v = rustTask, v !== newValue {
                v.cancel()
            }
        }
    }

    // use underscore prefix to indicate it's a private var, but internal for split into multiple file
    // swiftlint:disable identifier_name
    /// when set, is waiting for authentication, can should block all following normal response.
    var _authEnv: AuthenticateEnv?
    var _handleAuth = true
    // swiftlint:enable identifier_name
    private func finish() {
        rustTask = nil // safe since no read and only one set after creation
        _authEnv = nil
    }
    // MARK: - Loading API
    override open func startLoading() {
        metrics.fetchStartDate = Date()
        super.startLoading()
    }
    public func startLoading(request: BaseHTTProtocol) {
        if self.request.url?.absoluteString == "about:error" {
            self._response(errorDomain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable)
            return
        }

        switch self.context.cachePolicy {
        case .reloadIgnoringLocalCacheData, .reloadIgnoringLocalAndRemoteCacheData:
            requestServer(request: makeRustRequest())
        case let cachePolicy:
            getCachedResponse { [weak self] (cachedResponse) in
                guard let self = self else { return }
                var validateHeaders: [String: String] = [:]
                if let cachedResponse = cachedResponse {
                    let shouldUseCache = cachePolicy == .returnCacheDataDontLoad ||
                    cachePolicy == .returnCacheDataElseLoad ||
                    (self.isValid(cachedResponse: cachedResponse,
                                  validateHeaders: &validateHeaders) &&
                    cachePolicy != .reloadRevalidatingCacheData)
                    if shouldUseCache {
                        self.forward(cachedResponse: cachedResponse)
                        return
                    }
                }
                // no valid cache
                if cachePolicy == .returnCacheDataDontLoad {
                    debug( "\(dump(request: self.request)) returnDontLoad)" )
                    self._response(errorDomain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable)
                } else {
                    self.requestServer(request: self.makeRustRequest(additionalHeaders: validateHeaders),
                                       validateCachedResponse: cachedResponse)
                }
            }
        }
    }
    public func stopLoading(request: BaseHTTProtocol) {
        var params: [String: String] = [:]
        if let id = rustTask?.taskID { params["id"] = id.description }

        finish()

        #if !DEBUG
        if let start = metrics.fetchStartDate { params["start"] = dataFormatter.string(from: start) }
        if let end = metrics.fetchEndDate {
            params["end"] = dataFormatter.string(from: end)
            if let error = metrics.error {
                if let urlerror = error as? URLError {
                    params["type"] = "URLError(\(urlerror.errorCode))"
                } else {
                    params["type"] = "Unknown Error"
                }
            } else if let status = (metrics.response as? HTTPURLResponse)?.statusCode {
                params["type"] = "HTTP(\(status))"
            } else {
                params["type"] = "Unknown Load Type"
            }
        } else {
            params["end"] = dataFormatter.string(from: Date())
            if metrics.resourceFetchType == .localCache {
                params["type"] = "Cache"
            } else {
                params["type"] = "Cancel"
            }
        }

        logger.info(logId: "Rust HTTP Stat", "Rust HTTP Finish", params: params)
        #endif
    }

    // MARK: Request
    open func willStartRequestServer(request: FetchRequest?) {
        // 业务需求：覆盖来追踪taskid, 关联上rust的日志
    }

    private func requestServer(request: FetchRequest?, validateCachedResponse: CachedURLResponse? = nil) {
        guard let rustRequest = request else { return }
        do {
            metrics.resourceFetchType = .networkLoad
            let onReadBuf: RustHttpManager.OnReadIntoBuffer?
            // 测试发现对于设置的http body, 每次获取httpBodyStream都会生成一个新的stream，所以先获取一下保证唯一性
            // 而且URLProtocol获取到的request上只有stream...
            // TODO: 对于Session，如果提供的是流式的body或者使用的delegate, 可能需要调用相应的Delegate获取新的stream.
            if let bodyStream = self.context.bodyStream {
                context.setTaskExpectedToSend()
                let sentDelegate = context.hasSendProgressDelegate
                onReadBuf = { [weak self] (buffer, maxLength) -> Int in
                    guard let self = self else { return -1 }
                    return self.read(stream: bodyStream, into: buffer, maxLength: maxLength, hasProgress: sentDelegate)
                }
            } else {
                // Rust那边要求无body时不传onReadBuf, 传了onReadBuf但读取到-1的返回值算出错
                onReadBuf = nil
            }
            willStartRequestServer(request: request)
            self.rustTask = try RustHttpManager.fetchAsync(
                request: rustRequest,
                onReadBuf: onReadBuf,
                onEvent: { [weak self] response in
                    guard let response = response.response else {
                        return assertionFailure("empty http response!!")
                    }
                    // ~~现在这里不做线程安全保护，理论上Rust应该是串行的(需要保证Data接收顺序), 但回调线程一般不在开始线程上。~~
                    // 还是统一在startThread上串行吧，这点并发优化不了多少性能，反而容易出bug
                    self?.workQueue?.async { [weak self] in
                        guard let self = self, !self.isFinish else { return }
                        self.response(response, validateCachedResponse: validateCachedResponse)
                    }
                })
        } catch {
            self._response(errorDomain: NSURLErrorDomain, code: NSURLErrorUnknown, message: "internal unknown error!!")
        }
    }
    private func getCachedResponse(completionHandler: @escaping (CachedURLResponse?) -> Void) {
        if let cachedResponse = self.cachedResponse {
            // 客户端指定使用cache时才会进入，最终还是要protocol的实现使用相应的接口考虑cachePolicy
            completionHandler(cachedResponse)
        } else if let urlCache = self.context.urlCache {
            if let task = self.task as? URLSessionDataTask {
                urlCache.getCachedResponse(for: task) { [weak self] cachedResponse in
                    self?.workQueue?.run { completionHandler(cachedResponse) }
                }
            } else {
                completionHandler( urlCache.cachedResponse(for: self.request) )
            }
        } else {
            completionHandler(nil)
        }
    }
    private func makeRustRequest(additionalHeaders: [String: String]? = nil) -> FetchRequest? {
        // FIXME: User-Agent, and other default headers
        guard
            let url = self.request.url,
            var rustRequest = FetchRequest(request: self.request, with: context.cookieStorage)
        else {
            self._response(errorDomain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL)
            return nil
        }
        // 如果有授权头且没添加，添加进去
        let authHeader = AuthenticateCredentialStorage.shared.header(for: url)
        let appendHeaders = { (k: String, v: String) in
            if !rustRequest.headers.contains(where: { $0.name == k }) {
                rustRequest.headers.append(HttpHeader(name: k, value: v))
            }
        }
        authHeader.forEach(appendHeaders)
        if let additionalHeaders = additionalHeaders { additionalHeaders.forEach(appendHeaders) }

        rustRequest.isFollowRedirect = false
        if let priority = self.context.taskPriority { rustRequest.priority = priority }
        return rustRequest
    }
    // MARK: Callback
    /// gate for response, use this to give a chance to capture the ClientEvent
    func _response(event: ClientEvent) { // swiftlint:disable:this identifier_name
        if let authEnv = self._authEnv {
            authEnv.holdEvents.append(event)
        } else {
            self.response(event: event)
        }
    }
    /// forward auth hold responses and end authEnv.
    func _forwardHoldResponses() { // swiftlint:disable:this identifier_name
        guard let authEnv = self._authEnv else { return }
        for event in authEnv.holdEvents {
            self.response(event: event)
        }
        self._authEnv = nil
    }
    private func forward(cachedResponse: CachedURLResponse) {
        debug( "\(dump(request: self.request)) pass cachedResponse: \(reflect(cachedResponse))" )
        self.metrics.response = cachedResponse.response
        self.metrics.resourceFetchType = .localCache
        if let response = cachedResponse.response as? HTTPURLResponse {
            // if cache is a redirect cache, should call client
            self.dealRedirect(for: response, cachePolicy: .notAllowed)
        }
        self._response(event: .cached(cachedResponse))
    }
    private func read(stream: InputStream, into buffer: UnsafeMutablePointer<UInt8>, maxLength: Int, hasProgress: Bool)
    -> Int {
        if stream.streamStatus == .notOpen {
            debug("open \(dump(request: self.request)) steam \(stream)")
            stream.open()
        }
        let readed = stream.read(buffer, maxLength: maxLength)
        debug("\(dump(request: self.request)) readed: \(readed) from \(stream) into \(buffer). steam status \(stream.streamStatus.rawValue)") // swiftlint:disable:this line_length
        if readed == 0 && stream.streamStatus != .closed {
            stream.close()
        }
        context.didSend(count: readed, hasProgress: hasProgress)
        return readed
    }
    private func response(_ response: OnFetchResponse.OneOf_Response,
                          validateCachedResponse: CachedURLResponse?) {
        debug( "\(dump(request: self.request)) onevent: \(response)" )
        switch response {
        case .headerResponse(let v):
            self.response(header: v, cachedResponse: validateCachedResponse)
        case .bodyResponse(let v):
            self._response(event: .data(v.body))
        case .errorResponse(let v):
            if v.hasStageCost { self.metrics.fill(from: v.stageCost) }
            let userInfo = [
                "RustCode": v.code.rawValue,
                "larkErrorCode": v.larkErrorCode,
                "larkErrorStatus": v.larkErrorStatus
            ] as [String: Any]
            var code = NSURLErrorUnknown
            switch v.code {
            case .timeout: code = NSURLErrorTimedOut
            case .offline: code = NSURLErrorNotConnectedToInternet
            @unknown default: // sdk现在没有给code了，都是other，用larkErrorCode兜底
                switch v.larkErrorCode {
                case Int32(truncatingIfNeeded: Basic_V1_Auth_ErrorCode.timeout.rawValue):
                    code = NSURLErrorTimedOut
                case Int32(truncatingIfNeeded: Basic_V1_Auth_ErrorCode.offline.rawValue):
                    code = NSURLErrorNotConnectedToInternet
                default: break
                }
            }
            self._response(errorDomain: NSURLErrorDomain, code: code, message: v.message, userInfo: userInfo)
        case .successResponse(let v):
            if v.hasStageCost { self.metrics.fill(from: v.stageCost) }
            self.metrics.fetchEndDate = Date()
            self._response(event: .finish)
        case .cancelResponse:
            self._response(errorDomain: NSURLErrorDomain, code: NSURLErrorCancelled)
        @unknown default:
            // TODO: 处理其它response, 比如进度通知？
            break // ignore other unknown response
        }
    }
    private func response(header: OnFetchResponse.OnHeaderResponse, cachedResponse: CachedURLResponse?) {
        metrics.networkProtocol = header.protocol
        if header.statusCode == 304, let cachedResponse = cachedResponse {
            // 缓存有效，直接用缓存回应
            metrics.receiveHeaderDate = Date()
            let newCachedResponse = refresh(cachedResponse: cachedResponse, httpVersion: header.protocol.canonicalName)
            self.forward(cachedResponse: newCachedResponse)
            return // should finish after forward cached response
        }
        var headers = HttpHeader.convert(back: header.headers)
        // 如果没有Date属性，按当前值加上它。缓存会用到该时间判断过期
        // https://tools.ietf.org/html/rfc7231#section-7.1.1.2
        // 如果proxy有缓存并加上了age属性，计算date时减去他
        if headers["date"] == nil {
            headers["date"] = date(with: headers["age"]).toGMT()
        }
        guard
            let url = self.request.url,
            let response = HTTPURLResponse(url: url,
                                           statusCode: Int(header.statusCode),
                                           httpVersion: header.protocol.canonicalName,
                                           headerFields: headers)
        else {
            self._response(errorDomain: NSURLErrorDomain, code: NSURLErrorBadServerResponse,
                          message: "can't convert header response to HTTPURLResponse!")
            return
        }
        metrics.response = response
        metrics.receiveHeaderDate = Date()

        // HTTPURLResponse会把Header转换为标准的首字母大小的形式。
        // 如果是用OC的NSDictionary, 大小写查询是不敏感的。
        // 但转换成Swift的Dict后，查询是大小写敏感的...
        let cachePolicy = defaultCachePolicy(response: response)

        saveCookies(for: response)

        // 状态码处理: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
        dealRedirect(for: response, cachePolicy: cachePolicy)
        // if is authenticate, will block following _response
        //
        // NOTE: 苹果的demo里并没有用URLProtocol的auth api, 而是自己设置的class delegate代理..
        // 而现在URLProtocol多次请求时会泄露内存，（现在使用URLSession的直接调用绕过）
        _dealAuthentication(for: response)

        // dataTask会存进URLCache, 但useProtocolCachePolicy在请求时不会传cachedResponse, 所以还需要自己手动load
        // 另外downloadTask不会进URLCache
        self._response(event: .receive(response: response, policy: cachePolicy))
    }
    // swiftlint:disable:next identifier_name
    func _response(errorDomain: String, code: Int, message: String? = nil, userInfo: [String: Any] = [:]) {
        let error = RustHTTPError(domain: errorDomain, code: code, message: message, request: self.request, userInfo: userInfo)
        self.metrics.error = error
        self.metrics.fetchEndDate = Date()
        self._response(event: .error(error))
    }
    private func saveCookies(for response: HTTPURLResponse) {
        // 测试发现重定向也会存cookie
        if
            let storage = context.cookieStorage,
            let headers = response.allHeaderFields as? [String: String],
            let url = response.url,
            case let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url),
            !cookies.isEmpty
        {
            storage.setCookies(cookies, for: url, mainDocumentURL: request.mainDocumentURL)
        }
    }
    private func dealRedirect(for response: HTTPURLResponse, cachePolicy: URLCache.StoragePolicy) {
        // FIXME: 300怎么处理?
        guard
            response.statusCode > 300 && response.statusCode < 400 && response.statusCode != 304,
            let location = response.headerString(field: "Location"),
            let url = self.request.url?.redirect(to: location)
        else { return }

        var newRequest = self.request
        let isMainDoc = newRequest.url == newRequest.mainDocumentURL
        newRequest.url = url
        // 重定向主frame时，mainDocumentURL应该一起修改
        // FIXME: URLSession的重定向好像不会修改mainDocumentURL.. 是否需要保持一致？
        // 如果一致，需要处理cookie, webview等和mainDocumentURL相关的逻辑并测试
        if isMainDoc { newRequest.mainDocumentURL = url }
        // https://stackoverflow.com/questions/8138137/http-post-request-receives-a-302-should-the-redirect-request-be-a-get?rq=1
        // 302本来应该当成307处理的，但基本所有的浏览器都当成303处理了。
        // 规范同时说非GET HEAD情况应该提醒用户，但所有浏览器都没提醒..
        // 这里我们选择和实际情况一致
        if (response.statusCode == 303 || response.statusCode == 302) && newRequest.httpMethod != "HEAD" {
            newRequest.httpMethod = "GET"
            newRequest.httpBodyStream = nil
            newRequest.httpBody = nil
            newRequest.setValue(nil, forHTTPHeaderField: "Content-Length")
        }

        if cachePolicy != .notAllowed {
            // when called wasRedirectedTo, client(URLSession) won't save the redirect response.
            // so we save it
            self.store(cachedResponse: CachedURLResponse(response: response, data: Data(),
                                                         userInfo: nil, storagePolicy: cachePolicy))
        }
        self._response(event: .redirect(newRequest: newRequest, response: response))
    }
    /// refresh date and Expires etc header, for cache usage, and store the refreshed response into URLCache
    private func refresh(cachedResponse: CachedURLResponse, httpVersion: String) -> CachedURLResponse {
        guard
            let response = cachedResponse.response as? HTTPURLResponse,
            let url = response.url,
            var headers = response.allHeaderFields as? [String: String]
        else { return cachedResponse }

        let now = Date()
        // 如果有过期字段，按和Date差值来重新计算延长他
        if
            let expiresDate = Date(GMT: response.headerString(field: "Expires")),
            let date = Date(GMT: response.headerString(field: "Date")),
            case let timeInterval = expiresDate.timeIntervalSince(date), timeInterval > 0
        {
            headers["Expires"] = (now + timeInterval).toGMT()
        }
        // 更新收到消息的时间
        headers["Date"] = now.toGMT()
        guard let refreshedHttpResponse = HTTPURLResponse(url: url, statusCode: response.statusCode,
                                                          httpVersion: httpVersion, headerFields: headers)
        else { return cachedResponse }

        let cachedResponse = CachedURLResponse(response: refreshedHttpResponse, data: cachedResponse.data,
                                 userInfo: cachedResponse.userInfo, storagePolicy: cachedResponse.storagePolicy)
        // client will not save the valid cache response. so we save the refreshed CachedResponse
        store(cachedResponse: cachedResponse)
        return cachedResponse
    }
    private func store(cachedResponse: CachedURLResponse) {
        if let urlCache = self.context.urlCache {
            if let task = self.task as? URLSessionDataTask {
                urlCache.storeCachedResponse(cachedResponse, for: task)
            } else {
                urlCache.storeCachedResponse(cachedResponse, for: request)
            }
        }
    }
}

/// 只有NSError可以转化为URLError... 所以只是typealias，尽量保证系统error的兼容性
typealias RustHTTPError = NSError
extension RustHTTPError {
    convenience init(
        domain: String = NSURLErrorDomain, code: Int, message: String? = nil,
        request: URLRequest?, underlyingError: Error? = nil,
        userInfo: [String: Any] = [:]
    ) {
        var userInfo: [String: Any] = userInfo
        if let request, let url = request.url {
            userInfo["request"] = request
            userInfo[NSURLErrorFailingURLErrorKey] = url
            userInfo[NSURLErrorFailingURLStringErrorKey] = url.absoluteString
        }
        if let message = message {
            userInfo[NSLocalizedDescriptionKey] = message
        }
        if let underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlyingError
        }
        self.init(domain: domain, code: code, userInfo: userInfo)
    }
}

protocol RustHttpURLProtocolContext {
    var cookieStorage: HTTPCookieStorage? { get }
    var urlCache: URLCache? { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var bodyStream: InputStream? { get }
    var credentialStorage: URLCredentialStorage? { get }
    var taskPriority: FetchRequest.Priority? { get }
    func setTaskExpectedToSend()
    var hasSendProgressDelegate: Bool { get }
    func didSend(count: Int, hasProgress: Bool)

    func nextConnection(request: URLRequest, client: URLProtocolClient) -> RustHttpURLProtocol
    func auth(challenge: URLAuthenticationChallenge)
    /// 先临时这样保证有通知
    func authProgress()
}

/// 把Task和Session相关的调用都隔离开来
struct TaskContext: URLProtocolContext, RustHttpURLProtocolContext {
    var base: RustHttpURLProtocol
    var request: URLRequest { base.request }
    var task: URLSessionTask? { base.task }

    var taskPriority: FetchRequest.Priority? {
        guard let task = self.task else { return nil }
        switch task.priority {
        case let priority where priority < 1 / 3:      return FetchRequest.Priority.low
        case let priority where priority > 2 / 3:      return FetchRequest.Priority.high
        default: return nil
        }
    }
    var hasSendProgressDelegate: Bool {
        self.session?.delegate?.responds(to: #selector(URLSessionTaskDelegate.urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:))) == true // swiftlint:disable:this all
    }
    func didSend(count: Int, hasProgress: Bool) {
        if count > 0, let task = self.task { // swiftlint:disable:this all
            var sent = task.countOfBytesSent
            sent += Int64(count)
            task.setValue(sent, forKey: "countOfBytesSent")
            if hasProgress, let session = self.session, let delegate = session.delegate as? URLSessionTaskDelegate {
                session.delegateQueue.addOperation {
                    delegate.urlSession?(
                        session, task: task, didSendBodyData: Int64(count),
                        totalBytesSent: sent, totalBytesExpectedToSend: task.countOfBytesExpectedToSend)
                }
            }
        }
    }
    func setTaskExpectedToSend() {
        if let task = self.task, task.countOfBytesExpectedToSend < 1,
            let clength = self.request.value(forHTTPHeaderField: "Content-Length"),
            let length = Int64(clength), length > 0 {
                task.setValue(length, forKey: "countOfBytesExpectedToSend")
        }
    }
}
