//
//  DriveSDKImpl.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/18.
//

import Foundation
import SKCommon
import SpaceInterface
import RxSwift
import RxRelay
import EENavigator
import SKFoundation
import SKUIKit
import UniverseDesignIcon
import LarkDocsIcon
import SKInfra

class DriveSDKImpl: DriveSDK {
    private let config: DKConfig
    private let localAbility: DriveSDKLocalFilePreviewAbility?
    // TODO: 待 DriveSDK 接入用户态后，直接从 resolver 里取
    private var permissionSDK: PermissionSDK { DocsContainer.shared.resolve(PermissionSDK.self)! }
    init(config: DKConfig, ability: DriveSDKLocalFilePreviewAbility? = nil) {
        self.config = config
        self.localAbility = ability
    }

    func canOpen(fileName: String, fileSize: UInt64?, appID: String) -> SupportOptions {
        guard config.isValid(appID: appID) else {
            DocsLogger.error("drive.sdk.impl --- unknown appID", extraInfo: ["appID": appID])
            return []
        }
        guard let fileExtension = SKFilePath.getFileExtension(from: fileName) else {
            DocsLogger.error("drive.sdk.impl --- failed to get file extension for canOpen check")
            return []
        }
        return config.canOpen(type: fileExtension, appID: appID)
    }

