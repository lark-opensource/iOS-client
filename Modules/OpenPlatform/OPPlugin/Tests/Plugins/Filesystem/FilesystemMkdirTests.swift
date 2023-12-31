//
//  FilesystemMkdirTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/6/12.
//

import XCTest
import OPUnitTestFoundation
import LarkOpenAPIModel

@available(iOS 13.0, *)
final class FilesystemMkdirTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    //目录已经存在则报错
    func test_mkdir_dir_exist() throws {
        
        let dirName = FileSystemTestUtils.generateRandomString()
        let ttfile = try FileSystemTestUtils.createDirectory(ttfile: FileObject(rawValue: "ttfile://user/\(dirName)"))
        addTeardownBlock {
            try FileSystemTestUtils.removeDir(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["dirPath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.mkdir.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                XCTFail("file file already exist, should not success")
            case .failure(error: let error):
                let errno = error.errnoInfo["errno"] as? Int
                XCTAssertEqual(errno, OpenAPICommonErrno.fileAlreadyExists(filePath: "").rawValue)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_mkdir_dir_not_exist() throws {
        let dirName = FileSystemTestUtils.generateRandomString()
        let ttfile = try FileObject(rawValue: "ttfile://user/\(dirName)")
        addTeardownBlock {
            try FileSystemTestUtils.removeDir(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["dirPath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.mkdir.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let exist = try FileSystemTestUtils.fileExist(ttfile: ttfile)
                    XCTAssert(exist, "dir should exist")
                } catch  {
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
    
    func test_mkdir_multi_level_recursive() throws {
        let level = FileSystemTestUtils.generateRandomString()
        let dirName = FileSystemTestUtils.generateRandomString()
        let ttfile = try FileObject(rawValue: "ttfile://user/\(level)/\(dirName)")
        addTeardownBlock {
            try FileSystemTestUtils.removeDir(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["dirPath":ttfile.rawValue,
                                          "recursive":true]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.mkdir.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let exist = try FileSystemTestUtils.fileExist(ttfile: ttfile)
                    XCTAssert(exist, "dir should exist")
                } catch  {
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
    //非递归会判断parent目录是否存在
    func test_mkdir_multi_level_no_recursive() throws {
        let level = FileSystemTestUtils.generateRandomString()
        let dirName = FileSystemTestUtils.generateRandomString()
        let ttfile = try FileObject(rawValue: "ttfile://user/\(level)/\(dirName)")
        addTeardownBlock {
            try FileSystemTestUtils.removeDir(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["dirPath":ttfile.rawValue,
                                          "recursive":false]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.mkdir.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                XCTFail("multi-level dir no recursive, should not success")
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
    
    
}
