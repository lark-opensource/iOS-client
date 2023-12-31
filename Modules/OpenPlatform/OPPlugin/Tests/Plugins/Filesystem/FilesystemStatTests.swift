//
//  FilesystemStatTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/6/14.
//

import XCTest
import OPUnitTestFoundation

@available(iOS 13.0, *)
final class FilesystemStatTests: FilesystemBaseTests {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }
    
    func test_state_of_file() throws {

        let ttfile = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8)
        addTeardownBlock {
            try FileSystemTestUtils.removeFile(ttfile: ttfile)
        }
        let params:[AnyHashable : Any] = ["path":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.stat.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let stat = result?.toJSONDict()["stat"] as? [String: AnyHashable] else{
                    XCTFail("stat invalidate")
                    return
                }
                guard let size = stat["size"] as? NSNumber else {
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
    
}
