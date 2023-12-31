//
//  DriveSDKFileHandler.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/24.
//

import Foundation
import SpaceInterface
import EENavigator
import LarkContainer
import SKCommon
import UniverseDesignToast
import SKResource
import SKInfra

class DriveSDKLocalFileHandler: TypedRouterHandler<DriveSDKLocalFileBody> {
    override func handle(_ body: DriveSDKLocalFileBody, req: EENavigator.Request, res: Response) {
        let controller = DocsContainer.shared.resolve(DriveSDK.self)!.createLocalFileController(localFiles: body.files,
                                                                                                   index: body.index,
                                                                                                   appID: body.appID,
                                                                                                   thirdPartyAppID: body.thirdPartyAppID,
                                                                                                   naviBarConfig: body.naviBarConfig)

        res.end(resource: controller)
    }
}

class DriveSDKThirdPartyFileHandler: TypedRouterHandler<DriveSDKAttachmentFileBody> {
    override func handle(_ body: DriveSDKAttachmentFileBody, req: EENavigator.Request, res: Response) {
        // Drive 是否启用
        guard DriveFeatureGate.driveEnabled else {
            if let vc = req.from.fromViewController {
                UDToast.showTips(with: BundleI18n.SKResource.Drive_Drive_FileSecurityRestrictDownloadActionGeneralMessage,
                                 on: vc.view)
            }
            res.end(error: nil)
            return
        }
        let controller = DocsContainer.shared.resolve(DriveSDK.self)!.createAttachmentFileController(attachFiles: body.files,
                                                                                                     index: body.index,
                                                                                                     appID: body.appID,
                                                                                                     isCCMPermission: body.isCCMPremission,
                                                                                                     tenantID: body.tenantID,
                                                                                                     isInVCFollow: body.isInVCFollow,
                                                                                                     attachmentDelegate:
                                                                                                        body.attachmentDelegate,
                                                                                                     naviBarConfig: body.naviBarConfig)

        res.end(resource: controller)
    }
}

class DriveSDKIMFileHandler: TypedRouterHandler<DriveSDKIMFileBody> {
    override func handle(_ body: DriveSDKIMFileBody, req: EENavigator.Request, res: Response) {
        let controller = DocsContainer.shared.resolve(DriveSDK.self)!.createIMFileController(imFile: body.file,
                                                                                             appID: body.appID,
                                                                                             naviBarConfig: body.naviBarConfig)
        res.end(resource: controller)
    }
}
