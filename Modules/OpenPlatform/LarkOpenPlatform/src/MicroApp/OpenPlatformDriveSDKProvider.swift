//
//  DriveSDKProvider.swift
//  LarkOpenPlatform
//
//  Created by baojianjun on 2022/8/26.
//

import Foundation
import SpaceInterface
import Swinject
import RxSwift
import OPPlugin
import UIKit

class OpenPlatformDriveSDKProvider {
    private var uploader: DocCommonUploadProtocol? {
        return resolver.resolve(DocCommonUploadProtocol.self)
    }
    private var downloader: DocCommonDownloadProtocol? {
        return resolver.resolve(DocCommonDownloadProtocol.self)
    }
    private var driveSDK: DriveSDK? {
        return resolver.resolve(DriveSDK.self)
    }
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }
}

// MARK: - Upload

extension DocCommonUploadStatus {
    var toPluginUploadStatus: OpenPluginDriveUploadStatus {
        switch self {
        case .cancel: return .cancel
        case .failed: return .failed
        case .inflight: return .inflight
        case .pending: return .pending
        case .queue: return .queue
        case .ready: return .ready
        case .success: return .success
        @unknown default:
            return .pending
        }
    }
}

extension OpenPlatformDriveSDKProvider: OpenPluginDriveUploadProxy {
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                extra: [String : String]?) -> Observable<(String, Float, String, OpenPluginDriveUploadStatus)> {
        guard let uploader = uploader else {
            return Observable<(String, Float, String, OpenPluginDriveUploadStatus)>.empty()
        }
        
        return uploader.upload(localPath: localPath,
                               fileName: fileName,
                               mountNodePoint: mountNodePoint,
                               mountPoint: mountPoint,
                               copyInsteadMoveAfterSuccess: true,
                               priority: .default,
                               extra: extra)
        .map({ ($0.0, $0.1, $0.2, $0.3.toPluginUploadStatus) })
    }

    func cancelUpload(key: String) -> Observable<Bool> {
        guard let uploader = uploader else {
            return Observable<Bool>.just(false)
        }
        return uploader.cancelUpload(key: key)
    }

    func resumeUpload(key: String) -> Observable<Bool> {
        guard let uploader = uploader else {
            return Observable<Bool>.just(false)
        }
        return uploader.resumeUpload(key: key)
    }

    func deleteUploadResource(key: String) -> Observable<Bool> {
        guard let uploader = uploader else {
            return Observable<Bool>.just(false)
        }
        return uploader.deleteUploadResource(key: key)
    }
}

// MARK: - Download

extension DocCommonDownloadStatus {
    var toPluginDownloadStatus: OpenPluginDriveDownloadStatus {
        switch self {
        case .cancel: return .cancel
        case .failed: return .failed
        case .inflight: return .inflight
        case .pending: return .pending
        case .queue: return .queue
        case .ready: return .ready
        case .success: return .success
        @unknown default:
            return .pending
        }
    }
}

extension DocCommonDownloadRequestContext {
    init(with context: OpenPluginDriveDownloadRequestContext) {
        self.init(fileToken: context.fileToken,
                  mountNodePoint: context.mountNodePoint,
                  mountPoint: context.mountPoint,
                  priority: DocCommonDownloadPriority.default,
                  downloadType: DocCommonDownloadType.originFile,
                  localPath: context.localFilePath,
                  isManualOffline: false,
                  authExtra: context.extra)
    }
}

extension DocCommonDownloadResponseContext {
    func toPluginResp(reqestCtx: OpenPluginDriveDownloadRequestContext) -> OpenPluginDriveDownloadResponseContext {
        return OpenPluginDriveDownloadResponseContext(requestContext: reqestCtx,
                                                      downloadStatus: downloadStatus.toPluginDownloadStatus,
                                                      downloadProgress: downloadProgress,
                                                      errorCode: errorCode,
                                                      key: key,
                                                      localFilePath: localFilePath,
                                                      fileName: fileName,
                                                      fileType: fileType)
    }
}

extension OpenPlatformDriveSDKProvider: OpenPluginDriveDownloadProxy {
    
