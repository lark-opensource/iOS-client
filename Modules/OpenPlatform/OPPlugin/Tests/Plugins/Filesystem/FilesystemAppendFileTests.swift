//
//  FilesystemAppendFileTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/5/11.
//

import XCTest
import OPUnitTestFoundation

@available(iOS 13.0, *)
final class FilesystemAppendFileTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    func test_appendFile_string_no_encoding() throws {
        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .user)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue,
                                          "data":FileSystemTestUtils.multiLineString]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.appendFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let data = try FileSystemTestUtils.readFile(ttfile: ttfile)
                    let resString = String(data: data, encoding: .utf8)
                    XCTAssertEqual(resString, FileSystemTestUtils.multiLineString.appending(FileSystemTestUtils.multiLineString))
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
    
    func test_appendFile_data() throws {
        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .user)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        guard let data = FileSystemTestUtils.multiLineString.data(using: .utf8) else{
            XCTFail("string to data fail")
            return
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue,
                                          "data":data]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.appendFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let data = try FileSystemTestUtils.readFile(ttfile: ttfile)
                    let resString = String(data: data, encoding: .utf8)
                    XCTAssertEqual(resString, FileSystemTestUtils.multiLineString.appending(FileSystemTestUtils.multiLineString))
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
    
    func test_appendFile_string_base64_encoding() throws {
        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.base64String, using: .base64, type: .user)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let dataOrigin = try FileSystemTestUtils.readFile(ttfile: ttfile)

        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue,
                                          "data":FileSystemTestUtils.base64String,
                                          "encoding":"base64"]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.appendFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let dataNow = try FileSystemTestUtils.readFile(ttfile: ttfile)
                    XCTAssertEqual(dataNow.count, dataOrigin.count * 2)
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


}
