//
//  FilesystemReadFileTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/4/26.
//

import XCTest
import OPUnitTestFoundation

@available(iOS 13.0, *)
final class FilesystemReadFileTests: FilesystemBaseTests {
    var ttfile1: FileObject? = nil

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        ttfile1 = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8)

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try FileSystemTestUtils.removeFile(ttfile: ttfile1)
        try super.tearDownWithError()
    }

    func test_readFile_no_encoding() throws {
        guard let ttfile = ttfile1 else {
            XCTFail("ttfile not exist")
            return
        }

        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.readFile.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let resData = result?.toJSONDict()["data"] else{
                    XCTFail("data nil")
                    return
                }
                guard let resData = resData as? Data else{
                    XCTFail("invalidate result")
                    return
                }
                let resString = String(data: resData, encoding: .utf8)
                XCTAssertEqual(resString, FileSystemTestUtils.multiLineString)
            case .failure(error: let error):
                XCTFail(error.description)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }

    func test_readFile_utf8_encoding() throws {
        guard let ttfile = ttfile1 else {
            XCTFail("ttfile not exist")
            return
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue,
                                          "encoding":"utf8"]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.readFile.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let resData = result?.toJSONDict()["data"] else{
                    XCTFail("data nil")
                    return
                }
                guard let resData = resData as? String else{
                    XCTFail("invalidate result")
                    return
                }
                XCTAssertEqual(resData, FileSystemTestUtils.multiLineString)

            case .failure(error: let error):
                XCTFail(error.description)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_readFile_base64_encoding() throws {
        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.base64String, using: .base64)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue,
                                          "encoding":"base64"]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.readFile.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let resData = result?.toJSONDict()["data"] else{
                    XCTFail("data nil")
                    return
                }
                guard let resData = resData as? String else{
                    XCTFail("invalidate result")
                    return
                }
                XCTAssertEqual(resData, FileSystemTestUtils.base64String)

            case .failure(error: let error):
                XCTFail(error.description)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_readFile_hex_encoding() throws {
        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.hexString, using: .hex)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue,
                                          "encoding":"hex"]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.readFile.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let resData = result?.toJSONDict()["data"] else{
                    XCTFail("data nil")
                    return
                }
                guard let resData = resData as? String else{
                    XCTFail("invalidate result")
                    return
                }
                XCTAssertEqual(resData, FileSystemTestUtils.hexString)
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
