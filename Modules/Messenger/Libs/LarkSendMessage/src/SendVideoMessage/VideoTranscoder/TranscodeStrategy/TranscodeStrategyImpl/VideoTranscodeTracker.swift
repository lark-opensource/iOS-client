//
//  VideoTranscodeTracker.swift
//  LarkMessageCore
//
//  Created by 李晨 on 2022/11/22.
//

import UIKit
import Foundation
import RustPB // Basic_V1_DynamicNetStatusResponse
import LKCommonsTracker // Tracker

/// 转码打点需要的信息
public final class VideoTrackInfo {
    /// 转码参数信息
    public struct ParamInfo {
        /// 帧率
        public var rate: CGFloat = 0
        /// 码率，单位bps
        public var bitrate: Int32 = 0
        /// 分辨率
        public var videoSize: CGSize = .zero
        /// 准备智能合成状态
        public var aiCodecStatus: String = "unknown"
    }

    /// 视频信息
    public struct VideoInfo {
        /// 格式
        public var type: String = ""
        /// 帧率
        public var rate: CGFloat = 0
        /// 码率，单位bps
        public var bitrate: Int32 = 0
        /// 分辨率
        public var videoSize: CGSize = .zero
        /// 文件大小，单位bit
        public var fileSize: Float64 = 0
        /// 视频编码格式，H264 H265
        public var encodeType: String = "Other"
        /// 是否使用智能合成
        public var useAICodec: Bool = false
    }

    /// 原始视频信息
    public var origin = VideoInfo()
    /// 转码参数
    public var param = ParamInfo()
    /// 结果视频信息
    public var result = VideoInfo()
    /// 时长，单位秒
    public var duration: TimeInterval = 0
    /// 视频转码方式，origin发送源文件、reuse复用转码文件、muxer转封装、encode转码
    public var compressType: String = ""
    /// 是否是"原图"模式进行转码
    public var isOriginal: Bool = false
    /// 是否是弱网配置进行转码
    public var isWeakNetwork: Bool = false
    /// 是否 PHAsset 视频
    public var isPHAssetVideo: Bool = true
    /// 是否是 HDR 类型
    public var isHDR: Bool = false
    /// 未转封装原因
    public var notRemuxErrorcode: UInt64 = 0

    /// 转码耗时
    public var transcodeDuration: TimeInterval = 0

    /// 是否合并预压缩
    public var isMergePreCompress = false

    /// 是否使用边压边传递
    public var isCompressUpload = false

    /// 是否边压边传成功
    public var isCompressUploadSuccess = false

    /// 边压边传失败信息
    public var compressUploadFailedMsg = ""

    /// 是否合并预压缩
    public var preDuration: TimeInterval = 0

    /// 此任务上屏时间
    public var createTime: TimeInterval = 0

    /// 此任务开始转码时间
    public var startTime: TimeInterval = 0

    /// 是否进入后台
    public var isInBackground: Bool = false

    /// 结束时是否进入后台
    public var finishIsInBackground: Bool = false

    /// 网络状态
    public var netStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus = .excellent

    /// 视频上次修改时间
    public var modificationDate: TimeInterval = 0

    /// 视频发送时间
    public var videoSendDate: TimeInterval = 0

    /// 首帧图大小
    public var compressCoverFileSize: Float = 0

    /// 视频发送配置 Scene
    public var compileScene: String = "unknown"

    /// 视频发送配置
    public var compileQuality: String = "unknown"

    /// 是否是透传视频
    public var isPassthrough: Bool = false

    public init() {}
}

/// 视频转码埋点
class VideoTranscodeTracker {

    enum Result {
        case success
        case failed(error: Error)
    }

    static func transcode(info: VideoTrackInfo, result: VideoTranscodeTracker.Result, finishTime: CFTimeInterval = CACurrentMediaTime()) {
        var params: [String: Any] = [:]
        params = appendVideoInfo(videoTrackInfo: info, params: params)
        params = appendSendVideoCost(videoTrackInfo: info, params: params, finishTime: finishTime)
        params = appendSendVideoResult(
            videoTrackInfo: info,
            params: params,
            result: result
        )
        params = appendPerformance(videoTrackInfo: info, params: params)
        params = appendExtension(videoTrackInfo: info, params: params)
        SendMessageKeyPointRecorder.logger.info("event video_transcode_info_dev parmas \(params)")
        Tracker.post(TeaEvent("video_transcode_info_dev",
                              params: params))
    }

