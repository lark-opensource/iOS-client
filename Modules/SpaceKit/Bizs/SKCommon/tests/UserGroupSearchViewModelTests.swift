//
//  UserGroupSearchViewModelTests.swift
//  SpaceDemoTests
//
//  Created by gupqingping on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
import OHHTTPStubs
@testable import SKCommon
@testable import SKUIKit
import RxSwift
import RxRelay
import SKFoundation
import SKInfra
import SpaceInterface

class UserGroupSearchViewModelTests: XCTestCase {
    
    let disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        
        AssertionConfigForTest.disableAssertWhenTesting()

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.searchVisibleDepartment)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("visibleDepartment.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionCollaboratorsExist)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("visibleDepartmentExistV2.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.collaboratorsExistForShareFolder)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("visibleDepartmentExistV2.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDoc() {
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try? JSONSerialization.jsonObject(with: data!, options: .fragmentsAllowed)
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
                                                                     enableTransferOwner: true,
                                                                     formMeta: nil)
        print(fileModel.notShowUserGroupCell)
        let userPermissons: UserPermission? = nil
        let publicPermisson: PublicPermissionMeta? = nil

        let viewModel = UserGroupSearchViewModel(userGroups: [],
                                                    existedCollaborators: existedCollaborators,
                                                    selectedCollaborators: selectedItems,
                                                    fileModel: fileModel,
                                                    userPermission: userPermissons,
                                                    publicPermission: publicPermisson,
                                                    shouldCheckIsExisted: true,
                                                    isBitableAdvancedPermissions: true,
                                                    bitablePermissionRule: nil,
                                                    isEmailSharingEnabled: false)

        let expect = expectation(description: "testDoc")

        viewModel.reloadDataForUnitTest()
            .subscribe {
                XCTAssertTrue(true)
                expect.fulfill()
            } onError: { _ in
                XCTAssertTrue(false)
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testFolder() {
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try? JSONSerialization.jsonObject(with: data!, options: .fragmentsAllowed)
        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
        let existedCollaborators = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
        let selectedItems: [Collaborator] = []

        let fileModel: CollaboratorFileModel = CollaboratorFileModel(objToken: "fldcnRHLMIttPq76VD98eVtNbOg",
                                                                     docsType: ShareDocsType(rawValue: 0),
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

        let viewModel = UserGroupSearchViewModel(userGroups: [],
                                                    existedCollaborators: existedCollaborators,
                                                    selectedCollaborators: selectedItems,
                                                    fileModel: fileModel,
                                                    userPermission: userPermissons,
                                                    publicPermission: publicPermisson,
                                                    shouldCheckIsExisted: true,
                                                    isBitableAdvancedPermissions: true,
                                                    bitablePermissionRule: nil,
                                                    isEmailSharingEnabled: false)

        let expect = expectation(description: "testFolder")

        viewModel.reloadDataForUnitTest()
            .subscribe {
                XCTAssertTrue(true)
                expect.fulfill()
            } onError: { _ in
                XCTAssertTrue(false)
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testBitableAdPermUserCroupSearch() {
        
        let ug: [Collaborator] = []
        
        let fm = CollaboratorFileModel(
            objToken: "fldcnRHLMIttPq76VD98eVtNbOg",
            docsType: .bitable,
            title: "",
            isOWner: true,
            ownerID: "",
            displayName: "",
            spaceID: "",
            folderType: nil,
            tenantID: "1",
            createTime: 0,
            createDate: "",
            creatorID: "",
            templateMainType: nil,
            wikiV2SingleContainer: false,
            spaceSingleContainer: false,
            enableTransferOwner: true,
            formMeta: nil
        )
        
        let vm = UserGroupSearchViewModel(
            userGroups: ug,
            existedCollaborators: [],
            selectedCollaborators: [],
            fileModel: fm,
            userPermission: nil,
            publicPermission: nil,
            shouldCheckIsExisted: true,
            isBitableAdvancedPermissions: true,
            bitablePermissionRule: nil,
            isEmailSharingEnabled: false
        )
        
        let expect = expectation(description: "testBitableAdPermCollaboratorSearch")
        
        vm.reloadDataForUnitTest()
            .subscribe {
                XCTAssertTrue(true)
                expect.fulfill()
            } onError: { _ in
                XCTAssertTrue(false)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    private func tenantID() -> String {
        guard let tenantID = User.current.info?.tenantID else {
            return "1"
        }
        return tenantID
    }
}
