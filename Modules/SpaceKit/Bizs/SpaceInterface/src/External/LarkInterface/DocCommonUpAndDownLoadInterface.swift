//
//  DocCommonUpAndDownLoadInterface.swift
//  SpaceInterface
//
//  Created by maxiao on 2019/8/6.
//
// nolint: long parameters

import Foundation
import RxSwift

public enum DocCommonDownloadStatus: Int {
    case pending
    case inflight
    case failed
    case success
    case queue
    case ready
    case cancel

    public init() {
        self = .pending
    }
}

/// 下载优先级
///
/// 优先级背景描述
/// 1. Rust 下载是多线程处理的，但是文件任务是按照队列（FIFO）执行，一次只能下载一个文件。
/// 2. 上传和下载是单独的队列，互相不会有影响。
/// 3. 队列支持优先级处理，高优先级会挂起低优先级任务，等待高优先级任务完成后，排队的低优先级任务会自动恢复。
public enum DocCommonDownloadPriority: Equatable {
    /// 用户正在交互，优先级最高
    public static let userInteraction = Self.custom(priority: 10)
    /// 较高优先级
    public static let defaultHigh = Self.custom(priority: 5)
    /// 默认优先级
    public static let `default` = Self.custom(priority: 0)
    /// 较低优先级
    public static let defaultLow = Self.custom(priority: -5)
    /// 后台任务最低优先级
    public static let background = Self.custom(priority: -10)

    case custom(priority: Int32)

    public var rawValue: Int32 {
        switch self {
        case let .custom(priority):
            return priority
        }
    }
}


/// 下载类型
///
/// 背景：Drive 后端推动预览和下载分离，详见 https://bytedance.feishu.cn/docs/doccnijDerAVs9sghKdtuGT5U7f
/// originFile : 原始文件，用户上传到后端的文件，“第三方附件打开”使用等需要严格要求原始文件的场景
/// previewFile: 相似文件，后端做了转码或者修改部分内容的文件，check sum可能和原始文件不同，用于预览场景
/// image：解决文档中下载大量图片触发频控
/// cover: 缩略图

public enum DocCommonDownloadType: Equatable {
    case originFile
    case previewFile
    case image
    //缩略图宽高数据，因为 Rust 层最终是 Int32 类型，这里也使用 Int 类型
    case cover(width: Int, height: Int, policy: DocCommonDownloadPolicy)

    public init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .originFile
        case 1:
            self = .previewFile
        case 2:
            self = .image
        case 3:
            self = .defaultCover
        case CoverType.middleUp.rawValue:
            self = .middleUp
        case CoverType.middle.rawValue:
            self = .middle
        case CoverType.smallUp.rawValue:
            self = .smallUp
        case CoverType.small.rawValue:
            self = .small
        default:
            return nil
        }
    }

    //和安卓对齐，默认下载1280*1280大小的缩略图
    public static let defaultCover = Self.cover(width: CoverType.big.rawValue, height: CoverType.big.rawValue, policy: .equal)
    public static let bigCover = defaultCover
    public static let middleUp = Self.cover(width: CoverType.middleUp.rawValue, height: CoverType.middleUp.rawValue, policy: .allowUp)
    public static let middle = Self.cover(width: CoverType.middle.rawValue, height: CoverType.middle.rawValue, policy: .allowUp)
    public static let smallUp = Self.cover(width: CoverType.smallUp.rawValue, height: CoverType.smallUp.rawValue, policy: .allowUp)
    public static let small = Self.cover(width: CoverType.small.rawValue, height: CoverType.small.rawValue, policy: .allowUp)

    public var rawValue: Int {
        switch self {
        case .originFile:
            return 0
        case .previewFile:
            return 1
        case .image:
            return 2
        case .cover(let width, _, _):
            if width == CoverType.big.rawValue {
                return 3 //不改变原来的
            } else {
                return width
            }
        }
    }

    public var typeString: String {
        switch self {
        case .originFile:
            return "originFile"
        case .previewFile:
            return "previewFile"
        case .image:
            return "image"
        case .cover:
            return "cover"
        }
    }
}

public enum CoverType: Int {
    case big = 1280
    case middleUp = 850
    case middle = 720
    case smallUp = 480
    case small = 360
}

public enum DocCommonDownloadPolicy: String {
    case equal = "equal" // 精准匹配尺寸，找不到就返回原图，默认值
    case near = "near" // 返回最接近的结果
    case allowUp = "allow_up" // 返回图片要求大于等于请求size的最接近结果
    case allowDown = "allow_down" // 返回图片要求小于等于请求size的最接近结果
    case allowUpDefault = "allow_up_default" // allow_up策略无满足时返回最大封面
    case allowDownDefault = "allow_down_default" // allow_down策略无满足时返回最小封面
}

