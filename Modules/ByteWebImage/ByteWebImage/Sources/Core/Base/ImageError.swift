//
//  ImageError.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/22.
//

import Foundation

public enum ImageErrorCode: Int {
    public typealias RawValue = Int

    case userCancelled = -4_100_999
    case badImageURL = -4_401_000
    case badImageData = -44_900_001
    case emptyImage = -44_900_002
    case internalError = -43_900_003
    case overFlowExpectedSize = -42_900_004
    case awebpInvalid = -44_900_005
    case awebpConvertToGIfDataError = -44_900_006
    case skipDecodeGIFDueToMemoryError = -44_900_007
    case skipDecodeLargeGIFError = -44_900_008
    case checkTypeError = -42_900_007
    case checkLength = -42_900_008
    case srError = -44_900_009
    case zeroByte = -4_201_014
    case timedOut = -1001 /* NSURLErrorTimedOut */
    case unknown = -49_999_999
    case notSupportRust = -44_900_010
    case notSupportCustomDownloader = -44_900_011
    case requestFailed = -42_900_012
    case tiledFailed = -44_900_013
}

// swiftlint:disable operator_usage_whitespace
public typealias ByteWebImageErrorCode = Int
/// 用户主动取消 -999
public let ByteWebImageErrorUserCancelled                 = ImageErrorCode.userCancelled.rawValue
/// URL错误导致初始化请求失败 -1000
public let ByteWebImageErrorBadImageUrl                   = ImageErrorCode.badImageURL.rawValue
/// 返回数据不能解析
public let ByteWebImageErrorBadImageData                  = ImageErrorCode.badImageData.rawValue
/// 解析完成图片为空像素
public let ByteWebImageErrorEmptyImage                    = ImageErrorCode.emptyImage.rawValue
/// 内部逻辑错误
public let ByteWebImageErrorInternalError                 = ImageErrorCode.internalError.rawValue
/// 当开启渐进式下载，而且接收到的数据大于kHTTPResponseContentLength时报错
public let ByteWebImageErrorOverFlowExpectedSize          = ImageErrorCode.overFlowExpectedSize.rawValue
/// awebp格式校验错误
public let ByteWebImageErrorAwebpInvalid                  = ImageErrorCode.awebpInvalid.rawValue
/// webp动图转gif二进制错误
public let ByteWebImageErroraAwebpConvertToGIfDataError   = ImageErrorCode.awebpConvertToGIfDataError.rawValue
/// 内存不足时不解码 GIF
public let ByteWebImageErrorSkipDecodeGIFDueToMemoryError = ImageErrorCode.skipDecodeGIFDueToMemoryError.rawValue
/// 超大 GIF 不解码
public let ByteWebImageErrorSkipDecodeLargeGIFError       = ImageErrorCode.skipDecodeLargeGIFError.rawValue
/// 图片下载检查类型错误
public let ByteWebImageErrorCheckTypeError                = ImageErrorCode.checkTypeError.rawValue
/// 图片下载检查 data 长度
public let ByteWebImageErrorCheckLength                   = ImageErrorCode.checkLength.rawValue
/// 图片超分失败
public let ByteWebImageErrorSrEroor                       = ImageErrorCode.srError.rawValue
/// NSURLErrorZeroByteResource
public let ByteWebImageErrorZeroByte                      = ImageErrorCode.zeroByte.rawValue
/// 超时
public let ByteWebImageErrorTimeOut                       = ImageErrorCode.timedOut.rawValue
/// 未知错误
public let ByteWebImageErrorUnkown                        = ImageErrorCode.unknown.rawValue
/// Rust协议不支持
public let ByteWebImageErrorNotSupportRust                = ImageErrorCode.notSupportRust.rawValue
/// 自定义Downloader不支持
public let ByteWebImageErrorNotSupportCustomDownloader    = ImageErrorCode.notSupportCustomDownloader.rawValue
/// 请求失败
public let ByteWebImageErrorRequestFailed                 = ImageErrorCode.requestFailed.rawValue
/// 超大图分片加载失败
public let ByteWebImageTiledFailed                        = ImageErrorCode.tiledFailed.rawValue
// swiftlint:enable operator_usage_whitespace

public typealias ByteWebImageError = ImageError

public struct ImageError: Error {

    public var code: ByteWebImageErrorCode

    public var userInfo: [String: String]

