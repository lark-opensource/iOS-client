//
//  ImageManager+Download.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/10/20.
//

import Foundation

// MARK: - Register
extension ImageManager {

#if ByteWebImage_Include_Lark
    /// 注册Rust下载器
    /// - Parameter downloader: 下载器
    public func registerRustDownloader(_ downloader: any Downloader) {
        rustDownloader = downloader
    }
#endif

    /// 注册下载器
    /// 对应键已存在时，不替换，返回失败
    /// - Parameters:
    ///   - downloader: 下载器
    ///   - key: 键
    /// - Returns: 注册成功/失败
    @discardableResult
    public func registerDownloader(_ downloader: any Downloader, forKey key: String) -> Bool {
        if downloaderMap.keys.contains(key) { return false }
        downloaderMap[key] = downloader
        return true
    }
}

// MARK: - Instance
extension ImageManager {

    /// 查找下载器实例
    /// 按照以下规则查找，查找失败则抛出异常
    /// 1. Rust
    /// 2. 普通列表，返回指定标识符对应的下载器
    /// 3. 默认下载器
    /// - Parameters:
    ///   - url: 下载地址
    ///   - identifier: 标识符
    /// - Returns: 下载器实例
    func downloader(_ url: URL, identifier: String? = nil) throws -> any Downloader {
        let downloader: any Downloader
        if url.scheme == "rust" {
            guard let rustDownloader else {
                throw ImageError(ByteWebImageErrorNotSupportRust,
                                        description: "Not support Rust, retry after registration.")
            }
            downloader = rustDownloader
        } else if let identifier {
            guard let externDownloader = downloaderMap[identifier] else {
                throw ImageError(ByteWebImageErrorNotSupportCustomDownloader,
                                        description: "Not support custom downloader, retry after registration.")
            }
            downloader = externDownloader
        } else {
            downloader = defaultDownloader
        }

        downloader.delegate = self
        downloader.defaultHeaders = self.downloaderDefaultHttpHeaders
        downloader.maxConcurrentTaskCount = self.maxConcurrentTaskCount
        downloader.checkMimeType = self.checkMimeType
        downloader.checkDataLength = self.checkDataLength
        downloader.isConcurrentCallback = self.isConcurrentCallback
        return downloader
    }
}

// MARK: - DownloaderDelegate
extension ImageManager: DownloaderDelegate {

    public func downloader(_ downloader: Downloader, task: DownloadTask, finishedWith result: Result<Data, ByteWebImageError>, savePath: String?) {

        func recordTaskPerformance(_ request: ImageRequest, from task: DownloadTask) {
            request.performanceRecorder.queueBegin = task.createTime
            request.performanceRecorder.queueEnd = task.startTime
            request.performanceRecorder.downloadBegin = task.startTime
            request.performanceRecorder.downloadEnd = task.finishTime
        }

        // 获取URL对应的所有请求
        guard let requests = requestMap[task.identifier], !requests.isEmpty else {
            return
        }
        // 清理对应的请求
        requestMap[task.identifier] = nil

        switch result {
        case .success(let data):
            Log.trace("Download success with task \(task.identifier)")

            var group: [String: [ImageRequest]] = [:]

            // 根据缓存Key进行聚合
            // Todo: 可以优化的点
            // 1. 聚合降采样，可以考虑最大的
            // 2. 聚合非降采样，统一使用原图后，进行transform 或crop处理
            requests.forEach { request in
                recordTaskPerformance(request, from: task)

                let targetKey = request.originKey.targetKey
                var list = group[targetKey] ?? []
                list.append(request)
                group[targetKey] = list
            }
            // 针对每个缓存Key进行处理
            for (_, requests) in group {
                downloadDataProcessing(requests, task: task, data: data, filePath: savePath)
            }
        case .failure(let error):
            Log.trace("Download failed with task \(task.identifier)")

            requests.forEach { request in
                recordTaskPerformance(request, from: task)

                sendRequestDidFinishNotification(request, image: nil, from: .none)
                request.finish(.failure(error))
            }
        }
    }

    public func downloader(_ downloader: Downloader, task: DownloadTask, reiceivedSize rSize: Int, expectedSize eSize: Int) {
        requestMap[task.identifier]?.forEach { request in
            request.set(received: rSize, expectedSize: eSize)
        }
    }

    public func downloader(_ downloader: Downloader, task: DownloadTask, didReceived received: Data?, increment: Data?) {
        guard let data = received else { return }
        let key = task.identifier
        requestMap[key]?.forEach { request in
            // Todo: 基于现有的模型，这里可能会有不对齐的风险，后续可以考虑优化
            if request.currentRequestURL.absoluteString == task.url.absoluteString {
                request.receiveprogressData(currentData: data, taskQueue: progressTaskQueue)
            }
        }
    }
}

extension ImageManager {

