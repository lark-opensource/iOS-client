//
//  DefaultFileInfoProcessor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/6.
//

import Foundation
import SKCommon
import SKFoundation
import RxRelay
import LarkSecurityComplianceInterface
import LarkDocsIcon
import SpaceInterface
import SKInfra

// 配置项
struct DriveFileInfoProcessorConfig {
    // IM附件比较特殊，所有的文件都需要走转码（包括相似文件）
    // 同时又需要使用wps预览，无法使用preferPreview判断
    let isIMFile: Bool
    
    let isIMFileEncrypted: Bool
    // 在服务端转码可用时，优先使用服务端转码文件，会影响缓存判断
    var preferPreview: Bool
    // 第三方附件业务鉴权信息
    let authExtra: String?
    /// Cache Source
    let cacheSource: DriveCacheService.Source
    let previewFrom: DrivePreviewFrom
    let isInVCFollow: Bool
    let appID: String
    let scene: DKPreviewScene
    
    // 根据来源、文件类型、是否vcfollow判断是否优先使用转码文件
    static func preferPreview(fileType: DriveFileType, previewFrom: DrivePreviewFrom, isInVCFollow: Bool) -> Bool {
        let preferRemoteWhenReachable = preferRemotePreviewWhenReachable(type: fileType)
        DocsLogger.driveInfo("FileInfoProcessor -- perferRemote when reachable: \(preferRemoteWhenReachable)")
        // 历史版本的office文件优先使用转码，不走wps
        let isOfficeInHistory = (previewFrom == .history) && fileType.isOffice
        // vcFollow的office文件优先使用转码，不走wps
        let isOfficeInVCFollow = isInVCFollow && fileType.preferRemotePreviewInVCFollow
        return isOfficeInHistory || isOfficeInVCFollow || preferRemoteWhenReachable
    }
    
    // 某些本地支持效果比转码效果差，为了避免在上传后本地有源文件缓存的场景，会使用源文件打开，导致效果较差的问题
    // 在有网络的情况下，优先使用在线转码后的结果，在无网络的情况下才使用本地源文件预览
    static func preferRemotePreviewWhenReachable(type: DriveFileType) -> Bool {
        switch type {
        case .svg, .psd, .psb: // 目前只有svg
            return DocsNetStateMonitor.shared.isReachable
        default:
            return false
        }
    }
}

class DefaultFileInfoProcessor: FileInfoProcessor {
    let cacheService: DKCacheServiceProtocol
    let config: DriveFileInfoProcessorConfig
    let networkStatus: SKNetStatusService
    private(set) var originFileInfo: DKFileProtocol

    required init(cacheService: DKCacheServiceProtocol,
                  fileInfo: DKFileProtocol,
                  config: DriveFileInfoProcessorConfig,
                  networkStatus: SKNetStatusService = DocsNetStateMonitor.shared) {
        self.cacheService = cacheService
        self.originFileInfo = fileInfo
        self.config = config
        self.networkStatus = networkStatus
    }

    var useCacheIfExist: Bool {
        return true
    }
    
