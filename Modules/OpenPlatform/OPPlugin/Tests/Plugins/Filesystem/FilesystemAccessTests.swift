//
//  FilesystemAccessTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/5/11.
//

import XCTest
import OPUnitTestFoundation
import LarkOpenAPIModel

@available(iOS 13.0, *)
final class FilesystemAccessTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    func test_access_exist_file() throws {
        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["path":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.access.rawValue, params: params) { response in
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
    
    func test_access_no_exist_file() throws {
        let notExistFile = FileObject.generateRandomTTFile(type: .user, fileExtension: "txt")

        let params:[AnyHashable : Any] = ["path":notExistFile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.access.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                XCTFail("file not exist, should not success")
            case .failure(error: let error):
                let errno = error.errnoInfo["errno"] as? Int
                XCTAssertEqual(errno, OpenAPICommonErrno.fileNotExists(filePath: "").rawValue)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }

    func test_access_exist_dir() throws {
        let dirName = FileSystemTestUtils.generateRandomString()
        let ttfile = try FileSystemTestUtils.createDirectory(ttfile: FileObject(rawValue: "ttfile://user/\(dirName)"))
        addTeardownBlock {
            try FileSystemTestUtils.removeDir(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["path":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.access.rawValue, params: params) { response in
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

    func test_access_no_exist_dir() throws {
        let notExistDir = try FileObject(rawValue: "ttfile://user/notExistDir")
        let params:[AnyHashable : Any] = ["path":notExistDir.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.access.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                XCTFail("file not exist, should not success")
            case .failure(error: let error):
                let errnoInfo = error.errnoInfo["errno"] as? Int
                XCTAssertEqual(errnoInfo, OpenAPICommonErrno.fileNotExists(filePath: "").rawValue)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
}
