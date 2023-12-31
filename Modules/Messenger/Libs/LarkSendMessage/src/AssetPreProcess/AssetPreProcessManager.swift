//
//  AssetPreProcessManager.swift
//  LarkChat
//
//  Created by huanglx on 2021/10/12.
//

import UIKit
import Foundation
import LarkFoundation // Utils
import RxSwift // DisposeBag
import LKCommonsLogging // Logger
import LarkSDKInterface // UserGeneralSettings
import Photos // PHAsset
import LarkContainer // InjectedLazy
import RustPB // Media_V1_PreprocessResourceRequest
import LKCommonsTracker // Tracker
import ThreadSafeDataStructure // SafeDictionary
import ByteWebImage // ImageSourceResult

/// 资源预处理管理类
public final class AssetPreProcessManager: UserResolverWrapper {
    public let userResolver: UserResolver
    /// 预处理图片控制
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var rustService: SDKRustService?
    static let logger = Logger.log(AssetPreProcessManager.self, category: "AssetPreProcessManager")
    /// 是否是密聊
    private var isCrypto: Bool
    /// 是否是原图
    private var isOriginal: Bool = false

    /// 秒传 key 结果存储字典
    ///
    /// key: assetName
    /// value: 秒传 key
    private var preProcessResourceKeys: SafeDictionary<String, String> = [:] + .readWriteLock

    /// 已经处理的资源
    ///
    /// key: assetName
    /// value: ImageSourceResult
    private var finishAssets = SafeLRUDictionary<String, Any>()

    /// 队列中待处理的资源
    ///
    /// key: assetName
    /// value: 内部没使用
    private var pendingAssets: SafeDictionary<String, Any> = [:] + .readWriteLock
    /// 选择第一个资源的时间
    private var fistSelectTime: CFTimeInterval = 0
    /// 选择最后一个资源的时间
    private var lastSelectTime: CFTimeInterval = 0
    private let disposeBag = DisposeBag()
    /// 单测需要public出去，业务方不能设置
    public var checkEnable = false

    public init(userResolver: UserResolver, isCrypto: Bool) {
        self.userResolver = userResolver
        self.isCrypto = isCrypto
        let maxProcessCount = userGeneralSettings?.messagePreProcessConfig.maxProccessCount ?? 0
        self.finishAssets.capacity = maxProcessCount
        Self.logger.info("sendTree AssetPreProcessManager init, maxProcessCount: \(maxProcessCount), isCrypto: \(isCrypto)")
    }

    /// 添加处理完数据
    public func addToFinishAssets(name: String?, value: Any?) {
        guard self.checkEnable else {
            return
        }
        // 从处理队列数组中移除处理完的资源
        self.removeFromPendingAsset(name: name)
        if let name = name, let value = value {
            self.finishAssets.setValue(value, for: name)
            Self.logger.debug("sendTree addToFinishAssets, name:\(name)")
        }
    }

    /// 获取预处理资源key
    public func getPreprocessResourceKey(assetName: String) -> String? {
        guard self.checkEnable else {
            return nil
        }
        if self.preProcessResourceKeys.keys.contains(assetName), let key = self.preProcessResourceKeys[assetName] {
            AssetPreProcessManager.logger.info("sendTree getPreKey: \(key) for asset: \(assetName)")
            return key
        }
        return nil
    }

    /// 添加待处理数据，value内部没使用
    public func addToPendingAssets(name: String?, value: Any?) {
        guard self.checkEnable else {
            return
        }
        if let name = name, let value = value {
            if self.fistSelectTime == 0 {
                self.fistSelectTime = CACurrentMediaTime()
            }
            self.lastSelectTime = CACurrentMediaTime()
            self.pendingAssets.updateValue(value, forKey: name)
            Self.logger.debug("sendTree addToPendingAssets, name:\(name)")
        }
    }

    /// 获取处理完成图片数据
    public func getImageSourceResult(assetName: String) -> ImageSourceResult? {
        guard self.checkEnable else {
            return nil
        }
        if self.finishAssets.keys.contains(assetName),
           let imageResult = self.finishAssets[assetName] as? ImageSourceResult {
            return imageResult
        }
        return nil
    }

    /// 移除单个预处理资源
    public func cancelPreprocessResource(assetName: String) {
        guard self.checkEnable else {
            return
        }
        if let preprocessResourceKey = self.preProcessResourceKeys[assetName] {
            self.cancelPreProcessResource(key: preprocessResourceKey)
            self.preProcessResourceKeys.removeValue(forKey: assetName)
        }
    }

