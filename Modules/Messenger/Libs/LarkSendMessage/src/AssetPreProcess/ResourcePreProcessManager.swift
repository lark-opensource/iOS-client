//
//  ResourcePreProcessManager.swift
//  LarkSendMessage
//
//  Created by kangkang on 2023/8/11.
//

import Foundation
import Photos                   // PHAsset
import RustPB                   // Media_V1_PreprocessResourceRequest
import RxSwift                  // DisposeBag
import ByteWebImage             // ImageSourceResult
import LarkContainer            // InjectedLazy
import LarkSDKInterface         // UserGeneralSettings
import LKCommonsLogging         // Logger
import LKCommonsTracker         // Tracker
import ThreadSafeDataStructure  // SafeDictionary

// 业务方实现处理图片逻辑
public protocol PreProcessProtocol {
    func processImage(_ image: PHAsset, suffix: ResourcePreProcessManager.NameSuffix) -> ImageSourceResult?
    func processImage(_ image: UIImage, suffix: ResourcePreProcessManager.NameSuffix) -> ImageSourceResult?
}
public final class ResourcePreProcessManager: UserResolverWrapper {
    // 资源设置的执行步骤（预处理、秒传。二选一或者二选二）
    public typealias Options = Set<ProcessStep>
    public let userResolver: UserResolver
    private let scene: Media_V1_PreprocessResourceRequest.Scene

