//
//  OpenPluginDriveTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/3.
//

import XCTest
import LarkOpenAPIModel
import TTMicroApp
import TTMicroApp
@testable import OPPlugin
@testable import LarkSetting
import OPUnitTestFoundation
@available(iOS 13.0, *)
final class OpenPluginDriveTests: XCTestCase {
    
    private let testUtils = OpenPluginGadgetTestUtils()
    
    private var originSetting: [String: Any]?
    
    override func setUpWithError() throws {
        // 每次都保存Setting的状态，并在tearDown时还原
        originSetting = try SettingManager.shared.setting(with: Setting.key)
    }
    
    override func tearDownWithError() throws {
        if let originSetting = originSetting, let originString = originSetting.toJsonString() {
            SettingStorage.updateSettingValue(originString, with: SettingManager.currentChatterID(), and: Setting.key)
        }
        originSetting = nil
    }
    
    func test_uploadFileToCloudWithRandomTempFile() throws {
        
        enableAPI()
        
        /// 准备数据
        let randomFile = FileObject.generateRandomTTFile(type: .temp, fileExtension: "dat")
        // 生成一个要上传的文件
        let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: testUtils.context.apiTrace, tag: "UnitTest")
        /// 写入数据
        try FileSystemCompatible.writeSystemData(Data(), to: randomFile, context: fsContext)
        
        let params = [
            "filePath" : randomFile.rawValue,
            "mountPoint" : "testMountPoint",
            "mountNodePoint" : "testMountNodePoint",
            "taskID" : "testTaskID",
        ]
        
        let exp = XCTestExpectation(description: "async")
        
