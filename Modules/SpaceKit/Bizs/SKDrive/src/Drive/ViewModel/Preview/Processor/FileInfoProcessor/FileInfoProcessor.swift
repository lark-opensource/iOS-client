//
//  FileInfoProcessor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/6.
//

import Foundation
import SKCommon
import SKFoundation
import LarkDocsIcon

enum DriveProccesPreviewInfo {
    case local(url: SKFilePath, originFileType: DriveFileType) // 本地路径预览,除音视频类型
    case streamVideo(video: DriveVideo) // 边下边播视频数据
    case localMedia(url: SKFilePath, video: DriveVideo) // 本地视频,音频
    case previewHtml(extraInfo: String) // 缓存html预览
    case previewWPS // wps预览信息
    case archive(viewModel: DriveArchivePreviewViewModel) // 压缩文件数据
    case linearizedImage(preview: DriveFilePreview) // 线性化图片预览数据
    case thumb(thumb: UIImage, previewType: DrivePreviewFileType) // 缩略图预览流程
}

enum DriveProccessState {
    case setupPreview(fileType: DriveFileType, info: DriveProccesPreviewInfo) // fileType：实际预览的文件类型
    case unsupport(type: DriveUnsupportPreviewType) // 文件已缓存，但是缓存不支持预览
    case downloadOrigin // 开始下载源文件
    case downloadPreview(previewType: DrivePreviewFileType, customID: String?) // 开始下载预览文件
    case startPreviewGet // 开始获取转码信息preview/get请求
    case startTranscoding(pullInterval: Int64, handler: (() -> Void)?) // 开始等待preview/get推送或轮询结果
    case endTranscoding(status: DriveFilePreview.PreviewStatus) // 结束推送/轮休等待状态
    case fetchPreviewURLFail(canRetry: Bool, errorMsg: String)
    case cacDenied //cac管控
}
protocol FileInfoProcessStrategy {
    var useCacheIfExist: Bool { get }
}

protocol FileInfoProcessor: FileInfoProcessStrategy {
    /// 获取缓存预览信息
    func getCachePreviewInfo(fileInfo: DKFileProtocol) -> DriveProccessState?
    func handle(fileInfo: DKFileProtocol, hasOpenFromCache: Bool, complete: @escaping (DriveProccessState?) -> Void)
}
