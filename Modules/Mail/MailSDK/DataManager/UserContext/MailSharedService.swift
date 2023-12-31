//
//  MailSharedServices.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/11/3.
//

import Foundation
import EENavigator

/// MailUserContext 与 MailAccountContext 通用的服务
final class MailSharedServices {
    let user: User
    let navigator: Navigatable
    let userKVStore: MailKVStore
    let dataService: DataService
    let provider: ServiceProvider
    let profileRouter: ProfileRouter
    let editorLoader: MailEditorLoader
    let cacheService: MailCacheService
    let imageService: MailImageService
    let securityAudit: MailSecurityAudit
    let alertHelper: MailClientAlertHelper
    let featureManager: UserFeatureManager
    let messageListPreloader: MailMessageListUnreadPreloader
    let preloadServices: MailPreloadServicesProtocol
    let preloadCacheManager: MailPreloadCacheManager
    let driveDownloader: DriveDownloadProxy?
    let readReceiptManager: ReadReceiptDataManager
    init(
        user: User,
        navigator: Navigatable,
        provider: ServiceProvider,
        dataService: DataService,
        editorLoader: MailEditorLoader
    ) {
        self.user = user
        self.navigator = navigator
        self.userKVStore = MailKVStore(space: .user(id: user.userID), mSpace: .global)
        self.provider = provider
        self.editorLoader = editorLoader
        self.dataService = dataService
        let featureManager = UserFeatureManager(featureSwitch: provider.featureSwitch)
        let cacheService = MailCacheService(userID: user.userID, featureManager: featureManager)
        self.cacheService = cacheService
        self.featureManager = featureManager
        self.securityAudit = MailSecurityAudit(user: user)
        
        var downloader: DriveDownloadProxy?
        if featureManager.open(.offlineCacheImageAttach, openInMailClient: false) &&
            featureManager.open(.offlineCache, openInMailClient: false){
            downloader = MailDriveDownloadService(dataService: dataService)
        } else {
            downloader = provider.driveDownloader
        }
        self.driveDownloader = downloader
        self.readReceiptManager = ReadReceiptDataManager(dataService: dataService)
        let imageCache = MailImageCache(userID: user.userID, featureManager: featureManager)
        self.imageService = MailImageService(
            userID: user.userID,
            cacheService: cacheService,
            driveProvider: downloader,
            imageCache: imageCache,
            featureManager: featureManager)
        self.alertHelper = MailClientAlertHelper(navigator: navigator)
        self.profileRouter = ProfileRouter(routerProvider: provider.routerProvider, navigator: navigator)
        self.preloadServices = MailPreloadServices(manager: provider.preloadManager,
                                                   userID: user.userID,
                                                   driveProvider: downloader,
                                                   imageCache: imageCache,
                                                   featureManager: featureManager,
                                                   settings: provider.settingConfig)
        self.messageListPreloader = MailMessageListUnreadPreloader(userID: user.userID,
                                                                   settingConfig: provider.settingConfig,
                                                                   preloadServices: preloadServices)
        
        let fileCache = MailAttachOfflineCache(userID: user.userID, featureManager: featureManager)
        self.preloadCacheManager = MailPreloadCacheManager(imageCache: imageCache,
                                                           attachCache: fileCache,
                                                           featureManager: featureManager)

    }
}

protocol MailSharedServicesProvider: AnyObject {
    var sharedServices: MailSharedServices { get }
}

extension MailSharedServicesProvider {
    var user: User {
        sharedServices.user
    }

    var navigator: Navigatable {
        sharedServices.navigator
    }

    var userKVStore: MailKVStore {
        sharedServices.userKVStore
    }

    var provider: ServiceProvider {
        sharedServices.provider
    }

    var dataService: DataService {
        sharedServices.dataService
    }

    var profileRouter: ProfileRouter {
        sharedServices.profileRouter
    }

    var editorLoader: MailEditorLoader {
        sharedServices.editorLoader
    }

    var cacheService: MailCacheService {
        sharedServices.cacheService
    }

    var imageService: MailImageService {
        sharedServices.imageService
    }

    var alertHelper: MailClientAlertHelper {
        sharedServices.alertHelper
    }

    var securityAudit: MailSecurityAudit {
        sharedServices.securityAudit
    }

    var messageListPreloader: MailMessageListUnreadPreloader {
        sharedServices.messageListPreloader
    }

    var featureManager: UserFeatureManager {
        sharedServices.featureManager
    }

    var preloadServices: MailPreloadServicesProtocol {
        sharedServices.preloadServices
    }

    var readReceiptManager: ReadReceiptDataManager {
        sharedServices.readReceiptManager
    }
}
