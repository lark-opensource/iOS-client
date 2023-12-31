//
//  URLProtocolTests.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2018/11/26.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import Swifter
import EEAtomic

import XCTest
@testable import LarkRustClient
@testable import LarkRustHTTP
@testable import HTTProtocol
import RxSwift

class URLProtocolTests: BaseTestCase {
    open override class func setUp() {
        super.setUp()
        // ensure init rust sdk
        _ = HttpServer.testServer
        _ = rustClient
        // 测试proxy需要访问外网来测试，目前我是搭了一个自己的php服务器，实现相同的服务器功能来跑测试。
        // RustHttpManager.globalProxyURL = URL(string: "http://10.92.188.224:8080")
    }
    open override class func tearDown() {
        super.tearDown()
    }

    // MARK: overridable config
    class var useRustNetwork: Bool { registerProtocolClass === RustHttpURLProtocol.self }
    class var registerProtocolClass: URLProtocol.Type? {
        return RustHttpURLProtocol.self
    }
    class var sharedSession: BaseSession { URLSession.shared }
    // swiftlint:disable:next all
    func makeSession(config: ((BaseSessionConfiguration) -> Void)? = nil, delegate: ((BaseSessionDelegate) -> Void)? = nil, delegateQueue: OperationQueue? = nil) -> BaseSession {
        let configuration = makeURLSessionConfiguration()
        if let config { config(configuration) }
        let delegate = delegate.flatMap {
            let v = URLSessionTestDelegate()
            $0(v)
            return v
        }

        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }
    var enableComplexConnect: Bool { false }

    // MARK: State
    var tasks = AtomicInt(0) // async running task counter
    var isProtocolRegisterd = false
    private static var ident = 0
    func nextID() -> Int {
        URLProtocolTests.ident += 1
        return URLProtocolTests.ident
    }
    var serverURL: URL { return HttpServer.testServerURL }
    var server: HttpServer { return HttpServer.testServer }
    /// TTNet and rust will use chunk.., swifter not support it. add a mock server to test this case

