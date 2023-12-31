//
//  SKShareViewModelTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by peilongfei on 2022/6/8.
//  


import XCTest
@testable import SKCommon
import OHHTTPStubs
@testable import SKFoundation
import SKInfra

class SKShareViewModelTests: XCTestCase {
    
    var docVM: SKShareViewModel!
    
    var formVM: SKShareViewModel!
    
    var folderVM: SKShareViewModel!
    
    var oldFolderVM: SKShareViewModel!
    
    var shareSubTypeVM: SKShareViewModel?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        AssertionConfigForTest.disableAssertWhenTesting()
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.record.share", value: true)
        UserScopeNoChangeFG.setMockFG(key: "ccm.permission.mobile.copy_entity_enable", value: true)
        setupDocVM()
        setupFormVM()
        setupFolderVM()
        setupShareSubTypeVM()
        super.setUp()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.record.share")
        UserScopeNoChangeFG.removeMockFG(key: "ccm.permission.mobile.copy_entity_enable")
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    // 方法已经被注释了
//    func testShowformPanelEntrance() {
//        XCTAssertFalse(docVM.showformPanelEntrance())
//    }
    
    func testShowCollaboratorsEntrance() {
        XCTAssertTrue(docVM.showCollaboratorsEntrance())
    }
    
    func testShowEditLinkSettingEntrance() {
        XCTAssertTrue(docVM.showEditLinkSettingEntrance())
        XCTAssertTrue(formVM.showEditLinkSettingEntrance())
        XCTAssertTrue(folderVM.showEditLinkSettingEntrance())
        XCTAssertFalse(oldFolderVM.showEditLinkSettingEntrance())
    }
    
    func testShowPermissionSettingEntrance() {
        XCTAssertTrue(docVM.showPermissionSettingEntrance())
        XCTAssertFalse(formVM.showPermissionSettingEntrance())
        XCTAssertTrue(folderVM.showPermissionSettingEntrance())
    }
    
