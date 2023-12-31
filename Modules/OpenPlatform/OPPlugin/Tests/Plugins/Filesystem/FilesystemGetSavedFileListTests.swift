//
//  FilesystemGetSavedFileListTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/5/19.
//

import XCTest
import OPUnitTestFoundation

@available(iOS 13.0, *)
final class FilesystemGetSavedFileListTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    //temp文件不应该在getSavedFileList中
    func test_getSavedFileList_temp_dir() throws {

        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .temp)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = [:]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.getSavedFileList.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let fileList = result?.toJSONDict()["fileList"] as? [[String:AnyHashable]] else{
                    XCTFail("fileList invalidate")
                    return
                }
                let list = fileList.filter { element in
                    guard let filePath = element["filePath"] as? String else{
                        return false
                    }
                    return filePath == ttfile.rawValue
                }
                XCTAssertEqual(list.count, 0)
            case .failure(error: let error):
                XCTFail(error.description)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_getSavedFileList_user_dir() throws {

        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .user)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = [:]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.getSavedFileList.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let fileList = result?.toJSONDict()["fileList"] as? [[String:AnyHashable]] else{
                    XCTFail("size fileList")
                    return
                }
                let list = fileList.filter { element in
                    guard let filePath = element["filePath"] as? String else{
                        return false
                    }
                    return filePath == ttfile.rawValue
                }
                XCTAssertEqual(list.count, 1)
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