    func getNaviBarConfig(naviBarConfig: DriveSDKNaviBarConfig) -> DriveSDKNaviBarConfig {
        //ipad下所有drive文件标题居中
        if SKDisplay.pad {
            return DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: naviBarConfig.fullScreenItemEnable)
        } else {
            return naviBarConfig
        }
    }
    
    func open(onlineFile: OnlineFile, from: UIViewController, appID: String, dependency: Dependency) {
        let file = DriveSDKIMFile(fileName: onlineFile.fileName,
                                  fileID: onlineFile.fileID,
                                  msgID: onlineFile.msgID,
                                  uniqueID: onlineFile.uniqueID,
                                  senderTenantID: onlineFile.senderTenantID,
                                  extraAuthInfo: onlineFile.extraAuthInfo,
                                  dependency: dependency,
                                  isEncrypted: onlineFile.isEncrypted)
        open(imFile: file, from: from, appID: appID)
    }
    
    func open(localFile: LocalFile,
              from: UIViewController,
              appID: String,
              thirdPartyAppID: String?) {
        DocsLogger.driveInfo("drive.sdk.impl --- -- open local file")
        let moreVisable: Observable<Bool> = localFile.moreActions.count > 0 ? .just(true) : .just(false)
        let more = DKLocalFileDefaultMoreDependencyImpl(localActions: localFile.moreActions, moreMenueVisable: moreVisable, moreMenuEnable: .just(true))
        let action = DKLocalFileDefaultActionDependencyImpl()
        let dependency = DKLocalFileDefaultDependency(actionDependency: action, moreDependency: more)
        let file = DriveSDKLocalFileV2(fileName: localFile.fileName, fileType: localFile.fileType, fileURL: localFile.fileURL, fileId: localFile.fileID ?? "", dependency: dependency)

        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: false)
        let vc = self.createLocalFileController(localFiles: [file], index: 0, appID: appID, thirdPartyAppID: thirdPartyAppID, naviBarConfig: naviBarConfig)
        Navigator.shared.push(vc, from: from)
    }
    
    func localPreviewController(for localFile: LocalFile, appID: String, thirdPartyAppID: String?, naviBarConfig: DriveSDKNaviBarConfig) -> UIViewController {
        DocsLogger.driveInfo("drive.sdk.impl --- create local file preview vc")
        let actions = localFile.dependency.moreDependency.actions
        let moreVisable = localFile.dependency.moreDependency.moreMenuVisable
        let moreEnable = localFile.dependency.moreDependency.moreMenuEnable
        let more = DKLocalFileDefaultMoreDependencyImpl(localActions: actions, moreMenueVisable: moreVisable, moreMenuEnable: moreEnable)
        let dependency = DKLocalFileDefaultDependency(actionDependency: localFile.dependency.actionDependency,
                                                      moreDependency: more)
        let file = DriveSDKLocalFileV2(fileName: localFile.fileName, fileType: localFile.fileType, fileURL: localFile.fileURL, fileId: localFile.fileID ?? "", dependency: dependency)
        let vc = self.createLocalFileController(localFiles: [file], index: 0, appID: appID, thirdPartyAppID: thirdPartyAppID, naviBarConfig: getNaviBarConfig(naviBarConfig: naviBarConfig))
        return vc
    }

    func open(imFile: IMFile, from: UIViewController, appID: String) {
        let contextVM = createContextViewModel(imFile: imFile, appID: appID)
        let router = DKDefaultRouter()
        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: true)
        let driveSDKMainVC = DKMainViewController(viewModel: contextVM, router: router, naviBarConfig: naviBarConfig)
        Navigator.shared.push(driveSDKMainVC, from: from)
    }
    
    func createIMFileController(imFile: IMFile, appID: String, naviBarConfig: DriveSDKNaviBarConfig) -> UIViewController {
        let contextVM = createContextViewModel(imFile: imFile, appID: appID)
        let router = DKDefaultRouter()
        return DKMainViewController(viewModel: contextVM, router: router, naviBarConfig: getNaviBarConfig(naviBarConfig: naviBarConfig))
    }

    func createLocalFileController(localFiles: [LocalFileV2], index: Int, appID: String, thirdPartyAppID: String?, naviBarConfig: DriveSDKNaviBarConfig) -> UIViewController {
        let file = localFiles[index]
        if let localAbility = localAbility,
           checkIsEMLOrMsgFile(fileType: file.fileType, fileURL: file.fileURL),
            let vc = localAbility.previewVC(with: file.fileURL) {
            DocsLogger.driveInfo("drive.sdk.impl --- open local file with mail")
            return vc
        }
        DocsLogger.driveInfo("drive.sdk.impl --- create local file preview vc")
        let (permissionDomain, permissionBizDomain) = convertLocalFilePermissionContext(appID: appID)
        let viewmodels = localFiles.map({ (file) -> DKFileCellViewModelType in
            let fileExt = SKFilePath.getFileExtension(from: file.fileName)
            let fileType = DriveFileType(fileExtension: fileExt)
            let previewFrom = previewFromAppID(appID)
            let statistics = DKStatistics(appID: appID,
                                          fileID: file.fileID,
                                          fileType: fileType,
                                          previewFrom: previewFrom,
                                          mountPoint: nil,
                                          isInVCFollow: false,
                                          isAttachMent: true,
                                          statisticInfo: nil)
            let performanceRecorder = DrivePerformanceRecorder(fileToken: file.fileID,
                                                             fileType: fileExt ?? "",
                                                             previewFrom: previewFrom,
                                                             sourceType: .preview,
                                                             additionalStatisticParameters: [DrivePerformanceRecorder.ReportKey.sdkAppID.rawValue: appID])
            let dependency = DKLocalFileDependencyImpl(localFile: file,
                                                       appID: appID,
                                                       thirdPartyAppID:
                                                        thirdPartyAppID,
                                                       statistics: statistics,
                                                       performanceRecorder: performanceRecorder,
                                                       moreConfiguration: file.dependency.moreDependency,
                                                       actionProvider: file.dependency.actionDependency)
            let service = permissionSDK.driveSDKPermissionService(domain: permissionDomain,
                                                                  fileID: file.fileID,
                                                                  bizDomain: permissionBizDomain)
            return DKLocalFileCellViewModel(dependency: dependency,
                                            permissionService: service)
        })
        
        let viewModel = DKMainViewModel(files: viewmodels, initialIndex: index, supportLandscape: true)
        let router = DKDefaultRouter()

        return DKMainViewController(viewModel: viewModel, router: router, naviBarConfig: getNaviBarConfig(naviBarConfig: naviBarConfig))

    }

    private func convertLocalFilePermissionContext(appID: String) -> (PermissionSDK.DriveSDKPermissionDomain, PermissionRequest.BizDomain) {
        guard let appType = DKSupportedApp(rawValue: appID) else {
            return (.openPlatformAttachment, .openPlatform)
        }
        switch appType {
        case .im, .secretIM:
            return (.imFile, .customIM(fileBizDomain: .im))
        case .miniApp, .webBroswer:
            return (.openPlatformAttachment, .openPlatform)
        case .mail:
            return (.mailAttachment, .ccm)
        case .calendar:
            return (.calendarAttachment, .calendar)
        default:
            spaceAssertionFailure("unknown app type found when open local app")
            return (.openPlatformAttachment, .openPlatform)
        }
    }

    func createAttachmentFileController(attachFiles: [AttachmentFile],
                                        index: Int,
                                        appID: String,
                                        isCCMPermission: Bool,
                                        tenantID: String?,
                                        isInVCFollow: Bool,
                                        attachmentDelegate: DriveSDKAttachmentDelegate?,
                                        naviBarConfig: DriveSDKNaviBarConfig) -> UIViewController {
        let viewModels = attachFiles.map { (file) -> DKFileCellViewModelType in
            let fileType = DriveFileType(fileExtension: file.fileType)
            let previewFrom = previewFromAppID(appID)
            let statistics = DKStatistics(appID: appID,
                                          fileID: file.fileToken,
                                          fileType: fileType,
                                          previewFrom: previewFrom,
                                          mountPoint: file.mountPoint,
                                          isInVCFollow: isInVCFollow,
                                          isAttachMent: true,
                                          statisticInfo: nil)
            
            let performanceRecorder = DrivePerformanceRecorder(fileToken: file.fileToken,
                                                             fileType: file.fileType ?? "",
                                                             previewFrom: previewFrom,
                                                             sourceType: .preview,
                                                             additionalStatisticParameters: [DrivePerformanceRecorder.ReportKey.sdkAppID.rawValue: appID])
            let permission = permisionService(isCCMPermission: isCCMPermission,
                                              fileToken: file.fileToken,
                                              authExtra: file.authExtra,
                                              mountPoint: file.mountPoint,
                                              tenantID: tenantID,
                                              previewFrom: previewFrom)
            let canImport = isCCMPermission ? true : false
            let dependency = DKAttachentDependencyImpl(file: file,
                                                       appID: appID,
                                                       statistics: statistics,
                                                       performanceRecorder: performanceRecorder,
                                                       permissionHelper: permission,
                                                       isInVCFollow: isInVCFollow,
                                                       canImportAsOnlineFile: canImport,
                                                       moreConfiguration: file.dependency.moreDependency,
                                                       actionProvider: file.dependency.actionDependency)
            let context = DKSpacePreviewContext(previewFrom: previewFrom,
                                                canImportAsOnlineFile: canImport,
                                                isInVCFollow: isInVCFollow,
                                                wikiToken: nil,
                                                feedId: nil,
                                                isGuest: false,
                                                hostToken: file.hostToken)
            return DKAttachmentFileCellViewModel(dependency: dependency, previewFrom: previewFrom, commonContext: context, scene: .attach)
        }
        
        let viewmodel = attachMainViewModel(isInVCFollow: isInVCFollow, cellModels: viewModels, initialIndex: index, isCCMPermission: isCCMPermission)
        let router = DKDefaultRouter()
        let vc = DKMainViewController(viewModel: viewmodel, router: router, naviBarConfig: getNaviBarConfig(naviBarConfig: naviBarConfig))
        vc.attachmentDelegate = attachmentDelegate
        return vc
    }
    
    func createSpaceFileController(files: [AttachmentFile],
                                   index: Int,
                                   appID: String,
                                   isInVCFollow: Bool,
                                   context: [String: Any],
                                   statisticInfo: [String: String]?) -> UIViewController {
        let viewModels = files.map { (file) -> DKFileCellViewModelType in
            let fileType = DriveFileType(fileExtension: file.fileType)
            let previewFrom = getSpacePreviewFrom(from: context)
            let statistics = DKStatistics(appID: appID,
                                          fileID: file.fileToken,
                                          fileType: fileType,
                                          previewFrom: previewFrom,
                                          mountPoint: file.mountPoint,
                                          isInVCFollow: isInVCFollow,
                                          isAttachMent: false,
                                          statisticInfo: statisticInfo)
            let performanceRecorder = DrivePerformanceRecorder(fileToken: file.fileToken,
                                                             fileType: file.fileType ?? "",
                                                             previewFrom: previewFrom,
                                                             sourceType: .preview,
                                                             additionalStatisticParameters: [DrivePerformanceRecorder.ReportKey.sdkAppID.rawValue: appID])
            // 多图预览时，这里会提前建立若干个权限服务对象，有潜在的性能风险
            let service = permissionSDK.userPermissionService(for: .document(token: file.fileToken, type: .file), withPush: true)
            let permission = DrivePermissionHelper(fileToken: file.fileToken, type: .file, permissionService: service)
            let dependency = DKAttachentDependencyImpl(file: file,
                                                       appID: appID,
                                                       statistics: statistics,
                                                       performanceRecorder: performanceRecorder,
                                                       permissionHelper: permission,
                                                       isInVCFollow: isInVCFollow,
                                                       canImportAsOnlineFile: true,
                                                       moreConfiguration: file.dependency.moreDependency,
                                                       actionProvider: file.dependency.actionDependency)
            let context = parseSpaceContext(context: context, isInVCFollow: isInVCFollow, statisticInfo: statisticInfo)
            return DKAttachmentFileCellViewModel(dependency: dependency, previewFrom: previewFrom, commonContext: context, scene: .space)
        }
        
        let viewmodel = attachMainViewModel(isInVCFollow: isInVCFollow, cellModels: viewModels, initialIndex: index, isCCMPermission: true)
        let router = DKDefaultRouter()
        let naviBarConfig = getNaviBarConfig(naviBarConfig: DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true))
        let vc = DKMainViewController(viewModel: viewmodel, router: router, naviBarConfig: naviBarConfig)
        return vc
    }
    
    func getRoundImageForDriveAccordingto(fileType: String) -> UIImage {
        let driveFileType = DriveFileType(fileExtension: fileType)
        return driveFileType.roundImage ?? UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
    }
    
    func getSquareImageForDriveAccordingto(fileType: String) -> UIImage {
        let driveFileType = DriveFileType(fileExtension: fileType)
        return driveFileType.squareImage ?? UDIcon.getIconByKey(.fileUnknowColorful, size: CGSize(width: 48, height: 48))
    }
    
    private func createContextViewModel(imFile: IMFile, appID: String) -> DKMainViewModelType {
        // TODO: 确认下在这里注入哪些额外的 IM 上下文信息
        let permissionService = permissionSDK.driveSDKPermissionService(domain: .imFile, fileID: imFile.fileID, bizDomain: .customIM(fileBizDomain: .im))
        let dependency = imFileDependency(for: imFile, appID: appID)
        let vm = DKIMFileCellViewModel(dependency: dependency, permissionService: permissionService)
        return DKMainViewModel(files: [vm], initialIndex: 0, supportLandscape: true)
    }
    
    private func imFileDependency(for onlineFile: IMFile, appID: String) -> DKIMFileDependencyImpl {
        let fileInfoProvider = DKDefaultFileInfoProvider(appID: appID, fileID: onlineFile.fileID, authExtra: onlineFile.extraAuthInfo)
        let reachabilityRelay = BehaviorRelay<Bool>(value: DocsNetStateMonitor.shared.isReachable)
        let cacheService = DKCacheServiceImpl(appID: appID, fileID: onlineFile.fileID)
        let dependency = onlineFile.dependency
        
        let userID: String
        if let currentUserID = User.current.info?.userID {
            userID = currentUserID
        } else {
            assertionFailure("Failed to get current user ID when enter DriveSDK")
            DocsLogger.error("drive.sdk.impl --- Failed to get current user ID when enter DriveSDK")
            userID = ""
        }
        let saveService = DKSaveToSpacePushService(appID: appID, fileID: onlineFile.fileID, authExtra: onlineFile.extraAuthInfo, userID: userID)
        let fileExt = SKFilePath.getFileExtension(from: onlineFile.fileName)
        let fileType = DriveFileType(fileExtension: fileExt)
        let previewFrom = previewFromAppID(appID)
        let statistics = DKStatistics(appID: appID,
                                      fileID: onlineFile.fileID,
                                      fileType: fileType,
                                      previewFrom: previewFrom,
                                      mountPoint: "im_file",
                                      isInVCFollow: false,
                                      isAttachMent: true,
                                      statisticInfo: nil)
        let performanceRecorder = DrivePerformanceRecorder(fileToken: onlineFile.fileID,
                                                         fileType: fileExt ?? "",
                                                         previewFrom: previewFrom,
                                                         sourceType: .preview,
                                                         additionalStatisticParameters: [DrivePerformanceRecorder.ReportKey.sdkAppID.rawValue: appID])
        
        let dependencyImpl = DKIMFileDependencyImpl(appID: appID,
                                                onlineFile: onlineFile,
                                                fileInfoProvider: fileInfoProvider,
                                                reachabilityRelay: reachabilityRelay,
                                                cacheService: cacheService,
                                                saveService: saveService,
                                                moreConfiguration: dependency.moreDependency,
                                                actionProvider: dependency.actionDependency,
                                                statistics: statistics,
                                                performanceRecorder: performanceRecorder)
        return dependencyImpl
    }
    
    private func permisionService(isCCMPermission: Bool,
                                  fileToken: String,
                                  authExtra: String?,
                                  mountPoint: String,
                                  tenantID: String?,
                                  previewFrom: DrivePreviewFrom) -> DrivePermissionHelperProtocol {
        if isCCMPermission {
            // 仅 Doc 1.0 旧版本附件、Sheet 附件会走到此分支，后续不再新增
            let service = permissionSDK.userPermissionService(for: .document(token: fileToken, type: .file), withPush: true)
            return DriveAttachmentPermissionHelper(fileToken: fileToken, type: .file, permissionService: service)
        } else {
            // DocX、Base、邮箱、日历等第三方附件走此分支
            // TODO: 这里需要再讨论下第三方附件预览的场景和对应的权限管控怎么实现
            let sessionID = UUID().uuidString
            let userID = User.current.info?.userID ?? ""
            let cache = DriveThirdPartyAttachmentPermissionCache(userID: userID)
            let api = DriveThirdPartyAttachmentPermissionAPI(fileToken: fileToken, mountPoint: mountPoint, authExtra: authExtra, sessionID: sessionID, cache: cache)
            let validatorType = DriveThirdPartyAttachmentPermissionValidator.self
            let service = permissionSDK.driveSDKCustomUserPermissionService(permissionAPI: api,
                                                                            validatorType: validatorType,
                                                                            tokenForDLP: fileToken,
                                                                            bizDomain: previewFrom.permissionBizDomain,
                                                                            sessionID: sessionID)
            service.update(tenantID: tenantID ?? "") // 附件没传就给一个假的 tenantID，走外部租户的 DLP 文案
            return DriveThirdPartyFilePermission(with: fileToken,
                                                 authExtra: authExtra,
                                                 mountPoint: mountPoint,
                                                 permissionService: service)
        }
    }
    
    private func previewFromAppID(_ appID: String) -> DrivePreviewFrom {
        if let app = DKSupportedApp(rawValue: appID) {
            return app.previewFrom
        }
        return .driveSDK
    }
    
    private func attachMainViewModel(isInVCFollow: Bool, cellModels: [DKFileCellViewModelType], initialIndex: Int, isCCMPermission: Bool) -> DKMainViewModelType {
        if isInVCFollow {
            return DKFollowMainViewModel(files: cellModels, initialIndex: initialIndex, supportLandscape: true, isCCMPermission: isCCMPermission)
        } else {
            return DKMainViewModel(files: cellModels, initialIndex: initialIndex, supportLandscape: true)
        }
    }
    
    private func getSpacePreviewFrom(from context: [String: Any]) -> DrivePreviewFrom {
        guard let fromString = context["from"] as? String, let from = DrivePreviewFrom(rawValue: fromString) else {
            return .unknown
        }
        return from
    }
    
    // 云盘文件预览上下文
    private func parseSpaceContext(context: [String: Any], isInVCFollow: Bool, statisticInfo: [String: String]?) -> DKSpacePreviewContext {
        var previewFrom = DrivePreviewFrom.unknown
        if let fromValue = context[DKContextKey.from.rawValue] as? String, let from = DrivePreviewFrom(rawValue: fromValue) {
            previewFrom = from
        }
        let wikiToken = context[DKContextKey.wikiToken.rawValue] as? String
        let feedId = context[DKContextKey.feedID.rawValue] as? String
        let timeStamp = context[DKContextKey.editTimeStamp.rawValue] as? String
        let pdfPageNumer = context[DKContextKey.pdfPageNumber.rawValue] as? Int
        let feedFromInfo = FeedFromInfo.deserialize(context)
        let isGuest = User.current.basicInfo?.isGuest ?? false
        let previewContext = DKSpacePreviewContext(previewFrom: previewFrom,
                                                   canImportAsOnlineFile: true,
                                                   isInVCFollow: isInVCFollow,
                                                   wikiToken: wikiToken,
                                                   feedId: feedId,
                                                   isGuest: isGuest,
                                                   hostToken: nil)
        previewContext.statisticInfo = statisticInfo ?? [:]
        previewContext.feedFromInfo = feedFromInfo
        previewContext.hitoryEditTimeStamp = timeStamp
        previewContext.pdfPageNumber = pdfPageNumer
        
        return previewContext
    }
    
    private func checkIsEMLOrMsgFile(fileType: String?, fileURL: URL) -> Bool {
        let fileExt = fileType ?? SKFilePath.getFileExtension(from: fileURL.lastPathComponent)
        if fileExt == DriveFileType.eml.rawValue || fileExt == DriveFileType.msg.rawValue {
            DocsLogger.driveInfo("drive.sdk.impl --- eml will open with mail")
            return true
        }
        return false
    }
}

