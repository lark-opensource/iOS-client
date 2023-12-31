//
//  VideoAssetParser.swift
//  Action
//
//  Created by K3 on 2018/9/6.
//

import Foundation
import UIKit
import Photos // PHAsset
import LKCommonsLogging // Logger
import LarkSetting
import UniverseDesignToast // UDToast
import LarkSDKInterface // VideoSendSetting
import TTVideoEditor // VideoThumbParam
import LKCommonsTracker // Tracker
import LarkContainer // InjectedLazy
import ByteWebImage // WebP.Encoder
import LarkStorage // IsoPath
import LarkSensitivityControl

private typealias Path = LarkSDKInterface.PathWrapper

public enum VideoParseType {
    case normal
    case preprocess
}

/// 解析视频遇到的错误
public enum VideoParseError: Error {
    /// 提供的Asset不是视频类型的，没地方抛这个错误
    case assetTypeError(Error)
    /// 获取视频大小失败： 文件不存在，读取失败等
    case getVideoSizeError(Error)
    /// 文件大小超出上限
    /// - fileSize: 超出上限的文件大小
    /// - fileSizeLimit: 文件大小上限
    case fileReachMax(fileSize: UInt64, fileSizeLimit: UInt64)
    /// 用户取消发送
    case userCancel
    /// 获取视频信息失败
    case loadAVAssetError(Error)
    /// 获取视频信息失败，在iCloud中
    case loadAVAssetIsInCloudError(Error)
    /// 无法从AVAssert中读取视频轨道
    case videoTrackUnavailable
    /// 直接从PHAsset中读取视频FileURL失败
    case loadVideoSourceURLError(Error)
    /// 创建缓存路径失败
    case createSandboxPathError(Error)
    /// 直接Copy从PHAsset中获取的FileURL的数据失败
    case copyVideoSourceDataError(Error)
    /// 从PHAsset中调用requestExportSession读取视频数据失败
    case exportVideoDataError(Error)
    /// 获取视频首帧失败
    case getFirstFrameError(Error)
    /// 取消预处理任务
    case canelProcessTask
    /// AVComposition 获取视频失败
    case getAVCompositionUrlError
}

/// 视频信息的获取状态
public enum VideoParseStatus {
    /// 空；刚创建
    case empty
    /// 获取到信息，但是视频分辨率超出限制
    case reachMaxResolution
    /// 获取到信息，但是视频帧率超出限制
    case reachMaxFrameRate
    /// 获取到信息，但是视频码率超出限制
    case reachMaxBitrate
    /// 获取到信息，但是视频文件大小超出限制
    case reachMaxSize
    /// 获取到信息，但是视频时长超出超出限制
    case reachMaxDuration
    /// 获取到所有需要信息，且无异常
    case fillBaseInfo
    /// 视频不存在视频轨
    case videoTrackEmpty
}

public final class VideoParseInfo {
    /// 视频首帧
    var _preview: UIImage?
    /// 视频首帧
    public var preview: UIImage { return _preview ?? UIImage() }

    public func setPreview(_ image: UIImage) {
        _preview = image
    }
    /// 文件资源 id， 只有相册资源才会设置
    public var assetUUID = ""
    /// 文件名，供转附件发送使用
    public var name: String = ""
    /// 文件大小
    public var filesize: UInt64 = 0
    /// 分辨率
    public var naturalSize: CGSize = .zero
    /// 导出到沙盒的本地沙盒路径
    public var exportPath: String = ""
    /// 压缩后文件输出路径
    public var compressPath: String = ""
    /// 视频时长（s）
    public var duration: TimeInterval = 0
    /// 信息类型
    public var status: VideoParseStatus = .empty
    /// 是否是相册视频
    public var isPHAssetVideo: Bool = true
    /// 视频上一次修改时间
    public var modificationDate: TimeInterval = Date().timeIntervalSince1970
    // 视频发送配置
    public var videoSendSetting: VideoSendSetting?
    // 首帧图 data 缓存
    public var firstFrameData: Data?

    public init() {
    }
}

public final class VideoParser {
    enum VideoParserToken {
        static let exportVideo = Token("LARK-PSDA-asset_browser_export_video")
    }

    let userResolver: UserResolver
    /// "原图"模式下，视频的沙盒路径后缀，后续会通过是否带该后缀判断是否是"原图"模式发送视频
    public static let originPathSuffix: String = "-lark.origin.model.video.path"

    static let logger = Logger.log(VideoParser.self, category: "Module.VideoParser")

