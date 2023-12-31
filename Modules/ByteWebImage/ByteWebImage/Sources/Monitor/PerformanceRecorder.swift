//  PerformanceRecorder.swift
//  ByteWebImage
//
//  Created by Xiongming on 2021/3/28.
//

public final class PerformanceRecorder {
    var enableRecord: Bool = true // 是否应该被记录，生成的假的Request例如重复请求不该被记录
    var identifier: String // 唯一标志，和Request保持一致
    var category: String? // 分类标志，可以用来区分不同业务场景
    var sourceFileInfo: FileInfo? // 发起请求的代码文件信息，用于兜底定位哪个业务方发起的请求
    var imageKey: String // 图片请求URL或者rust key
    var startTime: TimeInterval = 0 // 开始时间戳
    var endTime: TimeInterval = 0
    var requestParams: ImageRequestParams = [] // 请求设置参数
    var retryCount: Int = 0 // 重试次数
    var contexID: String? // contextID
    // rust详细耗时
    var rustCost: [String: UInt64]?

    var error: ByteWebImageError? // 请求错误
    /// resolution
    var originSize: CGSize = .zero // 图片原始大小
    var loadSize: CGSize = .zero // 图片实际加载大小
    var requestSize: CGSize = .zero // 发起请求设置大小
    /// cache
    var cacheSeekBegin: TimeInterval = 0 // 缓存查找开始时间
    var cacheSeekEnd: TimeInterval = 0 // 缓存查找结束时间
    var cacheSeekCost: TimeInterval {
        let duration = cacheSeekEnd - cacheSeekBegin
        return duration > 0 ? duration : 0

    }
    var cacheType: ImageCacheOptions = .none // 缓存命中类型
    /// queue
    var queueBegin: TimeInterval = 0 // 排队开始时间
    var queueEnd: TimeInterval = 0 // 排队结束时间
    var queueCost: TimeInterval {
        let duration = queueEnd - queueBegin
        return duration > 0 ? duration : 0
    }
    /// download
    var downloadBegin: TimeInterval = 0 // 下载开始时间
    var downloadEnd: TimeInterval = 0 // 下载结束时间
    var downloadCost: TimeInterval {
        let duration = downloadEnd - downloadBegin
        return duration > 0 ? duration : 0
    }
    var expectedSize: Int64 = 0 // 预期下载大小
    var receiveSize: Int64 = 0 // 实际收到大小
    /// decrypt
    var decryptBegin: TimeInterval = 0 // 解密开始时间
    var decryptEnd: TimeInterval = 0 // 解密结束时间
    var decryptCost: TimeInterval {
        let duration = decryptEnd - decryptBegin
        return duration > 0 ? duration : 0
    }
    /// decode
    var imageType: ImageFileFormat = .unknown // 图片类别
    var decodeBegin: TimeInterval = 0 // 解码开始时间
    var decodeEnd: TimeInterval = 0 // 解码结束
    var decodeCost: TimeInterval {
        let duration = decodeEnd - decodeBegin
        return duration > 0 ? duration : 0
    }
    /// setImage
    var cacheBegin: TimeInterval = 0 // 缓存开始时间
    var cacheEnd: TimeInterval = 0 // 缓存结束时间
    var cacheCost: TimeInterval {
        let duration = cacheEnd - cacheBegin
        return duration > 0 ? duration : 0
    }

    init(with identifier: String, imageKey: String, category: String? = nil) {
        self.identifier = identifier
        self.imageKey = imageKey
        self.category = category
    }

}

extension PerformanceRecorder: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = PerformanceRecorder(with: self.identifier, imageKey: self.imageKey, category: self.category)
        copy.sourceFileInfo = self.sourceFileInfo
        copy.enableRecord = self.enableRecord
        copy.cacheBegin = self.cacheBegin
        copy.retryCount = self.retryCount
        // https://slardar.bytedance.net/node/app_detail/?aid=1378&os=iOS#/abnormal/detail/crash/1378_1ed2a403fa7789736468d19d0adc7785
        // userInfo 得进行deep copy
        var copyInfo: [String: String] = [:]
        for element in self.error?.userInfo ?? [:] {
            copyInfo[element.key] = element.value
        }
        var copyCost: [String: UInt64] = [:]
        for cost in self.rustCost ?? [:] {
            copyCost[cost.key] = cost.value
        }
        copy.rustCost = copyCost
        copy.error = ImageError(self.error?.code ?? 0, userInfo: copyInfo)
        copy.startTime = self.startTime
        copy.endTime = self.endTime
        copy.requestParams = self.requestParams
        copy.originSize = self.originSize
        copy.loadSize = self.loadSize
        copy.requestSize = self.requestSize
        copy.cacheSeekBegin = self.cacheSeekBegin
        copy.cacheSeekEnd = self.cacheSeekEnd
        copy.cacheType = self.cacheType
        copy.downloadBegin = self.downloadBegin
        copy.downloadEnd = self.downloadEnd
        copy.expectedSize = self.expectedSize
        copy.requestSize = self.requestSize
        copy.imageType = self.imageType
        copy.decodeBegin = self.decodeBegin
        copy.decodeEnd = self.decodeEnd
        copy.cacheBegin = self.cacheBegin
        copy.cacheEnd = self.cacheEnd
        copy.contexID = self.contexID
        return copy
    }

}
extension Dictionary {
    /// 对 Key or Value == String 的字典进行深拷贝，回避 String 二次释放等多线程问题
    func safeCopy() -> [Key: Value] {
        guard Key.self == String.self || Value.self == String.self else { return self }
        var copy: [Key: Value] = [:]
        for pair in self {
            copy[pair.key] = pair.value
        }
        return copy
    }
}
