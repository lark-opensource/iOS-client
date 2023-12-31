//
//  DKIMMainVMDependencyImpl.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/14.
//

import Foundation
import SpaceInterface
import RxSwift
import RxRelay

struct DKIMFileDependencyImpl: DKIMFileDependency {
    let appID: String
    let onlineFile: DriveSDKIMFile
    let fileInfoProvider: DKDefaultFileInfoProvider
    let reachabilityRelay: BehaviorRelay<Bool>
    let cacheService: DKCacheServiceProtocol
    let saveService: DKSaveToSpaceService
    let moreConfiguration: DriveSDKMoreDependency
    let actionProvider: DriveSDKActionDependency
    let statistics: DKStatisticsService
    let performanceRecorder: DrivePerformanceRecorder
}

struct DKLocalFileDependencyImpl: DKLocalFileDependency {
    var statistics: DKStatisticsService
    var performanceRecorder: DrivePerformanceRecorder
    var appID: String
    var thirdPartyAppID: String?
    var localFile: DriveSDKLocalFileV2
    var moreConfiguration: DriveSDKMoreDependency
    var actionProvider: DriveSDKActionDependency
    
    init(localFile: DriveSDKLocalFileV2,
         appID: String,
         thirdPartyAppID: String?,
         statistics: DKStatisticsService,
         performanceRecorder: DrivePerformanceRecorder,
         moreConfiguration: DriveSDKMoreDependency,
         actionProvider: DriveSDKActionDependency) {
        self.localFile = localFile
        self.appID = appID
        self.thirdPartyAppID = thirdPartyAppID
        self.statistics = statistics
        self.performanceRecorder = performanceRecorder
        self.moreConfiguration = moreConfiguration
        self.actionProvider = actionProvider
    }
}

struct DKAttachentDependencyImpl: DKAttachmentFileDependency {
    var isInVCFollow: Bool
    var canImportAsOnlineFile: Bool
    var appID: String
    var file: DriveSDKAttachmentFile
    var cacheService: DKCacheServiceProtocol
    var permissionHelper: DrivePermissionHelperProtocol
    var moreConfiguration: DriveSDKMoreDependency
    var actionProvider: DriveSDKActionDependency
    var statistics: DKStatisticsService
    var performanceRecorder: DrivePerformanceRecorder
    
    init(file: DriveSDKAttachmentFile,
         appID: String,
         statistics: DKStatisticsService,
         performanceRecorder: DrivePerformanceRecorder,
         permissionHelper: DrivePermissionHelperProtocol,
         isInVCFollow: Bool,
         canImportAsOnlineFile: Bool,
         moreConfiguration: DriveSDKMoreDependency,
         actionProvider: DriveSDKActionDependency) {
        self.file = file
        self.appID = appID
        self.statistics = statistics
        self.performanceRecorder = performanceRecorder
        self.permissionHelper = permissionHelper
        self.cacheService = DriveCacheServiceImpl(fileToken: file.fileToken)
        self.isInVCFollow = isInVCFollow
        self.canImportAsOnlineFile = canImportAsOnlineFile
        self.moreConfiguration = moreConfiguration
        self.actionProvider = actionProvider
    }
}
