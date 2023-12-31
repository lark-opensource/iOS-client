//
//  DKFileCellViewModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/12.
//

import UIKit
import RxSwift
import RxCocoa
import SpaceInterface
import SKCommon
import SKUIKit
import SKFoundation
import UniverseDesignToast
import LarkSecurityComplianceInterface
import LarkDocsIcon

protocol DKFileCellViewModelType {
    // MainViewModel需要和HostModule进行交互
    var hostModule: DKHostModuleType? { get }
    // 是否是VCFollow
    var isInVCFollow: Bool { get }
    // 开始加载文件
    func startPreview(hostContainer: UIViewController)
    // 改变预览模式：卡片模式，切换动画中，正常模式
    func willChangeMode(_ mode: DrivePreviewMode)
    func changingMode(_ mode: DrivePreviewMode)
    func didChangeMode(_ mode: DrivePreviewMode)
    // 重置
    func reset()
    // 预览状态
    var previewStateUpdated: Driver<DKFilePreviewState> { get }
    // 预览动作
    var previewAction: Observable<DKPreviewAction> { get }
    // 导航栏VM
    var naviBarViewModel: ReplaySubject<DKNaviBarViewModel> { get }
    // `isReadable`和`canExport`权限, 用于防截图判断
    var canReadAndCanCopy: Observable<(Bool, Bool)>? { get }
    // 性能数据上报
    var performanceRecorder: DrivePerformanceRecorder { get }
    // 业务数据上报
    var statisticsService: DKStatisticsService { get }
    // 是否需要展示水印
    var shouldShowWatermark: Bool { get }
    
    // 添加导航栏按钮
    func update(additionLeftBarItems: [DriveNavBarItemData], additionRightBarItems: [DriveNavBarItemData])
    
    // 处理外部事件
    func handle(previewAction: DKPreviewAction)
    
    // 用于兼容 drive 现有的预览异常处理
    func handleBizPreviewUnsupport(type: DriveUnsupportPreviewType)
    // 用于兼容 drive 现有的预览失败处理
    func handleBizPreviewFailed(canRetry: Bool)
    /// 用于处理降级流程
    func handleBizPreviewDowngrade()
    /// 用于获取预览文件类型
    func handleOpenFileSuccessType(openType: DriveOpenType)
    // 文件类型, 用于判断是否支持多文件预览
    var fileType: DriveFileType { get }
    // 文件ID, 用户判断多文件预览index
    var fileID: String { get }
    // 多文件预览保存关联图片浮窗信息
    var urlForSuspendable: String? { get }
    // 标题
    var title: String { get }
    //场景
    var previewFromScene: DrivePreviewFrom { get }
    // 目前没有合适的链路把 VC 的生命周期事件分发给 viewModel，后续有其他事件需要分发时，考虑拓展此方法
    /// VC 场景恢复全屏事件
    func didResumeVCFullWindow()

    var permissionService: UserPermissionService { get }
}


protocol DKMainViewModelType: NSObject, BulletinViewDelegate {
    // datasource
    func numberOfFiles() -> Int
    func willChangeMode(_ mode: DrivePreviewMode)
    func changingMode(_ mode: DrivePreviewMode)
    func didChangeMode(_ mode: DrivePreviewMode)
    func cellViewModel(at index: Int) -> DKFileCellViewModelType
    func title(of index: Int) -> String
    func prepareShowBulletin()
    func shouldOpenVerifyURL(type: ComplaintState)
    var curIndex: Int { get }
    var naviBarViewModel: Driver<DKNaviBarViewModel> { get }
    var reloadData: Driver<Int> { get }
    var subTitle: String? { get }
    var previewAction: Observable<DKPreviewAction> { get }
    var performanceRecorder: DrivePerformanceRecorder { get }
    var statisticsService: DKStatisticsService { get }
    var supportLandscape: Bool { get }
    var shouldShowWatermark: Bool { get }
    // MainViewController需要和HostModule进行交互
    var hostModule: DKHostModuleType? { get }
    // 多文件悬浮窗口
    var associatedFiles: [[String: String]] { get }
    // 区分是否需要展示评论bar，避免子vc通过delegate将commentbar展示出来
    var shouldShowCommentBar: Bool { get }
    // 文件是否被删除
    var fileDeleted: Bool { get }
    // 是否为云空间文件
    var isSpaceFile: Bool { get }
    // token 分屏需要
    var objToken: String { get }
    // title 分屏需要
    var title: String { get }
    // 来源
    var previewFrom: DrivePreviewFrom { get }
    // 自动化测试使用
    var readyToStart: Driver<()> { get }
    // 文件类型，卡片模式下判断是否显示标题栏
    var fileType: DriveFileType { get }
    var previewUIStateManager: DriveUIStateManager { get }

