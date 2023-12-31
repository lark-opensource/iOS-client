//
//  ImageRequestKey.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/23.
//

import UIKit
import EEAtomic

public final class ImageRequestKey {
    private(set) var transfromName: String = ""           // Image needs to be transfromed
    private(set) var sourceKey: String               // data key，url or requestKey from urlfilter，diskCache use this key
    @AtomicObject
    private var _targetKey: String?   // image key，what is it composed of sourceKey、transfromName、cropRect、downsampleSize, memoryCache use this key
    var targetKey: String {
        guard let key = _targetKey else {
            let key = sourceCacheKey().bt.processKey(config: processConfig)
            _targetKey = key
            return key
        }
        return key
    }
    // image downsample with size
    private(set) var downsampleSize: CGSize = .zero {
        didSet {
            if downsampleSize != oldValue { _targetKey = nil }
        }
    }
    // Image cropped area
    private(set) var cropRect: CGRect = .zero {
        didSet {
            if cropRect != oldValue { _targetKey = nil }
        }
    }
    // Image need smart cropping
    private(set) var smartCrop: Bool = false {
        didSet {
            if smartCrop != oldValue { _targetKey = nil }
        }
    }
    // customCacheKey
    private var customCacheKey: String? {
        didSet {
            if customCacheKey != oldValue { _targetKey = nil }
        }
    }

    private var processConfig: ImageProcessConfig {
        ImageProcessConfig(downsample: downsampleSize, needCrop: smartCrop, crop: cropRect, transformID: transfromName)
    }

    private var mutex = pthread_mutex_t()

    required init(with url: String, downsampleSize: CGSize = .zero, cropRect: CGRect = .zero, transfromName: String? = nil, smartCrop: Bool = false) {
        self.sourceKey = url
        self.downsampleSize = downsampleSize
        self.cropRect = cropRect
        self.transfromName = transfromName?.replacingOccurrences(of: "_", with: ".") ?? ""
        self.smartCrop = smartCrop
        pthread_mutex_init(&self.mutex, nil)
    }

    init(_ url: String) {
        let (source, config) = url.bt.parse() ?? (url, .default)
        self.sourceKey = source
        self.downsampleSize = config.downsample
        self.cropRect = config.crop
        self.transfromName = config.transformID
        self.smartCrop = (config.downsample != .zero)
        self._targetKey = url
        pthread_mutex_init(&self.mutex, nil)
    }

    deinit {
        pthread_mutex_destroy(&self.mutex)
    }

    func contains(url: String?) -> Bool {
        guard let url = url,
              !url.isEmpty,
              let requestURL = URL(string: url)
        else { return false }
        let requestKey = requestURL.absoluteString
        return self.sourceKey == url || self.sourceKey == requestKey
    }

    /// 设置Request Key
    public func setRequestKey(_ key: String) {
        self.sourceKey = key
    }
    /// 用来请求的Key
    public func requestKey() -> String {
        return self.sourceKey
    }
    /// 原始图片CacheKey
    public func sourceCacheKey() -> String {
        return customCacheKey ?? sourceKey
    }
    /// 经过处理图片CacheKey
    public func targetCacheKey() -> String {
        targetKey
    }
    /// 设置自定义缓存key
    public func setCustomCacheKey(_ key: String) {
        self.customCacheKey = key
    }

    public func setTransfromName(_ name: String?) {
        self.transfromName = name ?? ""
    }

    public func setDownsampleSize(_ size: CGSize) {
        self.downsampleSize = size
    }

    public func setCropRect(_ rect: CGRect) {
        self.cropRect = rect
    }

    public func setSmartCrop(_ crop: Bool) {
        self.smartCrop = crop
    }
}

extension ImageRequestKey: Hashable {

    public static func == (lhs: ImageRequestKey, rhs: ImageRequestKey) -> Bool {
        lhs.targetKey == rhs.targetKey
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(targetKey)
    }

    /// 判断两个请求Key是否相等
    /// cropRect是由服务端返回的，因此不做相等判断
    func isSame(as other: ImageRequestKey) -> Bool {
        sourceKey == other.sourceKey &&
        downsampleSize == other.downsampleSize &&
        smartCrop == other.smartCrop &&
        transfromName == other.transfromName
    }
}
