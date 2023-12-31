//
//  ImageSetting.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/5/14.
//

import Foundation
import LKCommonsLogging
import LarkSetting

// disable-lint: magic number

// MARK: - ImageSetting

public struct ImageSetting {

    static let key = UserSettingKey.make(userKeyLiteral: "eeImageConfig")

    public struct CacheSetting {

        /// 原图缓存大小
        private(set) var original: Int = 200 * 1024 * 1024
        /// 缩略图缓存大小
        private(set) var thumb: Int = (UIDevice.current.userInterfaceIdiom == .pad ? 20 : 10) * 1024 * 1024
        /// 文档缓存大小
        private(set) var docs: Int = 50 * 1024 * 1024
        /// 外部缓存大小
        private(set) var external: Int = 50 * 1024 * 1024

        fileprivate init() {}

        fileprivate init(with dict: [String: Any]) {
            self.init()
            if let original = dict["original"] as? Int {
                self.original = original
            }
            if let thumb = dict["thumb"] as? Int {
                self.thumb = thumb
            }
            if let docs = dict["docs"] as? Int {
                self.docs = docs
            }
            if let external = dict["external"] as? Int {
                self.external = external
            }
        }
    }

    public struct DownsamplingSetting {

        public struct DownsampleValue {

            /// 以 pt 为单位的降采样宽高乘积
            public let ptValue: Int
            /// 以 px 为单位的降采样宽高乘积
            public let pxValue: Int
            /// 以 pt 为单位的降采样 CGSize
            public let ptSize: CGSize
            /// 以 px 为单位的降采样 CGSize
            public let pxSize: CGSize

            init(_ ptValue: Int) {
                self.ptValue = ptValue
                self.pxValue = ptValue * Self.scale * Self.scale
                self.ptSize = Self.sizeFromProduct(ptValue)
                self.pxSize = Self.sizeFromProduct(pxValue)
            }

            private static let scale = Int(UIScreen.main.scale)
            private static func sizeFromProduct(_ int: Int) -> CGSize {
                let side = CGFloat(sqrt(Double(int)))
                return CGSize(width: side, height: side)
            }
        }
        /// 查看大图降采样大小
        public private(set) var image = DownsampleValue(1000 * 1000)
        /// 分片缩略图大小（大图查看器用）
        public private(set) var tilePreviewImage = DownsampleValue(700 * 700)
        /// 普通图片降采样大小
        public private(set) var normalImage = DownsampleValue(375 * 750)
        /// gif 不解码大小
        public private(set) var gif: Int = 0
        /// GIF 不解码内存系数
        public private(set) var skipDecodeGIFMemoryFactor: Double = 0
        /// 其他格式图片 不解码内存系数
        public private(set) var skipDecodeIMGMemoryFactor: Double = 0
        /// 是否启用分片
        public private(set) var enableTile: Bool = true

        fileprivate init() {}

        fileprivate init(with dict: [String: Any]) {
            self.init()
            if let image = dict["image"] as? Int {
                self.image = DownsampleValue(image)
            }
            if let tilePreviewImage = dict["tilePreviewImage"] as? Int {
                self.tilePreviewImage = DownsampleValue(tilePreviewImage)
            }
            if let normalImage = dict["normalImage"] as? Int {
                self.normalImage = DownsampleValue(normalImage)
            }
            if let gif = dict["gif"] as? Int {
                self.gif = gif
            }
            if let skipDecodeGIFMemoryFactor = dict["skipDecodeGIFMemoryFactor"] as? Double {
                self.skipDecodeGIFMemoryFactor = skipDecodeGIFMemoryFactor
            }
            if let skipDecodeIMGMemoryFactor = dict["skipDecodeIMGMemoryFactor"] as? Double {
                self.skipDecodeIMGMemoryFactor = skipDecodeIMGMemoryFactor
            }
            if let enableTile = dict["enableTile"] as? Bool {
                self.enableTile = enableTile
            }
        }
    }

    /// 解码配置
    internal struct DecodeSetting {

