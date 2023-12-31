//
//  BDTestPreloadPerformance.swift
//  DocsTests
//
//  Created by huahuahu on 2019/1/25.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import XCTest
@testable import SpaceKit
@testable import Docs

class BDTestPreloadPerformance: BDTestBase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func xtestPreloadPerformance() {
        var editorCostTimeMap = [String: TimeInterval]()
        var editorStartTimeMap = [String: TimeInterval]()
        let preloadMaxCount = 2
        var preloadStartCount = 0
        var preloadOkCount = 0
        expectation(forNotification: NSNotification.Name.PreloadTest.preloadStart, object: nil) { (notify) -> Bool in
            let editorId = notify.userInfo![Notification.DocsKey.editorIdentifer] as? String
            editorStartTimeMap[editorId!] = Date.timeIntervalSinceReferenceDate
            preloadStartCount += 1
            DocsLogger.info("\(editorId!) start preload")
            return preloadStartCount >= preloadMaxCount
        }
        expectation(forNotification: NSNotification.Name.PreloadTest.preloadok, object: nil) { (notify) -> Bool in
            let editorId = notify.userInfo![Notification.DocsKey.editorIdentifer] as? String
            editorCostTimeMap[editorId!] = Date.timeIntervalSinceReferenceDate - editorStartTimeMap[editorId!]!
            preloadOkCount += 1
            DocsLogger.info("\(editorId!) preload success")
            return preloadOkCount >= preloadMaxCount
        }

        waitForExpectations(timeout: 30) { (error) in
            if let error = error {
                DocsLogger.info("error! \(error)")
            } else {
                DocsLogger.info("test preload success", extraInfo: editorCostTimeMap, error: nil, component: nil)
            }
        }
    }
}
