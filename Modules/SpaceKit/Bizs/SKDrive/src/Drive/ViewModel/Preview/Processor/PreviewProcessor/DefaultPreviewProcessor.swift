//
//  DefaultPreviewProcessor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/8.
//

import Foundation
import SKCommon
import SKFoundation

/// 预览配置
struct DrivePreviewProcessorConfig {
    /// 是否允许降级为源文件，若本来就不允许降级，此配置不生效
    var allowDowngradeToOrigin: Bool = true
    /// IM接入方式没有源文件下载，需要通过similar文件下载源文件
    var canDownloadOrigin: Bool = false
    /// 预览场景(e.g 从 Doc 附件进入预览为 docsAttach)
    var previewFrom: DrivePreviewFrom = .unknown
    /// 是否在 VCFollow 中
    var isInVCFollow: Bool = false
    /// cache source
    var cacheSource: DriveCacheService.Source
    /// 第三方附件鉴权信息
    var authExtra: String?
}

class DefaultPreviewProcessor: PreviewProcessor {
    let cacheService: DKCacheServiceProtocol
    weak var handler: PreviewProcessHandler?
    let config: DrivePreviewProcessorConfig
    let fileInfo: DKFileProtocol

    init(cacheService: DKCacheServiceProtocol, fileInfo: DKFileProtocol, handler: PreviewProcessHandler, config: DrivePreviewProcessorConfig) {
        self.cacheService = cacheService
        self.fileInfo = fileInfo
        self.handler = handler
        self.config = config
    }

    deinit {
        DocsLogger.driveInfo("DefaultPreviewProcessor -- deinit")
    }

    var downgradeWhenGenerating: Bool {
        return false
    }

    func downgradeWhenPreviewUnavailable(for fileInfo: DKFileProtocol) -> Bool {
        fileInfo.fileType.isSupport && config.allowDowngradeToOrigin
    }
    
    func handle(preview: DKFilePreview, completion: @escaping () -> Void) {
        DocsLogger.driveInfo("DefaultPreviewProcessor -- preview get success: \(preview.previewStatus)")
        switch preview.previewStatus {
        case .ready:
            handleReady(preview: preview, completion: completion)
        case .generating, .failedCanRetry:
            if let longPushInterval = preview.longPushInterval {
                handleGenerating(preview: preview, pullInterval: longPushInterval, completion: completion)
            } else {
                // .generating 或 .failedCanRetry 状态下一定会有 longPushInterval 信息，若没有则说明转码失败。
                handleFailedNoRetry(preview: preview, completion: completion)
            }
        case .failedNoRetry:
            handleFailedNoRetry(preview: preview, completion: completion)
        case .unsupport, .sizeTooBig, .sizeIsZero, .fileEncrypt,
             .unknownArchiveFormat, .archiveNodeOverLimit, .archiveSubNodeOverLimit:
            handleFailed(preview: preview, completion: completion)
        }
    }
    
    func handle(error: Error, completion: @escaping () -> Void) {
        defer {
            completion()
        }
        DocsLogger.warning("DefaultPreviewProcessor -- fetch preview url failed", extraInfo: ["errorMsg": error.localizedDescription])
        if downgradeWhenPreviewUnavailable(for: fileInfo) {
            downloadOriginOrSimilarIfNeed()
        } else {
            DocsLogger.driveInfo("DefaultPreviewProcessor --  local not support failed can retry")
            handler?.updateState(.fetchPreviewURLFail(canRetry: true, errorMsg: "local not support, fetch preview url failed: \(error.localizedDescription)"))
        }
    }

    func handleReady(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        defer {
            completion()
        }
        DocsLogger.driveInfo("DefaultPreviewProcessor -- preview get success handle ready: downloadPreview")
        handler?.updateState(.endTranscoding(status: preview.previewStatus))
        
        guard let previewType = fileInfo.getPreferPreviewType(isInVCFollow: config.isInVCFollow) else {
            spaceAssertionFailure("DefaultPreviewProcessor -- previewType is nil")
            handler?.updateState(.unsupport(type: .typeUnsupport))
            return
        }
        
        DocsLogger.driveInfo("DefaultPreviewProcessor -- download preview")
        handler?.updateState(.downloadPreview(previewType: previewType, customID: nil))
    }

