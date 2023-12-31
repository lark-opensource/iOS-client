//
//  RustHttpURLProtocol+Authentication.swift
//  LarkRustClient
//
//  Created by SolaWing on 2018/12/21.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import HTTProtocol

// MARK: - URLAuthenticationChallenge Support
extension RustHttpURLProtocol {
    final class AuthenticateEnv: NSObject, URLAuthenticationChallengeSender {
        var url: URL
        var challenges: [HTTProtocol.AuthChallenge]
        var currentChallengeIndex = 0
        var proposedCredential: URLCredential?
        var failResponse: HTTPURLResponse
        var previousFailureCount = 0
        var holdEvents = [ClientEvent]() // hold and return when no valid certificate and no cancel
        #if DEBUG
        weak var waitingChallenge: URLAuthenticationChallenge?
        var waitingClientResponse = false // CustomHTTPProtocol里说必须保证中有一个Auth请求，且发起其它请求前需要先cancel
        #endif
        /// if provide credential, need a req to confirm validity
        var currentHttpReq: RustHttpURLProtocol? {
            willSet {
                // 设置新client时，如果旧client启动了且未停止，释放它。
                // NOTE: 理论上应该在启动线程上回调，保证线程安全
                if let cur = currentHttpReq, cur != newValue, cur.state != .waiting {
                    cur.stopLoading()
                }
            }
        }
        typealias AuthCallback = (URLSession.AuthChallengeDisposition, URLCredential?, URLAuthenticationChallenge) -> Void // swiftlint:disable:this line_length
        var onAuthResponse: AuthCallback
        deinit {
            self.currentHttpReq = nil
        }
        init(url: URL, challenges: [HTTProtocol.AuthChallenge], failResponse: HTTPURLResponse, onAuthResponse: @escaping AuthCallback) { // swiftlint:disable:this line_length
            self.url = url
            self.challenges = challenges
            self.failResponse = failResponse
            self.onAuthResponse = onAuthResponse
        }
        // 现在暂时只处理basic相关处理
        public func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
            self.onAuthResponse( .useCredential, credential, challenge )
        }
        public func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
            self.onAuthResponse(.useCredential, nil, challenge)
        }
        public func cancel(_ challenge: URLAuthenticationChallenge) {
            self.onAuthResponse(.cancelAuthenticationChallenge, nil, challenge)
        }
        public func performDefaultHandling(for challenge: URLAuthenticationChallenge) {
            self.onAuthResponse(.performDefaultHandling, nil, challenge)
        }
        public func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {
            self.onAuthResponse(.rejectProtectionSpace, nil, challenge)
        }
    }

    /// main entry for auth environment
    func _dealAuthentication(for response: HTTPURLResponse) { // swiftlint:disable:this identifier_name
        // [Basic Auth](https://tools.ietf.org/html/rfc7617)
        guard
            _handleAuth,
            case let auth = validate(response: response), !auth.isEmpty,
            let url = response.url
            else { return }

        // 每次请求服务端可能返回一组Challenge. 之后
        // ## 开始验证:
        // * 如果client取消，则报取消错误
        // * 如果client提供credential, 则重新请求服务器。之后:
        //   - 如果成功，则把回应传递给client, 旧回应丢弃
        //   - 如果仍然无效，替换Challenge数据，回到 [开始验证]()
        // * 如果client reject space, 跳转到下一个space, 让client验证. 直到没有更多的space, 返回原数据
        // * 如果client执行默认操作，首次默认操作是取历史缓存重新请求。否则跳转到下一个space
        //   - 默认请求成功则返回
        //   - 失败则替换challenge数据，回到[开始验证]()
        //      - 失败后还执行默认操作，是直接跳转到下一个space，直到结束返回原数据

        // ignore following message, until auth complete
        // hold the first original response. forward the original response if run out challenge
        _authEnv = AuthenticateEnv(url: url, challenges: auth, failResponse: response, onAuthResponse: {[weak self] type, credential, challenge in // swiftlint:disable:this line_length
            self?.workQueue?.run {
                // ensure not stopLoading after async call
                guard let self = self, !self.isFinish else { return }
                #if DEBUG
                assert(challenge === self._authEnv?.waitingChallenge)
                self._authEnv?.waitingChallenge = nil // should only receive once
                self._authEnv?.waitingClientResponse = false
                #endif
                switch type {
                case .useCredential:
                    // swiftlint:disable:next line_length
                    guard let credential = credential, self.basicAuth(credential: credential, for: challenge, save: true) else {
                        // other credential not implement, simply complete it
                        self._forwardHoldResponses()
                        return
                    }
                case .cancelAuthenticationChallenge:
                    self._authEnv = nil
                    self._response(errorDomain: NSURLErrorDomain, code: NSURLErrorCancelled)
                case .performDefaultHandling:
                    // 只有首次时的proposed是事先存在容器中的，尝试使用它
                    if challenge.previousFailureCount == 0 {
                        if let credential = challenge.proposedCredential {
                            if self.basicAuth(credential: credential, for: challenge) {
                                return
                            }
                        }
                    }
                    // for unknown or exceptions, default to jump to next space, like URLSession does
                    self._authEnv?.currentChallengeIndex += 1
                    self.notifyClientAuth()
                case .rejectProtectionSpace:
                    self._authEnv?.currentChallengeIndex += 1
                    self.notifyClientAuth()
                @unknown default:
                    assertionFailure()
                }
            }
        })
        notifyClientAuth()
    }
    /// - Returns: if valid response, else change _authEnv and return false
    private func validate(response: HTTPURLResponse) -> [HTTProtocol.AuthChallenge] {
        if response.statusCode == 401, case let auth = HTTProtocol.extract(authenticate: response.wwwAuthenticate) {
            return auth
        }
        return []
    }
    private func notifyClientAuth() {
        assert(workQueue?.isInQueue() == true, "auth should run on start thread for safety")
        guard
            let authEnv: AuthenticateEnv = _authEnv,
            let host = authEnv.url.host,
            let port = authEnv.url.defaultPort
            else { return }

        while authEnv.currentChallengeIndex < authEnv.challenges.count {
            let challengeInfo = authEnv.challenges[authEnv.currentChallengeIndex]
            guard challengeInfo.scheme == "basic", let realm = challengeInfo.1["realm"] else {
                authEnv.currentChallengeIndex += 1
                continue
            }
            #if DEBUG
            assert(!authEnv.waitingClientResponse)
            authEnv.waitingClientResponse = true
            #endif
            // TODO: Proxy Support
            let space = URLProtectionSpace(host: host, port: port, protocol: authEnv.url.scheme, realm: realm,
                                           authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
            let completionHandler = { () -> Void in
                // NOTE: AuthenticationChallenge没释放，内存泄漏
                // 看profile调用，应该在teardown的时候释放的. 是传第二个challenge把第一个给覆盖了却没释放?
                // 下次调用前，调用didCancel: challenge, 仍然泄漏
                // 改内部对象，不创建新的Challenge，也会导致多次retain，最后不释放...
                // 强制释放Challenge, 但仍然泄漏内部创建的对象..., 而且如果有其它client能正确释放的，反而破坏内存
                // 现在判断URLSession的情况，特殊处理，直接调用delegate, 但这样的话超时不会被重置延长..
                //
                // NOTE: iOS 13改版，不会调用这个sender了..
                let challenge = URLAuthenticationChallenge(
                    protectionSpace: space,
                    proposedCredential: authEnv.proposedCredential,
                    previousFailureCount: authEnv.previousFailureCount,
                    failureResponse: authEnv.failResponse,
                    error: nil,
                    sender: authEnv)
                #if DEBUG
                authEnv.waitingChallenge = challenge
                #endif
                debug( "\(dump(request: self.request)) waitAuth(\(authEnv.previousFailureCount)): \(challenge.protectionSpace)" ) // swiftlint:disable:this all
                self.context.auth(challenge: challenge)
            }
            setupProposedCredential(authEnv: authEnv, for: space, completionHandler: completionHandler)
            return // wait async callback -> authEnv.api
        }
        // no more valid challenge, simply finish
        self._forwardHoldResponses()
    }
    private func setupProposedCredential(authEnv: AuthenticateEnv, for space: URLProtectionSpace,
                                         completionHandler: @escaping () -> Void) {
        // load proposedCredential from storage
        if authEnv.proposedCredential == nil, let storage = self.context.credentialStorage {
            // try get from storage
            if let task = self.task {
                #if DEBUG
                var hasCallbacked = false
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 3) {
                    assert(hasCallbacked) // 确定一定会有回调
                }
                #endif
                storage.getDefaultCredential(for: space, task: task) { credential in
                    self.workQueue?.run {
                        #if DEBUG
                        hasCallbacked = true
                        #endif
                        authEnv.proposedCredential = credential
                        completionHandler()
                    }
                }
                return // wait async get credential from storage
            } else {
                authEnv.proposedCredential = storage.defaultCredential(for: space)
            }
        }
        completionHandler()
    }
    private func basicAuth(credential: URLCredential, for challenge: URLAuthenticationChallenge, save: Bool = false)
    -> Bool {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic,
            // api doc say password may need some time to obtain. test hasPassword first
            let user = credential.user, credential.hasPassword, let password = credential.password,
            let authEnv = self._authEnv,
            case var newRequest = self.request,
            let url = newRequest.url
        else { return false }

        let space = challenge.protectionSpace // 避免持胡challenge, challenge持有sender, 可能循环引用
        // 虽然官方说user里包含:是非法的，但看苹果实现没管这些
        let authorizationValue: String
        if let authStr = "\(user):\(password)".data(using: .utf8)?.base64EncodedString() {
            authorizationValue = "Basic \(authStr)"
        } else {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            authorizationValue = ""
            #endif
        }
        newRequest.setValue(authorizationValue, forHTTPHeaderField: "Authorization")

        let client = makeAuthClient { valid in
            // store credential
            if credential.persistence != .none {
                if valid {
                    // FIXME: 不同URLSession应该保存不同的path授权信息
                    // 但就URLSession的实现来说，其实是session缓存 + 共享缓存。
                    // session缓存没有时取共享缓存的, 并回调delegate

                    // 内存缓存请求后始终更新, 之后再请求会复用内存中的值而不再去系统共享的里面取或调用delegate
                    AuthenticateCredentialStorage.shared.saveAuth(url: url,
                                                                  header: ("authorization", authorizationValue))
                    if save { self.save(credential: credential, with: space, success: true) }
                } else {
                    AuthenticateCredentialStorage.shared.saveAuth(url: url, header: ("authorization", nil))
                    if save { self.save(credential: credential, with: space, success: false) }
                }
            }
        }
        let connection = context.nextConnection(request: newRequest, client: client)
        connection._handleAuth = false // response auth directly
        authEnv.currentHttpReq = connection
        connection.startLoading() // NOTE: 需要保证在同样的启动线程上运行，避免各种线程安全问题。
        return true
    }
    private func makeAuthClient(responseHook: @escaping (Bool) -> Void) -> URLProtocolClient {
        // 验证通过后发送hold的event
        var holdEvents: [URLProtocolForwardClient.Event] = []
        return URLProtocolForwardClient { [weak self] (forwardClient, event) in
            guard let self = self, !self.isFinish else { return }
            self.context.authProgress()
            let finish = {
                // 收到正常的响应后，全部转发给原client. 原未授权响应丢弃.
                // NOTE: not set _authEnv to nil or it will stopLoading auth connection
                // and _authEnv prevent original response in _response(event:)
                for v in holdEvents {
                    self.response(event: v.data)
                }
                self.response(event: event.data)

                // 已经确认有效response，后续的event也转发
                forwardClient.onEvent = {[weak self] in
                    guard let self = self, !self.isFinish else { return }
                    self.response(event: $1.data)
                }
            }
            switch event.data {
            case let .receive(response, _):
                if
                    let response = response as? HTTPURLResponse,
                    case let auth = self.validate(response: response),
                    !auth.isEmpty,
                    let authEnv = self._authEnv // _authEnv持有这次请求，避免捕获导致循环引用
                {
                    // 还是无效，循环验证流程
                    responseHook(false)

                    authEnv.failResponse = response
                    authEnv.previousFailureCount += 1
                    authEnv.challenges = auth // replace current challenges to newer
                    authEnv.currentChallengeIndex = 0
                    authEnv.currentHttpReq = nil // release the invalid request immediately
                    self.notifyClientAuth()
                } else {
                    responseHook(true)
                    finish()
                }
            default:
                if event.data.isFinishEvent { // 异常结束，直接按结束验证处理
                    finish()
                } else { // holder temp event, eg: redirect
                    holdEvents.append(event)
                }
            }
        }
    }

    private func save(credential: URLCredential, with space: URLProtectionSpace, success: Bool) {
        self._authEnv?.proposedCredential = credential
        guard credential.persistence != .none, let storage = self.context.credentialStorage, let user = credential.user
            else { return }
        // 通过观察URLSession，无论成功失败都覆盖, 但失败的不保存password
        var saveCredential = credential
        if !success {
            // 不成功时，应该只存username进去，不存不正确的password
            // NOTE: 方法签名是非空的，试了传空字符串hasPassword返回true, password返回"".
            // 强行传nil有用，返回符合预期，但可能有实现兼容问题, 需要多观察
            let sel = NSSelectorFromString("credentialWithUser:password:persistence:")
            typealias MakeCredential = @convention(c) (AnyObject, Selector, String, String?, URLCredential.Persistence) -> URLCredential // swiftlint:disable:this line_length
            let imp = unsafeBitCast(URLCredential.method(for: sel), to: MakeCredential.self)
            saveCredential = imp(URLCredential.self, sel, user, nil, credential.persistence)
            assert(!saveCredential.hasPassword)
        }
        if let task = self.task {
            storage.setDefaultCredential(saveCredential, for: space, task: task)
        } else {
            storage.setDefaultCredential(saveCredential, for: space)
        }
    }
}

