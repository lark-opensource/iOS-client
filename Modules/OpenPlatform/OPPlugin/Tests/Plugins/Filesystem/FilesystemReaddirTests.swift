//
//  FilesystemReaddirTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/6/12.
//

import XCTest
import OPUnitTestFoundation

@available(iOS 13.0, *)
final class FilesystemReaddirTests: FilesystemBaseTests {
    var ttfile1: FileObject? = nil
    var ttfile2: FileObject? = nil
    var ttfile3: FileObject? = nil
    var fileNameArr: [String] = []
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        
        let dirName = FileSystemTestUtils.generateRandomString()
        let dirPath = "ttfile://user/\(dirName)"
        ttfile1 = try FileSystemTestUtils.createDirectory(ttfile: FileObject(rawValue: dirPath))
        
        let fileName2 = "\(FileSystemTestUtils.generateRandomString()).txt"
        let ttfile_2 = try FileObject(rawValue: "\(dirPath)/\(fileName2)")
        fileNameArr.append(fileName2)
        ttfile2 = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, ttfile: ttfile_2)
        
        let fileName3 = "\(FileSystemTestUtils.generateRandomString()).txt"
        let ttfile_3 = try FileObject(rawValue: "\(dirPath)/\(fileName3)")
        fileNameArr.append(fileName3)
        ttfile3 = try FileSystemTestUtils.writeFile(str: FileSystemTestUtils.multiLineString, using: .utf8, ttfile: ttfile_3)

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try FileSystemTestUtils.removeDir(ttfile: ttfile1)
        try super.tearDownWithError()
    }
    
    func test_readdir_dir_exist() throws {
        guard let ttfile = ttfile1 else {
            XCTFail("ttfile not exist")
            return
        }
        let params:[AnyHashable : Any] = ["dirPath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: FileAPI.readdir.rawValue, params: params) { response in
            switch response {
            case .success(data: let result):
                guard let files = result?.toJSONDict()["files"] as? [String] else{
                    XCTFail("files invalidate")
                    return
                }
                XCTAssertEqual(Set(files), Set(self.fileNameArr))
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
