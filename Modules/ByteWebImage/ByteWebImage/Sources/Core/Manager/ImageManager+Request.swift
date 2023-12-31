//
//  ImageManager+Request.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/10/20.
//

import Foundation
import ThreadSafeDataStructure

// MARK: - Create Request
extension ImageManager {

    /// 请求图像
    /// - Parameters:
    ///   - url: 图像地址
    ///   - alternativeURLs: 备用地址列表
    ///   - category: 分类标识
    ///   - options: 配置项
    ///   - decrypt: 解码回调
    ///   - progress: 进展回调
    ///   - completion: 完成回调
    /// - Returns: 图像请求
    @discardableResult
    public func requestImage(_ url: URL,
                             alternativeURLs: [URL] = [],
                             category: String? = nil,
                             options: ImageRequestOptions = [],
                             decrypt: ImageRequestDecrypt? = nil,
                             progress: ImageRequestProgress? = nil,
                             completion: ImageRequestCompletion? = nil) -> ImageRequest {
        let callbacks = ImageRequestCallbacks(decrypt: decrypt, progress: progress, completion: completion)
        return requestImage(url, alternativeURLs: alternativeURLs, category: category, options: options, callbacks: callbacks)
    }

    /// 请求图像
    /// - Parameters:
    ///   - url: 图像地址
    ///   - alternativeURLs: 备用地址列表
    ///   - category: 分类标识
    ///   - options: 配置项
    ///   - callbacks: 回调列表
    /// - Returns: 图像请求
    @discardableResult
    public func requestImage(_ url: URL,
                             alternativeURLs: [URL] = [],
                             category: String? = nil,
                             options: ImageRequestOptions = [],
                             callbacks: ImageRequestCallbacks = .init()) -> ImageRequest {
        var options = options
        if callbacks.decrypt != nil {
            options.append(.notVerifyData)
        }

        let request = ImageRequest(url: url, alternativeURLs: alternativeURLs, category: category)
        request.params = options.parse()
        request.callbacks = callbacks

        // 修正降采样大小
        if request.params.notDownsample && !enableAllImageDownsample {
            request.params.downsampleSize = .notDownsample
        }

        requestImage(request)
        return request
    }

    /// 预请求图像
    /// - Parameters:
    ///   - url: 图像地址
    ///   - category: 分类标识
    ///   - options: 配置项
    /// - Returns: 图像预请求
    public func prefetchImage(_ url: URL,
                              category: String? = nil,
                              options: ImageRequestOptions = []) -> ImageRequest {
        var options = options
        if isPrefetchLowPriority {
            options.append(.priority(.low), .notCache(.memory))
        }

        let request = ImageRequest(url: url, category: category)
        request.params = options.parse()
        request.isPrefetchRequest = true
        request.minProgressNotificationInterval = 1

        requestImage(request)
        return request
    }

    /// 预请求图像(批量)
    /// - Parameters:
    ///   - urls: 图像地址列表
    ///   - category: 分类标识
    ///   - options: 配置项
    /// - Returns: 图像预请求列表
    public func prefetchImages(_ urls: [URL],
                               category: String? = nil,
                               options: ImageRequestOptions = []) -> [ImageRequest] {
        urls.compactMap { url in
            prefetchImage(url, category: category, options: options)
        }
    }
}

// MARK: - Cancel Request
extension ImageManager {

    public func cancelRequest(_ request: ImageRequest) {
        let key = request.requestKey
        guard let requests = requestMap[key], !requests.isEmpty else {
            return
        }

        // 判断是否需要取消下载
        // 如果存在另一个非预加载请求，则不取消下载操作
        if !requests.contains(where: { $0 !== request && !$0.isPrefetchRequest }) {
            try? downloader(request.currentRequestURL, identifier: request.params.downloaderIdentifier).taskFromCache(with: key)?.cancel()
        }

        // 移除该请求
        let list = requests.filter { $0 !== request }
        requestMap[key] = list.isEmpty ? nil : list
    }

    /// 取消所有预加载请求
    public func cancelAllPrefetchRequests() {
        allPrefetchRequests().forEach {
            $0.cancel()
        }
    }

    public func cancelAllRequests() {
        requestMap.forEach { _, requestList in
            requestList.forEach { $0.cancel() }
        }
    }

    /// 获取所有预加载请求
    public func allPrefetchRequests() -> [ImageRequest] {
        requestMap.values.flatMap {
            // SafeArray filter(_:) 会返回 SafeArray 类型，因此使用 compactMap(_:) 替代
            $0.compactMap { $0.isPrefetchRequest ? $0 : nil }
        }
    }
}

// MARK: - Process Request
extension ImageManager {

