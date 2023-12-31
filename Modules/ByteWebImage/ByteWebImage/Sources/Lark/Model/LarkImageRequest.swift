//
//  LarkImageRequest.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/13.
//

import Foundation

public final class LarkImageRequest: ImageRequest {

    var resource: LarkImageResource
    var passThrough: ImagePassThrough?
    public var contextId: String?

    /// 建议通过这个方法
    public required init(resource: LarkImageResource, category: String? = nil) throws {
        guard let url = resource.generateURL() else {
            let error = ImageError(ByteWebImageErrorBadImageUrl,
                                          userInfo: [NSLocalizedDescriptionKey: "can not analysis key"])
            throw error
        }
        self.resource = resource
        super.init(url: url, category: category)
        self.originKey.setCustomCacheKey(self.resource.cacheKey)
    }
    // 默认图片
    public required init(url: URL, alternativeURLs: [URL] = [], category: String? = nil) {
        if url.scheme != nil {
            self.resource = LarkImageResource.default(key: url.absoluteString)
        } else {
            self.resource = LarkImageResource.default(key: "rust://image/\(url.absoluteString)")
        }
        super.init(url: url, category: category)
        self.originKey.setCustomCacheKey(self.resource.cacheKey)
    }

    static func create(resource: LarkImageResource, url: URL) -> Self {
        (try? self.init(resource: resource)) ?? self.init(url: url)
    }
}

// convenient init empty request
extension ImageRequest {
    /// 设置图片的 key 为空且 placeholder 非空时，可能会在 Result.request 中返回此 URL
    public static let emptyURL = URL(string: "bytewebimage://empty-url") ?? URL(fileURLWithPath: "")

    /// 构建空 Request 便利属性
    static var emptyRequest: ImageRequest {
        // fileURLWithPath 有一次 IO，尽量避免调用
        // https://bytedance.feishu.cn/docx/doxcniSiFoBGmz1bHD6R0z5mFee
        ImageRequest(url: emptyURL)
    }
}
