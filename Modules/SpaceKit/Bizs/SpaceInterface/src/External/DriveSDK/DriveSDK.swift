//
//  DriveSDK.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2020/6/17.
//

import Foundation
import UIKit
import RxSwift
import EENavigator

public protocol DriveSDKDependency {
    var actionDependency: DriveSDKActionDependency { get }
    var moreDependency: DriveSDKMoreDependency { get }
}

// 其他业务上传完文件后调用DriveSDK保存本地缓存信息，在离线场景使用
public protocol DriveSDKCachePreviewAbilityProtocol {
    func saveCache(fileCache: [DriveSDKFileCache])
}

// 获取IM中本地文件缓存地址
public protocol DriveSDKIMLocalCacheServiceProtocol {
    func getIMCache(fileID: String, msgID: String, complete: @escaping (URL?) -> Void)
}

// 使用外部能力打开本地文件
public protocol DriveSDKLocalFilePreviewAbility {
    func openFile(from path: URL, from: NavigatorFrom)
    func previewVC(with path: URL) -> UIViewController?
}

public protocol DriveSDKLocalPreviewDependency {
    var actionDependency: DriveSDKActionDependency { get }
    var moreDependency: DriveSDKLocalMoreDependency { get }
}

// 在线文件
@available(*, deprecated, message: "use DriveSDKIMFile instead")
public struct DriveSDKOnlineFile {
    // 文件名，展示在导航栏上
    public var fileName: String
    // 文件ID
    public var fileID: String
    // 文件唯一ID，用于权限变更等协同业务
    public var uniqueID: String?
    // msgID, 转在线文档需要用到的参数
    public var msgID: String
    // 额外的鉴权信息，透传给业务放后台使用
    public var extraAuthInfo: String?
    /// 消息租户ID，CAC IM 下载管控需要使用
    public var senderTenantID: Int64?
    // 文件被加密，如 ip-garud
    public var isEncrypted: Bool
    

    public init(fileName: String,
                fileID: String,
                msgID: String,
                uniqueID: String?,
                senderTenantID: Int64?,
                extraAuthInfo: String?,
                isEncrypted: Bool) {
        self.fileName = fileName
        self.fileID = fileID
        self.msgID = msgID
        self.uniqueID = uniqueID
        self.extraAuthInfo = extraAuthInfo
        self.senderTenantID = senderTenantID
        self.isEncrypted = isEncrypted
    }
}

// IM附件信息
public struct DriveSDKIMFile {
    // 文件名，展示在导航栏上
    public var fileName: String
    // 文件ID
    public var fileID: String
    // 文件唯一ID，用于权限变更等协同业务
    public var uniqueID: String?
    // msgID, 转在线文档需要用到的参数
    public var msgID: String
    // 额外的鉴权信息，透传给业务放后台使用
    public var extraAuthInfo: String?
    /// 外部注入的预览依赖能力（更多按钮、停止预览信号等）
    public var dependency: DriveSDKDependency
    /// 消息租户ID，用于CAC IM 下载管控校验
    public var senderTenantID: Int64?
    // 文件被加密，如 ip-garud
    public var isEncrypted: Bool

    public init(fileName: String,
                fileID: String,
                msgID: String,
                uniqueID: String?,
                senderTenantID: Int64?,
                extraAuthInfo: String?,
                dependency: DriveSDKDependency,
                isEncrypted: Bool) {
        self.fileName = fileName
        self.fileID = fileID
        self.msgID = msgID
        self.uniqueID = uniqueID
        self.extraAuthInfo = extraAuthInfo
        self.dependency = dependency
        self.senderTenantID = senderTenantID
        self.isEncrypted = isEncrypted
    }
}

public struct DriveSDKIMFileBody: PlainBody {
    public static let pattern = "//client/drive/sdk/preview/imonline"
    public let file: DriveSDKIMFile
    public let appID: String
    public let naviBarConfig: DriveSDKNaviBarConfig // 导航栏样式配置
    public init(file: DriveSDKIMFile,
                appID: String,
                naviBarConfig: DriveSDKNaviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: true)) {
        self.file = file
        self.appID = appID
        self.naviBarConfig = naviBarConfig
    }
}

// 外部业务传入到DriveSDK的缓存信息
public struct DriveSDKFileCache {
    // 接入方的业务ID，比如IM为10001
    public let appID: String
    
