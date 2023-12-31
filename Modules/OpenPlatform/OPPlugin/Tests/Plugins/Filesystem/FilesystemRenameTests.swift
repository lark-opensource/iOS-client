//
//  FilesystemRenameTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/6/13.
//

import XCTest
import OPUnitTestFoundation
import LarkOpenAPIModel

@available(iOS 13.0, *)
final class FilesystemRenameTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    func test_rename_to_user() throws {
        let srcfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .user)
        let fileName = FileSystemTestUtils.generateRandomString()
        let desFile = try FileObject(rawValue: "ttfile://user/\(fileName)")
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: srcfile)
            try FileSystemTestUtils.removeFile(ttfile: desFile)
        }
        let params:[AnyHashable : Any] = ["oldPath":srcfile.rawValue,
                                          "newPath":desFile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.rename.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                do {
                    let srcExist = try FileSystemTestUtils.fileExist(ttfile: srcfile)
                    let desExist = try FileSystemTestUtils.fileExist(ttfile: desFile)
                    XCTAssert(!srcExist, "src file should not exist")
                    XCTAssert(desExist, "des file should exist")
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
    
    func test_rename_to_temp() throws {
        let srcfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .user)

        let fileName = FileSystemTestUtils.generateRandomString()
        let desFile = try FileObject(rawValue: "ttfile://temp/\(fileName)")
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: srcfile)
            try FileSystemTestUtils.removeFile(ttfile: desFile)
        }
        let params:[AnyHashable : Any] = ["oldPath":srcfile.rawValue,
                                          "newPath":desFile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.rename.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                XCTFail("desFile in temp, should not success")
            case .failure(error: let error):
                let errno = error.errnoInfo["errno"] as? Int
                XCTAssertEqual(errno, OpenAPICommonErrno.writePermissionDenied(filePath: "").rawValue)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
}
