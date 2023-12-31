//
//  DrivePreviewDefines.swift
//  SpaceKit-DocsSDK
//
//  Created by zenghao on 2019/6/28.
//

import Foundation
import SKCommon
import SKFoundation
import EENavigator
import SpaceInterface
import LarkDocsIcon

// MARK: - Server Transaction
/// 后端转码后的文件类型: https://bytedance.feishu.cn/space/doc/tSrvZGGj5N8WUT08s0vLlg#j83gMl
enum DrivePreviewFileType: Int, CaseIterable {
    case png = 1
    case pages = 2
    case mp4 = 3
    case jpg = 7
    case html = 8
    case linerizedPDF = 9
    case jpgLin = 11
    case pngLin = 12
    case archive = 13
    /// 转码的纯文本
    case transcodedPlainText = 14
    /// 原始文件
    case similarFiles = 16
    /// 视频文件流信息
    case videoMeta = 17
    /// ogg 转码后可能是 m4a 或 mp4 文件
    case ogg = 20
    /// 文件真实类型
    case mime = 21

    func toDriveFileType(originType: DriveFileType) -> DriveFileType {
        switch self {
        case .linerizedPDF:
            return DriveFileType(fileExtension: "pdf")
        case .png:
            return DriveFileType(fileExtension: "png")
        case .pages:
            return DriveFileType(fileExtension: "pages")
        case .mp4:
            return DriveFileType(fileExtension: "mp4")
        case .jpg:
            return DriveFileType(fileExtension: "jpg")
        case .html:
            return DriveFileType(fileExtension: "html")
        case .jpgLin:
            return DriveFileType(fileExtension: "jpg")
        case .pngLin:
            return DriveFileType(fileExtension: "png")
        case .archive:
            return DriveFileType(fileExtension: "json")
        case .transcodedPlainText:
            // TXT 和 csv 文件都需要转码，需要使用原始后缀
            return originType
        case .similarFiles, .ogg, .mime, .videoMeta:
            return originType
        }
    }
    var isImageLin: Bool {
        switch self {
        case .jpgLin, .pngLin:
            return true
        default:
            return false
        }
    }
}

/// 是否手动触发生成预览文件请求
enum DrivePreviewFileGeneratedType: Int {
    /// 非手动触发
    case normal = 0
    /// 手动触发
    case manual = 1
}

// MARK: - Preview
struct DrivePreviewConfiguration {
    /// If need Share & More
    var shouldShowRightItems = true
    /// A unified loading animate
    var loadingView: DocsLoadingViewProtocol?
    /// The date of history version
    var hitoryEditTimeStamp: String?
}

public struct DriveFileContext {
    public private(set) var fileMeta: DriveFileMeta
    public let docsInfo: DocsInfo

    public init(fileMeta: DriveFileMeta, docsInfo: DocsInfo) {
        self.fileMeta = fileMeta
        self.docsInfo = docsInfo
    }
}

/// 图片预览模式
enum DriveImagePreviewMode {
    /// 图片预览模式
    case normal
    /// 添加选区
    case selection
}

// MARK: - Video
/// 视频文件信息，cacheUrl和info必须二选一
struct DriveVideo: CustomStringConvertible {

    enum VideoType {
        case online(url: URL)
        case local(url: SKFilePath)
    }

    /// 本地播放或在线播放
    let type: VideoType
    /// 边下边播的信息
    let info: DriveVideoInfo?
    /// 视频名称
    let title: String
    /// 视频大小
    let size: UInt64

    // 用于缓存
    // Drive文件使用"token_dataversion"
    // DriveSDK 文件使用“appID_fileID”
    let cacheKey: String
    
    let authExtra: String? // 第三方附件接入业务可以通过authExtra透传参数给业务后方进行鉴权，根据业务需要可选

    // 默认按照分辨率从高到低进行排序，优先使用高分辨率
    var resolutionDatas: [String] {
        if let transcodeURLs = self.info?.transcodeURLs {
            return transcodeURLs.keys.map { $0.uppercased() }.sorted {
                // e.g 移除 "1080P"/"720P" 的最后 P 字符后转 Int 类型比较大小排序
                var p0 = $0
                var p1 = $1
                p0.removeLast()
                p1.removeLast()
                if let i0 = Int(p0), let i1 = Int(p1) {
                    return i0 < i1
                } else {
                    return $0 < $1
                }
            }
        } else {
            DocsLogger.driveInfo("no video info，no video bit rate")
            return []
        }
    }
}

extension DriveVideo {
    public var description: String {
        return "type: \(type), size: \(size), cacheKey: \(cacheKey)"
    }

}