    /// 下载数据处理(请求聚合)
    /// - Parameters:
    ///   - requests: 请求列表(缓存Key相同)
    ///   - task: 下载任务
    ///   - data: 图片数据
    ///   - filePath: 磁盘缓存路径(不为空认为已存入磁盘缓存)
    private func downloadDataProcessing(_ requests: [ImageRequest], task: DownloadTask, data: Data, filePath path: String?) {
        do {
            let (image, originData, filePathBlock) = try performImageProcessing(requests, task: task, data: data, filePath: path)
            lazy var filePath = filePathBlock()
            requests.forEach { request in
                sendRequestDidFinishNotification(request, image: image, from: .downloading)
                let savePath = request.params.needCachePath ? filePath : nil
                let data = request.params.ignoreImage ? originData : nil
                let result = ImageResultInternal(image: image, data: data, from: .downloading, savePath: savePath)
                request.finish(.success(result))
            }
        } catch {
            let error = ImageError.error(error, defaultCode: ByteWebImageErrorInternalError)
            Log.trace("Process download data failed \(error.code) \(error.localizedDescription)")
            requests.forEach { request in
                self.sendRequestDidFinishNotification(request, image: nil, from: .none)
                request.finish(.failure(error))
            }
            // 出现错误，清理已缓存的文件
            if let path {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
    }

    private func performImageProcessing(_ requests: [ImageRequest], task: DownloadTask, data: Data, filePath path: String?) throws -> (ByteImage?, Data, () -> String?) {
        // 1. 获取当前请求(当前请求URL与下载任务URL相同)
        guard let currentRequest = requests.first(where: {
            $0.currentRequestURL.absoluteString == task.url.absoluteString
        }) else {
            let error = ImageError(ByteWebImageErrorInternalError, description: "No available request found")
            throw error
        }

        assert(requests.allSatisfy { $0.originKey == currentRequest.originKey }, "Requests has different request url.")

        // 2. 解密数据
        var originData = data
        if let decrypt = currentRequest.decryptCallback {
            Log.trace("Start decrypt data \(currentRequest.requestKey)")

            switch decrypt(data) {
            case .success(let decryptData):
                Log.trace("Finish decrypt data \(currentRequest.requestKey)")

                originData = decryptData
            case .failure(let error):
                throw error
            }
        }

        // 3. 解码图片 & 深加工
        let (image, realImage) = try processImage(requests, currentRqst: currentRequest, cropRect: task.smartCropRect, data: originData)

        // 4. 缓存图片
        cacheImage(requests, disableCacheToDisk: disableCacheToDisk(task), image: realImage ?? image, data: originData, filePath: path)

        return (image, originData, { self.imageDiskPath(currentRequest) })
    }

    private func processImage(_ requests: [ImageRequest], currentRqst: ImageRequest, cropRect: CGRect, data originData: Data) throws -> (ByteImage?, UIImage?) {
        var needImage = false
        var needPath = false
        var decodeForDisplay = false
        var preloadAllFrames = false

        // 1. 获取处理参数
        for request in requests {
            needImage = needImage || !request.params.ignoreImage
            needPath = needPath || request.params.needCachePath
            decodeForDisplay = decodeForDisplay || !request.params.notDecodeForDisplay
            preloadAllFrames = preloadAllFrames || (request.params.preloadAllFrames && !request.params.onlyLoadFirstFrame)

            request.smartCropRect = cropRect
        }

        guard needImage else { return (nil, nil) }

        let image: ByteImage
        do {
            let targetSize = currentRqst.params.downsampleSize
            let targetRect = currentRqst.params.smartCorp ? cropRect : .zero
            let scale = ImageCompat.scaleFactor(currentRqst.currentRequestURL.absoluteString)

            // 2.1 图片解码
            Log.trace("Start decode image \(currentRqst.requestKey)")
            let beginTime = CACurrentMediaTime()
            image = try ByteImage(originData, scale: scale, decodeForDisplay: decodeForDisplay, downsampleSize: targetSize, cropRect: targetRect, enableAnimatedDownsample: currentRqst.params.enableAnimatedDownsample)
            let endTime = CACurrentMediaTime()
            Log.trace("Finish decode image \(currentRqst.requestKey)")

            // 2.1.1 记录解码信息
            requests.forEach { request in
                request.performanceRecorder.decodeBegin = beginTime
                request.performanceRecorder.decodeEnd = endTime
            }

            var decodeInfo = ImageDecodeInfo()
            decodeInfo.resourceLength = image.bt.dataCount
            decodeInfo.resourceWidth = Int(image.bt.pixelSize.width)
            decodeInfo.resouceHeight = Int(image.bt.pixelSize.height)
            decodeInfo.loadWidth = Int(image.bt.destPixelSize.width)
            decodeInfo.loadHeigt = Int(image.bt.destPixelSize.height)
            decodeInfo.colorSpace = image.bt.colorSpaceName ?? ""
            decodeInfo.imageType = image.bt.imageFileFormat.description
            decodeInfo.success = true
            decodeInfo.framesCount = image.bt.frameCount
            decodeInfo.cost = endTime - beginTime
            PerformanceMonitor.shared.receiveDecodeInfo(key: currentRqst.currentRequestURL.absoluteString, decodeInfo: decodeInfo)
        } catch {
            var error = error as? ByteWebImageError ?? ImageError(ByteWebImageErrorInternalError, description: error.localizedDescription)
            error.addDecodeFailedInfoIfNeeded(data: originData)

            var decodeInfo = ImageDecodeInfo()
            decodeInfo.resourceLength = originData.count
            decodeInfo.success = false
            PerformanceMonitor.shared.receiveDecodeInfo(key: currentRqst.currentRequestURL.absoluteString, decodeInfo: decodeInfo)
            throw error
        }

        // 2.2 预加载
        if preloadAllFrames {
            Log.trace("Preload all frames \(currentRqst.requestKey)")

            image.preLoadAllFrames()
        }

        // 2.3 转换
        var realImage: UIImage?
        if let transformer = currentRqst.transformer {
            Log.trace("Start transform \(transformer.appendingStringForCacheKey()) to image \(currentRqst.requestKey)")

            guard let transformImage = transformer.transformImageBeforeStore(with: image) else {
                let error = ImageError(ByteWebImageErrorEmptyImage,
                                              userInfo: [NSLocalizedDescriptionKey: "transform image faild"])
                throw error
            }
            Log.trace("Finish transform \(transformer.appendingStringForCacheKey()) to image \(currentRqst.requestKey)")
            transformImage.bt.requestKey = currentRqst.originKey
            transformImage.bt.webURL = currentRqst.currentRequestURL
            realImage = transformImage
        }

        return (image, realImage)
    }

    /// 禁止缓存到磁盘缓存
    /// 1. 支持CDN降级
    /// 2. 存在缓存控制时间，并小于阈值(1h)
    private func disableCacheToDisk(_ task: DownloadTask) -> Bool {
        isCDNdowngrade && task.cacheControlTime != 0 && task.cacheControlTime <= 1 * 60 * 60
    }

    /// 缓存图片
    /// - Parameters:
    ///   - requests: 请求列表(缓存Key相同)
    ///   - disableCacheToDisk: 是否禁止缓存到磁盘缓存
    ///   - image: 处理后的图片
    ///   - data: 图片数据(已解密)
    ///   - filePath: 文件路径
    private func cacheImage(_ requests: [ImageRequest], disableCacheToDisk: Bool, image: UIImage?, data: Data, filePath: String?) {
        // 1. 按照缓存器，聚合请求及缓存位置
        var cacheMap: [ImageCache: ([ImageRequest], ImageCacheOptions)] = [:]
        for request in requests {
            // 1.1 获取所有可缓存位置
            var options = request.params.notCache.opposite
            // 1.2 需要磁盘缓存路径，添加磁盘缓存
            if request.params.needCachePath {
                options = options.union(.disk)
            }
            // 1.3 未忽略CDN降级，并被禁止缓存到磁盘缓存，移除磁盘缓存
            if !request.params.ignoreCDNDowngrade && disableCacheToDisk {
                options = options.subtracting(.disk)
            }

            if options == .none { continue }

            let cache = cache(request)
            var (requestList, cacheOptions) = cacheMap[cache] ?? ([], .none)
            requestList.append(request)
            cacheOptions = cacheOptions.union(options)
            cacheMap[cache] = (requestList, cacheOptions)
        }

        // 2. 按照聚合结果，对不同缓存器进行缓存
        assert(!requests.isEmpty, "Requests should not be empty.")
        let request = requests[0]
        let targetKey = request.originKey.targetCacheKey()
        let sourceKey = request.originKey.sourceCacheKey()
        for (cache, (requestList, options)) in cacheMap {
            if options == .none { continue }

            Log.trace("Cache \(cache.identifier) to cache image at \(options)")
            let cacheBeginTime = CACurrentMediaTime()
            var cacheEndTime: CFTimeInterval = 0
            // 2.1 设置内存缓存
            if options.contains(.memory), let image {
                cache.set(image, forKey: targetKey, options: .memory)
                cacheEndTime = CACurrentMediaTime()
            }
            // 2.2 设置磁盘缓存
            if options.contains(.disk) {
                if let filePath {
                    // 如果已写入文件，直接根据该文件设置缓存
                    cache.diskCache.setExistFile(for: sourceKey, with: filePath)
                } else {
                    cache.set(nil, data: data, forKey: sourceKey, options: .disk)
                }
                cacheEndTime = CACurrentMediaTime()
            }

            // 2.3 更新缓存行为记录
            assert(cacheEndTime != 0, "Cache options should not be empty.")
            requestList.forEach { request in
                request.performanceRecorder.cacheBegin = cacheBeginTime
                request.performanceRecorder.cacheEnd = cacheEndTime
            }
        }
    }
}

// MARK: - Add Decode Failed Info
extension ByteWebImageError {
    public mutating func addDecodeFailedInfoIfNeeded(data: Data) {
        userInfo[ImageError.UserInfoKey.dataHash] = data.bt.crc32
        userInfo[ImageError.UserInfoKey.dataFormatHeader] = data.bt.formatHeader
        userInfo[ImageError.UserInfoKey.dataLength] = String(data.count)
    }
}
