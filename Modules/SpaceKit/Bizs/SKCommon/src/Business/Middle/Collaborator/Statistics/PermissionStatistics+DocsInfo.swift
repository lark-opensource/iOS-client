//
//  PermissionStatistics+DocsInfo.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/12/2.
//

import Foundation
import SKInfra

extension PermissionStatistics {

    public class func getReporterWith(docsInfo: DocsInfo?) -> PermissionStatistics? {
        let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: docsInfo?.objToken ?? "")
        let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: docsInfo?.objToken ?? "")
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo?.encryptedObjToken ?? "",
                                                      fileType: docsInfo?.type.name ?? "",
                                                      appForm: (docsInfo?.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo?.fileType,
                                                      module: docsInfo?.type.name ?? "",
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        return permStatistics
    }
}
