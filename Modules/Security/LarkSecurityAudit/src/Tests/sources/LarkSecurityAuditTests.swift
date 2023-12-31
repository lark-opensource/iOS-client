//
//  LarkSecurityAuditTests.swift
//  LarkSecurityAuditTests-Unit-Tests
//
//  Created by wangxijing on 2022/8/15.
//

import XCTest
@testable import LarkSecurityAudit
import ServerPB
import LarkContainer
import AppContainer
import LarkAccountInterface

class LarkSecurityAuditTests: XCTestCase {
    private static var securityAuditModel: LarkSecurityAuditTestsModel?
    private static var securityAudit: SecurityAuditManager?

    override class func setUp() {
        Self.securityAuditModel = LarkSecurityAuditTestsModel()
        Self.securityAudit = securityAuditModel?.securityAudit
    }

    func testString() {
        // test subString
        let string: String = "Hello"
        XCTAssertNil(string.subString(firstIndex: 0, length: 0))
        XCTAssertNil(string.subString(firstIndex: 1, length: 10))
        XCTAssertNil(string.subString(firstIndex: 10, length: 1))
        XCTAssertEqual(string.subString(firstIndex: 1, length: 3), Optional("ell"))
        // test appendPath
        let originString = "https://www.baidu.com"
        XCTAssertEqual(originString.appendPath(""), "https://www.baidu.com")
        XCTAssertEqual(originString.appendPath("", addLastSlant: true), "https://www.baidu.com/")
        XCTAssertEqual(originString.appendPath("board"), "https://www.baidu.com/board")
        XCTAssertEqual(originString.appendPath("/board"), "https://www.baidu.com/board")
        let originStringWithLastSlant = "https://www.baidu.com/"
        XCTAssertEqual(originStringWithLastSlant.appendPath("board"), "https://www.baidu.com/board")
        XCTAssertEqual(originStringWithLastSlant.appendPath("/board", addLastSlant: true), "https://www.baidu.com/board/")
    }

    func testCheckPermission() {
        Self.securityAuditModel?.updateData()
        guard let securityAudit = Self.securityAudit else { return }
        let result = securityAudit.checkAuthorityFromPermissionMap(PermissionType.fileUpload)
        XCTAssertEqual(result, AuthResult.allow)

        var entity = CustomizedEntity()
        entity.entityType = "ccmFile"
        entity.id = "baike"
        let baikeResult = securityAudit.checkAuthorityFromPermissionMap(PermissionType.baikeRepoView, object: entity)
        print("test2")
        XCTAssertEqual(baikeResult, AuthResult.deny)
    }

    func testMergeResponse() {
        Self.securityAuditModel?.updateData()
        guard let securityAudit = Self.securityAudit, let securityAuditModel = Self.securityAuditModel else { return }
        let result = securityAudit.checkAuthorityFromPermissionMap(PermissionType.fileUpload)
        XCTAssertEqual(result, AuthResult.allow)
        // test merge response
        let tempResponse = securityAuditModel.constructPermissionResponse(operationPermissionMap: [
            PermissionType.fileUpload: ResultType.deny,
            PermissionType.fileImport: ResultType.allow,
            PermissionType.fileDownload: ResultType.null
        ], extendPermissionMap: [
            PermissionType.localFileShare: ResultType.deny,
            PermissionType.docPreviewAndOpen: ResultType.allow,
            PermissionType.privacyGpsLocation: ResultType.null
        ], customPermissionMap: [.baikeRepoView: ResultType.allow])

        securityAudit.pullPermissionService?.mergeData(tempResponse)
        let resultAfterMerge = securityAudit.checkAuthorityFromPermissionMap(PermissionType.fileUpload)
        XCTAssertEqual(resultAfterMerge, AuthResult.deny)
    }

    func testClearPermission() {
        Self.securityAuditModel?.updateData()
        guard let securityAudit = Self.securityAudit else { return }
        securityAudit.pullPermissionService?.clearIPPermissionData()
        // 验证权限结果不被清理的
        let result = securityAudit.checkAuthorityFromPermissionMap(PermissionType.mobilePasteProtection)
        XCTAssertEqual(result, AuthResult.deny)
        // 验证权限结果被清理的
        let fileUploadResult = securityAudit.checkAuthorityFromPermissionMap(PermissionType.fileUpload)
        XCTAssertEqual(fileUploadResult, AuthResult.error)
    }

    func testGetStrictMode() {
        Self.securityAuditModel?.updateData()
        guard let securityAudit = Self.securityAudit, var permResponse = Self.securityAudit?.pullPermissionService?.permissionResponse else { return }
        let fgInfoMap: [ServerPB_Authorization_FeatureGateType: Bool] = [
            .featureGateFile: false,
            .featureGatePrivacy: false,
            .featureGatePasteProtection: false,
            .featureGateScreenProtection: false
        ]
        var featureGateInfo: [ServerPB_Authorization_FeatureGateInfo] = []
        for (key, value) in fgInfoMap {
            var fgInfo = ServerPB_Authorization_FeatureGateInfo()
            fgInfo.fgType = key
            fgInfo.isOpen = value
            featureGateInfo.append(fgInfo)
        }
        permResponse.permissionExtra.featureGateInfos = featureGateInfo
        securityAudit.pullPermissionService?.getStrictAuthMode(resp: permResponse)
        XCTAssertFalse(SecurityAuditManager.shared.strictAuthModeCache)
    }
}
