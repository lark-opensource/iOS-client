//
//  OrganizationSearchViewModelTests.swift
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
import SKFoundation
import SKInfra
import SpaceInterface


class OrganizationSearchViewModelTests: XCTestCase {

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

        let fileModel: CollaboratorFileModel = CollaboratorFileModel(objToken: "doccnLDKO2l21vFINm1Cpp4wTxc", docsType: ShareDocsType(rawValue: 2), title: "miji doc", isOWner: true, ownerID: "6807206588324069377", displayName: "miji doc", spaceID: "", folderType: nil, tenantID: tenantID(), createTime: 1636082828, createDate: "20211105", creatorID: "6807206588324069377", enableTransferOwner: true, formMeta: nil)
        let userPermissons: UserPermission? = nil
        let publicPermisson: PublicPermissionMeta? = nil

        let viewModel = OrganizationSearchViewModel(existedCollaborators: existedCollaborators, selectedItems: selectedItems, fileModel: fileModel, userPermissions: userPermissons, publicPermisson: publicPermisson)

        let expect = expectation(description: "test searchVisibleDepartment")

        viewModel.tableViewDriver.drive(onNext: { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTAssertTrue(false)
            }
            expect.fulfill()
            
        }).disposed(by: disposeBag)

        viewModel.breadcrumbsViewDriver.drive(onNext: { _ in

        }).disposed(by: disposeBag)

        viewModel.noResultDriver.drive(onNext: { _ in

        }).disposed(by: disposeBag)

        viewModel.searchVisibleDepartment(departmentInfo: DepartmentInfo.rootDepartment)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }

        viewModel.loadMoreVisibleDepartment(departmentInfo: DepartmentInfo.rootDepartment)
    }

    func testFolder() {
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
        let existedCollaborators = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
        let selectedItems: [Collaborator] = []

        let fileModel: CollaboratorFileModel = CollaboratorFileModel(objToken: "fldcnRHLMIttPq76VD98eVtNbOg", docsType: ShareDocsType(rawValue: 0), title: "miji folder", isOWner: true, ownerID: "6807206588324069377", displayName: "miji folder", spaceID: "", folderType: FolderType(ownerType: 5, shareVersion: 0, isShared: true), tenantID: tenantID(), createTime: 1636082828, createDate: "20211105", creatorID: "6807206588324069377", spaceSingleContainer: true, enableTransferOwner: true, formMeta: nil)
        let userPermissons: UserPermission? = nil
        let publicPermisson: PublicPermissionMeta? = nil

        let viewModel = OrganizationSearchViewModel(existedCollaborators: existedCollaborators, selectedItems: selectedItems, fileModel: fileModel, userPermissions: userPermissons, publicPermisson: publicPermisson)

        let expect = expectation(description: "test searchVisibleDepartment")

        viewModel.tableViewDriver.drive(onNext: { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTAssertTrue(false)
            }
            expect.fulfill()

        }).disposed(by: disposeBag)

        viewModel.breadcrumbsViewDriver.drive(onNext: { _ in

        }).disposed(by: disposeBag)

        viewModel.noResultDriver.drive(onNext: { _ in

        }).disposed(by: disposeBag)

        viewModel.searchVisibleDepartment(departmentInfo: DepartmentInfo.rootDepartment)
        viewModel.loadMoreVisibleDepartment(departmentInfo: DepartmentInfo.rootDepartment)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    
    func testBitableAdPermCollaboratorSearch() {
        
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
        let exist = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)

        let fm = CollaboratorFileModel(
            objToken: "doccnLDKO2l21vFINm1Cpp4wTxc",
            docsType: .bitable,
            title: "test",
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
            formMeta: nil
        )
        
        let vm = OrganizationSearchViewModel(
            existedCollaborators: exist,
            selectedItems: [],
            fileModel: fm,
            userPermissions: nil,
            publicPermisson: nil,
            isBitableAdvancedPermissions: true,
            bitablePermissonRule: nil
        )

        let expect = expectation(description: "testBitableAdPermCollaboratorSearch")

        vm.tableViewDriver.drive(onNext: { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTAssertTrue(false)
            }
            expect.fulfill()
            
        }).disposed(by: disposeBag)

        vm.breadcrumbsViewDriver.drive(onNext: { _ in

        }).disposed(by: disposeBag)

        vm.noResultDriver.drive(onNext: { _ in

        }).disposed(by: disposeBag)

        vm.searchVisibleDepartment(departmentInfo: DepartmentInfo.rootDepartment)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }

        vm.loadMoreVisibleDepartment(departmentInfo: DepartmentInfo.rootDepartment)
    }
    
    private func tenantID() -> String {
        guard let tenantID = User.current.info?.tenantID else {
            return "1"
        }
        return tenantID
    }
}