        testUtils.asyncCall(apiName: APIName.uploadFileToCloud.rawValue, params: params) { response in
            switch response.toTestReponse() {
            case .success(let data):
                XCTAssertNotNil(data, "data should not be nil")
            case .failure(let error):
                XCTAssert(false, "test_uploadFileToCloudWithRandomTempFile failed, \(error)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 2)
    }
    
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}

// MARK: - Test Params
@available(iOS 13.0, *)
extension OpenPluginDriveTests {
    func test_uploadFileToCloudWithEmptyMountPoint() {
        enableAPI()
        
        let params = [
            "filePath" : "tt:file//temp/xxx",
            "mountPoint" : "",
            "mountNodePoint" : "testMountNodePoint",
            "taskID" : "testTaskID",
        ]
        
        let exp = XCTestExpectation(description: "async")
        
        testUtils.asyncCall(apiName: APIName.uploadFileToCloud.rawValue, params: params) { response in
            switch response.toTestReponse() {
            case .success(_):
                XCTAssert(false)
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue, OpenAPICommonErrno.invalidParam(.invalidParam(param: "")).rawValue)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 2)
    }
}

// MARK: - Test Settings
@available(iOS 13.0, *)
extension OpenPluginDriveTests {
    
    // MARK: 直接验证Setting本身
    func test_settingDefaultTrueAppIDFalse() throws {
        
        // 修改指定值
        SettingStorage.updateSettingValue(Setting.mockValueDefaultTrueTestAppIDFalse, with: SettingManager.currentChatterID(), and: Setting.key)
        
        // 直接读Setting, 判断是否通过
        let setting = try SettingManager.shared.setting(with: Setting.key)
        
        func testValue(settingValue: [AnyHashable: Any]) {
            if let defaultValue = settingValue["default"] as? Bool {
                XCTAssertTrue(defaultValue)
            } else {
                XCTAssert(false, "setting mock failed!")
            }
            if let appIDValue = settingValue["testAppID"] as? Bool {
                XCTAssertFalse(appIDValue)
            } else {
                XCTAssert(false, "setting mock failed!")
            }
        }
        
        if let downloadValue = setting[APIName.downloadFileFromCloud.rawValue] as? [AnyHashable: Any] {
            testValue(settingValue: downloadValue)
        } else {
            XCTAssert(false, "setting mock failed!")
        }
        
        if let uploadValue = setting[APIName.uploadFileToCloud.rawValue] as? [AnyHashable: Any] {
            testValue(settingValue: uploadValue)
        } else {
            XCTAssert(false, "setting mock failed!")
        }
        
        if let openValue = setting[APIName.openFileFromCloud.rawValue] as? [AnyHashable: Any] {
            testValue(settingValue: openValue)
        } else {
            XCTAssert(false, "setting mock failed!")
        }
    }
    
    func test_settingDefaultFalseAppIDTrue() throws {
        
        // 修改指定值
        SettingStorage.updateSettingValue(Setting.mockValueDefaultFalseTestAppIDTrue, with: SettingManager.currentChatterID(), and: Setting.key)
        
        let setting = try SettingManager.shared.setting(with: Setting.key)
        
        func testValue(settingValue: [AnyHashable: Any]) {
            if let defaultValue = settingValue["default"] as? Bool {
                XCTAssertFalse(defaultValue)
            } else {
                XCTAssert(false, "setting mock failed!")
            }
            if let appIDValue = settingValue["testAppID"] as? Bool {
                XCTAssertTrue(appIDValue)
            } else {
                XCTAssert(false, "setting mock failed!")
            }
        }
        
        if let downloadValue = setting[APIName.downloadFileFromCloud.rawValue] as? [AnyHashable: Any] {
            testValue(settingValue: downloadValue)
        } else {
            XCTAssert(false, "setting mock failed!")
        }
        
        if let uploadValue = setting[APIName.uploadFileToCloud.rawValue] as? [AnyHashable: Any] {
            testValue(settingValue: uploadValue)
        } else {
            XCTAssert(false, "setting mock failed!")
        }
        
        if let openValue = setting[APIName.openFileFromCloud.rawValue] as? [AnyHashable: Any] {
            testValue(settingValue: openValue)
        } else {
            XCTAssert(false, "setting mock failed!")
        }
    }
    
//    func test_settingPlaceholderDefaultIsFalseAndSomeAppIDIsTrue() throws {
//        
//        let setting = try SettingManager.shared.setting(with: Setting.key)
//        
//        func testValue(settingValue: [AnyHashable: Any]) {
//            if let defaultValue = settingValue["default"] as? Bool {
//                XCTAssertFalse(defaultValue)
//            } else {
//                XCTAssert(false, "setting mock failed!")
//            }
//            if let appIDValue = settingValue["cli_a271e57f7b78900c"] as? Bool {
//                XCTAssertTrue(appIDValue)
//            } else {
//                XCTAssert(false, "setting mock failed!")
//            }
//        }
//        
//        if let downloadValue = setting[APIName.downloadFileFromCloud.rawValue] as? [AnyHashable: Any] {
//            testValue(settingValue: downloadValue)
//        } else {
//            XCTAssert(false, "setting mock failed!")
//        }
//        
//        if let uploadValue = setting[APIName.uploadFileToCloud.rawValue] as? [AnyHashable: Any] {
//            testValue(settingValue: uploadValue)
//        } else {
//            XCTAssert(false, "setting mock failed!")
//        }
//        
//        if let openValue = setting[APIName.openFileFromCloud.rawValue] as? [AnyHashable: Any] {
//            testValue(settingValue: openValue)
//        } else {
//            XCTAssert(false, "setting mock failed!")
//        }
//    }
    
    // MARK: 通过API验证逻辑
    func test_apiDisable() throws {
        
        disableAPI()
        
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: APIName.downloadFileFromCloud.rawValue, params: Params.DownloadFile.noFilePath) { response in
            switch response.toTestReponse() {
            case .success(_): break
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue, OpenAPICommonErrno.unable.rawValue)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }
    
    func test_apiEnable() throws {
        
        enableAPI()
        
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: APIName.downloadFileFromCloud.rawValue, params: Params.DownloadFile.noFilePath) { response in
            switch response.toTestReponse() {
            case .success(_): break
            case .failure(let error):
                XCTAssertNotEqual(error.errnoError?.errnoValue, OpenAPICommonErrno.unable.rawValue)
                XCTAssert(true)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 2)
    }
}

@available(iOS 13.0, *)
extension OpenPluginDriveTests {
    func enableAPI() {
        SettingStorage.updateSettingValue(Setting.mockValueEnable, with: SettingManager.currentChatterID(), and: Setting.key)
    }
    func disableAPI() {
        SettingStorage.updateSettingValue(Setting.mockValueDisable, with: SettingManager.currentChatterID(), and: Setting.key)
    }
}
