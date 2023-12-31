//
//  DLPManagerTest.swift
//  LarkSecurityCompliance-Unit-Tests
//
//  Created by ByteDance on 2023/8/24.
//

import XCTest
@testable import LarkSecurityCompliance
import LarkContainer
import LarkSecurityComplianceInterface

final class DLPManagerTest: XCTestCase {
    
    let dlpManager: DLPManager? = try? DLPManager(resolver: Container.shared.getCurrentUserResolver())
    
    func testExample() throws {
        let userId: Int64 = 111
        let ccmCopyModel = PointCutOperate.ccmContentCopy(entityType: .doc,
                                                          operateTenantId: userId,
                                                          operateUserId: userId,
                                                          token: "dddddddd",
                                                          ownerTenantId: 1111,
                                                          ownerUserId: 11_111).asModel()
        let ccmContentPreviewModel = PointCutOperate.ccmContentPreview(entityType: .sheet, operateTenantId: userId, operateUserId: userId).asModel()
        let ccmFileDownload = PointCutOperate.ccmFileDownload(entityType: .file,
                                                              operateTenantId: 111,
                                                              operateUserId: userId,
                                                              token: "ccccc",
                                                              ownerTenantId: 22_222,
                                                              ownerUserId: 2222).asModel()
        let ccmExport = PointCutOperate.ccmExport(entityType: .docx,
                                                  operateTenantId: 111,
                                                  operateUserId: userId,
                                                  token: "ccccc",
                                                  ownerTenantId: 22_222,
                                                  ownerUserId: 2222).asModel()
        let ccmOpenExternalAccess = PointCutOperate.ccmOpenExternalAccess(entityType: .bitable,
                                                                          operateTenantId: 111,
                                                                          operateUserId: userId,
                                                                          token: "ccccc",
                                                                          ownerTenantId: 22_222,
                                                                          ownerUserId: 2222,
                                                                          tokenEntityType: .sheet).asModel()
        let policyModels: [PolicyModel] = [
            ccmCopyModel,
            ccmContentPreviewModel,
            ccmFileDownload,
            ccmExport,
            ccmOpenExternalAccess
        ]
        
        let mappedPolicyModels = dlpManager?.associatePolicyModels(policyModels: policyModels)
        guard let mappedPolicyModels else { return }
        guard let firtstModel = mappedPolicyModels.first else { return }
        XCTAssertEqual(firtstModel.getToken(), ccmCopyModel.getToken())
        XCTAssertEqual(firtstModel.pointKey, .ccmCopyObject)
        XCTAssertFalse(mappedPolicyModels.contains(where: { model in
            model.pointKey == .ccmContentPreview
        }))
        guard let lastModel = mappedPolicyModels.last else { return }
        XCTAssertEqual(lastModel.entity.entityType, .sheet)
    }
}