    static var hud: UDToast?

    let transcodeService: VideoTranscodeService

    /// 附件传输上限，超过这个大小的视频不予发送，单位：B
    var fileMaxSize: UInt64 {
        let gigaByte: UInt64 = 1024 * 1024 * 1024
        return 100 * gigaByte
    }

    var videoExportSession: AVAssetExportSession?
    let videoSendSetting: VideoSendSetting
    let isOriginal: Bool
    let type: VideoParseType
    var isInFirstFrameFG: Bool { userResolver.fg.staticFeatureGatingValue(with: "mobile.messenger.first_frame") }

    private var userGeneralSettings: UserGeneralSettings

    init(userResolver: UserResolver, transcodeService: VideoTranscodeService, isOriginal: Bool, type: VideoParseType, videoSendSetting: VideoSendSetting) throws {
        self.userResolver = userResolver
        self.userGeneralSettings = try userResolver.resolve(assert: UserGeneralSettings.self)
        self.transcodeService = transcodeService
        self.isOriginal = isOriginal
        self.type = type
        self.videoSendSetting = videoSendSetting
    }

    /// 将转为附件发送时的提示文案
    func sendWithFileI18n(status: VideoParseStatus) -> String {
        switch status {
        /// 分辨率
        case .reachMaxResolution:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoResolutionExceedLimitAttach
        /// 帧率
        case .reachMaxFrameRate:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoFrameRateExceedLimitAttach
        /// 码率
        case .reachMaxBitrate:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoBitRateExceedLimitAttach
        /// 大小
        case .reachMaxSize:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoFileExceedsNumMBAttachment(
                (Int)(self.videoSendSetting.fileSize / 1024 / 1024)
            )
        /// 时长
        case .reachMaxDuration:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoLongerNumMinAttachment(
                (Int)(self.videoSendSetting.duration / 60)
            )
        /// 视频格式不支持
        case .videoTrackEmpty:
            return BundleI18n.LarkSendMessage.Lark_IMVideo_InvalidVideoFormatSentAsFile_PopupText
        case .empty, .fillBaseInfo:
            return ""
        }
    }

    /// 不支持发送时的提示文案
    public static func notSupportSendI18n(info: VideoParseInfo) -> String {
        guard let videoSendSetting = info.videoSendSetting else {
            assertionFailure()
            return ""
        }

        let status = info.status
        switch status {
        /// 分辨率
        case .reachMaxResolution:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoResolutionExceedLimitCancel
        /// 帧率
        case .reachMaxFrameRate:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoFrameRateExceedLimitCancel
        /// 码率
        case .reachMaxBitrate:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoBitRateExceedLimitCancel
        /// 大小
        case .reachMaxSize:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoFileExceedsNumMBCantSent(
                (Int)(videoSendSetting.fileSize / 1024 / 1024)
            )
        /// 时长
        case .reachMaxDuration:
            return BundleI18n.LarkSendMessage.Lark_Chat_VideoLongerNumMinCantSent(
                (Int)(videoSendSetting.duration / 60)
            )
        case .videoTrackEmpty:
            return BundleI18n.LarkSendMessage.Lark_IMVideo_InvalidVideoFormatUnableToSend_Text
        case .empty, .fillBaseInfo:
            return ""
        }
    }

    /// 创建视频缓存路径, 此处于 ChatFileContentProvider.getDownloadRootFolder 相似
    static func createVideoSaveURL(userID: String, isOriginal: Bool) -> URL? {
        let fileName = String(UUID().uuidString + (isOriginal ? VideoParser.originPathSuffix : ""))
        if Path.useLarkStorage {
            let rootPath = sendVideoCache(userID: userID).iso.rootPath
            try? rootPath.createDirectoryIfNeeded()
            let path = rootPath + fileName
            VideoParser.logger.info("create asset cache path \(path.absoluteString) \(rootPath.exists)")
            return path.url
        } else {
            let rootPath = Path.Old(sendVideoCache(userID: userID).rootPath)
            try? rootPath.createDirectoryIfNeeded()
            let path = rootPath + fileName
            VideoParser.logger.info("create asset cache path \(path.rawValue) \(rootPath.exists)")
            return URL(string: path.rawValue)
        }
    }

