//
//  LarkInterface+File.swift
//  LarkInterface
//
//  Created by ChalrieSu on 2018/6/29.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//
// LarkFile对外提供服务接口。 接口的实现在 LarkFile+Component.swift中

import UIKit
import Foundation
import LarkModel
import RxSwift
import EENavigator
import LarkFoundation
import LarkContainer
import RustPB
import LarkSDKInterface
import LarkStorage

public protocol DriveSDKFileDependency {
    func canOpenSDKPreview(fileName: String, fileSize: Int64) -> Bool
    func openSDKPreview(
        message: Message,
        chat: Chat?,
        fileInfo: FileContentBasicInfo?,
        from: NavigatorFrom,
        supportForward: Bool,
        canSaveToDrive: Bool,
        browseFromWhere: FileBrowseFromWhere
    )
    func getLocalPreviewController(fileName: String, fileType: String?, fileUrl: URL, fileID: String, messageId: String) -> UIViewController
    /*
     利用DriveSDK提供的能力打开本地文件预览页。
     fileName: 文件名
     fileType: 文件类型，传nil则从fileName中截取
     fileUrl: 本地文件路径
     appID: 业务在DriveSDK的唯一标识，如小程序是1002， 密聊附件1003， 新增业务和drive同学申请新的appid
     from: FromVC
    */
    func driveSDKPreviewLocalFile(fileName: String, fileUrl: URL, appID: String, from: NavigatorFrom)
}

public protocol AskOwnerDependency {
    func openAskOwnerView(body: AskOwnerBody, from: UIViewController?)
}

public protocol DocPermissionDependency: AnyObject {
    func deleteCollaborators(type: Int,
                             token: String,
                             ownerID: String,
                             ownerType: Int,
                             permType: Int,
                             complete: @escaping (Swift.Result<Void, Error>) -> Void)
}

public struct AskOwnerBody: CodablePlainBody {
    public static let pattern = "//client/docs/ask_owner"

    public var collaboratorID: String
    public var ownerName: String?
    public var ownerID: String?
    public var needPopover: Bool
    public var docsType: Int
    public var objToken: String
    public var imageKey: String
    public var title: String
    public var detail: String
    public var isExternal: Bool
    public var isCrossTenanet: Bool
    public var roleType: Int

    public init(collaboratorID: String,
                ownerName: String?,
                ownerID: String?,
                docsType: Int,
                objToken: String,
                imageKey: String,
                title: String,
                detail: String,
                isExternal: Bool = false,
                isCrossTenanet: Bool = false,
                needPopover: Bool = false,
                roleType: Int) {
        self.collaboratorID = collaboratorID
        self.ownerName = ownerName
        self.ownerID = ownerID
        self.docsType = docsType
        self.objToken = objToken
        self.imageKey = imageKey
        self.title = title
        self.detail = detail
        self.isExternal = isExternal
        self.isCrossTenanet = isCrossTenanet
        self.roleType = roleType
        self.needPopover = needPopover
    }
}

public struct FolderFirstLevelInformation {
    public let key: String
    public let authToken: String?
    public let authFileKey: String
    public let name: String
    public let size: Int64

    public init(key: String, authToken: String?, authFileKey: String, name: String, size: Int64) {
        self.key = key
        self.authToken = authToken
        self.authFileKey = authFileKey
        self.name = name
        self.size = size
    }
}

