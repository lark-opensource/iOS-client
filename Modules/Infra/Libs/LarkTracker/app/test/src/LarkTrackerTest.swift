//
//  RepleacemeSpec.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import Foundation
import XCTest
@testable import LarkTracker
@testable import RangersAppLog
@testable import LarkAppLog

class LarkTrackerTest: XCTestCase {

    var trackService: TrackService?

    override func setUp() {
        super.setUp()
        assert(LarkAppLog.appName == "LarkTrackerDev")
        assert(TrackService.appFullVersion == "1.0")
        TrackService.appID = "1161"
        TrackService.channel = "appstore"
        LarkAppLog.appID = "1161"
        LarkAppLog.channel = "appstore"
        self.trackService = TrackService(traceUserInterfaceIdiom: true, isStaging: false, isRelease: true)
    }

    override func tearDown() {
        super.tearDown()
    }

//    func testTrack() {
//        let completedExpectation = expectation(description: "track")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            guard let trackService = self.trackService else { return }
//            let track = MockBDAutoTrack()
//            trackService.tracker = track
//            trackService.track(event: "1")
//            trackService.track(event: "1", category: "1")
//            trackService.track(event: "1", category: "1", params: ["1": "1"])
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                XCTAssert(track.count == 3)
//                completedExpectation.fulfill()
//            }
//        }
//        waitForExpectations(timeout: 2, handler: nil)
//    }

    func testABTest() {
        guard let trackService = self.trackService else { return }
        trackService.setABSDKVersions(versions: "1.0")
        _ = trackService.abVersions()
        _ = trackService.allAbVersions()
        _ = trackService.allABTestConfigs()

        if let value = trackService.abTestValue(key: "123test", defaultValue: "123") as? String {
            assert(value == "123")
        } else {
            assertionFailure()
        }
        assert(!trackService.commonABExpParams(appId: "462391").isEmpty)
    }

    func testConfigChange() {
        guard let trackService = self.trackService else { return }
        LarkAppLog.shared.setupURLConfig(.init())
        LarkAppLog.shared.setupTeaEndpointsURL([])
        LarkAppLog.shared.updateURLConfig(.init(ttActiveURL: ["1"], ttDeviceURL: ["2"], commonHost: ["3"]))
        trackService.config(chatterID: "1", tenantID: "1", deviceID: "1", installID: "1")
        let completedExpectation = expectation(description: "track")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            assert(LarkAppLog.shared.urlConfig.ttActiveURL == ["1"])
            assert(LarkAppLog.shared.urlConfig.ttDeviceURL == ["2"])
            assert(LarkAppLog.shared.urlConfig.commonHost == ["3"])
            assert(LarkAppLog.shared.vendorType == .private)


            if let customHeaderCache = LarkAppLog.globalStore.dictionary(
                forKey: StoreKey.tracerManagerCustomHeaderKey
            ) {
                assert(customHeaderCache["device_id"] == "1")
                assert(customHeaderCache["install_id"] == "1")
                assert(customHeaderCache["tenant_id"] == "943328860684d8e46a423561ba2eb75f5b78e854")
            } else {
                assertionFailure()
            }
            completedExpectation.fulfill()

        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSingleConfigChange() {
        guard let trackService = self.trackService else { return }
        LarkAppLog.shared.setupURLConfig(.init())
        LarkAppLog.shared.setupTeaEndpointsURL([])

        LarkAppLog.shared.updateTTActiveUri(["1"])
        LarkAppLog.shared.updateTTDeviceUri(["2"])
        LarkAppLog.shared.updateCommonHost(["3"])
        LarkAppLog.shared.updateTeaEndpointsURL(["4"])

        trackService.config(chatterID: "1", tenantID: "1", deviceID: "1", installID: "1")
        let completedExpectation = expectation(description: "track")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            assert(LarkAppLog.shared.urlConfig.ttActiveURL == ["1"])
            assert(LarkAppLog.shared.urlConfig.ttDeviceURL == ["2"])
            assert(LarkAppLog.shared.urlConfig.commonHost == ["3"])
            assert(LarkAppLog.shared.teaEndpointsURL == ["4"])
            assert(LarkAppLog.shared.vendorType == .private)

            if let customHeaderCache = LarkAppLog.globalStore.dictionary(
                forKey: StoreKey.tracerManagerCustomHeaderKey
            ) {
                assert(customHeaderCache["device_id"] == "1")
                assert(customHeaderCache["install_id"] == "1")
                assert(customHeaderCache["tenant_id"] == "943328860684d8e46a423561ba2eb75f5b78e854")
            } else {
                assertionFailure()
            }
            completedExpectation.fulfill()

        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testEbcrypto() {
        XCTAssertEqual(Encrypto.prefixToken(), "08a441")
        XCTAssertEqual(Encrypto.suffixToken(), "42b91e")
        XCTAssertEqual(Encrypto.encryptoId(""), "")
        XCTAssertEqual(Encrypto.encryptoId("ee"), "fbfae50420c4fd0ef4b534524e274b7f99338962")
    }

    func testDebug() {
        let item = ETTrackerDebugItem()
        assert(!item.isSwitchButtonOn)
        item.switchValueDidChange?(true)
        assert(item.isSwitchButtonOn)
        let item2 = ETTrackerDebugItem()
        assert(item2.isSwitchButtonOn)
        item.switchValueDidChange?(false)
        assert(!item.isSwitchButtonOn)
        assert(!item2.isSwitchButtonOn)
    }
}

class MockBDAutoTrack: BDAutoTrack {

    var count: Int = 0

    override init() {
        super.init()
    }

    override func eventV3(_ event: String, params: [AnyHashable: Any]?) -> Bool {
        count += 1
        return true
    }
}