    static func phassetResourceID(asset: PHAsset) -> String {
        if let resource = self.videoAssetResources(for: asset) {
            // 按照更新时间区分视频是否被编辑过
            if let modificationDate = asset.modificationDate {
                return resource.assetLocalIdentifier.md5() + "\(modificationDate.timeIntervalSince1970)"
            } else {
                return resource.assetLocalIdentifier.md5()
            }
        } else {
            return asset.localIdentifier.md5()
        }
    }

    /// 创建视频缓存路径, 此处于 ChatFileContentProvider.getDownloadRootFolder 相似, 默认使用 PHAsset resource 作为唯一 id
    static func createVideoSaveURL(userID: String, asset: PHAsset, isOriginal: Bool) -> URL? {
        var videoFileName = self.phassetResourceID(asset: asset)
        // 如果取不到视频 identifier, 仍然使用 UUID
        if videoFileName.isEmpty {
            videoFileName = UUID().uuidString
        }
        let fileName = String(videoFileName + (isOriginal ? VideoParser.originPathSuffix : ""))
        if Path.useLarkStorage {
            let rootPath = sendVideoCache(userID: userID).iso.rootPath
            try? rootPath.createDirectoryIfNeeded()
            let path = rootPath + fileName
            VideoParser.logger.info("create asset cache path \(path.absoluteString) \(rootPath.exists)")
            return path.url
        } else {
            let rootPath = Path.Old(sendVideoCache(userID: userID).rootPath)
            try? rootPath.createDirectoryIfNeeded()
            let path = rootPath + fileName
            VideoParser.logger.info("create asset cache path \(path.rawValue) \(rootPath.exists)")
            return URL(string: path.rawValue)
        }
    }

    /// 获取视频第一帧
    func firstFrame(with asset: AVAsset, size: CGSize) throws -> (UIImage, Data?) {
        let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let coverSetting = self.userGeneralSettings.videoSynthesisSetting.value.coverSetting
        var maximumSize = size
        if coverSetting.limitEnable {
            maximumSize = self.getFirstFrameSize(originSize: size)
        }
        generator.maximumSize = maximumSize
        let image = try generator.copyCGImage(at: CMTimeMake(value: 0, timescale: 10), actualTime: nil)
        let uiImage = UIImage(cgImage: image)
        return (uiImage, self.getFirstFrameImageData(image: uiImage))
    }

