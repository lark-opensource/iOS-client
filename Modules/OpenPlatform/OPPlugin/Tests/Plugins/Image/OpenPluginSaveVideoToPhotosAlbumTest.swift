//
//  OpenPluginSsaveImageToPhotosAlbumTest.swift
//  OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/12/7.
//

import XCTest
import OPUnitTestFoundation
@testable import OPPlugin

@available(iOS 13.0, *)
final class OpenPluginSaveVideoToPhotosAlbumTest: XCTestCase {

    private var testUtils = OpenPluginGadgetTestUtils()
    private var ttfile: FileObject?
    
    override func setUpWithError() throws {
        testUtils.prepareGadgetSandboxPath(pkgName: "testPkg")
        do {
            let randomttfile = FileObject.generateRandomTTFile(type: .temp, fileExtension: "mp4")
            ttfile = randomttfile
            let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "mediaUnitTest")
            try FileSystemCompatible.writeSystemData("test".data(using: .utf8)!, to: randomttfile, context: fsContext)

        } catch  {}
    }

    override func tearDownWithError() throws {
        try FileSystemTestUtils.removeFile(ttfile: ttfile)
    }
    
    func test_saveVideoToPhotoAlbum_success() throws {
        guard let ttfile = ttfile else {
            XCTFail("ttfile not exist")
            return
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "saveVideoToPhotosAlbum", params: params) { response in
            switch response {
            case .success(_):
                exp.fulfill()
            case .failure(error: let error):
                XCTFail(error.description)
                exp.fulfill()
            default:
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }
}

