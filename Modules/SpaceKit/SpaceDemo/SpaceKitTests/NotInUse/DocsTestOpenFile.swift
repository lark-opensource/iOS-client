//
//  DocsTests.swift
//  DocsTests
//
//  Created by huahuahu on 2018/9/20.
//  Copyright © 2018 Bytedance. All rights reserved.
//

// 测试文档打开的速度
// swiftlint:disable all

import XCTest
@testable import DocsSDK
@testable import DocsDev

class DocsTestOpenFile: BDTestBase {
    
    let bigUrl = "https://docs.bytedance.net/doc/n35rLQImUBgZhLVO6CX5Db"
    let middleUrl = "https://docs.bytedance.net/doc/gSFQzwT707BNFPytWvIIVh"
    let smallUrl = "https://docs.bytedance.net/doc/1pnX7XXufUokcg3w4uV2Vh"
    override func setUp() {
        DocsLogger.info("called \(#function)")
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        DocsLogger.info("called \(#function)")
        super.tearDown()
    }
    
    func xtestOpenFilePreload() {
        // This is an example of a performance test case.
        DocsLogger.info("called \(#function)")
        self.expectation(forNotification: NSNotification.Name.PreloadTest.preloadok, object: nil) { (_) -> Bool in
            return true
        }
        
        self.waitForExpectations(timeout: 60) { (error) in
            if let error = error {
                DocsLogger.info("timeout \(error)")
            } else {
                DocsLogger.info("preload ok")
            }
        }
        delay(3)
        let iterTimes = 11
        openFileWithPreload(url: middleUrl, iterTime: iterTimes)
    }
    
    /// 测试某次打开文档
    // 必须预加载打开
    // pull_data 的数据必须来自本地
    // 统计 createUI/ pullJS/ pullData/ renderDoc 四个阶段
    func openFileWithPreload(url: String, iterTime: Int) {
        guard let navigation = nav as? UINavigationController else {
            assertionFailure()
            return
        }
//        var totalCreateUI: Double = 0 // createUI 阶段耗时
//        var totalpullJS: Double = 0 // pullJS（render函数起始，到） 阶段耗时
//        var totalPullDataJS: Double = 0 // pull_data JS 统计的数据
//        var totalPullDataNative: Double = 0 // pull_data native 的统计
//        var totalRenderJS: Double = 0 // render_doc JS 统计的数据
//        var totalRenderNative: Double = 0 // render_doc  native 统计的数据
//        var totalNative: Double = 0 // 打开文档总体的数据，native 统计
        var allrecords = [OpenFileTimeRecord]()
        
        for iter in 0 ..< iterTime {
            let vc = sdk?.open(url)
            DocsLogger.info("start test open time \(iter)")
            nav?.push(vc!, false, false)
            DocsLogger.info("start push \(url)")
            var pulldataStartDate: Date!
            var pullDataEndDate: Date!
            var renderStartDate: Date!
            var renderEndDate: Date!
            var record = OpenFileTimeRecord.empty
            self.waitForNotification(Notification.Name.JSLog.pullStart, handler: { (notify) -> Bool in
                guard let userInfo = notify.userInfo as? [String: Any] else {
                    XCTAssert(false, "end without useInfo")
                    return false
                }
                pulldataStartDate = userInfo["date"] as? Date
                return true
            }, timeOut: 20)

            self.waitForNotification(Notification.Name.JSLog.pullEnd, handler: { (notify) -> Bool in
                guard let userInfo = notify.userInfo as? [String: Any] else {
                    XCTAssert(false, "end without useInfo")
                    return false
                }
                pullDataEndDate = userInfo["date"] as? Date
                return true
            }, timeOut: 20)
            
            // pull_data，必须来源于本地
            self.expectation(forNotification: NSNotification.Name.OpenFileRecord.StageEnd, object: nil) { (notify) -> Bool in
                let userInfo = notify.userInfo!
                let eventName = userInfo["eventName"] as? String
                XCTAssertEqual(eventName, "dev_performance_stage")
                let stage = userInfo["stage"] as? String
                if stage == OpenFileRecord.Stage.pullData.rawValue {
                    let from = userInfo["clientvar_from"] as? String
                    XCTAssertEqual(from, "CACHE")
                    return true
                } else {
                    return false
                }
            }

            self.waitForNotification(Notification.Name.JSLog.renderStart, handler: { (notify) -> Bool in
                guard let userInfo = notify.userInfo as? [String: Any] else {
                    XCTAssert(false, "end without useInfo")
                    return false
                }
                renderStartDate = userInfo["date"] as? Date
                return true

            }, timeOut: 20)
            self.waitForNotification(Notification.Name.JSLog.renderEnd, handler: { (notify) -> Bool in
                guard let userInfo = notify.userInfo as? [String: Any] else {
                    XCTAssert(false, "end without useInfo")
                    return false
                }
                renderEndDate = userInfo["date"] as? Date
                return true
            }, timeOut: 20)
            
            self.expectation(forNotification: NSNotification.Name.OpenFileRecord.OpenEnd, object: nil) { (notify) -> Bool in
                guard let userInfo = notify.userInfo as? [String: Any] else {
                    XCTAssert(false, "end without useInfo")
                    return false
                }
                //必须预加载打开
                XCTAssertEqual(OpenFileRecord.OpenType.preload.rawValue, userInfo["docs_open_type"] as? String,  "\(iter) open not preload")
                //必须打开成功
                XCTAssertEqual(0, userInfo["docs_result_code"] as? Int)
                XCTAssertEqual("other", userInfo["docs_result_key"] as? String)
                XCTAssertEqual("render_doc", userInfo["stage"] as? String)
                guard let costTime = userInfo["cost_time"] as? Double,
                    let pullDataTime = userInfo["pull_data_costtime"] as? Double,
                    let createUI = userInfo["create_ui_costtime"] as? Double,
                    let getNativeData = userInfo["local_get_data"] as? Double,
                    let pullJsTime = userInfo["pull_js_costtime"] as? Double,
                    let renderDocTime = userInfo["render_doc_costtime"] as? Double else {
                        XCTAssert(false, "no cost time")
                        return false
                }
//                DocsLogger.info("open succ,), \(pullDataTime), \(renderDocTime), \(costTime)")
                record.createUI = createUI
                record.renderToPullData = pullJsTime
                record.pullDataTimeByNative = pullDataTime
                record.renderTimeByNative = renderDocTime
                record.totalTime = costTime
                record.getLocalData = getNativeData
                return true
            }

            self.waitForExpectations(timeout: 20) { (error) in
                if let error = error {
                    DocsLogger.error("wait for open finish \(iter), ) time out error is \(error)")
                } else {
                    DocsLogger.info("wait for open \(iter) succ")
                }
            }
            let pullTime = pullDataEndDate.timeIntervalSince(pulldataStartDate) * 1000
            let renderTIme = renderEndDate.timeIntervalSince(renderStartDate) * 1000
            DocsLogger.info("pull \(pullTime), renderTime: \(renderTIme)")
            record.PullDataTimeByJS = pullTime
            record.renderTimeByJS = renderTIme
            allrecords.append(record)

            delay(10)
            navigation.popToRootViewController(animated: true)
            DocsLogger.info("end bigUrl")
            delay(2)
        }
        let avarageRecord = allrecords.reduce(OpenFileTimeRecord.zero, +) / iterTime
        DocsLogger.info("average time is \(avarageRecord.oneline)", extraInfo: nil, error: nil, component: nil)
        allrecords.forEach { (record) in
            DocsLogger.info(record.oneline)
        }
    }
    
