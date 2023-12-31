//
//  ImageDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/18.
//

import Foundation

public struct ImageDecoderConfig {

    public var forceDecode: Bool = true

    public var downsamplePixelSize: Int = 0

    public var cropRect: CGRect = .zero

    public var limitSize: CGFloat = 0

    public var delayMinimum: TimeInterval = 0
}

public protocol ImageExternSource {}

public enum ImageDecoderResource {
    case imageIO(CGImageSource, ImageProperties)
    case webP(WebpBridge)
    case extern(ImageExternSource)
}

/// 图片解码协议
public protocol ImageDecoder: AnyObject {

    typealias Resources = ImageDecoderResource

    /// 配置项
    var config: ImageDecoderConfig { get set }

    /// 初始化
    init()

    /// 预处理数据
    /// - Parameter data: 原始数据
    /// - Returns: 数据资源
    func preprocess(_ data: Data) throws -> Resources

    /// 第n帧图像
    /// - Parameters:
    ///   - res: 数据资源
    ///   - index: 帧
    /// - Returns: 对应帧图像
    func image(_ res: Resources, at index: Int) throws -> CGImage

    /// 帧延迟
    /// - Parameters:
    ///   - res: 数据资源
    ///   - index: 帧
    /// - Returns: 对应帧延迟
    func delay(_ res: Resources, at index: Int) throws -> TimeInterval

    /// 当前格式是否支持动图
    var supportAnimation: Bool { get }

    /// 判断是否为动图
    /// - Parameter res: 数据资源
    /// - Returns: 是 / 否
    func isAnimatedImage(_ res: Resources) -> Bool

    /// 获取图片数量
    /// - Parameter res: 数据资源
    /// - Returns: 图片数量(无效数据返回0)
    func imageCount(_ res: Resources) -> Int

    /// 动图循环次数
    /// - Parameter res: 数据资源
    /// - Returns: 循环次数(静图返回0)
    func loopCount(_ res: Resources) -> Int

    /// 获取图片像素大小
    /// - Parameter res: 数据资源
    /// - Returns: 图片像素大小
    func pixelSize(_ res: Resources) throws -> CGSize

    /// 获取图片方向
    /// - Parameter res: 数据资源
    /// - Returns: 图片方向
    func orientation(_ res: Resources) throws -> UIImage.Orientation

    /// 清理缓存
    /// - Parameter resource: 数据资源
    func clearCacheIfNeeded(_ resource: Resources)

    /// 文件格式
    var imageFileFormat: ImageFileFormat { get }
}

extension ImageDecoder {

    public var supportAnimation: Bool {
        false
    }

    public func isAnimatedImage(_ res: Resources) -> Bool {
        supportAnimation && imageCount(res) > 1
    }

    public func imageCount(_ res: Resources) -> Int {
        0
    }

    public func loopCount(_ res: Resources) -> Int {
        0
    }

    public func clearCacheIfNeeded(_ resource: Resources) {}
}
