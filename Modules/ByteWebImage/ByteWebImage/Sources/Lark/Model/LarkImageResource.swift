//
//  LarkImageResource.swift
//  ByteWebImage
//
//  Created by Saafo on 2023/2/28.
//

import Foundation

/// Lark 业务层封装的基本资源类型
public enum LarkImageResource {

    /// 普通图片，支持 Rust image key (不带协议头默认为此) & http(s):// & file:// & data(base64) url
    ///
    /// 如果是 Rust 图片，下载阶段会使用 `RustPB/MGetResources` 接口请求
    case `default`(key: String)

    /// 表情图片
    case sticker(key: String,
                 stickerSetID: String,
                 downloadDirectory: String? = LarkImageService.shared.stickerSetDownloadPath)

    /// Reaction & Emoji
    case reaction(key: String, isEmojis: Bool)

    // 目前 DocC 还不支持链接到其他 module 的 symbol https://github.com/apple/swift-docc/issues/208

    /// 头像，一般适用于 Rust 头像场景，包含 key / entityID / params 三个参数。
    ///
    /// params会转换为大小参数拼接在 key 的后面，作为 `RustSDK/get_avatar(_:)` 接口 的 key 参数，
    /// entityID 一般是头像对应的实体，比如人即是 UserID，群即是 GroupID，小程序即是 AppID，也会传入 `RustSDK/get_avatar(_:)` 接口
    ///
    /// 对于一些复杂的业务场景，如果同时既可能是 Rust avatar key，也可能是 http(s) || data || file url，也可用此 case
    ///
    /// 当不是 Rust avatar key 时，会忽略 entityID，也不会拼接 params
    ///
    /// > Note: 请注意：
    /// > - 如果确定是 http(s) 的头像，请使用 `.default` 作为普通图片进行请求
    /// > - entityID 只是作为参数透传给 `RustSDK/get_avatar(_:)` 接口，图片库不做任何处理。有关 entityID 的问题优先咨询 Rust
    case avatar(key: String,
                entityID: String,
                params: AvatarViewParams = .defaultMiddle)

    /// Rust 图片，一般适用于使用 `RustPB/Media_V1_MGetResourcesRequest` 图场景，包含 key / fsUnit / crypto 三个参数
    ///
    /// 可以从 `RustPB/Basic_V1_Image` -> `ImageItem` -> `rustImage(key:fsUnit:crypto:)` 转换而来，例如：
    ///
    /// ```swift
    /// imageSet.getThumbResource()
    /// imageSet.getThumbItem().imageResource()
    /// ```
    ///
    /// 图片库内以 key 作为缓存 key，
    /// 网络请求时会发起 `MGetResource` 请求，传入 key / fsUnit / crypto
    case rustImage(key: String,
                   fsUnit: String? = nil,
                   crypto: Data? = nil)

    /// 缓存 key，只包含 resource 中的 key 字段，作为图片库磁盘缓存 ID
    public var cacheKey: String {
        switch self {
        case let .default(key):
            return key
        case let .sticker(key, _, _):
            return key
        case let .reaction(key, _):
            return key
        case let .avatar(key, entityID, params):
            #if DEBUG
            if entityID.isEmpty && !key.isEmpty { // entityID 不允许为空，但有时业务方两者皆为空来置空图片，暂时不 assert
                assertionFailure("entityID shouldn't be empty, please check.")
            }
            #endif
            Self.resourceSemaphore.wait()
            defer {
                Self.resourceSemaphore.signal()
            }
            if Self.isRustImage(key: key) {
                return key + "_\(params.size())"
            } else {
                return key // size 是 Rust MGetResource 的概念，非 Rust key 不拼 size
            }
        case let .rustImage(key, _, _):
            return key
        }
    }

    /// 直接获取 resource 的 URL.absoluteString，已经拼上了协议头
    public func getURLString() -> String? {
        return generateURL()?.absoluteString
    }
    
    /// 获取 resource 对应的 URL，已经拼上了协议头
    public func generateURL() -> URL? {
        let cacheKey = cacheKey
        guard let url = URL(string: cacheKey), !url.absoluteString.isEmpty else {
            return nil
        }
        if Self.needAddRustImagePrefix(key: cacheKey) {
            return URL(string: Self.rustImagePrefix + cacheKey)
        } else {
            return url
        }
    }

    // Utils

    static func removeRustImagePrefixIfExisted(key: String) -> String {
        guard key.hasPrefix(rustImagePrefix) else { return key }
        return String(key.dropFirst(rustImagePrefix.count))
    }

    private static func isRustImage(key: String) -> Bool {
        needAddRustImagePrefix(key: key) || hasRustImagePrefix(key: key)
    }

    private static func needAddRustImagePrefix(key: String) -> Bool {
        guard let url = URL(string: key) else { return false } // 空 key 不加
        if let scheme = url.scheme?.lowercased(),
           ["file", "data"].contains(scheme) || scheme.hasPrefix("http") {
            // file, data, http(s) 协议均被 URLSession 支持，不改动协议头
            return false
        }
        if key.hasPrefix(Self.rustImagePrefix) { // 已经有 rust 协议头不重复添加
            return false
        }
        return true
    }

    private static func hasRustImagePrefix(key: String) -> Bool {
        key.hasPrefix(Self.rustImagePrefix)
    }

    private static let rustImagePrefix = "rust://image/"

    private static let resourceSemaphore = DispatchSemaphore(value: 1)
}
