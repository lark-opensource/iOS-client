//
//  FilesystemUnzipTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/6/14.
//

import XCTest
import OPUnitTestFoundation
@testable import LarkSetting

@available(iOS 13.0, *)
final class FilesystemUnzipTests: FilesystemBaseTests {
    private var originSetting: [String: Any]?
    private var originFG: Bool?
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        try mockFgOrSettings()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        resetFgOrSettings()
        try super.tearDownWithError()
    }
    
    //不存在的文件，认为是success
    func test_unzip_file() throws {

        let srcTTfile = try FileSystemTestUtils.getUnzipTTFile()

        let dirName = FileSystemTestUtils.generateRandomString()
        let desTTfile = try FileSystemTestUtils.createDirectory(ttfile: FileObject(rawValue: "ttfile://user/\(dirName)"))
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: srcTTfile)
            try FileSystemTestUtils.removeDir(ttfile: desTTfile)
        }
        let params:[AnyHashable : Any] = ["zipFilePath":srcTTfile.rawValue,
                                          "targetPath":desTTfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.unzip.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let contenst = try FileSystemTestUtils.contentsOfDirectory(ttfile: desTTfile)
                    XCTAssert(contenst.contains("test.txt"))
                } catch {
                    XCTFail("error:\(error)")
                }
            case .failure(error: let error):
                XCTFail(error.description)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
}

@available(iOS 13.0, *)
extension FilesystemUnzipTests{
    func mockFgOrSettings() throws {
        originFG =  FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: FileSettings.Key.sandboxStandardizeEnable))
        originSetting = try SettingManager.shared.setting(with: FileSettings.Key.sandboxApiConfigKey)
        
        FeatureGatingStorage.updateDebugFeatureGating(fg: FileSettings.Key.sandboxStandardizeEnable, isEnable: true, id: "")
        SettingStorage.updateSettingValue(FileSettings.Value.sandboxApiConfigValue, with: SettingManager.currentChatterID(), and: FileSettings.Key.sandboxApiConfigKey)
    }
    
    func resetFgOrSettings() {
        if let originSetting = originSetting, let originString = originSetting.toJsonString() {
            SettingStorage.updateSettingValue(originString, with: SettingManager.currentChatterID(), and: FileSettings.Key.sandboxApiConfigKey)
        }
        if let originFG {
            FeatureGatingStorage.updateDebugFeatureGating(fg: FileSettings.Key.sandboxStandardizeEnable, isEnable: originFG, id: "")
        }
        originSetting = nil
        originFG = nil
    }
}
