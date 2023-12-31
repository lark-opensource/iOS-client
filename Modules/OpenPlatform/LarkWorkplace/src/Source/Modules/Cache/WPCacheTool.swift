//
//  WPCacheTool.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/4/21.
//

import Foundation
import ByteWebImage

private enum Const {
    // 缓存路径：Library/Caches/{{kCacheRootPath}}/{{namespace}}
    static let kCacheRootPath = "com.workplace.lark"

    // 缓存路径：Library/Caches/com.bd.imagcache.{{kImageCacheDomain}}
    static let kImageCacheDomain = "workplace"

    // 缓存路径：Library/Caches/{{kCacheRootPath}}/{{kVideoCacheDomain}}
    static let kVideoCacheDomain = "com.video.workplace"
}

class WPCacheTool {
    static var videoCachePath: String {
        if let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last {
            return root.path.appendingPathComponent("\(Const.kCacheRootPath)/\(Const.kVideoCacheDomain)")
        }
        return ""
    }

    /// 获取一个工作台图片下载器（通过此方法获取的的下载器共用统一的缓存目录）
    /// - Parameter withSession: 是否需要将 Session 设置到 Cookie 中
    /// - Returns: 图片下载器
    static func imageFetcher(withSession: Bool, session: String) -> ImageManager {
        let ins = ImageManager(category: Const.kImageCacheDomain)
        if withSession {
            ins.downloaderDefaultHttpHeaders = ["Cookie": "session=\(session)"]
        }
        return ins
    }
}
