//
//  BrowserViewJSServiceContext.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/3.
//

import Foundation
import WebKit
import RxSwift
import SpaceInterface
import SKUIKit
import SKFoundation
import EENavigator
import LarkContainer
import LarkDocsIcon

public protocol BrowserModelConfig: AnyObject {
    var userResolver: UserResolver { get }
    var browserViewLifeCycleEvent: BrowserViewLifeCycle { get }
    var jsEngine: BrowserJSEngine { get }
    @available(*, deprecated, message: "Disambiguate using hostBrowserInfo - PermissionUpdate")
    var browserInfo: BrowserViewDocsAttribute { get }
    var hostBrowserInfo: BrowserViewDocsAttribute { get }
    var requestAgent: BrowserRequestAgent { get }
    var shareAgent: BrowserViewShareAgent { get }
    var synchronizer: BrowserSynchronizer { get }
    var openRecorder: BrowserOpenRecorder { get }
    var feedInfo: BrowserFeedInfo { get }
    var loadingReporter: BrowserLoadingReporter? { get }
    var scrollProxy: EditorScrollViewProxy? { get }
    var docsInfoUpateReporter: DocsInfoDidUpdateReporter { get }
    var vcFollowDelegate: BrowserVCFollowDelegate? { get }
    var docComponentDelegate: DocComponentHostDelegate? { get set }
    var permissionConfig: BrowserPermissionConfig { get }
    func setFullscreenScrollingEnabled(_ enabled: Bool)
    func setDocsShortcutCallback(_ callback: String)
    func setDocsShortcut(_ info: [UIKeyCommand: String])
    func setClearDoneFinish(_ finish: Bool)
}

public protocol BrowserUIConfig: AnyObject {
    var displayConfig: BrowserViewDisplayConfig { get }
    var hostView: UIView { get }
    var scrollProxy: EditorScrollViewProxy? { get }
    var gestureProxy: EditorGestureProxy? { get }
    var uiResponder: BrowserUIResponder { get }
    var loadingAgent: BrowserLoadingAgent { get }
    var openDocAgent: BrowserOpenDocAgent { get }
    var bannerAgent: BannerItemAgent { get }
    var editorView: DocsEditorViewProtocol { get }
    var catalog: CatalogDisplayer? { get }
    var commentPadDisplayer: CommentPadDisplayer? { get }
    // 考虑了传感器情况的方向，VC 具体方向应该用 UIApplication.shared.statusBarOrientation
    var interfaceOrientation: UIInterfaceOrientation { get }
    /// Block全屏模式下定制化TopContainer
    var customTCDisplayConfig: CustomTopContainerDisplayConfig? { get }
}



public protocol BrowserViewMenuHandler: AnyObject {
    func selectAction()
    func selectAllAction()
    func cutAction()
    func copyAction()
    func pasteAction()
    // 交由 webview context 属性去处理，保存到 webview 中
    func setContextMenus(items: [UIMenuItem])
    // 交由 webview context 属性去处理，只返回处理后的对象
    func makeContextMenuItem(with uid: String, title: String, action: @escaping () -> Void) -> UIMenuItem?
    
    func setEditMenus(menus: [EditMenuCommand])
    func makeEditMenuItem(with uid: String, title: String, action: @escaping () -> Void) -> EditMenuCommand?
}

//展示各种item
public protocol BannerItemAgent: AnyObject {
    func requestShowItem(_ item: BannerItem)
    func requestHideItem(_ item: BannerItem)
    func requestChangeItemVisibility(to toHidden: Bool)
}

// 用于显示iPhone端的目录，以及iPad端目录的配置，不依赖Browserview约束
public protocol CatalogDisplayer {
    func catalogDetails() -> [CatalogItemDetail]?
    func resetCatalog()
    func hideCatalog()
    func prepareCatalog(_ items: [CatalogItemDetail])
    func setCatalogOrentations(_ orentation: UIInterfaceOrientationMask)
    func showCatalogDetails()
    func hideCatalogDetails()
    func keyboardDidChangeState(_ options: Keyboard.KeyboardOptions)
    func getCatalogDisplayObserver() -> BehaviorSubject<Bool>
    func closeCatalog()
    // iPad目录显示配置
    func configIPadCatalog(_ isShow: Bool, autoPresentInEmbed: Bool, complete: ((_ mode: IPadCatalogMode) -> Void)?)
    func setHighlightCatalogItemWith(_ identifier: String)
}
extension CatalogDisplayer {
    public func setCatalogOrentations(_ orentation: UIInterfaceOrientationMask) { }
}

