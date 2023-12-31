//
//  CollaboratorSearchViewModelTests.swift
//  SpaceDemoTests
//
//  Created by gupqingping on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.
// swiftlint:disable force_try line_length


import XCTest
import OHHTTPStubs
@testable import SKCommon
@testable import SKUIKit
import RxSwift
import RxRelay
@testable import SKFoundation
import SKInfra
import SpaceInterface
// @testable import BitableShareSubType


class CollaboratorSearchViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getShareFolderUserPermission)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("space_collaborator_perm.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionShareSpaceCollaboratorPerm)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("space_collaborator_perm.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDoc() {
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
        let existedCollaborators = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
        let selectedItems: [Collaborator] = []

        let fileModel: CollaboratorFileModel = CollaboratorFileModel(objToken: "doccnLDKO2l21vFINm1Cpp4wTxc",
                                                                     docsType: ShareDocsType(rawValue: 2),
                                                                     title: "miji doc",
                                                                     isOWner: true,
                                                                     ownerID: "6807206588324069377",
                                                                     displayName: "miji doc",
                                                                     spaceID: "",
                                                                     folderType: nil,
                                                                     tenantID: tenantID(),
                                                                     createTime: 1636082828,
                                                                     createDate: "20211105",
                                                                     creatorID: "6807206588324069377",
                                                                     spaceSingleContainer: true,
                                                                     enableTransferOwner: true,
                                                                     formMeta: nil)
        let userPermissons: UserPermission? = nil
        let publicPermisson: PublicPermissionMeta? = nil

        let viewModel = CollaboratorSearchViewModel(existedCollaborators: existedCollaborators,
                                                    selectedItems: selectedItems,
                                                    fileModel: fileModel,
                                                    lastPageLabel: "fakelastPageLabel",
                                                    userPermission: userPermissons,
                                                    publicPermisson: publicPermisson)
        viewModel.handle(visibleUserGroups: [])
        let expect = expectation(description: "test CollaboratorSearchViewModel")
        async {
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(viewModel.invitationDatas.count > 0)
        
        UserScopeNoChangeFG.setMockFG(key: "ccm.permision.mail_sharing", value: true)
        XCTAssertTrue(viewModel.isEmailSharingEnabled)
        UserScopeNoChangeFG.setMockFG(key: "ccm.permision.mail_sharing", value: false)
        XCTAssertFalse(viewModel.isEmailSharingEnabled)
    }

    func testNewShareFolder() {
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
        let existedCollaborators = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
        let selectedItems: [Collaborator] = []

        let fileModel: CollaboratorFileModel = CollaboratorFileModel(objToken: "fldcnRHLMIttPq76VD98eVtNbOg",
                                                                     docsType: .folder,
                                                                     title: "miji folder",
                                                                     isOWner: true,
                                                                     ownerID: "6807206588324069377",
                                                                     displayName: "miji folder",
                                                                     spaceID: "",
                                                                     folderType: FolderType(ownerType: 5,
                                                                                            shareVersion: 0,
                                                                                            isShared: true),
                                                                     tenantID: tenantID(),
                                                                     createTime: 1636082828,
                                                                     createDate: "20211105",
                                                                     creatorID: "6807206588324069377",
                                                                     spaceSingleContainer: true,
                                                                     enableTransferOwner: true,
                                                                     formMeta: nil)
        let userPermissons: UserPermission? = nil
        let publicPermisson: PublicPermissionMeta? = nil

        let viewModel = CollaboratorSearchViewModel(existedCollaborators: existedCollaborators,
                                                    selectedItems: selectedItems,
                                                    fileModel: fileModel,
                                                    lastPageLabel: "fakelastPageLabel",
                                                    userPermission: userPermissons,
                                                    publicPermisson: publicPermisson)

        let expect = expectation(description: "test CollaboratorSearchViewModel")

        viewModel.requestUserPermission()
        async {
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(viewModel.userPermissions?.canManageMeta() == true)
    }
    
    func testShareFormAndSubType() {
//        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
//        let data = try Data(contentsOf: URL(fileURLWithPath: path))
//        let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
//        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
//        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
//        let existedCollaborators = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
//        let selectedItems: [Collaborator] = []
//        let userPermissons: UserPermission? = nil
//        let publicPermisson: PublicPermissionMeta? = nil
//        let fileModel: CollaboratorFileModel = CollaboratorFileModel(objToken: "fldcnRHLMIttPq76VD98eVtNbOg", docsType: .bitableSub(.dashboard), title: "miji folder", isOWner: true, ownerID: "6807206588324069377", displayName: "miji folder", spaceID: "fldcnRHLMIttP", folderType: nil, tenantID: tenantID(), createTime: 1636082828, createDate: "20211105", creatorID: "6807206588324069377", spaceSingleContainer: false, enableTransferOwner: true, formMeta: nil)
//        let viewModel = CollaboratorSearchViewModel(existedCollaborators: existedCollaborators, selectedItems: selectedItems, fileModel: fileModel, lastPageLabel: nil, userPermission: userPermissons, publicPermisson: publicPermisson)
//        let fileModel2: CollaboratorFileModel = CollaboratorFileModel(objToken: "fldcnRHLMIttPq76VD98eVtNbOg", docsType: .form, title: "miji folder", isOWner: true, ownerID: "6807206588324069377", displayName: "miji folder", spaceID: "fldcnRHLMIttP", folderType: nil, tenantID: tenantID(), createTime: 1636082828, createDate: "20211105", creatorID: "6807206588324069377", spaceSingleContainer: false, enableTransferOwner: true, formMeta: nil)
//        let viewModel2 = CollaboratorSearchViewModel(existedCollaborators: existedCollaborators, selectedItems: selectedItems, fileModel: fileModel2, lastPageLabel: nil, userPermission: userPermissons, publicPermisson: publicPermisson)
    }

    func testOldShareFolder() {
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
        let existedCollaborators = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
        let selectedItems: [Collaborator] = []

        let fileModel: CollaboratorFileModel = CollaboratorFileModel(objToken: "fldcnRHLMIttPq76VD98eVtNbOg",
                                                                     docsType: .folder,
                                                                     title: "miji folder",
                                                                     isOWner: true,
                                                                     ownerID: "6807206588324069377",
                                                                     displayName: "miji folder",
                                                                     spaceID: "fldcnRHLMIttP",
                                                                     folderType: FolderType(ownerType: 1,
                                                                                            shareVersion: 0,
                                                                                            isShared: true),
                                                                     tenantID: tenantID(),
                                                                     createTime: 1636082828,
                                                                     createDate: "20211105",
                                                                     creatorID: "6807206588324069377",
                                                                     spaceSingleContainer: false,
                                                                     enableTransferOwner: true,
                                                                     formMeta: nil)
        let userPermissons: UserPermission? = nil
        let publicPermisson: PublicPermissionMeta? = nil

        let viewModel = CollaboratorSearchViewModel(existedCollaborators: existedCollaborators,
                                                    selectedItems: selectedItems,
                                                    fileModel: fileModel,
                                                    lastPageLabel: "fakelastPageLabel",
                                                    userPermission: userPermissons,
                                                    publicPermisson: publicPermisson)

        let expect = expectation(description: "test CollaboratorSearchViewModel")
        viewModel.requestUserPermission()
        async {
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(viewModel.userPermissions?.canManageMeta() == false)
    }
    func async(completion: @escaping() -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: completion)
    }
    private func tenantID() -> String {
        guard let tenantID = User.current.info?.tenantID else {
            return "1"
        }
        return tenantID
    }
}
