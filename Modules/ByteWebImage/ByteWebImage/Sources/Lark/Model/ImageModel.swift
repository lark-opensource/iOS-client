//
//  ImageModel.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/13.
//

import RustPB
import Foundation
import LKCommonsTracker
import LKCommonsLogging

// disable-lint: magic number

public struct ImageItem {

    public enum ImageType {
        case normal
        case encrypted
    }

    public var key: String?
    public var urls: [String]?
    public var type: ImageType?
    public var crypto: Data?
    public var fsUnit: String?

    public init() {}

    public init(key: String? = nil,
                urls: [String]? = nil,
                type: ImageType? = nil,
                crypto: Data? = nil,
                fsUnit: String? = nil) {
        self.key = key
        self.urls = urls
        self.type = type
        self.crypto = crypto
        self.fsUnit = fsUnit
    }
}

public extension ImageItem {

    @inline(__always)
    func imageResource() -> LarkImageResource {
        .rustImage(key: key ?? "", fsUnit: fsUnit, crypto: crypto)
    }
}

// MARK: - ImageItemSet

public struct ImageItemSet {
    public var key: String?
    public var token: String?
    public var urls: [String]?
    public var origin: ImageItem?
    public var thumbnail: ImageItem?
    public var middle: ImageItem?
    public var originWidth: Int?
    public var originHeight: Int?
    public var inlinePreview: UIImage?

    public init() {}
}

public extension ImageItemSet {
    func generateImageMessageKey(forceOrigin: Bool) -> String {
        return LarkImageService.shared.generateImageMessageKey(imageSet: self, forceOrigin: forceOrigin)
    }

    func generatePostMessageKey(forceOrigin: Bool) -> String {
        return LarkImageService.shared.generatePostMessageKey(imageSet: self, forceOrigin: forceOrigin)
    }

    func generateVideoMessageKey(forceOrigin: Bool) -> String {
        return LarkImageService.shared.generateVideoMessageKey(imageSet: self, forceOrigin: forceOrigin)
    }

    func getThumbKey() -> String {
        return LarkImageService.shared.getThumbKey(imageItemSet: self)
    }

    func isOriginKey(key: String) -> Bool {
        return LarkImageService.shared.isOriginKey(key: key, imageItemSet: self)
    }
}

public extension ImageItemSet {

    @inline(__always)
    func getThumbResource() -> LarkImageResource {
        getThumbItem().imageResource()
    }

    func getThumbItem() -> ImageItem {
        let thumbImageItem = thumbnail
        let middleImageItem = middle
        if UIScreen.main.bounds.width * UIScreen.main.scale > CGFloat(
            LarkImageService.shared.imageDisplaySetting.messageImageLoad.remote.remoteAutoThumbScreenWidthMax) {
            if let middleImageItem, let middleKey = middleImageItem.key, !middleKey.isEmpty {
                return middleImageItem
            }
        }
        return thumbImageItem ?? ImageItem()
    }

    func isOrigin(resource: LarkImageResource) -> Bool {
        let key = resource.cacheKey
        if !key.isEmpty {
            return isOrigin(key: key)
        }
        return false
    }

    func isOrigin(item imageItem: ImageItem) -> Bool {
        if let key = imageItem.key, !key.isEmpty {
            return isOrigin(key: key)
        }
        return false
    }

    @inline(__always)
    func isOrigin(key: String) -> Bool {
        key == origin?.key
    }
}

// MARK: - Extension of ImageItem

public extension ImageItem {
    static func transform(image: RustPB.Basic_V1_Image) -> ImageItem {
        var item = ImageItem()
        item.type = .normal
        if image.type == .encrypted {
            item.type = .encrypted
        }
        item.key = image.key
        item.urls = image.urls
        if image.hasCrypto {
            item.crypto = image.crypto
        }
        if image.hasFsUnit {
            item.fsUnit = image.fsUnit
        }
        #if ALPHA
        if item.needDebug() {
            logger.warn("transform Image: \(image.key), fsUnit: \(image.hasFsUnit), crypto: \(image.hasCrypto)")
        }
        #endif
        return item
    }

    // 两端统一：如果 fsUnit 或 Crypto 为空，统一使用 origin 的信息
    fileprivate mutating func repairInfoIfNeeded(with origin: ImageItem?) {
        guard let origin else { return }
        if fsUnit == nil || fsUnit?.isEmpty ?? false {
            fsUnit = origin.fsUnit
        }
        if crypto == nil || crypto?.isEmpty ?? false {
            crypto = origin.crypto
        }
    }

