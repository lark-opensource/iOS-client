//
//  ImageActionMessages.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/25.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkContainer
import RustPB

public enum ImageSourceType {
    case message(Message)
    case post(selectKey: String, message: Message)
    case sticker(Message)
}

// 点击图片
open class PreviewAssetActionMessage: Request {
    public typealias Response = EmptyResponse

    public var imageView: UIImageView?
    public var source: ImageSourceType
    public var isVideoMuted: Bool
    public var downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    public var extra: [String: Any]? /// 额外信息 用于原画视频跳转到文件中使用

    /// 某些特殊情况 imageview取不到可以为nil，但是尽量不要用nil
    public init(
        imageView: UIImageView?,
        source: ImageSourceType,
        isVideoMuted: Bool = false,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene? = nil,
        extra: [String: Any]? = nil
    ) {
        self.imageView = imageView
        self.source = source
        self.isVideoMuted = isVideoMuted
        self.downloadFileScene = downloadFileScene
        self.extra = extra
    }
}
