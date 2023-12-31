//
//  SpaceInterface+drive.swift
//  SpaceInterface
//
//  Created by huangzhikai on 2023/4/11.
//  从DriveDefines和DriveInterface迁移过来的

import Foundation
import RxSwift
import RxRelay
import RustPB

public typealias DriveUploadRequest = Space_Drive_V1_UploadRequest
public typealias DriveUploadScene = Space_Drive_V1_UploadScene
public typealias DriveUploadCallbackStatus = Space_Drive_V1_PushUploadCallback.Status
public typealias DriveDownloadCallbackStatus = Space_Drive_V1_PushDownloadCallback.Status

/// DriveRustRouter.DownloadPriority
/// 下载优先级
///
/// 优先级背景描述
/// 1. Rust 下载是多线程处理的，但是文件任务是按照队列（FIFO）执行，一次只能下载一个文件。
/// 2. 上传和下载是单独的队列，互相不会有影响。
/// 3. 队列支持优先级处理，高优先级会挂起低优先级任务，等待高优先级任务完成后，排队的低优先级任务会自动恢复。
public enum DriveDownloadPriority: Equatable {
    /// 用户正在交互，如第三方打开，优先级最高
    public static let userInteraction = Self.custom(priority: 10)
    /// 当前预览文件，较高优先级
    public static let preview = Self.custom(priority: 5)
    /// 默认优先级
    public static let `default` = Self.custom(priority: 0)
    /// 手动离线低优先级
    public static let manualOffline = Self.custom(priority: -5)
    /// 预加载最低优先级
    public static let preload = Self.custom(priority: -10)

    case custom(priority: Int32)

    public var rawValue: Int32 {
        switch self {
        case let .custom(priority):
            return priority
        }
    }
}

///DriveRustRouter.UploadPriority
/// 上传优先级
///
/// 优先级背景描述
/// 1. Rust 上传是多线程处理的，但是文件任务是按照队列（FIFO）执行，一次只能上传一个文件。
/// 2. 上传和下载是单独的队列，互相不会有影响。
/// 3. 队列支持优先级处理，高优先级会挂起低优先级任务，等待高优先级任务完成后，排队的低优先级任务会自动恢复。
public enum DriveUploadPriority: Equatable {
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

// MARK: - DriveDownload Callback
public struct DriveDownloadContext {
    public let key: String
    public let status: DriveDownloadCallbackStatus
    public let bytesTransferred: Int64
    public let bytesTotal: Int64
    public let mountPoint: String
    public let fileToken: String
    public let fileName: String
    public let fileType: String
    public let filePath: String

    public init(callback: Space_Drive_V1_PushDownloadCallback) {
        key = callback.key
        status = callback.status
        bytesTransferred = Int64(callback.bytesTransferred) ?? 0
        bytesTotal = Int64(callback.bytesTotal) ?? 0
        mountPoint = callback.mountPoint
        fileToken = callback.fileToken
        fileName = callback.fileName
        fileType = callback.fileType
        filePath = callback.filePath
    }
}

public protocol DriveDownloadCallback {

    func updateProgress(context: DriveDownloadContext)

    func onFailed(key: String,
                  errorCode: Int)

}

// MARK: - DriveUpload Callback
public struct DriveUploadContext {
    public let key: String
    public let status: DriveUploadCallbackStatus
    public let bytesTransferred: Int64
    public let bytesTotal: Int64
    public let fileToken: String
    public let fileName: String
    public let filePath: String
    // 仅在上传完成之后才能获取到dataVersion
    public let dataVersion: String
    public let mountPoint: String
    public let mountNodePoint: String
    // 节点token，比如上传到wiki，nodeToken为wiki节点的token
    public let nodeToken: String
    // 上传场景，目前wiki的上传场景为.wiki， 其他为.unknown
    public let scene: DriveUploadScene

