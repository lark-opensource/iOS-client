//
//  DriveModule.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/7.
//  


import Foundation
import SpaceInterface
import LarkRustClient
import EENavigator
import SKCommon
import SKUIKit
import SKFoundation
import LarkCache
import LibArchiveKit
import SKResource
import SKInfra
import LarkContainer

public final class DriveModule: ModuleService {

    public init() {}

    // 在 register 事件完成后的回调
    public func setup() {
        DocsContainer.shared.register(DriveModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)

        DocsContainer.shared.register(DriveRustRouterBase.self, factory: { (_) -> DriveRustRouterBase in
            return SpaceRustRouter.shared
        }).inObjectScope(.container)
        DocsContainer.shared.register(DriveRouterBase.self, factory: { (_) -> DriveRouterBase in
            return DriveRouter()
        }).inObjectScope(.container)

        DocsContainer.shared.register(DriveVCFactoryType.self, factory: { (_) -> DriveVCFactoryType in
            return DriveVCFactory.shared
        }).inObjectScope(.container)

        DocsContainer.shared.register(DriveUploadCacheServiceBase.self, factory: { (_) -> DriveUploadCacheServiceBase in
            return DriveUploadCacheService()
        }).inObjectScope(.container)
 
        DocsContainer.shared.register(DriveDownloadCallbackServiceBase.self, factory: { (_) -> DriveDownloadCallbackServiceBase in
            return DriveDownloadCallbackService.shared
        }).inObjectScope(.container)

        DocsContainer.shared.register(DriveCacheServiceBase.self, factory: { (_) -> DriveCacheServiceBase in
            return DriveCacheService.shared
        }).inObjectScope(.container)
        DocsContainer.shared.register(DriveCacheServiceProtocol.self) { (_) -> DriveCacheServiceProtocol in
            return DriveCacheService.shared
        }
        DocsContainer.shared.register(DrivePreloadServiceBase.self, factory: { (_) -> DrivePreloadServiceBase in
            return DrivePreloadService.shared
        }).inObjectScope(.container)
        DocsContainer.shared.register(DrivePreviewRecorderBase.self, factory: { (_) -> DrivePreviewRecorderBase in
            return DrivePreviewRecorder.shared
        }).inObjectScope(.container)
        DocsContainer.shared.register(DriveConvertFileConfigBase.self, factory: { (_) -> DriveConvertFileConfigBase in
            return DriveConvertFileConfig()
        }).inObjectScope(.container)

        DocsContainer.shared.register(DriveUploadCallbackServiceBase.self, factory: { (_) -> DriveUploadCallbackServiceBase in
            return DriveUploadCallbackService.shared
        }).inObjectScope(.container)

        DocsContainer.shared.register(DriveUploadStatusManagerBase.self, factory: { (_) -> DriveUploadStatusManagerBase in
            return DriveUploadStatusManager.shared
        }).inObjectScope(.container)

        DocsContainer.shared.register(DriveAutoPerformanceTestBase.self, factory: { (_, navigator) -> DriveAutoPerformanceTestBase in
            return DriveAutoPerformanceTest(navigator: navigator)
        })

        //在SpaceKitAssemble注册过一次了，在DocsContainer就不用重复注册
        if !DocsContainer.shared.useLarkContainer {
            
            DocsContainer.shared.register(DocCommonDownloadProtocol.self, factory: { (_) -> DocCommonDownloadProtocol in
                return DocCommonDownloader()
            })
            
            DocsContainer.shared.register(DocCommonUploadProtocol.self, factory: { (_) -> DocCommonUploadProtocol in
                return DocCommonUploader()
            }).inObjectScope(.container)
        }
        

        //如果使用的是LarkContainer，则已经在SpaceKitAssemble注册过了，这里不用再次注册，后续fg放开可以去掉
        if !DocsContainer.shared.useLarkContainer {
            DocsContainer.shared.register(SpaceDownloadCacheProtocol.self, factory: { (_) -> SpaceDownloadCacheProtocol in
                return DocDownloadCacheService.shared
            })
            DocsContainer.shared.register(DriveMoreActionProtocol.self, factory: { (_) -> DriveMoreActionProtocol in
                return DriveFileExportCapacity.shared
            })
        }
        
        DocsContainer.shared.register(UploadAndDownloadStastis.self) { _ -> UploadAndDownloadStastis in
            return DriveUploadAndDonwloadStastic.shared
        }

        DocsContainer.shared.register(SM4GCMExternalDecrypter.self) { _ in
            return SpaceRustRouter.shared
        }.inObjectScope(.container)
        
        DocsContainer.shared.register(DrivePermissionSDK.self) { resolver in
            let permissionSDK = resolver.resolve(PermissionSDK.self)!
            return DrivePermissionSDKImpl(permissionSDK: permissionSDK)
        }
    }

