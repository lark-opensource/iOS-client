//
//  MonitorTest.swift
//  LKCommonsTrackerDevEEUnitTest
//
//  Created by 李晨 on 2019/3/26.
//

import Foundation
import XCTest
import LKCommonsTracker

class TrackerTest: XCTestCase {

    override func setUp() {
        Tracker.unregisterAll(key: .tea)
        Tracker.unregisterAll(key: .slardar)
    }

    override func tearDown() {
    }

    func testTime() {
        let current = Tracker.currentTime()
        XCTAssert(current.duration == 0)

        Tracker.start(token: "token")
        sleep(2)
        let time = Tracker.end(token: "token")
        XCTAssert(time != nil)
        XCTAssert(time!.duration > 0)
    }

    func testEvent() {
        /// 测试 TeaEvent 创建
        let teaEvent = TeaEvent("tea", category: "category", params: ["value": 1], md5AllowList: [])
        XCTAssert(teaEvent.name == "tea")
        XCTAssert(teaEvent.params.count == 1 &&
            teaEvent.params["value"] as! Int == 1)
        XCTAssert(teaEvent.category! == "category")

        let message = TeaMessageSceneModel(messageId: "messageId",
                                           cid: "cid",
                                           messageType: "messageType")
        let chat = TeaChatSceneModel(chatId: "chatId",
                                     chatType: "chatType",
                                     chatTypeDetail: "chatTypeDetail",
                                     memberType: "memberType",
                                     isInnerGroup: "true",
                                     isPublicGroup: "false")
        let topic = TeaTopicSceneModel(threadId: "threadId")
        let circle = TeaCircleSceneModel(circleId: "circleId",
                                         categoryId: "categoryId",
                                         postId: "postId",
                                         cid: "cid")
        let doc = TeaDocSceneModel(fileId: "fileId",
                                   fileType: "fileType")
        let cal = TeaCalSceneModel(viewType: "viewType")
        let calEvent = TeaCalEventSceneModel(eventId: "eventId",
                                             fileId: "fileId",
                                             fileType: "fileType",
                                             cardMessageType: "cardMessageType",
                                             conferenceId: "conferenceId")
        let bizSceneModels: [TeaBizSceneProtocol] = [message, chat, topic, circle, doc, cal, calEvent]
        let teaEvent1 = TeaEvent("tea", params: ["value": 1], md5AllowList: ["message_id"], bizSceneModels: bizSceneModels)
        XCTAssert(teaEvent1.name == "tea")
        XCTAssert(teaEvent1.params.count == 20 &&
            teaEvent.params["value"] as! Int == 1)

        var params1: [AnyHashable: Any] = [:]
        params1["file_id_1"] = ["a", "b"]
        params1["file_id_2"] = ["a", "none"]
        params1["file_id_3"] = ["none", "none"]
        params1["file_id_4"] = "none"

        var md5AllowList1: [AnyHashable]
        md5AllowList1 = ["file_id_1", "file_id_2", "file_id_3", "file_id_4"]

        let teaEvent2 = TeaEvent("tea", params: params1, md5AllowList: md5AllowList1)
        XCTAssert(teaEvent2.md5AllowList.count == 2)

        /// 测试 SlardEvent 创建
        let slardarEvent = SlardarEvent(name: "slardar", metric: ["value": 1], category: ["status": 0], extra: ["info": "xxx"])
        XCTAssert(slardarEvent.metric.count == 1 &&
            slardarEvent.metric["value"] as! Int == 1)
        XCTAssert(slardarEvent.category.count == 1 &&
            slardarEvent.category["status"] as! Int == 0)
        XCTAssert(slardarEvent.extra.count == 1 &&
            slardarEvent.extra["info"] as! String == "xxx")
    }

    func testMonitor() {
        let proxy = MonitorProxy()

        let event = SlardarCustomEvent(name: "name", params: [:])
        let event2 = TeaEvent("tea", category: "catgory", params: ["value": 1], md5AllowList: [])
        Tracker.post(event)
        Tracker.register(key: .tea, tracker: proxy)
        Tracker.post(event2)
        XCTAssert(proxy.count == 1)
    }