    // 使用TTVideoEditor的方法获取首帧，可以跳过首帧黑屏的场景，目前模拟器稳定获取失败
    func getFirstFrameByTTVideoEditor(exportPath: String, size: CGSize) -> (UIImage, Data?)? {
        let coverSetting = self.userGeneralSettings.videoSynthesisSetting.value.coverSetting
        let startTime = CACurrentMediaTime()
        VideoParser.logger.info("\(self.type) video editor log, get first frame")
        let param = VideoThumbParam()
        param.videoPath = exportPath
        param.skipBlackFrame = true
        param.timestamp = self.videoSendSetting.firstFrame.timeStamp

        let skipParam = VideoThumbSkipParam()
        skipParam.blackAmount = self.videoSendSetting.firstFrame.blackAmount
        skipParam.blackThreshold = self.videoSendSetting.firstFrame.blackThreshold
        skipParam.maxSkipFrame = self.videoSendSetting.firstFrame.maxSkipFrame
        skipParam.transitionTime = self.videoSendSetting.firstFrame.transitionTime

        var bytesImage: UIImage?

        let callback = VideoThumbCallback()
        callback.onStartBlock = { () -> Int32 in
            VideoParser.logger.info("\(self.type) video editor log, callback.onStartBlock")
            return 0
        }
        callback.onFinishBlock = { () -> Int32 in
            VideoParser.logger.info("\(self.type) video editor log, callback.onFinishBlock")
            return 0
        }
        callback.allocFrameRGBABlock = { (width, height) -> UnsafeMutablePointer<UInt8>? in
            VideoParser.logger.info("\(self.type) video editor log, callback.allocFrameRGBABlock, \(width) \(height)")
            let bufferSize = 4 * width * height
            return UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bufferSize))
        }
        callback.frameAvailableBlock = { [weak self] (pointer, colorSpace, bitsPerComponent, width, height, realPts) -> Bool in
            guard let self = self else { return false }
            VideoParser.logger.info("\(self.type) video editor log, callback.frameAvailableBlock, \(width) \(height) \(realPts)")
            let imageSize = CGSize(width: CGFloat(width), height: CGFloat(height))
            var toSize = size
            if coverSetting.limitEnable {
                toSize = self.getFirstFrameSize(originSize: size)
            }
            bytesImage = self.imageRefFromBGRABytes(imageBytes: pointer, imageSize: imageSize, size: toSize, colorSpace: colorSpace, bitsPerComponent: bitsPerComponent)
            return true
        }
        // 此方法是同步的，目前模拟器不生效
        let code = VEVideoUtils.getVideoThumb(with: param, videoThumbSkipParam: skipParam, videoThumbCallback: callback)
        if code == 0, let image = bytesImage {
            Tracker.post(TeaEvent("video_first_frame_event_dev", params: [
                "cut_result": 1,
                "cut_duration": (CACurrentMediaTime() - startTime) * 1000,
                "res_code": code
            ]))
            return (image, self.getFirstFrameImageData(image: image))
        } else {
            Tracker.post(TeaEvent("video_first_frame_event_dev", params: [
                "cut_result": 0,
                "cut_duration": (CACurrentMediaTime() - startTime) * 1000,
                "res_code": code
            ]))
            return nil
        }
    }

    // 通过地址，绘制出图片，再将图片缩放为需要的大小
    private func imageRefFromBGRABytes(imageBytes: UnsafeMutablePointer<UInt8>, imageSize: CGSize, size: CGSize, colorSpace: CGColorSpace, bitsPerComponent: UInt32) -> UIImage? {
        let ump = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(4 * imageSize.width * imageSize.height))
        let count = Int(4 * imageSize.width * imageSize.height)
        ump.initialize(from: imageBytes, count: count)
        let context = CGContext(data: ump,
                    width: Int(imageSize.width),
                    height: Int(imageSize.height),
                    bitsPerComponent: Int(bitsPerComponent),
                    bytesPerRow: Int(imageSize.width * 4),
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        defer {
            ump.deinitialize(count: count)
            ump.deallocate()
            imageBytes.deinitialize(count: count)
            imageBytes.deallocate()
        }
        guard let cgImage = context?.makeImage() else { return nil }
        let image = UIImage(cgImage: cgImage)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let imageResult = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        ump.deinitialize(count: Int(4 * imageSize.width * imageSize.height))
        return imageResult
    }

    /// 转化首帧图 size
    func getFirstFrameSize(originSize: CGSize) -> CGSize {
        let coverSetting = self.userGeneralSettings.videoSynthesisSetting.value.coverSetting
        guard coverSetting.limitEnable,
              originSize.width * originSize.height > CGFloat(coverSetting.limitBigSideMax * coverSetting.limitSmallSideMax) else {
            return originSize
        }
        var resultSize: CGSize
        if originSize.width > originSize.height {
            let bigSideRatio = max(originSize.width / CGFloat(coverSetting.limitBigSideMax), 1)
            let smallSideRatio = max(originSize.height / CGFloat(coverSetting.limitSmallSideMax), 1)
            let minRate = min(bigSideRatio, smallSideRatio)
            resultSize = CGSize(width: originSize.width / minRate, height: originSize.height / minRate)
        } else {
            let bigSideRatio = originSize.height / CGFloat(coverSetting.limitBigSideMax)
            let smallSideRatio = originSize.width / CGFloat(coverSetting.limitSmallSideMax)
            let minRate = min(bigSideRatio, smallSideRatio)
            resultSize = CGSize(width: originSize.width / minRate, height: originSize.height / minRate)
        }
        VideoParser.logger.info("\(self.type) get first frame size \(resultSize), origin \(originSize)")
        return resultSize
    }

    /// 转化首帧图 data
    func getFirstFrameImageData(image: UIImage) -> Data? {
        let coverSetting = self.userGeneralSettings.videoSynthesisSetting.value.coverSetting
        guard coverSetting.limitEnable else {
            return nil
        }
        let current = CACurrentMediaTime()
        defer {
            VideoParser.logger.info("\(self.type) get first frame data cost \(CACurrentMediaTime() - current)")
        }
        var data: Data?
        if let cgImage = image.cgImage {
            data = WebP.Encoder.data(image: cgImage, quality: coverSetting.limitQuality * 100)
        }
        if data == nil {
            data = image.jpegData(compressionQuality: CGFloat(coverSetting.limitQuality))
        }

        guard let rawData = data else {
            VideoParser.logger.error("\(self.type) get first frame data failed")
            return nil
        }
        VideoParser.logger.info("\(self.type) get first frame data size \(rawData.count ?? 0)")
        return rawData
    }

    /// 并不能完全取消，只能取消部分操作
    func cancel() {
        videoExportSession?.cancelExport()
    }
}