    // 文件名，展示在导航栏上
    public let fileName: String
    
    // 文件objToken 或者 sdkFileId
    public let fileID: String
    
    // 缓存文件地址，由业务方管理缓存、DriveSDK内部会校验缓存是否可用，如果不可用
    public let localPath: String

    // 文件后缀名, 若非空则优先使用(而不是从路径中截取)
    public let fileType: String?
    
    // 文件版本信息
    public let dataVersion: String?
    
    public init(appID: String,
                fileName: String,
                fileID: String,
                uniqueID: String,
                localPath: String,
                fileType: String?,
                dataVersion: String?) {
        self.appID = appID
        self.fileName = fileName
        self.fileID = fileID
        self.localPath = localPath
        self.fileType = fileType
        self.dataVersion = dataVersion
    }
}

// 本地文件
@available(*, deprecated, message: "use DriveSDKLocalFileV2 instead")
public struct DriveSDKLocalFile {
    // 文件名，展示在导航栏标题上
    public let fileName: String
    // 文件类型，若没有则会从 filePath 截取后缀
    public let fileType: String?
    // 本地文件路径
    public let fileURL: URL
    // 用于标识文件，若需要审计则要传
    public let fileID: String?
    /// Deprecated: 更多按钮支持的选项，目前本地文件只支持使用其他应用打开（该属性未来会弃用）
    @available(*, deprecated, message: "use DriveSDKDependency.moreDependency instead")
    public var moreActions: [DriveSDKLocalMoreAction] = []
    /// 外部注入的预览依赖能力（更多按钮、停止预览信号等）
    public var dependency: DriveSDKLocalPreviewDependency
    
    @available(*, deprecated, message: "moreActions property will deprecated in feature version")
    public init(fileName: String, fileType: String?, fileURL: URL, fileID: String?, moreActions: [DriveSDKLocalMoreAction] = [.openWithOtherApp(customAction: nil)]) {
        self.fileName = fileName
        self.fileType = fileType
        self.fileURL = fileURL
        self.fileID = fileID
        self.moreActions = moreActions
        self.dependency = DriveSDKLocalPreviewDependencyDefaultImpl()
    }
    
    public init(fileName: String, fileType: String?, fileURL: URL, fileId: String?, dependency: DriveSDKLocalPreviewDependency) {
        self.fileName = fileName
        self.fileType = fileType
        self.fileURL = fileURL
        self.fileID = fileId
        self.dependency = dependency
    }
}

// 本地文件 V2
public struct DriveSDKLocalFileV2 {
    // 文件名，展示在导航栏标题上
    public let fileName: String
    // 文件类型，若没有则会从 filePath 截取后缀
    public let fileType: String?
    // 本地文件路径
    public let fileURL: URL
    // 用于标识文件唯一ID，若需要审计则要传
    public let fileID: String
    /// 外部注入的预览依赖能力（更多按钮、停止预览信号等）
    public var dependency: DriveSDKDependency
        
    public init(fileName: String,
                fileType: String?,
                fileURL: URL,
                fileId: String,
                dependency: DriveSDKDependency) {
        self.fileName = fileName
        self.fileType = fileType
        self.fileURL = fileURL
        self.fileID = fileId
        self.dependency = dependency

    }
}

public struct DriveSDKLocalFileBody: PlainBody {
    public var forcePush: Bool? = true
    public static let pattern = "//client/drive/sdk/preview/local"
    public let files: [DriveSDKLocalFileV2] // 文件信息列表, 仅支持图片文件多文件，其他文件不支持多文件预览
    public let appID: String
    public let thirdPartyAppID: String?
    public let index: Int // 当前文件Index
    public let naviBarConfig: DriveSDKNaviBarConfig // 导航栏样式配置

    public init(files: [DriveSDKLocalFileV2],
                index: Int,
                appID: String,
                thirdPartyAppID: String?,
                naviBarConfig: DriveSDKNaviBarConfig) {
        self.files = files
        self.index = index
        self.appID = appID
        self.thirdPartyAppID = thirdPartyAppID
        self.naviBarConfig = naviBarConfig
    }
}

