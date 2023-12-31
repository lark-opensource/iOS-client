//
//  FilesystemGetFileInfoTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/5/18.
//

import XCTest
import OPUnitTestFoundation
import LarkOpenAPIModel

@available(iOS 13.0, *)
final class FilesystemGetFileInfoTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    func test_getfileinfo_exist_file() throws {

        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.getFileInfo.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let size = result?.toJSONDict()["size"] as? NSNumber else{
                    XCTFail("size invalidate")
                    return
                }
                do {
                    let fileSize = try FileSystemTestUtils.fileSize(ttfile: ttfile)
                    XCTAssertEqual(size.int64Value, fileSize)
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
    
    func test_getfileinfo_no_exist_file() throws {
        let ttfile = FileObject.generateRandomTTFile(type: .user, fileExtension: "txt")

        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.getFileInfo.rawValue, params: params) { response in
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
  
}
