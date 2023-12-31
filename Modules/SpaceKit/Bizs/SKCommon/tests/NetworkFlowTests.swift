//
//  NetworkFlowTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/4/7.
//

import XCTest
import OHHTTPStubs
import SKFoundation
@testable import SKCommon
import SKInfra

class NetworkFlowTests: XCTestCase {
    var helper: NetworkFlowHelper!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        helper = NetworkFlowHelper(networkStauts: MockNetworkStatus(),
                                   cacheService: MockCacheServce())
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        AssertionConfigForTest.reset()

    }
    //第一次获取到的文件大小为0时，再次获取一个大于50M的文件
    func testCheckIfNeedToastWhenOfflineNeedToastWithSecondFileSizeRequest() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfo)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("getFileSizeOverLimit.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test fetch fileInfo size")
        helper.checkIfNeedToastWhenOffline(fileSize: 0, fileName: "xxx", objToken: "testtoken") { toastType in
            if case .manualOfflineFlowToast(_) = toastType {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }

            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }

    }
    //第一次获取到的文件大小为0时，再次获取一个小于50M的文件
    func testCheckIfNeedToastWhenOfflineNoToastWithSecondFileSizeRequest() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfo)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("getFileSizeBelowLimit.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test fetch fileInfo size")
        helper.checkIfNeedToastWhenOffline(fileSize: 0, fileName: "xxx", objToken: "testtoken") { toastType in
            if case .manualOfflineFlowToast(_) = toastType {
                XCTAssertTrue(false)
            } else {
                XCTAssertTrue(true)
            }

            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    //第一次获取到的文件size大于50M时
    func testCheckIfNeedToastWhenOfflineToastFirstFileSizeRequest() {
        let expect = expectation(description: "test fetch fileInfo size")
        helper.checkIfNeedToastWhenOffline(fileSize: 53428800, fileName: "xxx", objToken: "testtoken") { toastType in
            if case .manualOfflineFlowToast(_) = toastType {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }

            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    //第一次获取到的文件size小于50M时
    func testCheckIfNeedToastWhenOfflineNoToastFirstFileSizeRequest() {
        let expect = expectation(description: "test fetch fileInfo size")
        helper.checkIfNeedToastWhenOffline(fileSize: 20, fileName: "xxx", objToken: "testtoken") { toastType in
            if case .manualOfflineFlowToast(_) = toastType {
                XCTAssertTrue(false)
            } else {
                XCTAssertTrue(true)
            }

            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testProcessNoNeedJudgeToast() {
        var requestTaskCall = false
        var judgeToastCall = false
        helper.process(20, skipCheck: false, requestTask: {
            requestTaskCall = true
        }, judgeToast: {
            judgeToastCall = true
        })
        XCTAssertTrue(requestTaskCall)
        XCTAssertFalse(judgeToastCall)
    }

    func testProcessNeedJudgeToast() {
        var requestTaskCall = false
        var judgeToastCall = false
        helper.process(53428800, skipCheck: false, requestTask: {
            requestTaskCall = true
        }, judgeToast: {
            judgeToastCall = true
        })
        XCTAssertTrue(requestTaskCall)
        XCTAssertTrue(judgeToastCall)
    }
}

class MockNetworkStatus: SKNetStatusService {
    var accessType: NetworkType = .wwan4G
    var isReachable: Bool = true
    func addObserver(_ observer: AnyObject, _ block: @escaping NetStatusCallback) {
        // 空实现
    }
}

class MockCacheServce: DriveCacheServiceBase {
    func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile], completion: (() -> Void)?) {
        //
    }
    
    func canOpenOffline(token: String, dataVersion: String?, fileExtension: String?) -> Bool {
        return false
    }
    func isDriveFileExist(token: String, dataVersion: String?, fileExtension: String?) -> Bool {
        return false
    }
    func deleteAll(completion: (() -> Void)?) {
        // blank
    }
    func userDidLogout() {
        // logout
    }
}
