//
//  BDTestOpenDocStatistics.swift
//  DocsTests
//
//  Created by huahuahu on 2018/10/23.
//  Copyright © 2018 Bytedance. All rights reserved.
//

import XCTest
@testable import SpaceKit
@testable import Docs

class BDTestOpenDocStatistics: BDTestBase {
    let fileURL = "https://docs.bytedance.net/doc/n35rLQImUBgZhLVO6CX5Db"

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // 测试打开文档过程中，各个阶段及顺序
    // open -> pull_data start -> pull_data end -> render_doc start -> render_doc end
    func xtestOpenDocRecord() {
        delay(10)
        self.expectation(forNotification: Notification.Name.OpenFileRecord.OpenStart, object: nil) { (_) -> Bool in
            return true
        }
        let vc = sdk.open(fileURL)
        nav.push(vc, true, false)
        self.waitForExpectations(timeout: 20) { (error) in
            if let err = error {
                DocsLogger.info("wait for open start with error \(err)")
            } else {
                DocsLogger.info("did start open file")
            }
        }
        self.expectation(forNotification: Notification.Name.OpenFileRecord.StageStart, object: nil) { (notify) -> Bool in
            let userInfo = notify.userInfo!
            let eventName = userInfo["eventName"] as? String
            XCTAssertEqual(eventName, "dev_performance_stage")
            let stage = userInfo["stage"] as? String

            return stage == (OpenFileRecord.Stage.pullData.rawValue + "_start")
        }
        self.waitForExpectations(timeout: 20) { (error) in
            if let err = error {
                DocsLogger.info("wait for \(OpenFileRecord.Stage.pullData.rawValue)_start with error \(err)")
            } else {
                DocsLogger.info("did start \(OpenFileRecord.Stage.pullData.rawValue)")
            }
        }

        self.expectation(forNotification: Notification.Name.OpenFileRecord.StageEnd, object: nil) { (notify) -> Bool in
            let userInfo = notify.userInfo!
            let eventName = userInfo["eventName"] as? String
            XCTAssertEqual(eventName, "dev_performance_stage")
            let stage = userInfo["stage"] as? String
            return stage == OpenFileRecord.Stage.pullData.rawValue
        }
        self.waitForExpectations(timeout: 20) { (error) in
            if let err = error {
                DocsLogger.info("wait for \(OpenFileRecord.Stage.pullData.rawValue) end with error \(err)")
            } else {
                DocsLogger.info("did end \(OpenFileRecord.Stage.pullData.rawValue)")
            }
        }

        self.expectation(forNotification: Notification.Name.OpenFileRecord.StageStart, object: nil) { (notify) -> Bool in
            let userInfo = notify.userInfo!
            let eventName = userInfo["eventName"] as? String
            XCTAssertEqual(eventName, "dev_performance_stage")
            let stage = userInfo["stage"] as? String
            return stage == OpenFileRecord.Stage.renderDoc.rawValue + "_start"
        }
        self.waitForExpectations(timeout: 20) { (error) in
            if let err = error {
                DocsLogger.info("wait for \(OpenFileRecord.Stage.renderDoc.rawValue) start with error \(err)")
            } else {
                DocsLogger.info("did start \(OpenFileRecord.Stage.renderDoc.rawValue)")
            }
        }

        self.expectation(forNotification: Notification.Name.OpenFileRecord.StageEnd, object: nil) { (notify) -> Bool in
            let userInfo = notify.userInfo!
            let eventName = userInfo["eventName"] as? String
            XCTAssertEqual(eventName, "dev_performance_stage")
            let stage = userInfo["stage"] as? String
            return stage == OpenFileRecord.Stage.renderDoc.rawValue
        }
        self.expectation(forNotification: Notification.Name.OpenFileRecord.OpenEnd, object: nil) { (notify) -> Bool in
            let userInfo = notify.userInfo!
            XCTAssertEqual(userInfo[OpenFileRecord.ReportKey.resultKey.rawValue] as? String, "other")
            XCTAssertEqual(userInfo[OpenFileRecord.ReportKey.resultCode.rawValue] as? Int, 0)
            DocsLogger.info("did end open ")
            return true
        }

        self.waitForExpectations(timeout: 20) { (error) in
            if let err = error {
                DocsLogger.info("wait for \(OpenFileRecord.Stage.renderDoc.rawValue) end with error \(err)")
            } else {
                DocsLogger.info("did end \(OpenFileRecord.Stage.renderDoc.rawValue)")
            }
        }
    }

    //测试打开文档过程中，H5 向后台上报的信息
    func xtestOpenDocReportServer() {
        delay(10)
        var stages = ["scm", "dev_performance_render_createDom", "dev_performance_render_createHtml", "dev_performance_render_initEditor"]
        self.expectation(forNotification: Notification.Name.OpenFileRecord.EventHappen, object: nil) { (notify) -> Bool in
            let userInfo = notify.userInfo!
            guard let stage = userInfo["eventName"] as? String else {
                XCTAssertFalse(true, "can not get event name")
                return false
            }
            XCTAssert(stages.contains(stage), "\(stage) not in stages")
            stages.remove(at: stages.firstIndex(of: stage)!)
            DocsLogger.info("stage \(stage) happen")
            return stages.isEmpty
        }
        let vc = sdk.open(fileURL)
        nav.push(vc, true, false)
        self.waitForExpectations(timeout: 20) { (error) in
            XCTAssertNil(error)
        }
    }
}
