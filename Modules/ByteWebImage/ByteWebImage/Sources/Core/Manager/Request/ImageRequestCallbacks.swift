//
//  ImageRequestCallbacks.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/6.
//

import Foundation

/// 图片请求结果
public typealias ImageRequestResult = Result<ImageResult, ByteWebImageError>

/// 已加密图片数据解密回调
/// - Parameters:
///   - imageData: 图片数据
public typealias ImageRequestDecrypt = (_ encryptedData: Data?) -> Result<Data, ByteWebImageError>

/// 进度回调
/// - Parameters:
///   - request: 请求
///   - receivedSize: 收到大小(字节)
///   - expectedSize: 预期大小(字节)
public typealias ImageRequestProgress = (_ imageRequest: ImageRequest, _ receivedSize: Int, _ expectedSize: Int) -> Void

/// 完成回调
/// - Parameters:
///   - request: 图片请求结果
public typealias ImageRequestCompletion = (_ imageResult: ImageRequestResult) -> Void

/// 图片请求回调列表
public struct ImageRequestCallbacks {

    /// 解密
    public var decrypt: ImageRequestDecrypt?

    /// 进度
    public var progress: ImageRequestProgress?

    /// 完成
    public var completion: ImageRequestCompletion?

    public init(decrypt: ImageRequestDecrypt? = nil,
                progress: ImageRequestProgress? = nil,
                completion: ImageRequestCompletion? = nil) {
        self.decrypt = decrypt
        self.progress = progress
        self.completion = completion
    }
}