// 用于显示iPad端目录，依赖Browserview约束
public protocol CatalogPadDisplayer: UIView {
    func presentCatalogSideView(catalogSideView: IPadCatalogSideView, autoPresentInEmbed: Bool, complete: ((_ mode: IPadCatalogMode) -> Void)?)
    func dismissCatalogSideView(complete: @escaping () -> Void)
    func dismissCatalogSideViewByTapContent(complete: @escaping () -> Void)
}

public protocol CommentPadDisplayer {
    // 返回值表示当前是否有展示动画
    func presentCommentView(commentView: UIView, forceVisible: Bool, complete: @escaping () -> Void) -> Bool
    func dismissCommentView(animated: Bool, complete: @escaping () -> Void)
    func removePadCommentView()
}

public protocol BrowserJSEngine: SKExecJSFuncService {
    func fetchServiceInstance<H: JSServiceHandler>(_ service: H.Type) -> H?
    func simulateJSMessage(_ msg: String, params: [String: Any])
    var isBusy: Bool { get set }
    var editorView: DocsEditorViewProtocol { get }
    var editorIdentity: String { get }
    func evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)?)
}

extension BrowserJSEngine {
    public func fetchServiceInstance<H: JSServiceHandler>(_ service: H.Type) -> H? { return nil }
    public func simulateJSMessage(_ msg: String, params: [String: Any]) { }
}

public protocol BrowserNavigator: LarkOpenAgent {
    var currentBrowserVC: UIViewController? { get }

    var navigatorFromVC: NavigatorFrom { get }

    var preferredModalPresentationStyle: UIModalPresentationStyle { get }

    var presentedVC: UIViewController? { get }

    func presentClearViewController(_ v: UIViewController, animated: Bool)

    func presentViewController(_ v: UIViewController, animated: Bool, completion: (() -> Void)?)

    func dismissViewController(animated: Bool, completion: (() -> Void)?)

    func pushViewController(_ v: UIViewController)

    // canEmpty: iPad 模式下是否可以pop到兜底页
    func popViewController(canEmpty: Bool)

    @discardableResult
    func requiresOpen(url: URL) -> Bool

    func showUserProfile(token: String)

    func showEnterpriseTopic(query: String,
                             addrId: String,
                             triggerView: UIView,
                             triggerPoint: CGPoint,
                             clientArgs: String,
                             clickAction: EnterpriseTopicClickHandle?,
                             didTapApplink: EnterpriseTopicTapApplinkHandle?,
                             targetVC: UIViewController)

    func dismissEnterpriseTopic()
    
    func pageIsExistInStack(url: URL) -> Bool
    
    var routerParams: [String: Any]? { get }
    
    func showUserList(data: [UserInfoData.UserData], title: String?) -> UIViewController?
}

public protocol BrowserViewDocsAttribute: AnyObject {
    var docsInfo: DocsInfo? { get }
    var openSessionID: String? { get }
    var isShowComment: Bool { get set }
    var chatId: String? { get }
    var currentURL: URL? { get set }
    var loadedURL: URL? { get } //当前加载的 url
    var isInVideoConference: Bool { get }
    var spacePressesBeginTimestamp: Int? { get }
    var loadStatus: LoadStatus { get }
}
extension BrowserViewDocsAttribute {
    public var token: String? { return docsInfo?.objToken }
}

public protocol BaseBrowserUIResponder: SKBrowserUIResponder {
    @discardableResult
    func becomeFirst() -> Bool

    func setTrigger(trigger: String)
    func getTrigger() -> String?
    func addKeyboardResponder(_ responder: UIResponder)
    
    @discardableResult
    func resign() -> Bool
}

public protocol BrowserUIResponder: BaseBrowserUIResponder {
    var inputAccessory: SKInputAccessory { get }
    func setKeyboardDismissMode(_ mode: UIScrollView.KeyboardDismissMode)
    func startMonitorKeyboard()
    func stopMonitorKeyboard()
}

public protocol BrowserLoadingReporter: AnyObject {
    func didHideLoading()
    func failWithError(_ error: Error?)
}

public protocol BrowserLoadingAgent: AnyObject {
    func startLoadingAnimation()

    func stopLoadingAnimation()

    func showLoading()

    func hideLoading()
}

public protocol BitableAdPermissionSettingListener: AnyObject {
    func onBitableAdPermBridgeDataChange(_ data: BitableBridgeData)
}

extension BitableAdPermissionSettingListener {
    public func onBitableAdPermBridgeDataChange(_ data: BitableBridgeData) {}
}

public protocol BrowserViewDisplayConfig: AnyObject {

    var trailingButtonItems: [SKBarButtonItem] { get set }

    var rightBottomButtonItems: [UIButton]? { get set }

    var isEditButtonVisible: Bool { get }
    
    var isHistoryPanelShow: Bool { get set }

    var getCommentViewWidth: CGFloat { get }