        /// 动图延时最小值
        internal private(set) var animatedDelayMinimum: Double = 0.1

        fileprivate init() {}

        fileprivate init(with dict: [String: Any]) {
            self.init()
            if let animatedDelayMinimum = dict["animatedDelayMinimum"] as? Double {
                self.animatedDelayMinimum = animatedDelayMinimum
            }
        }
    }

    public private(set) var cache = CacheSetting()
    public private(set) var downsample = DownsamplingSetting()
    internal private(set) var decode = DecodeSetting()
    public private(set) var logLevel: Int = Log.Level.info.rawValue

    init() {}

    init(with dict: [String: Any]) {
        self.init()
        let dictName = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        if let deviceDict = dict[dictName] as? [String: Any] {
            if let cacheDict = deviceDict["cache"] as? [String: Any] {
                self.cache = CacheSetting(with: cacheDict)
            }
            if let downsampleDict = deviceDict["downsample"] as? [String: Any] {
                self.downsample = DownsamplingSetting(with: downsampleDict)
            }
            if let decodeDict = deviceDict["decode"] as? [String: Any] {
                self.decode = DecodeSetting(with: decodeDict)
            }
            if let logLevel = deviceDict["logLevel"] as? Int {
                self.logLevel = logLevel
            }
        }
        Self.logger.info("setting ImageSetting: " + "\(self)")
    }

    static let logger = Logger.log(ImageSetting.self,
                                   category: "ByteWebImage.ImageSetting")

}

// MARK: - ImageDisplayStrategySetting

/// setting: https://cloud.bytedance.net/appSettings-v2/detail/config/177278/detail/review-detail/281436
/// 图片加载使用降级策略
public struct ImageDisplayStrategySetting {

    static let key = UserSettingKey.make(userKeyLiteral: "chat_image_settings")

    public struct MessageCache {

        public private(set) var cacheEnable: Bool = true
        public private(set) var cacheLoadOriginMax: Int = 4_718_592 // 4.5M

        init() {}

        init(with dic: [String: Any]) {
            self.init()
            if let cache = dic["cache_enable"] as? Int {
                cacheEnable = cache == 1
            }
            if let max = dic["cache_load_origin_max"] as? Int {
                cacheLoadOriginMax = max
            }
        }
    }

    public struct MessageImageLoad {

        public struct MessageRemoteTarget {

            public private(set) var remoteAutoThumbScreenWidthMax: Int = 830

            init() {}

            init(with dic: [String: Any]) {
                self.init()
                if let max = dic["remote_auto_thumb_screen_width_max"] as? Int {
                    remoteAutoThumbScreenWidthMax = max
                }
            }
        }

        public private(set) var cache = MessageCache()
        public private(set) var remote = MessageRemoteTarget()

        init() {}

        init(with dic: [String: Any]) {
            self.init()
            if let cacheDic = dic["cache"] as? [String: Any] {
                cache = MessageCache(with: cacheDic)
            }
            if let remoteDic = dic["remote"] as? [String: Any],
               let targetDic = remoteDic["target"] as? [String: Any] {
                remote = MessageRemoteTarget(with: targetDic)
            }
        }
    }

    public struct LargeImageLoad {

        public struct LargeCache {

            public private(set) var cacheEnable: Bool = true

            init() {}

            init(with dic: [String: Any]) {
                self.init()
                if let enable = dic["cache_enable"] as? Int {
                    cacheEnable = enable == 1
                }
            }
        }

        public struct LargeRemoteTarget {

            public private(set) var remoteAutoOriginMax: Int = 512_000
            public private(set) var remoteDefaultTarget: String = "middle"

            init() {}

            init(with dic: [String: Any]) {
                self.init()
                if let max = dic["remote_auto_origin_max"] as? Int {
                    remoteAutoOriginMax = max
                }
                if let target = dic["remote_default_target"] as? String {
                    remoteDefaultTarget = target
                }
            }
        }

