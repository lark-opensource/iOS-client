//
//  ResourceMangerImpl.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/1.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkFoundation
import LarkSDKInterface
import RustPB
import LarkFeatureGating
import LarkContainer

/// SDKResource 不再同步读取磁盘缓存
/// isDiskCached 默认返回 false
/// Rust SDK 异步接口会优先获取本地资源缓存

open class SDKResourceStorageImpl<ResourceImpl: CanStorage>: ResourceStorage {
    public typealias ResourceItem = ResourceImpl

    public var name: String = ""
    public var options: [ResourceStorageOption] = [] {
        didSet {
            for option in options {
                switch option {
                case .callbackQueue(let cbq):
                    callbackQueue = cbq
                case .decode(let decoder):
                    self.decoder = decoder
                case .encode(let encoder):
                    self.encoder = encoder
                case .keyToFileName(let ktf):
                    keyToFileName = ktf
                @unknown default:
                    assert(false, "new value")
                    break
                }
            }
        }
    }
    //NSCache线程安全
    var memeryCache = NSCache<NSString, ResourceImpl>()
    private var processQueue: DispatchQueue
    private var callbackQueue: DispatchQueue
    private var decoder: (Data) -> Data? = { data in data }
    private var encoder: (Data) -> Data? = { data in data }
    private var keyToFileName: (String) -> String = { key in key }
    private var resourceAPI: ResourceAPI
    // FG功能：1. 取消encoder步骤。2. 并行改串行
    // 取消encoder是业务方行为。这里只做“并行”改“串行”

    public init(resourceAPI: ResourceAPI, memeryCacheSize: Int = 50 * 1024 * 1024) {
        self.resourceAPI = resourceAPI

        memeryCache.totalCostLimit = memeryCacheSize
        let parallelToSerialFG = resourceAPI.userResolver.fg.staticFeatureGatingValue(with: "messenger.audio.pre_decoder")
        if parallelToSerialFG {
            processQueue = DispatchQueue(label: "Lark.ResourceStorage.ProcessQueue", qos: .userInitiated)
        } else {
            processQueue = DispatchQueue(label: "Lark.ResourceStorage.ProcessQueue", qos: .userInitiated, attributes: .concurrent)
        }
        callbackQueue = .main
    }

    deinit {
        memeryCache.removeAllObjects()
    }

    public func isMemeryCached(key: String) -> Bool {
        return self.memeryCache.object(forKey: key as NSString) != nil
    }

    public func isDiskCached(key: String) -> Bool {
        return false
    }

    public func isCached(key: String) -> Bool {
        return isMemeryCached(key: key) || isDiskCached(key: key)
    }

    public func store(key: String, resource: ResourceImpl, compliteHandler: ((Data?) -> Void)? = nil) {
        let data = resource.getData()
        self.memeryCache.setObject(resource, forKey: key as NSString, cost: data.count)
        let workItem = DispatchWorkItem(flags: .barrier, block: {
            let decodeData = self.encoder(data)
            self.callbackQueue.lf.uiAsync {
                compliteHandler?(decodeData)
            }
        })
        self.processQueue.async(execute: workItem)
    }

    // 添加一个新key指向之前一个已经存在的key的内容
    public func store(key: String, oldKey: String, resource: ResourceImpl) {
        self.memeryCache.setObject(resource, forKey: key as NSString, cost: resource.getData().count)
        self.memeryCache.removeObject(forKey: oldKey as NSString)
    }

    public func remove(key: String) {
        self.memeryCache.removeObject(forKey: key as NSString)
        _ = resourceAPI.deleteResources(keys: [key]).subscribe(onNext: { (_) in
            SDKResourceDownloaderImpl.logger.info(
                "remove resources success",
                additionalData: ["key": key])
        }, onError: { (error) in
            SDKResourceDownloaderImpl.logger.error(
                "remove resources failed",
                additionalData: ["key": key],
                error: error)
        })
    }

    public func get(key: String) -> ResourceImpl? {
        if let resource = self.memeryCache.object(forKey: key as NSString) {
            return resource
        } else {
            let resource = self.getFromDisk(key: key)
            if let resource {
                self.memeryCache.setObject(resource, forKey: key as NSString, cost: resource.getData().count)
            }
            return resource
        }
    }

    public func get(key: String, resourceBlock: @escaping (ResourceImpl?) -> Void) {
        if let resource = self.memeryCache.object(forKey: key as NSString) {
            self.callbackQueue.lf.uiAsync {
                resourceBlock(resource)
            }
        } else {
            self.callbackQueue.lf.uiAsync {
                resourceBlock(nil)
            }
        }
    }

    public func getFromDisk(key: String) -> ResourceImpl? {
        return nil
    }

    public func cachePath(key: String) -> String {
        return ""
    }

    public func removeAllCache() {
        self.memeryCache.removeAllObjects()
    }
}

