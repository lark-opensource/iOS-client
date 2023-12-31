//
//  DKSecretSettingVCModuleTest.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by peilongfei on 2022/9/2.
//  


import XCTest
import SKCommon
import SwiftyJSON
import OHHTTPStubs
import SKFoundation
@testable import SKDrive
import SKInfra

class DKSecretSettingVCModuleTest: XCTestCase {
    
    var module: DKSecretSettingVCModule!
    let mockModule = MockHostModule()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        module = DKSecretSettingVCModule(hostModule: mockModule, windowSizeDependency: MockDependency())
        
        stubNet(userPermJson: "DriveUserPermissionOwner.json",
                publicPermJson: "DrivePublicPermissionOwner.json")
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        super.tearDown()
    }

    func testBindHostModule() {
        XCTAssertNoThrow(module.bindHostModule())
    }
    
    func testShowSecretSettingVC() {
        let meta = DriveFileMeta(size: 100,
                                 name: "",
                                 type: "",
                                 fileToken: "",
                                 mountNodeToken: "",
                                 mountPoint: "",
                                 version: nil,
                                 dataVersion: nil,
                                 source: .cache,
                                 tenantID: nil,
                                 authExtra: "")
        let docsFileInfo = DriveFileInfo(fileMeta: meta)
        let docsInfo = DocsInfo(type: .docX, objToken: "jdsfklsdjlfksdflkklsdf")
        let secInfo = ["sec_label": ""]
        docsInfo.secLabel = SecretLevel(json: JSON(secInfo))
        XCTAssertNoThrow(module.showSecretSettingVC(fileInfo: docsFileInfo, docsInfo: docsInfo, viewFrom: .moreMenu))
        XCTAssertNoThrow(module.showSecretSettingVC(fileInfo: docsFileInfo, docsInfo: docsInfo, viewFrom: .upperIcon))
        XCTAssertNoThrow(module.showSecretSettingVC(fileInfo: docsFileInfo, docsInfo: docsInfo, viewFrom: .banner))
    }
    
    private func stubNet(userPermJson: String, publicPermJson: String) {
        // stub user permission
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissonDocumentActionsState)
            print("xxxx - \(OpenAPI.APIPath.suitePermissonDocumentActionsState) contain:\(contain)")
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile(userPermJson, type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        // stub public permission
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionPublicV4)
            print("xxxx - \(OpenAPI.APIPath.suitePermissionPublicV4) contain:\(contain)")

            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile(publicPermJson, type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
    }
}