        public private(set) var cache = LargeCache()
        public private(set) var remote = LargeRemoteTarget()

        init() {}

        init(with dic: [String: Any]) {
            self.init()
            if let cacheDic = dic["cache"] as? [String: Any] {
                cache = LargeCache(with: cacheDic)
            }
            if let remoteDic = dic["remote"] as? [String: Any],
               let targetDic = remoteDic["target"] as? [String: Any] {
                remote = LargeRemoteTarget(with: targetDic)
            }
        }
    }

    internal struct ImageLoadDownsampleConfigs {

        /// format: `[fromType: [load_type: percentage]]`
        typealias ConfigsType = [Int: [Int: Int]]

        internal private(set) var configs: ConfigsType = [:]

        init() {
            // set default values
            set(fromTypes: [5, 6, 0], diskPercentage: 50, memoryPercentage: 10, to: &configs)
            set(fromTypes: [1], diskPercentage: 50, memoryPercentage: 20, to: &configs)
        }

        init(with dic: [[String: Any]]) {
            self.init()
            var newConfigs: ConfigsType = [:]
            dic.forEach { config in
                guard let fromTypes = config["from_types"] as? [Int],
                      let diskPercentage = config["disk_percentage"] as? Int,
                      let memoryPercentage = config["memory_percentage"] as? Int else { return }
                set(fromTypes: fromTypes, diskPercentage: diskPercentage,
                    memoryPercentage: memoryPercentage, to: &newConfigs)
            }
            if !newConfigs.isEmpty {
                configs = newConfigs
            }
            Self.logger.info("[Image][Settings] \(self)")
        }

        private func set(fromTypes: [Int], diskPercentage: Int,
                         memoryPercentage: Int, to configs: inout ConfigsType) {
            fromTypes.forEach { fromType in
                if configs[fromType] == nil {
                    configs[fromType] = [:]
                }
                configs[fromType]?[ImageResultFrom.diskCache.rawValue] = diskPercentage
                configs[fromType]?[ImageResultFrom.memoryCache.rawValue] = memoryPercentage
            }
        }

        internal func percentage(for fromType: TrackInfo.FromType, loadType: ImageResultFrom) -> Int? {
            guard let config = configs[fromType.rawValue],
                  let percentage = config[loadType.rawValue] else { return nil }
            return percentage
        }

        private static let logger = Logger.log(ImageLoadDownsampleConfigs.self,
                                               category: "ByteWebImage.ImageSetting")
    }

    public private(set) var messageImageLoad = MessageImageLoad()
    public private(set) var largeImageLoad = LargeImageLoad()
    internal private(set) var imageLoadDownsampleConfigs = ImageLoadDownsampleConfigs()

    init() {}

    init(with dic: [String: Any]) {
        self.init()
        guard let dic = dic["config"] as? [String: Any] else { return }
        if let messageDic = dic["message_image_load"] as? [String: Any] {
            messageImageLoad = MessageImageLoad(with: messageDic)
        }
        if let largeDic = dic["large_image_load"] as? [String: Any] {
            largeImageLoad = LargeImageLoad(with: largeDic)
        }
        if let downsampleDic = dic["image_load_downsample_configs"] as? [[String: Any]] {
            imageLoadDownsampleConfigs = ImageLoadDownsampleConfigs(with: downsampleDic)
        }
    }
}

// MARK: - ImageUploadComponentConfig

// 图片上传settings: https://cloud.bytedance.net/appSettings-v2/detail/config/153219/detail/status
public struct ImageUploadComponentConfig {

    static let key = UserSettingKey.make(userKeyLiteral: "image_upload_component_config")

    /// 图片文件大小阈值和图片尺寸大小阈值，根据不同的图片类型不同大小
    public struct FileSizeCheckConfig {

        /// 图片的文件大小和尺寸大小的限制
        public struct LimitByImageType {

            public private(set) var limitFileSize: CGFloat = 26_214_400
            public private(set) var limitImageSize: CGSize = CGSize(width: 5000, height: 5000)