    func testTeaIntervalMonitor() {
        /// [TEA] 测试 新的 Monitor start/end API
        let proxy = MonitorProxy()
        Tracker.register(key: .tea, tracker: proxy)
        var evtCnt = proxy.count
        Tracker.start(token: "tokenTea")
        sleep(2)
        Tracker.end(token: "tokenTea", platform: .tea) { (_ duration: TimeInterval?) -> (Event) in
            XCTAssert(duration != nil)
            XCTAssert(duration! > 0)
            XCTAssert(Int(duration!) == 2)
            return TeaEvent("tea", category: "catgory", params: ["value": 1, "time": duration!], md5AllowList: [])
        }
        XCTAssert(proxy.count == evtCnt + 1)
        evtCnt = proxy.count

        /*
        /// 测试 Token 不匹配情况 测试会触发assertion
        /// 如果需要测试通过 需要把 LKMonitor+Extension中的 assert改为print即可
        Tracker.start(token: "tokenTeaA")
        sleep(2)
        Tracker.end(token: "tokenTeaB", platform: .tea) { (_ duration: TimeInterval?) -> (Event) in
            assert(duration == nil)
            return TeaEvent("tea", category: "catgory", params: ["value": 2, "duration": duration!])

        }
        assert(proxy.count == evtCnt)
         */
    }

    func testSlardarIntervalMonitor() {
        /// [Slardar] 测试 新的 Monitor start/end API
        let proxy = MonitorProxy()
        Tracker.register(key: .slardar, tracker: proxy)
        var evtCnt = proxy.count
        Tracker.start(token: "tokenSlardar")
        sleep(2)
        Tracker.end(token: "tokenSlardar", platform: .slardar) { (_ duration: TimeInterval?) -> (Event) in
            XCTAssert(duration != nil)
            XCTAssert(duration! > 0)
            XCTAssert(Int(duration!) == 2)
            return SlardarEvent(name: "slardar", metric: ["value": 1, "duration": duration!], category: ["status": 0], extra: ["info": "xxx"])
        }
        XCTAssert(proxy.count == evtCnt + 1)
        evtCnt = proxy.count

        /// 测试 Token 不匹配情况 测试会触发assertion
        /// 如果需要测试通过 需要把 LKMonitor+Extension中的 assert改为print即可
        /*
        Tracker.start(token: "tokenSlardarA")
        sleep(2)
        Tracker.end(token: "tokenSlardarB", platform: .slardar) { (_ duration: TimeInterval?) -> (Event) in
            assert(duration == nil)
            return SlardarEvent(name: "slardar", metric: ["value": 2, "time": duration!], category: ["status": 0], extra: ["info": "xxx"])
        }
        assert(proxy.count == evtCnt)
        */
    }

    func testTwoService() {
        let proxy = MonitorProxy()
        let proxy2 = MonitorProxy()
        Tracker.register(key: .tea, tracker: proxy)
        Tracker.register(key: .tea, tracker: proxy2)
        let event = TeaEvent("name", params: [:])
        Tracker.post(event)
        XCTAssert(proxy.count == 1)
        XCTAssert(proxy2.count == 1)
    }

    func testUnRegister() {
        let proxy = MonitorProxy()
        Tracker.register(key: .tea, tracker: proxy)
        let event = TeaEvent("name", params: [:])
        Tracker.post(event)
        XCTAssert(proxy.count == 1)
        Tracker.unregister(key: .tea, tracker: proxy)
        Tracker.post(event)
        XCTAssert(proxy.count == 1)
    }

    func testABTest() {
        let proxy = MonitorProxy()
        Tracker.register(key: .tea, tracker: proxy)
        XCTAssert((Tracker.aBTestTracker as? MonitorProxy) === proxy)
    }

    func testBoolToString() {
        XCTAssert(true.stringValue == "true")
        XCTAssert(false.stringValue == "false")
        XCTAssert(true.intValue == 1)
        XCTAssert(false.intValue == 0)
    }
}

class MonitorProxy: TrackerService, ABTestService {
    func postABEvent(_ event: Event) {
    }

    var count: Int = 0
    func post(event: Event) {
        count += 1
    }

    func addPullABTestConfigObserve(observer: Any, selector: Selector) {
    }

    func abVersions() -> String {
        return ""
    }

    func allAbVersions() -> String {
        return ""
    }

    func abTestValue(key: String, defaultValue: Any) -> Any? {
        return nil
    }

    func allABTestConfigs() -> [AnyHashable : Any] {
        return [:]
    }

    func setABSDKVersions(versions: String?) {
    }

    func commonABExpParams(appId: String) -> [AnyHashable : Any] {
        return [:]
    }

    func registerABExposureExperimentsObserve(observer: Any, selector: Selector) {
    }

    func registerFetchExperimentDataObserver(observer: Any, selector: Selector) {
    }

    func queryExposureExperiments() -> String? {
        return nil
    }

    func experimentValue(key: String, shouldExposure: Bool) -> Any? {
        return nil
    }

    func fetchAndSaveExperimentData(url: String, completionCallBack: @escaping (Error?, [AnyHashable : Any]?) -> Void) {
    }
}