    public func registerURLRouter() {
        // Drive
        SKRouter.shared.register(types: [.file]) { resource, context, _ -> UIViewController in
            if let url = resource as? URL {
                return DriveVCFactory.shared.makeDrivePreview(url: url, context: context as? [String: Any])
            } else if let fileEntry = resource as? SpaceEntry {
                let source: FileListStatistics.Module = (context?[SKEntryBody.fromKey] as? FileListStatistics.Module) ?? .unknown
                let fileList: [SpaceEntry] = (context?[SKEntryBody.fileEntryListKey] as? [SpaceEntry]) ?? []
                return DriveVCFactory.shared.makeDrivePreview(file: fileEntry,
                                                              fileList: fileList,
                                                              from: source.converToDriveFrom(),
                                                              statisticInfo: [:])
            } else {
                spaceAssertionFailure("somethine wrong here, so that i just return an empty VC")
                return UIViewController()
            }
        }
        
        Navigator.shared.registerRoute(type: DriveThirdPartyAttachControllerBody.self) {
            return DriveThirdPartyAttachPreviewControllerHandler()
        }
        Navigator.shared.registerRoute(type: DriveSDKLocalFileBody.self) {
            return DriveSDKLocalFileHandler()
        }
        
        Navigator.shared.registerRoute(type: DriveSDKAttachmentFileBody.self) {
            return DriveSDKThirdPartyFileHandler()
        }
        
        Navigator.shared.registerRoute(type: DriveSDKIMFileBody.self) {
            return DriveSDKIMFileHandler()
        }
    }

    public func userDidLogin() {
        //传输Rust Client实例到Drive业务中，需要在SDK初始化流程中完成
        //From DocsSDK initDriveSDK
        DocsLogger.driveInfo("initDriveSDK")
        if let rustService = DocsContainer.shared.resolve(RustService.self) {
            SpaceRustRouter.shared.update(rustService: rustService)
        } else {
            DocsLogger.error("initDriveSDK error, init rust client first!")
        }
        // Drive & Wiki 初始化延迟2秒
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) {
            self.configDriveSDK()
        }
    }

     public func userDidLogout() {
        DocsLogger.driveInfo("reset DriveSDK init status")
        // 退出登陆后重新登录，如果通过监听这个信号，会获取到上传次的状态， 所以在退出登录重置状态
        SpaceRustRouter.shared.driveInitFinishObservable.accept(false)
    }
}


extension DriveModule {

