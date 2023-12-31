//
//  DKHostModuleHelper.swift
//  SKDrive-Unit-Tests
//
//  Created by majie.7 on 2022/3/17.
//

import XCTest
import SKUIKit
import OHHTTPStubs
import SwiftyJSON
import SKFoundation
import SKCommon
import RxSwift
import RxRelay
import RxCocoa
import SpaceInterface
import LarkDocsIcon
@testable import SKDrive

public func cacheNode(fileName: String, meta: DriveFileMeta, recordType: DriveCacheType = .preview) -> DriveCache.Node {
    let type = SKFilePath.getFileExtension(from: fileName)
    let r = DriveCache.Record(token: "testtoken",
                              version: "version",
                              recordType: recordType,
                              originName: fileName,
                              originFileSize: meta.size,
                              fileType: meta.type,
                              cacheType: .transient)
    let node = DriveCache.Node(record: r,
                               fileName: fileName,
                               fileSize: meta.size,
                               fileURL: SKFilePath.driveLibraryDir.appendingRelativePath("xxx.\(type)"))
    return node
}

public func cacheCoverNode(fileName: String, meta: DriveFileMeta, recordType: DriveCacheType = .preview) -> DriveCache.Node {
    let type = SKFilePath.getFileExtension(from: fileName)
    let r = DriveCache.Record(token: "testtoken",
                              version: "version",
                              recordType: recordType,
                              originName: fileName,
                              originFileSize: meta.size,
                              fileType: meta.type,
                              cacheType: .transient)
    let curBundle = Bundle(for: MockHostModule.self)
    guard let url = curBundle.url(forResource: "thumb", withExtension: "jpeg") else {
        return DriveCache.Node(record: r,
                               fileName: fileName,
                               fileSize: meta.size,
                               fileURL: SKFilePath(absPath: "/error/path"))
    }
    let node = DriveCache.Node(record: r,
                    fileName: fileName,
                    fileSize: meta.size,
                    fileURL: SKFilePath(absUrl: url))
    return node
}
public func invalidCacheCoverNode(fileName: String, meta: DriveFileMeta, recordType: DriveCacheType = .preview) -> DriveCache.Node {
    let type = SKFilePath.getFileExtension(from: fileName)
    let r = DriveCache.Record(token: "testtoken",
                              version: "version",
                              recordType: recordType,
                              originName: fileName,
                              originFileSize: meta.size,
                              fileType: meta.type,
                              cacheType: .transient)
    let curBundle = Bundle(for: MockHostModule.self)
    let node = DriveCache.Node(record: r,
                    fileName: fileName,
                    fileSize: meta.size,
                    fileURL: SKFilePath.driveLibraryDir.appendingRelativePath("xxx.\(type)"))
    return node
}

public func metaData(size: UInt64, fileName: String) -> DriveFileMeta {
    let type = SKFilePath.getFileExtension(from: fileName) ?? ""
    return DriveFileMeta(size: size,
                         name: fileName,
                         type: type,
                         fileToken: "testtoken",
                         mountNodeToken: "mountNodeToken",
                         mountPoint: "mountPoint",
                         version: "version",
                         dataVersion: "dataversion",
                         source: .other,
                         tenantID: nil,
                         authExtra: nil)
}

class MockDependency: NSObject, WindowSizeProtocol {
    var isMyWindowRegularSizeVaule: Bool = false
    
    var isMyWindowRegularSizeInPad: Bool {
        return isMyWindowRegularSizeVaule
    }
    func isMyWindowRegularSize() -> Bool {
        return isMyWindowRegularSizeVaule
    }
}
//  swiftlint:disable file_length
class MockDKHostSubModule: UIViewController, DKSubModleHostVC {
    var suspendID: String {
        return "ObjToken"
    }
    
    var navigationBar: SKNavigationBar = SKNavigationBar()
     
    var commentBar: DriveCommentBottomView = DriveCommentBottomView(likeEnabled: false)
     
    var bottomPlaceHolderView: UIView = UIView()
     
    var commentBarIsShow: Bool = false
    
    var didPresent: Bool = false
    
    var didPopover: Bool = false

