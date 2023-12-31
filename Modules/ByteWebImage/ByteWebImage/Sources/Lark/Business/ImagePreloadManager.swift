//
//  ImagePreloadManager.swift
//  ByteWebImage
//
//  Created by Saafo on 2022/12/29.
//

import Foundation
import LarkContainer
import LarkFoundation
import LarkRustClient
import LKCommonsLogging
import LKCommonsTracker
import Reachability
import RustPB
import ThreadSafeDataStructure
import LarkPreload
import LarkSetting

/// 图片预加载管理类
final public class ImagePreloadManager {

    // MARK: - Public Interface

    /// 全局单例
    public static let shared = ImagePreloadManager()

    /// 预加载图片
    /// - Parameters:
    ///   - scene: 具体场景，eg: "feed" "chat"
    ///   - sceneID: 具体场景的 ID，eg：ChatID "123456"
    ///   - sceneSubID: 场景的子 ID，目前主要是 Message ID，便于追查问题
    ///   - imageItem: 预加载 ImageItem
    /// - Note: 线程安全；耗时，不要在主线程调用
    public func preload(scene: String, sceneID: String, sceneSubID: String, imageItem: ImageItem) {
        guard !scene.isEmpty, !sceneID.isEmpty, let imageKey = imageItem.key, !imageKey.isEmpty else {
            Self.logger.trace("problematic info: scene: \(scene), sceneID: \(sceneID), imageKey: \(imageItem)")
            return
        }
        let record = PreloadRecord(scene: scene, sceneID: sceneID, sceneSubID: sceneSubID, imageItem: imageItem, state: .pending)
        guard checkShouldPreload(record: record) else { return }
        guard !checkHasCached(record: record) else { return }
        tryAddToPendingQueue(record: record)
    }

    /// 取消预加载任务，退出会话时可以调用
    /// - Parameters:
    ///   - scene: 具体场景，eg: "feed" "chat"
    ///   - sceneID: 具体场景的 ID，eg：ChatID "123456"
    /// - Note: 线程安全
    public func cancelPreload(scene: String, sceneID: String) {
        lock.writeOperation {
            unsafeLoadingList.removeAll { (record, request) in
                if record.scene == scene && record.sceneID == sceneID {
                    request.cancel()
                    return true
                } else {
                    return false
                }
            }
            unsafePendingQueue.removeAll { $0.scene == scene && $0.sceneID == sceneID }
        }
        tryLoadFromPendingQueue()
    }

    // MARK: - Internal Interface

    /// 预加载记录
    struct PreloadRecord: Equatable {
        enum State: String {
            /// 不需要预加载，本地有缓存时则标记为 needless，对应埋点中的 needless
            case needless
            /// 预加载等待中，对应埋点 none
            case pending
            /// 预加载过程中，对应埋点 preloading
            case preloading
            /// 预加载成功，对应埋点 preloaded
            case preloaded
            /// 预加载失败
            case failed
            /// 结果已消费，对应埋点中的 consumed
            case consumed
        }
        /// 具体场景 eg: "feed" "chat"
        var scene: String
        /// 具体场景的 ID，eg：ChatID "123456"
        var sceneID: String
        /// 场景的子 ID，目前主要是 Message ID，便于追查问题
        var sceneSubID: String
        /// ImageItem
        var imageItem: ImageItem
        /// 预加载状态
        var state: State
        /// 开始加载的时间戳
        var startTime: CFTimeInterval = 0

        static func == (lhs: Self, rhs: Self) -> Bool {
            // imageKey 相等即认为相等，忽略场景来源。
            guard let leftKey = lhs.imageItem.key, !leftKey.isEmpty,
                  let rightKey = rhs.imageItem.key, !rightKey.isEmpty else { return false }
            return leftKey == rightKey
        }
    }