    func download(with context: OpenPluginDriveDownloadRequestContext) -> Observable<OpenPluginDriveDownloadResponseContext> {
        guard let downloader = downloader else {
            return Observable<OpenPluginDriveDownloadResponseContext>.empty()
        }
        let result = downloader.download(with: .init(with: context))
            .map({ return $0.toPluginResp(reqestCtx: context) })
        return result
    }
    
    func cancelDownload(key: String) -> Observable<Bool> {
        guard let downloader = downloader else {
            return Observable<Bool>.just(false)
        }
        return downloader.cancelDownload(key: key)
    }
}

// MARK: - Preview

extension OpenPlatformDriveSDKProvider: OpenPluginDrivePreviewProxy {
    func preview(
        contexts: [OpenPluginDrivePreviewContext],
        actions: [OpenPluginDrivePreviewAction]?
    ) -> UIViewController? {
        guard let driveSDK = driveSDK else {
            return nil
        }
        var files = [DriveSDKAttachmentFile]()
        for context in contexts {
            let file = DriveSDKAttachmentFile(fileToken: context.fileToken,
                                              mountNodePoint: context.mountNodePoint,
                                              mountPoint: context.mountPoint,
                                              fileType: nil,
                                              name: nil,
                                              authExtra: context.extra,
                                              dependency: OpenPlatformDrivePreviewDependency(actions: actions))
            files.append(file)
        }
        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)

        let vc = driveSDK.createAttachmentFileController(attachFiles: files,
                                                         index: 0,
                                                         appID: DKSupportedApp.miniApp.rawValue,
                                                         isCCMPermission: false,
                                                         isInVCFollow: false,
                                                         attachmentDelegate: nil, naviBarConfig: naviBarConfig)
        return vc
    }
}

struct OpenPlatformDrivePreviewDependency: DriveSDKDependency {
    var actionDependency: DriveSDKActionDependency {
        return OpenPlatformDriveActionDependency()
    }
    var moreDependency: DriveSDKMoreDependency {
        return OpenPlatformDriveMoreDependency(actionHandlers: actions)
    }
    
    struct OpenPlatformDriveActionDependency: DriveSDKActionDependency {
        var closePreviewSignal: Observable<Void> {
            return .never()
        }
        
        var stopPreviewSignal: Observable<Reason> {
            return .never()
        }
    }

    private let actions: [OpenPluginDrivePreviewAction]?

    init(actions: [OpenPluginDrivePreviewAction]?) {
        self.actions = actions
    }
}

final class OpenPlatformDriveMoreDependency: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> {
        return .just(true)
    }
    var moreMenuEnable: Observable<Bool> {
        return .just(true)
    }
    var actions: [DriveSDKMoreAction] {
        return [.saveToLocal(handler: { [weak self] vc, info in
                    guard let self = self,
                            let saveToLocalActions = self.actionHandlers?.saveToLocalActions else { return }
                    for action in saveToLocalActions {
                        guard case let .saveToLocal(handler) = action else {
                            continue
                        }
                        handler(vc, info.toPluginDownloadCompleteInfo)
                    }
                }),
                .customOpenWithOtherApp(customAction: nil, callback: nil),
                .saveToSpace(handler: { _ in })]
    }

    private let actionHandlers: [OpenPluginDrivePreviewAction]?

    init(actionHandlers: [OpenPluginDrivePreviewAction]?) {
        self.actionHandlers = actionHandlers
    }
}

extension Array where Element == OpenPluginDrivePreviewAction {
    fileprivate var saveToLocalActions: [OpenPluginDrivePreviewAction] {
        return filter { action in
            if case .saveToLocal(_) = action {
                return true
            } else {
                return false
            }
        }
    }
}

extension DKAttachmentInfo {
    fileprivate var toPluginDownloadCompleteInfo: OpenPluginDrivePreviewDownloadCompleteInfo {
        return OpenPluginDrivePreviewDownloadCompleteInfo(
            fileName: name,
            fileToken: fileID,
            fileType: type,
            size: Int(truncatingIfNeeded: size)
        )
    }
}