            init() {}

            init(with dic: [String: Any]) {
                self.init()
                if let fileSize = dic["limit_file_size"] as? CGFloat {
                    self.limitFileSize = fileSize
                }
                if let imageSize = dic["limit_image_size"] as? [String: CGFloat],
                   let width = imageSize["width"],
                   let height = imageSize["height"] {
                    self.limitImageSize = CGSize(width: width, height: height)
                }
            }
        }

        public private(set) var enableCheck: Bool = true
        public private(set) var base = LimitByImageType()
        public private(set) var jpg = LimitByImageType()
        public private(set) var png = LimitByImageType()
        public private(set) var tiff = LimitByImageType()
        public private(set) var gif = LimitByImageType()

        init() {}

        init(with dic: [String: Any]) {
            self.init()
            if let enable = dic["enable_file_size_check"] as? Bool {
                self.enableCheck = enable
            }
            if let base = dic["base_config"] as? [String: Any] {
                self.base = LimitByImageType(with: base)
            }
            if let jpg = dic["jpg_config"] as? [String: Any] {
                self.jpg = LimitByImageType(with: jpg)
            }
            if let png = dic["png_config"] as? [String: Any] {
                self.png = LimitByImageType(with: png)
            }
            if let tiff = dic["tiff_config"] as? [String: Any] {
                self.tiff = LimitByImageType(with: tiff)
            }
            if let gif = dic["gif_config"] as? [String: Any] {
                self.gif = LimitByImageType(with: gif)
            }
        }
    }

    /// 图片类型校验的配置
    public struct FileTypeCheckConfig {

        public private(set) var enableCheck: Bool = true
        /// 本地校验，例如密聊场景下，只能本地转码
        public private(set) var localWhiteList: [String] = [
            "png", "webp", "jpg", "jpeg", "bmp", "x-icon", "vnd.microsoft.icon", "gif"
        ]
        /// 服务端支持转码类型
        public private(set) var serverWhiteList: [String] = [
            "png", "webp", "jpg", "jpeg", "heic", "heif", "bmp", "x-icon", "vnd.microsoft.icon", "gif"
        ]

        init() {}

        init(with dic: [String: Any]) {
            self.init()
            if let enableCheck = dic["enable_file_type_check"] as? Bool {
                self.enableCheck = enableCheck
            }
            if let local = dic["local_valid_image_white_list"] as? [String] {
                self.localWhiteList = local
            }
            if let server = dic["server_transcode_white_list"] as? [String] {
                self.serverWhiteList = server
            }
        }
    }

    /// 图片转码的配置
    public struct ClientTranscodeConfig {

        public private(set) var enableClientTranscode: Bool = true
        /// 无需进行转码的图片格式列表
        public private(set) var skipTranscodeImageTypeList: [String] = ["jpg", "webp", "jpeg", "gif"]
        /// 其他类型的图片，目标转码格式
        public private(set) var targetTranscodeType: String = "jpg"

        init() {}

        init(with dic: [String: Any]) {
            self.init()
            if let enable = dic["enable_client_transcode"] as? Bool {
                self.enableClientTranscode = enable
            }
            if let skip = dic["skip_transcode_image_type_list"] as? [String] {
                self.skipTranscodeImageTypeList = skip
            }
            if let target = dic["target_transcode_type"] as? String {
                self.targetTranscodeType = target
            }
        }
    }

    /// 删除exif信息的配置
    public struct RemoveExifConfig {

        public private(set) var enableRemove: Bool = true

        init() {}

        init(with dic: [String: Any]) {
            self.init()
            if let enable = dic["enable_remove_exif"] as? Bool {
                self.enableRemove = enable
            }
        }
    }

    /// 此配置的创建的初衷是发现部分图片压缩后，体积变的更大。为了减少这种情况的出现，添加配置进行拦截
    public struct UseSourceDataConfig {

