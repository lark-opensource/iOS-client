//
//  EENavigatorAsyncTests.swift
//  EENavigatorDemoTests
//
//  Created by liuwanlin on 2020/2/23.
//  Copyright © 2020年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
@testable import EENavigator

struct CardBody: CodableBody {
    static var patternConfig = PatternConfig(pattern: "/card/:id", type: .path)

    var _url: URL {
        return URL(string: "/card/\(id)")!
    }

    let id: String

    init(id: String) {
        self.id = id
    }

}

struct RedirectBody: CodableBody {
    static var patternConfig = PatternConfig(pattern: "/redirect/:id", type: .path)

    var _url: URL {
        return URL(string: "/redirect/\(id)")!
    }

    let id: String

    init(id: String) {
        self.id = id
    }
}

struct RedirectOneBody: CodableBody {
    static var patternConfig = PatternConfig(pattern: "/redirect/one/:id", type: .path)

    var _url: URL {
        return URL(string: "/redirect/one/\(id)")!
    }

    let id: String

    init(id: String) {
        self.id = id
    }
}

struct AsynRedirectBody: CodableBody {
    static var patternConfig = PatternConfig(pattern: "/asynRedirect/:id", type: .path)

    var _url: URL {
        return URL(string: "/asynRedirect/\(id)")!
    }

    let id: String

    init(id: String) {
        self.id = id
    }
}

struct FinishBody: CodableBody {
    static var patternConfig = PatternConfig(pattern: "/finish/:id", type: .path)

    var _url: URL {
        return URL(string: "/finish/\(id)")!
    }

    let id: String

    init(id: String) {
        self.id = id
    }
}

struct ChatByIDBody: CodableBody {
    static var patternConfig = PatternConfig(pattern: "/chat/by/:id", type: .path)

    var _url: URL {
        return URL(string: "/chat/by/\(id)")!
    }

    let id: String

    init(id: String) {
        self.id = id
    }
}

struct ChatBody: CodableBody {
    static var patternConfig = PatternConfig(pattern: "/chat/:id", type: .path)

    var _url: URL {
        return URL(string: "/chat/\(id)")!
    }

    let id: String

    init(id: String) {
        self.id = id
    }
}

struct ThreadBody: CodableBody {
    static var patternConfig = PatternConfig(pattern: "/thread/:id", type: .path)

    var _url: URL {
        return URL(string: "/thread/\(id)")!
    }

    let id: String

    init(id: String) {
        self.id = id
    }
}

