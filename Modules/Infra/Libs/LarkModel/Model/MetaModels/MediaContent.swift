//
//  MediaContent.swift
//  Action
//
//  Created by K3 on 2018/8/5.
//

import Foundation
import RustPB

public struct MediaContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message

    public var key: String
    public var name: String
    public var size: Int64
    public var mime: String
    public var source: RustPB.Basic_V1_MediaContent.Source
    public var image: ImageSet
    public var duration: Int32
    public var url: String
    // 消息链接化场景需要使用previewID做资源鉴权
    public var authToken: String?

    // 发送成功后SDK才会填充这个路径，用于播放
    public var filePath: String

    // 源文件路径
    public var originPath: String

    // 压缩文件路径
    public var compressPath: String

    // 是否是 PC 发出的原画视频
    public var isPCOriginVideo: Bool

    public init(
        key: String,
        name: String,
        size: Int64,
        mime: String,
        source: RustPB.Basic_V1_MediaContent.Source,
        image: ImageSet,
        duration: Int32,
        url: String,
        authToken: String?,
        filePath: String,
        originPath: String,
        compressPath: String,
        isPCOriginVideo: Bool
    ) {
        self.key = key
        self.name = name
        self.size = size
        self.mime = mime
        self.source = source
        self.image = image
        self.duration = duration
        self.authToken = authToken
        self.url = url
        self.filePath = filePath
        self.originPath = originPath
        self.compressPath = compressPath
        self.isPCOriginVideo = isPCOriginVideo
    }

    public static func transform(pb: PBModel) -> MediaContent {
        let content = pb.content.mediaContent
        return MediaContent(key: content.key,
                            name: content.name,
                            size: content.size,
                            mime: content.mime,
                            source: content.source,
                            image: content.image,
                            duration: content.duration,
                            url: content.url,
                            authToken: nil,
                            filePath: pb.content.filePath,
                            originPath: content.originPath,
                            compressPath: content.compressPath,
                            isPCOriginVideo: content.isOriginal)
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}

    public mutating func complement(previewID: String, messageLink: Basic_V1_MessageLink, message: Message) {
        self.authToken = previewID
    }

    public static func transform(
        content: RustPB.Basic_V1_MediaContent,
        filePath: String
    ) -> MediaContent {
        return MediaContent(key: content.key,
                     name: content.name,
                     size: content.size,
                     mime: content.mime,
                     source: content.source,
                     image: content.image,
                     duration: content.duration,
                     url: content.url,
                     authToken: nil,
                     filePath: filePath,
                     originPath: content.originPath,
                     compressPath: content.compressPath,
                     isPCOriginVideo: content.isOriginal)
    }
}
