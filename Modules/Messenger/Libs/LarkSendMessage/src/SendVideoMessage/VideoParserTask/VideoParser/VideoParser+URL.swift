//
//  VideoAssetParser+URL.swift
//  Action
//
//  Created by kongkaikai on 2018/11/23.
//

import UIKit
import Foundation
import RxSwift // Observable
import AVFoundation // AVURLAsset
import LarkFoundation // FileUtils
import LarkPerf // DeviceExtension
import LarkSDKInterface // PathWrapper

private typealias Path = LarkSDKInterface.PathWrapper

extension VideoParser {

    // parserVideo流程: baseVideoInfo(从PHAsset中获取各种信息) + getFirstFrame(获取首帧图片) + judgeInfo(判断各个参数是否超出限制)
    // baseVideoInfo: 从PHAsset和AVAsset中获取info的exportPath compressPath duration name fileSize originSize naturalSize
    // getFirstFrame: 使用VE接口获取首帧 + 使用系统接口获取首帧

    /// 解析视频：Copy数据、读取基本信息
    func parserVideo(with url: URL) -> Observable<VideoParseInfo> {
        return baseVideoInfo(with: url)
            .flatMap { [weak self] (info) -> Observable<VideoParseInfo> in
                guard let self = self else { return .empty() }
                return self.judgeInfo(info: info, url: url)
            }
            .flatMap { [weak self] (info) -> Observable<VideoParseInfo> in
                guard let self = self else { return .empty() }
                return self.getFirstFrame(info: info, url: URL(fileURLWithPath: info.exportPath))
            }
    }

    // 获取视频资源的基本信息
    func baseVideoInfo(with videoURL: URL) -> Observable<VideoParseInfo> {

        // 检查文件存在、合法，可以正常创建缓存路径
        guard let fileSize = checkFileExistsAndGetFileSize(at: videoURL) else {
            VideoParser.logger.error("\(self.type) read video file failed")
            let error = NSError(domain: "lark.media.parser.error", code: -100, userInfo: [
                NSLocalizedDescriptionKey: "get video file failed \(videoURL) \(Path(videoURL.path).exists)"
            ])
            return .error(VideoParseError.getVideoSizeError(error))
        }

        guard let cachePath = VideoParser.createVideoSaveURL(userID: userResolver.userID, isOriginal: self.isOriginal) else {
            VideoParser.logger.error("\(self.type) create cache directory failed")
            let error = NSError(domain: "lark.media.parser.error", code: -100, userInfo: [
                NSLocalizedDescriptionKey: "get url failed \(videoURL)"
            ])
            return .error(VideoParseError.createSandboxPathError(error))
        }

        // 获取视频原始分辨率
        let avasset = AVURLAsset(url: videoURL)
        guard let naturalSize = VideoParser.naturalSize(with: avasset) else {
            VideoParser.logger.error("\(self.type) URL: get video track error")
            return .error(VideoParseError.videoTrackUnavailable)
        }

        // 获取视频时长，单位：秒
        let time = avasset.duration
        let seconds = (Double(time.value) / Double(time.timescale)).rounded()

        // 获取视频应该转码到多少分辨率
        var strategy = VideoTranscodeStrategy()
        strategy.isOriginal = self.isOriginal
        let size = self.transcodeService.adjustVideoSize(naturalSize, strategy: strategy)

        let info = VideoParseInfo()
        info.videoSendSetting = self.videoSendSetting
        info.isPHAssetVideo = false
        info.modificationDate = Date().timeIntervalSince1970
        info.name = videoURL.lastPathComponent
        info.filesize = fileSize
        info.naturalSize = size
        info.duration = seconds
        info.exportPath = cachePath.path + ".mov"
        if userResolver.fg.staticFeatureGatingValue(with: "im.message.send_mov_video") {
            info.compressPath = info.exportPath + ".mov" // VE 目前所有的转码产物都是 mov
        } else {
            info.compressPath = cachePath.path + ".mp4"
        }
        info.status = .fillBaseInfo
        return .just(info)
    }