    #if ALPHA
    fileprivate func needDebug() -> Bool {
        if let fsUnit = self.fsUnit, !fsUnit.isEmpty {
            return false
        }
        if let crypto = self.crypto, !crypto.isEmpty {
            return false
        }
        return true
    }
    #endif
}

// MARK: Extension of Basic_V1_Image

public extension RustPB.Basic_V1_Image {

    @inline(__always)
    func imageItem() -> ImageItem {
        ImageItem.transform(image: self)
    }
}

// MARK: - Extension of ImageItemSet

fileprivate let logger = Logger.log(ImageItemSet.self, category: "ImageItemSet.transform")

public extension ImageItemSet {
    static func transform(imageSet: RustPB.Basic_V1_ImageSet) -> ImageItemSet {
        var imageItemSet = ImageItemSet()
        imageItemSet.key = imageSet.key
        imageItemSet.origin = ImageItem.transform(image: imageSet.origin)
        let thumbPair = getSuitableThumbnailImageItem(imageSet: imageSet)
        imageItemSet.thumbnail = thumbPair.thumbnail
        imageItemSet.middle = thumbPair.middle
        imageItemSet.thumbnail?.repairInfoIfNeeded(with: imageItemSet.origin)
        imageItemSet.middle?.repairInfoIfNeeded(with: imageItemSet.origin)
        #if ALPHA
        if imageItemSet.needDebug() {
            logger.warn("imageSet fsUnit crypto empty: \(imageSet)")
        }
        #endif
        imageItemSet.originWidth = Int(imageSet.origin.width)
        imageItemSet.originHeight = Int(imageSet.origin.height)
        imageItemSet.inlinePreview = getInlineImage(imageSetKey: imageSet.key,
                                                    hasInline: imageSet.hasInlinePreview,
                                                    inline: imageSet.inlinePreview)
        return imageItemSet
    }

    static func transform(imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty) -> ImageItemSet {
        var imageItemSet = ImageItemSet()
        imageItemSet.urls = imageProperty.urls
        imageItemSet.token = imageProperty.token
        imageItemSet.origin = imageProperty.hasOrigin ?
            ImageItem.transform(image: imageProperty.origin) :
            ImageItem(key: imageProperty.originKey, urls: imageProperty.urls)
        let thumbPair = getSuitableThumbnailImageItem(imageProperty: imageProperty)
        imageItemSet.thumbnail = thumbPair.thumbnail
        imageItemSet.middle = thumbPair.middle
        imageItemSet.thumbnail?.repairInfoIfNeeded(with: imageItemSet.origin)
        imageItemSet.middle?.repairInfoIfNeeded(with: imageItemSet.origin)
        #if ALPHA
        if imageItemSet.needDebug() {
            logger.warn("imageProperty fsUnit crypto empty: \(imageProperty)")
        }
        #endif
        imageItemSet.originWidth = Int(imageProperty.originWidth)
        imageItemSet.originHeight = Int(imageProperty.originHeight)
        imageItemSet.inlinePreview = getInlineImage(imageSetKey: imageProperty.originKey,
                                                    hasInline: imageProperty.hasInlinePreview,
                                                    inline: imageProperty.inlinePreview)
        return imageItemSet
    }

    #if ALPHA
    private func needDebug() -> Bool {
        thumbnail?.needDebug() ?? true || middle?.needDebug() ?? true || origin?.needDebug() ?? true
    }
    #endif

    /// 聊天记录内的缩略图策略
    func getThumbInfoForSearchHistory() -> (String, ImageItem?) {
        let isMiddle = (self.originWidth ?? 0) > 850
        var finalKey = ""
        var image: ImageItem?
        if isMiddle {
            if let midKey = self.middle?.key, !midKey.isEmpty {
                finalKey = midKey
                image = self.middle
            } else {
                finalKey = self.thumbnail?.key ?? ""
                image = self.thumbnail
            }
        } else {
            finalKey = self.thumbnail?.key ?? ""
            image = self.thumbnail
        }
        return (finalKey, image)
    }

    private static func getSuitableThumbnailImageItem(imageSet: RustPB.Basic_V1_ImageSet) -> (thumbnail: ImageItem, middle: ImageItem) {
        var thumbnailItem: ImageItem
        var middleItem: ImageItem
        if !imageSet.thumbnailWebp.key.isEmpty {
            thumbnailItem = ImageItem.transform(image: imageSet.thumbnailWebp)
        } else {
            thumbnailItem = ImageItem.transform(image: imageSet.thumbnail)
        }
        if !imageSet.middleWebp.key.isEmpty {
            middleItem = ImageItem.transform(image: imageSet.middleWebp)
        } else {
            middleItem = ImageItem.transform(image: imageSet.middle)
        }
        return (thumbnailItem, middleItem)
    }