    var hasAppearred: Bool = false
    
    var complete: (() -> Void)?
    
    var watermarkConfig: WatermarkViewConfig = WatermarkViewConfig()
     
    func showPopover(to viewController: UIViewController,
                     at index: Int,
                     completion: (() -> Void)?) {
        didPopover = true
        complete?()
    }
     
    func back(canEmpty: Bool) {
        
    }
     
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        didPresent = true
        complete?()
//        completion?()
    }
     
    func setupBottomView() {
        
    }

    func updateCommentBar(hiddenByPermission: Bool) {}
    
    func showCommentBar(_ shouldShow: Bool, animate: Bool) {
        
    }
    
    func resizeContentViewIfNeed(_ height: CGFloat?) {
        
    }
    
    func exitFullScreen() {
        
    }
    var isInFullScreen: Bool = false
    
}

class MockHostModule: DKHostModuleType {
    var pdfAIBridge: RxRelay.BehaviorRelay<Int>? = BehaviorRelay<Int>.init(value: 0)
    
    var pdfInlineAIAction: PublishRelay<DKPDFInlineAIAction>? = .init()

    var permissionService: UserPermissionService = MockUserPermissionService()

    var cacManager: CACManagerBridge.Type = CACManager.self
    
    var hostToken: String?
        
    var hostController: DKSubModleHostVC?
    var windowSizeDependency: WindowSizeProtocol?
    var permissionMask: UserPermissionMask?
    init(hostController: DKSubModleHostVC = MockDKHostSubModule(), windowSizeDependency: WindowSizeProtocol = MockDependency(), permissionMask: UserPermissionMask? = nil,
         isFromCardMode: Bool = false, isFromPreviewFrom: DrivePreviewFrom = .driveSDK) {
        self.hostController = hostController
        self.windowSizeDependency = windowSizeDependency
        self.permissionMask = permissionMask
        self.isFromCardMode = isFromCardMode
        self.isFromPreviewFrom = isFromPreviewFrom
    }

    var fileInfoRelay: BehaviorRelay<DriveFileInfo> {
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.pptx",
                                 type: "pptx",
                                 fileToken: "boxxxxxxx",
                                 mountNodeToken: "boxxxx",
                                 mountPoint: "explore",
                                 version: "123",
                                 dataVersion: nil,
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        return BehaviorRelay<DriveFileInfo>(value: fileInfo)
    }
    
    private let fileInfoError = PublishRelay<DriveError?>()
    var fileInfoErrorOb: Observable<DriveError?> {
        fileInfoError.catchErrorJustReturn(nil)
    }
    
    var docsInfoRelay: BehaviorRelay<DocsInfo> {
        let docsInfo = DocsInfo(type: .file, objToken: "boxxxxxxx")
        let secInfo = ["sec_label": ""]
        docsInfo.title = "test"
        docsInfo.secLabel = SecretLevel(json: JSON(secInfo))
        return BehaviorRelay<DocsInfo>(value: docsInfo)
    }
    
    var permissionRelay: BehaviorRelay<DrivePermissionInfo> {
        let info = DrivePermissionInfo(isReadable: true,
                                       isEditable: true,
                                       canComment: true,
                                       canExport: true,
                                       canCopy: true,
                                       canShowCollaboratorInfo: true,
                                       isCACBlock: false,
                                       permissionStatusCode: nil,
                                       userPermissions: permissionMask)
        return BehaviorRelay<DrivePermissionInfo>(value: info)
    }
    