        /// 是否可以不压缩
        ///
        /// 开关打开：部分jpg格式的图片已经被压缩过，如果「此次目标压缩值」，比「已压缩值」大，那么就跳过压缩步骤
        public private(set) var enableNotCompress: Bool = true
        /// 是否可以比较原图信息
        ///
        /// 开关打开：比较压缩前和压缩后的数据，如果变大或者压缩前图片短边就很短了，那么就使用压缩前的数据
        public private(set) var enableCompare: Bool = true
        /// 「压缩后」比「压缩前」大increaseByte，那么才判定是可以用压缩前数据。
        public private(set) var increaseByte: Int = 512_000
        /// 如果「压缩前」图片短边比imageShortSide小，也是可以用压缩前数据的
        public private(set) var imageShortSide: Int = 2000

        init() {}

        init(with dic: [String: Any]) {
            self.init()
            if let enableNotCompress = dic["enable_not_compress"] as? Int {
                self.enableNotCompress = enableNotCompress == 1
            }
            if let enableCompare = dic["enable_compare"] as? Int {
                self.enableCompare = enableCompare == 1
            }
            if let imageShortSide = dic["image_short_side"] as? Int {
                self.imageShortSide = imageShortSide
            }
            if let increaseByte = dic["image_file_increase_byte"] as? Int {
                self.increaseByte = increaseByte
            }
        }
    }

    /// 头像上传配置
    public struct AvatarConfig {

        /// 限制短边尺寸(px)
        public private(set) var limitImageSize: Int = 1080
        /// 压缩质量
        public private(set) var quality: Int = 75

        init() {}

        init(with dic: [String: Any]) {
            self.init()
            if let limitImageSize = dic["limit_image_size"] as? Int {
                self.limitImageSize = limitImageSize
            }
            if let quality = dic["quality"] as? Int {
                self.quality = quality
            }
        }
    }

    public private(set) var fileSizeCheckConfig = FileSizeCheckConfig()
    public private(set) var fileTypeCheckConfig = FileTypeCheckConfig()
    public private(set) var transcodeConfig = ClientTranscodeConfig()
    public private(set) var removeExifConfig = RemoveExifConfig()
    public private(set) var useSourceDataConfig = UseSourceDataConfig()
    public private(set) var avatarConfig = AvatarConfig()

    init() {}

    init(with dic: [String: Any]) {
        self.init()
        if let fileSizeConfig = dic["file_size_check_config"] as? [String: Any] {
            self.fileSizeCheckConfig = FileSizeCheckConfig(with: fileSizeConfig)
        }
        if let fileTypeConfig = dic["file_type_check_config"] as? [String: Any] {
            self.fileTypeCheckConfig = FileTypeCheckConfig(with: fileTypeConfig)
        }
        if let transcodeConfig = dic["client_transcode_config"] as? [String: Any] {
            self.transcodeConfig = ClientTranscodeConfig(with: transcodeConfig)
        }
        if let removeConfig = dic["remove_exif_config"] as? [String: Any] {
            self.removeExifConfig = RemoveExifConfig(with: removeConfig)
        }
        if let useSourceDataConfig = dic["use_source_data"] as? [String: Any] {
            self.useSourceDataConfig = UseSourceDataConfig(with: useSourceDataConfig)
        }
        if let avatarConfig = dic["avatar_config"] as? [String: Any] {
            self.avatarConfig = AvatarConfig(with: avatarConfig)
        }
    }

    public func getFileSizeFromSetting(imageType: ImageSourceResult.SourceType) -> CGFloat {
        switch imageType {
        case .png:
            return fileSizeCheckConfig.png.limitFileSize
        case .jpeg:
            return fileSizeCheckConfig.jpg.limitFileSize
        case .tiff:
            return fileSizeCheckConfig.tiff.limitFileSize
        case .gif:
            return fileSizeCheckConfig.gif.limitFileSize
        default:
            return fileSizeCheckConfig.base.limitFileSize
        }
    }

