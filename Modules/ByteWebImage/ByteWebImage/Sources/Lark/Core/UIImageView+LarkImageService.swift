//
//  UIImageView+LarkImageService.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/4/16.
//

import Foundation

private let kByteWebImageSetAnimationKey = "kByteWebImageSetAnimationKey"

extension ImageWrapper where Base: UIImageView {

    @discardableResult
    public func setLarkImage(_ resource: LarkImageResource,
                             placeholder: UIImage? = nil,
                             passThrough: ImagePassThrough? = nil,
                             options: ImageRequestOptions = [],
                             trackInfo: (() -> TrackInfo)? = nil,
                             modifier: RequestModifier? = nil,
                             file: String = #fileID,
                             function: String = #function,
                             line: Int = #line,
                             callbacks: ImageRequestCallbacks = .init()) -> LarkImageRequest? {
        // 1. URL合法
        guard let url = resource.generateURL() else {
            // 兼容设置 空Key+placeholder 来取消旧请求
            // 应修改使用 setInvalidURL(for: state, placeholder: placeholder, callbacks: callbacks)
            cancelImageRequest()
            base.image = placeholder
            if let placeholder {
                let result = ImageResult(request: .emptyRequest, image: placeholder, data: nil, from: .none, savePath: nil)
                callbacks.completion?(.success(result))
            } else {
                let error = ImageError(.badImageURL, description: "Invalid empty URL")
                callbacks.completion?(.failure(error))
            }
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
            setExistImageURL(request: LarkImageRequest.create(resource: resource, url: url), callbacks: callbacks)
            return nil
        }

        // 4. 完成回调逻辑注入
        let tracker = ImageTracker()
        tracker.start(with: url.absoluteString)

        let completion = callbacks.completion
        let newCallbacks = ImageRequestCallbacks(decrypt: callbacks.decrypt, progress: callbacks.progress) { [weak base] result in
            let originRequest = base?.bt.imageRequest
            // 在回调之前需要清空 imageRequest，防止嵌套调用的问题
            base?.bt.imageRequest = nil

            switch result {
            case .success(let imageResult):
                let request = imageResult.request
                if !request.finished, request.image != nil {
                    base?.bt.setUnfinishedImage(imageResult)
                    return
                }

                base?.bt.setFinishedImage(imageResult)
                tracker.sendSuccess(imageResult, trackInfo: trackInfo?(),
                                    file: file, function: function, line: line)
                completion?(.success(imageResult))
            case .failure(let error):
                if params.setPlaceholderUntilFailure {
                    base?.image = placeholder
                }
                tracker.send(.failure(error), request: originRequest, trackInfo: trackInfo?(),
                             file: file, function: function, line: line)
                completion?(.failure(error))
            }
        }

        // 5. 当前请求是否为该请求
        if let currentRequest = imageRequest as? LarkImageRequest,
           !currentRequest.canceled,
           currentRequest.originKey.isSame(as: tempKey),
           currentRequest.params == params {
            currentRequest.callbacks = newCallbacks
            return currentRequest
        }

        // 6. 设置新图片请求
        cancelImageRequest()
        resetBeforeNewRequest(params: params, placeholder: placeholder)

        let request = LarkImageService.shared.setImage(with: resource, passThrough: passThrough, options: options, modifier: modifier, file: file, function: function, line: line, progress: newCallbacks.progress, decrypt: newCallbacks.decrypt, completion: newCallbacks.completion)
        setNewImageRequest(request)
        return request
    }
}

extension ImageWrapper where Base: UIImageView {