    var commentManager: DriveCommentManager? {
        let meta = DriveFileMeta(size: 1024,
                                 name: "test",
                                 type: "pptx",
                                 fileToken: "boxxxxxxx",
                                 mountNodeToken: "boxxxx",
                                 mountPoint: "explore",
                                 version: nil,
                                 dataVersion: nil,
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let manager = DriveCommentManager(canComment: true, canShowCollaboratorInfo: true, canPreviewProvider: { true }, docsInfo: DocsInfo(type: .file, objToken: "xxxx"), fileInfo: fileInfo, feedFromInfo: nil)
        return manager
    }
    
    var netManager: DrivePreviewNetManagerProtocol {
        let net = MockNetManager()
        net.isUpdateFileInfo = isFromCardMode
        return net
    }
    
    var cacheService: DKCacheServiceProtocol {
        return MockCacheService()
    }
    
    var reachabilityChanged: Observable<Bool> {
        .just(true)
    }
    
    var commonContext: DKSpacePreviewContext {
        let context = DKSpacePreviewContext(previewFrom: isFromPreviewFrom,
                                            canImportAsOnlineFile: true,
                                            isInVCFollow: false,
                                            wikiToken: nil,
                                            feedId: nil,
                                            isGuest: false,
                                            hostToken: nil)
        return context
    }
    
    var moreDependency: DriveSDKMoreDependency = {
        return MockMoreDependency()
    }()
    
    var previewActionSubject: ReplaySubject<DKPreviewAction> {
        ReplaySubject<DKPreviewAction>.create(bufferSize: 1)
    }
    
    var statisticsService: DKStatisticsService {
        return MockStatisticService()
    }
    
    var openFileSuccessType: DriveOpenType? { .unknown }
    
    var currentDisplayMode: DrivePreviewMode { .normal }
    
    var isFromCardMode: Bool = false
    
    var isFromPreviewFrom: DrivePreviewFrom = .driveSDK
    
    var additionalStatisticParameters: [String: String] = [:]
    
    var subModuleActionsCenter = PublishRelay<DKSubModuleAction>()
    
    var scene: DKPreviewScene { .space }

}



/// Mock 附件场景的 HostModule
class MockAttachSceneHostModule: DKHostModuleType {
    
    var pdfAIBridge: RxRelay.BehaviorRelay<Int>? = BehaviorRelay<Int>.init(value: 0)
    var pdfInlineAIAction: PublishRelay<DKPDFInlineAIAction>? = .init()
    var permissionService: UserPermissionService = MockUserPermissionService()
    var cacManager: CACManagerBridge.Type = CACManager.self

    var hostToken: String?

    var hostController: DKSubModleHostVC?
    var windowSizeDependency: WindowSizeProtocol?
    var permissionMask: UserPermissionMask?
    init(hostController: DKSubModleHostVC = MockDKHostSubModule(), windowSizeDependency: WindowSizeProtocol = MockDependency(), permissionMask: UserPermissionMask? = nil,
         isFromCardMode: Bool = false, isFromPreviewFrom: DrivePreviewFrom = .driveSDK) {
        self.hostController = hostController
        self.windowSizeDependency = windowSizeDependency
        self.permissionMask = permissionMask
        self.isFromCardMode = isFromCardMode
        self.isFromPreviewFrom = isFromPreviewFrom
    }

    var fileInfoRelay: BehaviorRelay<DriveFileInfo> {
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.pptx",
                                 type: "pptx",
                                 fileToken: "boxxxxxxx",
                                 mountNodeToken: "boxxxx",
                                 mountPoint: "explore",
                                 version: "123",
                                 dataVersion: nil,
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        return BehaviorRelay<DriveFileInfo>(value: fileInfo)
    }

    private let fileInfoError = PublishRelay<DriveError?>()
    var fileInfoErrorOb: Observable<DriveError?> {
        fileInfoError.catchErrorJustReturn(nil)
    }

    var docsInfoRelay: BehaviorRelay<DocsInfo> {
        let docsInfo = DocsInfo(type: .file, objToken: "boxxxxxxx")
        let secInfo = ["sec_label": ""]
        docsInfo.title = "test"
        docsInfo.secLabel = SecretLevel(json: JSON(secInfo))
        return BehaviorRelay<DocsInfo>(value: docsInfo)
    }

    var permissionRelay: BehaviorRelay<DrivePermissionInfo> {
        let info = DrivePermissionInfo(isReadable: true,
                                       isEditable: true,
                                       canComment: true,
                                       canExport: true,
                                       canCopy: true,
                                       canShowCollaboratorInfo: true,
                                       isCACBlock: false,
                                       permissionStatusCode: nil,
                                       userPermissions: permissionMask)
        return BehaviorRelay<DrivePermissionInfo>(value: info)
    }

