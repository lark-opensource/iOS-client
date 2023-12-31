//
//  VideoParser+PHAsset.swift
//  Action
//
//  Created by kongkaikai on 2018/11/25.
//

/// 当前这个工具类是为了方便发送视频消息时候读取视频数据而抽离的；下面说一下读取数据的基本逻辑，以便于理解代码
///
/// PHAsset
/// 1. 输入PHAsset(主要是选图控件)，强制读视频文件主要为密聊发附件应用
/// 2. 获取视频：预览图、名字、文件大小、尺寸、时长、生成缓存文件路径
/// 3. 判断视频是否可以发送
///    - 大于1G不支持
///    - 时长大于5分钟或者文件大小大于300M则走附件
/// 4. 根据3的结果决定发附件还是视频消息
/// 5. 导出视频数据的方式分以下几种，自上而下依次尝试
///    - 尝试直接复制视频二进制
///    - 由`PHAsset`生成`PHAssetResource`调用`PHAssetResourceManager.default().writeData`
///    - `PHImageManager.default().requestExportSession`，以便于构建假消息，然后由外部决定什么时间调用转码逻辑
///
/// 整个过程中所有的异常全都以onError的形式抛出

import UIKit
import Foundation
import Photos // PHAsset
import RxSwift // Observable
import UniverseDesignToast // UDToast
import LarkFoundation // FileUtils
import EENavigator // Navigator
import ByteWebImage // LarkImageService
import LarkPerf // DeviceExtension
import LarkSDKInterface // PathWrapper
import LarkSensitivityControl

private typealias Path = LarkSDKInterface.PathWrapper

extension VideoParser {

    // parserVideo流程: baseVideoInfo(从PHAsset中获取各种信息) + getVideoFile(读取视频数据供发附件使用) + getFirstFrame(获取首帧图片)
    // baseVideoInfo: createVideoSaveURL(创建存储路径) + loadAVAsset(从PHAsset获取到AVAsset)
    // loadAVAsset: getInfoFromAsset(从PHAsset和AVAsset中获取info的exportPath compressPath duration name fileSize originSize naturalSize)
    // getVideoFile: 将视频文件导出到指定路径 + judgeInfo(判断各个属性是否超出限制)
    // getFirstFrame: 使用VE接口获取首帧 + 使用系统接口获取首帧

    /// 解析视频：Copy数据、读取基本信息
    func parserVideo(with phAsset: PHAsset) -> Observable<VideoParseInfo> {
        guard phAsset.mediaType == .video else {
            VideoParser.logger.error(
                "\(self.type) PHAsset: asstet mediaType error",
                additionalData: ["type": "\(phAsset.mediaType)"]
            )
            let error = NSError(domain: "lark.media.parser.error", code: -100, userInfo: [
                NSLocalizedDescriptionKey: "phassert is not video \(phAsset.mediaType)"
            ])
            return .error(VideoParseError.loadAVAssetError(error))
        }
        let resourceID = VideoParser.phassetResourceID(asset: phAsset)
        return baseVideoInfo(with: phAsset)
            .flatMap { (arg0) -> Observable<(VideoParseInfo, AVAsset)> in
                let (info, avAsset) = arg0
                // 文件超出附件发送限制，取消发送
                guard info.filesize <= self.fileMaxSize else {
                    VideoParser.logger.error("\(self.type) PHAsset: file reach max size", additionalData: ["filesize": "\(info.filesize)"])
                    return .error(VideoParseError.fileReachMax(fileSize: info.filesize, fileSizeLimit: self.fileMaxSize))
                }
                // 将资源导入到指定路径上
                return self.getVideoFile(info, phasset: phAsset)
                    .flatMap { [weak self] info -> Observable<(VideoParseInfo, AVAsset)> in
                        guard let self = self else { return .empty() }
                        // 判断视频的各个属性是否可以使用附件发送
                        return self.judgeInfo(info: info, avAsset: avAsset)
                    }
            }.flatMap { [weak self] (arg) -> Observable<VideoParseInfo> in
                let (info, avasset) = arg
                guard let self = self else { return .empty() }
                // 尝试获取首帧图缓存
                VideoParser.logger.info("\(self.type) try to get first frame from cache")
                if let image = LarkImageService.shared.image(with: .default(key: resourceID)) {
                    VideoParser.logger.error("\(self.type) get first frame cache image")
                    info.setPreview(image)
                    info.firstFrameData = self.getFirstFrameImageData(image: image)
                    return .just(info)
                }
                // 获取首帧
                return self.getFirstFrame(info: info, avAsset: avasset).do(onNext: { (info) in
                    // 缓存首帧图片
                    let preview = info.preview
                    if preview.size != .zero {
                        LarkImageService.shared.cacheImage(image: preview, resource: .default(key: resourceID))
                    }
                })
            }
    }

