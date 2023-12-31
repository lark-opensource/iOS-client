//
//  Cache+Debug.swift
//  ByteWebImage
//
//  Created by Saafo on 2022/9/5.
//

import Foundation
import LarkEnv

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

extension LarkImageService {
    enum Debug {
        static func clearMemoryCache() {
            LarkImageService.shared.thumbCache.memoryCache.removeAllObjects()
            LarkImageService.shared.originCache.memoryCache.removeAllObjects()
        }
        static func clearMemoryAndDiskCache() {
            LarkImageService.shared.clearAllCache()
        }
        @discardableResult
        static func clearSDKCache() -> Bool {
            let userID = LarkImageService.shared.dependency.currentAccountID
            var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ??
            URL(fileURLWithPath: NSHomeDirectory() + "/Documents/")
            url.appendPathComponent("sdk_storage")
            if EnvManager.env.isStaging {
                url.appendPathComponent("staging") // BOE 环境路径都在 staging 目录下
            }
            url.appendPathComponent(userID.bt.md5) // 用户文件夹为 UserID.md5
            url.appendPathComponent("resources") // 资源文件夹
            url.appendPathComponent("images") // 图片文件夹
            do {
                try FileManager.default.removeItem(at: url)
                LarkImageService.logger.info("removed sdk image cache, url: \(url)")
                return true
            } catch {
                LarkImageService.logger.error("remove sdk image cache failed: \(error), url: \(url)")
                return false
            }
        }
    }
}