    var commentManager: DriveCommentManager? {
        let meta = DriveFileMeta(size: 1024,
                                 name: "test",
                                 type: "pptx",
                                 fileToken: "boxxxxxxx",
                                 mountNodeToken: "boxxxx",
                                 mountPoint: "explore",
                                 version: nil,
                                 dataVersion: nil,
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let manager = DriveCommentManager(canComment: true, canShowCollaboratorInfo: true, canPreviewProvider: { true }, docsInfo: DocsInfo(type: .file, objToken: "xxxx"), fileInfo: fileInfo, feedFromInfo: nil)
        return manager
    }

    var netManager: DrivePreviewNetManagerProtocol {
        let net = MockNetManager()
        net.isUpdateFileInfo = isFromCardMode
        return net
    }

    var cacheService: DKCacheServiceProtocol {
        return MockCacheService()
    }

    var reachabilityChanged: Observable<Bool> {
        .just(true)
    }

    var commonContext: DKSpacePreviewContext {
        let context = DKSpacePreviewContext(previewFrom: isFromPreviewFrom,
                                            canImportAsOnlineFile: true,
                                            isInVCFollow: false,
                                            wikiToken: nil,
                                            feedId: nil,
                                            isGuest: false,
                                            hostToken: nil)
        return context
    }

    var moreDependency: DriveSDKMoreDependency = {
        return MockMoreDependency()
    }()

    var previewActionSubject: ReplaySubject<DKPreviewAction> {
        ReplaySubject<DKPreviewAction>.create(bufferSize: 1)
    }

    var statisticsService: DKStatisticsService {
        return MockStatisticService()
    }

    var openFileSuccessType: DriveOpenType? { .unknown }

    var currentDisplayMode: DrivePreviewMode { .normal }

    var isFromCardMode: Bool = false

    var isFromPreviewFrom: DrivePreviewFrom = .driveSDK

    var additionalStatisticParameters: [String: String] = [:]

    var subModuleActionsCenter = PublishRelay<DKSubModuleAction>()

    var scene: DKPreviewScene { .attach }

}

class MockNetManager: DrivePreviewNetManagerProtocol {
    
    var isUpdateFileInfo = false
    func fetchDocsInfo(docsInfo: DocsInfo, completion: @escaping (Error?) -> Void) {}
    
    func fetchFileInfo(context: FetchFileInfoContext,
                       polling: (() -> Void)?,
                       completion: @escaping (DriveResult<DriveFileInfo>) -> Void) {}
    
    func fetchPreviewURL(regenerate: Bool, mountPoint: String, mountToken: String, completion: @escaping (DriveResult<DriveFilePreview>) -> Void) {}
    
    func updateFileInfo(name: String, completion: @escaping (DriveResult<Bool>) -> Void) {
        if isUpdateFileInfo {
            completion(DriveResult.success(true))
        } else {
            completion(.failure(DriveError.serverError(code: 111)))
        }
    }
    
    func saveToSpace(fileInfo: DriveFileInfo, completion: @escaping (DriveResult<Bool>) -> Void) {}
    
    func getReadingData(docsInfo: DocsInfo, callback: @escaping DriveGetReadingDataCallback) {}
    
    func cancelFileInfo() {}
}

class MockCacheService: DKCacheServiceProtocol {
    var fileExist: Bool = true
    var fileResult: Result<DriveCache.Node, Error> = .failure(DriveError.fileInfoError)
    var fileData: Result<(DriveCache.Node, Data), Error> = .failure(DriveError.fileInfoError)
    var coverData: Result<(DriveCache.Node, Data), Error> = .failure(DriveError.fileInfoError)
    var oggData: Result<(DriveCache.Node, Data), Error> = .failure(DriveError.fileInfoError)
    var pdfData: Result<(DriveCache.Node, Data), Error> = .failure(DriveError.fileInfoError)
    var wpsData: Result<(DriveCache.Node, Data), Error> = .failure(DriveError.fileInfoError)
    var videoData: Result<(DriveCache.Node, Data), Error> = .failure(DriveError.fileInfoError)
    var htmlData: Result<(DriveCache.Node, Data), Error> = .failure(DriveError.fileInfoError)
    func fileDownloadURL(cacheType: DriveCacheType, type: String, dataVersion: String?) -> SKFoundation.SKFilePath {
        return SKFilePath.driveLibraryDir.appendingRelativePath("xxx")
    }
    