    private let logger = Logger.log(ResourcePreProcessManager.self, category: "AssetPreProcessManager")
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    private let cache: LarkDiskCache = LarkDiskCache(with: "com.lark.cache.thumb")
    // 当前选中的resource
    private var resourcesDic: SafeDictionary<String, ResourceResult> = [:] + .readWriteLock
    private lazy var assetProcessQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "assetProcessQueue"
        queue.maxConcurrentOperationCount = userGeneralSettings?.messagePreProcessConfig.processMaxConcurrentOperationCount ?? 1
        queue.qualityOfService = .userInteractive
        return queue
    }()

    private lazy var assetCancelQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "assetCancelQueue"
        queue.maxConcurrentOperationCount = userGeneralSettings?.messagePreProcessConfig.processMaxConcurrentOperationCount ?? 1
        queue.qualityOfService = .userInteractive
        return queue
    }()

    // 资源类型
    public enum ResourceType {
        static let prefix = "send_resource_"
        // PHAsset的图片资源
        case imageAsset(PHAsset)
        // 图片 Cover 资源和对应的PHAsset
        case image(UIImage, PHAsset)
        // 视频目标压缩路径
        case media(String)
        // 文件导出路径
        case file(String)

        var rawValue: String {
            switch self {
            case .image(_, let asset): return ResourceType.prefix + ResourcePreProcessManager.getDefaultKeyFrom(phAsset: asset)
            case .imageAsset(let asset): return ResourceType.prefix + ResourcePreProcessManager.getDefaultKeyFrom(phAsset: asset)
            case .file(let s): return ResourceType.prefix + s
            case .media(let s): return ResourceType.prefix + s
            }
        }
    }

    // 名字后缀。从 resource 对应name，可能需要带上后缀
    public enum NameSuffix: Hashable {
        case none
        // 图片发送，是否原图
        case image(Bool)
        // 图片发送，cover图
        case cover
        case custom(String)

        var rawValue: String {
            switch self {
            case .none: return ""
            case .image(let origin): return origin ? "_origin" : "_notOriginal"
            case .cover: return "_cover"
            case .custom(let n): return "_" + n
            }
        }
    }

    /// 当前业务使用：
    ///         图片cover  图片图     file    media
    /// 预处理             ✅          ✅        ❌      ❌
    /// 秒传                 ❌          ✅       ✅      ✅
    ///
    /// 分为“预处理”和“秒传”两个步骤，业务可以选择执行二选一或者二选二
    public enum ProcessStep: Hashable {
        // 预处理
        case preprocessing(pro: any PreProcessProtocol)
        // 秒传/预上传
        case preSwiftTransmission

        var rawValue: String {
            switch self {
            case .preSwiftTransmission: return "preSwiftTransmission"
            case .preprocessing(pro: let pre): return "preprocessing \(pre)"
            }
        }

        public static func == (lhs: ResourcePreProcessManager.ProcessStep, rhs: ResourcePreProcessManager.ProcessStep) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.rawValue)
        }
    }

    public init(userResolver: UserResolver, scene: Media_V1_PreprocessResourceRequest.Scene) {
        self.userResolver = userResolver
        self.scene = scene
    }

    deinit {
        logger.info("resource process deinit")
        resourcesDic.forEach { (_, resource) in
            // 没有 get 过的，执行 cancel
            self.assetCancelQueue.addOperations(resource.addCancelIfNeeded(), waitUntilFinished: false)
        }
    }

    // 待处理的资源
    public func onResourcesChanged(_ resources: [(ResourceType, NameSuffix, Options)]) {
        guard userGeneralSettings?.messagePreProcessConfig.enablePreProccess ?? false else { return }
        // 如果传入的resource为空，可能是1.反勾选。2.没有选图片。如果是反勾选，需要正常走流程（会删除资源）。如果是没有选图片则应该继续走流程
        if resources.isEmpty, resourcesDic.isEmpty { return }
        // 待删除的
        let deleteResources = resourcesDic
        // 待处理的
        let newResources: SafeDictionary<String, ResourceResult> = [:] + .readWriteLock
        // 已经处理过的
        let hadResources: SafeDictionary<String, ResourceResult> = [:] + .readWriteLock
        resources.forEach { (type, name, options) in
            let key = type.rawValue + name.rawValue
            // 存在相同的resource，此resource已经被处理了
            if let resouce = deleteResources.removeValue(forKey: key) {
                hadResources[key] = resouce
            } else {
                // 没有相同的resource，那么新建resource，等待处理
                if name == .cover, !(userGeneralSettings?.messagePreProcessConfig.enableCoverPreprocess ?? false) { return }
                let resource = ResourceResult(userResolver: userResolver,
                                              scene: scene,
                                              cache: cache,
                                              resource: type,
                                              name: key,
                                              options: options,
                                              nameSuffix: name)
                newResources[key] = resource
            }
        }
        logger.info("delete_count: \(deleteResources.keys), new_count: \(newResources.keys) had_count: \(hadResources.keys)")
        // 取消处理和取消预上传
        deleteResources.forEach { (_, resource) in
            self.assetCancelQueue.addOperations(resource.cancel(), waitUntilFinished: false)
        }
        // 开始处理
        newResources.forEach { (_, resource) in
            assetProcessQueue.addOperations(resource.start(), waitUntilFinished: false)
        }
        resourcesDic = newResources.merging(hadResources) { (_, new) in new }
        ResourceTracker.onChangeResource(resources)
    }

    public func onSendStart() {
        // 还没有开始执行的任务，取消执行
        logger.info("cancel all operations")
        assetProcessQueue.cancelAllOperations()
    }

    public func onSendFinish(preprocessCount: Int) {
        logger.info("sendFinish. count: \(preprocessCount) \(resourcesDic)")
        // 清空 resourceDic
        resourcesDic.forEach { (_, resource) in
            // 没有 get 过的，执行 cancel
            self.assetCancelQueue.addOperations(resource.addCancelIfNeeded(), waitUntilFinished: false)
        }
        resourcesDic.removeAll()
        // 发送埋点
        ResourceTracker.onSendFinish(num: preprocessCount)
    }

    public func getSwiftKey(type: ResourceType, name: NameSuffix = .none) -> String? {
        let specialKey = type.rawValue + name.rawValue
        if let res = resourcesDic[specialKey] {
            return res.getKey()
        }
        return nil
    }

    public func getImageResult(type: ResourceType, name: NameSuffix = .none) -> ImageSourceResult? {
        let specialKey = type.rawValue + name.rawValue
        if let resource = resourcesDic[specialKey] {
           return resource.getImageProcessResult()
        }
        return nil
    }

    /// 从 PHAsset 获取缓存 key，目前就图片在使用，文件不需要，视频在VideoMessageSend
    public static func getDefaultKeyFrom(phAsset: PHAsset) -> String {
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
            return key
        } else {
            let key = phAsset.localIdentifier.md5()
            return key
        }
    }
}

// 资源管理器埋点
class ResourceTracker {
    // 第一个资源时间
    static private var firstResourceTime: TimeInterval = 0
    // 最后一个资源时间
    static private var lastResourceTime: TimeInterval = 0
    // TimeInterval：资源从取消到再次勾选的时长
    static private var repeatCostArray: [TimeInterval] = []
    // 一共处理过的 resource
    // String: resource的key
    // (Bool, TimeInterval?): 资源勾选时，Bool设置为true, TimeInterval?设置为nil；资源取消勾选时，Bool设置为false，TimeInterval?设置为当前时间
    static private var resourceProcessedDic: [String: (Bool, TimeInterval?)] = [:]

