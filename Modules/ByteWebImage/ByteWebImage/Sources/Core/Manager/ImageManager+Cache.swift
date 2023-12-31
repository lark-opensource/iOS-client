//
//  ImageManager+Cache.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/9/13.
//

import Foundation

// MARK: - Register Cache
extension ImageManager {

    /// 注册新缓存
    public func registerCache(_ cache: ImageCache, forKey key: String) {
        cacheMap[key] = cache
    }
}

// MARK: - Cache
extension ImageManager {

    /// 查找缓存实例(标识符)
    /// 查找失败返回默认缓存实例
    /// - Parameter identifier: 标识符
    /// - Returns: 缓存实例
    func cache(_ identifier: String? = nil) -> ImageCache {
        guard let identifier else {
            return defaultCache
        }
        return cacheMap[identifier] ?? defaultCache
    }

    /// 查找缓存实例(请求)
    /// 查找失败返回默认缓存实例
    /// - Parameter request: 请求
    /// - Returns: 缓存实例
    func cache(_ request: ImageRequest) -> ImageCache {
        cache(request.params.cacheIdentifier)
    }
}

// MARK: - Request
extension ImageManager {

    /// 缓存查询(预加载)
    /// - Parameters:
    ///   - request: 请求(预加载)
    ///   - completion: 回调
    func preQueryCache(_ request: ImageRequest, completion: @escaping (ImageCacheOptions) -> Void) {
        let cacheKey = request.originKey.targetKey
        DispatchImageQueue.async {
            let options = self.cache(request).contains(cacheKey, options: .all)
            completion(options)
        }
    }

    /// 缓存查询
    func queryCache(_ request: ImageRequest, completion: @escaping (UIImage?, String?, ImageCacheOptions) -> Void) {
        let requestOptions = request.params
        let cacheOptions = requestOptions.ignoreCache.opposite
        let needImage = !requestOptions.ignoreImage
        let needPath = requestOptions.needCachePath
        if needImage {
            queryImage(request, options: cacheOptions, fuzzy: fuzzyCache) { image, options in
                if needPath {
                    DispatchImageQueue.async {
                        let cachePath = self.imageDiskPath(request)
                        completion(image, cachePath, options)
                    }
                } else {
                    completion(image, nil, options)
                }
            }
        } else if needPath {
            DispatchImageQueue.async {
                guard let cachePath = self.imageDiskPath(request, checkExist: true) else {
                    completion(nil, nil, .none)
                    return
                }
                completion(nil, cachePath, .disk)
            }
        } else {
            completion(nil, nil, .none)
        }
    }

    /// 查询非预取请求缓存
    func queryCache(for request: ImageRequest, callback: @escaping (UIImage?, String?, ImageCacheOptions) -> Void) {
        queryCache(request, completion: callback)
    }

    private func queryImage(_ request: ImageRequest, options: ImageCacheOptions, fuzzy: Bool, completion: @escaping (UIImage?, ImageCacheOptions) -> Void) {
        let cache = cache(request)
        let key = request.originKey.targetCacheKey()

        let memoryCompletion: (ImageCache.CacheImage?, ImageCacheOptions) -> Void = { image, imageOptions in
            if case .normal(let img) = image {
                completion(img, imageOptions)
                return
            }
            if options.contains(.disk) {
                DispatchImageQueue.async {
                    if request.canceled || request.isFinished() {
                        return
                    }
                    let start = CACurrentMediaTime()
                    let (cacheImage, cacheOptions) = cache.image(forKey: key, options: .disk, fuzzy: (fuzzy && image == nil), requestOptions: request.params, size: request.params.downsampleSize)
                    let end = CACurrentMediaTime()

                    if let cacheImage {
                        let result = self.processCacheImage(cacheImage, cacheOptions, request, key, start, end)
                        completion(result.0, result.1)
                    } else {
                        let result = self.processCacheImage(image, imageOptions, request, key)
                        completion(result.0, result.1)
                    }
                }
                return
            }
            let result = self.processCacheImage(image, imageOptions, request, key)
            completion(result.0, result.1)
        }

        if options.contains(.memory) {
            let (cacheImage, cacheOptions) = cache.image(forKey: key, options: .memory, fuzzy: fuzzy, requestOptions: request.params, size: request.params.downsampleSize)
            memoryCompletion(cacheImage, cacheOptions)
        } else {
            memoryCompletion(nil, .none)
        }
    }

