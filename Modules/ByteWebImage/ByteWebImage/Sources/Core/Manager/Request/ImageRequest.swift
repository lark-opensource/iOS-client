//
//  ImageRequest.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/24.
//

import Foundation
import EEAtomic

/// 图片来源类型
public enum ImageResultFrom: Int {
    case none
    /// 网络下载
    case downloading
    /// 磁盘缓存
    case diskCache
    /// 内存缓存
    case memoryCache
}

/// 图片请求结果
public struct ImageResult {
    /// 原始的图片请求
    public var request: ImageRequest
    /// 图片
    public let image: UIImage?
    /// 图片的 Data
    ///
    /// 仅当 ``ImageRequestOption/ignoreImage`` 和 ``ImageRequestOption/needCachePath`` 选项同时存在时，才会返回
    public let data: Data?
    /// 图片来源
    public let from: ImageResultFrom
    /// 缓存路径
    ///
    /// 仅当 ``ImageRequestOption/needCachePath`` 选项存在时，才会返回
    public let savePath: String?
    public init(request: ImageRequest,
                image: UIImage?,
                data: Data?,
                from: ImageResultFrom,
                savePath: String?) {
        self.request = request
        self.image = image
        self.data = data
        self.from = from
        self.savePath = savePath
    }
}

struct ImageResultInternal {
    public let image: UIImage?  // 图片
    public let data: Data?      // 图片的data
    public let from: ImageResultFrom // 图片来源
    public let savePath: String? // 缓存路径
    public func toImageResult(with request: ImageRequest) -> ImageResult {
        return ImageResult(request: request,
                           image: self.image,
                           data: self.data,
                           from: self.from,
                           savePath: self.savePath)
    }
}

/// 图片请求，封装了缓存查询、网络下载、解码等多个步骤
public class ImageRequest {

    /// 唯一标识
    public let uuid: String = UUID().uuidString

    // 分类标识，可以根据分类标识对请求分组
    public let category: String?

    /// 请求参数
    internal var params: ImageRequestParams = [] {
        didSet {
            let size = params.downsampleSize
            guard !size.equalTo(.zero), !size.equalTo(ImageManager.default.defaultDownsampleSize) else { return }
            self.originKey.setDownsampleSize(params.downsampleSize)
        }
    }

    /// 回调列表
    public internal(set) var callbacks: ImageRequestCallbacks = .init()

    public internal(set) var alternativeURLs: [URL] = [] {
        // 备选URLs，下载失败后会自动重试其中的URL
        didSet {
            if !alternativeURLs.contains(self.currentRequestURL) {
                alternativeURLs.append(self.currentRequestURL)
            }
        }
    }

    private var cacheName: String? // 对应的缓存实例的名字，manager会根据cacheName分组缓存，使用前确保向BDWebImageManager注册对应缓存实例
    public var isPrefetchRequest: Bool = false // 标记是否是预加载，预加载请求如果查询到缓存则不会继续处理，如果取消某个正常请求，和他标识相同的预加载也将被取消

    public var smartCropRect: CGRect = .zero
    public var maxRetryCount: UInt = 3 // 最大重试次数3
    public var extralInfo: [String: Any]? // request附加业务信息，会透传到Downloader层
    public var downloadDiretory: String? // 指定下载后所存的目录

    public var modifier: ImageRequestModifier?
    /// 最小进度变化通知，避免频繁回调影响性能。取值范围：0~1
    public var minProgressNotificationInterval: TimeInterval = 0.05
    public var transformer: (any BaseTransformer)? {
        didSet {
            if let trans = self.transformer, !trans.appendingStringForCacheKey().isEmpty {
                self.originKey.setTransfromName(trans.appendingStringForCacheKey())
            }
        }
    }
    // 当前是使用 [BDWebImageManager requestKeyWithURL:] 赋值的，在保留缓存和获取缓存时会拼接上transformKey
    public var requestKey: String {
        set {
            self.originKey.setRequestKey(newValue)
        }
        get {
            return self.originKey.requestKey()
        }
    }

