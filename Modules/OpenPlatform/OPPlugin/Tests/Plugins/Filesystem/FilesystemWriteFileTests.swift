//
//  FilesystemWriteFileTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/5/9.
//

import XCTest
import OPUnitTestFoundation

@available(iOS 13.0, *)
final class FilesystemWriteFileTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    func test_writeFile_string_no_encoding() throws {
        let randomFile = FileObject.generateRandomTTFile(type: .user, fileExtension: "txt")
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: randomFile)
        }
        let params:[AnyHashable : Any] = ["filePath":randomFile.rawValue,
                                          "data":FileSystemTestUtils.multiLineString]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.writeFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let data = try FileSystemTestUtils.readFile(ttfile: randomFile)
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
    
    func test_writeFile_data() throws {
        let randomFile = FileObject.generateRandomTTFile(type: .user, fileExtension: "txt")
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: randomFile)
        }
        guard let data = FileSystemTestUtils.multiLineString.data(using: .utf8) else{
            XCTFail("string to data fail")
            return
        }
        let params:[AnyHashable : Any] = ["filePath":randomFile.rawValue,
                                          "data":data]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.writeFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let data = try FileSystemTestUtils.readFile(ttfile: randomFile)
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
    
    func test_writeFile_string_base64_encoding() throws {
        let randomFile = FileObject.generateRandomTTFile(type: .user, fileExtension: "txt")
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: randomFile)
        }
        let params:[AnyHashable : Any] = ["filePath":randomFile.rawValue,
                                          "data":FileSystemTestUtils.base64String,
                                          "encoding":"base64"]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.writeFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let data = try FileSystemTestUtils.readFile(ttfile: randomFile)
                    let resString = data.base64EncodedString()
                    XCTAssertEqual(resString, FileSystemTestUtils.base64String)
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