    /*
     资源秒传预处理
     param:
        filePath:文件路径
        fileType:文件类型
        assetName:资源名称
        imageSourceResult:图片资源预处理结果
     response：
        key：预处理标识，调用发送接口时通过key去查找预处理结果
     */
    public func preProcessResource(filePath: String?,
                                    data: Data?,
                                    fileType: Media_V1_PreprocessResourceRequest.FileType, assetName: String,
                                    imageSourceResult: ImageSourceResult?) {
        guard self.checkEnable else {
            return
        }
        var request = RustPB.Media_V1_PreprocessResourceRequest()
        request.fileType = fileType
        if let filePath = filePath {
            request.filePath = filePath
        }
        if let data = data {
            request.image = data
        }
        self.rustService?.sendAsyncRequest(request).subscribe(onNext: { [weak self] (resp: Media_V1_PreprocessResourceResponse) in
                //添加到处理完数组中
                self?.addToPreprocessResource(name: assetName, value: resp.key)
            }, onError: { error in
                Self.logger.error("sendTree preProcessResource failed: \(error)")
            }).disposed(by: self.disposeBag)
    }

    /// 预处理后处理
    public func afterPreProcess(assets: [PHAsset]) {
        guard self.checkEnable else {
            return
        }
        //取消冗余处理的key
        var keys = self.preProcessResourceKeys.keys
        var assetNames: [String] = []
        assets.forEach { asset in
            let assetKey = getDefaultKeyFrom(phAsset: asset)
            let assetName = self.combineImageKeyWithIsOriginal(imageKey: assetKey, isOriginal: self.isOriginal)
            assetNames.append(assetName)
        }
        // 用户最开始选中的是[A、B]，最后取消选中[B]点击发送[A]，这时候需要调用SDK接口取消[B]的预处理
        keys.forEach { key in
            if !assetNames.contains(key) {
               //取消资源
                let preprocessResourceKey = self.preProcessResourceKeys[key]
                if let preprocessResourceKey = preprocessResourceKey {
                    self.cancelPreProcessResource(key: preprocessResourceKey)
                }
            }
        }

        //埋点
        if self.fistSelectTime != 0, self.lastSelectTime != 0 {
            //选择第一个时间
            let firstSelectToSendInterval = (CACurrentMediaTime() - fistSelectTime) * 1000
            //选择最后一个的时间
            let lastSelectToSendInterval = (CACurrentMediaTime() - lastSelectTime) * 1000
            //预处理个数
            let resourceCount = self.preProcessResourceKeys.keys.count
            //时机发送的个数
            let preProcessResourceCount = assets.count
            let param: [String: Any] = ["first_select_to_send_interval": firstSelectToSendInterval,
                                         "last_select_to_send_interval": lastSelectToSendInterval,
                                         "resource_count": resourceCount,
                                         "pre_process_resource_count": preProcessResourceCount]
            Tracker.post(TeaEvent("resource_select_dev",
                                  params: param))
            self.lastSelectTime = 0
            self.fistSelectTime = 0
            AssetPreProcessManager.logger.info("sendTree finish, post event: \(param)")
        }
        //释放资源
        self.finishAssets.removeAll()
        self.preProcessResourceKeys.removeAll()
    }

    /// 从 PHAsset 获取缓存 key，目前就图片在使用，文件不需要，视频在VideoMessageSend
    public func getDefaultKeyFrom(phAsset: PHAsset) -> String {
        // 一般情况下if都会有值
        if let resource = phAsset.assetResource {
            let assetLocalIdentifier = resource.assetLocalIdentifier
            let modificationDate: Double? = phAsset.modificationDate?.timeIntervalSince1970
            var date: String = ""
            if let modificationDate {
                date = "\(modificationDate)"
            }
            // 用Identifier + modificationDate区别编辑过的PHAsset
            let key = (assetLocalIdentifier + date).md5()
            Self.logger.info("sendTree getDefaultKey: \(key), from resource: \(resource), for phasset: \(phAsset)")
            return key
        } else {
            let key = phAsset.localIdentifier.md5()
            let resources = PHAssetResource.assetResources(for: phAsset)
            Self.logger.warn("sendTree getDefaultKey: \(key), from phasset: \(phAsset), instead of resources: \(resources)")
            return key
        }
    }

    /// 组合图片的key区分原图和非原图
    public func combineImageKeyWithIsOriginal(imageKey: String, isOriginal: Bool) -> String {
        self.isOriginal = isOriginal
        return imageKey + (isOriginal ? "_oiginal" : "_notOriginal")
    }

    /// 组合图片 key 和 "\_cover"
    public func combineImageKeyWithCover(imageKey: String) -> String {
        return imageKey + "_cover"
    }

    /// 针对类型是否开启预处理
    public func checkEnableByType(fileType: Media_V1_PreprocessResourceRequest.FileType) -> Bool {
        switch fileType {
        case .image:
            return self.checkPreProcessEnable
        case .media:
            return self.checkPreProcessEnable
        case .file:
            return self.checkPreProcessEnable
        @unknown default:
            return self.checkPreProcessEnable
        }
    }

    /// 判断是否开启预处理
    public lazy var checkPreProcessEnable: Bool = {
        let enablePreProccessFromSettings = userGeneralSettings?.messagePreProcessConfig.enablePreProccess ?? false
        //如果settings配置开启且非密聊
        let result = enablePreProccessFromSettings && !isCrypto
        self.checkEnable = result
        AssetPreProcessManager.logger.info("sendTree checkPreProcessEnable: \(result), setting: \(enablePreProccessFromSettings), isCrypto: \(isCrypto)")
        return result
    }()