    // 从PHAsset中获取info的各种信息
    func baseVideoInfo(with phAsset: PHAsset) -> Observable<(VideoParseInfo, AVAsset)> {
        guard let cachePath = VideoParser.createVideoSaveURL(userID: userResolver.userID, asset: phAsset, isOriginal: self.isOriginal) else {
            VideoParser.logger.error("\(self.type) PHAsset: get cache file path error")
            let error = NSError(domain: "lark.media.parser.error", code: -100, userInfo: [
                NSLocalizedDescriptionKey: "get phasset url failed \(phAsset) self.isOriginal \(self.isOriginal)"
            ])
            return .error(VideoParseError.createSandboxPathError(error))
        }
        // 从PHAsset获取到AVAsset
        return loadAVAsset(with: phAsset)
            .flatMap { [weak self] (avAsset) -> Observable<(VideoParseInfo, AVAsset)> in
                guard let self = self else { return .empty() }
                return self.getInfoFromAsset(phAsset: phAsset, avAsset: avAsset, cachePath: cachePath)
            }
    }

    // 从phasset和avasset获取部分info
    func getInfoFromAsset(phAsset: PHAsset, avAsset: AVAsset, cachePath: URL) -> Observable<(VideoParseInfo, AVAsset)> {
        let info = VideoParseInfo()
        info.assetUUID = Self.phassetResourceID(asset: phAsset)
        info.videoSendSetting = self.videoSendSetting
        info.isPHAssetVideo = true
        info.modificationDate = phAsset.modificationDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        info.exportPath = cachePath.path + ".mov"
        if userResolver.fg.staticFeatureGatingValue(with: "im.message.send_mov_video") {
            info.compressPath = info.exportPath + ".mov" // VE 目前所有的转码产物都是 mov
        } else {
            info.compressPath = cachePath.path + ".mp4"
        }
        info.duration = CMTimeGetSeconds(avAsset.duration).rounded()
        var name = self.name(for: phAsset)
        if !userResolver.fg.staticFeatureGatingValue(with: "im.message.send_mov_video") {
            // 保证后缀为mp4：系统处理plist等后缀有未知问题
            if !name.lowercased().hasSuffix("mp4") {
                name += ".mp4"
            }
        }
        info.name = name
        info.filesize = UInt64(VideoTranscoder.filesize(for: avAsset))
        if info.filesize == 0 { info.filesize = UInt64(phAsset.size) }
        let originSize = CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight)
        // 获取视频应该转码到多少分辨率
        var strategy = VideoTranscodeStrategy()
        strategy.isOriginal = self.isOriginal
        info.naturalSize = self.transcodeService.adjustVideoSize(originSize, strategy: strategy)
        return .just((info, avAsset))
    }

    // 获取首帧
    func getFirstFrame(info: VideoParseInfo, avAsset: AVAsset) -> Observable<VideoParseInfo> {

        //调用系统API获取视频资源的首帧
        func useSystemAPI(size: CGSize) -> Observable<VideoParseInfo> {
            do {
                let imageInfo = try self.firstFrame(with: avAsset, size: info.naturalSize)
                info.setPreview(imageInfo.0)
                info.firstFrameData = imageInfo.1
                return .just(info)
            } catch let error {
                VideoParser.logger.error("\(self.type) PHAsset: get firstframe error", error: error)
                return .error(VideoParseError.getFirstFrameError(error))
            }
        }
        // 低端机获取第一帧的耗时随着尺寸增大耗时劣化严重，如果是低端机则使用小图
        let firstFrameSize = DeviceExtension.isLowDeviceClassify ? self.calculateSize(
            originSize: info.naturalSize, maxSize: CGSize(width: 400, height: 400)) : info.naturalSize
        // VESDK 内部接口对 iOS 14 以下支持的不完善，降级为系统接口
        if #available(iOS 14.0, *), isInFirstFrameFG, !DeviceExtension.isLowDeviceClassify {
            VideoParser.logger.info("\(self.type) begin get first frame from VE")
            // 使用TTVideoEditor的方法获取首帧，因为可以一定程度上跳过首屏黑帧的问题
            if let imageInfo = getFirstFrameByTTVideoEditor(exportPath: info.exportPath, size: info.naturalSize) {
                info.setPreview(imageInfo.0)
                info.firstFrameData = imageInfo.1
                VideoParser.logger.info("\(self.type) succeed get first frame from VE")
                return .just(info)
            } else {
                VideoParser.logger.info("\(self.type) failed get first frame from VE, begin from system api")
                return useSystemAPI(size: firstFrameSize)
            }
        } else {
            VideoParser.logger.info("\(self.type) begin get first frame from system api")
            return useSystemAPI(size: firstFrameSize)
        }
    }

    /// 低端机获取第一帧的耗时随着尺寸增大耗时劣化严重，如果是低端机则使用小图
    func calculateSize(originSize: CGSize, maxSize: CGSize) -> CGSize {
        var fitSize: CGSize = originSize
        if originSize.width > maxSize.width || originSize.height > maxSize.height {
            let widthScaleRatio: CGFloat = min(1, maxSize.width / originSize.width)
            let heightScaleRatio: CGFloat = min(1, maxSize.height / originSize.height)
            let scaleRatio = min(widthScaleRatio, heightScaleRatio)
            fitSize = CGSize(width: originSize.width * scaleRatio, height: originSize.height * scaleRatio)
        }
        return fitSize
    }

    // 检查各个属性是否符合预期，如果超出限制，将根据具体规则，取消发送或者转为附件
    func judgeInfo(info: VideoParseInfo, avAsset: AVAsset) -> Observable<(VideoParseInfo, AVAsset)> {
        // 超出附件发送限制，取消发送
        guard info.filesize <= self.fileMaxSize else {
            VideoParser.logger.error(
                "\(self.type) PHAsset: file reach max size",
                additionalData: ["filesize": "\(info.filesize)"]
            )
            return .error(VideoParseError.fileReachMax(fileSize: info.filesize, fileSizeLimit: self.fileMaxSize))
        }

        VideoParser.logger.info("\(self.type) avasset tracks \(avAsset.tracks)")
        // 视频不存在视频轨
        if avAsset.tracks(withMediaType: .video).isEmpty {
            info.status = .videoTrackEmpty
            return .just((info, avAsset))
        }

        // 大小超出限制，转附件
        if info.filesize > self.videoSendSetting.fileSize {
            info.status = .reachMaxSize
            return .just((info, avAsset))
        }
        // 时长超出限制，转附件
        if info.duration > self.videoSendSetting.duration {
            info.status = .reachMaxDuration
            return .just((info, avAsset))
        }
        let avasset = AVURLAsset(url: URL(fileURLWithPath: info.exportPath), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        VideoParser.logger.info("\(self.type) avasset tracks count \(avasset.tracks.count)")
        if let videoInfo = VideoTranscoder.videoInfo(avasset: avasset) {
            // 分辨率超出限制，转附件
            if videoInfo.2.width * videoInfo.2.height >
                self.videoSendSetting.resolution.width * self.videoSendSetting.resolution.height {
                info.status = .reachMaxResolution
                return .just((info, avAsset))
            }
            // 帧率超出限制，转附件
            if videoInfo.0 > self.videoSendSetting.frameRate {
                info.status = .reachMaxFrameRate
                return .just((info, avAsset))
            }
            // 码率超出限制，转附件
            if videoInfo.1 > self.videoSendSetting.bitrate {
                info.status = .reachMaxBitrate
                return .just((info, avAsset))
            }
        } else {
            VideoParser.logger.error("\(self.type) get video info failed \(avasset) \(avasset.tracks)")
        }
        VideoParser.logger.info("\(self.type) judge avasset info success")
        info.status = .fillBaseInfo
        return .just((info, avAsset))
    }

    func name(for asset: PHAsset) -> String {
        //低端机获取文件名耗时严重，非低端机获取视频的真实名称，低端机名称用当前时间
        if !DeviceExtension.isLowDeviceClassify {
            if let resource = VideoParser.videoAssetResources(for: asset) {
                return resource.originalFilename
            }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd-HH:mm:ss.SSS"
        return formatter.string(from: asset.creationDate ?? Date())
    }

    fileprivate func loadAVAsset(with asset: PHAsset) -> Observable<AVAsset> {
        // 判断是否在本地（非iCloud等），不在则展示 loading
        let videoLocallyAvailable = VideoParser.videoLocallyAvailable(for: asset)
        if !videoLocallyAvailable {
            /// 如果视频不可用且是预处理类型任务，则直接返回错误
            if self.type == .preprocess {
                return Observable<AVAsset>.error(VideoParseError.canelProcessTask)
            }

            DispatchQueue.main.async {
                if let window = self.userResolver.navigator.mainSceneWindow {
                    VideoParser.hud?.remove()
                    VideoParser.hud = UDToast.showLoading(
                        with: BundleI18n.LarkSendMessage.Lark_Legacy_VideoMessagePrepareToSend,
                        on: window,
                        disableUserInteraction: false)
                }
            }
        }
        return Observable<AVAsset>.create { (observer) -> Disposable in
            VideoParser.logger.info("\(self.type) PHAsset: start requestAVAsset")
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            try? AlbumEntry.requestAVAsset(forToken: VideoParserToken.exportVideo,
                                           manager: PHImageManager.default(),
                                           forVideoAsset: asset,
                                           options: options,
                                           resultHandler: { (avAsset, _, info) in
                VideoParser.logger.info("\(self.type) PHAsset: finsih requestAVAsset \(avAsset) \(info)")
                DispatchQueue.main.async {
                    VideoParser.hud?.remove()
                    VideoParser.hud = nil
                }
                if let avAsset = avAsset {
                    observer.onNext(avAsset)
                    observer.onCompleted()
                } else if (info?[PHImageResultIsInCloudKey] as? NSNumber)?.boolValue == true {
                    VideoParser.logger.error("\(self.type) PHAsset: requestAVAsset error: inCloud")
                    let error = NSError(domain: "lark.media.parser.error", code: -100, userInfo: [
                        NSLocalizedDescriptionKey: "get avasset failed \(info)"
                    ])
                    observer.onError(VideoParseError.loadAVAssetIsInCloudError(error))
                } else if let error = info?[PHImageErrorKey] as? Error {
                    VideoParser.logger.error("\(self.type) PHAsset: requestAVAsset error", error: error)
                    observer.onError(error)
                } else {
                    let error = NSError(domain: "lark.media.parser.error", code: -100, userInfo: [
                        NSLocalizedDescriptionKey: "get avasset failed \(info)"
                    ])
                    VideoParser.logger.error("\(self.type) PHAsset: requestAVAsset error \(info)")
                    observer.onError(VideoParseError.loadAVAssetError(error))
                }
            })
            return Disposables.create()
        }
    }

    // MARK: - 读取视频数据供发附件使用
    private func getVideoFile(_ info: VideoParseInfo, phasset: PHAsset) -> Observable<VideoParseInfo> {
        let sandboxURL = URL(fileURLWithPath: info.exportPath)
        return loadVideoMetadata(with: phasset, to: sandboxURL)
            .catchError { [weak self] error -> Observable<URL> in
                // 如果是 getAVCompositionUrlError 错误 直接跳到下一步
                if let parseError = error as? VideoParseTask.ParseError,
                   case VideoParseError.getAVCompositionUrlError = parseError {
                    return .error(error)
                }
                VideoParser.logger.error("\(self?.type) PHAsset: load video data by resource error", error: error)
                guard let self = self, let resource = VideoParser.videoAssetResources(for: phasset) else {
                    return .error(error)
                }
                return self.loadVideoData(by: resource, saveTo: sandboxURL)
            }.catchError { [weak self] (error) -> Observable<URL> in
                guard let self = self else { return .empty() }
                VideoParser.logger.error("\(self.type) PHAsset: copy file error", error: error)
                if self.type == .preprocess {
                    return .error(VideoParseError.canelProcessTask)
                }
                return self.loadVideoExportData(with: phasset, to: sandboxURL)
            }.map { _ in info }
            .do(onNext: { [weak self](info) in
                guard let self = self else { return }
                let url = info.exportPath
                let fileName = String(URL(string: url)?.path.split(separator: "/").last ?? "")
                let fileSize = try? FileUtils.fileSize(url)
                sendVideoCache(userID: self.userResolver.userID).saveFileName(
                    fileName,
                    size: max(
                        Int(info.filesize),
                        Int(fileSize ?? 0)
                    )
                )
            })
    }

    /// 尝试直接读取视频的元数据，可能会失败
    private func loadVideoMetadata(with asset: PHAsset, to sandboxURL: URL) -> Observable<URL> {
        return Observable<URL>.create { (observer) -> Disposable in

            /// 如果沙盒指定路径存在文件，则直接使用
            if Path(sandboxURL.path).exists {
                VideoParser.logger.info("\(self.type) PHAsset: video data is exists in \(sandboxURL)")
                observer.onNext(sandboxURL)
                observer.onCompleted()
            } else {
                VideoParser.logger.info("\(self.type) start to loadVideoMetadata")
                // TODO: 不应该两次调用 requestAVAsset,虽然耗时很少
                try? AlbumEntry.requestAVAsset(forToken: VideoParserToken.exportVideo,
                                               manager: PHImageManager.default(),
                                               forVideoAsset: asset,
                                               options: nil,
                                               resultHandler: { (asset, _, info) in
                    VideoParser.logger.info("\(self.type) finish to loadVideoMetadata")
                    // 获取视频URL，这里的URL只能在当前闭包使用，出了闭包会失效

                    var path: String?
                    let infoFilePathKey = "PHImageFileSandboxExtensionTokenKey"

                    // avasset 可以直接访问到URL
                    if let avURLAsset = asset as? AVURLAsset {
                        path = avURLAsset.url.path
                    } else if let info = info, let sandboxExtensionTokenKey = info[infoFilePathKey] as? String {
                        // 否则获取的是AVComposition对象，尝试从info中读取URL，在iOS13之前的系统中大部分情况可以成功
                        path = sandboxExtensionTokenKey.components(separatedBy: ";").last
                    }

                    // 如果读到了Path，则尝试Copy数据，否则报错
                    if let path = path {
                        do {
                            try Path(path).copyFile(to: Path(sandboxURL.path))
                            observer.onNext(sandboxURL)
                            observer.onCompleted()
                        } catch let error {
                            if Path(sandboxURL.path).exists {
                                observer.onNext(sandboxURL)
                                observer.onCompleted()
                            } else {
                                VideoParser.logger.error("\(self.type) PHAsset: copyVideoSourceDataError error")
                                observer.onError(VideoParseError.copyVideoSourceDataError(error))
                            }
                        }
                    } else {
                        // 判断 asset 是否是 AVComposition
                        if asset is AVComposition {
                            VideoParser.logger.error("\(self.type) PHAsset: getAVCompositionUrlError error")
                            observer.onError(VideoParseError.getAVCompositionUrlError)
                        } else {
                            VideoParser.logger.error("\(self.type) PHAsset: loadVideoSourceURLError error \(info)")
                            let error = NSError(domain: "lark.media.parser.error", code: -100, userInfo: [
                                NSLocalizedDescriptionKey: "get video failed \(info)"
                            ])
                            observer.onError(VideoParseError.loadVideoSourceURLError(error))
                        }
                    }
                })
            }

            return Disposables.create()
        }
    }

    /// 使用PHAssetResourceManager导出视频
    private func loadVideoData(by resource: PHAssetResource, saveTo sandboxURL: URL) -> Observable<URL> {
        return Observable<URL>.create { (observer) -> Disposable in
            let option = PHAssetResourceRequestOptions()
            option.isNetworkAccessAllowed = true
            VideoParser.logger.info("\(self.type) start to loadVideoData")
            try? AlbumEntry.writeData(forToken: VideoParserToken.exportVideo,
                                      manager: PHAssetResourceManager.default(),
                                      forResource: resource,
                                      toFile: sandboxURL,
                                      options: option) { (error) in
                VideoParser.logger.info("\(self.type) finish to loadVideoData")
                if let error = error, !Path(sandboxURL.path).exists {
                    observer.onError(error)
                } else {
                    observer.onNext(sandboxURL)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    /// 使用requestExportSession导出视频，这种方式可能会发生转码，比较慢;
    private func loadVideoExportData(with asset: PHAsset, to sandboxURL: URL) -> Observable<URL> {
        DispatchQueue.main.async {
            // 无UI上下文，只能暂时取MainScene
            if let window = self.userResolver.navigator.mainSceneWindow {
                VideoParser.hud?.remove()
                VideoParser.hud = UDToast.showLoading(
                    with: BundleI18n.LarkSendMessage.Lark_Legacy_VideoMessagePrepareToSend,
                    on: window,
                    disableUserInteraction: false)
            }
        }
        return Observable<URL>.create { [weak self] (observer) -> Disposable in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            VideoParser.logger.info("\(self.type) start to loadVideoExportData")
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            try? AlbumEntry.requestExportSession(forToken: VideoParserToken.exportVideo,
                                                 manager: PHImageManager.default(),
                                                 forVideoAsset: asset,
                                                 options: options,
                                                 exportPreset: AVAssetExportPresetPassthrough
            ) { [weak self] (exportSession, _) in
                VideoParser.logger.info("\(self?.type) finish to loadVideoExportData")
                guard let `self` = self, let exportSession = exportSession else {
                    let error = NSError(domain: "lark.media.parser.error", code: -100, userInfo: [
                        NSLocalizedDescriptionKey: "session is release"
                    ])
                    observer.onError(VideoParseError.exportVideoDataError(error))
                    observer.onCompleted()
                    return
                }

                self.videoExportSession = exportSession
                exportSession.outputURL = sandboxURL
                exportSession.outputFileType = .mov
                exportSession.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        VideoParser.hud?.remove()
                        VideoParser.hud = nil
                    }
                    switch exportSession.status {
                    case .completed:
                        observer.onNext(sandboxURL)
                        observer.onCompleted()
                    case .cancelled:
                        VideoParser.logger.error("\(self.type) PHAsset: export video user cancel error")
                        observer.onError(VideoParseError.userCancel)
                    default:
                        if Path(sandboxURL.path).exists {
                            observer.onNext(sandboxURL)
                            observer.onCompleted()
                        } else {
                            VideoParser.logger.error("\(self.type) PHAsset: export video data error \(exportSession.status.rawValue) error \(exportSession.error)")
                            let error = exportSession.error ?? NSError(domain: "lark.media.parser.error", code: -100, userInfo: [
                                NSLocalizedDescriptionKey: "export failed"
                            ])
                            observer.onError(VideoParseError.exportVideoDataError(error))
                        }
                    }
                })
            }

            return Disposables.create()
        }
    }

    static func videoAssetResources(for asset: PHAsset) -> PHAssetResource? {
        let resources = PHAssetResource.assetResources(for: asset)
        let supportTypes: [PHAssetResourceType] = [.video, .fullSizeVideo]
        if let current = resources.first(where: { resource in
            if #available(iOS 14, *) {
                var isCurrent = false
                if let value = resource.value(forKey: "isCurrent") as? Bool {
                    isCurrent = value
                }
                return isCurrent && supportTypes.contains(resource.type)
            }
            return false
        }) {
            return current
        }
        return resources.first { $0.type == .video } ?? resources.first
    }

    static func videoLocallyAvailable(for asset: PHAsset) -> Bool {
        let resourceArray = PHAssetResource.assetResources(for: asset)
        var matchedResources: [PHAssetResource] = []
        let supportTypes: [PHAssetResourceType] = [.video, .fullSizeVideo]
        matchedResources = resourceArray.filter({ (resource) -> Bool in
            if #available(iOS 14, *) {
                var isCurrent = false
                if let value = resource.value(forKey: "isCurrent") as? Bool {
                    isCurrent = value
                }
                return supportTypes.contains(resource.type) && isCurrent
            } else {
                return resource.type == .video
            }
        })
        if matchedResources.isEmpty {
            matchedResources = resourceArray.filter({ (resource) -> Bool in
                return resource.type == .video
            })
        }
        if let locallyAvailable = matchedResources.first?.value(forKey: "locallyAvailable") as? Bool {
            return locallyAvailable
        }
        return true
    }
}