    public private(set) var currentRequestURL: URL // 当前请求的URL
    public private(set) var currentIndex: UInt = 0
    public private(set) var originKey: ImageRequestKey
    public internal(set) var sourceFileInfo: FileInfo? {
        didSet {
            self.performanceRecorder.sourceFileInfo = sourceFileInfo
        }
    }

    // results
    private(set) var image: UIImage? // 返回图，如果支持BDImage默认为BDImage，如果支持BDImage则已经decode
    private(set) var data: Data? // 原始data
//    public private(set) var error: ByteWebImageError? // 请求错误，可能为网络错误，解码错误和内部逻辑错误
    public private(set) var cachePath: String? // 最终缓存路径，未设置BDImageRequestNeedCachePath默认为空
    public private(set) var progress: Double = 0.0 // 当前进度0~1
    public private(set) var receivedSize: Int = 0 // 当前收到的Byte数
    public private(set) var expectedSize: Int = 0 // 预期接收到的Byte数
    public private(set) var finished = false
    public private(set) var canceled = false
    public private(set) var needUpdateProgress = false
    // recoder
    @AtomicObject
    var performanceRecorder: PerformanceRecorder
    // Costs
    /// 查缓存耗时
    public var cacheSeekCost: TimeInterval { performanceRecorder.cacheSeekCost }
    /// 下载排队耗时
    public var queueCost: TimeInterval { performanceRecorder.queueCost }
    /// 下载耗时
    public var downloadCost: TimeInterval { performanceRecorder.downloadCost }
    /// 解密耗时
    public var decryptCost: TimeInterval { performanceRecorder.decryptCost }
    /// 解码耗时
    public var decodeCost: TimeInterval { performanceRecorder.decodeCost }
    /// 存缓存耗时
    public var cacheCost: TimeInterval { performanceRecorder.cacheCost }
    public var rustCost: [String: UInt64]? { performanceRecorder.rustCost?.safeCopy() }

    var contextID: String? { performanceRecorder.contexID }

    private var retridCount = 0
    private var lastNotifiedProgress: Double = 0

    public required init(url: URL, alternativeURLs: [URL] = [], category: String? = nil) {
        self.currentRequestURL = url
        if !alternativeURLs.isEmpty && !alternativeURLs.contains(url) {
            var newURLs = [URL]()
            newURLs.append(url)
            self.alternativeURLs = newURLs
        } else {
            self.alternativeURLs = alternativeURLs
        }
        // 从备选数组取第一个作为当前的URL
        if let currentUrl = self.alternativeURLs.first {
            self.currentRequestURL = currentUrl
        }
        self.originKey = ImageRequestKey(with: self.currentRequestURL.absoluteString)
        self.category = category
        self.performanceRecorder = PerformanceRecorder(with: uuid, imageKey: url.absoluteString)
        self.performanceRecorder.category = category
        self.performanceRecorder.startTime = CACurrentMediaTime()
    }

    // MARK: - Public

    public func isFinished() -> Bool {
        return self.finished
    }

    public func isFailed() -> Bool {
        return self.finished && self.image == nil
    }

    public func cancel() {
        self.retridCount = 0
        if let first = self.alternativeURLs.first {
            self.currentRequestURL = first
        }
        self.completionCallback = nil
        self.progressCallback = nil
        // MARK: TODO
        ImageManager.default.cancelRequest(self)
        self.image = nil
        self.data = nil
        let error = ImageError(ByteWebImageErrorUserCancelled, userInfo: [NSLocalizedDescriptionKey: "image request cancelled"])
        self.callback(with: Result.failure(error))
        self.canceled = true
        self.performanceRecorder.endTime = CACurrentMediaTime()
        self.performanceRecorder.error = error
        PerformanceMonitor.shared.receiveRecord(self.performanceRecorder)
    }

    public func retry() {
        DispatchQueue.main.async {
            ImageManager.default.requestImage(self)
        }
    }

