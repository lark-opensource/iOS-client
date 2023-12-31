//
//  ResourceManager.swift
//  LarkVideoDirector
//
//  Created by Saafo on 2023/9/26.
//

import LarkEnv
import Foundation
import LarkStorage
import LarkContainer
import LKCommonsLogging
import LKCommonsTracker
import LarkAccountInterface
import OfflineResourceManager

enum ResourceManager {

    struct Resource {
        let key: String
        let fileName: String
        let type: DeliverType

        enum DeliverType {
            case gec // gecko，避讳
            case odr
        }

        // Default resources
        static let ocr = Resource(key: "effect_model_image_ocr", fileName: "image_ocr.model", type: .gec)
        static let aiCodec = Resource(key: "lensCodecModel",
                                      fileName: "lens_smart_codec_ios_v2.0.model", type: .odr)
    }

    private static let logger = Logger.log(ResourceManager.self, category: "ResourceManager")

    @Provider private static var passportService: PassportService

    static func fetchResource(for resource: Resource, completion: ((String?) -> Void)? = nil) {
        switch resource.type {
        case .odr:
            fetchODRResource(for: resource, completion: completion)
        case .gec:
            fetchGecResource(for: resource, completion: completion)
        }
    }

    static func localCache(for resource: Resource) -> String? {
        switch resource.type {
        case .odr:
            return localODRCache(for: resource)
        case .gec:
            return localGecCache(for: resource)
        }
    }

    // MARK: Gecko

    private static func fetchGecResource(for resource: Resource, completion: ((String?) -> Void)? = nil) {
        registerGecResourceIfNeeded(resource)
        if let path = gecCache(for: resource) {
            completion?(path)
            return
        }
        OfflineResourceManager.fetchResource(byId: resource.key) { isSuccess, status in
            logger.debug("fetch resource: \(resource.key) finished, success: \(isSuccess), status: \(status)")
            if let cachePath = gecCache(for: resource) {
                completion?(cachePath)
                return
            }
            logger.warn("failed to find cache after download for resource: \(resource.key)")
            completion?(nil)
            return
        }
    }

    private static func localGecCache(for resource: Resource) -> String? {
        registerGecResourceIfNeeded(resource)
        if let cachePath = gecCache(for: resource) {
            return cachePath
        }
        return nil
    }

    private static func registerGecResourceIfNeeded(_ resource: Resource) {
        let accessKey = currentGecAccessKey()
        let resourceConfig = OfflineResourceBizConfig(bizID: resource.key,
                                                      bizKey: accessKey,
                                                      subBizKey: resource.key)
        if case .unRegistered = OfflineResourceManager.getResourceStatus(byId: resourceConfig.bizID) {
            OfflineResourceManager.registerBiz(configs: [resourceConfig])
        }
    }

    private enum AccessKey {
        static let domesticOnline = "f2e97c8d28fd14414ce871534b57db7e"
        static let domesticPre = "80f3d6f8eb94aad0dc181ca3a881adcc"
        static let domesticBoe = "285fded323223388f4aedf68b975d216"
        static let overseaOnline = "3c2fec1517974f15d2acc29b8d9da298"
        static let overseaPre = "006b1e876ef90fef9e373ee7a0e8601b"
        static let overseaBoe = "2b1172275ce1d4df5e6c993a651e80ad"
    }

    private static func currentGecAccessKey() -> String {
        switch (EnvManager.env.type, self.passportService.isFeishuBrand) {
        case (.release, true):
            return AccessKey.domesticOnline
        case (.staging, true):
            return AccessKey.domesticBoe
        case (.preRelease, true):
            return AccessKey.domesticPre
        case (.release, false):
            return AccessKey.overseaOnline
        case (.staging, false):
            return AccessKey.overseaBoe
        case (.preRelease, false):
            return AccessKey.overseaPre
        @unknown default:
            return AccessKey.domesticOnline
        }
    }

    /// 查询 Gecko 本地缓存
    private static func gecCache(for resource: Resource) -> String? {
        if let path = OfflineResourceManager.rootDir(forId: resource.key) {
            let filePath = path + "/" + resource.fileName
            if filePath.asAbsPath().exists {
                logger.debug("found cache for resource: \(resource.key) path: \(filePath)")
                return filePath
            }
        }
        return nil
    }

    // MARK: ODR

    private static func fetchODRResource(for resource: Resource, completion: ((String?) -> Void)? = nil) {
        if let cache = localODRCache(for: resource) {
            completion?(cache)
            return
        }
        let request = NSBundleResourceRequest(tags: [resource.key])
        request.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent

        let backupAndReturnPath: () -> String? = {
            if let resourcePath = Bundle.main.path(forResource: resource.fileName, ofType: nil),
               let backupPath = odrBackupPath(for: resource) {
                try? resourcePath.asAbsPath().notStrictly.copyItem(to: backupPath.asAbsPath())
                if let cache = localODRCache(for: resource) {
                    Bundle.main.setPreservationPriority(0, forTags: [resource.key])
                    return cache
                }
            }
            return nil
        }
        let start = CACurrentMediaTime()
        request.conditionallyBeginAccessingResources { resourcesAvailable in
            guard !resourcesAvailable else {
                let path = backupAndReturnPath()
                completion?(path)
                postOdrTracker(start: start, type: "disk", size: nil, error: nil)
                return
            }
            request.beginAccessingResources { error in
                if let error {
                    print(error)
                    completion?(nil)
                    postOdrTracker(start: start, type: "net", size: nil, error: error)
                    return
                }
                let path = backupAndReturnPath()
                completion?(path)
                let size = path?.asAbsPath().fileSize
                postOdrTracker(start: start, type: "net", size: size, error: nil)
                return
            }
        }
    }

    private static func localODRCache(for resource: Resource) -> String? {
        if let backupPath = odrBackupPath(for: resource), backupPath.asAbsPath().exists {
            return backupPath
        }
        return nil
    }

    /// 因为每次要调用 (conditionally)beginAccessingResources 之后才能异步从 Bundle 获取到文件，所以这里做下备份便于同步获取。
    ///
    /// 系统那一份设置低优先级自动删除。
    /// 一般情况都不会返回 nil
    private static func odrBackupPath(for resource: Resource) -> String? {
        let folderPath = AbsPath.library
            .appendingRelativePath("OnDemandResources")
            .appendingRelativePath("\(resource.key)")
        try? folderPath.notStrictly.createDirectoryIfNeeded()
        return folderPath.appendingRelativePath("\(resource.fileName)").absoluteString
    }

    private static func postOdrTracker(start: TimeInterval, type: String, size: UInt64?, error: Error?) {
        let cost = CACurrentMediaTime() - start
        var params: [AnyHashable: Any] = [:]
        params["latency"] = cost
        params["load_type"] = type
        params["status"] = "success"
        if let size {
            params["resource_content_length"] = size
        }
        if let error {
            params["errorMsg"] = error.localizedDescription
            params["status"] = "failed"
        }
        let trackerName = "odr_download_dev"
        Tracker.post(TeaEvent(trackerName, params: params))
        logger.info("\(trackerName) params: \(params)")
    }
}