// DriveSDK附件
public struct DriveSDKAttachmentFile {
    public let fileToken: String // 文件token
    public let hostToken: String? // 宿主token
    public let mountNodePoint: String? // optional String 父节点token，有的话就传
    public let mountPoint: String // 挂载点，mail为“email”
    public let fileType: String?
    public let name: String?
    public let version: String? // 如果文件有多版本，通过version打开对应版本文件
    public let dataVersion: String? // 如果文件存在多版本，文件发生变化，通过dataVersion区分本地文件缓存
    public let authExtra: String?
    public let urlForSuspendable: String?
    /// 外部注入的预览依赖能力（更多按钮、停止预览信号等）
    public var dependency: DriveSDKDependency
    /// DriveSDK预览过程中从业务后端返回的perm_v2信息, 是一个json, 业务方可以通过监听此状态
    /// 处理自己的逻辑
    public var handleBizPermission: (([String: Any]) -> Void)?

    public init(fileToken: String,
                hostToken: String? = nil,
                mountNodePoint: String?,
                mountPoint: String,
                fileType: String?,
                name: String?,
                version: String? = nil,
                dataVersion: String? = nil,
                authExtra: String?,
                urlForSuspendable: String? = nil,
                dependency: DriveSDKDependency) {
        self.fileToken = fileToken
        self.hostToken = hostToken
        self.mountNodePoint = mountNodePoint
        self.mountPoint = mountPoint
        self.fileType = fileType
        self.name = name
        self.version = version
        self.dataVersion = version
        self.authExtra = authExtra
        self.urlForSuspendable = urlForSuspendable
        self.dependency = dependency
    }
}

public protocol DriveSDKAttachmentDelegate: AnyObject {
    func onAttachmentClose()
    func onAttachmentSwitch(to index: Int, with fileID: String)
}

public extension DriveSDKAttachmentDelegate {
    func onAttachmentSwitch(to index: Int, with fileID: String) {}
}

public struct DriveSDKAttachmentFileBody: PlainBody {
    public static let pattern = "//client/drive/sdk/preview/thirdparty"
    public let files: [DriveSDKAttachmentFile] // 文件列表信息，目前只支持单文件预览，使用 list用于后续扩展
    public let index: Int // 当前文件index
    public let appID: String
    public let isInVCFollow: Bool // 是否在VCfollow中打开附件预览
    public let isCCMPremission: Bool // 是否使用ccm权限服务, 目前doc、sheet附件使用了ccm权限服务，其他业务使用第三方业务权限
    public var tenantID: String?
    public let naviBarConfig: DriveSDKNaviBarConfig // 导航栏样式配置
    public weak var attachmentDelegate: DriveSDKAttachmentDelegate?

    public init(files: [DriveSDKAttachmentFile],
                index: Int,
                appID: String,
                isCCMPremission: Bool = false,
                isInVCFollow: Bool = false,
                naviBarConfig: DriveSDKNaviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)) {
        self.files = files
        self.index = index
        self.appID = appID
        self.isCCMPremission = isCCMPremission
        self.isInVCFollow = isInVCFollow
        self.naviBarConfig = naviBarConfig
    }
}

public struct DriveSDKSupportOptions: OptionSet {

    // 原生支持打开
    public static let native = DriveSDKSupportOptions(rawValue: 1 << 0)
    // 后端转码后支持打开
    public static let serverTransform = DriveSDKSupportOptions(rawValue: 1 << 1)

    public let rawValue: UInt
    // 是否支持打开
    public var isSupport: Bool {
        return !isEmpty
    }
    
    // 是否支持本地打开
    public var localSupport: Bool {
        return contains(.native)
    }

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

/// 导航栏属性配置
public struct DriveSDKNaviBarConfig {
    /// 导航栏标题对齐位置
    public let titleAlignment: UIControl.ContentHorizontalAlignment
    /// 是否展示全屏按钮,在iPad下如果设置为false，不会展示左上角的全屏按钮，并且如果从全屏跳转到预览界面会退出全屏。
    public let fullScreenItemEnable: Bool
    
    public init(titleAlignment: UIControl.ContentHorizontalAlignment, fullScreenItemEnable: Bool) {
        self.titleAlignment = titleAlignment
        self.fullScreenItemEnable = fullScreenItemEnable
    }
}

// DriveSDK文件信息，用户回调给业务方，执行转发等操作
public struct DKAttachmentInfo {
    public let fileID: String
    public let name: String
    public let type: String
    public let size: UInt64
    public var localPath: URL? // 本地路径，已下载的附件才会有本地路径
    public init(fileID: String, name: String, type: String, size: UInt64, localPath: URL? = nil) {
        self.fileID = fileID
        self.name = name
        self.type = type
        self.size = size
        self.localPath = localPath
    }
    
