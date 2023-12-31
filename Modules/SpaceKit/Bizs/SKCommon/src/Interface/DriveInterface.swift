//
//  DriveInterface.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/15.
//
//  Drive对外提供的业务接口


import Foundation
import RxSwift
import RxRelay
import SKFoundation
import SpaceInterface
import LarkDocsIcon

//DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
public protocol DriveRouterBase: SKTypeAccessible {

    /// 展示媒体选择器DriveAssetPickerViewController
    ///
    /// - Parameters
    ///   - sourceController: 源控制器
    ///   - folderPathToken: 当前文件夹路径token
    static func showAssetPickerViewController(sourceViewController: UIViewController,
                                              mountToken: String,
                                              mountPoint: String,
                                              scene: DriveUploadScene,
                                              completion: ((Bool) -> Void)?)

    /// 展示文件选择器DriveDocumentPickerViewController
    ///
    /// - Parameters
    ///   - sourceController: 源控制器
    ///   - folderPathToken: 当前文件夹路径token
    static func showDocumentPickerViewController(sourceViewController: UIViewController,
                                                 mountToken: String,
                                                 mountPoint: String,
                                                 scene: DriveUploadScene,
                                                 completion: ((Bool) -> Void)?)

    /// 展示上传列表页面
    ///
    /// - Parameters
    ///   - sourceController: 源控制器
    ///   - folderPathToken: 当前文件夹路径token
    static func showUploadListViewController(sourceViewController: UIViewController, folderToken: String, scene: DriveUploadScene, params: [String: Any])
}

/// 保存到本地的结果
public enum SaveICloudFileResult {
    case success(SaveSuccessModel)
    case fail(iCloudURL: URL, error: SaveError)
    
    public enum SaveError: Error {
        case invalidFile
        case saveFailure
    }

    public struct SaveSuccessModel {
        public var iCloudURL: URL
        public var localURL: URL
        public var fileSize: UInt64
        public var fileName: String
        
        public init(iCloudURL: URL, localURL: URL, fileSize: UInt64, fileName: String) {
            self.iCloudURL = iCloudURL
            self.localURL = localURL
            self.fileSize = fileSize
            self.fileName = fileName
        }
    }
}

public protocol DriveUploadCacheServiceBase: SKTypeAccessible {
    /// 该接口附带上传功能
    static func saveICouldFileToLocal(urls: [URL], mountToken: String, mountPoint: String, scene: DriveUploadScene) -> Bool
    /// 该接口仅提供本地保存功能
    static func saveICloudFile(urls: [URL],
                               isContinueWhenContainInvalidItem: Bool,
                               eachFileSaveResult: ((SaveICloudFileResult) -> Void)?,
                               completion: (([URL: SaveICloudFileResult]) -> Void)?) -> Bool
}

public protocol DriveCacheServiceBase: SimpleModeObserver {
    func canOpenOffline(token: String, dataVersion: String?, fileExtension: String?) -> Bool
    func isDriveFileExist(token: String, dataVersion: String?, fileExtension: String?) -> Bool
    func deleteAll(completion: (() -> Void)?)
    func userDidLogout()
}

public protocol DrivePreloadServiceBase: AnyObject {
    func handle(files: [(token: String, fileSize: UInt64?, fileType: DriveFileType)], source: DrivePreloadSource)
    func update(config: DrivePreloadConfig)
}


public protocol DriveConvertFileConfigBase: SKTypeAccessible {
    static func needShowRedGuide() -> Bool
    static func recordHadClickRedGuide()
    static func parseFileEnabled(fileToken: String, completion: @escaping (Result<Void, Error>) -> Void)

    static var featureEnabled: Bool { get }
    // 单位 Byte
    static var importSizeLimit: Int64 { get }
    static func isSizeOverLimit(_ byte: UInt64) -> Bool
}

public protocol DriveUploadCallbackServiceBase: DriveMultipDelegates {}

public protocol DriveUploadStatusManagerBase: DriveMultipDelegates {}


open class DriveAutoPerformanceTestBase {
    public init(navigator: UIViewController?) { }
    open func start() {}
    open func stop() {}
}

/// 记录上传下载来源信息接口，需要在其他的模块调用，在上传下载结束后上报使用
public protocol UploadAndDownloadStastis {
    // 记录上传的信息
    func recordUploadInfo(module: String, uploadKey: String, isDriveSDK: Bool)
    // 记录下载信息
    func recordDownloadInfo(module: String, downloadKey: String, fileID: String, fileSubType: String?, isExport: Bool, isDriveSDK: Bool)
}