    // 获取视频首帧
    func getFirstFrame(info: VideoParseInfo, url: URL) -> Observable<VideoParseInfo> {

        //调用系统API获取视频资源的首帧
        func useSystemAPI() -> Observable<VideoParseInfo> {
            do {
                let imageInfo = try self.firstFrame(with: AVURLAsset(url: url), size: info.naturalSize)
                info.setPreview(imageInfo.0)
                info.firstFrameData = imageInfo.1
                return .just(info)
            } catch let error {
                VideoParser.logger.error("\(self.type) PHAsset: get firstframe error", error: error)
                return .error(VideoParseError.getFirstFrameError(error))
            }
        }
        // VESDK 内部接口对 iOS 14 以下支持的不完善，降级为系统接口
        if #available(iOS 14.0, *), isInFirstFrameFG, !DeviceExtension.isLowDeviceClassify {
            // 使用TTVideoEditor的方法获取首帧，因为可以一定程度上跳过首屏黑帧的问题
            if let imageInfo = getFirstFrameByTTVideoEditor(exportPath: url.path, size: info.naturalSize) {
                info.setPreview(imageInfo.0)
                info.firstFrameData = imageInfo.1
                return .just(info)
            } else {
                return useSystemAPI()
            }
        } else {
            return useSystemAPI()
        }
    }

    // 判断info的各个属性是否满足条件，如果不满足则转附件或者不发送
    func judgeInfo(info: VideoParseInfo, url: URL) -> Observable<VideoParseInfo> {
        // 移动视频到exportPath位置
        if let error = self.loadVideoData(at: url, to: URL(fileURLWithPath: info.exportPath)) {
            return .error(error)
        }
        let url = info.exportPath
        let fileName = String(URL(string: info.exportPath)?.path.split(separator: "/").last ?? "")
        let fileSize = try? FileUtils.fileSize(url)
        sendVideoCache(userID: userResolver.userID).saveFileName(fileName, size: max(Int(info.filesize), Int(fileSize ?? 0)))
        // 超出附件发送限制，取消发送
        guard info.filesize <= self.fileMaxSize else {
            VideoParser.logger.error("\(self.type) PHAsset: file reach max size", additionalData: ["filesize": "\(info.filesize)"])
            return .error(VideoParseError.fileReachMax(fileSize: info.filesize, fileSizeLimit: self.fileMaxSize))
        }

        // 大小超出限制，转附件
        if info.filesize > self.videoSendSetting.fileSize {
            info.status = .reachMaxSize
            return .just(info)
        }
        // 时长超出限制，转附件
        if info.duration > videoSendSetting.duration {
            info.status = .reachMaxDuration
            return .just(info)
        }
        let avasset = AVURLAsset(url: URL(fileURLWithPath: info.exportPath), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        if let videoInfo = VideoTranscoder.videoInfo(avasset: avasset) {
            // 分辨率超出限制，转附件
            if videoInfo.2.width * videoInfo.2.height >
                self.videoSendSetting.resolution.width * self.videoSendSetting.resolution.height {
                info.status = .reachMaxResolution
                return .just(info)
            }
            // 帧率超出限制，转附件
            if videoInfo.0 > self.videoSendSetting.frameRate {
                info.status = .reachMaxFrameRate
                return .just(info)
            }
            // 码率超出限制，转附件
            if videoInfo.1 > self.videoSendSetting.bitrate {
                info.status = .reachMaxBitrate
                return .just(info)
            }
        } else {
            VideoParser.logger.error("\(self.type) get video info failed \(avasset) \(avasset.tracks)")
        }
        info.status = .fillBaseInfo
        return .just(info)
    }

    func checkFileExistsAndGetFileSize(at url: URL) -> UInt64? {
        let path = Path(url.path)
        if path.exists, !path.isDirectory {
            if let fileSize = path.fileSize {
                return fileSize
            } else {
                VideoParser.logger.error("\(self.type) URL: get video file size error")
            }
        }
        VideoParser.logger.error("\(self.type) URL: file not found or is directory")
        return nil
    }

    public class func naturalSize(with asset: AVURLAsset) -> CGSize? {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else { return nil }

        let degress = VideoTranscoder.degress(with: videoTrack.preferredTransform)
        return VideoTranscoder.videoPreviewSize(with: videoTrack.naturalSize, degress: degress)
    }

    /// 把沙盒视频从at移动到to
    func loadVideoData(at url: URL, to targetURL: URL) -> Error? {
        let fromPath = Path(url.path)
        let targetPath = Path(targetURL.path)
        do {
            try fromPath.moveFile(to: targetPath)
        } catch {
            VideoParser.logger.error("\(self.type) URL: move video fail", error: error)
            do {
                try fromPath.copyFile(to: targetPath)
            } catch {
                VideoParser.logger.error("\(self.type) URL: copy video fail", error: error)
                return error
            }
        }
        return nil
    }
}