    public func getImageSizeFromSetting(imageType: ImageSourceResult.SourceType) -> CGSize {
        switch imageType {
        case .png:
            return fileSizeCheckConfig.png.limitImageSize
        case .jpeg:
            return fileSizeCheckConfig.jpg.limitImageSize
        case .tiff:
            return fileSizeCheckConfig.tiff.limitImageSize
        case .gif:
            return fileSizeCheckConfig.gif.limitImageSize
        default:
            return fileSizeCheckConfig.base.limitImageSize
        }
    }
}

// MARK: - ImageExportConfig

/// 图片导出 settings: https://cloud.bytedance.net/appSettings-v2/detail/config/170153/detail/basic
public struct ImageExportConfig {

    static let key = UserSettingKey.make(userKeyLiteral: "image_export_config")

    /// 转换配置
    public struct ConvertConfig {

        /// 需要转换格式的原格式列表
        public fileprivate(set) var convertSourceTypes: [String] = ["webp"]

        /// 即使原格式不在上述列表中，当系统不支持该格式时，是否需要转换
        public fileprivate(set) var convertWhenSystemUnavailable: Bool = true

        fileprivate init() {}

        fileprivate init(with dic: [String: Any]) {
            self.init()
            if let convertSourceTypes = dic["convertSourceTypes"] as? [String] {
                self.convertSourceTypes = convertSourceTypes
            }
            if let convertWhenSystemUnavailable = dic["convertWhenSystemUnavailable"] as? Bool {
                self.convertWhenSystemUnavailable = convertWhenSystemUnavailable
            }
        }
    }

    /// 非原图转换配置
    public private(set) var noneOrigin = ConvertConfig()

    /// 原图转换配置
    public private(set) var origin = {
        var config = ConvertConfig()
        config.convertSourceTypes = []
        return config
    }()

    init() {}

    init(with dic: [String: Any]) {
        self.init()
        if let noneOrigin = dic["noneOrigin"] as? [String: Any] {
            self.noneOrigin = ConvertConfig(with: noneOrigin)
        }
        if let origin = dic["origin"] as? [String: Any] {
            self.origin = ConvertConfig(with: origin)
        }
    }
}

// MARK: - ImagePreloadConfig

/// 图片预加载配置：https://cloud.bytedance.net/appSettings-v2/detail/config/174557/detail/status

public struct ImagePreloadConfig {

    static let key = UserSettingKey.make(userKeyLiteral: "image_preload")

    /// scene 对应的策略
    struct PreloadStrategy {

        /// scene 场景枚举，如 "feed", "chat"
        let scene: String

        /// 是否开启该 scene 的预加载
        let preloadEnable: Int

        /// 队列中最大数量
        let maxCount: Int
    }

    /// 整体功能的开关，由 setting & ab 共同控制
    public var preloadEnable: Bool = true

    /// 网络限制
    ///
    /// 0: 代表无限制； 1: 弱网时不加载； 2: 仅 WiFi 时加载
    private(set) var networkLimit: Int = 1

    /// CPU 限制, 当前设备 CPU 平均使用超过数值则抛弃此次预加载
    private(set) var cpuLimit: Int = 80

    /// 内存预加载缓存 LRU 个数限制
    public private(set) var preloadCacheCount: Int = 200

    /// 最大并发数, 0 代表不限制
    private(set) var maxConcurrentCount: Int = 2

    /// scene 对应的策略
    private(set) var preloadStrategy: [PreloadStrategy] = [
        PreloadStrategy(scene: "feed", preloadEnable: 1, maxCount: 5),
        PreloadStrategy(scene: "chat", preloadEnable: 1, maxCount: 20)
    ]

    init() {}

    init(with dic: [String: Any]) {
        self.init()
        if let preloadEnable = dic["preload_enable"] as? Int {
            self.preloadEnable = preloadEnable == 1
        }
        if let networkLimit = dic["network_limit"] as? Int {
            self.networkLimit = networkLimit
        }
    }

    func getStrategy(from scene: String) -> PreloadStrategy? {
        preloadStrategy.first { $0.scene == scene }
    }
}