class EENavigatorAsyncTests: XCTestCase {
    override func setUp() {
        super.setUp()

        Navigator.shared.registerRoute(type: CardBody.self) { (_, _, res) in
            res.wait()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                res.end(resource: UIViewController())
            })
        }

        setupForMutilAsyncRedirect()
        setupRedirectAndAsyncRedirect()

        UIApplication.shared.keyWindow?.rootViewController = UINavigationController(rootViewController: UIViewController())
    }

    override func tearDown() {
        super.tearDown()

        tearMutilAsyncRedirect()
        tearDownRedirectAndAsyncRedirect()
        Navigator.shared.deregisterRoute(ThreadBody.patternConfig.pattern)
    }

    func setupForMutilAsyncRedirect() {
        Navigator.shared.registerRoute(type: ChatByIDBody.self) { (body, _, res) in
           res.wait()
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
               res.redirect(body: ChatBody(id: body.id))
           })
        }

        Navigator.shared.registerRoute(type: ChatBody.self) { (body, _, res) in
           res.redirect(body: ThreadBody(id: body.id))
        }

        Navigator.shared.registerRoute(type: ThreadBody.self) { (body, _, res) in
           res.end(resource: UIViewController())
        }
    }

    func tearMutilAsyncRedirect() {
        Navigator.shared.deregisterRoute(CardBody.patternConfig.pattern)
        Navigator.shared.deregisterRoute(ChatByIDBody.patternConfig.pattern)
        Navigator.shared.deregisterRoute(ChatBody.patternConfig.pattern)
    }

    /// 测试场景：push card with id 1, push again after 0.1 second, push again after 0.1 second
    /// 预期结果：只有第一个push生效，后续push都被忽略
    func testMutilAsyncPush() {
        let nvc = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)!

        let expectation1 = XCTestExpectation(description: "push 1")
        Navigator.shared.push(body: CardBody(id: "1"), from: nvc.topViewController!, animated: false, completion: { _,_ in
            XCTAssert(nvc.viewControllers.count == 2)
            expectation1.fulfill()
        })

        let expectation2 = XCTestExpectation(description: "push 1, 2nd")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            Navigator.shared.push(body: CardBody(id: "1"), from: nvc.topViewController!, animated: false, completion: { _,_ in
                XCTAssert(nvc.viewControllers.count == 2)
                expectation2.fulfill()
            })
        })

        let expectation3 = XCTestExpectation(description: "push 1, 3rd")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            Navigator.shared.push(body: CardBody(id: "1"), from: nvc.topViewController!, animated: false, completion: { _,_ in
                XCTAssert(nvc.viewControllers.count == 2)
                expectation3.fulfill()
            })
        })

        wait(for: [expectation1, expectation2, expectation3], timeout: 2)
    }

    /// 测试场景：push card with id 1, push card with id 2, push card with id 1
    /// 预期结果：第一步栈内有1，第二部站内有1，2，第三步栈内只有1
    func testMutilAsyncPush2() {
        let nvc = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)!

        let expectation1 = XCTestExpectation(description: "push 1")
        Navigator.shared.push(body: CardBody(id: "1"), from: nvc.topViewController!, animated: false, completion: { _,_ in
            XCTAssert(nvc.viewControllers.count == 2)
            expectation1.fulfill()
        })

        let expectation2 = XCTestExpectation(description: "push 2")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            Navigator.shared.push(body: CardBody(id: "2"), from: nvc.topViewController!, animated: false, completion: { _,_ in
                XCTAssert(nvc.viewControllers.count == 3)
                expectation2.fulfill()
            })
        })

        let expectation3 = XCTestExpectation(description: "push 1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            Navigator.shared.push(body: CardBody(id: "1"), from: nvc.topViewController!, animated: false, completion: { _,_ in
                XCTAssert(nvc.viewControllers.count == 2)
                expectation3.fulfill()
            })
        })

        wait(for: [expectation1, expectation2, expectation3], timeout: 2)
    }

    /// 测试场景：多次 push ChatByIDBody(1) -> asyn redirect ChatBody(1) -> syn redirect ThreadBody(1)
    /// 预期结果：能避免重复进入，栈内只有一个1
    func testMutilAsyncRedirect() {
        let nvc = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)!

        let expectation1 = XCTestExpectation(description: "push 1")
        Navigator.shared.push(body: ChatByIDBody(id: "1"), from: nvc, animated: false, completion: { _,_ in
            XCTAssert(nvc.viewControllers.count == 2)
            expectation1.fulfill()
        })

        let expectation2 = XCTestExpectation(description: "push 1")
        Navigator.shared.push(body: ChatByIDBody(id: "1"), from: nvc.topViewController!, animated: false, completion: { _,_ in
            XCTAssert(nvc.viewControllers.count == 2)
            expectation2.fulfill()
        })

        let expectation3 = XCTestExpectation(description: "push 1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            Navigator.shared.push(body: ChatByIDBody(id: "1"), from: nvc.topViewController!, animated: false, completion: { _,_ in
                XCTAssert(nvc.viewControllers.count == 2)
                expectation3.fulfill()
            })
        })

        wait(for: [expectation1, expectation2, expectation3], timeout: 2)
    }

    /// 测试场景：syn redirect(1) -> asyn redirect(1) -> syn redirect(1) -> end
    /// 预期结果：能成功进入1
    func testRedirectAndAsyncRedirect() {
        let nvc = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)!

        let expectation1 = XCTestExpectation(description: "push 1")
        Navigator.shared.push(body: RedirectBody(id: "1"), from: nvc, animated: false, completion: { _,_ in
            XCTAssert(nvc.viewControllers.count == 2)
            expectation1.fulfill()
        })

        wait(for: [expectation1], timeout: 2)
    }

    func setupRedirectAndAsyncRedirect() {
        Navigator.shared.registerRoute(type: RedirectBody.self) { (body, _, res) in
            res.redirect(body: AsynRedirectBody(id: body.id))
        }

        Navigator.shared.registerRoute(type: AsynRedirectBody.self) { (body, _, res) in
            res.wait()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                res.redirect(body: RedirectOneBody(id: body.id))
            })
        }

        Navigator.shared.registerRoute(type: RedirectOneBody.self) { (body, _, res) in
            res.redirect(body: FinishBody(id: body.id))
        }

        Navigator.shared.registerRoute(type: FinishBody.self) { (body, _, res) in
           res.end(resource: UIViewController())
        }
    }

    func tearDownRedirectAndAsyncRedirect() {
        Navigator.shared.deregisterRoute(RedirectBody.patternConfig.pattern)
        Navigator.shared.deregisterRoute(AsynRedirectBody.patternConfig.pattern)
        Navigator.shared.deregisterRoute(RedirectOneBody.patternConfig.pattern)
        Navigator.shared.deregisterRoute(FinishBody.patternConfig.pattern)
    }
}
