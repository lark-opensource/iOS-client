//  Created by Songwen Ding on 2018/7/25.
//  注意：新增的缓存，如果是非自动清理的，要求业务有清理逻辑，避免磁盘无限增加

import SKFoundation
import LarkCache
import LarkFileKit
import LarkStorage
import UniverseDesignToast
import SKResource

public final class CacheService {

    private static var currentUserIdStr: String {
        guard let userID = User.current.info?.userID else {
            spaceAssertionFailure("failed to get user id when access user cache")
            return "unknown"
        }
        return userID
    }

    // 父节点，路径:library/DocsSDK/$uid
    private enum SKUserPath: Biz {
        static var parent: Biz.Type? = CCM.self
        static var path: String = currentUserIdStr
    }

    // 会自动清理, 不区分用户, 路径:library/Caches/DocsSDK/skNormalCache
    private enum SKNormalCache: Biz {
        static var parent: Biz.Type? = CCM.self
        static var path: String = "skNormalCache"
        static var directory: CacheDirectory = CacheDirectory.cache
    }

    // 不会自动清理, 区分用户, 路径:library/DocsSDK/$uid/skConfigCache
    private enum SKConfigCache: Biz {
        static var parent: Biz.Type? = SKUserPath.self
        static var path: String = "skConfigCache"
        static var directory: CacheDirectory = CacheDirectory.library
    }

    // 特殊图片缓存，不会自动清理, 路径:library/DocsSDK/docsImageStore
    private enum DocsImageStore: Biz {
        static var parent: Biz.Type? = CCM.self
        static var path: String = "docsImageStore"
        static var directory: CacheDirectory = CacheDirectory.library
    }

    // 图片缓存，会自动清理, 路径:library/Caches/DocsSDK/docsImageCache
    private enum DocsImageCache: Biz {
        static var parent: Biz.Type? = CCM.self
        static var path: String = "docsImageCache"
        static var directory: CacheDirectory = CacheDirectory.cache
    }

    // 视频/file缓存，会自动清理, 路径:library/Caches/DocsSDK/SKVideoFileCache
//    private enum SKVideoFileCache: Biz {
//        static var parent: Biz.Type? = CCM.self
//        static var path: String = "SKVideoFileCache"
//        static var directory: CacheDirectory = CacheDirectory.cache
//    }

    // 通用普通缓存
    // 无限增加的普通数据可以存放到这里
    public static var normalCache: Cache {
        let domain = Domain.biz.ccm.child("skNormalCache")
        let cachePath: IsoPath = .in(space: .global, domain: domain).build(.cache)
        let cache: Cache = CacheManager.shared.cache(
            rootPath: cachePath,
            cleanIdentifier: "library/Caches/DocsSDK/skNormalCache"
        ).asCryptoCache()
        return cache
    }
        

    // 通用配置缓存
    // 一些全局配置项可以存放到这里，注意无限增长的数据不能存到这里，例如每个文档的数据（文档数量是无限增长的）
    public static var configCache: Cache {
        configCache(for: currentUserIdStr)
    }

    public static func configCache(for userID: String) -> Cache {
        let space: Space = .user(id: userID)
        let domain = Domain.biz.ccm.child("skConfigCache")
        let cachePath: IsoPath = .in(space: space, domain: domain).build(.library)
        let cache: Cache = CacheManager.shared.cache(
            rootPath: cachePath,
            cleanIdentifier: "library/DocsSDK/$uid/skConfigCache"
        ).asCryptoCache()
        return cache
    }

    // 文档内，手动离线图片存储（包括未同步图片）(加解密！！！)
    public static var docsImageStore: Cache {
        let domain = Domain.biz.ccm.child("docsImageStore")
        let cachePath: IsoPath = .in(space: .global, domain: domain).build(.library)
        let cache: Cache = CacheManager.shared.cache(
            rootPath: cachePath,
            cleanIdentifier: "library/DocsSDK/docsImageStore"
        ).asCryptoCache()
        return cache
    }

    // 文档内，图片临时缓存 (加解密！！！)
    public static var docsImageCache: Cache {
        let domain = Domain.biz.ccm.child("docsImageCache")
        let cachePath: IsoPath = .in(space: .global, domain: domain).build(.cache)
        let cache: Cache = CacheManager.shared.cache(
            rootPath: cachePath,
            cleanIdentifier: "library/Caches/DocsSDK/docsImageCache"
        ).asCryptoCache()
        return cache
    }

}



// MARK: - 删除旧的缓存文件
extension CacheService {
    public class func deleteOldFileIfExist() {
        if oldCachePath.exists {
            do {
                let result = try oldCachePath.removeItem()
                DocsLogger.error("[SKFilePath] move old cache file \(result)")
            } catch {
                DocsLogger.error("[SKFilePath] move old cache file failed.")
            }
        }
    }

    static private var oldCachePath: SKFilePath = {
        return SKFilePath.globalSandboxWithLibrary.appendingRelativePath("CacheService")
    }()
}

extension CacheService {

    /// 落盘加密是否开启 https://bytedance.feishu.cn/docs/doccn9FUsFRGCTEf5jImKMp9w8d
    public static func isDiskCryptoEnable() -> Bool {
        return isCryptoEnable()
    }
    
    public static func showFailureIfDiskCryptoEnable(on view: UIView) -> Bool {
        if Self.isDiskCryptoEnable() {
            DocsLogger.error("[KACrypto] can't save or export", component: LogComponents.newCache)
            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_ShareSecuritySettingKAToast, on: view)
            return true
        }
        return false
    }
}