    func notifyControllerWillAppear()
    func notifyControllerDidDisappear()
    
}

// 文件加载阶段
enum DKFileStage {
    /// 初始状态
    case initial
    /// 加载 FileInfo 中
    case fetchingFileInfo
    /// 加载 FileInfo 失败
    case fetchFailed
    /// 异步加载 FileInfo 中
    case asyncFetchingFileInfo
    /// 预览缓存中，特指异步加载 FileInfo 失败或者 FileInfo 没有更新的状态
    case previewingCache
    /// 在线预览中（交由 previewVM 接管）
    case onlinePreviewing(previewVM: DKPreviewViewModel)
    /// 业务方停止预览
    case forbidden
    ///条件访问控制管控
    case cacFroBidden
    /// 受 TNS 管控停止预览，并进行重定向
    case blockByTNS(info: TNSRedirectInfo)

    /// 当前阶段是否支持降级预览
    var canDowngradeStage: Bool {
        switch self {
        case .blockByTNS, .forbidden, .cacFroBidden, .fetchFailed:
            return false
        case .initial, .fetchingFileInfo, .asyncFetchingFileInfo, .previewingCache, .onlinePreviewing:
            return true
        }
    }
}

struct DKAlertContent {
    struct Action {
        let style: UIAlertAction.Style
        let title: String
        let handler: (() -> Void)?
    }

    let title: String?
    let message: String?
    let actions: [Action]

    var isEmpty: Bool {
        return title == nil
            && message == nil
            && actions.isEmpty
    }
}