    /// 获取预加载结果
    /// - Parameters:
    ///   - imageKey: 图片 key
    ///   - consumeRecord: 是否要消费记录，相当于把记录状态标记为 consumed
    /// - Returns: 返回预加载结果，如果返回为空代表没有进行过预加载
    internal func getResult(imageKey: String, consumeRecord: Bool = true) -> PreloadRecord? {
        if FeatureGatingManager.shared.featureGatingValue(with: "lark.image.preload.enable") {
            //命中反馈
            PreloadMananger.shared.feedbackForDiskCache(diskCacheId: imageKey, preloadBiz: .Common, preloadType: .ImageType)
        }
        let (shouldReturn, record) = lock.readOperation {
            let record = unsafeResultCache.getValue(for: imageKey, update: false) ??
                unsafeLoadingList.first(where: { $0.record.imageItem.key == imageKey })?.record ??
                unsafePendingQueue.first(where: { $0.imageItem.key == imageKey })
            if record == nil || !consumeRecord || record?.state != .preloaded {
                return (true, record)
            } else {
                return (false, record)
            }
        }
        if shouldReturn {
            return record
        }
        return lock.writeOperation {
            if let record = unsafeResultCache[imageKey] {
                var consumedRecord = record
                consumedRecord.state = .consumed
                unsafeResultCache[imageKey] = consumedRecord
                return record
            } else {
                return nil
            }
        }
    }

    // MARK: - Internal Attributes

    // MARK: Data Caches

    /// 结果存储类
    ///
    /// - Key: imageKey
    /// - Value: PreloadResult
    /// - Note: 线程不安全，需要加锁操作
    private var unsafeResultCache: UnsafeLRUDictionary<String, PreloadRecord> = .init()

    /// 用于 cancelRequest 的正在加载缓存
    ///
    /// LoadingList 同时最多加载 m 个 (m = 2)
    /// 加载成功后，会将结果存到 resultCache，并且尝试从 pendingQueue pop
    /// - Note: 线程不安全，需要加锁操作
    private var unsafeLoadingList: [(record: PreloadRecord, request: LarkImageRequest)] = []

    /// 排队缓存
    ///
    /// PendingQueue 同时最多值排队 n 个 (n = 5)，超过了忽略当前将要加入的。
    /// 当有新请求加入 pendingQueue 且 loadingList 空闲时，或 loadingList 有成员加载成功时，会 pop pendingQueue
    /// - Note: 线程不安全，需要加锁操作
    private var unsafePendingQueue: [PreloadRecord] = []

    private var lock = SynchronizationType.readWriteLock.generateSynchronizationDelegate()

    // MARK: Attributes

    private static let logger = Logger.log(ImagePreloadManager.self)

    private let reachability: Reachability? = {
        let reachability = Reachability()
        try? reachability?.startNotifier()
        return reachability
    }()

    private var dynamicNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus = .excellent

    private let weakNetStatus: [Basic_V1_DynamicNetStatusResponse.NetStatus] = [
        .weak, .netUnavailable, .serviceUnavailable
    ]

    private var weakNet: Bool {
        weakNetStatus.contains(dynamicNetStatus)
    }

    private var currentInBackground: Bool = false

    private var config: ImagePreloadConfig { LarkImageService.shared.imagePreloadConfig }

    // MARK: Init

