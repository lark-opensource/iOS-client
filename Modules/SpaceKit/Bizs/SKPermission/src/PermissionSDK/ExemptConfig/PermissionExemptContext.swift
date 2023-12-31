//
//  PermissionExemptContext.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import SKFoundation
import SpaceInterface

struct PermissionExemptContext: Equatable {

    static let all: [PermissionExemptScene: PermissionExemptContext] = setupExemptContexts()

    static subscript(key: PermissionExemptScene) -> PermissionExemptContext {
        get {
            all[key]!
        }
    }

    let operation: PermissionRequest.Operation
    let bizDomain: PermissionRequest.BizDomain
    let rules: PermissionExemptRules

    private static func setupExemptContexts() -> [PermissionExemptScene: PermissionExemptContext] {
        let contexts: [PermissionExemptScene: PermissionExemptContext] = [
            .duplicateSystemTemplate:
                    .init(operation: .createCopy,
                          bizDomain: .ccm,
                          rules: .userPermissionOnly),
            .useTemplateButtonEnable:
                    .init(operation: .createCopy,
                          bizDomain: .ccm,
                          rules: PermissionExemptRules(shouldCheckDLP: false)),
            .driveAttachmentMoreVisable:
                    .init(operation: .downloadAttachment,
                          bizDomain: .ccm,
                          rules: .userPermissionOnly),
            .downloadDocumentImageAttachmentWithDLP:
                    .init(operation: .downloadAttachment,
                          bizDomain: .ccm,
                          rules: PermissionExemptRules(shouldCheckFileStrategy: false,
                                                       shouldCheckDLP: true,
                                                       shouldCheckSecurityAudit: false,
                                                       shouldCheckUserPermission: false)),
            .viewSpaceFolder:
                    .init(operation: .view,
                          bizDomain: .ccm,
                          rules: PermissionExemptRules(shouldCheckFileStrategy: false,
                                                       shouldCheckDLP: false,
                                                       shouldCheckSecurityAudit: false, shouldCheckUserPermission: true)),
            .dlpBannerVisable:
                    .init(operation: .shareToExternal,
                          bizDomain: .ccm,
                          rules: PermissionExemptRules(shouldCheckSecurityAudit: false))
        ]
        spaceAssert(contexts.count == PermissionExemptScene.allCases.count, "count of exempt countexts not equal to count of exempt scenes")
        return contexts
    }
}

extension PermissionRequest {

    init(entity: PermissionRequest.Entity, exemptScene: PermissionExemptScene, extraInfo: PermissionExtraInfo) {
        // 这里通过单测保证一定能根据 scene 取到 context
        let context = PermissionExemptContext.all[exemptScene]!
        self.init(entity: entity,
                  operation: context.operation,
                  bizDomain: context.bizDomain,
                  extraInfo: extraInfo,
                  exemptConfig: context.rules)
    }
}

