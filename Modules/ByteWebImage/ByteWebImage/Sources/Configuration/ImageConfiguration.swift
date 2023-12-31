//
//  ImageConfiguration.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/11/15.
//

import Foundation

// MARK: - Permanent Config

/// 图片总开关配置
public enum ImageConfiguration {

    // MARK: - Cache

    /// 使用缓存功能(默认: true)
    public static var enableCache: Bool = true

    // MARK: - Tile

    /// 启用分片
    public static var enableTile: Bool = true

    // MARK: - Decode

    /// WebP图片不完整时，直接抛出错误
    public static var forbiddenWebPPartial: Bool = true

    // MARK: - Animated Image Downsample / Crop

    /// 裁剪动图帧间隔限制(默认: 0.1)
    public static var animatedDelayMinimum: TimeInterval = 0.1
}

// MARK: - Temporary Config

extension ImageConfiguration {

    // MARK: - Decode

    /// HEIC图片串行解码
    ///
    /// 提供开关做线上实验 Fix heif 解码 crash https://bytedance.feishu.cn/docs/doccnEotnJ5JkfY0By8ISixE2md
    public static var heicSerialDecode: Bool = false
}
