//
//  ImageManager+Decode.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/20.
//

import Foundation

extension ImageManager: ImageDecoderRegister {

    @discardableResult
    /// 注册自定义解码器
    /// - Parameters:
    ///   - format: 对指定格式注册
    ///   - decoder: 解码器
    /// - Returns: 指定格式原有的解码器（如果有）
    public static func register(_ format: ImageFileFormat, _ decoder: ImageDecoder.Type) -> ImageDecoder.Type? {
        ImageDecoderFactory.register(format, decoder)
    }

    @discardableResult
    public static func unregister(_ format: ImageFileFormat, _ decoder: ImageDecoder.Type?) -> ImageDecoder.Type? {
        ImageDecoderFactory.unregister(format, decoder)
    }
}