    /// 设置图片便利方法 For Lark
    ///
    /// [ByteWebImage 图片库使用文档](https://bytedance.feishu.cn/wiki/wikcnIilihYzNjRlUMen4UCNhbh)
    /// - Note: 在回调前，会尝试将 UIImage 设置在 UIImageView 上，故不需要在回调中手动设置
    /// - Parameters:
    ///   - resource: Lark 图片资源 LarkImageResource，支持填入 Rust image key / http(s) / file / base64 / 头像 / 表情
    ///   - placeholder: 占位图
    ///   - passThrough: 透传 RustPB 的 Basic\_V1\_ImageSetPassThrough 字段，一般不用传
    ///   - options: 请求选项，一般不用传
    ///   - trackInfo: 业务方的埋点信息，**尽量传入 Biz & Scene & from\_type 字段，在 image\_load 埋点中使用，便于大盘归因**
    ///   - modifier: RequestModifier, 可以在 URLRequest 发起请求之前修改，一般不用传
    ///   - file: 调用此方法的文件信息，**禁止覆盖默认值**
    ///   - function: 调用此方法的方法信息，**禁止覆盖默认值**
    ///   - line: 调用此方法的行号信息，**禁止覆盖默认值**
    ///   - progress: 下载进度更新回调
    ///   - decrypt: 下载完成后解密回调
    ///   - completion: 图片加载完成回调，可以在此获取到最终图片
    /// - Returns: 图片请求 LarkImageRequest
    @discardableResult
    public func setLarkImage(_ resource: LarkImageResource,
                             placeholder: UIImage? = nil,
                             passThrough: ImagePassThrough? = nil,
                             options: ImageRequestOptions = [],
                             trackInfo: (() -> TrackInfo)? = nil,
                             modifier: RequestModifier? = nil,
                             file: String = #fileID,
                             function: String = #function,
                             line: Int = #line,
                             progress: ImageRequestProgress? = nil,
                             decrypt: ImageRequestDecrypt? = nil,
                             completion: ImageRequestCompletion? = nil) -> LarkImageRequest? {
        let callbacks = ImageRequestCallbacks(decrypt: decrypt, progress: progress, completion: completion)
        return setLarkImage(resource, placeholder: placeholder, passThrough: passThrough, options: options, trackInfo: trackInfo, modifier: modifier, file: file, function: function, line: line, callbacks: callbacks)
    }

    /// 设置图片便利方法 For Lark
    ///
    /// [ByteWebImage 图片库使用文档](https://bytedance.feishu.cn/wiki/wikcnIilihYzNjRlUMen4UCNhbh)
    /// - Note: 在回调前，会尝试将 UIImage 设置在 UIImageView 上，故不需要在回调中手动设置
    /// - Parameters:
    ///   - resource: Lark 图片资源 LarkImageResource，支持填入 Rust image key / http(s) / file / base64 / 头像 / 表情
    ///   - placeholder: 占位图
    ///   - passThrough: 透传 RustPB 的 Basic\_V1\_ImageSetPassThrough 字段，一般不用传
    ///   - options: 请求选项，一般不用传
    ///   - transformer: 在下载之后，存入磁盘之前或之后转换一张图片，存入内存并显示，一般不用传
    ///   - downloaderIdentifier: 显式声明需要用的下载器，默认根据协议头：无协议头默认为 Rust；其他为 URLSession，一般不用传
    ///   - size: 图片降采样大小，单位 pt（分辨率最大限制大小）（按宽高乘积来算），一般不用传
    ///   - cacheName: 如果为空，使用默认缓存策略，一般不用传
    ///   - timeoutInterval: 请求超时限制，默认 30s
    ///   - trackStart: 业务方的埋点信息，**尽量传入 Biz & Scene & from\_type 字段，在 image\_load 埋点中使用，便于大盘归因**
    ///   - trackEnd: deprecated, will remove soon, and `trackStart` will also be renamed to `trackInfo`.
    ///   - modifier: RequestModifier, 可以在 URLRequest 发起请求之前修改，一般不用传
    ///   - file: 调用此方法的文件信息，**禁止覆盖默认值**
    ///   - function: 调用此方法的方法信息，**禁止覆盖默认值**
    ///   - line: 调用此方法的行号信息，**禁止覆盖默认值**
    ///   - progress: 下载进度更新回调
    ///   - decrypt: 下载完成后解密回调
    ///   - completion: 图片加载完成回调，可以在此获取到最终图片
    /// - Returns: 图片请求 LarkImageRequest
    @available(*, deprecated, renamed: "setLarkImage(_:placeholder:passThrough:options:trackInfo:modifier:file:function:line:progress:decrypt:completion:)")
    @discardableResult
    public func setLarkImage(with resource: LarkImageResource,
                             placeholder: UIImage? = nil,
                             passThrough: ImagePassThrough? = nil,
                             options: ImageRequestOptions = [],
                             transformer: BaseTransformer? = nil,
                             downloaderIdentifier: String? = nil,
                             size: CGSize? = nil,
                             cacheName: String? = nil,
                             timeoutInterval: TimeInterval? = nil,
                             trackStart: (() -> TrackInfo)? = nil,
                             trackEnd: (() -> TrackInfo)? = nil,
                             modifier: RequestModifier? = nil,
                             file: String = #fileID,
                             function: String = #function,
                             line: Int = #line,
                             progress: ImageRequestProgress? = nil,
                             decrypt: ImageRequestDecrypt? = nil,
                             completion: ImageRequestCompletion? = nil) -> LarkImageRequest? {
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
        let callbacks = ImageRequestCallbacks(decrypt: decrypt, progress: progress, completion: completion)
        return setLarkImage(resource, placeholder: placeholder, passThrough: passThrough, options: options,  trackInfo: trackStart, modifier: modifier, file: file, function: function, line: line, callbacks: callbacks)
    }
}
