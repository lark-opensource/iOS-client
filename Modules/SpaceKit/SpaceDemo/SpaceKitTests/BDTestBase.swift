//
//  BDTestBase.swift
//  DocsTests
//
//  Created by huahuahu on 2018/9/26.
//  Copyright © 2018 Bytedance. All rights reserved.
//

import XCTest
@testable import SpaceKit
@testable import Docs

class BDTestBase: XCTestCase {

    var nav: NavigationProtocol!
    weak var appdelegate: AppDelegate!
    var sdk: DocsSDK!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        guard let nav1 = UIApplication.shared.keyWindow?.rootViewController as? NavigationProtocol,
        let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
//            fatalError()
            return
        }
        nav = nav1
        sdk = appdelegate.context.sdkMediator.docs
        DocsLogger.info("setup finish")

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func delay(_ seconds: Double, functionName: String = #function) {
        DocsLogger.info("start wait \(functionName)")
        let expectation = XCTestExpectation(description: "delay")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: (seconds + 3))
        DocsLogger.info("end wait \(functionName)")
    }

}
