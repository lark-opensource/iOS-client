//
//  WKHTTPTask.swift
//  LarkRustClient
//
//  Created by SolaWing on 2019/1/9.
//  Copyright © 2019年 Bytedance. All rights reserved.
//

#if ENABLE_WKWebView
import Foundation
import WebKit

@available(iOS 11.0, *)
public protocol WKHTTPTask: AnyObject {
    var task: WKURLSchemeTask { get }
    var webView: WKWebView? { get }
}

@available(iOS 11.0, *)
public protocol WKHTTPTaskDelegate: AnyObject {
    /// use WKBaseHTTPHandler's default implementation. not need to override
    func taskDidFinish(_ task: WKHTTPTask)
    /// return the protocol WKHTTPTask use to load resource.
    func taskURLProtocol(_ task: WKHTTPTask) -> URLProtocol.Type
    /// return the request to load, or nil to reject request
    func taskWillLoad(_ task: WKHTTPTask, request: URLRequest) -> URLRequest?
}

@available(iOS 11.0, *)
extension WKBaseHTTPHandler {
    /// Task Wraper for interact with WKURLSchemeTask and URLProtocol
    final class Task: WKHTTPTask {
        public var task: WKURLSchemeTask
        var currentRequest: URLProtocol? {
            didSet {
                if let old = oldValue {
                    old.stopLoading()
                    self.hold = nil
                    self.memoryBuffer = nil
                }
            }
        }
        weak var webView: WKWebView?
        private weak var delegate: WKHTTPTaskDelegate?

        var isLoadingMainFrame: Bool
        enum State: Int {
            // NOTE: 会进行大小比较
            case waiting = 0       /// 初始状态
            case connecting = 1    /// 向rust发起请求，进行连接
            case receiveHeader = 2 /// 收到header响应，等待数据
            case receiveData = 3   /// 收到Data响应，等待更多数据或者结束
            case finish = 4        /// 已经结束
        }
        // 用来记录当前状态，WKWebView有bug，结束前必须回调body，否则会崩溃
        private var state = State.waiting
        // 用来暂存响应，完结后可缓存
        private var hold: Buffer?
        // FIXME: WKWebView的增量更新好像有问题.
        // https://forms.gle/57qTuTtq6xPKyr7a8
        // 上面这个页面，正常是会页内跳转页面。这里会导致WKProcess结束且无后续回调，但如果一次性收到数据则不会。
        // NOTE: 现在使用buffer一次性回调来解决问题. 但可能出现内存过多容量不足的问题。暂时不管这种极端case
        // 另外就是一次性回调导致WKWebView的部分加载功能废掉了。
        private var memoryBuffer: MemoryBuffer?

        deinit {
            assert(currentRequest == nil, "currentRequest should release in stopLoading")
            self.currentRequest = nil
        }
        init(task: WKURLSchemeTask, webView: WKWebView, delegate: WKHTTPTaskDelegate?) {
            self.task = task
            self.webView = webView
            self.delegate = delegate
            // 重定向后url会发生改变，可能不一致，先保存下来，用来确认是mainFrame的加载
            self.isLoadingMainFrame = task.request.url == task.request.mainDocumentURL
        }
        func startLoading() {
            assert(Thread.isMainThread) // WK的回调都是在主线程，这个类也是单线程使用的

            load(request: task.request)
        }
        func stopLoading() {
            self.currentRequest = nil
        }
        func load(request: URLRequest) {
            // 重定向等可能给出异常request
            guard
                let loadClass = delegate?.taskURLProtocol(self),
                var request = delegate?.taskWillLoad(self, request: request),
                loadClass.canInit(with: request)
            else {
                let url = task.request.url
                self.complete(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: [
                    NSLocalizedDescriptionKey: "unsupported URL",
                    NSURLErrorFailingURLErrorKey: url as Any,
                    NSURLErrorFailingURLStringErrorKey: url?.absoluteString as Any
                ]))
                return
            }
            request = loadClass.canonicalRequest(for: request)
            let urlprotocol = loadClass.init(request: request, cachedResponse: nil, client: wrapWeakURLClient())

            currentRequest = urlprotocol

