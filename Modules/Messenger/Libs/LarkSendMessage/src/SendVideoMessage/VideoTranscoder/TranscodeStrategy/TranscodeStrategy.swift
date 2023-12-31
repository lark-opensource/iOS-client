//
//  TranscodeStrategy.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2020/1/16.
//

import UIKit
import Foundation
import RxSwift // Observable

/// 转码策略定义
protocol TranscodeStrategy {
    /// 转码
    func transcode(
        key: String,
        form: String,
        to: String,
        strategy: VideoTranscodeStrategy,
        videoSize: CGSize,
        extraInfo: [String: Any],
        progressBlock: ProgressHandler?,
        dataBlock: VideoDataCBHandler?,
        retryBlock: (() -> Void)?
    ) -> Observable<TranscodeInfo>

    func cancelVideoTranscode()

    /// 缩放视频尺寸，目前会根据时长区别缩放
    func adjustVideoSize(_ naturalSize: CGSize, strategy: VideoTranscodeStrategy) -> CGSize
}