    func isFileExist(fileExtension: String?, dataVersion: String?) -> Bool {
        fileExist
    }
    
    func isFileExist(type: DriveCacheType, fileExtension: String?, dataVersion: String?) -> Bool {
        fileExist
    }
    
    func getFile(fileExtension: String?, dataVersion: String?) -> Result<DriveCache.Node, Error> {
        return fileResult
    }
    
    func getFile(type: DriveCacheType, fileExtension: String?, dataVersion: String?) -> Result<DriveCache.Node, Error> {
        return fileResult
    }
    
    func getData(type: DriveCacheType, fileExtension: String?, dataVersion: String?) -> Result<(DriveCache.Node, Data), Error> {
        switch type {
        case .preview, .similar, .origin:
            return fileData
        case let .associate(customID):
            if customID.hasPrefix("image-cover") {
                return coverData
            } else if customID.hasPrefix("ogg-info") {
                return oggData
            } else if customID.hasPrefix("partial-pdf") {
                return pdfData
            } else if customID.hasPrefix("web-office-info") {
                return wpsData
            } else if customID.hasPrefix("video-info") {
                return videoData
            } else if customID.hasPrefix("html-extra-info") {
                return htmlData
            } else {
                return .failure(DriveError.fileInfoError)
            }
        case .unknown:
            return .failure(DriveError.fileInfoError)
        }
    }
    
    func saveFile(filePath: SKFoundation.SKFilePath, basicInfo: SKDrive.DriveCacheServiceBasicInfo, completion: ((Result<SKFoundation.SKFilePath, Error>) -> Void)?) {}
    
    func saveData(data: Data, basicInfo: SKDrive.DriveCacheServiceBasicInfo, completion: ((Result<SKFoundation.SKFilePath, Error>) -> Void)?) {}
    
    func deleteFile(dataVersion: String?) {}
}

class MockMoreDependency: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> {
        .just(true)
    }
    
    var moreMenuEnable: Observable<Bool> {
        .just(true)
    }
    
    var actions: [DriveSDKMoreAction] = []
}

class MockStatisticService: DKStatisticsService {
    func enterPreview() {}
    
    func exitPreview() {}
    
    func reportSaveToSpace() {}
    
    func toggleAttribute(action: DriveStatisticAction, source: DriveStatisticActionSource) {}
    
    func enterFileLandscape(_ isLandscape: Bool) {}
    
    func clientClickDisplay(screenMode: String) {}
    
    func reportDrivePageView(isSupport: Bool, displayMode: DrivePreviewMode) {}
    
    func reportEvent(_ event: DocsTrackerEventType, params: [String: Any]) {}
    
    func reportClickEvent(_ event: DocsTrackerEventType, clickEventType: ClickEventType, params: [String: Any]) {}

    func reportExcelContentPageView(editMethod: SKDrive.FileEditMethod) {}
    
    func updateFileType(_ fileType: DriveFileType) {}
    
    func reportFileOpen(fileId: String, fileType: DriveFileType, isSupport: Bool) {}
    
    var additionalParameters: [String: String] = [:]
    
    var commonTrackParams: [String: String] = [:]
    
    var previewFrom: DrivePreviewFrom { .driveSDK }
}

class MockDKFileCellViewModel: NSObject, DKFileCellViewModelType {

    var permissionService: UserPermissionService = MockUserPermissionService()

    var previewFromScene: SKCommon.DrivePreviewFrom { .recent }
    
    var canReadAndCanCopy: RxSwift.Observable<(Bool, Bool)>? { nil }
    
    var hostModule: DKHostModuleType? {
        MockHostModule()
    }
    
    var isInVCFollow: Bool { false }
    
    func startPreview(hostContainer: UIViewController) {}
    
    func willChangeMode(_ mode: DrivePreviewMode) {}
    