    public func receiveprogressData(currentData: Data, taskQueue: DispatchQueue) {
        // 这里调用比较频繁，在多图片情况下，会有内存爆炸问题「SD也存在类似的情况」因此可以考虑使用时间换空间的做法
        if self.params.animatedImageProgressiveDownload && !currentData.bt.isAnimatedImageData {
            return
        }
        if self.needUpdateProgress {
            if self.params.progressiveDownload || self.params.animatedImageProgressiveDownload {
                self.needUpdateProgress = false
                guard (try? ImageDecoderFactory.decoder(for: currentData.bt.imageFileFormat)) != nil else { return }
                // Manager持有queue和间接持有request，在执行block的时候可能request已经被释放？
                taskQueue.async { [weak self] in
                    guard let `self` = self else { return }
                    if let image = self.image as? ByteImage, image.imageFileFormat == .webp {
                        image.changeImage(with: currentData)
                    } else {
                        let decodeForDisplay = !self.params.notDecodeForDisplay
                        // 动图不支持降采样
                        do {
                            self.image = try ByteImage(currentData,
                                                       scale: ImageCompat.scaleFactor(self.currentRequestURL.absoluteString),
                                                       decodeForDisplay: decodeForDisplay,
                                                       downsampleSize: .zero,
                                                       cropRect: .zero,
                                                       enableAnimatedDownsample: self.params.enableAnimatedDownsample)
                        } catch {
                            DispatchQueue.main.async { [weak self] in
                                guard let `self` = self else { return }
                                if !self.canceled {
                                    if let error = error as? ByteWebImageError {
                                        self.completionCallback?(Result.failure(error))
                                    }
                                }
                            }
                        }
                    }
                    var realImage: UIImage?
                    if let image = self.image {
                        realImage = self.transformer?.transformImageBeforeStore(with: image)
                    } else {
                        realImage = self.image
                    }
                    realImage?.bt.requestKey = self.originKey
                    realImage?.bt.webURL = self.currentRequestURL
                    realImage?.bt.loading = true // 渐进加载
                    if let realImage = realImage {
                        DispatchQueue.main.async { [weak self] in
                            guard let `self` = self else { return }
                            if !self.canceled {
                                let result = ImageResult(request: self, image: realImage, data: currentData, from: .downloading, savePath: nil)
                                self.completionCallback?(Result.success(result))
                            }
                        }
                    }
                }
            }
        }
    }

    public func set(received rSize: Int, expectedSize eSize: Int) {
        self.receivedSize = rSize
        self.expectedSize = eSize
        self.setProgress(Double(rSize) / Double(eSize))
    }

    // MARK: - Private

    private func setProgress(_ progress: Double, with from: ImageResultFrom = .downloading) {
        self.progress = progress
        if from == .downloading {
            if self.progress >= 1.0 && self.receivedSize == 0 {
                self.receivedSize = self.data?.count ?? 100
                self.expectedSize = self.data?.count ?? 100
            }
            self.performanceRecorder.expectedSize = Int64(self.expectedSize)
            self.performanceRecorder.receiveSize = Int64(self.receivedSize)
            self.lastNotifiedProgress = progress
            self.needUpdateProgress = false
            if pthread_main_np() != 0 {
                self.progressCallback?(self, self.receivedSize, self.expectedSize)
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self, !self.canceled else { return }
                    self.progressCallback?(self, self.receivedSize, self.expectedSize)
                }
            }
        }
    }
}

extension ImageRequest {

    func finish(_ result: Result<ImageResultInternal, ImageError>) {
        if self.canceled { return }
        self.performanceRecorder.endTime = CACurrentMediaTime()
        switch result {
        case .success(let imageResult):
            self.performanceRecorder.originSize = imageResult.image?.bt.pixelSize ?? .zero
            self.performanceRecorder.loadSize = imageResult.image?.bt.destPixelSize ?? .zero
            self.performanceRecorder.imageType = imageResult.image?.bt.imageFileFormat ?? .unknown
            self.image = imageResult.image
            self.data = imageResult.data
            self.setProgress(1.0, with: imageResult.from)
            self.cachePath = imageResult.savePath
            self.callback(with: Result.success(imageResult.toImageResult(with: self)))
            PerformanceMonitor.shared.receiveRecord(self.performanceRecorder)
        case .failure(let error):
            self.performanceRecorder.error = error
            self.failed(with: error)
        }
    }

