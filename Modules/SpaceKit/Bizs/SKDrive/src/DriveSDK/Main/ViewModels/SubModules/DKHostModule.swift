//
//  DKHostModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/19.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SKCommon
import SpaceInterface
import SKFoundation
import SKUIKit

enum DKSubModuleAction {
    case showLoading
    case endLoading
    case showFeed
    case showShareVC
    case clickNavSecretEvent    //导航栏点击密级按钮
    case showSecretVC           //more面板内打开密级vc
    case showMyAIVC             //打开MyAI 分会话
    case updateSecretLabel(name: String) //确认更新密级标签
    case clickSecretBanner
    case showMoreVC
    case openReadingData
    case openHistory
    case spaceOpenWithOtherApp
    case rename
    case applyEditPermission(scene: InsideMoreDataProvider.ApplyEditScene)
    case publicPermissionSetting
    case didSetupCommentManager(manager: DriveCommentManager) // commentManager初始化完成
    case viewComments(commentID: String?, isFromFeed: Bool)
    case refreshVersion(version: String?) // 刷新版本
    case stopDownload // 停止下载
    case enterComment(area: DriveAreaComment.Area, commentSource: DriveCommentSource) // 打开评论面板
    case updateNaviBar(vm: DKNaviBarViewModel)
    case refreshNaviBarItemsDots // 刷新导航栏按钮状态
    case updateAdditionNavibarItem(leftItems: [DKNaviBarItem], rightItems: [DKNaviBarItem])
    case clearNaviBarItems // 移除右上角按钮
    case openSuccess(openType: DriveOpenType)
    case fileDidDeleted
    case wikiNodeDeletedStatus(isDelete: Bool)
    case updateDocsInfo // 更新docsInfo
    case resotreSuccess // 恢复删除的drive文档成功
    case redirectToWiki(token: String) // 跳转到Wiki页面
}

class DKSpacePreviewContext {
    let previewFrom: DrivePreviewFrom
    let canImportAsOnlineFile: Bool
    let feedId: String?
    let wikiToken: String?
    let isGuest: Bool
    let hostToken: String? // 宿主token
    // 目前用于 drive 浏览时子 VC 之间记录数据，如刷新版本时保留状态，供新的子vc读取
    var extraInfo: [String: Any] = [:]
    /// 用于传递埋点相关数据
    var statisticInfo: [String: String] = [:]
    var feedFromInfo: FeedFromInfo?
    
    /// AI分会话返回的PDF页面
    var pdfPageNumber: Int?
    
    weak var followAPIDelegate: SpaceFollowAPIDelegate?
    var isInVCFollow: Bool
    var hitoryEditTimeStamp: String?
    
    init(previewFrom: DrivePreviewFrom,
         canImportAsOnlineFile: Bool,
         isInVCFollow: Bool,
         wikiToken: String?,
         feedId: String?,
         isGuest: Bool,
         hostToken: String?) {
        self.previewFrom = previewFrom
        self.canImportAsOnlineFile = canImportAsOnlineFile
        self.isInVCFollow = isInVCFollow
        self.feedId = feedId
        self.isGuest = isGuest
        self.wikiToken = wikiToken
        self.hostToken = hostToken
    }
}

// 将子模块和DKMainViewController的交互抽象为一个协议，解除直接依赖
protocol DKSubModleHostVC: UIViewController {
    // 悬浮窗 ID,更多面板需要用到
    var suspendID: String { get }
    var navigationBar: SKNavigationBar { get }
    var commentBar: DriveCommentBottomView { get }
    var bottomPlaceHolderView: UIView { get }
    var commentBarIsShow: Bool { get set }
    var watermarkConfig: WatermarkViewConfig { get }
    var hasAppearred: Bool { get }
    func showPopover(to viewController: UIViewController,
                at index: Int,
                completion: (() -> Void)?)

    func back(canEmpty: Bool)
    func present(_ viewControllerToPresent: UIViewController,
            animated flag: Bool,
            completion: (() -> Void)?)
    func setupBottomView()
    func updateCommentBar(hiddenByPermission: Bool)
    func showCommentBar(_ shouldShow: Bool, animate: Bool)
    func resizeContentViewIfNeed(_ height: CGFloat?)
    // 全屏操作
    func exitFullScreen()
    var isInFullScreen: Bool { get }
}

protocol DKHostModuleType: AnyObject {
    var windowSizeDependency: WindowSizeProtocol? { get } 
    var hostController: DKSubModleHostVC? { get }
    var fileInfoRelay: BehaviorRelay<DriveFileInfo> { get }
    var fileInfoErrorOb: Observable<DriveError?> { get }
    var docsInfoRelay: BehaviorRelay<DocsInfo> { get }
    var pdfInlineAIAction: PublishRelay<DKPDFInlineAIAction>? { get }
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    var permissionRelay: BehaviorRelay<DrivePermissionInfo> { get }
    var commentManager: DriveCommentManager? { get }
    var netManager: DrivePreviewNetManagerProtocol { get }
    var cacheService: DKCacheServiceProtocol { get }
    var reachabilityChanged: Observable<Bool> { get }
    var commonContext: DKSpacePreviewContext { get }
    var moreDependency: DriveSDKMoreDependency { get }
    var previewActionSubject: ReplaySubject<DKPreviewAction> { get }
    var statisticsService: DKStatisticsService { get }
    var openFileSuccessType: DriveOpenType? { get }
    var currentDisplayMode: DrivePreviewMode { get }
    var isFromCardMode: Bool { get }
    // 额外的上报参数
    var additionalStatisticParameters: [String: String] { get }
    // 子模块之间通过actionsCenter传递事件
    var subModuleActionsCenter: PublishRelay<DKSubModuleAction> { get }
    // 预览场景
    var scene: DKPreviewScene { get }
    // 附件宿主token
    var hostToken: String? { get }
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    var cacManager: CACManagerBridge.Type { get }

    var permissionService: UserPermissionService { get }
    
    var pdfAIBridge: BehaviorRelay<Int>? { get }
}
