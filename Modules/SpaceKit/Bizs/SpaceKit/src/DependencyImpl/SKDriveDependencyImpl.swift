//
//  SKDriveDependencyImpl.swift
//  SpaceKit
//
//  Created by lijuyou on 2021/1/14.
//  


import Foundation
import SKCommon
import SKBrowser
import SKDrive
import SKWikiV2
import SpaceInterface
import SKInfra
import SKWorkspace
import LarkContainer
import SKFoundation

class SKDriveDependencyImpl: SKDriveDependency {
    func createMoreDataProvider(context: SKDrive.DriveMoreDataProviderContext) -> SKDrive.DriveMoreDataProviderType {
        return DriveMoreDataProvider(docsInfo: context.docsInfo,
                                     feedId: context.feedId,
                                     fileType: context.fileType,
                                     fileSize: context.fileSize,
                                     isFromWiki: context.isFromWiki,
                                     hostViewController: context.hostViewController,
                                     userPermissions: context.userPermissions,
                                     permissionService: context.permissionSerivce,
                                     publicPermissionMeta: context.publicPermissionMeta,
                                     outsideControlItems: context.outsideControlItems,
                                     followAPIDelegate: context.followAPIDelegate)
    }
    
    func makeShareViewControllerV2(context: SKDrive.DriveShareVCContext) -> UIViewController {
        let shareVC = SKShareViewController(context.shareEntity,
                                            delegate: context.delegate,
                                            router: context.router,
                                            source: context.source,
                                            isInVideoConference: context.isInVideoConference)
        shareVC.watermarkConfig.needAddWatermark = context.shouldShowWatermark
        return shareVC
    }
    
    func getWikiInfo(by wikiToken: String) -> WikiInfo? {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        
        guard let wikiSrtorageAPI = try? userResolver.resolve(assert: WikiStorageBase.self) else {
            return nil
        }
        return wikiSrtorageAPI.getWikiInfo(by: wikiToken)
    }
}