    private static func getSuitableThumbnailImageItem(imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty) -> (thumbnail: ImageItem, middle: ImageItem) {
        var thumbnailItem: ImageItem
        var middleItem: ImageItem
        if !imageProperty.thumbnailWebp.key.isEmpty {
            thumbnailItem = ImageItem.transform(image: imageProperty.thumbnailWebp)
        } else {
            thumbnailItem = ImageItem(key: imageProperty.thumbKey, urls: imageProperty.urls, type: nil)
        }
        if !imageProperty.middleWebp.key.isEmpty {
            middleItem = ImageItem.transform(image: imageProperty.middleWebp)
        } else {
            middleItem = ImageItem(key: imageProperty.middleKey, urls: imageProperty.urls, type: nil)
        }
        return (thumbnailItem, middleItem)
    }

    /// 返回 inline 图，优先查内存缓存，无则解码 Data 并 上报埋点
    private static func getInlineImage(imageSetKey: String, hasInline: Bool, inline data: Data) -> UIImage? {
        let inlineKey: LarkImageResource = .default(key: imageSetKey + "_inline")
        if let image = LarkImageService.shared.image(with: inlineKey, cacheOptions: .memory) {
            return image
        } else { // 非缓存需要上报埋点
            var params: [AnyHashable: Any] = [
                "resultCode": 0,
                "errorMsg": "",
                "latency": 0,
                "size": 0,
                "width": 0,
                "height": 0,
            ]
            var resultImage: ByteImage?
            var resultCode = 0
            if hasInline, !data.isEmpty {
                do {
                    let startTime = CACurrentMediaTime()
                    let image = try ByteImage(data)
                    let decodeCost = (CACurrentMediaTime() - startTime) * 1000 // ms
                    LarkImageService.shared.cacheImage(image: image, resource: inlineKey, cacheOptions: .memory)
                    params["latency"] = decodeCost
                    params["width"] = Int(image.size.width * image.scale)
                    params["height"] = Int(image.size.height * image.scale)
                    params["size"] = data.count
                    resultImage = image
                } catch {
                    let btError = error as? ByteWebImageError
                    resultCode = btError?.code ?? 2
                    params["errorMsg"] = btError?.localizedDescription ?? error.localizedDescription
                }
            } else { // 无 inline 时也上报
                resultCode = 1
            }
            params["resultCode"] = resultCode
            // 异步上报
            DispatchQueue.global().async {
                switch resultCode {
                case 0: logger.info("decode inline succeeded for imageSetKey: \(imageSetKey), params: \(params)")
                case 1: logger.warn("didn't find inline for imageSetKey: \(imageSetKey), params: \(params)")
                default: // 解码失败统计特征
                    params[ByteWebImageError.UserInfoKey.dataHash] = data.bt.crc32
                    params[ByteWebImageError.UserInfoKey.dataFormatHeader] = data.bt.formatHeader
                    params[ByteWebImageError.UserInfoKey.dataLength] = String(data.count)
                    logger.error("decode inline failed for imageSetKey: \(imageSetKey), params: \(params)")
                }
                let event = TeaEvent("inline_preview_decode_dev", params: params)
                Tracker.post(event)
            }
            return resultImage
        }
    }
}

// MARK: - AvatarImageParams

public struct AvatarImageParams {

    public enum CutType: Int32 {
        case top = 1, bottom, left, right, center, face
    }

    /// default: 128
    public var width: Int32?
    /// default: 128
    public var height: Int32?
    public var cutType: CutType?
    /// default: webp
    public var format: ImageFileFormat?
    /// 图片质量 [0, 100], default: 70
    public var quality: Int32?
    /// 返回原图，忽略其他设置
    public var noop: Bool?
    /// 判断是否为空
    public var isEmpty: Bool {
        if width != nil ||
            height != nil ||
            cutType != nil ||
            format != nil ||
            quality != nil ||
            noop != nil {
            return false
        }
        return true
    }

    public static var faceAvatarImageParams: AvatarImageParams = {
        var faceAvatarImageParams = AvatarImageParams()
        faceAvatarImageParams.width = 640
        faceAvatarImageParams.height = 640
        faceAvatarImageParams.cutType = .face
        faceAvatarImageParams.format = .webp
        faceAvatarImageParams.quality = 75
        return faceAvatarImageParams
    }()

    public static var middleImage: AvatarImageParams {
        var middleImage = AvatarImageParams()
        middleImage.width = 128
        middleImage.height = 128
        return middleImage
    }

    public static var bigImage: AvatarImageParams {
        var middleImage = AvatarImageParams()
        middleImage.width = 640
        middleImage.height = 640
        return middleImage
    }