    // 判断当前PopoverAt面板是否展示
    var isPopoverAtFinderScene: Bool? { get set }

    /// 当前render是否是DarMode
    var isRenderDarkMode: Bool { get set }

    func setTitle(_ title: String, for objToken: String)

    func setNavigation(titleInfo: NavigationTitleInfo?, needDisPlayTag: Bool?, tagValue: String?,
                       iconInfo: IconSelectionInfo?, canRename: Bool?)

    func setNavigation(title: String?)

    func setNavigation(secretTitle: String)

    /// 设置导航栏状态
    func setTitleBarStatus(_ status: Bool)

    /// 设置左滑返回是否开启
    func setToggleSwipeGestureEnable(_ enable: Bool)
    
    /// 设置全屏模式按钮是否可用
    func setFullScreenModeButtonEnable(_ enable: Bool)

    /// 设置无网banner状态
    func setOfflineTipViewStatus(_ status: Bool)

    ///展示/隐藏翻译按钮
    func showTranslateBtn()
    func hideTranslateBtn()

    ///处理文档删除事件
    func handleDeleteEvent()
    
    ///处理文档删除恢复事件
    func handleDeleteRecoverEvent()

    ///处理密钥删除事件
    func handleKeyDeleteEvent()
    
    ///处理文档 NotFound 事件
    func handleNotFoundEvent()

    /// 旋转屏幕
    func setOrientation(_ orientation: UIInterfaceOrientation)

    /// 设置编辑按钮是否可见
    func setEditButtonVisible(_ visible: Bool)

    /// 切换当前编辑模式至另一种 ()
    func toggleEditMode()
    
    /// 设置完成按钮是否可见
    func setCompleteButtonVisible(_ visible: Bool)

    /// 设置导航栏是否常驻（是代表一直显示，否代表跟随 webview 滑动进度来决定是否显示）
    func setNavBarFixedShowing(_ isFixed: Bool)
    
    /// 获取导航栏遮挡WebView的高度
    func getWebViewCoverHeight() -> CGFloat

    /// 设置iPad目录启用状态
    func setIpadCatalogState(isOpen: Bool)
    func obtianIPadCatalogState() -> Bool

    /// CodeBlock设置状态
    func setCodeBlockSceneStatus(_ isInCodeBlockScene: Bool)

    /// 设置编辑按钮位置
    func modifyEditButtonBottomOffset(height: CGFloat)

    /// 在 LM DM 切换时主动调用 window.clear + window.render(url, infos)
    func rerenderWebview(with docUrl: URL?)
    
    /// 是否展示“模板”tag
    func setShowTemplateTag(_ showTemplateTag: Bool)
    
    /// 收到删除通知是否可以展示删除兜底页
    func canShowDeleteVersionEmptyView(_ show: Bool)

    /// 设置外显目录是否显示
    func setCatalogueBanner(visible: Bool)
    
    /// 设置外显目录
    func setCatalogueBanner(catalogueBannerData: SKCatalogueBannerData?, callback: SKCatalogueBannerViewCallback?)
    
    func showBitableAdvancedPermissionsSettingVC(data: BitableBridgeData, listener: BitableAdPermissionSettingListener?)
    
    /// 刷新文（重走render流程）
    func refresh()
}
public extension BrowserViewDisplayConfig {
    func rerenderWebview() {
        self.rerenderWebview(with: nil)
    }
}

public protocol BrowserRequestAgent: AnyObject {
    var requestHeader: [String: String] { get }
    var currentUrl: URL? { get }
    func clearPreloadStatus()
    func addPreloadType(_ type: String)
    func notifyPreloadHtmlReady(preloadTypes: [String])
}

public protocol BrowserViewShareAgent {
    func browserViewRequestShareAccessory() -> UIView?
}

public protocol BrowserOpenDocAgent: AnyObject {
    func didBeginEdit()
}

public protocol BrowserSynchronizer {
    func didSync(with objToken: String, type: DocsType)
    func setNeedSync(_ shouldSync: Bool, for objToken: FileListDefine.ObjToken, type: DocsType)
}

public protocol BrowserOpenRecorder {
    func appendInfo(_ info: @autoclosure () -> String)
}

 public protocol BrowserFeedInfo {
    func markMessagesRead(_ params: [String: Any])

    func markFeedCardShortcut(isAdd: Bool, success: SKMarkFeedSuccess?, failure: SKMarkFeedFailure?)
    func needShowFeedCardShortcut(channel: Int) -> Bool
    func isFeedCardShortcut() -> Bool
}


public enum BrowserDocumentType {
    /// 当前宿主文档
    case hostDocument
    /// 关联文档
    case referenceDocument(objToken: String)
}