    public var driveInfo: DriveAttachmentInfo {
        return DriveAttachmentInfo(token: fileID, name: name, type: type, size: size, localPath: localPath)
    }
}

// createSpaceFileController接口context参数的key定义
public enum DKContextKey: String {
    case from // previewFrom
    case wikiToken // 如果drive文件是wiki，需要带wikitoken
    case feedID = "feed_id" // 如果是从Lark feed打开drive，需要带feedID
    case editTimeStamp // 历史版本打开需要带编辑时间，用于显示在副标题
    case pdfPageNumber = "page" // AI分会话场景支持跳转到PDF页面
}

public protocol DriveSDK {
    typealias OnlineFile = DriveSDKOnlineFile
    typealias IMFile = DriveSDKIMFile
    typealias LocalFile = DriveSDKLocalFile
    typealias LocalFileV2 = DriveSDKLocalFileV2
    typealias AttachmentFile = DriveSDKAttachmentFile
    typealias SupportOptions = DriveSDKSupportOptions
    typealias Dependency = DriveSDKDependency
    typealias LocalDependency = DriveSDKLocalPreviewDependency
    typealias DownloadState = DriveSDKDownloadState
    typealias MoreAction = DriveSDKMoreAction
    typealias LocalFileAction = DriveSDKLocalMoreAction

    /// DriveSDK是否支持预览
    /// - Parameters:
    ///   - fileName: 文件名
    ///   - fileSize: 文件大小
    ///   - appID: 接入方 ID
    /// - Returns: 返回支持类型：1. 支持服务端转码预览；2. 本地支持预览； 3. 不支持预览
    func canOpen(fileName: String, fileSize: UInt64?, appID: String) -> SupportOptions

    /// 在线文件预览
    /// - Parameters:
    ///   - onlineFile: 在线文件信息
    ///   - from: 当前VC,用于路由跳转
    ///   - appID: 接入业务方 id，如: im 1001，小程序 1002
    ///   - dependency: 预览依赖能力，详情查看 DriveSDKDependency
    func open(onlineFile: OnlineFile, from: UIViewController, appID: String, dependency: Dependency)

    /// 本地文件预览接口
    /// - Parameters:
    ///   - localFile: 文件信息
    ///   - from: 当前的VC，用于路由跳转
    ///   - appID: 接入业务方 id，如: im 1001，小程序 1002
    ///   - thirdPartyAppID: 如：具体小程序的 appId,可以传空
    func open(localFile: LocalFile, from: UIViewController, appID: String, thirdPartyAppID: String?)
    
    /// 本地文件预览接口
    /// - Parameters:
    ///   - localFile: 文件信息
    ///   - appID: 接入业务方 id；如：im 1001，小程序 1002，密聊 1003
    ///   - thirdPartyAppID: 第三方 id；如：具体小程序的 appId,可以传空
    ///   - naviBarConfig: 导航栏配置
    /// - Returns: 预览的页面 ViewController
    func localPreviewController(for localFile: LocalFile, appID: String, thirdPartyAppID: String?, naviBarConfig: DriveSDKNaviBarConfig) -> UIViewController
    
    // MARK: - 新接口
    /// 通过push打开在线IM附件预览
    /// - Parameters:
    ///   - imFile: IM在线文件信息
    ///   - from: 当前VC,用于路由跳转
    ///   - appID: 接入业务方 id，如: im 1001，小程序 1002
    func open(imFile: IMFile, from: UIViewController, appID: String)
    /// 创建在线IM附件预览
    /// - Parameters:
    ///   - imFile: IM在线文件信息
    ///   - appID: 接入业务方 id，如: im 1001，小程序 1002
    ///   - naviBarConfig: 导航栏配置
    func createIMFileController(imFile: IMFile,
                                appID: String,
                                naviBarConfig: DriveSDKNaviBarConfig) -> UIViewController

