//
//  SKDriveDependency.swift
//  SKDrive
//
//  Created by lijuyou on 2021/1/14.
//  


import Foundation
import SKCommon
import SpaceInterface

public struct DriveMoreDataProviderContext {
    public let docsInfo: DocsInfo
    public let feedId: String?
    public let fileType: String?
    public let fileSize: Int64
    public let isFromWiki: Bool
    public let hostViewController: UIViewController
    public let permissionSerivce: UserPermissionService
    public let userPermissions: UserPermissionAbility?
    public let publicPermissionMeta: PublicPermissionMeta?
    public let outsideControlItems: MoreDataOutsideControlItems?
    public let followAPIDelegate: SpaceFollowAPIDelegate?
}

public struct DriveShareVCContext {
    public let shareEntity: SKShareEntity
    public let hostViewController: UIViewController
    public let delegate: ShareViewControllerDelegate?
    public let router: ShareRouterAbility
    public let source: ShareSource
    public let isInVideoConference: Bool
    public let shouldShowWatermark: Bool
}

public protocol SKDriveDependency {
    func createMoreDataProvider(context: DriveMoreDataProviderContext) -> DriveMoreDataProviderType
    
    func makeShareViewControllerV2(context: DriveShareVCContext) -> UIViewController
    
    func getWikiInfo(by wikiToken: String) -> WikiInfo?
}