    public init() { }

    // SDK逻辑问题导致iOS目前需要的脏逻辑，jira LKR-443
    public func cutKey(avatarKey: String) -> String {
        if self.cutType == CutType.face {
            return avatarKey.replacingOccurrences(of: avatarKeyPostfix, with: "")
        }
        return avatarKey
    }

    public func buildAvatarSDKKey(avatarKey: String) -> String {
        return "\(avatarKey)\(avatarKeyPostfix)"
    }

    private var avatarKeyPostfix: String {
        return "\((format ?? .webp).displayName)w\(width ?? 128)h\(height ?? 128)cs"
    }

    static public func transform(additionMap: [String: Any]) -> AvatarImageParams {
        var params = AvatarImageParams()
        if let rawValue = additionMap["cutType"] as? Int32, let cutType = CutType(rawValue: rawValue) {
            params.cutType = cutType
        }
        if let format = additionMap["format"] as? ImageFileFormat {
            params.format = format
        }
        if let width = additionMap["width"] as? Int32 {
            params.width = width
        }
        if let height = additionMap["height"] as? Int32 {
            params.height = height
        }
        if let noop = additionMap["noop"] as? Bool {
            params.noop = noop
        }
        if let quality = additionMap["quality"] as? Int32 {
            params.quality = quality
        }
        return params
    }

    public func transformDic() -> [String: Any] {
        var config: [String: Any] = [:]
        if let width = self.width {
            config["width"] = width
        }
        if let height = self.height {
            config["height"] = height
        }
        if let cutType = self.cutType {
            config["cutType"] = cutType.rawValue
        }
        if let format = self.format {
            config["format"] = format
        }
        if let quality = self.quality {
            config["quality"] = quality
        }
        if let noop = self.noop {
            config["noop"] = noop
        }
        return config
    }
}

// MARK: - AvatarView SizeType
public enum SizeType: Equatable {

    case size(CGFloat) // max(width, height)
    case thumb
    case middle
    case big

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.thumb, .thumb),
             (.middle, .middle),
             (.big, .big):
            return true
        case (.size(let lhsSize), .size(let rhsSize)):
            return lhsSize == rhsSize
        default:
            return false
        }
    }
}

// MARK: - AvatarViewParams

// 头像缓存收敛方案引入: https://bytedance.feishu.cn/docs/doccnJ7qlB0MRrDa3sqPdOmNCzd
// 与EEImageService.AvatarImageParams的区别是: AvatarImageParams是Image的大小等信息，AvatarViewParams是View的大小等信息
public struct AvatarViewParams {
    // default: .middle
    public var sizeType: SizeType
    // default: webp / heic
    public var format: ImageFileFormat

    public static var defaultThumb: AvatarViewParams {
        return AvatarViewParams(sizeType: .thumb, format: defaultFormat)
    }

    public static var defaultMiddle: AvatarViewParams {
        return AvatarViewParams(sizeType: .middle, format: defaultFormat)
    }

    public static var defaultBig: AvatarViewParams {
        return AvatarViewParams(sizeType: .big, format: defaultFormat)
    }

    public init(sizeType: SizeType = .middle,
                format: ImageFileFormat = Self.defaultFormat) {
        self.sizeType = sizeType
        self.format = format
    }

    public func size() -> CGFloat {
        let config = LarkImageService.shared.avatarConfig
        switch sizeType {
        case .size(let size): return size
        case .thumb: return CGFloat(config.dprConfigs[.thumb]?.sizeHigh ?? 0)
        case .middle: return CGFloat(config.dprConfigs[.middle]?.sizeHigh ?? 0)
        case .big: return CGFloat(config.dprConfigs[.big]?.sizeHigh ?? 0)
        }
    }

    public func transformDic() -> [String: Any] {
        var addition = [String: Any]()
        let avatarSize = Int32(size())
        addition["avatarSize"] = avatarSize
        addition["width"] = avatarSize
        addition["height"] = avatarSize
        addition["format"] = format
        return addition
    }

    public static func transform(additionMap: [String: Any]?) -> AvatarViewParams? {
        guard let additionMap else { return nil }
        var params = AvatarViewParams()
        if let format = additionMap["format"] as? ImageFileFormat {
            params.format = format
        }
        let width = additionMap["width"] as? Int32
        let height = additionMap["height"] as? Int32
        if width != nil || height != nil {
            let maxSize = max(width ?? 0, height ?? 0)
            params.sizeType = .size(CGFloat(maxSize))
        }
        return params
    }

    public static var defaultFormat: ImageFileFormat {
        LarkImageService.shared.avatarDownloadHeic ? .heic : .webp
    }
}
