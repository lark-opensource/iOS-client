//
//  PerformancePlugin.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/5/27.
//

import Foundation

/// 性能插件
///
/// 用于接收图片请求流程事件
public protocol PerformancePlugin {

    /// 唯一识别符
    var identifier: String { get }

    /// 图片加载完成记录
    func receivedRecord(_ record: PerformanceRecorder)

    /// 图片下载信息
    func receiveDownloadInfo(key: String, downloadInfo: ImageDownloadInfo)

    /// 图片解码后信息
    func receiveDecodeInfo(key: String, decodeInfo: ImageDecodeInfo)

}
