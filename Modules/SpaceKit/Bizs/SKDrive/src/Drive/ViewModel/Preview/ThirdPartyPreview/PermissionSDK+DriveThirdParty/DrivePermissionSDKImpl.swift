//
//  DrivePermissionSDKImpl.swift
//  SKDrive
//
//  Created by Weston Wu on 2023/10/30.
//

import Foundation
import SpaceInterface
import SKCommon

class DrivePermissionSDKImpl: DrivePermissionSDK {

    let permissionSDK: PermissionSDK

    init(permissionSDK: PermissionSDK) {
        self.permissionSDK = permissionSDK
    }

    func attachmentUserPermissionService(fileToken: String,
                                         mountPoint: String,
                                         authExtra: String?,
                                         bizDomain: PermissionRequest.BizDomain) -> UserPermissionService {
        let userID = User.current.info?.userID ?? ""
        let cache = DriveThirdPartyAttachmentPermissionCache(userID: userID)
        let sessionID = UUID().uuidString
        let api = DriveThirdPartyAttachmentPermissionAPI(fileToken: fileToken,
                                                         mountPoint: mountPoint,
                                                         authExtra: authExtra,
                                                         sessionID: sessionID,
                                                         cache: cache)
        let validatorType = DriveThirdPartyAttachmentPermissionValidator.self
        let service = permissionSDK.driveSDKCustomUserPermissionService(permissionAPI: api,
                                                                        validatorType: validatorType,
                                                                        tokenForDLP: fileToken,
                                                                        bizDomain: bizDomain,
                                                                        sessionID: sessionID)
        return service
    }
    

}