            state = .connecting
            urlprotocol.startLoading()
        }
        // MARK: URLClient Events
        private func wrapWeakURLClient() -> URLProtocolClient {
            // FIXME: 百度加载崩溃页原因和Workaround
            // https://haokan.baidu.com/videoui/page/searchresult?pd=wise&vid=9530322541147264278&is_invoke=1&innerIframe=1#viewportType=virtual&paddingTop=54&pageType=&pageInfo=
            // 已知最后崩溃前最后一个请求`als.baidu.com/clog/glog`如果屏蔽或者发送空body，就不会崩溃，单独看这个请求也没什么特殊的。

            return URLProtocolForwardClient { [weak self](client, event) in
                // 如果已经结束或者重定向后，不再接收后续消息
                guard let self = self, self.currentRequest?.client === client else { return }
                switch event.data {
                case let .receive(response, policy):          self.receive(response: response, cachePolicy: policy)
                case .data(let v):                            self.receive(data: v)
                case .finish:                                 self.complete(error: nil)
                case .error(let v):                           self.complete(error: v)
                case let .redirect(newRequest, response):     self.redirect(response: response, newRequest: newRequest)
                case .cached(let v):
                    self.task.didReceive(v.response)
                    self.task.didReceive(v.data)
                    self.state = .receiveData // avoid complete send data
                    self.complete(error: nil)
                case .challenge(let challenge):
                    self.challenge(challenge)
                case .cancel: // cancel Challenge, RustHttp不会主动调用，暂时忽略
                    assertionFailure("not implement")
                }
            }
        }
        private func redirect(response: URLResponse, newRequest: URLRequest) {
            assert(state == .connecting)
            // typealias Sign = @convention(c) (AnyObject, Selector, URLResponse, URLRequest) -> Void
            // var redirectSelector: Selector {
            //     // 使用私有API，有被拒风险，把名字简单拆分一下 `_didPerformRedirection:newRequest:`
            //     return NSSelectorFromString(["_", "didPerf", "ormRe", "direction:", "newRequest:"].joined())
            // }
            // let sel = redirectSelector
            // guard task.responds(to: sel) else {
            //     assertionFailure("unimplemented api")
            //     logger.error("WKWebView redirect api unimplemented")
            //     return
            // }
            // let imp = unsafeBitCast((task as AnyObject).method(for: sel), to: Sign.self)

            // // WKURLSchemeHandler的私有redirect API仅仅是通知，
            // // 以便让webView的相应回调以及document.location等做出相应的修改
            // // 但WKWebView不会自己发起新请求，需要直接返回新数据
            // // 调用后task.request会产生改变
            // imp(task, sel, response, newRequest)
            self.load(request: newRequest)
        }
        private func challenge(_ challenge: URLAuthenticationChallenge) {
            guard let sender = challenge.sender else { return }
            func defaultHandle(proposedCredential: URLCredential?) {
                if let handle = sender.performDefaultHandling(for:) {
                    handle(challenge)
                } else {
                    useCredential(proposedCredential)
                }
            }
            func useCredential(_ credential: URLCredential?) {
                if let credential = credential {
                    sender.use(credential, for: challenge)
                } else {
                    sender.continueWithoutCredential(for: challenge)
                }
            }

            // swiftlint:disable:next line_length
            if let webView = self.webView, let delegate = webView.navigationDelegate?.webView(_:didReceive:completionHandler:) {
                delegate(webView, challenge, { choose, credential in
                    assert(Thread.isMainThread) // 需要保证在同一线程回调。WK都是在主线程。不过RustHTTP本身也做了线程保护
                    switch choose {
                    case .cancelAuthenticationChallenge: sender.cancel(challenge)
                    case .performDefaultHandling: defaultHandle(proposedCredential: credential)
                    case .useCredential: useCredential(credential)
                    case .rejectProtectionSpace:
                        if let handle = sender.rejectProtectionSpaceAndContinue(with:) {
                            handle(challenge)
                        } else {
                            sender.continueWithoutCredential(for: challenge)
                        }
                    @unknown default:
                        assertionFailure()
                    }
                })
            } else {
                defaultHandle(proposedCredential: challenge.proposedCredential)
            }
        }
        private func receive(response: URLResponse, cachePolicy: URLCache.StoragePolicy) {
            // 拦截后，WKWebView好像只有有限的页面内存缓存，且跳转后就可能失效了。所以最终还是要共用系统的缓存
            // FIXME: 如果是nonPersistent store, 是否应该复用系统默认的缓存? 还是新开一个私有的?
            self.state = .receiveHeader

            if let request = currentRequest?.request, request.httpMethod != "HEAD" { // head请求不会接收body，而且不完整所以不缓存。
                let policy = self.storeCachePolicy(for: cachePolicy)
                if policy != .notAllowed {
                    self.hold = try? Buffer(response: response, policy: policy)
                }

                if self.isLoadingMainFrame {
                    self.memoryBuffer = MemoryBuffer { [unowned(unsafe) self] data in
                        self.flush(data: data)
                    }
                }
            }
            // cookies should save into WK cookie storage before response, else js may can't get cookie..
            self.saveCookies(response: response)
            self.task.didReceive(response)
        }
        private func receive(data: Data) {
            self.state = .receiveData
            if let buffer = self.memoryBuffer {
                buffer.append(data: data)
            } else {
                self.flush(data: data)
            }
        }
        private func flush(data: Data) {
            do {
                try self.hold?.data.append(data: data)
            } catch {
                debug("catch error: \(error)")
                self.hold = nil
            }
            self.task.didReceive(data)
        }
        private func complete(error: Error?) {
            // FIXME: 没有超时设置... 会不会有不结束一直卡着的可能? 这样会泄漏内存. 需要测试一下。甚至包括直接释放webView
            var error = error
            guardDataReceive(error: &error)
            if let error = error {
                task.didFailWithError(error)
            } else {
                self.memoryBuffer?.flush()
                self.saveCache()
                task.didFinish()
            }
            self.state = .finish
            self.delegate?.taskDidFinish(self)
            self.stopLoading()
        }