public struct FolderManagementBody: Body {
    private static let prefix = "//client/folder/message/management"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:messageId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(Self.prefix)/\(messageId)") ?? .init(fileURLWithPath: "")
    }

    public let message: Message?
    public let messageId: String
    public let scene: FileSourceScene
    public let downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    public let chatFromTodo: Chat?
    /// 从哪一层开始进行预览，不传默认最上层
    public let firstLevelInformation: FolderFirstLevelInformation?

    public var isOpeningInNewScene: Bool = false //是否是分屏打开
    // 消息链接化场景无权限时（如单聊时转发出去的无权限消息链接）可能拉不到chat，使用内存中的Chat
    public var useLocalChat: Bool = false
    // Office文件类型的鉴权涉及其他业务，消息链接化场景暂时屏蔽Office文件类型的点击事件（三端对齐）
    public let canFileClick: ((_ fileName: String) -> Bool)?
    // 是否支持跳转到会话
    public let canViewInChat: Bool
    // 是否能转发
    public let canForward: Bool
    // 是否支持搜索
    public let canSearch: Bool
    // 是否能保存到云空间
    public let canSaveToDrive: Bool

    public init(message: Message? = nil,
                messageId: String? = nil,
                scene: FileSourceScene,
                downloadFileScene: RustPB.Media_V1_DownloadFileScene? = nil,
                chatFromTodo: Chat? = nil,
                firstLevelInformation: FolderFirstLevelInformation? = nil) {
        self.init(message: message,
                  messageId: messageId,
                  scene: scene,
                  downloadFileScene: downloadFileScene,
                  chatFromTodo: chatFromTodo,
                  firstLevelInformation: firstLevelInformation,
                  canViewInChat: true,
                  canForward: true,
                  canSearch: true,
                  canSaveToDrive: true)
    }

    public init(message: Message? = nil,
                messageId: String? = nil,
                scene: FileSourceScene,
                downloadFileScene: RustPB.Media_V1_DownloadFileScene? = nil,
                chatFromTodo: Chat? = nil,
                firstLevelInformation: FolderFirstLevelInformation? = nil,
                useLocalChat: Bool = false,
                canFileClick: ((_ fileName: String) -> Bool)? = nil,
                canViewInChat: Bool,
                canForward: Bool,
                canSearch: Bool,
                canSaveToDrive: Bool) {
        self.message = message
        self.messageId = (messageId ?? message?.id) ?? ""
        self.scene = scene
        self.downloadFileScene = downloadFileScene
        self.chatFromTodo = chatFromTodo
        self.firstLevelInformation = firstLevelInformation
        self.useLocalChat = useLocalChat
        self.canFileClick = canFileClick
        self.canViewInChat = canViewInChat
        self.canForward = canForward
        self.canSearch = canSearch
        self.canSaveToDrive = canSaveToDrive
    }
}

// 文件来源
public enum FileBrowseFromWhere {
    public static let FileFavoriteKey: String = "FileFavoriteKey" /// 收藏里的消息携带 favorite id
    public static let DownloadFileSceneKey: String = "DownloadFileSceneKey" /// 文件资源下载时需要携带
    case file(extra: [String: Any]) /// 文件类型消息携带
    case folder(extra: [String: Any]) /// 文件夹类型消息内部包含的文件
}

// 文件基本信息
public protocol FileContentBasicInfo {
    var key: String { get }
    // 消息链接化场景需要使用previewID做鉴权
    var authToken: String? { get }
    // 消息链接化场景嵌套文件夹需要传最外层的文件的key给后端做鉴权
    var authFileKey: String { get }
    var size: Int64 { get }
    var name: String { get }
    var cacheFilePath: String { get }
    var filePreviewStage: Basic_V1_FilePreviewStage { get }
}

public enum FileOperationEvent {
    case saveToDrive
    case openFile
    case downloadFile
    case viewFileInChat
}

public struct FileBrowseMenuOptions: OptionSet {
    public let rawValue: UInt

    public static let forward = FileBrowseMenuOptions(rawValue: 1 << 0)
    public static let favorite = FileBrowseMenuOptions(rawValue: 1 << 1)
    public static let viewInChat = FileBrowseMenuOptions(rawValue: 1 << 2)
    public static let canSaveToAlbum = FileBrowseMenuOptions(rawValue: 1 << 3)
    public static let canSaveFileToDrive = FileBrowseMenuOptions(rawValue: 1 << 4)
    public static let forwardCopy = FileBrowseMenuOptions(rawValue: 1 << 5)
    public static let openWithOtherApp = FileBrowseMenuOptions(rawValue: 1 << 6)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

public enum FileSourceScene {
    case messageDetail  //回复详情界面
    case search
    case chat           //chat聊天界面
    case fileTab        //文件Tab界面
    case pin
    case favorite(favoriteId: String)
    case flag
    case mergeForward
    case forwardPreview
    case unknown
}

public struct MessageFileBrowseBody: PlainBody {