    func getCachePreviewInfo(fileInfo: DKFileProtocol) -> DriveProccessState? {
        
        if let state = getOfflineCACState(fileId: fileInfo.fileID) {
            return state
        }
        guard canOpenFromCache(fileInfo) else {
            DocsLogger.driveInfo("FileInfoProcessor -- file type cannot open from cache", extraInfo: ["type": fileInfo.type])
            return nil
        }
        if let unsupportType = fileUnsupportType(fileInfo: fileInfo) {
            return .unsupport(type: unsupportType)
        }
        
        guard cacheFileIsSupported(fileInfo: fileInfo) else {
            DocsLogger.driveInfo("FileInfoProcessor -- can not preview cached file： \(fileInfo.type)")
            return .unsupport(type: .typeUnsupport)
        }

        var cacheNode: DriveCache.Node?
        if config.preferPreview {
            DocsLogger.driveInfo("FileInfoProcessor -- preview prefer： \(fileInfo.type)")
            cacheNode = try? cacheService.getFile(type: .preview, fileExtension: fileInfo.fileExtension, dataVersion: fileInfo.dataVersion).get()
        } else {
            cacheNode = cacheFileNode(fileInfo: fileInfo)
        }
        guard let node = cacheNode else {
            DocsLogger.driveInfo("FileInfoProcessor -- file cache node not found")
            return nil
        }
        guard let fileURL = node.fileURL else {
            spaceAssertionFailure("FileInfoProcessor -- cache node file path not set")
            return nil
        }
        let codec = fileURL.getVideoCodecType()
        DocsLogger.driveInfo("FileInfoProcessor -- video codec: \(codec)")
        
        let originFileType = DriveFileType(fileExtension: node.record.originFileExtension)
        let previewFileType = DriveFileType(fileExtension: node.fileExtension)
        let previewInfo: DriveProccesPreviewInfo
        if fileInfo.fileType.isMedia && fileInfo.fileType.isVideoPlayerSupport {
            let videoInfo = DriveVideo(type: .local(url: fileURL),
                                       info: nil,
                                       title: fileInfo.name,
                                       size: fileInfo.size,
                                       cacheKey: fileInfo.videoCacheKey, authExtra: config.authExtra)
            previewInfo = .localMedia(url: fileURL, video: videoInfo)
        } else {
            previewInfo = .local(url: fileURL, originFileType: originFileType)
        }
        return .setupPreview(fileType: previewFileType, info: previewInfo)
    }
    
    func handle(fileInfo: DKFileProtocol, hasOpenFromCache: Bool, complete: @escaping (DriveProccessState?) -> Void) {
        let preferRemote = checkIfPreferRemotePreview(curFileInfo: originFileInfo, newFileInfo: fileInfo)
        let isSameFile = checkIfIsSameFile(curFileInfo: originFileInfo, newFileInfo: fileInfo)
        DocsLogger.driveInfo("FileInfoProcessor -- hasOpenFromCache: \(hasOpenFromCache), preferRemote: \(preferRemote), isSameFile: \(isSameFile)")
        if hasOpenFromCache && isSameFile && !preferRemote {
            DocsLogger.driveInfo("FileInfoProcessor -- 缓存文件和拉取到的fileInfo没有变化，不需要进行后续请求")
            complete(nil)
        } else {
            DocsLogger.driveInfo("FileInfoProcessor -- 没有使用缓存预览/文件有变化，走正常加载流程")
            deleteCacheFileIfNeeded(curFileInfo: originFileInfo, newFileInfo: fileInfo)
            let state = handleSuccess(fileInfo)
            complete(state)
        }
    }
    
    func downloadFile(fileInfo: DKFileProtocol) -> DriveProccessState? {
        let shouldUserRemotePreview: Bool
        let previewType = fileInfo.getPreferPreviewType(isInVCFollow: config.isInVCFollow)
        if previewType == nil {
            // 后端不支持转码
            DocsLogger.driveInfo("FileInfoProcessor -- 后端不支持转码")
            shouldUserRemotePreview = false
        } else if config.preferPreview {
            // 配置为优先使用服务端转码
            DocsLogger.driveInfo("FileInfoProcessor -- 配置优先使用后端转码")
            shouldUserRemotePreview = true
        } else {
            // 判断是否优先使用本地预览
            shouldUserRemotePreview = !fileInfo.fileType.preferLocalPreview
        }
        if shouldUserRemotePreview {    // 后端支持转码，具体类型看DrivePreviewFileType
            if previewType == .similarFiles { // 相似文件类型不需要判断previewStatus
                guard fileInfo.fileType.isSupport else {
                    DocsLogger.driveInfo("FileInfoProcessor -- 不支持相似文件预览")
                    return .unsupport(type: .typeUnsupport)
                }
                DocsLogger.driveInfo("FileInfoProcessor -- 开始请求转码信息")
                return .startPreviewGet
            }
            var previewStatus = fileInfo.previewStatus
            if let previewType = previewType {
                previewStatus = fileInfo.previewMetas[previewType]?.previewStatus.rawValue ?? fileInfo.previewStatus
            }
            if previewStatus == DriveFilePreview.PreviewStatus.generating.rawValue ||
                previewStatus == DriveFilePreview.PreviewStatus.ready.rawValue {
                DocsLogger.driveInfo("FileInfoProcessor -- begin fetch preview URL")
                return .startPreviewGet
            } else if fileInfo.fileType.isSupport {
                DocsLogger.driveInfo("FileInfoProcessor -- 转码失败降级为相似文件")
                return .downloadOrigin
            } else {
                DocsLogger.warning("FileInfoProcessor -- showUnsupportView",
                                   extraInfo: ["previewStatus": previewStatus ?? "unknown"])
                let unsupportType = DriveUnsupportPreviewType(previewStatus: previewStatus)
                return .unsupport(type: unsupportType)
            }
        } else if fileInfo.fileType.isSupport {
            // 下载原文件
            DocsLogger.driveInfo("FileInfoProcessor -- 下载源文件")
            return .downloadOrigin
        } else {
            let previewStatus = fileInfo.previewStatus
            let unsupportType = DriveUnsupportPreviewType(previewStatus: previewStatus)
            DocsLogger.driveInfo("FileInfoProcessor -- unsupport", extraInfo: ["status": previewStatus ?? -1])
            return .unsupport(type: unsupportType)
        }
    }
    
