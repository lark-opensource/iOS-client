//
//  PublicPermissionViewControllerManager.swift
//  SKCommon
//
//  Created by tanyunpeng on 2023/8/24.
//  


import Foundation
import SpaceInterface
import SKCommon
import SKFoundation
import SKInfra

public struct PublicPermissionViewControllerManager {
    
    
    public static func getPublicPermissionController(docsInfo: DocsInfo, followAPIDelegate: BrowserVCFollowDelegate?, isMyWindowRegularSizeInPad: Bool, permStatistics: PermissionStatistics, url: String) -> PublicPermissionLynxController {
        let wikiV2SingleContainer = docsInfo.isFromWiki
        let spaceSingleContainer = (docsInfo.ownerType == 5)
        let fileModel = PublicPermissionFileModel(objToken: docsInfo.objToken,
                                                  wikiToken: docsInfo.wikiInfo?.wikiToken,
                                                  type: ShareDocsType(rawValue: docsInfo.type.rawValue),
                                                  fileType: docsInfo.fileType ?? "",
                                                  ownerID: docsInfo.ownerID ?? "",
                                                  tenantID: docsInfo.tenantID ?? "",
                                                  createTime: docsInfo.createTime ?? 0,
                                                  createDate: docsInfo.createDate ?? "",
                                                  createID: docsInfo.creatorID ?? "",
                                                  wikiV2SingleContainer: wikiV2SingleContainer,
                                                  wikiType: docsInfo.inherentType,
                                                  spaceSingleContainer: spaceSingleContainer)
        let permissionVC = PublicPermissionLynxController(token: docsInfo.objToken,
                                                      type: ShareDocsType(rawValue: docsInfo.type.rawValue),
                                                      isSpaceV2: spaceSingleContainer,
                                                      isWikiV2: wikiV2SingleContainer,
                                                      needCloseButton: isMyWindowRegularSizeInPad,
                                                      fileModel: fileModel,
                                                      permStatistics: permStatistics,
                                                      dlpDialogUrl: url,
                                                      followAPIDelegate: followAPIDelegate)
        return permissionVC
    }
    
}