    private func processCacheImage(_ cacheImage: ImageCache.CacheImage?, _ cacheOptions: ImageCacheOptions, _ request: ImageRequest, _ key: String, _ start: CFTimeInterval = 0, _ end: CFTimeInterval = 0) -> (UIImage?, ImageCacheOptions) {
        switch (cacheImage, cacheOptions) {
        case (_, .none):
            return (nil, .none)
        case (.normal(let img), .memory):
            return (img, .memory)
        case (let .crude(img, type), .memory):
            let newImg = processImage(img, request: request, type: type)
            return (newImg, .memory)
        case (.normal(let img), .disk):
            request.performanceRecorder.decodeBegin = start
            request.performanceRecorder.decodeEnd = end
            reportDecodeInfo(request, image: img, cost: end - start)
            cacheImageToMemory(img, forKey: key, request: request, needCache: !request.params.notCache.contains(.memory))
            return (img, .disk)
        case (let .crude(img, type), .disk):
            request.performanceRecorder.decodeBegin = start
            request.performanceRecorder.decodeEnd = end
            reportDecodeInfo(request, image: img, cost: end - start)
            let newImg = processImage(img, request: request, type: type)
            cacheImageToMemory(newImg, forKey: key, request: request, needCache: !request.params.notCache.contains(.memory))
            return (newImg, .disk)
        default:
            return (nil, .none)
        }
    }

    // MARK: Utils

    private func processImage(_ image: UIImage, request: ImageRequest, type: ImageCache.ProcessType) -> UIImage {
        var result = image
        if type.contains(.transform), let transformer = request.transformer {
            if let transformImage = transformer.transformImageBeforeStore(with: result) {
                result = transformImage
            }
        }
        if type.contains(.crop) {
            let crop = request.originKey.cropRect
            if let cropImage = result.bt.crop(to: crop) {
                result = cropImage
            }
        }
        return result
    }

    private func cacheImageToMemory(_ image: UIImage, forKey key: String, request: ImageRequest, needCache: Bool) {
        guard needCache else { return }
        request.performanceRecorder.cacheBegin = CACurrentMediaTime()
        let cache = cache(request)
        cache.set(image, forKey: key, options: .memory)
        request.performanceRecorder.cacheEnd = CACurrentMediaTime()
    }

    /// 获取图片磁盘缓存路径
    /// - Parameters:
    ///   - request: 图片请求
    ///   - checkExist: 检查文件是否存在
    /// - Returns: 磁盘缓存路径
    func imageDiskPath(_ request: ImageRequest, checkExist: Bool = false) -> String? {
        let key = request.originKey.sourceCacheKey()
        let cache = cache(request)
        guard let path = cache.diskCachePath(forKey: key), !path.isEmpty else {
            return nil
        }
        if checkExist {
            let isExists = FileManager.default.fileExists(atPath: path)
            return isExists ? path : nil
        } else {
            return path
        }
    }

    private func reportDecodeInfo(_ request: ImageRequest, image: UIImage, cost: CFTimeInterval) {
        // 这里只能是解码成功，失败的的话会走下载
        var decodeInfo = ImageDecodeInfo()
        decodeInfo.resourceLength = image.bt.dataCount
        decodeInfo.resourceWidth = Int(image.bt.pixelSize.width)
        decodeInfo.resouceHeight = Int(image.bt.pixelSize.height)
        decodeInfo.loadHeigt = Int(image.bt.destPixelSize.height)
        decodeInfo.loadWidth = Int(image.bt.destPixelSize.width)
        decodeInfo.colorSpace = image.bt.colorSpaceName ?? ""
        decodeInfo.imageType = image.bt.imageFileFormat.description
        decodeInfo.success = true
        decodeInfo.framesCount = image.bt.frameCount
        decodeInfo.cost = cost
        PerformanceMonitor.shared.receiveDecodeInfo(key: request.currentRequestURL.absoluteString, decodeInfo: decodeInfo)
    }
}