/// 上传状态回调接口 均在主线程
public protocol DriveUploadStatusUpdator {
    /// 文件夹token
    var mountToken: String { get }
    /// mountPoint
    var mountPoint: String { get }
    /// scene
    var scene: DriveUploadScene { get }

    /// 存在未上传的文件
    func onExistUploadingFile()

    /// 等待上传中
    ///
    /// - Parameters:
    ///   - progress: 进度
    ///   - reminder: 剩余文件数量
    func onWaitingUpload(_ progress: Double, reminder: Int)

    /// 上传中更新进度
    ///
    /// - Parameters:
    ///   - progress: 进度
    ///   - reminder: 剩余文件数量
    ///   - total: 总上传文件
    func onUpdateProgress(_ progress: Double, reminder: Int, total: Int)

    /// 所有任务上传完成没有失败项
    ///
    /// - Parameter progress: 进度为1.0
    func onAllUploadTaskCompletedNoError(progress: Double)

    /// 上传完成但存在失败文件
    ///
    /// - Parameters:
    ///   - progress: 上传进度1.0
    ///   - errorCount: 失败文件数量
    func onUploadFinishedExistError(progress: Double, errorCount: Int)

    /// 文件上传成功的回调
    ///
    /// - Parameters:
    ///   - fileToken: 文件token
    ///   - moutNodePoint: 文件夹token
    ///   - nodeToken: 节点token, 如果是上传到wiki，nodeToken为文件对应的wikitoken
    func onUploadedFile(fileToken: String, moutNodePoint: String, nodeToken: String)

    /// 上传失败
    ///
    /// - Parameter count: 传输失败文件个数
    func onUploadFailedCount(count: Int)

    /// 文件上传失败原因
    ///
    /// - Parameters:
    ///   - mountNodePoint: 上传的文件夹
    ///   - key: 上传文件任务的唯一标识，rust内部使用
    ///   - errorCode: 错误码
    func onUploadError(mountNodePoint: String, key: String, errorCode: Int)

    /// 没有文件在上传
    func onNoExistUploadingFile()
}

public protocol DriveVCFactoryType {
    func openDriveFileWithOtherApp(file: SpaceEntry, originName: String?, sourceController: UIViewController, sourceRect: CGRect?, arrowDirection: UIPopoverArrowDirection, previewFrom: DrivePreviewFrom)

    /// Docs List 进入Drive预览
    ///
    /// - Parameters:
    ///     - file:SpaceEntry
    ///     - fileList:[SpaceEntry]
    ///     - from:DrivePreviewFrom
    ///     - statisticInfo: 埋点数据
    /// - Returns: DrivePreviewController
    func makeDrivePreview(file: SpaceEntry, fileList: [SpaceEntry], from: DrivePreviewFrom?, statisticInfo: [String: String]) -> UIViewController

    /// Lark feed open url
    ///
    /// - Parameter url: URL
    /// - Paraeter context: extra infos
    /// - Paraeter alertMoreActions: 第三方附件预览界面更多按钮弹出AlertVC选项配置，Drive业务预览传空
    /// - Returns: DrivePreviewController
    func makeDrivePreview(url: URL, context: [String: Any]?) -> UIViewController

    func makeDriveLocalPreview(files: [DriveLocalFileEntity], index: Int) -> UIViewController?

    func makeDriveThirdPartyPreview(files: [DriveThirdPartyFileEntity], index: Int, moreActions: [DriveAlertVCAction], isInVCFollow: Bool, bussinessId: String) -> UIViewController

    func isDriveMainViewController(_ viewController: UIViewController) -> Bool

    func makeImportToDriveController(file: SpaceEntry, actionSource: DriveStatisticActionSource, previewFrom: DrivePreviewFrom) -> UIViewController
    
    func saveToLocal(file: SpaceEntry, originName: String?, sourceController: UIViewController, previewFrom: DrivePreviewFrom)
    
    func saveToLocal(data: [String: Any], fileToken: String, mountNodeToken: String, mountPoint: String, fromVC: UIViewController, previewFrom: DrivePreviewFrom)
}

public extension DriveVCFactoryType {
    func openDriveFileWithOtherApp(file: SpaceEntry,
                                   originName: String?,
                                   sourceController: UIViewController,
                                   sourceRect: CGRect?,
                                   arrowDirection: UIPopoverArrowDirection) {
        openDriveFileWithOtherApp(file: file,
                                  originName: originName,
                                  sourceController: sourceController,
                                  sourceRect: sourceRect,
                                  arrowDirection: arrowDirection,
                                  previewFrom: .docsList)
    }

