//
//  EENavigatorDemoTests.swift
//  EENavigatorDemoTests
//
//  Created by liuwanlin on 2018/9/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
@testable import EENavigator

class TestOpenBody: PlainBody {
    
    static var pattern: String {
        return "/OpenWithBody"
    }
    
}

class TestPresentFrom: NavigatorFrom {
    
    var fromViewController: UIViewController? = nil
    
}

class TestRegisterRouterHandler: RouterHandler {
    func handle(req: Request, res: Response) {
        let resource = RouterResource()
        res.end(resource: resource)
    }
}


class TabProviderImpl: TabProvider {

    var tabbarController: UITabBarController?

    public func switchTab(to tabIdentifier: String) {

        if let index = tabbarController?.viewControllers?.firstIndex(where: { (vc) -> Bool in
            return vc.accessibilityLabel == tabIdentifier
        }) {
            tabbarController?.selectedIndex = index
        }
    }
}

class EENavigatorTests: XCTestCase {
    
    var tabProvider = TabProviderImpl()
    
    override func setUp() {
        super.setUp()

        let handler1: Handler = { (req, _) in
            print(req.url.absoluteString)
        }

        let handler2: Handler = { (_, _) in
            print("empty middleware")
        }
        Navigator.shared.tabProvider = {
            return self.tabProvider
        }


        Navigator.shared.registerMiddleware(handler1)
        Navigator.shared.registerMiddleware(handler2)
        Navigator.shared.registerRoute(match: { url in
            return url.absoluteString.hasPrefix("match")
        }, priority: .default) { req in
            return true
        } _: { req, res in
            let vc = UIViewController()
            res.end(resource: vc)
        }


        Navigator.shared.registerMiddleware(regExpPattern: "^/chat(/.*)?", { (_, _) in
            print("pass through chat")
        })

        Navigator.shared.registerRoute(pattern: "/clendar") { (_, res) in
            let nvc = UINavigationController(rootViewController: UIViewController())
            res.end(resource: nvc)
        }
        Navigator.shared.registerRoute(pattern: "/feed") { (_, res) in
            let nvc = UINavigationController(rootViewController: UIViewController())
            res.end(resource: nvc)
        }
        Navigator.shared.registerRoute(pattern: "/mine") { (_, res) in
            let nvc = UINavigationController(rootViewController: UIViewController())
            res.end(resource: nvc)
        }

        Navigator.shared.registerRoute(pattern: "/chat") { (_, res) in
            res.end(resource: UIViewController())
        }
        Navigator.shared.registerRoute(pattern: "/chat/setting") { (_, res) in
            res.end(resource: UIViewController())
        }

        Navigator.shared.registerRoute(pattern: "/chat/setting/present") { (_, res) in
            res.end(resource: UIViewController())
        }

        Navigator.shared.registerRoute(regExpPattern: "^http(s)?\\://.*") { (_, res) in
            let vc = UIViewController()
            vc.title = "web"
            res.end(resource: vc)
        }

        Navigator.shared.registerRoute(pattern: "/async") { (_, res) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                res.end(resource: UIViewController())
            })
            res.wait()
        }
        Navigator.shared.registerRoute(type: TestOpenBody.self) { body, req, res in
            let vc = UIViewController()
            res.end(resource: vc)
        }

        Navigator.shared.registerOpenType(pattern: "/chat") { (_, _) -> OpenType? in
            return .showDetail
        }
        
        Navigator.shared.registerOpenType(plainPattern: "/plainPattern") { (_, _) -> OpenType? in
            return .showDetail
        }
        
        Navigator.shared.registerOpenType(regExpPattern: "/regExpPattern") { (_, _) -> OpenType? in
            return .showDetail
        }
        
        Navigator.shared.registerRoute(pattern: "/testCacheHandler",
                                       priority: .default,
                                       tester: { _ in
                                           true
                                       },
                                       cacheHandler: true) {
                                            return TestRegisterRouterHandler()
                                       }

        let tabFeed: UIViewController! = Navigator.shared
            .response(for: URL(string: "/feed")!)
            .resource as? UIViewController
        let tabCalendar: UIViewController! = Navigator.shared
            .response(for: URL(string: "/clendar")!)
            .resource as? UIViewController
        let tabMine: UIViewController! = Navigator.shared
            .response(for: URL(string: "/mine")!)
            .resource as? UIViewController

        let rootViewController = UITabBarController()
        rootViewController.identifier = "/root"
        rootViewController.viewControllers = [tabFeed, tabCalendar, tabMine]
        tabProvider.tabbarController = rootViewController
        UIApplication.shared.keyWindow?.rootViewController = rootViewController
    }

    override func tearDown() {
        super.tearDown()

        Navigator.shared.deregisterMiddleware("")
        Navigator.shared.deregisterMiddleware("^/chat(/.*)?")

        Navigator.shared.deregisterRoute("/clendar")
        Navigator.shared.deregisterRoute("/feed")
        Navigator.shared.deregisterRoute("/mine")

        Navigator.shared.deregisterRoute("/chat")
        Navigator.shared.deregisterRoute("/chat/setting")
        Navigator.shared.deregisterRoute("/chat/setting/present")
        Navigator.shared.deregisterRoute("^http(s)?\\://.*")
        Navigator.shared.deregisterRoute("/async")
        Navigator.shared.deregisterRoute(TestOpenBody.pattern)
        Navigator.shared.deregisterRoute("/plainPattern")
        Navigator.shared.deregisterRoute("/testCacheHandler")
    }

    func test_change_shared_navigator() {
        let old_navigator = Navigator.shared
        let new_navigator = Navigator.resetSharedNavigator()
        XCTAssert(new_navigator === Navigator.shared)
        XCTAssert(old_navigator !== new_navigator)
    }

    func testCanOpen() {
        var contains = Navigator.shared.contains(URL(string: "/clendar")!)
        XCTAssert(contains)

        contains = Navigator.shared.contains(URL(string: "/clendar/none")!)
        XCTAssert(!contains)
    }

    func testOpen() {
        let response = Navigator.shared.response(for: URL(string: "http://baidu.com")!)
        XCTAssert((response.resource as? UIViewController)?.title == "web")
    }

    func testOpenComplicatedURL() {
        let expectation = XCTestExpectation(description: "Present view controller")
        let url = "/chat/setting/present?openType=push&animated=false"
        Navigator.shared.push(URL(string: "/chat")!, from: self.topMost(), animated: false) { (_, _) in
            Navigator.shared.push(URL(string: "/chat/setting")!, from: self.topMost(), animated: false) { (_, _) in
                Navigator.shared.open(URL(string: url)!, from: self.topMost()) { (_, _) in
                    let vc = self.topMost()
                    XCTAssert(vc.identifier == "/chat/setting/present")
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 3)
    }

    func testPresent() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        let expectation = XCTestExpectation(description: "Present view controller")
        Navigator.shared.present(URL(string: "/chat/setting/present")!, from: nvc, animated: false) { (_, _) in
            let vc = UIViewController.topMost(of: nvc, checkSupport: false)

            XCTAssert(
                vc?.identifier == "/chat/setting/present" &&
                    vc?.navigationController == nil
            )

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }
    
    func testSwitchTab() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        Navigator.shared.switchTab(URL(string: "//clendar")!,
                                   from: nvc,
                                   animated: true) {
            XCTAssert(true)
        }
    }
    
    func testPresentBody() {
        let body = TestOpenBody()
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        Navigator.shared.present(body: body,
                                 naviParams: nil,
                                 context: [:],
                                 wrap: nil,
                                 from: nvc,
                                 prepare: nil,
                                 animated: true) { req, res in
            XCTAssertNil(res.error?.current)
        }
    }
    
    func testPresentWithController() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        Navigator.shared.present(UIViewController(), from: nvc)
    }

    func testPresentWithWrap() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        let expectation = XCTestExpectation(description: "Present view controller with wrap")
        let url = URL(string: "/chat/setting/present")!
        Navigator.shared.present(url, wrap: UINavigationController.self, from: nvc, prepare: nil, animated: false) { (_, _) in
            let vc = UIViewController.topMost(of: nvc, checkSupport: false)

            XCTAssert(
                vc?.identifier == "/chat/setting/present" &&
                vc?.navigationController != nil
            )

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }
    
    func testPresentWithError() {
        let url = URL(string: "/chat/setting/present")!
        let from = TestPresentFrom()
        Navigator.shared.present(url, from: from, animated: false) { req, res in
            if let error = res.error?.stack.last as? RouterError {
                XCTAssert(error.code == RouterError.cannotPresent.code)
                XCTAssertNotNil(res.error?.current.localizedDescription)
            }
        }
    }
    
    func testShowDetailWithBody() {
        let body = TestOpenBody()
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        Navigator.shared.showDetail(body: body,
                                    naviParams: nil,
                                    context: [:],
                                    wrap: nil,
                                    from: nvc) { req, res in
            XCTAssertNil(res.error?.current)
        }
    }
    
    func testShowDetailWithError() {
        let url = URL(string: "/chat/setting/present")!
        let from = TestPresentFrom()
        Navigator.shared.showDetail(url, context: [:], from: from) { req, res in
            if let error = res.error?.stack.last as? RouterError {
                XCTAssert(error.code == RouterError.cannotShowDetail.code)
            }
        }
    
    }
    
    func testPushWithError() {
        let url = URL(string: "/chat/setting/present")!
        let vc = UIViewController()
        Navigator.shared.push(url, from: vc, animated: true) { req, res in
            if let error = res.error?.stack.last as? RouterError {
                XCTAssert(error.code == RouterError.cannotPush.code)
            }
        }
    }

    func testPush() {
        let expectation = XCTestExpectation(description: "Push view controller")
        Navigator.shared.push(URL(string: "/chat")!, from: self.topMost(), animated: false) { (_, _) in
            let vc = self.topMost()
            XCTAssert(
                vc.identifier == "/chat" &&
                vc.navigationController != nil &&
                vc.navigationController?.viewControllers.count == 2
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }
    
    func testPushContolerr() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        let contoller = UIViewController()
        Navigator.shared.push(contoller, from: nvc)
    }

    func testPushButPop() {
        let expectation = XCTestExpectation(description: "Push view controller but pop indeed")
        Navigator.shared.push(URL(string: "/chat")!, from: self.topMost(), animated: false) { (_, _) in
            Navigator.shared.push(URL(string: "/chat/setting")!, from: self.topMost(), animated: false) { (_, _) in
                Navigator.shared.push(URL(string: "/chat")!, from: self.topMost(), animated: false) { (_, _) in
                    let vc = self.topMost()
                    XCTAssert(
                        vc.identifier == "/chat" &&
                        vc.navigationController != nil &&
                        vc.navigationController?.viewControllers.count == 2
                    )
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 3)
    }

    func testPresentAsync() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        let expectation = XCTestExpectation(description: "Present async controller")
        Navigator.shared.present(URL(string: "/async")!, from: nvc, animated: false) { (_, _) in
            let vc = UIViewController.topMost(of: nvc, checkSupport: false)

            XCTAssert(
                vc?.identifier == "/async"
            )

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }

    func testPushAsync() {
        let expectation = XCTestExpectation(description: "Push async controller")
        Navigator.shared.push(URL(string: "/async")!, from: self.topMost(), animated: false) { (_, _) in
            let vc = self.topMost()
            XCTAssert(
                vc.identifier == "/async"
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }

    func testContextParams() {
        let nvc = UIApplication.shared.keyWindow?.rootViewController!
        let expectation1 = XCTestExpectation(description: "test push context params")
        let expectation2 = XCTestExpectation(description: "test present context params")
        let expectation3 = XCTestExpectation(description: "test showDetail context params")
        guard let from = UIViewController.topMost(of: nvc, checkSupport: false) else { return }
        Navigator.shared.push(URL(string: "/chat")!, from: from) { (req, _) in
            XCTAssert(req.context.from()?.fromViewController === from)
            XCTAssert(req.context.openType() == OpenType.push)
            expectation1.fulfill()
        }

        Navigator.shared.present(URL(string: "/chat")!, from: from) { (req, _) in
            XCTAssert(req.context.from()?.fromViewController === from)
            XCTAssert(req.context.openType() == OpenType.present)
            expectation2.fulfill()
        }

        Navigator.shared.showDetail(URL(string: "/chat")!, from: from) { (req, _) in
            XCTAssert(req.context.from()?.fromViewController === from)
            XCTAssert(req.context.openType() == OpenType.showDetail)
            expectation3.fulfill()
        }

        wait(for: [expectation1, expectation2, expectation3], timeout: 3)
    }

    func testSupportNavigation() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        let vc = UIViewController.topMost(of: nvc, checkSupport: false)
        vc?.supportNavigator = false

        let parent = UIViewController.topMost(of: nvc, checkSupport: true)
        XCTAssert(vc?.parent == parent)

        vc?.supportNavigator = true
    }

    func testOpenType() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        let expectation1 = XCTestExpectation(description: "test custom open type")
        let expectation2 = XCTestExpectation(description: "test default open type")
        let expectation3 = XCTestExpectation(description: "test default open type")
        let expectation4 = XCTestExpectation(description: "test default open type")

        Navigator.shared.open(URL(string: "/chat")!, from: nvc) { (req, _) in
            XCTAssert(req.context.openType() == OpenType.showDetail)
            expectation1.fulfill()
        }

        Navigator.shared.open(URL(string: "/feed?openType=showDetail")!, from: nvc) { (req, _) in
            XCTAssert(req.context.openType() == OpenType.showDetail)
            expectation2.fulfill()
        }

        Navigator.shared.open(URL(string: "/feed")!, from: nvc) { (req, _) in
            XCTAssert(req.context.openType() == OpenType.push)
            expectation3.fulfill()
        }

        expectation4.fulfill()
        // useDefaultOpenType没有人用，先忽略这个feature。有需求时再考虑重新实现
        // Navigator.shared.open(URL(string: "/feed")!, from: nvc, useDefaultOpenType: false) { (req, _) in
        //     XCTAssert(req.context.openType() == OpenType.none)
        //     expectation4.fulfill()
        // }

        wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 3)
    }
    
    func testOpenWithBody() {
        Navigator.shared.open(body: TestOpenBody(), naviParams: nil, context: [:], from: topMost(), useDefaultOpenType: true) { req, res in
            XCTAssertNil(res.error?.current)
        }

    }
    
    func testShowDetailsWithBody() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        Navigator.shared.showDetail(body: TestOpenBody(),
                                    naviParams: nil,
                                    context: [:],
                                    wrap: nil,
                                    from: nvc) { req, res in
            XCTAssertNil(res.error?.current)
        }
        let vc = UIViewController()
        Navigator.shared.showDetail(vc, wrap: nil, from: nvc) {
            XCTAssert(true)
        }
    }

    private func topMost() -> UIViewController {
        let currentWindows = UIApplication.shared.windows
        var rootViewController: UIViewController?
        for window in currentWindows {
            if let windowRootViewController = window.rootViewController {
                rootViewController = windowRootViewController
                break
            }
        }
        return UIViewController.topMost(of: rootViewController, checkSupport: false) ?? UIViewController()
    }
    func testPop() {
        let nvc = UIApplication.shared.keyWindow!.rootViewController!
        Navigator.shared.open(URL(string: "/feed")!, from: nvc) { (req, res) in
            Navigator.shared.pop(from: nvc, animated: true) {
                XCTAssert(true)
            }
        }
    }
}
