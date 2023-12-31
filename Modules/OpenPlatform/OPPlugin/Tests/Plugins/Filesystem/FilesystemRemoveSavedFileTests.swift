//
//  FilesystemRemoveSavedFileTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/6/13.
//

import XCTest
import OPUnitTestFoundation

@available(iOS 13.0, *)
final class FilesystemRemoveSavedFileTests: FilesystemBaseTests {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    func test_removeSavedFile_user_dir() throws {

        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .user)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.removeSavedFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
               break
            case .failure(error: let error):
                XCTFail(error.description)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    //如果是removeSavedFile，temp目录可以删除
    func test_removeSavedFile_temp_dir() throws {

        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .temp)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.removeSavedFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                break
            case .failure(error: let error):
                XCTFail(error.description)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    //不存在的文件，认为是success
    func test_removeSavedFile_file_not_exist() throws {
        let ttfile = FileObject.generateRandomTTFile(type: .user, fileExtension: "txt")

        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.removeSavedFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                break
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