    static func onChangeResource(_ resources: [(ResourcePreProcessManager.ResourceType, ResourcePreProcessManager.NameSuffix, ResourcePreProcessManager.Options)]) {
        // 记录第一个开始时间
        // 记录最后一个开始时间
        if Self.firstResourceTime == 0 {
            Self.firstResourceTime = CACurrentMediaTime()
        }
        Self.lastResourceTime = CACurrentMediaTime()

        var selectDic: [String: (Bool, TimeInterval?)] = [:]
        resources.forEach { (type, name, _) in
            let key = type.rawValue + name.rawValue
            if let value = Self.resourceProcessedDic.removeValue(forKey: key), let lastTime = value.1 {
                // 记录反复勾选情况
                Self.repeatCostArray.append(CACurrentMediaTime() - lastTime)
            }
            selectDic[key] = (true, nil)
        }
        var unSelectDic: [String: (Bool, TimeInterval?)] = [:]
        Self.resourceProcessedDic.forEach { (key, value) in
            if value.0 {
                unSelectDic[key] = (false, CACurrentMediaTime())
            } else {
                unSelectDic[key] = value
            }
        }
        Self.resourceProcessedDic = selectDic.merging(unSelectDic, uniquingKeysWith: { (_, new) in new })
    }

    static func onSendFinish(num: Int) {
        // 没有勾选过图片，最后发送也没有图片，不发送埋点
        if resourceProcessedDic.isEmpty, num == 0 { return }
        let firstCost = (CACurrentMediaTime() - Self.firstResourceTime) * 1000
        let lastCost = (CACurrentMediaTime() - Self.lastResourceTime) * 1000
        let repeatSelectCost = Self.repeatCostArray.isEmpty ? 0.0 : Self.repeatCostArray.reduce(0.0, +) / Double(Self.repeatCostArray.count) * 1000
        let params: [String: Any] = ["first_select_to_send_interval": firstCost,                    // 选择第一个资源到点击发送的时间
                                     "last_select_to_send_interval": lastCost,                      // 选择最后一个资源到点击发送的时间
                                     "resource_count": num,                                         // 最终发送的资源个数
                                     "pre_process_resource_count": Self.resourceProcessedDic.count, // 实际处理的资源个数
                                     "repeat_select_cost": repeatSelectCost,                        // 用户对同一资源反复勾选的时长平均数
                                     "repeat_select_count": Self.repeatCostArray.count]             // 用户对同一资源反复勾选次数
        Tracker.post(TeaEvent("resource_select_dev", params: params))

        // 重置属性
        Self.firstResourceTime = 0
        Self.lastResourceTime = 0
        Self.repeatCostArray = []
        Self.resourceProcessedDic = [:]
    }
}

// 单个 Resource 处理
public class ResourceResult: UserResolverWrapper {
    public let userResolver: UserResolver
    private let scene: Media_V1_PreprocessResourceRequest.Scene
    var step: Step {
        didSet {
            logger.info("\(self.name) step: \(step)")
        }
    }
    let name: String
    // 是否调用过 get key 的方法。如果没有调用过，就删除，则执行取消操作
    private var hasGetKey: Bool = false
    private let resource: ResourcePreProcessManager.ResourceType
    private let options: ResourcePreProcessManager.Options
    private let nameSuffix: ResourcePreProcessManager.NameSuffix
    private let cache: LarkDiskCache
    private var uploadKey: String?
    private let disposeBag = DisposeBag()
    private let logger = Logger.log(ResourceResult.self, category: "ResourceResult")
    @ScopedInjectedLazy private var rustService: SDKRustService?

    public enum Step {
        case nonStart       // 未开始处理
        case processing     // 业务预处理中
        case processed      // 业务预处理完成
        case swiftProcessing// 秒传/预上传中
        case uploadFinish   // 上传完成
        case cancelUploading// 正在取消上传
        case cancelUploaded // 已经取消上传
    }

    init(userResolver: UserResolver,
         scene: Media_V1_PreprocessResourceRequest.Scene,
         cache: LarkDiskCache,
         resource: ResourcePreProcessManager.ResourceType,
         name: String,
         options: ResourcePreProcessManager.Options,
         nameSuffix: ResourcePreProcessManager.NameSuffix,
         uploadKey: String? = nil) {
        self.userResolver = userResolver
        self.scene = scene
        self.cache = cache
        self.resource = resource
        self.name = name
        self.options = options
        self.nameSuffix = nameSuffix
        self.uploadKey = uploadKey
        self.step = .nonStart
    }

    // 预处理步骤 + 秒传步骤
    func start() -> [Operation] {
        // swiftProcessing 执行依赖于 process 执行完
        swiftProcessing().addDependency(process())
        return [process(), swiftProcessing()]
    }

    // 删除服务端资源
    func cancel() -> [Operation] {
        // 能否取消正在排队上传的资源
        return [cancelSwiftProcess()]
    }

    // 是否get过秒传key，如果没有get过调用 cancel()
    func addCancelIfNeeded() -> [Operation] {
        logger.info("\(self.name) hasGetKey \(hasGetKey)")
        if hasGetKey {
            return []
        } else {
            return cancel()
        }
    }

