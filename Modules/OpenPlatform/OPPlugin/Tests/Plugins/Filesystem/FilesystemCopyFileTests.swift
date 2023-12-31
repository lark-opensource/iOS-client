//
//  FilesystemCopyFileTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/5/15.
//

import XCTest
import OPUnitTestFoundation
import LarkOpenAPIModel

@available(iOS 13.0, *)
final class FilesystemCopyFileTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }

    func test_copyFile_exist_file() throws {

        let srcFile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8)
        let destFile = FileObject.generateRandomTTFile(type: .user, fileExtension: "txt")
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: srcFile)
            try FileSystemTestUtils.removeFile(ttfile: destFile)
        }
        let params:[AnyHashable : Any] = ["srcPath":srcFile.rawValue,
                                          "destPath":destFile.rawValue]
        let exp = XCTestExpectation(description: "async")
        
        testUtils.asyncCall(apiName: FileAPI.copyFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let data = try FileSystemTestUtils.readFile(ttfile: destFile)
                    let resString = String(data: data, encoding: .utf8)
                    XCTAssertEqual(resString, FileSystemTestUtils.multiLineString)
                } catch {
                    XCTFail("\(error)")
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
    
    func test_copyFile_not_exist_file() throws {
        let srcFile = FileObject.generateRandomTTFile(type: .user, fileExtension: "txt")
        let destFile = FileObject.generateRandomTTFile(type: .user, fileExtension: "txt")

        let params:[AnyHashable : Any] = ["srcPath":srcFile.rawValue,
                                          "destPath":destFile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.copyFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                XCTFail("srcfile not exist, should not success")
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

    func test_copyFile_dest_tempDir() throws {
        let srcFile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8)
        let destFile = FileObject.generateRandomTTFile(type: .temp, fileExtension: "txt")
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: srcFile)
            try FileSystemTestUtils.removeFile(ttfile: destFile)
        }
        let params:[AnyHashable : Any] = ["srcPath":srcFile.rawValue,
                                          "destPath":destFile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.copyFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                XCTFail("temp dir writePermissionDenied, should not success")
            case .failure(error: let error):
                let errno = error.errnoInfo["errno"] as? Int
                XCTAssertEqual(errno, OpenAPICommonErrno.writePermissionDenied(filePath: "").rawValue)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 20)
    }
    
}