    private func callback(with result: ImageRequestResult) {
        self.finished = true
        guard !self.canceled else { return }
        if pthread_main_np() != 0 {
            // 在主线程
            self.completionCallback?(result)
        } else {
            DispatchQueue.main.async { // 不 weak self，否则会被直接释放
                guard !self.canceled else { return } // 主线程再判断是否取消，避免子线程判断后 async 到主线程之后再回调期间被取消
                self.completionCallback?(result)
            }
        }
    }

    private func failed(with error: ByteWebImageError?) {
        if self.canRetry(error) {
            if !self.alternativeURLs.isEmpty && self.currentIndex < alternativeURLs.count - 1 {
                self.currentIndex += 1
                self.currentRequestURL = self.alternativeURLs[Int(self.currentIndex)]
                self.retry()
                return
            }
            // retry http by https
            if self.currentRequestURL.scheme == "http",
               let resourceSpecifier = (self.currentRequestURL as NSURL).resourceSpecifier,
               let httpsURL = URL(string: "https://" + resourceSpecifier) {
                self.currentRequestURL = httpsURL
                retridCount += 1
                self.retry()
            }
            if error?.code ?? 0 == ByteWebImageErrorTimeOut {
                self.retridCount += 1
                self.retry()
                return
            }
        }
        let error = error ?? ImageError(ByteWebImageErrorUnkown, userInfo: [
            NSLocalizedDescriptionKey: "retry num over max"
        ])
        self.performanceRecorder.endTime = CACurrentMediaTime()
        self.performanceRecorder.retryCount = self.retridCount
        PerformanceMonitor.shared.receiveRecord(self.performanceRecorder)
        self.callback(with: Result.failure(error))
    }

    private func canRetry(_ error: ImageError? = nil) -> Bool {
        if self.params.disableAutoRetryOnFailure { return false }

        guard let error else {
            return true
        }

        if ImageRequest.defaultRetryErrorCodes.contains(error.code) {
            return true
        } else if error.code == NSURLErrorNetworkConnectionLost ||
            error.code == NSURLErrorNotConnectedToInternet ||
            self.canceled || self.retridCount >= self.maxRetryCount ||
            self.currentIndex >= self.alternativeURLs.count - 1 {
            return false
        } else {
            return true
        }
    }
}

// MARK: - Params
extension ImageRequest {

    public internal(set) var decryptCallback: ImageRequestDecrypt? {
        get { callbacks.decrypt }
        set { callbacks.decrypt = newValue }
    }

    public internal(set) var progressCallback: ImageRequestProgress? {
        get { callbacks.progress }
        set { callbacks.progress = newValue }
    }

    public internal(set) var completionCallback: ImageRequestCompletion? {
        get { callbacks.completion }
        set { callbacks.completion = newValue }
    }

    public internal(set) var timeoutInterval: TimeInterval {
        get { params.timeoutInterval }
        set { params.timeoutInterval = newValue }
    }
}

// MARK: - Tools
extension ImageRequest {

    func syncConfigurationToPerformanceRecorder() {
        performanceRecorder.requestParams = params
        performanceRecorder.requestSize = params.downsampleSize
    }
}

extension ImageRequest: Hashable {

    public static func == (lhs: ImageRequest, rhs: ImageRequest) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(Unmanaged.passUnretained(self).toOpaque())
    }
}

// MARK: - Static
extension ImageRequest {

    private static var defaultRetryErrorCodes: [ByteWebImageErrorCode] = [
        ByteWebImageErrorCheckTypeError,
        ByteWebImageErrorCheckLength,
        ByteWebImageErrorZeroByte
    ]
}

enum ImageCompat {

    static func scaleFactor(_ key: String? = nil) -> CGFloat {
        guard let key = (key as? NSString)?.deletingPathExtension,
              let scaleValue = [3, 2, 1].first(where: {
                  key.contains("@\($0)")
              }) else {
            return UIScreen.main.scale
        }
        return CGFloat(scaleValue)
    }
}