    private func configDriveSDK() {
        //初始化Drive Rust端业务：工作队列，DB等
        //From DocsSDK configDriveSDK
        let storagepath = SKFilePath.driveLibraryDir
        let CDNDownloadDisabled = DriveFeatureGate.defaultDriveRustConfig.disableCdnDownload
        let CDNDomainNewSelectEnabled = DriveFeatureGate.defaultDriveRustConfig.newCdnDomainSelect
        let maxThreadSize = DriveFeatureGate.defaultDriveRustConfig.maxThreadSize
        let maxDownlaodPartSize = DriveFeatureGate.defaultDriveRustConfig.maxDownloadPartSize
        let smallUploadSize = DriveFeatureGate.defaultDriveRustConfig.smallUploadFileSize

        DocsLogger.driveInfo("DriveSdk.init_sdk config", extraInfo: ["CDNDownloadDisabled": CDNDownloadDisabled,
                                                                "CDNDomainNewSelectEnabled": CDNDomainNewSelectEnabled,
                                                                "maxThreadSize": maxThreadSize,
                                                                "maxDownlaodPartSize": maxDownlaodPartSize])
        var rustConfig = DriveRustConfig()
        rustConfig.newCdnDomainSelect = CDNDomainNewSelectEnabled
        rustConfig.maxThreadSize = Int32(maxThreadSize)
        rustConfig.maxDownloadPartSize = Int32(maxDownlaodPartSize)
        rustConfig.smallUploadFileSize = Int32(smallUploadSize)
        rustConfig.uploadOptimize = true

        let userInfo = DriveRustUserInfo(userId: User.current.info?.userID ?? "",
                                         tenantId: User.current.info?.tenantID ?? "",
                                         session: User.current.token ?? "",
                                         deviceID: CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.deviceID) ?? "")
        

        SpaceRustRouter.shared.config(storagePath: storagepath.pathString,
                                      userInfo: userInfo,
                                      driveConfig: rustConfig,
                                      disableCDNDownload: CDNDownloadDisabled)

        DriveManualOfflineService.shared.reload(userID: User.current.info?.userID)
        
        unzipPreviewResourcesIfNeeded()
    }
}

// MARK: 解压drive预览资源
extension DriveModule {
    
    private var appVersion: String? { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String }
    private static var folderName: String { "DrivePreviewResources" } // 目录名
    private static var outputPath: SKFilePath { SKFilePath.driveLibraryDir.appendingRelativePath(Self.folderName) } // 解压路径
    private var versionPath: SKFilePath { Self.outputPath.appendingRelativePath("unzip_bundle_version") } // 解压路径下版本号记录
   
    
    // public是因为要给spacedemo用
    public final func unzipPreviewResourcesIfNeeded() {
        
        if versionPath.exists {
            let version = try? String.read(from: versionPath)
            if version != nil, version == appVersion {
                // no-op
                DocsLogger.driveInfo("no need to unzip preview resources")
            } else {
                try? Self.outputPath.cleanDir()
                doUnzipPreviewResources()
            }
        } else {
            doUnzipPreviewResources()
        }
    }
    
    private func doUnzipPreviewResources() {
        guard let zipfilePath = I18n.resourceBundle.path(forResource: "\(Self.folderName)/drive_prev_res", ofType: "7z") else {
            DocsLogger.error("cannot get drive_prev_res zipfile")
            return
        }
        do {
            let file = try LibArchiveFile(path: zipfilePath)
            try file.extract7z(toDir: Self.outputPath.pathURL)
            DocsLogger.driveInfo("decompress drive preview res zipfile succeed")
            
            if let version = appVersion, let data = version.data(using: .utf8), !data.isEmpty {
                _ = versionPath.writeFile(with: data, mode: .over)
                DocsLogger.driveInfo("write version [\(version)] to file:\(versionPath)")
            } else {
                DocsLogger.driveInfo("appVersion is empty")
            }
        } catch {
            DocsLogger.error("decompress 7z failed", error: error)
        }
    }
    
    static func getPreviewResourceURL(name: String, extensionType: String) -> URL? {
        let fileName = "\(name).\(extensionType)"
        let targetPath = outputPath.appendingRelativePath(fileName)
        let outputFiles = outputPath.fileListInDirectory() ?? []
        for file in outputFiles where file.contains(fileName) {
            DocsLogger.driveInfo("get preview resource succeed: \(targetPath)")
            return targetPath.pathURL
        }
        DocsLogger.driveInfo("get preview resource failed: \(targetPath)")
        return nil
    }
}
