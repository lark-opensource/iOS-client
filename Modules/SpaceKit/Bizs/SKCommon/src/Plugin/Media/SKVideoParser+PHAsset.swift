//
//  SKVideoParser+Asset.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/11/26.
//

import SKFoundation
import Photos
import RxSwift
import RxCocoa
import LarkUIKit
import LarkSensitivityControl
import SKInfra

extension SKVideoParser {

    func parserVideo(with phAsset: PHAsset) -> Observable<Info> {
        guard phAsset.mediaType == .video else {
            assert(phAsset.mediaType == .video, "should be 'video'")
            DocsLogger.error("PHAsset: asstet mediaType error", extraInfo: ["type": "\(phAsset.mediaType)"], component: LogComponents.pickFile)
            return .error(PError.loadAVAssetError)
        }

        return baseVideoInfo(with: phAsset)
            .flatMap { [weak self] (info) -> Observable<Info> in
                guard let self = self else { return .empty() }
                let resources = PHAssetResource.assetResources(for: phAsset)
                var tempSource: PHAssetResource? = resources.first(where: { $0.type == .fullSizeVideo })
                if tempSource == nil {
                    tempSource = resources.first(where: { $0.type == .video })
                }

                guard let resource = tempSource else {
                    DocsLogger.error("PHAsset: assetResources error", component: LogComponents.pickFile)
                    return .empty()
                }

                if info.filesize <= self.fileMaxSize {
                    info.status = .fillBaseInfo
                    let sandboxURL: URL = info.exportPath?.pathURL ?? URL(fileURLWithPath: "")
                    return self.loadVideoData(by: resource, saveTo: sandboxURL).map { _ in
                        return info
                    }
                } else {
                    info.status = .reachMaxSize
                    DocsLogger.error("视频过大，filesize=\(info.filesize),duration=\(info.duration) ", component: LogComponents.pickFile)
                }
                return .just(info)
            }
    }

    private func baseVideoInfo(with phasset: PHAsset) -> Observable<Info> {
        var fileName = self.name(for: phasset)
        // Some strange filenames may be read, like Adjustments.plist;
        // when the video was edited by the system editor. This will
        // cause some unexpected errors
        //
        // jira: https://jira.bytedance.com/browse/SUITE-62740
        let lowerName = fileName.lowercased()
        if !lowerName.hasSuffix("mp4") && !lowerName.hasSuffix("mov") {
            DocsLogger.info("append mp4", component: LogComponents.pickFile)
            fileName += ".mp4"
        }
        let pathExtention = (fileName as NSString).pathExtension

        let uuid = UUID().uuidString
        let cachePath = SKPickContentType.getUploadCacheUrl(uuid: uuid, pathExtension: pathExtention)
        guard !cachePath.pathString.isEmpty else {
            DocsLogger.error("PHAsset: get cache file path error", component: LogComponents.pickFile)
            return .error(PError.createSandboxPathError)
        }

        return loadAVAsset(with: phasset)
            .flatMap { [weak self] (avAsset) -> Observable<Info> in
                guard let self = self else { return .empty() }
                let info = Info()
                let size = self.resolutionSizeForLocalVideo(for: avAsset)
                info.height = size.height
                info.width = size.width
                info.name = fileName
                info.filesize = UInt64(self.filesize(for: avAsset))
                info.duration = phasset.duration
                info.uuid = uuid
                info.exportPath = cachePath
                info.docSourcePath = SKPickContentType.cacheUrlPrefix + "\(uuid).\(pathExtention)"
                return .just(info)
            }
    }

    fileprivate func loadAVAsset(with asset: PHAsset) -> Observable<AVAsset> {
        return Observable<AVAsset>.create { (observer) -> Disposable in
            do {
                try AlbumEntry.requestAVAsset(forToken: Token(PSDATokens.DocX.docx_insert_video_click_comfirm), manager: PHImageManager.default(), forVideoAsset: asset, options: nil) { avAsset, _, info in
                    if let avAsset = avAsset {
                        observer.onNext(avAsset)
                        observer.onCompleted()
                    } else if (info?[PHImageResultIsInCloudKey] as? NSNumber)?.boolValue == true {
                        DocsLogger.error("PHAsset: requestAVAsset error: inCloud", component: LogComponents.pickFile)
                        observer.onError(PError.loadAVAssetIsInCloudError)
                    } else if let error = info?[PHImageErrorKey] as? Error {
                        DocsLogger.error("PHAsset: requestAVAsset error", error: error, component: LogComponents.pickFile)
                        observer.onError(error)
                    } else {
                        DocsLogger.error("PHAsset: requestAVAsset error", component: LogComponents.pickFile)
                        observer.onError(PError.loadAVAssetError)
                    }
                }
            } catch {
                DocsLogger.error("AlbumEntry: requestAVAsset error")
                observer.onError(PError.loadAVAssetError)
            }
            return Disposables.create()
        }
    }

    /// 获取文件大小，单位：byte
    fileprivate func filesize(for asset: AVAsset) -> Float64 {
        var size: Float64 = 0
        for track in asset.tracks(withMediaType: .video) + asset.tracks(withMediaType: .audio) {
            let dataRate = track.estimatedDataRate
            let duration = CMTimeGetSeconds(track.timeRange.duration)
            size += Float64(dataRate) * duration / 8
        }
        return size
    }

    fileprivate func name(for asset: PHAsset) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        let editedResource = resources.first(where: { $0.type == .fullSizeVideo })
        let originResource = resources.first(where: { $0.type == .video })
        if let origin = originResource {
            return origin.originalFilename
        } else if let edited = editedResource {
            return edited.originalFilename
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd-HH:mm:ss.SSS"
        return formatter.string(from: asset.creationDate ?? Date())
    }

    /// 使用PHAssetResourceManager导出视频
    private func loadVideoData(by resource: PHAssetResource, saveTo sandboxURL: URL) -> Observable<URL> {
        return Observable<URL>.create { (observer) -> Disposable in
            let option = PHAssetResourceRequestOptions()
            option.isNetworkAccessAllowed = true
            do {
                try AlbumEntry.writeData(forToken: Token(PSDATokens.DocX.doc_insert_video_write_data), manager: PHAssetResourceManager.default(), forResource: resource, toFile: sandboxURL, options: option) { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(sandboxURL)
                        observer.onCompleted()
                    }
                }
            } catch {
                DocsLogger.error("AlbumEntry: writeData error")
                observer.onError(PError.loadAVAssetError)
            }
            return Disposables.create()
        }
    }
    
    ///获取视频Size，单位：CGSize
    fileprivate func resolutionSizeForLocalVideo(for asset: AVAsset) -> CGSize {
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return CGSize(width: 0.0, height: 0.0) }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: fabs(size.width), height: fabs(size.height))
    }
}
