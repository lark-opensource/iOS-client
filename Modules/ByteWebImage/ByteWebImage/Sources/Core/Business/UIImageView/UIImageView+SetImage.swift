//
//  UIImageView+SetImage.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/8.
//

import Foundation

private enum AssociativeKey {

    static let animation = "AssociativeKey.Animation"
}

extension ImageWrapper where Base: UIImageView {

    @discardableResult
    public func setImage(_ url: URL?,
                         alternativeURLs: [URL] = [],
                         placeholder: UIImage? = nil,
                         options: ImageRequestOptions = [],
                         callbacks: ImageRequestCallbacks = .init()) -> ImageRequest? {
        // 1. URL合法
        guard let url else {
            setInvalidURL(placeholder: placeholder, callbacks: callbacks)
            return nil
        }

        // 2. 修正参数 & 创建检测键
        var options = options
        var params = options.parse()
        if let size = params.adjustDownsampleSizeIfNeeded(base) {
            params.downsampleSize = size
            options.append(.downsampleSize(size))
        }

        let tempKey = ImageRequestKey(with: url.absoluteString, downsampleSize: params.downsampleSize, cropRect: .zero, transfromName: params.transformer?.base.appendingStringForCacheKey(), smartCrop: params.smartCorp)

        // 3. 当前图像是否为该请求图像
        if let key = base.image?.bt.requestKey, key.isSame(as: tempKey) {
            setExistImageURL(request: ImageRequest(url: url), callbacks: callbacks)
            return nil
        }

        // 4. 完成回调逻辑注入
        let completion = callbacks.completion
        let newCallbacks = ImageRequestCallbacks(decrypt: callbacks.decrypt, progress: callbacks.progress) { [weak base] result in
            base?.bt.imageRequest = nil

            switch result {
            case .success(let imageResult):
                let request = imageResult.request
                if !request.finished, request.image != nil {
                    base?.bt.setUnfinishedImage(imageResult)
                    return
                }

                base?.bt.setFinishedImage(imageResult)
                completion?(.success(imageResult))
            case .failure(let error):
                if params.setPlaceholderUntilFailure {
                    base?.image = placeholder
                }
                completion?(.failure(error))
            }
        }

        // 5. 当前请求是否为该请求
        if let currentRequest = imageRequest,
           !currentRequest.canceled,
           currentRequest.originKey.isSame(as: tempKey),
           currentRequest.params == params {
            currentRequest.callbacks = newCallbacks
            return currentRequest
        }

        // 6. 设置新图片请求
        cancelImageRequest()
        resetBeforeNewRequest(params: params, placeholder: placeholder)

        let request = ImageManager.default.requestImage(url, alternativeURLs: alternativeURLs, options: options, callbacks: newCallbacks)
        setNewImageRequest(request)
        return request
    }

    /// 时序安全地设置图片。会先取消当前请求，再设置图片
    public func setImage(_ image: UIImage?) {
        cancelImageRequest()
        base.image = image
    }
}

extension ImageWrapper where Base: UIImageView {

    @discardableResult
    public func setImage(_ url: URL?,
                         alternativeURLs: [URL] = [],
                         placeholder: UIImage? = nil,
                         options: ImageRequestOptions = [],
                         progress: ImageRequestProgress? = nil,
                         decrypt: ImageRequestDecrypt? = nil,
                         completionHandler: ImageRequestCompletion? = nil) -> ImageRequest? {
        let callbacks = ImageRequestCallbacks(decrypt: decrypt,
                                              progress: progress,
                                              completion: completionHandler)
        return self.setImage(url, alternativeURLs: alternativeURLs, placeholder: placeholder,
                             options: options, callbacks: callbacks)
    }

    @available(*, deprecated, renamed: "setImage(_:alternativeURLs:placeholder:options:progress:decrypt:completionHandler:)")
    @discardableResult
    public func setImage(with url: URL?,
                         alternativeURLs: [URL] = [],
                         placeholder: UIImage? = nil,
                         transformer: BaseTransformer? = nil,
                         downloaderIdentifier: String? = nil,
                         size: CGSize? = nil,
                         options: ImageRequestOptions = [],
                         cacheName: String? = nil,
                         timeoutInterval: TimeInterval? = nil,
                         progress: ImageRequestProgress? = nil,
                         decrypt: ImageRequestDecrypt? = nil,
                         completionHandler: ImageRequestCompletion? = nil) -> ImageRequest? {
        var options = options
        if let cacheName, !cacheName.isEmpty {
            options.append(.cache(cacheName))
        }
        if let size, size != .zero {
            options.append(.downsampleSize(size))
        }
        if let transformer {
            options.append(.transformer(ProcessableWrapper(base: transformer)))
        }
        if let downloaderIdentifier, !downloaderIdentifier.isEmpty {
            options.append(.downloader(downloaderIdentifier))
        }
        if let timeoutInterval, timeoutInterval != Constants.defaultTimeoutInterval {
            options.append(.timeout(timeoutInterval))
        }
        let callbacks = ImageRequestCallbacks(decrypt: decrypt,
                                              progress: progress,
                                              completion: completionHandler)
        return self.setImage(url, alternativeURLs: alternativeURLs, placeholder: placeholder,
                             options: options, callbacks: callbacks)
    }
}
