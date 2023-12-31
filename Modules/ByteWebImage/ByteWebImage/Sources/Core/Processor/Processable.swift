//
//  Processable.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/9/14.
//

import Foundation

public protocol BaseTransformer: NSObjectProtocol, Processable {}

/// 图片预处理器协议
public protocol Processable: AnyObject {


    ///实现Transformer可以实现的方法，作为缓存的key
    ///
    /// - Returns: 返回一个string，作为缓存的key
    func appendingStringForCacheKey() -> String

    /// 实现Transformer可以实现的方法,在缓存前处理图片，图片处理后会被缓存
    ///
    /// - Parameter image: 下载完成后的原始图片
    /// - Returns: 处理后的图片，图片会被缓存到本地
    func transformImageBeforeStore(with image: UIImage) -> UIImage?

    /// 实现Transformer可以实现的方法,在缓存后处理图片，图片仅用于本次使用，缓存的是原图
    ///
    /// - Parameter image: 下载完成后被储存的图片
    ///
    /// - Returns: 处理后的图片，图片不会被缓存到本地
    func transformImageAfterStore(with image: UIImage) -> UIImage?
}

extension Processable {
    public func appendingStringForCacheKey() -> String {
        return ""
    }
    public func transformImageBeforeStore(with image: UIImage) -> UIImage? {
        return nil
    }

    public func transformImageAfterStore(with image: UIImage) -> UIImage? {
        return image
    }
}

public struct ProcessableWrapper: Hashable, CustomStringConvertible {

    public let base: any Processable

    public static func == (lhs: ProcessableWrapper, rhs: ProcessableWrapper) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(base.appendingStringForCacheKey())
    }

    public var description: String {
        base.appendingStringForCacheKey()
    }
}