    internal init() {
        unsafeResultCache.capacity = config.preloadCacheCount
        _ = SimpleRustClient.global.register(pushCmd: .pushDynamicNetStatus) { [weak self] (message: RustPB.Basic_V1_DynamicNetStatusResponse) in
            self?.dynamicNetStatus = message.netStatus
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    deinit {
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Processes

    private func checkShouldPreload(record: PreloadRecord) -> Bool {
        guard config.preloadEnable,
              let sceneConfig = config.getStrategy(from: record.scene),
              sceneConfig.preloadEnable != 0 else {
            Self.logger.trace("config not permit, config: \(config), ignore record: \(record)")
            return false
        }
        // Network check
        if config.networkLimit == 1, weakNet {
            Self.logger.trace("due to weak net, ignore record: \(record)")
            return false
        } else if config.networkLimit == 2, let reachability, reachability.connection != .wifi {
            Self.logger.trace("due to network \(reachability.connection) is not wifi, ignore record: \(record)")
            return false
        }
        // CPU check
        let currentCPUUsage = (try? Utils.averageCPUUsage) ?? 100
        if Float(config.cpuLimit) < currentCPUUsage {
            Self.logger.trace("due to cpu usage \(currentCPUUsage) exceeded config \(config.cpuLimit), ignore record: \(record)")
            return false
        }
        return true
    }

    private func checkHasCached(record: PreloadRecord) -> Bool {
        if LarkImageService.shared.isCached(resource: .default(key: record.imageItem.key ?? "")) {
            Self.logger.trace("image already cached, ignore record: \(record)")
            return true
        } else {
            return false
        }
    }

    /// 尝试加入等待队列，内部会校验是否能够加入等待队列，是否已有请求
    private func tryAddToPendingQueue(record: PreloadRecord) {
        let needContinue = lock.writeOperation {
            let scene = record.scene
            let maxCount = config.getStrategy(from: scene)?.maxCount ?? 0
            let existingCount = unsafePendingQueue.filter({ $0.scene == scene }).count
            // 校验是否超过排队限制，超过直接忽略
            guard maxCount > existingCount else {
                Self.logger.trace("maxCount \(maxCount) exceeded existingCount \(existingCount), ignore record: \(record)")
                return false
            }
            // 校验是否已有请求，已有直接忽略
            guard !unsafePendingQueue.contains(record),
                  !unsafeLoadingList.lazy.map({ $0.record }).contains(record),
                  let imageKey = record.imageItem.key,
                  unsafeResultCache[imageKey] == nil else {
                Self.logger.trace("already requesting or requested, ignore record: \(record)")
                return false
            }
            unsafePendingQueue.append(record)
            Self.logger.trace("add to pending queue, record: \(record)")
            return true
        }
        guard needContinue else { return }
        tryLoadFromPendingQueue()
    }

    /// 尝试从 pendingQueue 取一个请求开始请求并加入 loadingList
    /// 禁止在主线程调用
    private func tryLoadFromPendingQueue() {
        if PreloadMananger.shared.preloadEnable(), FeatureGatingManager.shared.featureGatingValue(with: "lark.image.preload.enable") {
            PreloadMananger.shared.addTask(preloadName: "lark_image_preload", biz: .Common, preloadType: .ImageType, hasFeedback: true) {
                self.loadFromPendingQueue()
            } stateCallBack: { _ in
            }
        } else {
            self.loadFromPendingQueue()
        }
    }
    
    private func loadFromPendingQueue() {
        lock.writeOperation {
            // 校验 loadingList 是否空置，pendingQueue 是否有等待请求
            guard (unsafeLoadingList.count < config.maxConcurrentCount || config.maxConcurrentCount == 0),
                  !unsafePendingQueue.isEmpty else {
                Self.logger.trace("tryLoadFromPendingQueue stop due to loadingCount: \(unsafeLoadingList.count), " +
                                  "configConcurrent: \(config.maxConcurrentCount), pendingCount: \(unsafePendingQueue.count)")
                return
            }
            var record = unsafePendingQueue.removeFirst()
            record.startTime = CACurrentMediaTime()
            record.state = .preloading

            guard let request = LarkImageService.shared.setImage(with: record.imageItem.imageResource(),
                                                                 options: [.ignoreImage, .priority(.low)],
                                                                 completion: { [weak self] result in
                self?.addToResultCache(record: record, result: result)
                self?.tryLoadFromPendingQueue()
            }) else {
                Self.logger.warn("generate request failed, ignore record: \(record)")
                return
            }
            unsafeLoadingList.append((record: record, request: request))
            Self.logger.trace("start loading record: \(record)")
        }
    }

    private func addToResultCache(record: PreloadRecord, result: ImageRequestResult) {
        var params: [String: Any] = ["result": "failed",
                                     "latency": (CACurrentMediaTime() - record.startTime) * 1000,
                                     "net_state": weakNet ? 0 : 1,
                                     "app_is_front": currentInBackground ? 0 : 1]
        lock.writeOperation {
            guard let index = self.unsafeLoadingList.firstIndex(where: { $0.record == record }),
                  let imageKey = record.imageItem.key else {
                Self.logger.warn("unexpected to find record in loadingList, record: \(record), list: \(unsafeLoadingList)")
                return
            }
            unsafeLoadingList.remove(at: index)
            var record = record
            switch result {
            case .success:
                record.state = .preloaded
                params["result"] = "success"
                Self.logger.debug("finished preload, record: \(record), params: \(params)")
            case .failure(let error):
                record.state = .failed
                Self.logger.error("finished preload with error: \(error), record: \(record), params: \(params)")
            }
            unsafeResultCache.setValue(record, for: imageKey)
        }
        Tracker.post(TeaEvent("image_preload_result_dev", params: params))
    }

    // MARK: - Utils

    @objc
    private func applicationWillEnterForeground() {
        currentInBackground = false
    }

    @objc
    private func applicationDidEnterBackground() {
        currentInBackground = true
    }
}