    func testFetchDocMeta() {
        let expect = expectation(description: "testFetchDocMeta")
        docVM.fetchDocMeta(token: docVM.shareEntity.objToken, type: docVM.shareEntity.type) { meta, error in
            XCTAssertNil(error)
            XCTAssertNotNil(meta)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testFetchUserPermissions() {
        let expect = expectation(description: "testFetchUserPermissions")
        expect.expectedFulfillmentCount = 4
        
        docVM.fetchUserPermissions { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        formVM.fetchUserPermissions { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        folderVM.fetchUserPermissions { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        oldFolderVM.fetchUserPermissions { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testFetchPublicPermissions() {
        let expect = expectation(description: "testFetchPublicPermissions")
        expect.expectedFulfillmentCount = 5
        
        docVM.fetchPublicPermissions { ret, error in
            XCTAssertNil(error)
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        
        formVM.fetchPublicPermissions { ret, error in
            XCTAssertNil(error)
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        
        folderVM.fetchPublicPermissions { ret, error in
            XCTAssertNil(error)
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        
        oldFolderVM.fetchPublicPermissions { ret, error in
            XCTAssertNil(error)
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        
        shareSubTypeVM?.fetchPublicPermissions { ret, error in
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testRequestFormShareMeta() {
        let expect = expectation(description: "testRequestFormShareMeta")
        formVM.requestFormShareMeta { meta, error in
            XCTAssertNil(error)
            XCTAssertNotNil(meta)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testUpdateFormShareMeta() {
        let expect = expectation(description: "testUpdateFormShareMeta")
        expect.expectedFulfillmentCount = 2
        formVM.updateFormShareMeta(true) { ret in
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        
        formVM.updateFormShareMeta(false) { ret in
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testUpdatePublicPermissions() {
        let expect = expectation(description: "testUpdatePublicPermissions")
        expect.expectedFulfillmentCount = 3
        
        docVM.updatePublicPermissions(linkShareEntity: 4) { ret, error, json in
            XCTAssertNil(error)
            XCTAssertTrue(ret)
            XCTAssertNotNil(json)
            expect.fulfill()
        }
        
        folderVM.updatePublicPermissions(linkShareEntity: 4) { ret, error, json in
            XCTAssertNil(error)
            XCTAssertTrue(ret)
            XCTAssertNotNil(json)
            expect.fulfill()
        }
        
        oldFolderVM.updatePublicPermissions(linkShareEntity: 4) { ret, error, json in
            XCTAssertNil(error)
            XCTAssertTrue(ret)
            XCTAssertNotNil(json)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testUnlockPermission() {
        let expect = expectation(description: "testUnlockPermission")
        expect.expectedFulfillmentCount = 2
        
        docVM.unlockPermission { ret in
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        
        folderVM.unlockPermission { ret in
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testFetchUserPermissionsAndPublicPermissions() {
        let expect = expectation(description: "testFetchUserPermissionsAndPublicPermissions")
        expect.expectedFulfillmentCount = 2
        docVM.fetchUserPermissionsAndPublicPermissions { ret in
            XCTAssertTrue(ret)
        } allCompletion: { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        shareSubTypeVM?.fetchUserPermissionsAndPublicPermissions { ret in
            XCTAssertTrue(ret)
        } allCompletion: { error in
            expect.fulfill()
        }
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testUpdateBitableShareFlag() {
        shareSubTypeVM?.updateBitableShareFlag(true) { error in
            XCTAssertNotNil(error)
        }
    }
    
    func testRequestBitableShareMeta() {
        let expect = expectation(description: "testFetchUserPermissions")
        expect.expectedFulfillmentCount = 2
        
        self.shareSubTypeVM?.requestBitableShareMeta { (result, code) in
            XCTAssertNotNil(result)
            expect.fulfill()
        }
        
        let shareEntity = SKShareEntity(
            objToken: "mockToken123",
            type: 0,
            title: "",
            isOwner: false,
            ownerID: "",
            displayName: "",
            tenantID: "",
            isFromPhoenix: false,
            shareUrl: "",
            enableShareWithPassWord: false,
            enableTransferOwner: false,
            bitableShareEntity: nil
        )
        let shareSubTypeVM = SKShareViewModel(shareEntity: shareEntity)
        shareSubTypeVM.requestBitableShareMeta { (result, code) in
            XCTAssertNotNil(result)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
}

extension SKShareViewModelTests {
    
    func setupDocVM() {
        let docShareEntiry = SKShareEntity(objToken: "docbcCtQz1Zt8kAo57wnOVP4iph",
                                           type: 2,
                                           title: "模版测试一下",
                                           isOwner: true,
                                           ownerID: "7096041708793626643",
                                           displayName: "芜湖起飞",
                                           tenantID: "",
                                           isFromPhoenix: false,
                                           shareUrl: "https://wprwq3i7jr.feishu-boe.cn/docs/docbcCtQz1Zt8kAo57wnOVP4iph",
                                           enableShareWithPassWord: true,
                                           enableTransferOwner: true)
        let docBizParameter = SpaceBizParameter(module: .home(.recent))
        docVM = SKShareViewModel(shareEntity: docShareEntiry,
                                 bizParameter: docBizParameter,
                                 isInVideoConference: false)
        
        let fetchDocMetaPath = OpenAPI.APIPath.meta(docVM.shareEntity.objToken, docVM.shareEntity.type.rawValue)
        let docMetaJsonPath = "doc_meta.json"
        stub(apiPath: fetchDocMetaPath, filePath: docMetaJsonPath)
        
        let fetchDocUserPermissionPath = OpenAPI.APIPath.suitePermissonDocumentActionsState
        let userDocPermissionJsonPath = "user_permission.json"
        stub(apiPath: fetchDocUserPermissionPath, filePath: userDocPermissionJsonPath)
        
        let fetchDocPublicPermission = OpenAPI.APIPath.suitePermissionPublicV4 + "?token=\(docVM.shareEntity.objToken)&type=\(docVM.shareEntity.type.rawValue)"
        let publicDocPermissionJsonPath = "public_permission.json"
        stub(apiPath: fetchDocPublicPermission, filePath: publicDocPermissionJsonPath)
        
        let updateDocPublicPermissionPath = OpenAPI.APIPath.suitePermissionPublicUpdateV5
        let updateDocPublicPermissionJsonPath = "permission_public_updatev4.json"
        stub(apiPath: updateDocPublicPermissionPath, filePath: updateDocPublicPermissionJsonPath)
        
        let docPermissionUnlockPath = OpenAPI.APIPath.unlockFile
        let docPermissionUnlockJsonPath = "permission_unlock.json"
        stub(apiPath: docPermissionUnlockPath, filePath: docPermissionUnlockJsonPath)
    }
    
    func setupFormVM() {
        let formShareMeta = FormShareMeta(token: "basbcJqA1yY7qv4Ps1Y2KH6Bqoh",
                                          tableId: "tblAI3vj0rp2J3lb",
                                          viewId: "vewVm92WiA",
                                          shareType: 1,
                                          hasCover: false)
        let formShareEntiry = SKShareEntity(objToken: "basbcJqA1yY7qv4Ps1Y2KH6Bqoh",
                                            type: 80,
                                            title: "表单视图 1",
                                            isOwner: true,
                                            ownerID: "7096041708793626643",
                                            displayName: "芜湖起飞",
                                            tenantID: "6898285364474019860",
                                            isFromPhoenix: false,
                                            shareUrl: "https://wprwq3i7jr.feishu-boe.cn/base/basbcJqA1yY7qv4Ps1Y2KH6Bqoh",
                                            enableShareWithPassWord: true,
                                            enableTransferOwner: true,
                                            formShareMeta: formShareMeta)
        formVM = SKShareViewModel(shareEntity: formShareEntiry,
                                   bizParameter: nil,
                                   isInVideoConference: false)
        
        let formMeta = formVM.shareEntity.formShareFormMeta
        let formToken = formMeta?.token ?? ""
        let formShareType = formMeta?.shareType ?? 0
        let formTableId = formMeta?.tableId ?? ""
        let formViewId = formMeta?.viewId ?? ""
        let fetchShareFormMetaPath = OpenAPI.APIPath.getFormShareMetaPath(formToken) + "?shareType=\(formShareType)&tableId=\(formTableId)&viewId=\(formViewId)"
        let formShareMetaJsonPath = "form_share_meta.json"
        stub(apiPath: fetchShareFormMetaPath, filePath: formShareMetaJsonPath)
        
        let fetchFormUserPermissionPath = OpenAPI.APIPath.getFormPermissionPath(formVM.shareEntity.objToken)
        let userFormPermissionJsonPath = "form_user_permission.json"
        stub(apiPath: fetchFormUserPermissionPath, filePath: userFormPermissionJsonPath)
        
        let fetchFormPublicPermission = OpenAPI.APIPath.getFormPermissionSettingPath(formVM.shareEntity.objToken)
        let publicFormPermissionJsonPath = "public_permission.json"
        stub(apiPath: fetchFormPublicPermission, filePath: publicFormPermissionJsonPath)
        
        let updateFormMetaPath = OpenAPI.APIPath.updateFormMetaPath
        let updateFormShareMetaJsonPath = "update_form_share_meta.json"
        stub(apiPath: updateFormMetaPath, filePath: updateFormShareMetaJsonPath)
    }
    
    func setupFolderVM() {
        let folderShareEntiry = SKShareEntity(objToken: "docbcCtQz1Zt8kAo57wnOVP4iph",
                                           type: 0,
                                           title: "模版测试一下",
                                           isOwner: true,
                                           ownerID: "7096041708793626643",
                                           displayName: "芜湖起飞",
                                           folderType: .v2Common,
                                           tenantID: "",
                                           isFromPhoenix: false,
                                           shareUrl: "https://wprwq3i7jr.feishu-boe.cn/docs/docbcCtQz1Zt8kAo57wnOVP4iph",
                                           spaceSingleContainer: true,
                                           enableShareWithPassWord: true,
                                           enableTransferOwner: true)
        let folderBizParameter = SpaceBizParameter(module: .home(.recent))
        folderVM = SKShareViewModel(shareEntity: folderShareEntiry,
                                 bizParameter: folderBizParameter,
                                 isInVideoConference: false)
        
        let oldFolderShareEntiry = SKShareEntity(objToken: "docbcCtQz1Zt8kAo57wnOVP4iph",
                                           type: 0,
                                           title: "模版测试一下",
                                           isOwner: true,
                                           ownerID: "7096041708793626643",
                                           displayName: "芜湖起飞",
                                           folderType: .common,
                                           tenantID: "",
                                           isFromPhoenix: false,
                                           shareUrl: "https://wprwq3i7jr.feishu-boe.cn/docs/docbcCtQz1Zt8kAo57wnOVP4iph",
                                           wikiV2SingleContainer: true,
                                           spaceSingleContainer: false,
                                           enableShareWithPassWord: true,
                                           enableTransferOwner: true)
        oldFolderVM = SKShareViewModel(shareEntity: oldFolderShareEntiry,
                                 bizParameter: folderBizParameter,
                                 isInVideoConference: false)
        
        let fetchFolderUserPermissionPath = OpenAPI.APIPath.getShareFolderUserPermission
        let userFolderPermissionJsonPath = "folder_user_permission.json"
        stub(apiPath: fetchFolderUserPermissionPath, filePath: userFolderPermissionJsonPath)
        
        let fetchFolderPublicPermission = OpenAPI.APIPath.getShareFolderPublicPermissionV2 + "?token=\(folderVM.shareEntity.objToken)&type=\(folderVM.shareEntity.type.rawValue)"
        let publicFolderPermissionJsonPath = "folder_public_permission.json"
        stub(apiPath: fetchFolderPublicPermission, filePath: publicFolderPermissionJsonPath)
        
        let updateFolderPublicPermissionPath = OpenAPI.APIPath.updateShareFolderPublicPermissionV2
        let updateFolderPublicPermissionJsonPath = "folder_update_permission.json"
        stub(apiPath: updateFolderPublicPermissionPath, filePath: updateFolderPublicPermissionJsonPath)

        let updateOldFolderPublicPermissionPath = OpenAPI.APIPath.suitePermissionShareSpaceSetUpdate
        let updateOldFolderPublicPermissionJsonPath = "folder_update_permission.json"
        stub(apiPath: updateOldFolderPublicPermissionPath, filePath: updateOldFolderPublicPermissionJsonPath)
        
        let folderPermissionUnlockPath = OpenAPI.APIPath.unlockShareFolder
        let folderPermissionUnlockJsonPath = "permission_unlock.json"
        stub(apiPath: folderPermissionUnlockPath, filePath: folderPermissionUnlockJsonPath)
    }
    
    func setupShareSubTypeVM() {
        // let bitableShareMeta = BitableShareMeta(flag: .open, objType: 80, shareToken: "shrbcBUNnvDSVf8JqD5aaA5llhf", shareType: .dashboard, constraintExternal: false)
        // let shareEntiry = SKShareEntity(objToken: "BNDtbBXWNaz6sjsogvNbUIricPW",
        //                                     type: 85,
        //                                     title: "仪表盘",
        //                                     isOwner: true,
        //                                     ownerID: "6959157050525876244",
        //                                     displayName: "芜湖起飞",
        //                                     tenantID: "1",
        //                                     isFromPhoenix: false,
        //                                     shareUrl: "https://bytedance.feishu-boe.cn/base/BNDtbBXWNaz6sjsogvNbUIricPW",
        //                                     enableShareWithPassWord: true,
        //                                     enableTransferOwner: true,
        //                                     bitableShareEntity: bitableShareMeta)
        // shareSubTypeVM = SKShareViewModel(shareEntity: formShareEntiry, bizParameter: nil, isInVideoConference: false)
        // let param = shareEntiry.bitableShareEntity?.param
        // let requestBitableShareMetaPath = OpenAPI.APIPath.getFormShareMetaPath(param.baseToken)
        // let dashboardShareMetaJSONPath = "dashboard_share_meta.json"
        // stub(apiPath: requestBitableShareMetaPath, filePath: dashboardShareMetaJSONPath)
        // let fetchFormUserPermissionPath = OpenAPI.APIPath.getFormPermissionPath(param.baseToken)
        // let userFormPermissionJsonPath = "form_user_permission.json"
        // stub(apiPath: fetchFormUserPermissionPath, filePath: userFormPermissionJsonPath)
        
        let shareParam = BitableShareParam(
            baseToken: "mockToken123",
            shareType: .record,
            tableId: "",
            recordId: "")
        let bitableShareMeta = BitableShareMeta(
            flag: .open,
            objType: nil,
            shareToken: "mockToken123",
            shareType: .record,
            constraintExternal: false
        )
        let bitableShareEntity = BitableShareEntity(param: shareParam, docUrl: nil, meta: bitableShareMeta)
        let shareEntity = SKShareEntity(
            objToken: "mockToken123",
            type: ShareDocsType.bitableSub(.record).rawValue,
            title: "",
            isOwner: false,
            ownerID: "",
            displayName: "",
            tenantID: "",
            isFromPhoenix: false,
            shareUrl: "",
            enableShareWithPassWord: false,
            enableTransferOwner: false,
            bitableShareEntity: bitableShareEntity
        )
        self.shareSubTypeVM = SKShareViewModel(shareEntity: shareEntity)
        
        stub(apiPath: OpenAPI.APIPath.getFormShareMetaPath(shareEntity.objToken), filePath: "bitable_share_meta.json")
    }
    
    func stub(apiPath: String, filePath: String) {
        OHHTTPStubs.stub(condition: { request -> Bool in
            return request.url?.absoluteString.contains(apiPath) ?? false
        }, response: { _ -> HTTPStubsResponse in
            return HTTPStubsResponse(fileAtPath: OHPathForFile(filePath, type(of: self))!,
                                     statusCode: 200,
                                     headers: ["Content-Type": "application/json"])
        })
    }
}