open class SDKResourceDownloaderImpl: ResourceDownloader {
    static let logger = Logger.log(SDKResourceDownloaderImpl.self, category: "SDKResourceDownloaderImpl")

    public static let downloadSceneKey = "ResourceDownloadSceneKey"
    public enum DownloadScene: String {
        case favorite  /// 收藏下载场景
        case todo
        case chat  /// 默认下载场景

        public static func transform(_ pb: RustPB.Media_V1_DownloadFileScene) -> Self {
            switch pb {
            case .favorite:
                return .favorite
            case .todo:
                return .todo
            case .chat, .unknown:
                return .chat
            @unknown default:
                assertionFailure("Media_V1_DownloadFileScene has new type")
                return .chat
            }
        }
    }

    final class ResourceLoadAction {
        var downloadCount: Int = 0
        var stateChanges: [(stateChange: StateChangeBlock, options: DownloadOptions)] = []
        var statusCode: Int = 0
        var data: NSMutableData?
        var dataLength: Int64 = 0
        var totalDataLength: Int64 = 0
        var downloadTask: ResourceDownloadTaskImpl?
    }

    public var name: String = "SDKResourceDownloader"

    var downloadTaskQueue: OperationQueue

    private(set) var stateChangeBlock: StateChangeBlock?

    public var maxDownloadConcurrentTaskCount: Int = 0

    public var keepAlive: Bool = true
    var writeLockQueue: DispatchQueue
    var processQueue: DispatchQueue
    public var defaultDownloadOptions: DownloadOptions?

    var stateChangeBlocks: [String: ResourceLoadAction] = [:]

    var resourceAPI: ResourceAPI

    public init(resourceAPI: ResourceAPI) {
        self.resourceAPI = resourceAPI
        self.downloadTaskQueue = OperationQueue()
        self.downloadTaskQueue.qualityOfService = .userInitiated
        self.downloadTaskQueue.name = "\(self.name).TaskQueue"
        self.writeLockQueue = DispatchQueue(label: "\(self.name).WriteLockQueue")
        self.processQueue = DispatchQueue(label: "\(self.name).ProcessQueue", qos: .default, attributes: .concurrent)
    }

    @discardableResult
    public func downloadResource(key: String, authToken: String?, onStateChangeBlock: (@escaping StateChangeBlock), options: DownloadOptions? = nil) -> ResourceDownloadTaskImpl? {
        let options = defaultDownloadOptions ?? .default
        var disposeBag = DisposeBag()
        var downloadScene: RustPB.Media_V1_DownloadFileScene = .chat
        if let resourceScene = options.context[Self.downloadSceneKey] as? String {
            switch resourceScene {
            case DownloadScene.favorite.rawValue:
                downloadScene = .favorite
            case DownloadScene.todo.rawValue:
                downloadScene = .todo
            case DownloadScene.chat.rawValue:
                downloadScene = .chat
            default:
                assertionFailure("DownloadScene has new type")
                downloadScene = .chat
            }
        }

        resourceAPI.fetchResource(key: key, path: nil, authToken: authToken, downloadScene: downloadScene, isReaction: false, isEmojis: false, avatarMap: nil)
            .subscribeOn(OperationQueueScheduler(operationQueue: self.downloadTaskQueue))
            .subscribe(onNext: { (resource) in
                disposeBag = DisposeBag()
                do {
                    let data = try Data.read_(from: resource.path)
                    if let decodeData = options.processor.processReceiveData(data) {
                        onStateChangeBlock(
                            DownloadStateImpl(
                                error: nil,
                                statusCode: 200,
                                readyState: .done,
                                data: decodeData,
                                dataLength: Int64(decodeData.count),
                                totalDataLength: Int64(decodeData.count)
                            )
                        )
                    }
                    return
                } catch {
                    onStateChangeBlock(
                        DownloadStateImpl(
                            error: error,
                            statusCode: 200,
                            readyState: .done,
                            data: nil,
                            dataLength: 0,
                            totalDataLength: 0
                        )
                    )
                }
                onStateChangeBlock(
                    DownloadStateImpl(
                        error: NSError(domain: "decode error", code: 0, userInfo: nil),
                        statusCode: 200,
                        readyState: .done,
                        data: nil,
                        dataLength: 0,
                        totalDataLength: 0
                    )
                )
            }, onError: { (error) in
                SDKResourceDownloaderImpl.logger.error(error.localizedDescription)
                onStateChangeBlock(
                    DownloadStateImpl(
                        error: error,
                        statusCode: 200,
                        readyState: .done,
                        data: nil,
                        dataLength: 0,
                        totalDataLength: 0
                    )
                )
            }).disposed(by: disposeBag)

        return nil
    }

    public func cancelDownloadTask(task: ResourceDownloadTaskImpl) {
    }

    public func pauseDownloadTask(task: ResourceDownloadTaskImpl) {
    }

    public func resumeDownloadTask(task: ResourceDownloadTaskImpl) {
    }

    public func clean(url: URL) {
    }
}
