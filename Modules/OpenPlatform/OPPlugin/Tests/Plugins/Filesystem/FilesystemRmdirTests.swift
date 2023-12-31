//
//  FilesystemRmdirTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/6/13.
//

import XCTest
import OPUnitTestFoundation
import LarkOpenAPIModel

@available(iOS 13.0, *)
final class FilesystemRmdirTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    func test_rmdir_dir_exist() throws {
        let dirName = FileSystemTestUtils.generateRandomString()
        let ttfile = try FileSystemTestUtils.createDirectory(ttfile: FileObject(rawValue: "ttfile://user/\(dirName)"))
        addTeardownBlock {
            try FileSystemTestUtils.removeDir(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["dirPath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.rmdir.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let exist = try FileSystemTestUtils.fileExist(ttfile: ttfile)
                    XCTAssert(!exist, "should not exist")
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
    //不存在的dir，直接返回成功
    func test_rmdir_dir_not_exist() throws {
        let dirName = FileSystemTestUtils.generateRandomString()
        let ttfile = try FileObject(rawValue: "ttfile://user/\(dirName)")
        let params:[AnyHashable : Any] = ["dirPath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.rmdir.rawValue, params: params) { response in
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
    //父目录递归删除
    func test_rmdir_multi_level_recursive() throws {

        let level = FileSystemTestUtils.generateRandomString()
        let dirNameMuti = FileSystemTestUtils.generateRandomString()
        let ttfile = try FileSystemTestUtils.createDirectory(ttfile: FileObject(rawValue: "ttfile://user/\(level)/\(dirNameMuti)"))
        addTeardownBlock {
            try FileSystemTestUtils.removeDir(ttfile: ttfile)
        }
        let parentTTFile = ttfile.deletingLastPathComponent
        let params:[AnyHashable : Any] = ["dirPath":parentTTFile.rawValue,
                                          "recursive":true]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.rmdir.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let exist = try FileSystemTestUtils.fileExist(ttfile: parentTTFile)
                    XCTAssert(!exist, "should not exist")
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

    //非递归会判断parent是否有子文件&目录
    func test_rkdir_multi_level_no_recursive() throws {
        let level2 = FileSystemTestUtils.generateRandomString()
        let dirNameMuti2 = FileSystemTestUtils.generateRandomString()
        let ttfile = try FileSystemTestUtils.createDirectory(ttfile: FileObject(rawValue: "ttfile://user/\(level2)/\(dirNameMuti2)"))
        addTeardownBlock {
            try FileSystemTestUtils.removeDir(ttfile: ttfile)
        }
        let parentTTFile = ttfile.deletingLastPathComponent
        let params:[AnyHashable : Any] = ["dirPath":parentTTFile.rawValue,
                                          "recursive":false]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.rmdir.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                XCTFail("multi-level dir no recursive, should not success")
            case .failure(error: let error):
                let errno = error.errnoInfo["errno"] as? Int
                XCTAssertEqual(errno, OpenAPICommonErrno.directoryNotEmpty(filePath: "").rawValue)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }

    
}
