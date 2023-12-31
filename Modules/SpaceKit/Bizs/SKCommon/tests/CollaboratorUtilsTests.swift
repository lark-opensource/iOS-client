//
//  CollaboratorUtilsTests.swift
//  SpaceDemoTests
//
//  Created by gupqingping on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.
// swiftlint:disable force_try


import XCTest
@testable import SKCommon
@testable import SKUIKit
import RxSwift
import RxRelay
import SKResource

class CollaboratorUtilsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetupSelectItemPermission() {
        let collaborator = Collaborator(rawValue: 0, userID: "fakeUserID", name: "fakeName",
                                        avatarURL: "fakeAvatarURl", avatarImage: nil,
                                        userPermissions: UserPermissionMask(rawValue: 0), groupDescription: nil)
        CollaboratorUtils.setupSelectItemPermission(currentItem: collaborator, objToken: nil, docsType: .doc, userPermissions: nil)
        XCTAssertTrue(collaborator.userPermissions.canView())
    }

    func testUtil() {
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
        let items = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)

        XCTAssertTrue(CollaboratorUtils.containsOrganizationCollaborators(items))
        XCTAssertFalse(CollaboratorUtils.containsMultiOrganizationCollaborators(items))
        XCTAssertFalse(CollaboratorUtils.containsLargeGroupCollaborators(items))
        XCTAssertTrue(CollaboratorUtils.containsExternalCollaborators(items))
        XCTAssertTrue(CollaboratorUtils.containsInternalGroupCollaborators(items))
        XCTAssertEqual(CollaboratorUtils.containsGroupCollaboratorsCount(items), 1)

        var context = CollaboratorUtils.PlaceHolderContext(source: .sharePanel,
                                                           docsType: .bitableSub(BitableShareSubType.dashboard),
                                                           isForm: false,
                                                           isBitableAdvancedPermissions: false,
                                                           isSingleContainer: false,
                                                           isSameTenant: false,
                                                           isEmailSharingEnabled: true)
        XCTAssertFalse(CollaboratorUtils.addUserGroupEnable(context: context))

        XCTAssertFalse(CollaboratorUtils.addDepartmentEnable(source: .diyTemplate, docsType: .doc))
        context = .init(source: .sharePanel,
                        docsType: .docX,
                        isForm: false,
                        isBitableAdvancedPermissions: false,
                        isSingleContainer: false,
                        isSameTenant: false,
                        isEmailSharingEnabled: true)
        XCTAssertEqual(CollaboratorUtils.getCollaboratorSearchPlaceHolder(context: context),
                       BundleI18n.SKResource.LarkCCM_Docs_Share_SearchForEmail_Placeholder)
        context = .init(source: .sharePanel,
                        docsType: .docX,
                        isForm: false,
                        isBitableAdvancedPermissions: false,
                        isSingleContainer: false,
                        isSameTenant: false,
                        isEmailSharingEnabled: false)
        XCTAssertEqual(CollaboratorUtils.getCollaboratorSearchPlaceHolder(context: context),
                       BundleI18n.SKResource.Doc_Permission_AddUserHint)
        context = .init(source: .diyTemplate,
                        docsType: .doc,
                        isForm: false,
                        isBitableAdvancedPermissions: false,
                        isSingleContainer: true,
                        isSameTenant: true,
                        isEmailSharingEnabled: true)
        _ = CollaboratorUtils.addUserGroupEnable(context: context)
    }
    
}