    override func setUp() {
        super.setUp()
        // 开始将清掉缓存避免干扰而不进行正常请求
        URLCache.shared.removeAllCachedResponses()

        if let urlprotocol = Self.registerProtocolClass {
            URLProtocol.registerClass(urlprotocol)
            isProtocolRegisterd = true
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        if isProtocolRegisterd, let urlprotocol = Self.registerProtocolClass {
            URLProtocol.unregisterClass(urlprotocol)
            isProtocolRegisterd = false
        }

        super.tearDown()
    }

    // MARK: Helper Method
    func waitTasks() { runUntil(condition: tasks.load() == 0) }
    struct RequestTask {
        typealias URLResponseHandler = (Data?, URLResponse?, Error?) -> Void
        var urlrequest: URLRequest
        var completeHandler: URLResponseHandler?
        var run: ((RequestTask) -> BaseSessionTask?)?
        @discardableResult
        func resume() -> BaseSessionTask? {
            return run?(self)
        }
    }

    private func httpMethodShouldHaveBody(_ method: String) -> Bool {
        // set body with GET request, cause system HTTP timeout. don't know why..
        switch method.uppercased() {
        case "GET", "HEAD": return false
        default: return true
        }
    }

    func httpRequest(
        path: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil,
        bodyStream: InputStream? = nil,
        timeout: TimeInterval = 20, // default use small timeout because it's in localhost and should fast
        in session: BaseSession? = nil,
        completeHandler: ((Data?, HTTPURLResponse?, Error?) -> Void)? = nil
    ) -> RequestTask {
        let session = session ?? Self.sharedSession
        let url = HttpServer.makeURL(relativeString: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.timeoutInterval = timeout
        request.enableComplexConnect = self.enableComplexConnect
        if httpMethodShouldHaveBody(method) {
            if body != nil { request.httpBody = body }
            if bodyStream != nil { request.httpBodyStream = bodyStream }
        }
        let taskHandler: RequestTask.URLResponseHandler? =
            completeHandler != nil ? { completeHandler!($0, $1 as? HTTPURLResponse, $2) } : nil
        let task = RequestTask(urlrequest: request, completeHandler: taskHandler, run: {[weak self] in
                                   return self?.resume(task: $0, in: session)
                                   })
        return task
    }

    func resume(task: RequestTask, in session: BaseSession) -> BaseSessionDataTask {
        return self.resume(request: task.urlrequest, in: session, completeHandler: task.completeHandler)
    }

    @discardableResult
    func resume(request: URLRequest, in session: BaseSession = sharedSession,
                completeHandler: RequestTask.URLResponseHandler? ) -> BaseSessionDataTask {
        tasks.add(1)
        let task = session.dataTask(with: request) { (data, response, error) in
            completeHandler?(data, response as? HTTPURLResponse, error)
            self.tasks.sub(1)
        }
        task.resume()
        return task
    }

    func makeURLSessionConfiguration(identifier: String? = nil) -> URLSessionConfiguration {
        let configuration: URLSessionConfiguration
        switch identifier {
        case "default", nil:
            configuration = URLSessionConfiguration.default
        case "ephemeral":
            configuration = URLSessionConfiguration.ephemeral
        default:
            configuration = URLSessionConfiguration.background(withIdentifier: identifier!)
        }
        if isProtocolRegisterd, let urlprotocol = Self.registerProtocolClass {
            configuration.protocolClasses = [urlprotocol]

        }
        return configuration
    }

    // MARK: - HTTP REQUEST
    func testGetRequest() {
        let responseText = "hello tester!"
        server["/hello"] = { _ in HttpResponse.ok(.text(responseText)) }

        httpRequest(path: "/hello") { (data, response, error) in
            XCTAssertNil(error)
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertEqual(data, responseText.data(using: .utf8))
        }.resume()
        waitTasks()
    }
    func testOptionsRequest() {
        let responseText = "hello tester!"
        server["/options"] = { _ in
            // swiftlint:disable:next all
            HttpResponse.raw(204, "No Content", ["Allow": "OPTIONS, GET, HEAD, POST"], { (writer: HttpResponseBodyWriter) in
                                 try? writer.write(responseText.data(using: .utf8)!)
                             })
        }

        httpRequest(path: "/options", method: "OPTIONS") { (_, response, error) in
            XCTAssertNil(error)
            XCTAssertEqual(response?.statusCode, 204)
            // options shoudn't return body?
            //            XCTAssertEqual(data, responseText.data(using: .utf8))
            // URLResponse不是所有key都会转化为标准首字母大写的形式
            XCTAssertEqual(response?.headerString(field: "allow"), "OPTIONS, GET, HEAD, POST")
        }.resume()
        waitTasks()
    }
    func testPostRequest() {
        func post(message: String, identifier: String) {
            let body = message.data(using: .utf8)!
            httpRequest(path: "/post#\(identifier)", method: "POST", body: body) { (data, response, error) in
                XCTAssertNil(error, identifier)
                XCTAssertEqual(response?.statusCode, 200, identifier)
                if message.count < (1 << 10) {
                    XCTAssertEqual(data, message.data(using: .utf8), identifier)
                } else {
                    XCTAssertEqual(data, body, identifier)
                }
            }.resume()
        }
        post(message: "hello post", identifier: "hello")
        // "large post body should be ok"
        post(message: (0..<(1 << 16 - 11)).reduce(into: "", { result, _ in result.append("x") }), identifier: "large" )

        waitTasks()
    }
    func testBodyStreamWithoutContentLengthShouldnotCrash() {
        // swifter not read body when no content length
        let body = (0..<(1 << 16)).reduce(into: "", { result, _ in result.append("x") })
        var req = URLRequest(url: HttpServer.makeURL(relativeString: "/post"))
        req.enableComplexConnect = self.enableComplexConnect
        req.httpMethod = "POST"
        req.httpBodyStream = InputStream(data: body.data(using: .utf8)!)
        resume(request: req) { (_, _, _) -> Void in }
        waitTasks()
    }
    func testUploadTask() {
        // 复合连接没有进度通知..，会失败
        // if self is ComplexConnectionTests { return }
        let body = Data(repeating: 88, count: 1 << 15)
        // 本地的断网没用, 仍然可以请求，用外网来测试断网的影响
        // var req = URLRequest(url: URL(string: "http://10.92.188.224/~wang/RustHttp/slowResponse")!)
        var req = URLRequest(url: HttpServer.makeURL(relativeString: "/slowresponse"))
        req.httpMethod = "POST"
        // test: 同时测试一下能够即时收到body，不会失败
        req.timeoutInterval = 2 // 这个是连接无响应的时间, 不是总时间
        req.allHTTPHeaderFields = ["duration": "4"]
        req.enableComplexConnect = self.enableComplexConnect
        tasks.add(1)
        let task = Self.sharedSession.uploadTask(with: req, from: body) { (_, _, error) in
            XCTAssertNil(error)
            self.tasks.sub(1)
        }
        task.resume()
        waitTasks()
    }
    func testUploadFile() {
        let length = 1 << 15
        let body = Data(repeating: 88, count: length)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("upload.data")
        try! body.write(to: url) // swiftlint:disable:this all

        var req = URLRequest(url: HttpServer.makeURL(relativeString: "/slowresponse"))
        req.httpMethod = "POST"
        req.timeoutInterval = 2 // 这个是连接无响应的时间, 不是总时间
        req.allHTTPHeaderFields = ["duration": "1"]
        req.enableComplexConnect = self.enableComplexConnect

        var didSend: Int64 = 0
        let session = makeSession(delegate: { delegate in
            delegate.sendNotify = { (send) in
                XCTAssertEqual(send.totalBytesExpectedToSend, Int64(length))
                didSend += send.bytesSent
                XCTAssertEqual(send.totalBytesSent, didSend)
            }
        })

        tasks.add(1)
        let task = session.uploadTask(with: req, fromFile: url) { (_, _, error) in
            XCTAssertNil(error)
            self.tasks.sub(1)
        }
        task.resume()
        waitTasks()
        XCTAssertEqual(didSend, Int64(length))
    }
    func testDownloadTask() {
        // let url = URL(string: "https://forms.gle/57qTuTtq6xPKyr7a8")!
        let url = HttpServer.makeURL(relativeString: "/web/page/googleDocsBugs.html")
        var req = URLRequest(url: url)
        // swiftlint:disable line_length
        req.allHTTPHeaderFields = [
            "referer": "http://127.0.0.1/~wang/testLark.php",
            "accept": "text/html, application/xhtml+xml, application/xml;q=0.9, */*;q=0.8",
            "user-agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Test WKWebView",
            "accept-language": "en-US",
            "accept-encoding": "gzip"
        ]
        req.enableComplexConnect = self.enableComplexConnect
        // swiftlint:enable line_length

        tasks.add(1)
        let task = Self.sharedSession.downloadTask(with: req) { (url, response, error) in
            XCTAssertNotNil(url)
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            self.tasks.sub(1)
        }
        task.resume()
        waitTasks()
    }
    func testHeaderRequest() {
        httpRequest(
            path: "/head", method: "HEAD", headers: ["Custom": "hello", "en-usq10en-cnq09zh-hans-cnq08": "User-Agent"],
            completeHandler: { (data, response, error) in
                XCTAssertNil(error)
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssert(response?.allHeaderFields.contains {
                    // swiftlint:disable:next line_length
                    ($0.key as! String).lowercased() == "custom" && ($0.value as? String) == "hello" // swiftlint:disable:this all
                } == true)
                // HEAD request shouldn't have body
                XCTAssert( data == nil || data!.isEmpty )
            }).resume()

        let session = makeSession(config: { (configuration) in
            configuration.setHttpAdditionalHeaders([
                "x-custom-header": "custom",
                // shouldn't override user configure header
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X)"
            ])
        })
        httpRequest(path: "/head", method: "HEAD", in: session) { (_, response, _) in
            XCTAssertEqual(response?.headerString(field: "x-custom-header"), "custom")
            XCTAssertEqual(response?.headerString(field: "User-Agent"),
                           "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X)")
        }.resume()
        waitTasks()
    }
    func testPutPatchDeleteRequest() {
        // begin request
        // NOTE: 这个使用非本地的server不好模拟状态。服务端是分布式的，数据需要存下来，还要注意清理这种临时数据
        let body = "hello".data(using: .utf8)!
        var chain = [
            httpRequest(path: "/file/a.txt", method: "PUT", body: body) { (data, response, error) -> Void in
                XCTAssertNil(error)
                XCTAssert( data == nil || data!.isEmpty )
                XCTAssertEqual(response?.statusCode, 201)
            },
            httpRequest(path: "/file/a.txt", method: "GET", body: Data()) { (data, response, error) -> Void in
                XCTAssertNil(error)
                XCTAssertEqual(data, body)
                XCTAssertEqual(response?.statusCode, 200)
            },
            httpRequest(path: "/file/a.txt", method: "PATCH", body: body) { (data, response, error) -> Void in
                XCTAssertNil(error)
                XCTAssert( data == nil || data!.isEmpty )
                XCTAssertEqual(response?.statusCode, 204)
            },
            httpRequest(path: "/file/a.txt", method: "GET", body: Data()) { (data, response, error) -> Void in
                XCTAssertNil(error)
                XCTAssertEqual(data, body + body)
                XCTAssertEqual(response?.statusCode, 200)
            },
            httpRequest(path: "/file/a.txt", method: "DELETE", body: Data()) { (data, response, error) -> Void in
                XCTAssertNil(error)
                XCTAssert( data == nil || data!.isEmpty )
                XCTAssertEqual(response?.statusCode, 204)
            },
            httpRequest(path: "/file/a.txt", method: "GET", body: Data()) { (data, response, error) -> Void in
                XCTAssertNil(error)
                XCTAssert( data == nil || data!.isEmpty )
                XCTAssertEqual(response?.statusCode, 404)
            }
        ].makeIterator()

        func run() {
            if var task = chain.next() {
                task.completeHandler = {[handler = task.completeHandler](data, response, error) -> Void in
                    handler?(data, response, error)
                    run()
                }
                task.resume()
            }
        }
        run()

        waitTasks()
    }
    func testCancelRequest() {
        let task = httpRequest(path: "/slowresponse") { (_, _, error) -> Void in
            XCTAssertEqual((error as? NSError)?.code, NSURLErrorCancelled)
        }.resume()
        task?.cancel()
        waitTasks()
    }
    func testBugs() {
        // require network
        let url = URL(string: "https://zos.alipayobjects.com/rmsportal/eFatlrQCyUQVBoalzBPS.png")!
        var req = URLRequest(url: url)
        req.enableComplexConnect = self.enableComplexConnect
        resume(request: req) { (_, _, error) -> Void in XCTAssertNil(error, url.absoluteString); }

        waitTasks()
    }

    // MARK: - OTHER MISC
    // swiftlint:disable:next function_body_length
    func testMetrics() {
        guard Self.useRustNetwork else { return }

        var session: BaseSession! // swiftlint:disable:this all
        autoreleasepool { () -> Void in
            var delegate: BaseSessionDelegate! // swiftlint:disable:this all
            var rustMetricsCountShouldbe = 1
            var identifier = ""
            session = makeSession(delegate: {
                delegate = $0
                delegate.authHandler = {
                    switch $0.challenge.protectionSpace.authenticationMethod {
                    case NSURLAuthenticationMethodHTTPBasic:
                        let credential = URLCredential(user: "byte", password: "dance", persistence: .forSession)
                        $0.completionHandler(.useCredential, credential)
                    default: $0.completionHandler(.performDefaultHandling, nil)
                    }
                }
                delegate.finishCollecting = {
                    XCTAssertEqual($0.task.rustMetrics.count, rustMetricsCountShouldbe, identifier)
                    self.tasks.sub(1)
                }
            })

            func changeDownloadTaskStillCanGetMetrics() {
                tasks.add(1) // pair finishCollecting
                delegate.receiveResponse = {
                    $0.completionHandler(.becomeDownload)
                }
                rustMetricsCountShouldbe = 1
                identifier = "download"
                defer { delegate.receiveResponse = nil }

                let url = HttpServer.makeURL(relativeString: "/post")
                // let url = URL(string: "https://zos.alipayobjects.com/rmsportal/eFatlrQCyUQVBoalzBPS.png")!
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                let body = (0..<(1 << 16)).reduce(into: "", { result, _ in result.append("x") })
                req.httpBody = body.data(using: .utf8)!
                req.enableComplexConnect = self.enableComplexConnect
                // becomeDownload only work for non completionHandler
                let task = session.dataTask(with: req)
                task.resume()
                waitTasks()
            }
            func authTaskContainMultipleMetrics() {
                AuthenticateCredentialStorage.shared.clearAllCache()
                rustMetricsCountShouldbe = 2
                identifier = "auth"
                tasks.add(1) // pair finishCollecting
                httpRequest(path: "/auth/login", in: session).resume()
                waitTasks()
            }
            func redirectContainMultipleMetrics() {
                tasks.add(1)
                identifier = "redirect"
                rustMetricsCountShouldbe = 2
                httpRequest(path: "/redirect/receive", in: session).resume()
                waitTasks()
            }

            changeDownloadTaskStillCanGetMetrics()
            authTaskContainMultipleMetrics()
            redirectContainMultipleMetrics()
        }

        if let session = session as? URLSession {
            tasks.add(1)
            session.getAllTasks {
                XCTAssertEqual($0.count, 0)
                #if DEBUG
                XCTAssertEqual(session.leftRustMetricsCount, 0, "should release metrics when finish")
                #endif
                self.tasks.sub(1)
            }
        } else if session is RustHTTPSession {
            #if DEBUG
            XCTAssertEqual(RustHTTPSessionTask.resourceCounter.value, 0)
            #endif
        }
        waitTasks()
    }

    func test404Request() {
        httpRequest(path: "/404Path") { _, response, error -> Void in
            XCTAssertNil(error, "404 should be a normal response, not a error")
            XCTAssertEqual(response?.statusCode, 404)
        }.resume()
        waitTasks()
    }
    func testRetryCount() {
        let responseText = "hello tester!"
        // var first = true
        server["/hello"] = { _ in
            // if first {
            //     first = false
            //     return HttpResponse.internalServerError(nil)
            // }
            return HttpResponse.ok(.text(responseText))
        }

        var task = httpRequest(path: "/hello") { (data, response, error) in
            XCTAssertNil(error)
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertEqual(data, responseText.data(using: .utf8))
        }
        // 测试serverError不会重试，不知道rust什么情况下会重试。
        task.urlrequest.retryCount = 3
        task.resume()
        waitTasks()
    }
    func testConcurrencyLargeDataCompletionTask() {
        #if DEBUG
        HTTProtocol.shouldShowDebugMessage = false
        defer { HTTProtocol.shouldShowDebugMessage = true }
        #endif
        var req = URLRequest(url: HttpServer.makeURL(relativeString: "/largeResponse"))
        let (size, count) = (1 << 27, 4)
        req.allHTTPHeaderFields = ["size": String(size), "count": String(count)]

        let lock = UnfairLock()
        var data = Data()
        var response: URLResponse?
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 8
        let session = makeSession(
            delegate: { [tasks] delegate in
                delegate.enableLog = false
                delegate.receiveResponse = {
                    response = $0.response
                    $0.completionHandler(.allow)
                }
                delegate.receiveData = {
                    let locked = lock.tryLock()
                    if !locked {
                        XCTFail("concurrency issue!")
                        $0.task.cancel()
                        return
                    }
                    defer { if locked { lock.unlock() } }
                    usleep(10)
                    data.append($0.data)
                }
                delegate.complete = {
                    XCTAssertNotNil(response)
                    XCTAssertEqual(data.count, size * count)
                    XCTAssertNil($0.error)
                    tasks.sub(1)
                }
            }, delegateQueue: queue)
        tasks.add(1)
        let task = session.dataTask(with: req)
        task.resume()
        waitTasks()
    }
    #if PLAY
    /// 真机测试系统超过内存限制会直接异常crash，没有错误抛出。大数据应该使用downloadTask
    func testLargeDataCompletionTask() {
        #if DEBUG
        HTTProtocol.shouldShowDebugMessage = false
        defer { HTTProtocol.shouldShowDebugMessage = true }
        #endif
        var req = URLRequest(url: HttpServer.makeURL(relativeString: "/largeResponse"))
        let (size, count) = (1 << 30, 8)
        req.allHTTPHeaderFields = ["size": String(size), "count": String(count)]
        tasks.add(1)
        let task = Self.sharedSession.dataTask(with: req) { [self] (data, response, error) in
            XCTAssertNotNil(response)
            XCTAssertEqual(data?.count, size * count)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            tasks.sub(1)
        }
        task.resume()
        waitTasks()
    }
    class URLSessionTaskOrderTestDelegate: BaseSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
        override func log(function: String = #function) {
            print("Delegate - (Task) \(function)")
            called.append(function)
        }
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            log()
            if let v = complete { v((session, task, error)) }
        }
    }
    // current URLProtocolTests order(system session) test in 16.4 simulator:
    //
    // Delegate - URLProtocolTests: dataTask with block
    // Delegate - urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)
    // Delegate - urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)
    // Delegate - urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)
    // Delegate - urlSession(_:task:didFinishCollecting:)
    // Delegate - URLProtocolTests: dataTask with block end
    // Delegate - URLProtocolTests: dataTask with delegate
    // Delegate - urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)
    // Delegate - urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)
    // Delegate - urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)
    // Delegate - urlSession(_:dataTask:didReceive:completionHandler:)
    // Delegate - urlSession(_:dataTask:didReceive:)
    // Delegate - urlSession(_:dataTask:willCacheResponse:completionHandler:)
    // Delegate - urlSession(_:task:didFinishCollecting:)
    // Delegate - (Task) urlSession(_:task:didCompleteWithError:)
    // Delegate - URLProtocolTests: download with delegate
    // Delegate - urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)
    // Delegate - urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)
    // Delegate - urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)
    // Delegate - urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)
    // Delegate - urlSession(_:task:didFinishCollecting:)
    // Delegate - urlSession(_:downloadTask:didFinishDownloadingTo:)
    // Delegate - (Task) urlSession(_:task:didCompleteWithError:)
    // Delegate - URLProtocolTests: download with complete block
    // Delegate - urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)
    // Delegate - urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)
    // Delegate - urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)
    // Delegate - urlSession(_:task:didFinishCollecting:)
    // Delegate - URLProtocolTests: download with block end

    func testURLSessionDelegateOrder() {
        print(">>> Delegate - Order Start")
        var delegate: BaseSessionDelegate!
        let session = makeSession(delegate: { v in delegate = v })

        var req = URLRequest(url: HttpServer.makeURL(relativeString: "/redirect/greet?code=307&method=POST"))
        req.httpBody = Data(repeating: 33, count: 1 << 6)
        req.setValue("307", forHTTPHeaderField: "code")
        req.httpMethod = "POST"
        do {
            tasks.add(1)
            print("Delegate - \(Self.self): dataTask with block")
            let task = (session as BaseSession).dataTask(with: req) { [self](data, _, _) in
                print("Delegate - \(Self.self): dataTask with block end")
                XCTAssertEqual(data, "greet".data(using: .utf8)!)
                tasks.sub(1)
            }
            if #available(iOS 15.0, *) {
                if let task = task as? URLSessionTask {
                    task.delegate = URLSessionTaskOrderTestDelegate()
                }
            }
            task.resume()
            waitTasks()
        }
        do {
            tasks.add(1)
            print("Delegate - \(Self.self): dataTask with delegate")
            let task = (session as BaseSession).dataTask(with: req)
            delegate.complete = { [self] (v) in
                XCTAssertNil(v.error)
                tasks.sub(1)
            }
            defer { delegate.complete = nil }
            if #available(iOS 15.0, *) {
                if let task = task as? URLSessionTask {
                    task.delegate = URLSessionTaskOrderTestDelegate()
                    (task.delegate as! URLSessionTaskOrderTestDelegate).complete = { [self] (v) in // swiftlint:disable:this all
                        XCTAssertNil(v.error)
                        tasks.sub(1)
                    }
                }
            }
            task.resume()
            waitTasks()
        }
        do {
            tasks.add(1)
            print("Delegate - \(Self.self): download with delegate")
            let task = (session as BaseSession).downloadTask(with: req)
            delegate.complete = { [self] (v) in
                XCTAssertNil(v.error)
                tasks.sub(1)
            }
            defer { delegate.complete = nil }
            if #available(iOS 15.0, *) {
                if let task = task as? URLSessionTask {
                    task.delegate = URLSessionTaskOrderTestDelegate()
                    (task.delegate as! URLSessionTaskOrderTestDelegate).complete = { [self] (v) in // swiftlint:disable:this all
                        XCTAssertNil(v.error)
                        tasks.sub(1)
                    }
                }
            }
            task.resume()
            waitTasks()
        }

        do {
            tasks.add(1)
            print("Delegate - \(Self.self): download with complete block")
            let task2 = (session as BaseSession).downloadTask(with: req) { [self](url, _, _) in
                print("Delegate - \(Self.self): download with block end")
                XCTAssertEqual(url.flatMap { try? Data(contentsOf: $0) }, "greet".data(using: .utf8)!)
                tasks.sub(1)
            }
            if #available(iOS 15.0, *) {
                if let task = task2 as? URLSessionTask {
                    task.delegate = URLSessionTaskOrderTestDelegate()
                }
            }
            task2.resume()
            waitTasks()
        }
    }
    #endif

    // TODO: Proxy
    // TODO: Video Stream, HTTP Live Streaming
    // TODO: Range Support And Cache
    // TODO: Memory Test, Shouldn't have Leak. CustomHTTPProtocol say:
    //   Using a custom NSURLProtocol subclass can cause CFNetwork to leak on HTTP redirects <rdar://problem/10093777>
    //   And Currently 401 re-auth leak Challenge Data
    // TODO: 性能优化，时间和原生对比好像差不少...
}
