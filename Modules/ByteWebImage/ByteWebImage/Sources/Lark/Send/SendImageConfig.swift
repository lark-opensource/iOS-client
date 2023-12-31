//
//  LarkSendImageConfig.swift
//  ByteWebImage
//
//  Created by kangsiwan on 2022/1/27.
//

import Foundation
import LarkSetting
import LKCommonsLogging
import AppReciableSDK

public enum PhotoLibraryProcessStatus {
    case beforeRequest
    case finishRequest
    case beforeImageProcess
    case finishImageProcess
}

public struct ImageInfoDependency {
    let useOrigin: Bool
    let sendImageProcessor: SendImageProcessor
    var statusHandler: ((PhotoLibraryProcessStatus) -> Void)?
    public var scene: Scene = .Chat
    public var isConvertWebp: Bool = false
    public init(useOrigin: Bool,
                sendImageProcessor: SendImageProcessor,
                statusHandler: ((PhotoLibraryProcessStatus) -> Void)? = nil) {
        self.useOrigin = useOrigin
        self.sendImageProcessor = sendImageProcessor
        self.statusHandler = statusHandler
    }
}

// check阶段的自定义配置
public struct SendImageCheckConfig {
    // 图片埋点类型
    public enum ImageEventTrackType {
        // message_send事件
        case messageSend
        // image_upload事件
        case imageUpload
    }
    // 图片的文件大小。业务方设置，则使用设置的，如果没有设置，调用setting获取
    public var fileSize: CGFloat?
    // 图片的尺寸大小
    public var imageSize: CGSize?
    // 原图
    public let isOrigin: Bool
    /// 是否要转为 WebP
    /// - Note: 目前仅当 isOrigin == false 时生效
    public let needConvertToWebp: Bool // TODO: @kangsiwan 把这三个属性换成 Options
    // 是否涉及远端：是否密聊
    public let canUseServer: Bool
    // 业务，用于埋点
    public let biz: Biz
    // 场景,用于埋点
    public let scene: Scene
    // 埋点类型: 目前只有imageUpload
    public let imageEventTrack: ImageEventTrackType
    // 图片场景
    public let fromType: UploadImageInfo.FromType
    // 从setting获取配置
    static let logger = Logger.log(SendImageCheckConfig.self, category: "SendImageCheckConfig")

    public init(imageSize: CGSize? = nil,
                fileSize: CGFloat? = nil,
                isOrigin: Bool = false,
                needConvertToWebp: Bool = false,
                canUseServer: Bool = true,
                scene: Scene,
                biz: Biz = .Core,
                fromType: UploadImageInfo.FromType,
                event: ImageEventTrackType = .imageUpload) {
        self.isOrigin = isOrigin
        self.needConvertToWebp = needConvertToWebp
        self.canUseServer = canUseServer
        self.scene = scene
        self.biz = biz
        self.fileSize = fileSize
        self.imageSize = imageSize
        self.imageEventTrack = event
        self.fromType = fromType
    }
}

// compress阶段的自定义配置
public struct SendImageCompressConfig {
    public let compressRate: Float?
    public let destPixel: Int?
    public init(compressRate: Float? = nil, destPixel: Int? = nil) {
        self.compressRate = compressRate
        self.destPixel = destPixel
    }
}

// 发送组件的自定义配置
public struct SendImageConfig {
    public let checkConfig: SendImageCheckConfig
    public let compressConfig: SendImageCompressConfig
    // 当在check和compress阶段发生错误，是直接抛出错误结束流程，还是跳过错误继续处理下一个输入
    // true：跳过错误继续处理下一个；false：直接抛出错误结束流程
    public let isSkipError: Bool
    public init(isSkipError: Bool = true,
                checkConfig: SendImageCheckConfig = SendImageCheckConfig(scene: .Chat, fromType: .image),
                compressConfig: SendImageCompressConfig = SendImageCompressConfig()) {
        self.isSkipError = isSkipError
        self.checkConfig = checkConfig
        self.compressConfig = compressConfig
    }
}