    func handleSuccess(_ fileInfo: DKFileProtocol) -> DriveProccessState? {
        DocsLogger.driveInfo("FileInfoProcessor -- fileInfo加载成功", extraInfo: ["token": DocsTracker.encrypt(id: fileInfo.fileID),
                                                            "fileType": fileInfo.type])
        if let unsupportType = fileUnsupportType(fileInfo: fileInfo) {
            return .unsupport(type: unsupportType)
        }
        DocsLogger.driveInfo("FileInfoProcessor -- file not exist, try download file")
        return downloadFile(fileInfo: fileInfo)
    }

    // 判断两个fileInfo是否为同一个file
    // dataVersion相等并且后缀名相等
    func checkIfIsSameFile(curFileInfo: DKFileProtocol, newFileInfo: DKFileProtocol) -> Bool {
        // 在bitable缩略图场景，缓存的dataversion可能为nil,但是并没有改变版本。
        let dataVersionNotChanged = curFileInfo.dataVersion == nil || (curFileInfo.dataVersion == newFileInfo.dataVersion)
        
        DocsLogger.driveInfo("checkIfIsSameFile -- curFile: \(curFileInfo.dataVersion), newFile: \(newFileInfo.dataVersion)")
        return curFileInfo.fileID == newFileInfo.fileID && dataVersionNotChanged &&
        curFileInfo.type.lowercased() == newFileInfo.type.lowercased()
    }
    
    // 缓存文件不支持预览并且服务端支持转码，优先使用服务端转码
    private func checkIfPreferRemotePreview(curFileInfo: DKFileProtocol, newFileInfo: DKFileProtocol) -> Bool {
        // 缓存文件不支持打开
        let curCacheFileIsUnsupport = !cacheFileIsSupported(fileInfo: curFileInfo)
        // 该文件后端支持转码预览
        let previewType = newFileInfo.getPreferPreviewType(isInVCFollow: config.isInVCFollow)
        let hasRemotePreview = (previewType != nil) && (previewType != .similarFiles)
        DocsLogger.driveInfo("FileInfoProcessor -- curCacheFileIsUnsupport \(curCacheFileIsUnsupport), previewType: \(String(describing: previewType))")
        return curCacheFileIsUnsupport && hasRemotePreview
    }
    
    func deleteCacheFileIfNeeded(curFileInfo: DKFileProtocol, newFileInfo: DKFileProtocol) {
        guard curFileInfo.type != newFileInfo.type else { return }
        cacheService.deleteFile(dataVersion: curFileInfo.dataVersion)
        DocsLogger.driveInfo("FileInfoProcessor -- drive delete not right cache file type")
    }

    private func canOpenFromCache(_ fileInfo: DKFileProtocol) -> Bool {
        if isCacheExist(fileInfo) {
            return useCacheIfExist
        }
        return false
    }
    
