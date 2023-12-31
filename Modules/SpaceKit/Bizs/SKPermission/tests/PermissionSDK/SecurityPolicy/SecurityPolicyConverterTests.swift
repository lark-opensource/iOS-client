//
//  SecurityPolicyConverterTests.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/24.
//

import Foundation
import XCTest
@testable import SKPermission
@testable import SKFoundation
import ServerPB
import LarkSecurityComplianceInterface
import SpaceInterface
import SKResource
import LarkContainer

final class SecurityPolicyConverterTests: XCTestCase {

    typealias Converter = SecurityPolicyConverter

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        UserScopeNoChangeFG.clearAllMockFG()
    }

    // 主要用于检查 entity 类型是否正确
    func testConvertPolicyModel() {
        let ccmRequest = PermissionRequest(token: "MOCK_TOKEN",
                                           type: .docX,
                                           operation: .createCopy,
                                           bizDomain: .customCCM(fileBizDomain: .calendar),
                                           tenantID: nil)
        var model = SecurityPolicyConverter.convertPolicyModel(request: ccmRequest, operatorUserID: 1024, operatorTenantID: 10240)
        if let ccmEntity = model?.entity as? CCMEntity {
            // entityType/domain/operate 另外判断
            XCTAssertEqual(ccmEntity.operatorTenantId, 10240)
            XCTAssertEqual(ccmEntity.operatorUid, 1024)
            XCTAssertEqual(ccmEntity.fileBizDomain, .calendar)
        } else {
            XCTFail("un-expected entity found: \(String(describing: model?.entity))")
        }

        let imRequest = PermissionRequest(driveSDKDomain: .imFile, fileID: "MOCK_FILE_ID", operation: .createCopy, bizDomain: .customIM(fileBizDomain: .im, senderUserID: 1, senderTenantID: 2, msgID: "MSG_ID", fileKey: "FILE_KEY", chatID: 3, chatType: 4))
        model = SecurityPolicyConverter.convertPolicyModel(request: imRequest, operatorUserID: 6, operatorTenantID: 7)
        if let entity = model?.entity as? IMFileEntity {
            XCTAssertEqual(entity.operatorTenantId, 7)
            XCTAssertEqual(entity.operatorUid, 6)
            XCTAssertEqual(entity.fileBizDomain, .im)
            XCTAssertEqual(entity.senderUserId, 1)
            XCTAssertEqual(entity.senderTenantId, 2)
            XCTAssertEqual(entity.msgId, "MSG_ID")
            XCTAssertEqual(entity.fileKey, "FILE_KEY")
            XCTAssertEqual(entity.chatID, 3)
            XCTAssertEqual(entity.chatType, 4)
        } else {
            XCTFail("un-expected entity found: \(String(describing: model?.entity))")
        }
    }

    func testConvertEntityType() {
        func assert(entityType expect: EntityType, docsType: DocsType, operation: PermissionRequest.Operation, file: StaticString = #file, line: UInt = #line) {
            let request = PermissionRequest(token: "MOCK_TOKEN",
                                            type: docsType,
                                            operation: operation,
                                            bizDomain: .ccm,
                                            tenantID: nil)
            let model = SecurityPolicyConverter.convertPolicyModel(request: request, operatorUserID: 0, operatorTenantID: 0)
            if let entity = model?.entity {
                XCTAssertEqual(entity.entityType, expect, file: file, line: line)
            } else {
                XCTFail("un-expected model found: \(String(describing: model))", file: file, line: line)
            }
        }

        func assert(entityType expect: EntityType,
                    driveSDKDomain: PermissionRequest.Entity.DriveSDKPermissionDomain,
                    operation: PermissionRequest.Operation,
                    bizDomain: PermissionRequest.BizDomain = .ccm,
                    file: StaticString = #file, line: UInt = #line) {
            let request = PermissionRequest(driveSDKDomain: driveSDKDomain, fileID: "", operation: operation, bizDomain: bizDomain)
            let model = SecurityPolicyConverter.convertPolicyModel(request: request, operatorUserID: 0, operatorTenantID: 0)
            if let entity = model?.entity {
                XCTAssertEqual(entity.entityType, expect, file: file, line: line)
            } else {
                XCTFail("un-expected model found: \(String(describing: model))", file: file, line: line)
            }
        }

        let fileConvertOperation: [PermissionRequest.Operation] = [.downloadAttachment, .download, .upload, .uploadAttachment]
        fileConvertOperation.forEach { operation in
            assert(entityType: .file, docsType: .docX, operation: operation)
        }
        // CCM
        assert(entityType: .doc, docsType: .doc, operation: .createCopy)
        assert(entityType: .docx, docsType: .docX, operation: .createCopy)
        assert(entityType: .sheet, docsType: .sheet, operation: .createCopy)
        assert(entityType: .bitable, docsType: .bitable, operation: .createCopy)
        assert(entityType: .mindnote, docsType: .mindnote, operation: .createCopy)
        assert(entityType: .file, docsType: .file, operation: .createCopy)
        assert(entityType: .spaceCatalog, docsType: .folder, operation: .createCopy)
        assert(entityType: .slides, docsType: .slides, operation: .createCopy)
        // DriveSDK
        assert(entityType: .imMsgFile, docsType: .imMsgFile, operation: .createCopy)
        assert(entityType: .file, driveSDKDomain: .imFile, operation: .createCopy, bizDomain: .ccm)
        assert(entityType: .imMsgFile, driveSDKDomain: .imFile, operation: .createCopy, bizDomain: .im)
        // 几种现在未定义的场景，未来更新
        assert(entityType: .doc, docsType: .wiki, operation: .createCopy)
        assert(entityType: .file, driveSDKDomain: .openPlatformAttachment, operation: .createCopy)
        assert(entityType: .file, driveSDKDomain: .calendarAttachment, operation: .createCopy)
        assert(entityType: .file, driveSDKDomain: .mailAttachment, operation: .createCopy)
    }

    func testConvertEntityDomain() {
        func assert(domain expect: EntityDomain,
                    docsType: DocsType,
                    file: StaticString = #file, line: UInt = #line) {
            let request = PermissionRequest(token: "MOCK_TOKEN",
                                            type: docsType,
                                            operation: .createCopy,
                                            bizDomain: .ccm,
                                            tenantID: nil)
            let model = SecurityPolicyConverter.convertPolicyModel(request: request, operatorUserID: 0, operatorTenantID: 0)
            if let entity = model?.entity {
                XCTAssertEqual(entity.entityDomain, expect, file: file, line: line)
            } else {
                XCTFail("un-expected model found: \(String(describing: model))", file: file, line: line)
            }
        }

        func assert(domain expect: EntityDomain,
                    driveSDKDomain: PermissionRequest.Entity.DriveSDKPermissionDomain,
                    bizDomain: PermissionRequest.BizDomain = .ccm,
                    file: StaticString = #file, line: UInt = #line) {
            let request = PermissionRequest(driveSDKDomain: driveSDKDomain, fileID: "", operation: .createCopy, bizDomain: bizDomain)
            let model = SecurityPolicyConverter.convertPolicyModel(request: request, operatorUserID: 0, operatorTenantID: 0)
            if let entity = model?.entity {
                XCTAssertEqual(entity.entityDomain, expect, file: file, line: line)
            } else {
                XCTFail("un-expected model found: \(String(describing: model))", file: file, line: line)
            }
        }

        assert(domain: .ccm, docsType: .doc)
        assert(domain: .ccm, docsType: .docX)
        assert(domain: .ccm, docsType: .sheet)
        assert(domain: .ccm, docsType: .bitable)
        assert(domain: .ccm, docsType: .mindnote)
        assert(domain: .ccm, docsType: .slides)
        assert(domain: .ccm, docsType: .file)
        assert(domain: .ccm, docsType: .wiki)

        assert(domain: .im, docsType: .imMsgFile)
        assert(domain: .im, driveSDKDomain: .imFile, bizDomain: .im)
        assert(domain: .ccm, driveSDKDomain: .imFile, bizDomain: .ccm)
        assert(domain: .calendar, driveSDKDomain: .calendarAttachment)
        assert(domain: .ccm, driveSDKDomain: .openPlatformAttachment)
        assert(domain: .ccm, driveSDKDomain: .mailAttachment)
    }

    func assert(operation: PermissionRequest.Operation,
                expect: EntityOperate,
                entity: PermissionRequest.Entity = .ccm(token: "MOCK_TOKEN", type: .docX),
                bizDomain: PermissionRequest.BizDomain = .ccm,
                file: StaticString = #file,
                line: UInt = #line) {
        let request = PermissionRequest(entity: entity,
                                        operation: operation,
                                        bizDomain: bizDomain)
        let model = SecurityPolicyConverter.convertPolicyModel(request: request, operatorUserID: 0, operatorTenantID: 0)
        XCTAssertEqual(model?.entity.entityOperate, expect, file: file, line: line)
    }

    func testConvertNormalOperation() {
        // 测试没有特殊转换逻辑的 operation
        func batchAssert(operation: PermissionRequest.Operation,
                         expect: EntityOperate,
                         file: StaticString = #file,
                         line: UInt = #line) {
            assert(operation: operation, expect: expect, entity: .ccm(token: "MOCK_TOKEN", type: .docX), file: file, line: line)
            assert(operation: operation, expect: expect, entity: .ccm(token: "MOCK_TOKEN", type: .file), file: file, line: line)
            assert(operation: operation,
                   expect: expect,
                   entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customIM(fileBizDomain: .im),
                   file: file,
                   line: line)
            assert(operation: operation,
                   expect: expect,
                   entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customIM(fileBizDomain: .ccm),
                   file: file,
                   line: line)
            assert(operation: operation,
                   expect: expect,
                   entity: .driveSDK(domain: .openPlatformAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customCCM(fileBizDomain: .unknown),
                   file: file,
                   line: line)
            assert(operation: operation,
                   expect: expect,
                   entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .calendar,
                   file: file,
                   line: line)
            assert(operation: operation,
                   expect: expect,
                   entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .ccm,
                   file: file,
                   line: line)
            assert(operation: operation,
                   expect: expect,
                   entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customCCM(fileBizDomain: .mail),
                   file: file,
                   line: line)
            assert(operation: operation,
                   expect: expect,
                   entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customCCM(fileBizDomain: .mail),
                   file: file,
                   line: line)
        }

        batchAssert(operation: .export, expect: .ccmExport)
        batchAssert(operation: .createCopy, expect: .ccmCreateCopy)
        batchAssert(operation: .downloadAttachment, expect: .ccmAttachmentDownload)
        batchAssert(operation: .uploadAttachment, expect: .ccmAttachmentUpload)
        batchAssert(operation: .shareToExternal, expect: .openExternalAccess)
    }

    func testConvertView() {
        // 只受 entity 影响
        let operation = PermissionRequest.Operation.view
        assert(operation: operation, expect: .ccmFilePreView, entity: .ccm(token: "MOCK_TOKEN", type: .file))
        assert(operation: operation,
               expect: .ccmFilePreView,
               entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
               bizDomain: .customIM(fileBizDomain: .im))
        assert(operation: operation,
               expect: .ccmFilePreView,
               entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
               bizDomain: .customIM(fileBizDomain: .ccm))

        assert(operation: operation, expect: .ccmContentPreview, entity: .ccm(token: "MOCK_TOKEN", type: .docX))
        assert(operation: operation,
               expect: .ccmContentPreview,
               entity: .driveSDK(domain: .openPlatformAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .customCCM(fileBizDomain: .unknown))
        assert(operation: operation,
               expect: .ccmContentPreview,
               entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .calendar)
        assert(operation: operation,
               expect: .ccmContentPreview,
               entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .ccm)
        assert(operation: operation,
               expect: .ccmContentPreview,
               entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .customCCM(fileBizDomain: .mail))
        assert(operation: operation,
               expect: .ccmContentPreview,
               entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .customCCM(fileBizDomain: .mail))
    }

    func testConvertCopyContentOperation() {
        // 只受 bizDomain 影响
        let operation = PermissionRequest.Operation.copyContent
        assert(operation: operation, expect: .ccmCopy, entity: .ccm(token: "MOCK_TOKEN", type: .docX))
        assert(operation: operation, expect: .ccmCopy, entity: .ccm(token: "MOCK_TOKEN", type: .file))
        assert(operation: operation,
               expect: .imFileCopy,
               entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
               bizDomain: .customIM(fileBizDomain: .im))
        assert(operation: operation,
               expect: .imFileCopy,
               entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
               bizDomain: .customIM(fileBizDomain: .ccm))
        assert(operation: operation,
               expect: .ccmCopy,
               entity: .driveSDK(domain: .openPlatformAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .customCCM(fileBizDomain: .unknown))
        assert(operation: operation,
               expect: .ccmCopy,
               entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .calendar)
        assert(operation: operation,
               expect: .ccmCopy,
               entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .ccm)
        assert(operation: operation,
               expect: .ccmCopy,
               entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .customCCM(fileBizDomain: .mail))
        assert(operation: operation,
               expect: .ccmCopy,
               entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .customCCM(fileBizDomain: .mail))
    }

    func testConvertUploadOperation() {
        // 只受 bizDomain 影响
        let operation = PermissionRequest.Operation.upload
        assert(operation: operation, expect: .ccmFileUpload, entity: .ccm(token: "MOCK_TOKEN", type: .docX))
        assert(operation: operation, expect: .ccmFileUpload, entity: .ccm(token: "MOCK_TOKEN", type: .file))
        assert(operation: operation,
               expect: .imFileUpload,
               entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
               bizDomain: .customIM(fileBizDomain: .im))
        assert(operation: operation,
               expect: .imFileUpload,
               entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
               bizDomain: .customIM(fileBizDomain: .ccm))
        assert(operation: operation,
               expect: .ccmFileUpload,
               entity: .driveSDK(domain: .openPlatformAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .customCCM(fileBizDomain: .unknown))
        assert(operation: operation,
               expect: .ccmFileUpload,
               entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .calendar)
        assert(operation: operation,
               expect: .ccmFileUpload,
               entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .ccm)
        assert(operation: operation,
               expect: .ccmFileUpload,
               entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .customCCM(fileBizDomain: .mail))
        assert(operation: operation,
               expect: .ccmFileUpload,
               entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
               bizDomain: .customCCM(fileBizDomain: .mail))
    }

    func testConvertDownloadOperation() {
        // 只受 bizDomain 影响
        let downloadOperations: [PermissionRequest.Operation] = [
            .download, .openWithOtherApp, .save
        ]
        downloadOperations.forEach { operation in
            assert(operation: operation, expect: .ccmFileDownload, entity: .ccm(token: "MOCK_TOKEN", type: .docX))
            assert(operation: operation, expect: .ccmFileDownload, entity: .ccm(token: "MOCK_TOKEN", type: .file))

            assert(operation: operation,
                   expect: .imFileDownload,
                   entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customIM(fileBizDomain: .im))
            assert(operation: operation,
                   expect: .imFileDownload,
                   entity: .driveSDK(domain: .imFile, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customIM(fileBizDomain: .ccm))

            assert(operation: operation,
                   expect: .ccmFileDownload,
                   entity: .driveSDK(domain: .openPlatformAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customCCM(fileBizDomain: .unknown))
            assert(operation: operation,
                   expect: .ccmFileDownload,
                   entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .calendar)
            assert(operation: operation,
                   expect: .ccmFileDownload,
                   entity: .driveSDK(domain: .calendarAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .ccm)
            assert(operation: operation,
                   expect: .ccmFileDownload,
                   entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customCCM(fileBizDomain: .mail))
            assert(operation: operation,
                   expect: .ccmFileDownload,
                   entity: .driveSDK(domain: .mailAttachment, fileID: "MOCK_FILE_ID"),
                   bizDomain: .customCCM(fileBizDomain: .mail))
        }
    }

    func testConvertIrrelevantOperation() {
        let irrelevantOperations: [PermissionRequest.Operation] = [
            .applyEmbed,
            .comment,
            .createSubNode,
            .delete,
            .deleteEntity,
            .deleteVersion,
            .edit,
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
            .secretLabelVisible,
            .viewCollaboratorInfo
        ]
        irrelevantOperations.forEach { operation in
            let request = PermissionRequest(token: "MOCK_TOKEN",
                                            type: .docX,
                                            operation: operation,
                                            bizDomain: .ccm,
                                            tenantID: nil)
            let model = SecurityPolicyConverter.convertPolicyModel(request: request, operatorUserID: 0, operatorTenantID: 0)
            XCTAssertNil(model, "operation: \(operation)")
        }
    }

    func testConvertAuthEntity() {
        // 这里重点测 permissionType 的转化，entity 的转换在 SecurityAuditConverter 内单独测
        func assert(operation: EntityOperate,
                    expect: PermissionType,
                    entity: PermissionRequest.Entity = .ccm(token: "MOCK_TOKEN", type: .docX),
                    needKAConvertion: Bool,
                    file: StaticString = #file, line: UInt = #line) {
            let request = PermissionRequest(entity: entity, operation: .export, bizDomain: .ccm)
            let authEntity = SecurityPolicyConverter.convertAuthEntity(request: request,
                                                                       entityOperation: operation,
                                                                       needKAConvertion: needKAConvertion)
            XCTAssertEqual(authEntity.permType, expect, file: file, line: line)
        }

        func batchAssert(entity: PermissionRequest.Entity, expectKAConvertion: Bool, file: StaticString = #file, line: UInt = #line) {
            let expectDownloadType: PermissionType = expectKAConvertion ? .docDownload : .fileDownload
            let expectExportType: PermissionType = expectKAConvertion ? .docExport : .fileExport
            assert(operation: .ccmFileUpload, expect: .fileUpload, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmFileUpload, expect: .fileUpload, entity: entity, needKAConvertion: true, file: file, line: line)
            assert(operation: .ccmAttachmentUpload, expect: .fileUpload, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmAttachmentUpload, expect: .fileUpload, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .ccmFileDownload, expect: .fileDownload, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmFileDownload, expect: expectDownloadType, entity: entity, needKAConvertion: true, file: file, line: line)
            assert(operation: .ccmAttachmentDownload, expect: .fileDownload, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmAttachmentDownload, expect: expectDownloadType, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .ccmExport, expect: .fileExport, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmExport, expect: expectExportType, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .ccmCopy, expect: .fileCopy, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmCopy, expect: .fileCopy, entity: entity, needKAConvertion: true, file: file, line: line)
            assert(operation: .ccmCreateCopy, expect: .fileCopy, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmCreateCopy, expect: .fileCopy, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .ccmFilePreView, expect: .localFilePreview, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmFilePreView, expect: .localFilePreview, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .ccmContentPreview, expect: .docPreviewAndOpen, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmContentPreview, expect: .docPreviewAndOpen, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .ccmMoveRecycleBin, expect: .fileDelete, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .ccmMoveRecycleBin, expect: .fileDelete, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .imFileDownload, expect: .fileDownload, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .imFileDownload, expect: expectDownloadType, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .imFileCopy, expect: .fileCopy, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .imFileCopy, expect: .fileCopy, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .imFilePreview, expect: .localFilePreview, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .imFilePreview, expect: .localFilePreview, entity: entity, needKAConvertion: true, file: file, line: line)

            assert(operation: .imFileRead, expect: .fileRead, entity: entity, needKAConvertion: false, file: file, line: line)
            assert(operation: .imFileRead, expect: .fileRead, entity: entity, needKAConvertion: true, file: file, line: line)
        }

        let noNeedConvertList: [DocsType] = [.file, .wiki, .folder]
        noNeedConvertList.forEach { type in
            batchAssert(entity: .ccm(token: "MOCK_TOKEN", type: type), expectKAConvertion: false)
        }

        let needConvertList: [DocsType] = [.doc, .docX, .sheet, .mindnote, .bitable, .slides]
        needConvertList.forEach { type in
            batchAssert(entity: .ccm(token: "MOCK_TOKEN", type: type), expectKAConvertion: true)
        }

        let driveSDKList: [PermissionRequest.Entity.DriveSDKPermissionDomain] = [
            .imFile, .mailAttachment, .calendarAttachment, .openPlatformAttachment
        ]
        driveSDKList.forEach { domain in
            batchAssert(entity: .driveSDK(domain: domain, fileID: "MOCK_FILE_ID"), expectKAConvertion: false)
        }
    }

    func testConvertPointKey() {
        let convertions: [(EntityOperate, PointKey)] = [
            (.ccmCopy, .ccmCopy),
            (.ccmExport, .ccmExport),
            (.ccmAttachmentDownload, .ccmAttachmentDownload),
            (.ccmAttachmentUpload, .ccmAttachmentUpload),
            (.ccmContentPreview, .ccmContentPreview),
            (.ccmFilePreView, .ccmFilePreView),
            (.ccmCreateCopy, .ccmCreateCopy),
            (.ccmFileUpload, .ccmFileUpload),
            (.ccmFileDownload, .ccmFileDownload),
            (.ccmMoveRecycleBin, .ccmMoveRecycleBin),
            (.imFileDownload, .imFileDownload),
            (.imFileCopy, .imFileCopy),
            (.imFilePreview, .imFilePreview),
            (.imFileRead, .imFileRead)
        ]
        convertions.forEach { (operation, pointKey) in
            let result = SecurityPolicyConverter.convertPointKey(entityOperation: operation)
            XCTAssertEqual(result, pointKey)
        }
    }

    func testConvertDLPResponse() {
        let request = PermissionRequest(token: "MOCK_TOKEN", type: .docX, operation: .createCopy, bizDomain: .ccm, tenantID: nil)
        var result = ValidateResult(userResolver: Container.shared.getCurrentUserResolver(),
                                    result: .deny,
                                    extra: ValidateExtraInfo(resultSource: .dlpDetecting, errorReason: nil))
        var response = Converter.convertDLPResponse(result: result, request: request, maxCostTime: 300, isSameTenant: true)
        response.assertEqual(denyType: .blockByDLPDetecting)
        response.assertEqual(behaviorType: .info(text: BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(5), allowOverrideMessage: false))

        result = ValidateResult(userResolver: Container.shared.getCurrentUserResolver(),
                                result: .deny,
                                extra: ValidateExtraInfo(resultSource: .dlpSensitive, errorReason: nil))
        response = Converter.convertDLPResponse(result: result, request: request, maxCostTime: 300, isSameTenant: true)
        response.assertEqual(denyType: .blockByDLPSensitive)
        response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed, allowOverrideMessage: false))

        result = ValidateResult(userResolver: Container.shared.getCurrentUserResolver(),
                                result: .deny,
                                extra: ValidateExtraInfo(resultSource: .ttBlock, errorReason: nil))
        response = Converter.convertDLPResponse(result: result, request: request, maxCostTime: 300, isSameTenant: true)
        response.assertEqual(denyType: .blockByDLPSensitive)
        response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed, allowOverrideMessage: false))

        result = ValidateResult(userResolver: Container.shared.getCurrentUserResolver(),
                                result: .deny,
                                extra: ValidateExtraInfo(resultSource: .unknown, errorReason: nil))
        response = Converter.convertDLPResponse(result: result, request: request, maxCostTime: 300, isSameTenant: true)
        response.assertEqual(denyType: .blockByDLPSensitive)
        response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed, allowOverrideMessage: false))
    }

    func testDLPErrorMessage() {
        XCTAssertEqual(Converter.errorMessage(source: .dlpDetecting,
                                              operation: .copyContent,
                                              maxCostTime: 300,
                                              isSameTenant: true),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(5))

        XCTAssertEqual(Converter.errorMessage(source: .dlpDetecting,
                                              operation: .copyContent,
                                              maxCostTime: 300,
                                              isSameTenant: false),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(5))

        XCTAssertEqual(Converter.errorMessage(source: .dlpDetecting,
                                              operation: .copyContent,
                                              maxCostTime: 600,
                                              isSameTenant: true),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(10))

        XCTAssertEqual(Converter.errorMessage(source: .dlpDetecting,
                                              operation: .createCopy,
                                              maxCostTime: 600,
                                              isSameTenant: true),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(10))

        XCTAssertEqual(Converter.errorMessage(source: .ttBlock,
                                              operation: .copyContent,
                                              maxCostTime: 300,
                                              isSameTenant: true),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_CopyFailed_Toast)

        XCTAssertEqual(Converter.errorMessage(source: .ttBlock,
                                              operation: .copyContent,
                                              maxCostTime: 300,
                                              isSameTenant: false),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_CopyFailed_Toast)

        XCTAssertEqual(Converter.errorMessage(source: .ttBlock,
                                              operation: .copyContent,
                                              maxCostTime: 600,
                                              isSameTenant: true),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_CopyFailed_Toast)

        XCTAssertEqual(Converter.errorMessage(source: .ttBlock,
                                              operation: .createCopy,
                                              maxCostTime: 600,
                                              isSameTenant: true),
                          BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed)

        XCTAssertNotEqual(Converter.errorMessage(source: .ttBlock,
                                              operation: .createCopy,
                                              maxCostTime: 600,
                                              isSameTenant: true),
                          BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed)

        XCTAssertEqual(Converter.errorMessage(source: .dlpSensitive,
                                              operation: .copyContent,
                                              maxCostTime: 300,
                                              isSameTenant: true),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed)

        XCTAssertEqual(Converter.errorMessage(source: .dlpSensitive,
                                              operation: .copyContent,
                                              maxCostTime: 300,
                                              isSameTenant: false),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed)

        XCTAssertEqual(Converter.errorMessage(source: .dlpSensitive,
                                              operation: .copyContent,
                                              maxCostTime: 600,
                                              isSameTenant: true),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed)

        XCTAssertEqual(Converter.errorMessage(source: .dlpSensitive,
                                              operation: .createCopy,
                                              maxCostTime: 600,
                                              isSameTenant: true),
                       BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed)

        let otherSources: [ValidateSource] = [.unknown, .fileStrategy, .securityAudit]
        otherSources.forEach { source in
            XCTAssertEqual(Converter.errorMessage(source: source,
                                                  operation: .copyContent,
                                                  maxCostTime: 300,
                                                  isSameTenant: true),
                           BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed)

            XCTAssertEqual(Converter.errorMessage(source: source,
                                                  operation: .copyContent,
                                                  maxCostTime: 300,
                                                  isSameTenant: false),
                           BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed)

            XCTAssertEqual(Converter.errorMessage(source: source,
                                                  operation: .copyContent,
                                                  maxCostTime: 600,
                                                  isSameTenant: true),
                           BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed)

            XCTAssertEqual(Converter.errorMessage(source: source,
                                                  operation: .createCopy,
                                                  maxCostTime: 600,
                                                  isSameTenant: true),
                           BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed)
        }
    }

    func testIsDLPRelevantOperations() {
        UserScopeNoChangeFG.setMockFG(key: "lark.security.ccm_dlp_migrate", value: true)
        let relevantOperations: [PermissionRequest.Operation] = [
            .copyContent,
            .export,
            .download,
            .openWithOtherApp,
            .save,
            .downloadAttachment,
            .shareToExternal
        ]
        relevantOperations.forEach { operation in
            let request = PermissionRequest(token: "MOCK_TOKEN",
                                            type: .bitable,
                                            operation: operation,
                                            bizDomain: .ccm,
                                            tenantID: nil)
            guard let model = Converter.convertPolicyModel(request: request, operatorUserID: 100, operatorTenantID: 100) else {
                XCTFail("convert model failed for operation: \(operation)")
                return
            }
            guard let entity = model.entity as? CCMEntity else {
                XCTFail("model no CCMEntity for operation: \(operation)")
                return
            }
            XCTAssertEqual(entity.token, "MOCK_TOKEN")
            XCTAssertEqual(entity.tokenEntityType, .bitable)
        }
        relevantOperations.forEach { operation in
            let request = PermissionRequest(entity: .ccm(token: "MOCK_TOKEN",
                                                         type: .bitable,
                                                         parentMeta: SpaceMeta(objToken: "MOCK_PARENT_TOKEN",
                                                                               objType: .docX)),
                                            operation: operation,
                                            bizDomain: .ccm)
            guard let model = Converter.convertPolicyModel(request: request, operatorUserID: 100, operatorTenantID: 100) else {
                XCTFail("convert model failed for operation: \(operation)")
                return
            }
            guard let entity = model.entity as? CCMEntity else {
                XCTFail("model no CCMEntity for operation: \(operation)")
                return
            }
            XCTAssertEqual(entity.token, "MOCK_PARENT_TOKEN")
            XCTAssertEqual(entity.tokenEntityType, .docx)
        }
    }
}
