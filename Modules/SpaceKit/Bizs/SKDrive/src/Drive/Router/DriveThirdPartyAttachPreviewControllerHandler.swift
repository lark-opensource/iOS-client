//
//  DriveThirdPartyAttachPreviewControllerHandler.swift
//  SKECM
//
//  Created by bupozhuang on 2021/4/29.
//

import Foundation
import SpaceInterface
import EENavigator
import LarkContainer

class DriveThirdPartyAttachPreviewControllerHandler: TypedRouterHandler<DriveThirdPartyAttachControllerBody> {
    override func handle(_ body: DriveThirdPartyAttachControllerBody, req: EENavigator.Request, res: Response) {
        let previewController = DriveVCFactory.shared.makeDriveThirdPartyPreview(files: body.files,
                                                                                   index: body.index,
                                                                                   moreActions: body.actions,
                                                                                   isInVCFollow: body.isInVCFollow,
                                                                                   bussinessId: body.bussinessId)
        res.end(resource: previewController)
    }
}