enum DKPreviewAction {
    case toast(content: String, type: DocsExtension<UDToast>.MsgType)
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    case dialog(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?)
    case forward(handler: (UIViewController, DKAttachmentInfo) -> Void, info: DKAttachmentInfo)
    case saveToAlbum(handler: (UIViewController, DKAttachmentInfo) -> Void, info: DriveFileInfo,previewFrom: DrivePreviewFrom)
    case saveToFile(handler: (UIViewController, DKAttachmentInfo) -> Void, info: DriveFileInfo, previewFrom: DrivePreviewFrom)
    case saveToLocal(handler: (UIViewController, DKAttachmentInfo) -> Void, info: DriveFileInfo)
    case importAs(convertType: DKConvertFileType, actionSource: DriveStatisticActionSource, previewFrom: DrivePreviewFrom)
    case openDrive(token: String, appID: String)
    case openWithOtherApp(url: URL, sourceView: UIView?, sourceRect: CGRect?, callback: ((String, Bool) -> Void)?)
    case downloadAndOpenWithOtherApp(meta: DriveFileMeta, previewFrom: DrivePreviewFrom,sourceView: UIView?, sourceRect: CGRect?, callback: ((String, Bool) -> Void)?)
    case downloadOriginFile(viewModel: DKDownloadViewModel, isOpenWithOtherApp: Bool)
    case cancelDownload // 4G流量提醒取消预览
    case exitPreview // 退出预览
    case alert(content: DKAlertContent)
    case storageQuotaAlert // 租户存储超限弹窗
    case userStorageQuotaAlert(token: String) // 用户容量超限
    case customAction(action: (UIViewController) -> Void) // 自定义事件
    case appealResult(state: ComplaintState) //举报结果
    case hideAppealBanner //隐藏举报公告
    case completeDownloadToSave(fileType: DriveFileType, url: URL, handler: ((UIViewController) -> Void)?) // 下载完成后处理
    case saveToSpaceQuotaAlert(fileSize: Int64) //保存到云空间商业化弹窗
    case didFetchFileInfo(fileInfo: DKFileProtocol) // 获取到fileInfo
    // 开始初始化预览VC，此时还没有openSuccess，有可能预览失败，添加这个事件是为了处理卡片模式下视频没有完全加载的情况下点击进入全屏状态UI异常问题
    case setupChildPreviewVC(openType: DriveOpenType)
    case openSuccess(openType: DriveOpenType)
    case openFailed
    case open(entry: SKEntryBody, context: [String: Any])
    case openURL(url: URL)
    case openShadowFile(id: String, url: URL)
    case closeBulletin(info: BulletinInfo?)
    case showNotice(info: BulletinInfo)
    case customUserDefine(handler: (UIViewController, DKAttachmentInfo) -> Void, info: DKAttachmentInfo)//用户自定义more面板操作
    case showDLPBanner
    case hideDLPBanner
    case showSecretBanner(type: SecretBannerView.BannerType)
    case hideSecretBanner
    case showSecretSetting
    case push(viewController: UIViewController)
    case legacyShowLeaderPermAlert(token: String, userPermission: UserPermissionAbility?)
    case showLeaderPermAlert(token: String, permissionContainer: UserPermissionContainer?)
    case cacBlock
    case showCustomBanner(banner: UIView, bannerID: String)
    case hideCustomBanner(bannerID: String)
    case hideLoadingToast
    case showFlowOnboarding(id: OnboardingID)
}

enum DKFilePreviewState {
    case loading // 开始请求预览数据,显示loading
    case endLoading // 加载完成，隐藏loading
    case transcoding(fileType: String, handler: ((UIView, CGRect?) -> Void)?, downloadForPreviewHandler: (() -> Void)?) // 转码中
    case endTranscoding // 转码结束
    case showDownloading(fileType: DriveFileType) // 开始下载
    case downloading(progress: Float) // 下载进度
    case downloadCompleted // 下载成功
    case setupPreview(type: DriveFileType, info: DKFilePreviewInfo) // 创建预览界面 type:实际预览的文件类型，info: 对应文件类型预览需要的数据
    case setupUnsupport(info: DKUnSupportViewInfo, handler: ((UIView, CGRect?) -> Void)?) // 不支持预览
    case forbidden(reason: String, image: UIImage?)
    // 收敛错误类型，统一用下面这个替换掉 deleted、downloadFailed
    // 显示错误提示页面
    case setupFailed(data: DKPreviewFailedViewData)
    // 删除文件支持恢复页面
    case deleteFileRestore(type: RestoreType, completion: (() -> Void))
    // isFromPermissionAPI: 无权限状态由两个接口，一个是fileInfo接口，一个是permission接口，permission接口的结果优先级更高
    // isAdminBlocked 表明是否因为 admin 精细化管控 view 点位导致的无权限，影响文案和 icon
    case noPermission(docsInfo: DocsInfo,
                      canRequestPermission: Bool,
                      isFromPermissionAPI: Bool,
                      isAdminBlocked: Bool,
                      isShareControlByCAC: Bool,
                      isPreviewControlByCAC: Bool,
                      isViewBlockByAudit: Bool)
    case showPasswordInputView(fileToken: String, restartBlock: () -> Void)
    // 卡片切换前、中、后状态
    case willChangeMode(mode: DrivePreviewMode)
    case changingMode(mode: DrivePreviewMode)
    case didChangeMode(mode: DrivePreviewMode)
    case cacDenied //cac管控
}
