//
//  ImageDecoderFactory.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/20.
//

import Foundation
import ThreadSafeDataStructure

/// 图片解码器注册协议
public protocol ImageDecoderRegister {

    /// 注册图片解码器
    /// - Parameters:
    ///   - format: 图片格式
    ///   - decoder: 解码器
    /// - Returns: 之前绑定的解码器类型
    static func register(_ format: ImageFileFormat, _ decoder: ImageDecoder.Type) -> ImageDecoder.Type?

    /// 注销图片解码器
    /// - Parameters:
    ///   - format: 图片格式
    ///   - decoder: 解码器
    /// - Returns: 注销的解码器类型，类型不匹配返回 nil
    static func unregister(_ format: ImageFileFormat, _ decoder: ImageDecoder.Type?) -> ImageDecoder.Type?
}

/// 图片解码器创建协议
public protocol ImageDecoderCreator {

    /// 创建对应类型的解码器
    /// - Parameter for: 图片格式
    /// - Returns: 解码器
    static func decoder(for format: ImageFileFormat) throws -> any ImageDecoder
}

/// 图片解码器工厂
internal enum ImageDecoderFactory {

    /// 解码器列表
    private(set) static var decoderMap: SafeDictionary<ImageFileFormat, ImageDecoder.Type> = [
        .gif: GIF.Decoder.self,
        .jpeg: JPEG.Decoder.self,
        .png: PNG.Decoder.self,
        .webp: WebP.Decoder.self,
        .heif: HEIF.Decoder.self,
        .heic: HEIC.Decoder.self,
        .bmp: BMP.Decoder.self,
        .ico: ICO.Decoder.self,
        .tiff: TIFF.Decoder.self,
        .icns: ICNS.Decoder.self
    ] + .readWriteLock
}

extension ImageDecoderFactory: ImageDecoderRegister {

    @discardableResult
    static func register(_ format: ImageFileFormat, _ decoder: ImageDecoder.Type) -> ImageDecoder.Type? {
        let type = decoderMap[format]
        decoderMap[format] = decoder
        return type
    }

    @discardableResult
    static func unregister(_ format: ImageFileFormat, _ decoder: ImageDecoder.Type?) -> ImageDecoder.Type? {
        // 需要解绑情况：
        // 1. 存在绑定关系，且未指定解码器
        // 2. 存在绑定关系，且绑定的为指定解码器
        guard let type = decoderMap[format],
              decoder == nil || decoder == type else {
            return nil
        }

        decoderMap[format] = decoder
        return type
    }
}

extension ImageDecoderFactory: ImageDecoderCreator {

    static func decoder(for format: ImageFileFormat) throws -> any ImageDecoder {
        guard let decoderType = decoderMap[format] else {
            throw ImageError.Decoder.formatNotSupport
        }

        return decoderType.init()
    }
}