    public init(callback: Space_Drive_V1_PushUploadCallback) {
        key = callback.key
        status = callback.status
        bytesTransferred = Int64(callback.bytesTransferred) ?? 0
        bytesTotal = Int64(callback.bytesTotal) ?? 0
        fileToken = callback.fileToken
        fileName = callback.extraInfo.fileName
        filePath = callback.filePath
        dataVersion = callback.dataVersion
        mountPoint = callback.mountPoint
        mountNodePoint = callback.mountNodePoint
        nodeToken = callback.extraInfo.nodeToken
        scene = callback.scene
    }
}

public protocol DriveUploadCallback {
    func updateProgress(context: DriveUploadContext)
    func onFailed(key: String,
                  mountPoint: String,
                  scene: DriveUploadScene,
                  errorCode: Int,
                  fileSize: Int64)
}


/// 上传请求参数
///
/// - Parameters:
///   - localPath: 上传文件路径
///   - fileName: 文件名
///   - mountNodePoint: 父节点，对于Drive文件是文件夹，为空是传到“我的空间”；对于Doc，是文件的token;
///   - mountPoint: 挂载点，Drive文件一般是"explorer"；或者业务端定义参见：
///   - uploadCode: 某些业务场景无法获取到mountNodePoint, 只能通过业务后台返回的uploadCode进行上传，如果使用uploadCode, 则mountNodePoint传空字符串
///   - scene: 区分场景，可以通过scene获取不同场景的上传任务，默认为unknown
///   - objType: DocsType 的值
///   - apiType: 见 ApiType 定义
///   - extRust: 传给 Rust 的参数
public struct DriveUploadRequestContext {
    public let localPath: String
    public let fileName: String
    public let mountNodePoint: String
    public let mountPoint: String
    public let uploadCode: String?
    public let scene: DriveUploadScene
    public let objType: Int32?
    public let apiType: DriveUploadRequest.ApiType?
    public let priority: DriveUploadPriority
    public let extraParams: [String: String]
    public let extRust: [String: String]

    // nolint-next-line: long parameters
    public init(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                uploadCode: String?,
                scene: DriveUploadScene,
                objType: Int32?,
                apiType: DriveUploadRequest.ApiType?,
                priority: DriveUploadPriority,
                extraParams: [String: String],
                extRust: [String: String]) {
        self.localPath = localPath
        self.fileName = fileName
        self.mountNodePoint = mountNodePoint
        self.mountPoint = mountPoint
        self.uploadCode = uploadCode
        self.scene = scene
        self.objType = objType
        self.apiType = apiType
        self.priority = priority
        self.extraParams = extraParams
        self.extRust = extRust
    }
}

// MARK: - DriveRustRouterBase
public protocol DriveRustRouterBase: AnyObject {

    var mainMountPointTokenString: String { get }
    var driveInitFinishObservable: BehaviorRelay<Bool> { get }

    /// 根据URL下载文件
    ///
    /// - Parameters:
    ///   - remoteUrl: 远程下载地址
    ///   - localPath: 本地路径
    ///   - priority: 下载优先级 不传默认为0， 低优先级传小于0的数值
    ///   - slice: 是否启动分片下载，可以实现缓存下载，需要后台支持http range。
    /// - Returns: key
    func downloadNormal(remoteUrl: String,
                        localPath: String,
                        fileSize: String?,
                        slice: Bool,
                        priority: DriveDownloadPriority) -> Observable<String>
    /// 根据fileToken下载文件
    ///
    /// - Parameters:
    ///   - localPath: 本地路径
    ///   - fileToken: 文件token
    ///   - mountNodePoint: 父节点，没有可传空，传空则进入“我的空间”；文档中的图片则为文档token
    ///   - mountPoint: 挂载点 "explorer"
    /// - Returns: key
    func downloadfile(localPath: String,
                      fileToken: String,
                      mountNodePoint: String,
                      mountPoint: String) -> Observable<String>

    func upload(context: DriveUploadRequestContext) -> Observable<String>

    func cancelDownload(key: String) -> Observable<Int>
    func cancelUpload(key: String) -> Observable<Int>
    func resumeUpload(key: String) -> Observable<Int>
    func deleteUploadResource(key: String) -> Observable<Int>
}

public protocol DriveDownloadCallbackServiceBase: AnyObject {
    func addObserver(_ delegate: AnyObject)
}

// MARK: - DriveShadowFileManagerProtocol
public protocol DriveShadowFileManagerProtocol {
    var fileIdParamKey: String { get }
    func getMoreItemState(id: String) -> (enabled: BehaviorRelay<Bool>, visable: BehaviorRelay<Bool>)
    func showMorePanel(id: String, from: UIViewController, sourceView: UIView?, sourceRect: CGRect?)
    func removeShadowFile(id: String)
}