    /// 请求图像
    /// - Parameter request: 图像请求
    internal func requestImage(_ request: ImageRequest) {
        // 根据全局配置，调整请求参数
        if !self.forceDecode {
            request.params.update(.notDecodeForDisplay)
        }
        if !self.enableMemoryCache {
            request.params.update(.notCache(.memory))
        }

        // 性能记录同步配置属性
        request.syncConfigurationToPerformanceRecorder()

        // 检测请求URL是否合法
        if request.currentRequestURL.absoluteString.isEmpty {
            let error = ImageError(.badImageURL, description: "Bad image url")
            request.finish(.failure(error))
            return
        }

        Log.trace("Start request \(request.requestKey) with params \(request.params)")
        sendRequestDidStartNotification(request)

        if request.params.ignoreCache == .all {
            requestImageWithNoCached(request)
            return
        }

        if request.isPrefetchRequest {
            request.performanceRecorder.cacheSeekBegin = CACurrentMediaTime()
            self.preQueryCache(request) { [weak self] type in
                guard let self else { return }
                request.performanceRecorder.cacheSeekEnd = CACurrentMediaTime()
                request.performanceRecorder.cacheType = type

                guard type != .none else {
                    self.requestImageWithNoCached(request)
                    return
                }

                Log.trace("Found \(type) cache for pre-request \(request.requestKey)")
                let from: ImageResultFrom = (type == .memory) ? .memoryCache : .diskCache
                self.sendRequestDidFinishNotification(request, image: nil, from: from)
                let result = ImageResultInternal(image: nil, data: nil, from: from, savePath: nil)
                request.finish(.success(result))
            }
            return
        }

        request.performanceRecorder.cacheSeekBegin = CACurrentMediaTime()
        self.queryCache(request) { [weak self] (image, path, type) in
            guard let self else { return }
            request.performanceRecorder.cacheSeekEnd = CACurrentMediaTime()
            request.performanceRecorder.cacheType = type

            guard type != .none else {
                self.requestImageWithNoCached(request)
                return
            }

            image?.bt.requestKey = request.originKey
            image?.bt.webURL = request.currentRequestURL
            if request.params.preloadAllFrames,
               !request.params.onlyLoadFirstFrame,
               let image = image as? ByteImage {
                image.preLoadAllFrames()
            }
            var data: Data?
            if request.params.ignoreImage, let cachePath = path {
                let url = URL(fileURLWithPath: cachePath)
                do {
                    data = try Data(contentsOf: url)
                } catch {
                    Log.trace("Found \(type) cache for request \(request.requestKey)")
                    let error = error as NSError
                    let imageError = ImageError(error.code,
                                                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription,
                                                           ImageError.UserInfoKey.cacheType: type.description
                                                          ])
                    request.finish(.failure(imageError))
                }
            }

            Log.trace("Found \(type) cache for request \(request.requestKey)")
            let from: ImageResultFrom = (type == .memory) ? .memoryCache : .diskCache
            self.sendRequestDidFinishNotification(request, image: image, from: from)
            let result = ImageResultInternal(image: image, data: data, from: from, savePath: path)
            request.finish(.success(result))
        }
    }

    /// 请求图像(无缓存)
    /// - Parameter request: 图像请求
    private func requestImageWithNoCached(_ request: ImageRequest) {
        Log.trace("Start request \(request.requestKey) with no cache")

        if request.params.onlyQueryCache {
            let error = ImageError(.requestFailed, description: "No cached image")
            request.finish(.failure(error))
            return
        }
        downloadImage(request)
    }

    private func downloadImage(_ request: ImageRequest) {
        if request.canceled { return }

        Log.trace("Start download request \(request.requestKey)")
        let tempRequests = requestMap[request.requestKey] ?? ([] + .readWriteLock)
        if !tempRequests.contains(request) {
            tempRequests.append(request)
        }
        requestMap[request.requestKey] = tempRequests
        let downloader = try? downloader(request.currentRequestURL, identifier: request.params.downloaderIdentifier)
        downloader?.download(with: request)
    }
}

// MARK: - Notification
extension ImageRequest {

    public static let requestDidStartNotification = NSNotification.Name("ImageRequestDidStartNotification")

    public static let requestDidFinishNotification = NSNotification.Name("ImageRequestDidFinishNotification")
}

extension ImageManager {

    /// 发送请求开始执行通知
    func sendRequestDidStartNotification(_ request: ImageRequest) {
        guard enableImageLoadNotification else { return }

        NotificationCenter.default.post(name: ImageRequest.requestDidStartNotification, object: nil, userInfo: ["requestImageObj": request.uuid])
    }

    /// 发送请求结束执行通知
    func sendRequestDidFinishNotification(_ request: ImageRequest, image: UIImage?, from: ImageResultFrom) {
        guard enableImageLoadNotification else { return }

        var imageInfo = [String: Any]()
        imageInfo["from"] = from
        imageInfo["requestImageObj"] = request.uuid
        imageInfo["imageUrl"] = request.currentRequestURL
        imageInfo["imageMemorySize"] = image?.bt.cost ?? 0
        NotificationCenter.default.post(name: ImageRequest.requestDidFinishNotification, object: nil, userInfo: imageInfo)
    }
}