    public static let pattern = "//client/file/message/browse"

    public let message: Message?
    public let messageId: String
    public let fileInfo: FileContentBasicInfo? /// 文件基本信息，优先使用。为空的话从消息体获取
    public let isInnerFile: Bool /// 是否为子文件
    public let scene: FileSourceScene
    public let downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    /// 1. Todo 业务域复用 FileBrower，chatFromTodo 描述 todo 业务域携带过来的 chat 信息
    /// 2. 消息链接化场景也直接使用传过来的chat，否则对于无权限的场景chat（如单聊时转发出去的无权限消息链接）可能拉不到
    public let chatFromTodo: Chat?
    /// 文件没有权限回调
    public var fileHasNoAuthorize: ((Message.FileDeletedStatus) -> Void)?

    public var operationEvent: ((FileOperationEvent) -> Void)?

    public var isOpeningInNewScene: Bool = false //是否是分屏打开
    // 消息链接化场景无权限时（如单聊时转发出去的无权限消息链接）可能拉不到chat，使用内存中的Chat
    public var useLocalChat: Bool = false
    // Office文件类型的鉴权涉及其他业务，消息链接化场景暂时屏蔽Office文件类型的点击事件（三端对齐）
    public let canFileClick: ((_ fileName: String) -> Bool)?
    // 是否支持跳转到会话
    public let canViewInChat: Bool
    // 是否能转发
    public let canForward: Bool
    public let canSearch: Bool
    // 是否能保存到云空间
    public let canSaveToDrive: Bool

    public init(message: Message? = nil,
                messageId: String? = nil,
                fileInfo: FileContentBasicInfo? = nil,
                isInnerFile: Bool = false,
                scene: FileSourceScene,
                fileHasNoAuthorize: ((Message.FileDeletedStatus) -> Void)? = nil,
                operationEvent: ((FileOperationEvent) -> Void)? = nil,
                downloadFileScene: RustPB.Media_V1_DownloadFileScene? = nil,
                chatFromTodo: Chat? = nil) {
        self.init(message: message,
                  messageId: messageId,
                  fileInfo: fileInfo,
                  isInnerFile: isInnerFile,
                  scene: scene,
                  fileHasNoAuthorize: fileHasNoAuthorize,
                  operationEvent: operationEvent,
                  downloadFileScene: downloadFileScene,
                  chatFromTodo: chatFromTodo,
                  useLocalChat: false,
                  canFileClick: nil,
                  canViewInChat: true,
                  canForward: true,
                  canSearch: true,
                  canSaveToDrive: true)
    }

    public init(message: Message? = nil,
                messageId: String? = nil,
                fileInfo: FileContentBasicInfo? = nil,
                isInnerFile: Bool = false,
                scene: FileSourceScene,
                fileHasNoAuthorize: ((Message.FileDeletedStatus) -> Void)? = nil,
                operationEvent: ((FileOperationEvent) -> Void)? = nil,
                downloadFileScene: RustPB.Media_V1_DownloadFileScene? = nil,
                chatFromTodo: Chat? = nil,
                useLocalChat: Bool,
                canFileClick: ((_ fileName: String) -> Bool)? = nil,
                canViewInChat: Bool,
                canForward: Bool,
                canSearch: Bool,
                canSaveToDrive: Bool) {
        self.message = message
        self.messageId = (messageId ?? message?.id) ?? ""
        self.fileInfo = fileInfo
        self.isInnerFile = isInnerFile
        self.scene = scene
        self.chatFromTodo = chatFromTodo
        self.fileHasNoAuthorize = fileHasNoAuthorize
        self.operationEvent = operationEvent
        self.downloadFileScene = downloadFileScene
        self.useLocalChat = useLocalChat
        self.canFileClick = canFileClick
        self.canViewInChat = canViewInChat
        self.canForward = canForward
        self.canSearch = canSearch
        self.canSaveToDrive = canSaveToDrive
    }
}
@available(iOS 13.0, *)
public final class FileBrowseSceneContext { //分屏预览文件&文件夹需要的上下文
    public var message: Message
    public var scene: FileSourceScene
    public var downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    public init(message: Message, scene: FileSourceScene, downloadFileScene: RustPB.Media_V1_DownloadFileScene? = nil, chatFromTodo: Chat? = nil) {
        self.message = message
        self.scene = scene
        self.downloadFileScene = downloadFileScene
    }
}

// 文件管理器内进入文件预览
public struct MessageFolderFileBrowseBody: PlainBody {