    public enum UserInfoKey {
        /// 缓存类型
        public static let cacheType = "cache_type"
        /// Data 的 CRC32 校验码
        public static let dataHash = "resource_hash"
        /// Data 前 16 bytes 的 Hex 字符串
        public static let dataFormatHeader = "format_header"
        /// Data 长度
        public static let dataLength = "resource_content_length"
        /// 解码 GIF 尺寸
        public static let gifSize = "gif_size"
        /// 解码 GIF 时可用内存
        public static let decodeGIFAvailableMemory = "decode_gif_available_memory"
        /// 解码 GIF 所需内存
        public static let decodeGIFCostMemory = "decode_gif_cost_memory"
        /// 当前图片下标
        public static let decodeIndex = "decode_index"
        /// `error_status` 透传SDK的值，一般用于上报网络库的错误
        public static let errorStatus = "error_status"
        /// Context ID
        static let contextID = "log_id"
        // errorType取值：native or sdk，用来区分是SDK报错还是端上报错
        static let errorType = "error_type"
    }

    public var localizedDescription: String {
        self.userInfo[NSLocalizedDescriptionKey] ?? ""
    }

    public init(_ code: ImageErrorCode.RawValue, userInfo: [String: String] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public init(_ code: ImageErrorCode.RawValue, description: String) {
        self.code = code
        self.userInfo = [NSLocalizedDescriptionKey: description]
    }

    public init(_ code: ImageErrorCode, userInfo: [String: String] = [:]) {
        self.init(code.rawValue, userInfo: userInfo)
    }

    public init(_ code: ImageErrorCode, description: String) {
        self.init(code.rawValue, description: description)
    }

    public static func error(_ error: Error, defaultCode: ByteWebImageErrorCode) -> Self {
        if let error = error as? Self {
            return error
        }
        return ImageError(defaultCode, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription,
                                                  "nserror_code": "\((error as NSError).code)"])
    }
}

// MARK: - 新版本添加错误

// swiftlint:disable number_separator

// 使用6位数字表示错误编号
// 49 作为开头
// 01 表示 Codable，02 表示 Cache，03 表示 Manager，04 表示 xxx

// MARK: - Common

extension ImageError {

    /// 图片地址错误
    static func badImageURL(_ description: String = "Empty Image URL.") -> ImageError {
        ImageError(ImageErrorCode.badImageURL, description: description)
    }

    /// 图片数据错误
    static func badImageData(_ description: String = "Empty Image Data.") -> ImageError {
        ImageError(ImageErrorCode.badImageData, description: description)
    }
}

// MARK: - Decoder

extension ImageErrorCode {

    public enum Decoder {

        public static let formatNotSupport: RawValue = 49_01_01

        public static let invalidData: RawValue = 49_01_02

        public static let invalidIndex: RawValue = 49_01_03

        public static let invalidImageProperties: RawValue = 49_01_04

        public static let hugeAnimatedImage: RawValue = 49_01_05

        public static let insufficientMemory: RawValue = 49_01_06
    }
}

extension ImageError {

    enum Decoder {

        /// 不支持的格式
        static var formatNotSupport: ImageError {
            ImageError(ImageErrorCode.Decoder.formatNotSupport, description: "File Format Not Support.")
        }

        /// 无效数据
        static var invalidData: ImageError {
            ImageError(ImageErrorCode.Decoder.invalidData, description: "Data is invalid.")
        }

        /// 无效位置
        static func invalidIndex(_ index: Int) -> ImageError {
            ImageError(ImageErrorCode.Decoder.invalidIndex,
                       userInfo: [NSLocalizedDescriptionKey: "Index is Invalid",
                                  ImageError.UserInfoKey.decodeIndex: "\(index)"])
        }

        /// 无效图片参数
        static func invalidImageProperties(_ index: Int) -> ImageError {
            ImageError(ImageErrorCode.Decoder.invalidImageProperties,
                       userInfo: [NSLocalizedDescriptionKey: "Image Properties is Invalid",
                                  ImageError.UserInfoKey.decodeIndex: "\(index)"])
        }

        /// 超大动图不解码
        static func hugeAnimatedImage<T: LosslessStringConvertible>(_ size: T) -> ImageError {
            ImageError(ImageErrorCode.Decoder.hugeAnimatedImage,
                       userInfo: [NSLocalizedDescriptionKey: "Animated Image is Huge.",
                                  ImageError.UserInfoKey.gifSize: String(size)])
        }

        /// 内存空间不足
        static func insufficientMemory<T: LosslessStringConvertible, U: LosslessStringConvertible>(_ availableSize: T, _ requiredSize: U) -> ImageError {
            ImageError(ImageErrorCode.Decoder.insufficientMemory,
                       userInfo: [NSLocalizedDescriptionKey: "Insufficient Memory.",
                                  ImageError.UserInfoKey.decodeGIFAvailableMemory: String(availableSize),
                                  ImageError.UserInfoKey.decodeGIFCostMemory: String(requiredSize)])
        }
    }
}