public struct DocCommonDownloadRequestContext {
    // 文件 Token
    public let fileToken: String
    // 挂载点的 Token，文档中的图片则传文档Token
    public let mountNodePoint: String
    // 节点信息
    public let mountPoint: String
    // 优先级
    public let priority: DocCommonDownloadPriority
    // 下载类型
    public let downloadType: DocCommonDownloadType
    //文档token
    public let docToken: String
    //文档类型
    public let docType: Int32?
    // 下载路径， 如果传nil，DriveCacheService会根据fileToken和downlaodType生成本地下载路径并将文件存储到DriveCacheService中， 目前CCM内部业务不传路径信息
    // 如果不为nil, 文件将被下载到指定路径，外部业务需要传递localPath，文件信息不会存在DriveCacheService中
    public let localPath: String?

    public let isManualOffline: Bool

    public let authExtra: String?
    
    // 如果是附件的封面图，需要传
    public let dataVersion: String? // 文件版本
    public let originFileSize: UInt64? // 文件原始大小，非缩略图大小
    public let fileName: String? // 文件名
    // 默认开启cdn下载，对于小文件可以选择关闭cdn下载减少一次请求
    public let disableCdn: Bool
    
    public let disableCoverRetry: Bool
    /// 埋点参数
    public let teaParams: [String: String]

    public init(fileToken: String,
                docToken: String = "",
                docType: Int32? = nil,
                mountNodePoint: String,
                mountPoint: String,
                priority: DocCommonDownloadPriority,
                downloadType: DocCommonDownloadType,
                localPath: String?,
                isManualOffline: Bool,
                authExtra: String? = nil,
                dataVersion: String? = nil,
                originFileSize: UInt64? = nil,
                fileName: String? = nil,
                disableCdn: Bool = false,
                disableCoverRetry: Bool = false,
                teaParams: [String: String] = [:]) {
        self.fileToken = fileToken
        self.docToken = docToken
        self.docType = docType
        self.mountNodePoint = mountNodePoint
        self.mountPoint = mountPoint
        self.priority = priority
        self.downloadType = downloadType
        self.localPath = localPath
        self.isManualOffline = isManualOffline
        self.authExtra = authExtra
        self.dataVersion = dataVersion
        self.originFileSize = originFileSize
        self.fileName = fileName
        self.disableCdn = disableCdn
        self.disableCoverRetry = disableCoverRetry
        self.teaParams = teaParams
    }
}

public struct DocCommonDownloadResponseContext {
    // 请求信息
    public let requestContext: DocCommonDownloadRequestContext
    // 下载状态
    public let downloadStatus: DocCommonDownloadStatus
    // 下载进度（已完成的字节，总共的字节）
    public let downloadProgress: (Float, Float)
    // 错误码
    public let errorCode: Int
    
    public let key: String
    
    public let localFilePath: String
    
    public let fileName: String
    
    public let fileType: String

    public init(requestContext: DocCommonDownloadRequestContext,
                downloadStatus: DocCommonDownloadStatus,
                downloadProgress: (Float, Float),
                errorCode: Int = -1,
                key: String,
                localFilePath: String,
                fileName: String,
                fileType: String) {
        self.requestContext = requestContext
        self.downloadStatus = downloadStatus
        self.downloadProgress = downloadProgress
        self.errorCode = errorCode
        self.key = key
        self.localFilePath = localFilePath
        self.fileName = fileName
        self.fileType = fileType
    }
    
    public static func initailResponseContext(with request: DocCommonDownloadRequestContext, key: String) -> DocCommonDownloadResponseContext {
        return DocCommonDownloadResponseContext(requestContext: request,
                                                downloadStatus: .pending,
                                                downloadProgress: (0.0, 0.0),
                                                errorCode: -1, key: key,
                                                localFilePath: "", fileName: "", fileType: "")
    }
}

public protocol DocCommonDownloadProtocol {

    func download(with context: DocCommonDownloadRequestContext) -> Observable<DocCommonDownloadResponseContext>

    func download(with contexts: [DocCommonDownloadRequestContext]) -> Observable<DocCommonDownloadResponseContext>

    func downloadNormal(remoteUrl: String, localPath: String, priority: DocCommonDownloadPriority) -> Observable<DocCommonDownloadResponseContext>

    func cancelDownload(key: String) -> Observable<Bool>
}