    func changingMode(_ mode: DrivePreviewMode) {}
    
    func didChangeMode(_ mode: DrivePreviewMode) {}
    
    func reset() {}
    
    var previewStateUpdated: Driver<DKFilePreviewState> {
        .just(.loading)
    }
    
    var previewAction: Observable<DKPreviewAction> {
        .just(.openFailed)
    }
    
    var naviBarViewModel: ReplaySubject<DKNaviBarViewModel> {
        return ReplaySubject<DKNaviBarViewModel>.create(bufferSize: 1)
    }
    
    var canReadAndExport: Observable<(Bool, Bool)>? { nil }
    
    var performanceRecorder: DrivePerformanceRecorder {
        DrivePerformanceRecorder(fileToken: "boxxxxx",
                                 fileType: "pptx",
                                 previewFrom: .driveSDK,
                                 sourceType: .localFile,
                                 additionalStatisticParameters: nil)
    }
    
    var statisticsService: DKStatisticsService {
        MockStatisticService()
    }
    
    var shouldShowWatermark: Bool { false }
    
    func update(additionLeftBarItems: [DriveNavBarItemData], additionRightBarItems: [DriveNavBarItemData]) {}
    
    func handle(previewAction: DKPreviewAction) {}
    
    func handleBizPreviewUnsupport(type: DriveUnsupportPreviewType) {}
    
    func handleBizPreviewFailed(canRetry: Bool) {}
    
    func handleBizPreviewDowngrade() {}
    
    func handleOpenFileSuccessType(openType: DriveOpenType) {}
    
    var fileType: DriveFileType {
        return DriveFileType.pptx
    }
    
    var fileID: String = ""
    
    var urlForSuspendable: String?
    
    var title: String = ""

    func didResumeVCFullWindow() {}
}


class MockNetworkStatusMonitor: SKNetStatusService {
    var accessType: NetworkType = NetworkType.wifi
    var isReachable: Bool = true
    private var block: NetStatusCallback?
    // 触发网络状态变化
    func changeTo(networkType: NetworkType, reachable: Bool) {
        isReachable = reachable
        accessType = networkType
        block?(networkType, reachable)
    }
    func addObserver(_ observer: AnyObject, _ block: @escaping NetStatusCallback) {
        self.block = block
    }
}
class MockSKDriveDependencyImpl: SKDriveDependency {

    func createMoreDataProvider(context: DriveMoreDataProviderContext) -> DriveMoreDataProviderType {
        return MockDriveMoreDataProvider()
    }

    func makeShareViewControllerV2(context: DriveShareVCContext) -> UIViewController {
        return UIViewController()
    }
    
    func getWikiInfo(by wikiToken: String) -> WikiInfo? {
        return nil
    }
}

class MockDriveSDKImpl: DriveSDK {
    func canOpen(fileName: String, fileSize: UInt64?, appID: String) -> SupportOptions {
        return DriveSDKSupportOptions(rawValue: 1)
    }
    
    func open(onlineFile: OnlineFile, from: UIViewController, appID: String, dependency: Dependency) {
    }
    
    func open(localFile: LocalFile, from: UIViewController, appID: String, thirdPartyAppID: String?) {
    }
    
    func localPreviewController(for localFile: LocalFile, appID: String, thirdPartyAppID: String?, naviBarConfig: SpaceInterface.DriveSDKNaviBarConfig) -> UIViewController {
        UIViewController()
    }
    
    func open(imFile: IMFile, from: UIViewController, appID: String) {
    }
    
    func createIMFileController(imFile: IMFile, appID: String, naviBarConfig: SpaceInterface.DriveSDKNaviBarConfig) -> UIViewController {
        UIViewController()
    }
    
    func createLocalFileController(localFiles: [LocalFileV2], index: Int, appID: String, thirdPartyAppID: String?, naviBarConfig: SpaceInterface.DriveSDKNaviBarConfig) -> UIViewController {
        UIViewController()
    }
    