    /// 判断是否要预处理 cover
    public lazy var checkPreprocessCoverEnable: Bool = {
        let enable = userGeneralSettings?.messagePreProcessConfig.enableCoverPreprocess ?? false
        Self.logger.info("sendTree coverEnable: \(enable)")
        return enable
    }()

    /// 判断内存是否足够
    public func checkMemoryIsEnough() -> Bool {
        guard let userGeneralSettings else { return true }
        let availableMemory = (try? Utils.availableMemory) ?? 0
        let isEnough = availableMemory > userGeneralSettings.messagePreProcessConfig.maxMemory * 1024
        if !isEnough {
            Self.logger.info("sendTree checkMemory failed, free memory: \(availableMemory)")
        }
        return isEnough
    }

    /// 判断资源是否已经处理
    public func checkAssetHasOperation(assetName: String) -> Bool {
        guard self.checkEnable else {
            return false
        }
        return self.finishAssets.keys.contains(assetName) || self.pendingAssets.keys.contains(assetName)
    }

    /// 取消任务
    public func cancelAllOperation() {
        guard self.checkEnable else {
            return
        }
        self.cancelAllTask()
        self.pendingAssets.removeAll()
    }

    /// 添加秒传预处理返回的key
    public func addToPreprocessResource(name: String?, value: String?) {
        if let name = name, let value = value {
            self.preProcessResourceKeys.updateValue(value, forKey: name)
        }
    }

    /// 移除待处理数据
    public func removeFromPendingAsset(name: String?) {
        if let name = name {
            self.pendingAssets.removeValue(forKey: name)
            Self.logger.debug("sendTree removeFromPendingAsset name:\(name)")
        }
    }

    /// 取消资源
    private func cancelPreProcessResource(key: String) {
        var request = RustPB.Media_V1_CancelPreprocessResourceRequest()
        request.key = key
        self.rustService?.sendAsyncRequest(request).subscribe().disposed(by: self.disposeBag)
    }

    ///队列管理
    private lazy var assetQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "assetQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()

    private var queueSuspendOperationCount = OperatorCounter()

    /// 队列任务个数
    private var assetQueueOperationCount: Int {
        return assetQueue.operationCount
    }

    /// 恢复队列
    public func resumeQueue() {
        queueSuspendOperationCount.decrease(category: "AssetPreProcessManager") { [weak self] in
            self?.assetQueue.isSuspended = false
        }
    }

    /// 暂停队列
    public func pauseQueue() {
        queueSuspendOperationCount.increase(category: "AssetPreProcessManager") { [weak self] in
            self?.assetQueue.isSuspended = true
        }
    }

    /// 取消队列中的任务
    public func cancelAllTask() {
        self.assetQueue.cancelAllOperations()
    }

    /// 当前队列是否处于暂停状态
    public func queueIsPause() -> Bool {
        return queueSuspendOperationCount.hasOperator
    }

    /// 添加一个任务
    public func addAssetProcessOperation(_ operation: Operation) {
        self.assetQueue.addOperation(operation)
    }

    /// 添加一组任务
    public func addAssetProcessOperations(_ operations: [Operation], waitUntilFinished: Bool = false) {
        self.assetQueue.addOperations(operations, waitUntilFinished: waitUntilFinished)
    }
}

/// 移除对LarkCore的依赖，Copy一份
public final class OperatorCounter {
    public var hasOperator: Bool { self.threadSafe { return _hasOperator } }
    private var _hasOperator: Bool = false
    private var operatorCountMap: [String: Int] = [:]
    private var lock: NSRecursiveLock = NSRecursiveLock()

    //增加操作计数，category: 区分不同场景
    public func increase(category: String, hasOperator: (() -> Void)? = nil) {
        self.threadSafe {
            let operatorCount = (operatorCountMap[category] ?? 0) + 1
            operatorCountMap[category] = operatorCount
            if !self._hasOperator {
                self._hasOperator = true
                hasOperator?()
            }
        }
    }

    //减少操作计数，category: 区分不同场景
    public func decrease(category: String, noneOperator: (() -> Void)? = nil) {
        self.threadSafe {
            var operatorCount = (operatorCountMap[category] ?? 0) - 1
            if operatorCount < 0 { operatorCount = 0 }
            operatorCountMap[category] = operatorCount
            var hasOperator = false
            for v in self.operatorCountMap where v.value != 0 {
                hasOperator = true
                break
            }
            if !hasOperator, self._hasOperator != hasOperator {
                self._hasOperator = hasOperator
                noneOperator?()
            }
        }
    }

    private func threadSafe<R>(perform: () -> R) -> R {
        lock.lock()
        defer { lock.unlock() }
        return perform()
    }
}
