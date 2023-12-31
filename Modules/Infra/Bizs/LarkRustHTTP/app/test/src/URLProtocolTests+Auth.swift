//
//  URLProtocolTests+Auth.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2018/12/21.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import XCTest
@testable import LarkRustClient
@testable import LarkRustHTTP

extension URLProtocolTests {
    func basicAuth(
        user: String, password: String,
        failPolicy: URLSession.AuthChallengeDisposition = .performDefaultHandling,
        persistence: URLCredential.Persistence = .forSession
        ) -> BaseSessionDelegate.AuthHandler {
        return basicAuth(credentials: [(user, password)], failPolicy: failPolicy, persistence: persistence)
    }
    func basicAuth(
        credentials: [(user: String, password: String)],
        failPolicy: URLSession.AuthChallengeDisposition = .performDefaultHandling,
        persistence: URLCredential.Persistence = .forSession
        ) -> BaseSessionDelegate.AuthHandler {
        return { env in
            let credential = credentials[env.challenge.previousFailureCount % credentials.count]
            let user = credential.user, password = credential.password
            debug("receive challenges:\(env.challenge.previousFailureCount): \(env.challenge.protectionSpace). use: \(user):\(password) response: \(String(describing: env.challenge.failureResponse)) proposed: \(String(describing: env.challenge.proposedCredential))") // swiftlint:disable:this all
            debug("challenges \(env.challenge) => sender: \(env.challenge.sender?.description ?? "nil")")
            let completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void = { (policy, cred) in
                debug("challenge completeHandler \(policy) \(cred?.description ?? "nil")")
                env.completionHandler(policy, cred)
            }
            guard env.challenge.previousFailureCount < credentials.count else {
                completionHandler(failPolicy, nil)
                return
            }
            switch env.challenge.protectionSpace.authenticationMethod {
            case NSURLAuthenticationMethodHTTPBasic:
                let credential = URLCredential(user: user, password: password, persistence: persistence)
                completionHandler(.useCredential, credential)
            default: completionHandler(.performDefaultHandling, nil)
            }
        }
    }
    func testBasicAuth() { // swiftlint:disable:this all
        /*
         debug("all credentials \(String(describing: URLCredentialStorage.shared.allCredentials))")
         // clear history storage
         */
        // avoid cache inteference
        URLCredentialStorage.shared.removeAll()
        AuthenticateCredentialStorage.shared.clearAllCache()

        var delegate: BaseSessionDelegate! // swiftlint:disable:this all
        // urlCredentialStorage好像不影响URLSession复用通过的验证, 而且提供的凭据也不存进去?  (自己new出来只是抽象的没功能?)
        // 好像URLSession只调用default的get和set方法, 且还移除了password
        // 怀疑其它的保存是直接调用了CF的里面的方法
        //
        // 但是shared的(包括forSession)会存进去. 而且shared会影响到共享的session. 共享的session遇到401里，默认处理是提供storage里的凭据
        // 有delegate情况下，首次回调也会把凭据放到proposed里面
        // session验证成功的情况下, 后续同path域的不会再回调
        //
        // 进一步验证，shared里用default方法取出的是该space最近一次设置的credential(如果是错的，就没password, 正确的有password)
        //
        // configuration.urlCredentialStorage = URLCredentialStorage()
        let session = makeSession(delegate: { delegate = $0 })

        func defaultAuthWithoutHandling(willBe: Int) {
            httpRequest(path: "/auth/login") { (_, response, error) in
                XCTAssertNil(error)
                XCTAssertEqual(response?.statusCode, willBe)
                }.resume()
            waitTasks()
        }

        func wrongUserNameStill401() {
            for policy in [.performDefaultHandling, .rejectProtectionSpace] as [URLSession.AuthChallengeDisposition] {
                delegate.authHandler = basicAuth(user: "faker", password: "pass", failPolicy: policy)
                httpRequest(path: "/auth/login", in: session) { (data, response, error) in
                    XCTAssertNil(error)
                    XCTAssertEqual(response?.statusCode, 401)
                    // URLSession default return first invalid response
                    XCTAssertEqual(data, "no user".data(using: .utf8))
                    }.resume()
                waitTasks()
            }
        }
        func userNameContainColonWillAlsoSendToServer() {
            // cancel when failed to ensure last request is my auth
            delegate.authHandler = basicAuth(user: "faker:aa", password: "pass", failPolicy: .cancelAuthenticationChallenge) // swiftlint:disable:this all
            httpRequest(path: "/auth/login", in: session) { (data, response, error) in
                let error = error as? URLError
                XCTAssertEqual(error?.code, URLError.cancelled)
                XCTAssertNil(response)
                self.httpRequest(path: "/auth/state") { data, _, _ in
                    XCTAssertEqual(data, "faker:aa:pass".data(using: .utf8))
                    }.resume()
                }.resume()
            waitTasks()
        }
        func cancelAuthCauseCancelRequestError() {
            delegate.authHandler = basicAuth(user: "faker", password: "pass",
                                             failPolicy: .cancelAuthenticationChallenge)
            httpRequest(path: "/auth/login", in: session) { (_, response, error) in
                let error = error as? URLError
                XCTAssertEqual(error?.code, URLError.cancelled)
                XCTAssertNil(response)
                }.resume()
            waitTasks()
        }
        func willRechallengeIfProvideWrongInfo() {
            // final provide correct info, so will be success when final
            delegate.authHandler = basicAuth(credentials: [("byte", ""), ("byte", "wrong"), ("byte", "dance")],
                                             persistence: .none)
            httpRequest(path: "/auth/login", in: session) { (data, response, error) in
                XCTAssertNil(error)
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssertEqual(data, "byte:dance".data(using: .utf8))
                }.resume()
            waitTasks()
        }
        func correctUserGet200(persistence: URLCredential.Persistence) {
            delegate.authHandler = basicAuth(user: "byte", password: "dance", persistence: persistence)
            httpRequest(path: "/auth/login", in: session) { (data, response, error) in
                XCTAssertNil(error)
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssertEqual(data, "byte:dance".data(using: .utf8))
                }.resume()
            waitTasks()
        }
        func followingTaskHasAuthWithoutDealItAfterSaveCorrectAuth() {
            // session persistence don't need our provide auth twice
            delegate.authHandler = nil
            httpRequest(path: "/auth/login", in: session) { (data, response, _) in
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssertEqual(data, "byte:dance".data(using: .utf8))
                }.resume()
        }
        func otherRequest(path: String, in urlsession: BaseSession? = nil, shouldAuth: Bool) {
            delegate.authHandler = nil
            httpRequest(path: path, in: urlsession ?? session) { (data, response, _) in
                XCTAssertEqual(response?.statusCode, 200)
                let headers = { () -> [String: String]? in
                    guard let data = data else { return nil }
                    return try? JSONDecoder().decode([String: String].self, from: data)
                }()
                let expect = "Basic \("byte:dance".data(using: .utf8)!.base64EncodedString())" // swiftlint:disable:this all
                XCTAssert( headers?.contains {
                    $0.key.lowercased() == "authorization" && $0.value == expect
                    } == shouldAuth, "\((path, urlsession, shouldAuth))")
                }.resume()
        }

        // 虽然多challenge应该不是很常见
        // 目前观察到苹果总是回调最后一个Basic realm, 哪怕是返回多个www-auth

        defaultAuthWithoutHandling(willBe: 401)
        cancelAuthCauseCancelRequestError()
        willRechallengeIfProvideWrongInfo()
        correctUserGet200(persistence: .none)
        // none Persistence also need auth when next request
        wrongUserNameStill401()
        userNameContainColonWillAlsoSendToServer()

        correctUserGet200(persistence: .forSession)
        // 测试运行发现URLSession获取到Valid的auth后，对同url base的网址就会自动带上auth，不会再回调授权
        // wrongUserNameStill401()

        followingTaskHasAuthWithoutDealItAfterSaveCorrectAuth()

        // https://tools.ietf.org/html/rfc7617#section-2.2
        // 相同path的应该共用credential
        otherRequest(path: "/auth/header", shouldAuth: true)
        otherRequest(path: "/header", shouldAuth: false)
        // otherRequest(path: "/header", in: URLSession.shared, shouldAuth: false)
        waitTasks()

        // after custom session set auth in shared credentialStorage,
        // other session will also has these proposed credential
        defaultAuthWithoutHandling(willBe: 200) // after save, shared session will first reject and then use saved auth.
        otherRequest(path: "/auth/header", in: Self.sharedSession, shouldAuth: true)
        otherRequest(path: "/header", in: Self.sharedSession, shouldAuth: false)

        waitTasks()
        // debug("custom all credentials \(String(describing: session.configuration.urlCredentialStorage?.allCredentials))") // swiftlint:disable:this line_length
        debug("all credentials \(String(describing: URLCredentialStorage.shared.allCredentials))")
    }
    // TODO: 其它Auth方法支持
}