// MARK: - AuthInfoStorage

/// threadsafe storage for save credential infomation
/// 根据`https://tools.ietf.org/html/rfc7617#2.2`, same base url should share auth
///
/// URLSession有维护内存私有的Storage, 发起请求时会自动带上私有Storage里的Auth信息。
/// 请求失败时，才调用delegate或者从设置(共享)的URLCredentialStorage里取信息。
/// 这个类即是为了替代URLSession的私有Storage，提供相应的Auth信息，让自定义URLProtocol能实现相应的兼容行为。
final class AuthenticateCredentialStorage {

    static var shared = AuthenticateCredentialStorage()
    // TODO: 暂时只存basic的, 以后加入其它的Auth后再扩展
    // TODO: 现在只要保存的方法，没分Session保存也不支持清理...

    // serverURL: headerField: path: headerValue
    private var storage: [URL: [String: [String: String]]] = [:]
    private var lock = DispatchSemaphore(value: 1)

    /// save auth header infomation in storage
    ///
    /// - Parameters:
    ///   - url: the auth url
    ///   - header: the saved header, should be (lowercase header field, header value)
    func saveAuth(url: URL, header: (String, String?)) {
        var spaceURL = url.deletingLastPathComponent()
        guard let serverURL = URL(string: "/", relativeTo: url)?.absoluteURL else { return }
        var path = spaceURL.path

        lock.wait(); defer { lock.signal() }
        storage[serverURL, default: [:]][header.0, default: [:]][path] = header.1
    }
    func header(for url: URL) -> [(String, String)] {
        guard let serverURL = URL(string: "/", relativeTo: url)?.absoluteURL else { return [] }
        var path = url.path; if path.isEmpty { path = "/" }

        lock.wait(); defer { lock.signal() }
        guard let spaces = storage[serverURL] else { return [] }
        return spaces.compactMap { (field, v) in
            // 取最长的前缀path上保存的auth信息
            let headerValue = v.filter { path.hasPrefix($0.key) }
                .max { $0.key.count < $1.key.count }?
                .value
            return headerValue.flatMap { (field, $0) }
        }
    }
    // test only, currently no way for outer user clear the auth memory cache..
    func clearAllCache() {
        lock.wait(); defer { lock.signal() }
        storage = [:]
    }
}