    func saveToLocal(file: SpaceEntry, originName: String?, sourceController: UIViewController) {
        saveToLocal(file: file, originName: originName, sourceController: sourceController, previewFrom: .docsList)
    }
}

/// FileBlock前端参数
/// appID: 应用ID
/// fileID: fileToken
/// fileName: 文件名
/// mountPoint: 挂载点，参考 https://bytedance.feishu.cn/wiki/wikcnnx6X3KMIcKQszifWMyvBkf
/// mountNodePoint: 挂在的节点token
/// fileType: 文件类型，文件后缀，如：pdf
/// authExtra: 精细化权限鉴权信息
/// isInVCFollow: 是否在 MagicShare 中打开
public struct DriveFileBlockParams {
    public let appID: String
    public let fileID: String
    public let fileName: String
    public let mountPoint: String
    public let mountNodePoint: String
    public let fileType: String
    public let authExtra: String?
    public let progress: Float?
    public let isInVCFollow: Bool
    public let hostToken: String?
    public let tenantID: String?

    public static func createWithParams(params: [AnyHashable: Any], docsInfo: DocsInfo?) -> DriveFileBlockParams? {
        guard let appID = params["app-id"] as? String, let fileID = params["file-id"] as? String,
        let mountPoint = params["mount-point"] as? String,
        let mountNodePoint = params["mount-node-token"] as? String,
        let fileType = params["file-type"] as? String else {
            return nil
        }
        let authExtra = params["auth-extra"] as? String
        let fileName = params["file-name"] as? String ?? ""
        let isInVCFollow = (params["in-vc"] as? String ?? "") == "1"
        var hostToken = params["doc-token"] as? String
        let srcDocToken = params["src-obj-token"] as? String //源文档的token, 支持SyncedBlock
        let progressStringVaule = params["progress"] as? String ?? "0"
        let progress: Float? = Float(progressStringVaule) ?? 0.0
        if UserScopeNoChangeFG.LJY.enableSyncBlock,
           let srcDocToken,
           !srcDocToken.isEmpty {
            hostToken = srcDocToken
        }
        let tenantID: String?
        if let hostToken {
            tenantID = docsInfo?.getBlockTenantId(srcObjToken: hostToken)
        } else {
            tenantID = docsInfo?.tenantID
        }
        return DriveFileBlockParams(appID: appID,
                                    fileID: fileID,
                                    fileName: fileName,
                                    mountPoint: mountPoint,
                                    mountNodePoint: mountNodePoint,
                                    fileType: fileType,
                                    authExtra: authExtra,
                                    progress: progress,
                                    isInVCFollow: isInVCFollow,
                                    hostToken: hostToken,
                                    tenantID: tenantID)
    }
}

public enum DrivePreviewMode: Equatable {
    case card
    case normal
}
public protocol DKPreviewVCManagerProtocol {
    func getPreviewVC(with identifier: String, params: DriveFileBlockParams?) -> DriveFileBlockVCProtocol?
    func makeAnimatedContainer(vc: BaseViewController) -> DriveAnimatedContainer
    func component(with identifier: String, moveInScreen: Bool)
    func clear()
    func delete(with identifier: String)
}

public protocol DriveAnimatedContainer: BaseViewController, UIViewControllerTransitioningDelegate {
    var childVC: BaseViewController { get }
    var childVCFrame: (() -> CGRect)? { get set }
    var resetChildVC: (() -> Void)? { get set }
    func setupChild()
    func willChangeMode(_ mode: DrivePreviewMode)
    func changingMode(_ mode: DrivePreviewMode)
    func didChangeMode(_ mode: DrivePreviewMode)
}

public protocol DriveFileBlockVCProtocol: BaseViewController {
    func didChangeMode(_ mode: DrivePreviewMode)
    var clickEnterFull: (() -> Void)? { get set }
    var panGesture: UIPanGestureRecognizer? { get }
    // 在这个视图上native需要处理自定义手势，同层渲染禁用前端手势
    var customGestureView: UIView? { get }
    var statusBarIsHidden: Bool { get }
    /// VC 对应的同层 Component
    var fileBlockComponent: DriveFileBlockComponentProtocol? { get set }
    /// VC 同层渲染挂载在文档的位置
    var fileBlockMountToken: String? { get set }
}

public protocol DriveFileBlockLoadingProtocol: UIView {
    func startAnimate()
}

public protocol DriveFileBlockComponentProtocol: AnyObject {
    /// 从同层 FileBlock 模式进入全屏模式
    /// - Parameter animated: 是否有弹出动画，无动画的场景为重复弹出情况
    /// - Returns: 返回是否成功进入结果
    func enterFullMode() -> Bool
}