// MARK: - default local dependency impl
struct DKLocalFileDefaultMoreDependencyImpl: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool>
    
    var moreMenuEnable: Observable<Bool>
    
    var actions: [DriveSDKMoreAction]
    
    init(actions: [DriveSDKMoreAction], moreMenueVisable: Observable<Bool>, moreMenuEnable: Observable<Bool> = .just(true)) {
        self.actions = actions
        self.moreMenuVisable = moreMenueVisable
        self.moreMenuEnable = moreMenuEnable
    }
    // 兼容旧版本
    init(localActions: [DriveSDKLocalMoreAction], moreMenueVisable: Observable<Bool>, moreMenuEnable: Observable<Bool> = .just(true)) {
        self.actions = localActions.map { $0.newMoreAction }
        self.moreMenuVisable = moreMenueVisable
        self.moreMenuEnable = moreMenuEnable
    }
}

struct DKLocalFileDefaultActionDependencyImpl: DriveSDKActionDependency {
    var uiActionSignal: RxSwift.Observable<SpaceInterface.DriveSDKUIAction> {
        return .never()
    }
    var closePreviewSignal: Observable<Void>
    var stopPreviewSignal: Observable<Reason>
    init(closePreviewSignal: Observable<Void> = .never(), stopPreviewSignal: Observable<Reason> = .never()) {
        self.closePreviewSignal = closePreviewSignal
        self.stopPreviewSignal = stopPreviewSignal
    }
}