///////////////////////////////////////////////////////////////
public protocol DocCommonFile {
    var commonKey: String { get }
    var commonFileName: String { get }
    var commonType: String { get }
}

public enum DocCommonUploadStatus: Int {
    case pending
    case inflight
    case failed
    case success
    case queue
    case ready
    case cancel

    public init() {
        self = .pending
    }
}

/// 上传下载错误码定义
public enum DocCommonUploadErrorCode: Int {
    case offline = 1007
}
/// 上传优先级
///
/// 优先级背景描述
/// 1. Rust 上传是多线程处理的，但是文件任务是按照队列（FIFO）执行，一次只能上传一个文件。
/// 2. 上传和下载是单独的队列，互相不会有影响。
/// 3. 队列支持优先级处理，高优先级会挂起低优先级任务，等待高优先级任务完成后，排队的低优先级任务会自动恢复。
public enum DocCommonUploadPriority: Equatable {
    /// 用户正在交互，优先级最高
    public static let userInteraction = Self.custom(priority: 10)
    /// 较高优先级
    public static let defaultHigh = Self.custom(priority: 5)
    /// 默认优先级
    public static let `default` = Self.custom(priority: 0)
    /// 较低优先级
    public static let defaultLow = Self.custom(priority: -5)
    /// 后台任务最低优先级
    public static let background = Self.custom(priority: -10)

    case custom(priority: Int32)

    public var rawValue: Int32 {
        switch self {
        case let .custom(priority):
            return priority
        }
    }
}

public protocol DocCommonUploadProtocol {
    // 如果启动后马上调用上传，需要等待ready为true
    var ready: Observable<Bool> { get }
    /// 参数
    /// copyInsteadMoveAfterSuccess: true 则上传成功后拷贝到 Drive 缓存目录中，而非移动，需接入方自行删除临时文件
    /// 返回值
    /// 1. uploadKey: 此次上传任务的token，可以用来cancel、resume、delete上传任务
    /// 2. progress: 上传进度百分比
    /// 3. objToken: 文档token
    /// 4. uploadStatus: 状态
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                copyInsteadMoveAfterSuccess: Bool,
                priority: DocCommonUploadPriority) -> Observable<(String, Float, String, DocCommonUploadStatus)>

    /// 参数
    /// extra: 鉴权等额外参数, 不需要的话就直接传 nil
    /// 返回值: 同上
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                copyInsteadMoveAfterSuccess: Bool,
                priority: DocCommonUploadPriority,
                extra: [String: String]?) -> Observable<(String, Float, String, DocCommonUploadStatus)>

    /// 参数
    /// uploadCode: 部分业务场景无法获取到mountNodePoint， 只能通过uploadCode进行上传。
    /// 返回值: 同上
    func upload(localPath: String,
                fileName: String,
                mountPoint: String,
                uploadCode: String,
                copyInsteadMoveAfterSuccess: Bool,
                priority: DocCommonUploadPriority) -> Observable<(String, Float, String, DocCommonUploadStatus)>
    func cancelUpload(key: String) -> Observable<Bool>
    func resumeUpload(key: String, copyInsteadMoveAfterSuccess: Bool) -> Observable<(String, Float, String, DocCommonUploadStatus)>
    func resumeUpload(key: String) -> Observable<Bool>
    func deleteUploadResource(key: String) -> Observable<Bool>
}

public extension DocCommonUploadProtocol {
    /// 使用默认优先级上传文件
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String) -> Observable<(String, Float, String, DocCommonUploadStatus)> {
        return upload(localPath: localPath,
                      fileName: fileName,
                      mountNodePoint: mountNodePoint,
                      mountPoint: mountPoint,
                      copyInsteadMoveAfterSuccess: false,
                      priority: .default)
    }
    // 超大附件上传新增extra
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                extra: [String: String]?) -> Observable<(String, Float, String, DocCommonUploadStatus)> {
        return upload(localPath: localPath,
                    fileName: fileName,
                    mountNodePoint: mountNodePoint,
                    mountPoint: mountPoint,
                    copyInsteadMoveAfterSuccess: false,
                    priority: .default,
                    extra: extra)
    }
    func upload(localPath: String,
                fileName: String,
                mountPoint: String,
                uploadCode: String) -> Observable<(String, Float, String, DocCommonUploadStatus)> {
        return upload(localPath: localPath,
                      fileName: fileName,
                      mountPoint: mountPoint,
                      uploadCode: uploadCode,
                      copyInsteadMoveAfterSuccess: false,
                      priority: .default)
    }
}