    private static func appendVideoInfo(videoTrackInfo: VideoTrackInfo, params: [String: Any]) -> [String: Any] {
        var params = params
        params["origin_fps"] = videoTrackInfo.origin.rate
        params["origin_file_size"] = videoTrackInfo.origin.fileSize / 1024 / 1024
        params["origin_bitrate"] = videoTrackInfo.origin.bitrate / 1000
        params["origin_video_size"] = "\(Int(videoTrackInfo.origin.videoSize.width))x\(Int(videoTrackInfo.origin.videoSize.height))"

        params["result_fps"] = videoTrackInfo.result.rate
        params["result_file_size"] = videoTrackInfo.result.fileSize / 1024 / 1024
        params["result_bitrate"] = videoTrackInfo.result.bitrate / 1000
        params["result_video_size"] = "\(Int(videoTrackInfo.result.videoSize.width))x\(Int(videoTrackInfo.result.videoSize.height))"
        params["video_duration"] = videoTrackInfo.duration
        params["is_use_cache"] = videoTrackInfo.compressType == "reuse" ? 1 : 0
        params["is_original"] = videoTrackInfo.isOriginal ? 1 : 0
        return params
    }

    private static func appendSendVideoCost(videoTrackInfo: VideoTrackInfo, params: [String: Any], finishTime: CFTimeInterval) -> [String: Any] {
        var params = params
        params["compress_duration"] = videoTrackInfo.transcodeDuration
        return params
    }

    private static func appendSendVideoResult(videoTrackInfo: VideoTrackInfo, params: [String: Any], result: VideoTranscodeTracker.Result) -> [String: Any] {
        var params = params
        switch result {
        case .success:
            params["result"] = "success"
        case .failed(error: let error):
            params["result"] = "failed"
            if let error = error as? NSError {
                params["errorCode"] = error.code
                params["errorMsg"] = "\(error)"
            } else {
                params["errorCode"] = -1
                params["errorMsg"] = "\(error)"
            }
        }
        return params
    }

    private static func appendPerformance(videoTrackInfo: VideoTrackInfo, params: [String: Any]) -> [String: Any] {
        var params = params

        guard let compressDuration = params["compress_duration"] as? TimeInterval,
            let uploadDuration = params["upload_duration"] as? TimeInterval,
            let originFileSize = params["origin_file_size"] as? TimeInterval,
            let resultFileSize = params["result_file_size"] as? TimeInterval,
            let resultBitrate = params["result_bitrate"] as? Int32,
            let originBitrate = params["origin_bitrate"] as? Int32 else {
                return params
        }

        if compressDuration > 0 {
            params["compress_speed"] = originFileSize * 1000 / compressDuration
        }

        if uploadDuration > 0 {
            params["upload_speed"] = resultFileSize * 1000 / uploadDuration
        }

        if resultFileSize > 0 {
            params["compress_ratio_file_size"] = originFileSize / resultFileSize
        }
        if resultBitrate > 0 {
            params["compress_ratio_bitrate"] = TimeInterval(originBitrate) / TimeInterval(resultBitrate)
        }
        return params
    }

    private static func appendExtension(videoTrackInfo: VideoTrackInfo, params: [String: Any]) -> [String: Any] {
        var params = params
        params["decode_is_use_hw_264"] = 1
        params["decode_is_use_hw_265"] = 1
        params["encode_is_use_hw_264"] = 1
        params["compress_is_remux"] = videoTrackInfo.compressType == "muxer" ? 1 : 0
        params["compress_is_HDR"] = videoTrackInfo.isHDR ? 1 : 0
        params["origin_video_format"] = videoTrackInfo.origin.type
        params["origin_encode_format"] = videoTrackInfo.origin.encodeType
        params["result_encode_format"] = videoTrackInfo.result.encodeType
        params["unenabled_remux_code"] = videoTrackInfo.notRemuxErrorcode
        params["is_in_background"] = videoTrackInfo.isInBackground ? 1 : 0
        params["finish_is_in_background"] = videoTrackInfo.finishIsInBackground ? 1 : 0
        params["use_weak_net_setting"] = videoTrackInfo.isWeakNetwork ? 1 : 0
        params["compile_scene"] = videoTrackInfo.compileScene
        params["compile_quality"] = videoTrackInfo.compileQuality
        params["prepare_aicodec_status"] = videoTrackInfo.param.aiCodecStatus
        params["use_aicodec"] = videoTrackInfo.result.useAICodec ? 1 : 0
        return params
    }
}