    func createAttachmentFileController(attachFiles: [AttachmentFile],
                                        index: Int,
                                        appID: String,
                                        isCCMPermission: Bool,
                                        tenantID: String?,
                                        isInVCFollow: Bool,
                                        attachmentDelegate: SpaceInterface.DriveSDKAttachmentDelegate?,
                                        naviBarConfig: SpaceInterface.DriveSDKNaviBarConfig) -> UIViewController {
        UIViewController()
    }
    
    func createSpaceFileController(files: [AttachmentFile],
                                   index: Int, appID: String,
                                   isInVCFollow: Bool,
                                   context: [String: Any],
                                   statisticInfo: [String: String]?) -> UIViewController {
        UIViewController()
    }
    
    func getRoundImageForDriveAccordingto(fileType: String) -> UIImage {
        UIImage()
    }
    
    func getSquareImageForDriveAccordingto(fileType: String) -> UIImage {
        UIImage()
    }
    
    
}

class MockDriveMoreDataProvider: DriveMoreDataProviderType {

    var builder: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal) {
                delete
            }
        }
    }

    var delete: MoreItem? {
        MoreItem(type: .delete) {
            true
        } prepareEnable: { () -> Bool in
            true
        } handler: { (_, _) in
        }
    }

    var updater: SKCommon.MoreDataSourceUpdater?

    var outsideControlItems: SKCommon.MoreDataOutsideControlItems?

    // output
    lazy var shareClick: Driver<()> = {
        _shareClick.asDriver(onErrorJustReturn: ())
    }()
    lazy var back: Driver<()> = {
        _back.asDriver(onErrorJustReturn: ())
    }()
    lazy var showReadingPanel: Driver<()> = {
        _showReadingPanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var showPublicPermissionPanel: Driver<()> = {
        _showPublicPermissionPanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var showApplyEditPermission: Signal<InsideMoreDataProvider.ApplyEditScene> = {
        _showApplyEditPermission.asSignal()
    }()
    lazy var historyRecordAction: Driver<()> = {
        _historyRecordAction.asDriver(onErrorJustReturn: ())
    }()
    lazy var showRenamePanel: Driver<()> = {
        _showRenamePanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var importAsDocsAction: Driver<()> = {
        _importAsDocsAction.asDriver(onErrorJustReturn: ())
    }()
    lazy var openInOtherAppAction: Driver<()> = {
        _openInOtherAppAction.asDriver(onErrorJustReturn: ())
    }()
    lazy var didSuspendAction: Driver<Bool> = {
        _suspendAction.asDriver(onErrorJustReturn: false)
    }()
    lazy var showSaveToLocal: Driver<()> = {
        _showSaveToLocal.asDriver(onErrorJustReturn: ())
    }()
    lazy var showOperationHistoryPanel: Signal<()> = {
        _showOperationHistoryPanel.asSignal()
    }()
    lazy var showSensitivtyLabelSetting: Driver<SecretLevel?> = {
        _showSensitivtyLabelSetting.asDriver(onErrorJustReturn: nil)
    }()
    lazy var showForcibleWarning: Signal<()> = {
        _showForcibleWarning.asSignal()
    }()
    lazy var redirectToWiki: Driver<String> = {
        _redirectToWiki.asDriver(onErrorJustReturn: "")
    }()

    // input
    let networkFlowHelper = NetworkFlowHelper()
    let _shareClick = PublishSubject<()>()
    let _back = PublishSubject<()>()
    let _showReadingPanel = PublishSubject<()>()
    let _showPublicPermissionPanel = PublishSubject<()>()
    let _showApplyEditPermission = PublishRelay<InsideMoreDataProvider.ApplyEditScene>()
    let _historyRecordAction = PublishSubject<()>()
    let _showRenamePanel = PublishSubject<()>()
    let _importAsDocsAction = PublishSubject<()>()
    let _openInOtherAppAction = PublishSubject<()>()
    let _suspendAction = PublishSubject<Bool>()
    let _showSaveToLocal = PublishSubject<()>()
    let _showOperationHistoryPanel = PublishRelay<Void>()
    let _showSensitivtyLabelSetting = PublishSubject<SecretLevel?>()
    let _showForcibleWarning = PublishRelay<Void>()
    let _redirectToWiki = PublishSubject<String>()

}