    func waitForNotification(_ notification: NSNotification.Name, handler: XCTNSNotificationExpectation.Handler? = nil, timeOut: Double = 10)  {
        DocsLogger.info("wait for \(notification) start")
        self.expectation(forNotification: notification, object: nil, handler: handler)
    }
}

extension DocsTestOpenFile {
    
    struct OpenFileTimeRecord {
        var createUI: Double!  // createUI 阶段耗时
        var getLocalData: Double!
        var renderToPullData: Double!  // （render函数起始，到） 阶段耗时
        var PullDataTimeByJS: Double!  // pull_data JS 统计的数据
        var pullDataTimeByNative: Double! // pull_data native 的统计
        var renderTimeByJS: Double! // render_doc JS 统计的数据
        var renderTimeByNative: Double!  // render_doc  native 统计的数据
        var totalTime: Double! // 打开文档总体的数据，native 统计

        static public func + (left: OpenFileTimeRecord, right: OpenFileTimeRecord) -> OpenFileTimeRecord {
                var record = OpenFileTimeRecord.empty
                record.createUI = left.createUI + right.createUI
                record.getLocalData = left.getLocalData + right.getLocalData
                record.renderToPullData = left.renderToPullData + right.renderToPullData
                record.PullDataTimeByJS = left.PullDataTimeByJS + right.PullDataTimeByJS
                record.pullDataTimeByNative = left.pullDataTimeByNative + right.pullDataTimeByNative
                record.renderTimeByJS = left.renderTimeByJS + right.renderTimeByJS
                record.renderTimeByNative = left.renderTimeByNative + right.renderTimeByNative
                record.totalTime = left.totalTime + right.totalTime
                return record
        }
        
        static public func / (left: OpenFileTimeRecord, right: Int) -> OpenFileTimeRecord {
            var record = OpenFileTimeRecord.empty
            record.createUI = left.createUI / Double(right)
            record.getLocalData = left.getLocalData / Double(right)
            record.renderToPullData = left.renderToPullData / Double(right)
            record.PullDataTimeByJS = left.PullDataTimeByJS / Double(right)
            record.pullDataTimeByNative = left.pullDataTimeByNative / Double(right)
            record.renderTimeByJS = left.renderTimeByJS / Double(right)
            record.renderTimeByNative = left.renderTimeByNative / Double(right)
            record.totalTime = left.totalTime / Double(right)
            return record
        }
        
        static var empty = OpenFileTimeRecord.init()
        static var zero = OpenFileTimeRecord.init(createUI: 0, getLocalData: 0, renderToPullData: 0, PullDataTimeByJS: 0, pullDataTimeByNative: 0, renderTimeByJS: 0, renderTimeByNative: 0, totalTime: 0)
        
        var oneline: String {
            return "(createui, renderToPullData, getdataLocal, pullData, render, total) is (\(createUI!.asNumber) \(renderToPullData!.asNumber) \(getLocalData!.asNumber) \(pullDataTimeByNative!.asNumber) \(renderTimeByNative!.asNumber) \(totalTime!.asNumber))"
        }
        
        var onelineWithJSTime: String {
            return "(createui, renderToPullData, pullData, pullDataJS, render, renderJS, total) is (\(createUI!.asNumber) \(renderToPullData!.asNumber) \(pullDataTimeByNative!.asNumber) \(PullDataTimeByJS!.asNumber) \(renderTimeByNative!.asNumber) \(renderTimeByJS!.asNumber) \(totalTime!.asNumber))"
        }
    }
}

extension Double {
    var asNumber:String {
        if self >= 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            formatter.percentSymbol = ""
            formatter.maximumFractionDigits = 2
            return "\(formatter.string(from: NSNumber(value: self)) ?? "")"
        }
        return ""
    }
}
