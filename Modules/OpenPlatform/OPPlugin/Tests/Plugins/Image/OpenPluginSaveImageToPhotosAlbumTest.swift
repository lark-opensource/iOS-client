//
//  OpenPluginSsaveImageToPhotosAlbumTest.swift
//  OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/12/7.
//

import XCTest
import OPUnitTestFoundation
@testable import OPPlugin

extension BDPAuthorization {
    @objc class func hook_checkSystemPermission(withTips:BDPAuthorizationSystemPermissionType,completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}

@available(iOS 13.0, *)
final class OpenPluginSaveImageToPhotosAlbumTest: XCTestCase {

    private var testUtils = OpenPluginGadgetTestUtils()
    private var ttfile: FileObject?
    
    override func setUpWithError() throws {
        testUtils.prepareGadgetSandboxPath(pkgName: "testPkg")
        do {
            let randomttfile = FileObject.generateRandomTTFile(type: .temp, fileExtension: "jpg")
            ttfile = randomttfile
            let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "mediaUnitTest")
            try FileSystemCompatible.writeSystemData("test".data(using: .utf8)!, to: randomttfile, context: fsContext)

        } catch  {}

        BDPAuthorization.lkw_swizzleOriginClassMethod(#selector(BDPAuthorization.checkSystemPermission(withTips:completion:)), withHookClassMethod: #selector(BDPAuthorization.hook_checkSystemPermission(withTips:completion:)))
    }

    override func tearDownWithError() throws {
        try FileSystemTestUtils.removeFile(ttfile: ttfile)
        BDPAuthorization.lkw_swizzleOriginClassMethod(#selector(BDPAuthorization.checkSystemPermission(withTips:completion:)), withHookClassMethod: #selector(BDPAuthorization.hook_checkSystemPermission(withTips:completion:)))
    }
    
    func test_saveImageToPhotoAlbum_success() throws {
        guard let ttfile = ttfile else {
            XCTFail("ttfile not exist")
            return
        }
        let params:[AnyHashable : Any] = ["filePath":ttfile.rawValue]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "saveImageToPhotosAlbum", params: params) { response in
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