struct DKLocalFileDefaultDependency: DriveSDKDependency {
    var actionDependency: DriveSDKActionDependency
    
    var moreDependency: DriveSDKMoreDependency
    
    init(actionDependency: DriveSDKActionDependency, moreDependency: DriveSDKMoreDependency) {
        self.actionDependency = actionDependency
        self.moreDependency = moreDependency
    }
}

// MARK: default attachmetn dependency impl
struct DKAttachDefaultMoreDependencyImpl: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool>
    
    var moreMenuEnable: Observable<Bool>
    
    var actions: [DriveSDKMoreAction]
    
    init(actions: [DriveSDKMoreAction], moreMenueVisable: Observable<Bool>, moreMenuEnable: Observable<Bool> = .just(true)) {
        self.actions = actions
        self.moreMenuVisable = moreMenueVisable
        self.moreMenuEnable = moreMenuEnable
    }
    // 兼容旧版本
    init(localActions: [DriveSDKLocalMoreAction], moreMenueVisable: Observable<Bool>, moreMenuEnable: Observable<Bool> = .just(true)) {
        self.actions = localActions.map { $0.newMoreAction }
        self.moreMenuVisable = moreMenueVisable
        self.moreMenuEnable = moreMenuEnable
    }
}

struct DKAttachDefaultActionDependencyImpl: DriveSDKActionDependency {
    var uiActionSignal: Observable<DriveSDKUIAction>
    var closePreviewSignal: Observable<Void>
    var stopPreviewSignal: Observable<Reason>
    init(closePreviewSignal: Observable<Void> = .never(),
         stopPreviewSignal: Observable<Reason> = .never(),
         uiActionSignal: Observable<DriveSDKUIAction> = .never()) {
        self.closePreviewSignal = closePreviewSignal
        self.stopPreviewSignal = stopPreviewSignal
        self.uiActionSignal = uiActionSignal
    }
}

struct DKAttachDefaultDependency: DriveSDKDependency {
    var actionDependency: DriveSDKActionDependency
    
    var moreDependency: DriveSDKMoreDependency
    
    init(actionDependency: DriveSDKActionDependency, moreDependency: DriveSDKMoreDependency) {
        self.actionDependency = actionDependency
        self.moreDependency = moreDependency
    }
}
