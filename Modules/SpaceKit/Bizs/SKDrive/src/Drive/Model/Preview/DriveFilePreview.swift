//
//  DriveFilePreview.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/23.
//

import Foundation
import SwiftyJSON
import SKFoundation

/// 后台生成的文件预览信息
/// - 后台接口文档 https://bytedance.feishu.cn/space/doc/tSrvZGGj5N8WUT08s0vLlg#  搜/api/box/preview/get/
struct DriveFilePreview: Codable {

    enum PreviewStatus: Int {
        case ready = 0
        case generating = 1
        /// 失败可重试，可以理解为是转码中的一种特殊状态，后台会自动重试
        case failedCanRetry = 2
        /// 失败不可重试
        case failedNoRetry = 3
        case unsupport = 4
        case sizeTooBig = 5
        case sizeIsZero = 6
        case fileEncrypt = 9

        case unknownArchiveFormat = 1001
        case archiveNodeOverLimit = 1002
        case archiveSubNodeOverLimit = 1003
        
        // 判断是否是可转码
        var isAvalible: Bool {
            switch self {
            case .ready, .generating, .failedCanRetry:
                return true
            case .unsupport, .failedNoRetry, .sizeIsZero,
                    .sizeTooBig, .fileEncrypt, .unknownArchiveFormat,
                    .archiveNodeOverLimit, .archiveSubNodeOverLimit:
                return false
            }
        }
    }

    private let status: Int
    /// 轮询间隔
    let interval: Int64?
    /// 有长链时的轮询间隔
    let longPushInterval: Int64?
    /// 预览文件下载地址
    var previewURL: String?
    /// 预览文件大小
    var previewFileSize: UInt64?
    /// 线性化PDF
    var linearized: Bool?
    /// 视频转码urls 不同分辨率
    var videoInfo: DriveVideoInfo?
    /// 额外信息，html、zip 文件使用
    var extra: String?

    private enum CodingKeys: String, CodingKey {
        case status
        case interval
        case longPushInterval = "long_push_retry_interval"
        case linearized = "linearized"
        case videoInfo  = "content"
        case extra = "extra"
        case previewFileSize = "preview_file_size"
    }

    var previewStatus: PreviewStatus {
        return PreviewStatus(rawValue: status) ?? .failedNoRetry
    }

    init(context: DriveFilePreviewContext) {
        self.status = context.status
        self.interval = context.interval
        self.longPushInterval = context.longPushInterval
        self.previewURL = context.previewURL
        self.previewFileSize = context.previewFileSize
        self.linearized = context.linearized
        self.videoInfo = context.videoInfo
        self.extra = context.extra
    }
}

struct DriveVideoInfo: Codable {
    let type: Int
    let transcodeURLs: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case transcodeURLs = "transcode_urls"
    }
}

struct DriveOggInfo: Codable {
    let mimeType: String
    let previewType: Int
}

struct DriveWebOfficeInfo: Codable {
    /// 是否支持 WPS 在线预览
    let enable: Bool
}

struct DriveMediaMetaInfo: Codable {
    let streams: [DriveVideoMeta]
}

struct DriveVideoMeta: Codable {
    /// 编码格式 e.g. h264
    let codecName: String
    /// 编码类型 e.g. video/audio
    let codecType: String
    /// 编码器标签名 e.g. avc1
    let codecTag: String
    /// 单位bit/s
    let bitRate: String
    let width: Int
    let height: Int

    private enum CodingKeys: String, CodingKey {
        case codecName = "codec_name"
        case codecType = "codec_type"
        case codecTag = "codec_tag_string"
        case bitRate = "bit_rate"
        case width = "width"
        case height = "height"
    }
}

struct DriveFilePreviewContext {
    let status: Int
    let interval: Int64?
    let longPushInterval: Int64?
    let previewURL: String?
    let previewFileSize: UInt64?
    let linearized: Bool?
    let videoInfo: DriveVideoInfo?
    let extra: String?
}

extension DriveFilePreviewContext {
    init(status: Int) {
        self.init(status: status, interval: nil, longPushInterval: nil, previewURL: nil, previewFileSize: nil, linearized: nil, videoInfo: nil, extra: nil)
    }

    init(status: Int, linearized: Bool) {
        self.init(status: status, interval: nil, longPushInterval: nil, previewURL: nil, previewFileSize: nil, linearized: linearized, videoInfo: nil, extra: nil)
    }

    init(status: Int, extra: String) {
        self.init(status: status, interval: nil, longPushInterval: nil, previewURL: nil, previewFileSize: nil, linearized: nil, videoInfo: nil, extra: extra)
    }
}

extension DriveFilePreview {
    var imageSize: CGSize? {
        guard let jsonData = self.extra?.data(using: .utf8, allowLossyConversion: false),
            let dic = try? JSON(data: jsonData),
            let height = dic["height"].int,
            let width = dic["width"].int else {
                return nil
        }
        return CGSize(width: width, height: height)
    }
    
    var mimeType: String? {
        guard let jsonData = self.extra?.data(using: .utf8, allowLossyConversion: false),
            let dic = try? JSON(data: jsonData),
            let type = dic["mime_type"].string else {
                return nil
        }
        return type.isEmpty ? nil : type
    }

    var mediaMeta: DriveMediaMetaInfo? {
        guard let jsonData = self.extra?.data(using: .utf8, allowLossyConversion: false),
              let json = try? JSON(data: jsonData),
              let data = json["meta_info"].rawString()?.data(using: .utf8) else {
            return nil
        }
        guard let mediaMetaInfo = try? JSONDecoder().decode(DriveMediaMetaInfo.self, from: data) else {
            DocsLogger.driveError("decode DriveMediaMetaInfo fail")
            return nil
        }
        DocsLogger.driveDebug("DriveMediaMetaInfo: \(mediaMetaInfo)")
        return mediaMetaInfo
    }
}