public protocol BrowserPermissionConfig: AnyObject {
    @available(*, deprecated, message: "Disambiguate using hostUserPermissions - PermissionUpdate")
    var userPermissions: UserPermissionAbility? { get set }
    /// 获取宿主文档用户权限
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    var hostUserPermissions: UserPermissionAbility? { get set }
    /// 获取宿主或关联文档用户权限
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    func getUserPermission(for: BrowserDocumentType) -> UserPermissionAbility?
    
    /// 获取宿主或关联文档权限服务
    func getPermissionService(for: BrowserDocumentType) -> UserPermissionService?
    
    /// 获取宿主或关联文档权限服务
    func getPermissionService(for docsType: DocsType, objToken: String) -> UserPermissionService?

    /// 更新宿主或关联文档用户权限，也会一并更新是否可复制状态
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    func update(userPermission: UserPermissionAbility?, for: BrowserDocumentType, objType: DocsType)
    /// 更新宿主或关联文档用户权限，也会一并更新是否可复制状态
    func update(permissionData: Data, for: BrowserDocumentType, objType: DocsType)
    /// 用户权限服务完成更新后的通知
    func notifyDidUpdate(permisisonResponse: UserPermissionResponse?, for: BrowserDocumentType, objType: DocsType)

    var publicPermissionMeta: PublicPermissionMeta? { get }

    func showApplyPermissionView(_ canApply: Bool, name: String, ownerID: String, blockType: SKApplyPermissionBlockType)
    func dismissApplyPermissionView()
    /// 当前是否显示无权限申请界面
    var isShowingApplyPermissionView: Bool { get }

    @available(*, deprecated, message: "Disambiguate using hostCanCopy - PermissionUpdate")
    var canCopy: Bool { get }
    /// 宿主文档是否可以复制内容，已综合了admin权限
    var hostCanCopy: Bool { get }
    /// 宿主文档是否可截屏：文档权限 & 同步块数组权限
    var hostCaptureAllowed: Bool { get }
    /// 宿主或关联文档是否可以复制内容、截屏录屏，已综合了admin权限
    func checkCanCopy(for documentType: BrowserDocumentType) -> Bool
    // TODO: 去掉 canCopy 的缓存，每次都重新计算？
    /// DLP、CAC 等状态变化时，需要更新 canCopy 状态
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    func notifyPermissionUpdate(for documentType: BrowserDocumentType, type: DocsType)
    @available(*, deprecated, message: "Disambiguate using hostPermissionEventNotifier - PermissionUpdate")
    var permissionEventNotifier: DocsPermissionEventNotifier { get }
    /// 用于注册监听：宿主文档权限变化了
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    var hostPermissionEventNotifier: DocsPermissionEventNotifier { get }
    /// 用于注册监听宿主或关联文档权限变化了
    @available(*, deprecated, message: "Use UserPermissionService instead - PermissionSDK")
    func getPermissionEventNotifier(for: BrowserDocumentType) -> DocsPermissionEventNotifier
}

/// Block全屏模式下定制化TopContainer
public protocol CustomTopContainerDisplayConfig: AnyObject {
    // change the top container is displayed and initialize if needed
    func setCustomTopContainer(isShow: Bool)
    // change the `isHidden` of the top container
    func setCustomTopContainerHidden(_ hidden: Bool)
    func customTopContainerShow() -> Bool

    // change the top container pattern
    var leftBarButtonItems: [SKBarButtonItem]? { get set }
    var rightBarButtonItems: [SKBarButtonItem]? { get set }
    var layoutAttributes: SKNavigationBar.LayoutAttributes? { get set }
    var hideCustomHeaderInLandscape: Bool? { get set }

    func setCustomTCTitleInfo(_ titleInfo: NavigationTitleInfo?)
    func setCustomTCTitleHorizontalAlignment(_ titleHorizontalAlignment: UIControl.ContentHorizontalAlignment)

    func shouldShowDivider(_ show: Bool)
    func setCustomTCThemeColor(_ themeColor: String)

    // interactive action
    func setCustomTCInteractivePopGestureAction(_ action: @escaping () -> Void)

    // special logic
    func setCustomCenterView(_ view: CustomSubTopContainer?)
    func setCustomRightView(_ view: CustomSubTopContainer?)
    func getCustomCenterView() -> CustomSubTopContainer?
    
    // 保存popGesture的delegate，在注销时将popGesture的delegate设置成原来的值
    func setPreNaviPopGestureDelegate(naviPopGestureDelegate: UIGestureRecognizerDelegate?)
}

public protocol CustomSubTopContainer: UIView {
    // 某些场景下需要给出具体的宽高
    func currentLayout() -> CGSize
}

public protocol VerisonHistoryPanelDisplayer {
    func showVersionPanel(token: String, type: DocsType)
}