    /// 本地文件预览接口
    /// - Parameters:
    ///   - localFile: 文件信息数组，目前只支持多图片预览，其他文件类型不支持多文件
    ///   - from: 当前的VC，用于路由跳转
    ///   - appID: 接入业务方 id，如: im 1001，小程序 1002
    ///   - thirdPartyAppID: 如：具体小程序的 appId,可以传空
    func createLocalFileController(localFiles: [LocalFileV2],
                                   index: Int,
                                   appID: String,
                                   thirdPartyAppID: String?,
                                   naviBarConfig: DriveSDKNaviBarConfig) -> UIViewController
    
    /// 第三方附件文件预览接口
    /// - Parameters:
    ///   - thirdPartyFiles: 文件信息数组，目前只支持多图片预览，其他文件类型不支持多文件
    ///   - from: 当前的VC，用于路由跳转
    ///   - appID: 接入业务方 id，如: im 1001，小程序 1002
    ///   - thirdPartyAppID: 如：具体小程序的 appId,可以传空
    ///   - thirdPartyAppID: 如：具体小程序的 appId,可以传空
    func createAttachmentFileController(attachFiles: [AttachmentFile],
                                        index: Int,
                                        appID: String,
                                        isCCMPermission: Bool,
                                        tenantID: String?,
                                        isInVCFollow: Bool,
                                        attachmentDelegate: DriveSDKAttachmentDelegate?,
                                        naviBarConfig: DriveSDKNaviBarConfig) -> UIViewController
    
    /// space云盘文件预览接口
    func createSpaceFileController(files: [AttachmentFile],
                                   index: Int,
                                   appID: String,
                                   isInVCFollow: Bool,
                                   context: [String: Any],
                                   statisticInfo: [String: String]?) -> UIViewController
    
    ///提供给外部获取圆形图标的接口
    ///- Parameters:
    ///     - fileType：文件名后缀，如：.pdf，.mp4
    func getRoundImageForDriveAccordingto(fileType: String) -> UIImage
    
    ///提供给外部获取方形图标的接口
    ///- Parameters:
    ///     - fileType：文件名后缀，如：.pdf，.mp4
    func getSquareImageForDriveAccordingto(fileType: String) -> UIImage
}

public extension DriveSDK {
    /// 第三方附件文件预览接口
    /// - Parameters:
    ///   - thirdPartyFiles: 文件信息数组，目前只支持多图片预览，其他文件类型不支持多文件
    ///   - from: 当前的VC，用于路由跳转
    ///   - appID: 接入业务方 id，如: im 1001，小程序 1002
    ///   - thirdPartyAppID: 如：具体小程序的 appId,可以传空
    ///   - thirdPartyAppID: 如：具体小程序的 appId,可以传空
    func createAttachmentFileController(attachFiles: [AttachmentFile],
                                        index: Int,
                                        appID: String,
                                        isCCMPermission: Bool,
                                        isInVCFollow: Bool,
                                        attachmentDelegate: DriveSDKAttachmentDelegate?,
                                        naviBarConfig: DriveSDKNaviBarConfig) -> UIViewController {
        createAttachmentFileController(attachFiles: attachFiles,
                                       index: index,
                                       appID: appID,
                                       isCCMPermission: isCCMPermission,
                                       tenantID: nil,
                                       isInVCFollow: isInVCFollow,
                                       attachmentDelegate: attachmentDelegate,
                                       naviBarConfig: naviBarConfig)
    }
}


// MARK: - DriveSDKLocalPreviewDependency 默认实现
public final class DriveSDKLocalPreviewDependencyDefaultImpl: DriveSDKLocalPreviewDependency {
    public var actionDependency: DriveSDKActionDependency { DriveSDKActionDependencyDefaultImpl() }
    public var moreDependency: DriveSDKLocalMoreDependency { DriveSDKLocalMoreDependencyDefaultImpl() }
    public init() {}
}

public final class DriveSDKLocalMoreDependencyDefaultImpl: DriveSDKLocalMoreDependency {
    public var moreMenuVisable: Observable<Bool> { .just(true) }
    public var moreMenuEnable: Observable<Bool> { .just(true) }
    public var actions: [DriveSDKLocalMoreAction] { [.openWithOtherApp(customAction: nil)] }
    public init() {}
}

public final class DriveSDKActionDependencyDefaultImpl: DriveSDKActionDependency {
    public var uiActionSignal: RxSwift.Observable<DriveSDKUIAction> {
        .never()
    }
    public var stopPreviewSignal: Observable<Reason> { .never() }
    public var closePreviewSignal: Observable<Void> { .never() }
    public init() {}
}