    // 获取秒传 key
    func getKey() -> String? {
        hasGetKey = true
        return self.uploadKey
    }

    // 获取图片资源的预处理步骤结果
    func getImageProcessResult() -> ImageSourceResult? {
        guard let jsonData = cache.data(for: name) else { return nil }
        let decoder = JSONDecoder()
        let result = try? decoder.decode(ImageSourceResult.self, from: jsonData)
        self.logger.info("\(self.name) result Data count: \(result?.data?.count ?? 0)")
        // 检查数据可用性
        if let image = result?.image, image.size.width != 0, image.size.height != 0 {
            return result
        } else {
            // 如果不可用，则删除在磁盘的缓存，避免再次使用脏数据
            self.cache.remove(for: name)
            return nil
        }
    }

    func cacheCanUse() -> Bool {
        // 磁盘中存在路径，并且能取出data，data能生成image，image是正确的
        if self.cache.contains(self.name), let jsonData = cache.data(for: self.name) {
            let decoder = JSONDecoder()
            let result = try? decoder.decode(ImageSourceResult.self, from: jsonData)
            if let image = result?.image, image.size.width != 0, image.size.height != 0 {
                return true
            }
        }
        return false
    }

    // 预处理
    private func process() -> Operation {
        return BlockOperation { [weak self] in
            guard let self,
                  let proPress = self.options.first(where: { $0 != .preSwiftTransmission }),
                  case let.preprocessing(pro: prePro) = proPress else { return }
            self.step = .processing
            // 从磁盘中查找
            if self.cacheCanUse() {
                // 从磁盘中找到，结束
                self.logger.info("\(self.name) process() had cache")
                self.step = .processed
                return
            }
            // 从磁盘中没有找到，压缩图片
            var result: ImageSourceResult?
            switch self.resource {
            case .imageAsset(let asset):
                result = prePro.processImage(asset, suffix: self.nameSuffix)
            case .image(let image, _):
                result = prePro.processImage(image, suffix: self.nameSuffix)
            case .file:
                result = nil
            case .media:
                result = nil
            }
            self.logger.info("\(self.name) process() has done. result is nil: \(result == nil)")
            if let result {
                // 存入磁盘
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(result) {
                    self.logger.info("\(self.name) process() set cache")
                    self.cache.set(data, for: self.name)
                }
            }
            self.step = .processed
        }
    }

    // 秒传
    private func swiftProcessing() -> Operation {
        return BlockOperation { [weak self] in
            // 如果当前resource包含秒传步骤，执行秒传
            guard let self, self.options.contains(.preSwiftTransmission) else { return }
            // 如果当前resource被执行了cancel逻辑，则不执行秒传
            // 用户勾选A图，马上取消A图。A图片会被先添加进待处理队列，紧接着会被添加进待清理队列。如果待清理队列先执行，则待处理队列的任务尽量不执行
            if self.step == .cancelUploading || self.step == .cancelUploaded { return }

            self.step = .swiftProcessing
            var request = RustPB.Media_V1_PreprocessResourceRequest()
            switch self.resource {
            case .imageAsset(_), .image(_, _):
                request.fileType = .image
                if let result = self.getImageProcessResult(), let data = result.data {
                    request.image = data
                }
            case .media(let path):
                // 因为 media 没有预处理步骤，所以直接调用秒传接口
                request.fileType = .media
                request.filePath = path
            case .file(let path):
                // 因为 file 没有预处理步骤，所以直接调用秒传接口
                request.fileType = .file
                request.filePath = path
            }
            request.scene = self.scene
            self.logger.info("\(self.name) swift() will request. type: \(request.fileType) count: \(request.image.count) path: \(request.filePath)")
            self.rustService?.sendAsyncRequest(request).subscribe(onNext: { (resp: Media_V1_PreprocessResourceResponse) in
                self.uploadKey = resp.key
                self.step = .uploadFinish
                self.logger.info("\(self.name) swift() done \(resp.key)")
            }, onError: { error in
                self.logger.info("\(self.name) swift() error \(error)")
                self.step = .uploadFinish
            }).disposed(by: self.disposeBag)
        }
    }

    // 取消秒传
    private func cancelSwiftProcess() -> Operation {
        return BlockOperation { [weak self] in
            guard let self, let key = self.uploadKey else { return }
            self.step = .cancelUploading
            self.logger.info("\(self.name) cancelSwift(). key: \(key)")
            var request = RustPB.Media_V1_CancelPreprocessResourceRequest()
            request.key = key
            self.rustService?.sendAsyncRequest(request).subscribe(onNext: { [weak self] in
                self?.logger.info("\(self?.name) cancelSwift(). Success")
                self?.step = .cancelUploaded
            })
        }
    }
}