    func handleGenerating(preview: DriveFilePreview, pullInterval: Int64, completion: @escaping (() -> Void)) {
        defer {
            completion()
        }
        if downgradeWhenGenerating && fileInfo.fileType.isSupport {
            DocsLogger.driveInfo("DefaultPreviewProcessor -- preview get success generating can downgrade start download orgin file")
            downloadOriginOrSimilarIfNeed()
        } else {
            DocsLogger.driveInfo("DefaultPreviewProcessor -- preview get success generating can't downgrade waitinng")
            handler?.updateState(.startTranscoding(pullInterval: pullInterval, handler: { [weak self] in
                guard let self else { return }
                guard let handler = self.handler else { return }
                guard handler.isWaitTranscoding else {
                    DocsLogger.driveInfo("DefaultPreviewProcessor -- transcoding is ended, ignore click action")
                    return
                }
                handler.updateState(.endTranscoding(status: preview.previewStatus))
                downloadOriginOrSimilarIfNeed()
            }))
        }
    }

    func handleFailedNoRetry(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        defer {
            completion()
        }
        DocsLogger.driveInfo("DefaultPreviewProcessor -- preview get success failed not retry")
        handler?.updateState(.endTranscoding(status: preview.previewStatus))
        if downgradeWhenPreviewUnavailable(for: fileInfo) {
            downloadOriginOrSimilarIfNeed()
        } else {
            DocsLogger.driveInfo("DefaultPreviewProcessor -- local not support failed preview")
            handler?.updateState(.fetchPreviewURLFail(canRetry: false, errorMsg: "preview get failed not retry and local not support"))
        }
    }

    func handleFailed(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        defer {
            completion()
        }
        DocsLogger.driveInfo("DefaultPreviewProcessor -- preview get success failed status", extraInfo: ["status": preview.previewStatus.rawValue])
        handler?.updateState(.endTranscoding(status: preview.previewStatus))
        if downgradeWhenPreviewUnavailable(for: fileInfo) {
            downloadOriginOrSimilarIfNeed()
        } else {
            DocsLogger.driveInfo("DefaultPreviewProcessor -- local not support show unsupport")
            let unsupportType = DriveUnsupportPreviewType(previewStatus: preview.previewStatus)
            handler?.updateState(.unsupport(type: unsupportType))
        }
    }
    
    func downloadOriginOrSimilarIfNeed() {
        if config.canDownloadOrigin {
            DocsLogger.driveInfo("DefaultPreviewProcessor -- local support start download origin file")
            handler?.updateState(.downloadOrigin)
        } else {
            DocsLogger.driveInfo("DefaultPreviewProcessor -- local support start download similar file")
            handler?.updateState(.downloadPreview(previewType: .similarFiles, customID: nil))
        }
    }
    
    func saveCacheData<T: Codable>(_ data: T, type: DriveCacheType) {
        DispatchQueue.global().async {
            do {
                let jsonEncoder = JSONEncoder()
                let data = try jsonEncoder.encode(data)
                let basicInfo = DriveCacheServiceBasicInfo(cacheType: type,
                                                         source: self.config.cacheSource,
                                                         token: self.fileInfo.fileID,
                                                         fileName: self.fileInfo.name,
                                                         fileType: nil,
                                                         dataVersion: self.fileInfo.dataVersion,
                                                         originFileSize: self.fileInfo.size)
                self.cacheService.saveData(data: data, basicInfo: basicInfo, completion: nil)
            } catch {
                DocsLogger.error("DefaultPreviewProcessor -- save video streaming info failed with encode error", error: error)
            }
        }
    }
}