    public static let pattern = "//client/folder/message/file/browse"

    public let message: Message // 最外层文件夹所属 message
    public let fileInfo: FileContentBasicInfo
    public let scene: FileSourceScene
    public let downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    /// Todo 业务域复用 FileBrower，chatFromTodo 描述 todo 业务域携带过来的 chat 信息
    public let chatFromTodo: Chat?
    public let supportForwardCopy: Bool
    //文件是否是支持在线预览的压缩包
    public var isPreviewableZip: Bool

    public init(message: Message,
                fileInfo: FileContentBasicInfo,
                scene: FileSourceScene,
                downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
                chatFromTodo: Chat? = nil,
                supportForwardCopy: Bool,
                isPreviewableZip: Bool = false) {
        self.message = message
        self.fileInfo = fileInfo
        self.scene = scene
        self.chatFromTodo = chatFromTodo
        self.downloadFileScene = downloadFileScene
        self.supportForwardCopy = supportForwardCopy
        self.isPreviewableZip = isPreviewableZip
    }
}

// IM中风险文件申诉
public struct RiskFileAppealBody: PlainBody {
    public static let pattern: String = "//client/file/risk_appeal"

    public let objToken: String
    public let version: Int
    public let fileType: Int
    public let locale: String

    public init(fileKey: String,
                version: Int = 0,
                fileType: Int = 0,
                locale: String) {
        self.objToken = fileKey
        self.version = version
        self.fileType = fileType
        self.locale = locale
    }
}

public struct LocalFileBody: PlainBody {
    public enum RequestFrom {
        case im
        case other
    }

    public static let pattern = "//client/file/local"
    /// 文件选择总数限制
    public var maxSelectCount: Int?
    /// 单个文件大小限制
    public var maxSingleFileSize: Int?
    /// 总文件大小限制
    public var maxTotalFileSize: Int?
    public var chooseLocalFiles: (([LocalAttachFile]) -> Void)?
    public var chooseFilesChange: (([String]) -> Void)?
    public var cancelCallback: (() -> Void)?
    /// 附加需要搜索的路径
    public var extraFilePaths: [URL]?
    /// 请求发起场景
    public var requestFrom: RequestFrom?
    /// 是否展示系统相册中的视频
    public var showSystemAlbumVideo: Bool = true
    /// VC的title
    public var title: String?
    /// 底部发送按钮title
    public var sendButtonTitle: String?
    public init() {}
}

public protocol FileMessageInfoService {
    func getFileMessageInfo(message: Message, downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> FileMessageInfoProtocol
}

public protocol FileMessageInfoProtocol {
    var fileKey: String { get }

    var authToken: String? { get }

    var authFileKey: String { get }

    var fileName: String { get }

    var fileFormat: FileFormat { get }

    var isFileExist: Bool { get }

    var fileLocalURL: URL { get }

    var fileLocalPath: String { get }

    var fileIcon: UIImage { get }

    var fileSizeString: String { get }

    var pathExtension: String { get }

    var canSaveToAlbum: Bool { get }

