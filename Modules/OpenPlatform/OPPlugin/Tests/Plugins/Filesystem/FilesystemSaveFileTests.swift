//
//  FilesystemSaveFileTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/6/13.
//

import XCTest
import OPUnitTestFoundation
import LarkOpenAPIModel

@available(iOS 13.0, *)
final class FilesystemSaveFileTests: FilesystemBaseTests {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    func test_savefile_src_temp_dir() throws {

        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .temp)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["tempFilePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.saveFile.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let savedFilePath = result?.toJSONDict()["savedFilePath"] as? String else{
                    XCTFail("savedFilePath invalidate")
                    return
                }
                do {
                    let exist = try FileSystemTestUtils.fileExist(ttfile: FileObject(rawValue: savedFilePath))
                    XCTAssert(exist, "src temp dir should save success & exist")
                } catch {
                    XCTFail("error:\(error)")
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
    
    func test_savefile_src_user_dir() throws {

        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, type: .user)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["tempFilePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.saveFile.rawValue, params: params) { response in
            switch response {
            case .success(data: _):
                XCTFail("src user dir should not save success")
            case .failure(error: let error):
                let errno = error.errnoInfo["errno"] as? Int
                XCTAssertEqual(errno, OpenAPICommonErrno.invalidParam(.invalidParam(param: "")).rawValue)
            case .continue(_, _):
                XCTFail("should not case continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
   
}
