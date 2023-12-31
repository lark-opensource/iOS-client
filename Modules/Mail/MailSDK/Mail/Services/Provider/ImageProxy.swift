//
//  ImageProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/23.
//

import Foundation

public enum CutType: Int32 {
    case top = 1, bottom, left, right, center, face
}

public enum ImageFormat: Int32 {
    case webp, jpeg, png
}

public struct SetAvatarImageParams {
    /// default: 120
    public var width: Int32?
    /// default: 120
    public var height: Int32?
    public var cutType: CutType?
    /// default: png
    public var format: ImageFormat?
    /// 图片质量 [0, 100], default: 70
    public var quality: Int32?
    /// 返回原图，忽略其他设置
    public var noop: Bool? //

    public init() { }

}

public typealias ProgressCallback = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)
public typealias CompletionCallback = ((_ image: UIImage?, _ error: Error?) -> Void)

public protocol SetImageTask {
    func cancel()
}

public protocol ImageProxy {
    /// 设置头像的图片所用方法
    @discardableResult
    func setAvatar(_ imageView: UIImageView,
                   key: String,
                   entityId: String,
                   avatarImageParams: SetAvatarImageParams?,
                   placeholder: UIImage?,
                   progress: ProgressCallback?,
                   completion: CompletionCallback?) -> SetImageTask?

    func setExternalImage(_ imageView: UIImageView,
                          key: String,
                          url: String,
                          placeholder: UIImage?,
                          progress: ProgressCallback?,
                          completion: CompletionCallback?) -> SetImageTask?
}