extension TaskContext {
    func nextConnection(request: URLRequest, client: URLProtocolClient) -> RustHttpURLProtocol {
        let connection = RustHttpURLProtocol(request: request, cachedResponse: nil, client: client)
        connection.workQueue = base.workQueue
        if let task = base._task {
            connection._task = task // pass current task so can use same session configuration
            task.add(metric: connection.metrics)
        }
        return connection
    }
    func authProgress() {
        // 默认的URLSession没有刷新timeout的能力
    }
    func auth(challenge: URLAuthenticationChallenge) {
        let useSessionDelegate: Bool
        if #available(iOS 13.0, *) {
            useSessionDelegate = true
        } else {
            useSessionDelegate = challenge.previousFailureCount > 0
        }
        if useSessionDelegate, let session = session {
            self.notify(session: session, challenge: challenge)
        } else {
            base.response(event: .challenge(challenge))
        }
    }
    private func notify(session: URLSession, challenge: URLAuthenticationChallenge) {
        guard let sender = challenge.sender as? RustHttpURLProtocol.AuthenticateEnv else {
            assertionFailure("pass in challenge should use AuthenticateEnv as sender")
            return
        }
        if let callback = (session.delegate as? URLSessionTaskDelegate)?.urlSession(_:task:didReceive:completionHandler:), let task = self.task {
            session.delegateQueue.addOperation {
                callback(session, task, challenge) { (choose, credential) in
                    // RustHttpURLProtocol will ensure callback run on start thread.
                    // so we don't need to throwing to start thread here
                    sender.onAuthResponse(choose, credential, challenge)
                }
            }
        } else {
            sender.onAuthResponse(.performDefaultHandling, nil, challenge)
        }
    }
}