    func cacheFileIsSupported(fileInfo: DKFileProtocol) -> Bool {
        var node: DriveCache.Node?
        if config.preferPreview {
            DocsLogger.driveInfo("FileInfoProcessor -- preferPreview")
            node = try? cacheService.getFile(type: .preview, fileExtension: nil, dataVersion: fileInfo.dataVersion).get()
        } else {
            node = cacheFileNode(fileInfo: fileInfo)
        }
            
        guard let cacheNode = node else {
            DocsLogger.driveInfo("FileInfoProcessor -- has no cache node")
            return false
        }
        let localFileType = DriveFileType(fileExtension: cacheNode.fileExtension)
        DocsLogger.driveInfo("FileInfoProcessor -- cache local file type \(localFileType)")
        return localFileType.isSupport
    }

    private func isCacheExist(_ fileInfo: DKFileProtocol) -> Bool {
        if let previewType = fileInfo.getPreferPreviewType(isInVCFollow: config.isInVCFollow),
           previewType == .html, config.previewFrom != .vcFollow { // 第一次打开dataVersion 为空，导致没有命中缓存
            let cacheType = DriveCacheType.htmlExtraInfo
            return cacheService.isFileExist(type: cacheType, fileExtension: nil, dataVersion: fileInfo.dataVersion)
        }
        
        if config.preferPreview {
            // 优先使用服务端转码文件，只检查服务端转码文件的缓存
            return cacheService.isFileExist(type: .preview, fileExtension: fileInfo.fileExtension, dataVersion: fileInfo.dataVersion)
        }
        
        let originFileExist = cacheService.isFileExist(type: .similar, fileExtension: fileInfo.fileExtension, dataVersion: fileInfo.dataVersion)
        let previewFileExist = cacheService.isFileExist(type: .preview, fileExtension: fileInfo.fileExtension, dataVersion: fileInfo.dataVersion)
        return originFileExist || previewFileExist
    }
    
    func cacheFileNode(fileInfo: DKFileProtocol) -> DriveCache.Node? {
        var node: DriveCache.Node?
        node = try? cacheService.getFile(type: .preview, fileExtension: nil, dataVersion: fileInfo.dataVersion).get()
        if node == nil {
            DocsLogger.driveInfo("FileInfoProcessor -- preview node no cached")
            node = try? cacheService.getFile(type: .similar, fileExtension: nil, dataVersion: fileInfo.dataVersion).get()
        }
        return node
    }
    
    /// 离线场景CAC只管控云空间Drive文件
    func getOfflineCACState(fileId: String) -> DriveProccessState? {
        if !networkStatus.isReachable && config.scene == .space {
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
                let request = PermissionRequest(token: fileId, type: .file, operation: .preview, bizDomain: .ccm, tenantID: nil)
                let response = permissionSDK.validate(request: request)
                if !response.allow {
                    return .cacDenied
                }
            } else {
                let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFilePreView, fileBizDomain: config.previewFrom.transfromBizDomain, docType: .file, token: fileId)
                if !result.allow {
                    return .cacDenied
                }
            }
        }
        return nil
    }
}

/// Helpers
extension DefaultFileInfoProcessor {
    private func fileUnsupportType(fileInfo: DKFileProtocol) -> DriveUnsupportPreviewType? {
        if fileInfo.size == 0 {
            DocsLogger.driveInfo("FileInfoProcessor -- file size is zero")
            return .sizeIsZero
        }

        if fileInfo.size > fileInfo.fileType.fileSizeLimits {
            DocsLogger.driveInfo("FileInfoProcessor -- 缓存文件大小超过限制")
            return .sizeTooBig
        }
        return nil
    }
    
    func saveCacheData<T: Codable>(_ data: T, type: DriveCacheType, fileInfo: DKFileProtocol) {
        DispatchQueue.global().async {
            do {
                let jsonEncoder = JSONEncoder()
                let data = try jsonEncoder.encode(data)
                let basicInfo = DriveCacheServiceBasicInfo(cacheType: type,
                                                         source: self.config.cacheSource,
                                                         token: fileInfo.fileID,
                                                         fileName: fileInfo.name,
                                                         fileType: nil,
                                                         dataVersion: fileInfo.dataVersion,
                                                         originFileSize: fileInfo.size)
                self.cacheService.saveData(data: data, basicInfo: basicInfo, completion: nil)
            } catch {
                DocsLogger.driveError("FileInfoProcessor -- save cache data failed with encode error", error: error)
            }
        }
    }
}