    var isEncrypted: Bool { get }
}
public extension FileMessageInfoProtocol {
    // 解密后的path
    func safeLocalFilePath() -> AbsPath {
        if SBUtils.checkEncryptStatus(forFileAt: self.fileLocalPath) == .encrypted {
            return (try? SBUtils.decrypt(atPath: self.fileLocalPath)) ?? AbsPath(self.fileLocalPath)
        } else {
            return AbsPath(self.fileLocalPath)
        }
    }
}

///桥接DrivesSDK文件相关能力
public protocol DriveSDKDependencyBridge {
    var actionDependency: DriveSDKActionDependencyBridge { get }
    var moreDependency: DriveSDKMoreDependencyBridge { get }
}

public enum DriveSDKDownloadStateBridge {
    case downloading(progress: Double)
    case success(fileURL: URL)
    case interrupted(reason: String)
}

public protocol DriveSDKFileProviderBridge {
    var fileSize: UInt64 { get } // 文件总大小，用于显示下载进度
    var localFileURL: URL? { get } // 如果已下载完成，提供LocalFileURL，直接从本地打开
    /// 下载操作前置拦截
    func canDownload(fromView: UIView?) -> Observable<Bool>
    func download() -> Observable<DriveSDKDownloadStateBridge>
    func cancelDownload()
}

public enum DriveSDKMoreActionBridge {
    case openWithOtherApp(fileProvider: DriveSDKFileProviderBridge)
    case saveToSpace
    case forward(handler: (UIViewController) -> Void)
}

public protocol DriveSDKMoreDependencyBridge {
    var moreMenuVisable: Observable<Bool> { get }
    var moreMenuEnable: Observable<Bool> { get }
    var provider: DriveSDKFileProviderBridge { get }
    func handleForward(vc: UIViewController)
}

public protocol DriveSDKActionDependencyBridge {
    typealias Reason = DriveSDKStopReasonBridge
    var closePreviewSignal: Observable<Void> { get }
    var stopPreviewSignal: Observable<Reason> { get }
}

public struct DriveSDKStopReasonBridge {
    public var image: UIImage?
    public var reason: String
    public init(reason: String, image: UIImage?) {
        self.reason = reason
        self.image = image
    }
}

// MARK: DrivesSDK 本地预览
public protocol DriveSDKLocalDependencyBridge {
    var actionDependency: DriveSDKActionDependencyBridge { get }
    var moreDependency: DriveSDKLocalMoreDependencyBridge { get }
}

public protocol DriveSDKLocalMoreDependencyBridge {
    var moreMenuVisable: Observable<Bool> { get }
    var moreMenuEnable: Observable<Bool> { get }
}

// MARK: 获取本地沙盒文件
public protocol AttachedFile {
    var id: String { get }
    var type: AttachedFileType { get }
    var name: String { get }
    var size: Int64 { get }
    var videoDuration: TimeInterval? { get }
    var filePath: String { get }
}

public enum AttachedFileType: Int {
    case albumVideo
    case localVideo
    case PDF
    case EXCEL
    case WORD
    case PPT
    case TXT
    case MD
    case JSON
    case HTML
    case unkown
}

public protocol LocalFileFetchService {
    func fetchAttachedFilesFromDownloadDirectory(and extraPaths: [URL]) -> [AttachedFile]
}

public struct LocalAttachFile {
    public let name: String
    public let fileURL: URL
    public var size: UInt?
    public init(name: String, fileURL: URL) {
        self.name = name
        self.fileURL = fileURL
    }

    public init(name: String, fileURL: URL, size: UInt) {
        self.name = name
        self.fileURL = fileURL
        self.size = size
    }
}

public protocol FileUtilService: AnyObject {
    func fileIsPreviewableZip(fileName: String, fileSize: Int64) -> Bool
    func onFileMessageClicked(message: Message, chat: Chat, window: UIWindow, downloadFileScene: RustPB.Media_V1_DownloadFileScene?, openFileBlock: @escaping (() -> Void))
    func onFolderMessageClicked(message: Message, chat: Chat, window: UIWindow, downloadFileScene: RustPB.Media_V1_DownloadFileScene?, openFolderBlock: @escaping (() -> Void))
}

public protocol RustEncryptFileDecodeService {
    //根据原始路径，返回解密后文件的路径
    func decode(fileKey: String, fileType: String, sourcePath: URL, finish: @escaping (Result<URL, Error>) -> Void)

    func clean(force: Bool)
}
