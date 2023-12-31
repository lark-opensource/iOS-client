//
//  LarkSecurityAuditTestsModel.swift
//  LarkSecurityAudit-Unit-Tests
//
//  Created by ByteDance on 2023/6/13.
//

import Foundation
@testable import LarkSecurityAudit
import ServerPB
import LarkContainer

struct LarkSecurityAuditTestsModel {
    var securityAudit: SecurityAuditManager

    init() {
        let resolver = Container.shared.getCurrentUserResolver()
        securityAudit = SecurityAuditManager.shared
        securityAudit.pullPermissionService = PullPermissionService(resolver: resolver)
    }

    func updateData() {
        let response = constructPermissionResponse()
        securityAudit.pullPermissionService?.mergeData(response)
        securityAudit.pullPermissionService?.getStrictAuthMode(resp: response)
    }

    private func constructPermissionResponse() -> ServerPB_Authorization_PullPermissionResponse {
        let operatePermissionsMap: [ServerPB_Authorization_PermissionType: ServerPB_Authorization_ResultType] = [
            .fileUpload: .allow,
            .fileImport: .null,
            .fileDownload: .deny,
            .fileExport: .allow,
            .filePrint: .allow,
            .fileAppOpen: .deny,
            .fileAccessFolder: .allow,
            .fileRead: .deny,
            .fileEdit: .allow,
            .fileComment: .deny,
            .fileCopy: .allow,
            .fileDelete: .deny,
            .fileShare: .null,
            .search: .allow
        ]
        let extendPermissionMap: [ServerPB_Authorization_PermissionType: ServerPB_Authorization_ResultType] = [
            .localFileShare: .allow,
            .docPreviewAndOpen: .deny,
            .privacyGpsLocation: .allow,
            .pcPasteProtection: .deny,
            .webPasteProtection: .allow,
            .mobilePasteProtection: .deny,
            .mobileScreenProtect: .allow,
            .pcScreenProtect: .allow,
            .docDownload: .deny,
            .docExport: .deny,
            .docPrint: .allow
        ]
        let customPermissionMap: [ServerPB_Authorization_PermissionType: ServerPB_Authorization_ResultType] = [.baikeRepoView: .deny]
        return constructPermissionResponse(operationPermissionMap: operatePermissionsMap, extendPermissionMap: extendPermissionMap, customPermissionMap: customPermissionMap)
    }

    func constructPermissionResponse(operationPermissionMap: [PermissionType: ResultType],
                                             extendPermissionMap: [PermissionType: ResultType], customPermissionMap: [PermissionType: ResultType],
                                             clearOld: Bool = false) -> ServerPB_Authorization_PullPermissionResponse {
        var permissionsData = ServerPB_Authorization_AllPermissionData()
        permissionsData.updateTime = Int64(Date().timeIntervalSince1970)
        permissionsData.expireTime = Int64(SecurityAuditManager.ntpTime) + 60 * 60 * 1000
        permissionsData.operatePermissionData = getOperatePermissions(operationPermissionMap)
        permissionsData.extendedOperatePermissionData = getExtendOperatePermissions(extendPermissionMap)
        permissionsData.customizedOperatePermissionData = getCustomOperatePermissions(customPermissionMap)
        var permissionsResponse = ServerPB_Authorization_PullPermissionResponse()
        permissionsResponse.permissionData = permissionsData
        permissionsResponse.clearOld_p = true
        permissionsResponse.permVersion = "1-1-1"
        var extraInfo = ServerPB_Authorization_PermissionExtra()
        extraInfo.featureGateInfos = getFeatureInfo()
        extraInfo.permissionTypeInfos = getPermissionTypeInfo()
        permissionsResponse.permissionExtra = extraInfo
        return permissionsResponse
    }

    private func getOperatePermissions(_ operatePermissionsMap: [PermissionType: ResultType]) -> [ServerPB_Authorization_OperatePermission] {
        var operationPermissions: [ServerPB_Authorization_OperatePermission] = []
        for (key, value) in operatePermissionsMap {
            var operationPermission = ServerPB_Authorization_OperatePermission()
            operationPermission.permType = key
            operationPermission.result = value
            var entity = Entity()
            entity.entityType = .any
            operationPermission.object = entity
            operationPermissions.append(operationPermission)
        }
        return operationPermissions
    }

    private func getExtendOperatePermissions(_ extendPermissionMap: [PermissionType: ResultType]) -> [ServerPB_Authorization_ExtendedOperatePermission] {
        var operationPermissions: [ServerPB_Authorization_ExtendedOperatePermission] = []
        for (key, value) in extendPermissionMap {
            var operationPermission = ServerPB_Authorization_ExtendedOperatePermission()
            operationPermission.permType = key
            operationPermission.result = value
            var entity = Entity()
            entity.entityType = .any
            operationPermission.object = entity
            operationPermissions.append(operationPermission)
        }
        return operationPermissions
    }

    private func getCustomOperatePermissions(_ customPermissionMap: [PermissionType: ResultType]) -> [ServerPB_Authorization_CustomizedOperatePermission] {
        var operationPermissions: [ServerPB_Authorization_CustomizedOperatePermission] = []
        for (key, value) in customPermissionMap {
            var operationPermission = ServerPB_Authorization_CustomizedOperatePermission()
            operationPermission.permType = key
            operationPermission.result = value
            var entity = CustomizedEntity()
            entity.id = "baike"
            entity.entityType = "ccmFile"
            operationPermission.object = entity
            operationPermissions.append(operationPermission)
        }
        return operationPermissions
    }

    private func getFeatureInfo() -> [ServerPB_Authorization_FeatureGateInfo] {
        let fgInfoMap: [ServerPB_Authorization_FeatureGateType: Bool] = [
            .featureGateFile: true,
            .featureGatePrivacy: false,
            .featureGatePasteProtection: true,
            .featureGateScreenProtection: false
        ]
        var featureGateInfo: [ServerPB_Authorization_FeatureGateInfo] = []
        for (key, value) in fgInfoMap {
            var fgInfo = ServerPB_Authorization_FeatureGateInfo()
            fgInfo.fgType = key
            fgInfo.isOpen = value
            featureGateInfo.append(fgInfo)
        }
        return featureGateInfo
    }

    private func getPermissionTypeInfo() -> [ServerPB_Authorization_PermissionTypeInfo] {
        let permissionTypeInfoMap: [ServerPB_Authorization_PermissionType: Bool] = [
            .fileUpload: true,
            .fileImport: true,
            .fileDownload: true,
            .fileExport: true,
            .filePrint: true,
            .fileAppOpen: true,
            .fileAccessFolder: true,
            .fileRead: true,
            .fileEdit: true,
            .fileComment: true,
            .fileCopy: true,
            .fileDelete: true,
            .fileShare: true,
            .search: true,
            .localFileShare: true,
            .docPreviewAndOpen: true,
            .privacyGpsLocation: true,
            .pcPasteProtection: true,
            .webPasteProtection: false,
            .mobilePasteProtection: false,
            .mobileScreenProtect: false,
            .pcScreenProtect: false,
            .docDownload: false,
            .docExport: true,
            .docPrint: true,
            .baikeRepoView: false
        ]
        var permissionTypeInfo = [ServerPB_Authorization_PermissionTypeInfo]()
        for (key, value) in permissionTypeInfoMap {
            var permInfo = ServerPB_Authorization_PermissionTypeInfo()
            permInfo.permType = key
            permInfo.forceClear = value
            permissionTypeInfo.append(permInfo)
        }
        return permissionTypeInfo
    }
}
