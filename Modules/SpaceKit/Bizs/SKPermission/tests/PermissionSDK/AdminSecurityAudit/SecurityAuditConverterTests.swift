//
//  SecurityAuditConverterTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/23.
//

import Foundation
import XCTest
@testable import SKPermission
import ServerPB
import LarkSecurityAudit
import SKFoundation
import SKResource
import SpaceInterface

final class SecurityAuditConverterTests: XCTestCase {

    private typealias Converter = SecurityAuditConverter

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testConvertEntity() {
        var entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .doc))
        XCTAssertEqual(entity.id, "CCM_TOKEN")
        XCTAssertEqual(entity.entityType, .ccmDoc)

        entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .sheet))
        XCTAssertEqual(entity.entityType, .ccmSheet)

        entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .bitable))
        XCTAssertEqual(entity.entityType, .ccmBitable)

        entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .mindnote))
        XCTAssertEqual(entity.entityType, .ccmMindnote)

        entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .file))
        XCTAssertEqual(entity.entityType, .ccmFile)

        entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .slides))
        XCTAssertEqual(entity.entityType, .ccmSlide)

        entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .imMsgFile))
        XCTAssertEqual(entity.entityType, .imFile)

        entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .folder))
        XCTAssertEqual(entity.entityType, .unknown)

        entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .docX))
        XCTAssertEqual(entity.entityType, .unknown)

        entity = Converter.convertEntity(entity: .ccm(token: "CCM_TOKEN", type: .wiki))
        XCTAssertEqual(entity.entityType, .unknown)

        entity = Converter.convertEntity(entity: .driveSDK(domain: .imFile, fileID: "IM_FILE_ID"))
        XCTAssertEqual(entity.id, "IM_FILE_ID")
        XCTAssertEqual(entity.entityType, .imFile)

        entity = Converter.convertEntity(entity: .driveSDK(domain: .calendarAttachment, fileID: ""))
        XCTAssertEqual(entity.entityType, .unknown)

        entity = Converter.convertEntity(entity: .driveSDK(domain: .mailAttachment, fileID: ""))
        XCTAssertEqual(entity.entityType, .unknown)

        entity = Converter.convertEntity(entity: .driveSDK(domain: .openPlatformAttachment, fileID: ""))
        XCTAssertEqual(entity.entityType, .unknown)
    }

    func testConvertLegacyPermissionType() {
        var result = Converter.convertLegacyPermissionType(operation: .shareToExternal)
        XCTAssertEqual(result, .fileShare)

        let irrelevantOperations: [PermissionRequest.Operation] = [
            .applyEmbed,
            .comment,
            .copyContent,
            .createCopy,
            .createSubNode,
            .delete,
            .deleteEntity,
            .deleteVersion,
            .download,
            .downloadAttachment,
            .edit,
            .export,
            .inviteEdit,
            .inviteFullAccess,
            .inviteSinglePageEdit,
            .inviteSinglePageFullAccess,
            .inviteSinglePageView,
            .inviteView,
            .isContainerFullAccess,
            .isSinglePageFullAccess,
            .manageCollaborator,
            .manageContainerCollaborator,
            .manageContainerPermissionMeta,
            .managePermissionMeta,
            .manageSinglePageCollaborator,
            .manageSinglePagePermissionMeta,
            .manageVersion,
            .modifySecretLabel,
            .moveSubNode,
            .moveThisNode,
            .moveToHere,
            .openWithOtherApp,
            .save,
            .secretLabelVisible,
            .upload,
            .uploadAttachment,
            .view,
            .viewCollaboratorInfo
        ]

        irrelevantOperations.forEach { operation in
            XCTAssertNil(Converter.convertLegacyPermissionType(operation: operation))
        }
    }

    func testToastMessage() {
        let message = Converter.toastMessage(operation: .shareToExternal)
        XCTAssertEqual(message, BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
    }
}