        // 如果不调用body就finish，会导致崩溃.
        // 查了下webkit历史，果然18年8月才修复，从目前xcode看iOS12.1 模拟器 还没有合进主版本...
        // https://github.com/WebKit/webkit/commit/08f4b2ef1b29daf50d0156679fdfea1512188f84
        //
        // 所以检查下当前状态，没发data的补上data
        private func guardDataReceive(error: inout Error?) {
            if self.state.rawValue < State.receiveData.rawValue {
                debug("guard data receive: \(self.state) \(self.state.rawValue)")
                if state.rawValue < State.receiveHeader.rawValue {
                    assert(error != nil, "should receive response before finish")
                    error = error ?? NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
                    guard
                        let url = self.task.request.url,
                        let response = HTTPURLResponse(url: url, statusCode: 404,
                                                       httpVersion: "HTTP/1.1", headerFields: nil)
                        else {
                            assertionFailure("THIS SHOULDN'T FAIL")
                            return
                    }
                    task.didReceive(response)
                }
                task.didReceive(Data())
            }
        }
        private func saveCookies(response: URLResponse) {
            // HTTPCookie创建时，如果无domain，则默认当前domain，否则加上.前缀
            // 给定 host: www.example.com
            // accept:
            //  .example.com
            //  .www.example.com
            //  www.example.com
            // reject:
            //  example.com                                  // 无.前缀的需要精确匹配
            //  .com, .org, s3-ap-northeast-1.amazonaws.com  // 这个是public suffix, 有一个很长的列表: https://github.com/publicsuffix/list/blob/master/public_suffix_list.dat
            //
            // 参考这篇总结: http://bayou.io/draft/cookie.domain.html

            // 现在都共用系统HTTPCookieStorage的实现, 保证系统的cookie同步到WK(包括历史和3xx保存的).
            // FIXME: 如果需要优化性能时, 再考虑如何增量更新

            // NOTE 改为了使用WKCookieSyncer的同步监听实现. 做了排重，这里也同步一下保证及时性(在回调前把cookie设置上去感觉会好一些)
            guard
                currentRequest?.request.httpShouldHandleCookies == true,
                let webView = webView,
                let url = response.url // 如果重定向，URL可能和原来的不一样
            else { return }

            let hasSetCookie = { () -> Bool in
                if let setCookie = (response as? HTTPURLResponse)?.headerString(field: "Set-Cookie") {
                    return !setCookie.isEmpty
                }
                return false
            }

            if self.isLoadingMainFrame || hasSetCookie() {
                // 这里的URL和webView现在的有可能不一样..
                WKCookieSyncer.sync(to: webView, url: url)
            }
        }
        private func saveCache() {
            guard let response = self.hold?.finish(), let request = self.currentRequest?.request else {
                return
            }
            self.hold = nil
            URLCache.shared.storeCachedResponse(response, for: request)
        }

        // MARK: Helper
        /// 用于缓存并一次性返回结果，有内存大小限制。
        /// 主要用来避免主frame部分加载无响应的问题。
        private final class MemoryBuffer {
            private var data = Data(capacity: MemoryBuffer.defaultCapacity)
            /// called when buffer overflow, or call flush command
            /// after flush, buffer is empty
            private let flushAction: (Data) -> Void
            static let defaultCapacity = 64 << 10
            static let maxCapacity = 16 << 20
            init(flush: @escaping (Data) -> Void) {
                self.flushAction = flush
            }

            func append(data: Data) {
                let left = MemoryBuffer.maxCapacity - self.data.count
                if data.count > left {
                    self.flush()
                    // 太大的内容直接flush
                    if data.count > MemoryBuffer.maxCapacity {
                        self.flushAction(data)
                        return
                    }
                }
                self.data.append(data)
            }

            func flush() {
                guard !self.data.isEmpty else { return }
                self.flushAction(self.data)
                self.data.removeAll(keepingCapacity: true)
            }
        }
        private struct Buffer {
            let data: HTTProtocolBuffer
            let response: URLResponse
            let policy: URLCache.StoragePolicy
            init(response: URLResponse, policy: URLCache.StoragePolicy) throws {
                self.data = try HTTProtocolBuffer(response: response, policy: policy)
                self.response = response
                self.policy = policy
            }
            func finish() -> CachedURLResponse {
                CachedURLResponse(response: response, data: data.asData(), storagePolicy: policy)
            }
        }

        // 取WKWebView和指定Policy中更小的
        private func storeCachePolicy(for cachePolicy: URLCache.StoragePolicy) -> URLCache.StoragePolicy {
            if cachePolicy == .allowed {
                return webView?.configuration.websiteDataStore.isPersistent == true ? .allowed : .allowedInMemoryOnly
            }
            return cachePolicy
        }
    }
}
#endif
