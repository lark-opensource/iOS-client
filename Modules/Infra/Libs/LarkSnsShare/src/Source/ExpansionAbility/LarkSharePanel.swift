//
//  LarkSharePanel.swift
//  LarkSnsShare
//
//  Created by Siegfried on 2021/12/14.
//

import Foundation
import UIKit
import RxSwift
import LarkShareToken
import LarkUIKit
import LarkFoundation
import UniverseDesignTheme
import LKCommonsLogging
import LarkEMM
import LarkSensitivityControl
import UniverseDesignToast
import LarkContainer
import EENavigator

public final class LarkSharePanel: NSObject, LarkShareItemClickDelegate, SnsShareDelegate {
    private static var token = Token("LARK-PSDA-pasteboard_larksharepanel")
    private static var beforeShowDowngradeTipToken = Token("LARK-PSDA-sharePanel_before_show_downgradeTip")
    private static var saveImageInDowngradeTipToken = Token("LARK-PSDA-sharePanel_auto_save_image_in_downgradeTip")
    private static var saveImageButtonClickedToken = Token("LARK-PSDA-sharePanel_save_image_button_clicked")

    let userResolver: UserResolver
    // MARK: API
    /// 动态配置分享选项
    /// productLevel / scene 的字段文档链接: https://bytedance.feishu.cn/sheets/shtcnAcBrNPsFxdeVs4U54Ihywc
    ///
    /// - Parameter by: 当前项目场景标志符
    /// - Parameter shareContent: 分享内容
    /// - Parameter on: 基于哪个VC弹出
    /// - Parameter popoverMaterial: popover状态下相关配置
    /// - Parameter productLevel: 面板展示所在业务 - 埋点用
    /// - Parameter scene: 面板展示所在业务场景 - 埋点用
    /// - Parameter pasteConfig: 分享面板剪贴板配置
    public init(userResolver: UserResolver,
                by traceId: String,
                shareContent contentContext: ShareContentContext,
                on baseViewController: UIViewController,
                popoverMaterial: PopoverMaterial,
                productLevel: String,
                scene: String,
                pasteConfig: SnsPasteConfig? = nil
    ) {
        self.userResolver = userResolver
        self.traceId = traceId
        self.previousContentContext = contentContext
        self.currentContentContext = contentContext
        self.baseViewController = baseViewController
        self.popoverMaterial = popoverMaterial
        self.productLevel = productLevel
        self.scene = scene
        self.pasteConfig = pasteConfig
        if pasteConfig == nil {
            assertionFailure("pasteConfig param better be set, default can't paste externally")
        }
    }

    /// 静态配置分享选项
    /// productLevel / scene 的字段文档链接: https://bytedance.feishu.cn/sheets/shtcnAcBrNPsFxdeVs4U54Ihywc
    ///
    /// - Parameter with: 本地配置的分享选项列表
    /// - Parameter shareContent: 分享内容
    /// - Parameter on: 基于哪个VC弹出
    /// - Parameter popoverMaterial: popover状态下相关配置
    /// - Parameter productLevel: 面板展示所在业务 - 埋点用
    /// - Parameter scene: 面板展示所在业务场景 - 埋点用
    /// - Parameter pasteConfig: 分享面板剪贴板配置
    public init(userResolver: UserResolver,
                with staticItemTypes: [LarkShareItemType],
                shareContent contentContext: ShareContentContext,
                on baseViewController: UIViewController,
                popoverMaterial: PopoverMaterial,
                productLevel: String,
                scene: String,
                pasteConfig: SnsPasteConfig? = nil
    ) {
        self.userResolver = userResolver
        self.shareItemTypes = staticItemTypes
        self.currentContentContext = contentContext
        self.previousContentContext = contentContext
        self.baseViewController = baseViewController
        self.popoverMaterial = popoverMaterial
        self.productLevel = productLevel
        self.scene = scene
        self.pasteConfig = pasteConfig
        if pasteConfig == nil {
            assertionFailure("pasteConfig param better be set, default can't paste externally")
        }
    }

    /// 分享面板代理
    public weak var delegate: LarkSharePanelDelegate?
    /// 是否允许旋转
    public var isRotatable: Bool = false
    /// 分享面板是否已经被关闭
    public private(set) var isDismissed: Bool = true
    /// traceId无法获取时，本地兜底分享类型
    public var defaultShareItemTypes: [LarkShareItemType]?
    /// 降级面板相关配置
    public var downgradeTipPanel: DowngradeTipPanelMaterial? {
        didSet {
            self.currentDowngradeTipPanelMaterial = downgradeTipPanel
            self.previousDowngradeTipPanelMaterial = downgradeTipPanel
        }
    }
    /// 面板标题
    public var title: String? {
        didSet {
            guard let title = title else { return }
            self.headerTitle = title
        }
    }
    /// 自定义文本分享类型映射
    public var customShareContextMapping: [String: CustomShareContext] = [:]
    /// 业务方设置图片的闭包
    public var setImageBlock: ((LarkSharePanel) -> Void)?
    /// 本地降级检查
    public var needDowngradeChecker: ((LarkShareItemType) -> Bool)?
    /// 本地中断操作
    public var downgradeInterceptor: ((_ itemType: LarkShareItemType) -> Void)?
    /// 指定分享面板亮暗模式
    @available(iOS 13.0, *)
    public var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        set {
            self.currentUserInterfaceStyle = SharePanelTheme.convert(from: newValue)
        }
        get {
            return SharePanelTheme.convert(from: currentUserInterfaceStyle)
        }
    }
    /// 业务加载完图片后调用imageReady 通知面板图片下载完成
    /// - Parameters:
    ///   - with: 就绪的图片资源
    ///   - imageTitle: 图片标题，不填则从一级面板的上下文中获取
    ///   - downgradeTipPanelTitle: 降级面板的标题，不填默认为预设文案 `已保存至相册`
    public func notifyImageReady(with image: UIImage,
                                 imageTitle: String? = nil,
                                 downgradeTipPanelTitle: String? = nil) {
        guard let imagePanel = self.shareImagePanel else {
            assertionFailure("IMAGE SHARE PANEL IS NOT INIT")
            return
        }
        imagePanel.showImageAndHideLoading(with: image)
        let imagePrepare = ImagePrepare(title: imageTitle ?? self.getImageTitleFromContext(), image: image)
        self.currentContentContext = ShareContentContext.image(imagePrepare)
        self.currentDowngradeTipPanelMaterial = DowngradeTipPanelMaterial.image(panelTitle: downgradeTipPanelTitle)
    }

    /// 展示分享面板
    ///
    /// ```swift
    /// shareResultCallback: ((ShareResult, LarkShareItemType) -> Void)?
    /// ```
    /// - Parameters:
    ///  - shareResultCallback: 分享回调
    public func show(_ shareResultCallback: ((ShareResult, LarkShareItemType) -> Void)?) {
        guard let baseViewController = self.baseViewController else { return }
        self.shareCallback = shareResultCallback
        if let traceId = self.traceId {
            _Self.logger.info("""
                [LarkSharePanel] showDynamicVC
            """)
            showDynamicVC(traceId: traceId,
                          on: baseViewController)
        } else {
            _Self.logger.info("""
                [LarkSharePanel] showDynamicVC
            """)
            showStaticVC(itemTypes: self.shareItemTypes,
                         on: baseViewController)
        }
    }

    /// 设置配置区数据源
    /// - parameter dataSource: 配置项的数据源
    public func setShareSettingDataSource(dataSource: [[ShareSettingItem]]) {
        for section in dataSource {
            for item in section {
                self.shareSettingStorage[item.identifier] = item
            }
        }
        self.currentShareSettingGroups = dataSource
    }

    /// 更新单个配置项
    /// - parameter newItem: 更新后的一个配置项
    public func updateShareSettingItem(newItem: ShareSettingItem) {
        guard self.shareSettingStorage.keys.contains(newItem.identifier) else {
            assertionFailure("identifier is not exist")
            return
        }
        let newGroup: [[ShareSettingItem]] = self.currentShareSettingGroups.map { section in
            let section = section.map { oldItem -> ShareSettingItem in
                if oldItem.identifier == newItem.identifier {
                    return newItem
                }
                return oldItem
            }
            return section
        }
        self.shareActionPanel?.reloadSettingData(dataSource: newGroup)
    }

    /// 关闭分享面板
    public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.shareActionPanel?.dismissCurrentVC(animated: flag)
        self.shareImagePanel?.dismissCurrentVC(animated: flag)
        completion?()
    }

    // MARK: Priority
    private enum DatasourceMode {
        case dynamic
        case local
    }
    /// 剪贴板配置
    private var pasteConfig: SnsPasteConfig?
    private var currentDisposable: Disposable?
    private weak var lastBasePresenterDelegate: SnsShareDelegate?
    /// python脚本分词
    private lazy var dynamicConfParser: ShareConfigurationProvider = ShareDynamicConfigurationParser(shareDynamicAPI: try? userResolver.resolve(assert: ShareDynamicAPI.self))
    /// 当前远端分享配置
    private var currentShareConfiguration: ShareDynamicConfiguration?
    /// 头部标题
    private var headerTitle: String = BundleI18n.LarkSnsShare.Lark_UD_SharePanelShareTitle
    /// ipad popover配置
    private var popoverMaterial: PopoverMaterial
    /// 当前打开的分享面板
    private var currentPanelType: PanelType = .actionPanel
    /// 分享面板
    private weak var shareActionPanel: LarkShareActionPanel?
    /// 图片面板
    private weak var shareImagePanel: LarkShareImagePanel?
    /// 基于哪个VC弹出
    private weak var baseViewController: UIViewController?
    /// 当前点击的分享类型
    private var currentItemType: LarkShareItemType = .unknown
    /// 远端配置时的 traceID
    private var traceId: String?
    /// 展示的分享选项，默认显示为 [.wechat, .weibo, .qq, .more(.default), .timeline]
    private var shareItemTypes: [LarkShareItemType] = LarkShareItemType.snsItems()
    /// 图片面板分享选项
    private var imageShareTypes: [LarkShareItemType]?
    /// 当前分享上下文
    private var currentContentContext: ShareContentContext
    /// 被图片分享覆盖前的一级面板的分享上下文
    private var previousContentContext: ShareContentContext
    /// 当前面板相关降级配置
    private var currentDowngradeTipPanelMaterial: DowngradeTipPanelMaterial?
    /// 被图片分享覆盖前的一级面板降级配置
    private var previousDowngradeTipPanelMaterial: DowngradeTipPanelMaterial?
    /// 当前配置区配置项
    private var currentShareSettingGroups: [[ShareSettingItem]] = []
    /// 当前配置区标识与配置项映射
    private var shareSettingStorage: [String: ShareSettingItem] = [:]
    /// 分享回调
    private var shareCallback: ((ShareResult, LarkShareItemType) -> Void)?
    /// 埋点数据：面板展示所在业务
    private var productLevel: String
    /// 埋点数据：分享面板所在业务场景
    private var scene: String
    /// 当前的 userInterfaceStyle，0: unspecified，1: light，2: dark
    private var currentUserInterfaceStyle: SharePanelTheme = .unspecified
    /// 日志系统
    private typealias _Self = LarkSharePanel
    private static let logger = Logger.log(LarkSharePanel.self, category: "lark.sns.share.ud.LarkSharePanel")
    /// 当前数据源类型
    private var mode: DatasourceMode = .local {
        willSet {
            if case .local = newValue {
                self.currentShareConfiguration = nil
                self.currentDowngradeTipPanelMaterial = nil
            }
        }
    }

    /// 远端配置面板
    private func showDynamicVC(traceId: String,
                               on baseViewController: UIViewController) {
        /// 异步获取settings中的配置
        self.currentDisposable = self.dynamicConfParser.parse(traceId: traceId).subscribe { [weak self] configuration in
            guard let self = self else { return }
            self.mode = .dynamic
            self.currentShareConfiguration = configuration
            self.shareItemTypes = configuration.items.compactMap { panelItem in
                /// 获取自定义内容的上下文，建立映射
                if case .custom(let identifier) = panelItem {
                    if let context = self.customShareContextMapping[identifier] {
                        return .custom(context)
                    }
                    return nil
                }
                return panelItem.toShareItem()
            }
            self.showStaticVC(itemTypes: self.shareItemTypes, on: baseViewController)
        } onError: { [weak self] error in
            guard let self = self else { return }
            self.mode = .local
            if let err = error as? DynamicConfParseError {
                var errorCode = ShareResult.ErrorCode.unknownError
                var errorMsg = "unknown"
                switch err {
                case .parseFailed:
                    errorCode = .dynamicConfParseFailed
                    errorMsg = "dynamicConfParseFailed"
                case .fetchFailed:
                    errorCode = .dynamicConfFetchFailed
                    errorMsg = "dynamicConfFetchFailed"
                case .illegalConfigurationStruct:
                    errorCode = .illegalConfigurationStruct
                    errorMsg = "illegalConfigurationStruct"
                case .traceIdNotFound:
                    errorCode = .traceIdNotFound
                    errorMsg = "traceIdNotFound"
                }
                _Self.logger.error("""
                    [LarkSharePanel] parse dynamic conf failed,
                    traceId = \(traceId),
                    errCode = \(errorCode.rawValue)
                """)
                self.shareCallback?(.failure(errorCode, errorMsg), .unknown)
                // 解析出错 ，转为降级策略或兜底策略
                self.showStaticVC(itemTypes: self.defaultShareItemTypes ?? self.shareItemTypes, on: baseViewController)
            } else {
                _Self.logger.error("""
                    [LarkSharePanel] parse dynamic conf failed with unknown error,
                    traceId = \(traceId),
                    description = \(error.localizedDescription)
                """)
                self.shareCallback?(.failure(.unknownError, "未知错误，请联系 dongwei.1615@bytedance.com 进一步排查"), .unknown)
            }
        }
    }

    /// 本地配置面板
    private func showStaticVC(itemTypes: [LarkShareItemType], on baseViewController: UIViewController) {
        // 应用瘦身，飞书/Lark 采用不同分享
        let filteredItems = itemTypes.filter { (itemType) -> Bool in
            return ShareSlimming.currentWhitelist().contains(itemType)
        }
        // 对图片面板的分享选项继承自actionPanel
        if self.setImageBlock != nil {
            self.imageShareTypes = filteredItems.map({ itemType in
                switch itemType {
                case .shareImage:
                    return .save
                default:
                    return itemType
                }
            }).filter({ itemType in
                return itemType != .copy
            })
        }

        if filteredItems.isEmpty {
            // 过滤后的选项为空，弹出系统分享
            handleSystemShare(presentFrom: baseViewController, contentContext: self.currentContentContext)
        } else if let item = onlyOneSnsItem(filteredItems) {
            // 如果只配置了仅一个分享相关的item，会直接模拟手动点击唤起app分享或进入降级流程
            handleShareAction(by: item)
        } else {
            presentPanel(shareTypes: itemTypes, delegate: self, on: baseViewController)
        }
    }

    /// 弹出分享面板
    private func presentPanel(shareTypes: [LarkShareItemType]?,
                              delegate: LarkShareItemClickDelegate?,
                              on baseViewController: UIViewController?) {
        guard let shareTypes = shareTypes,
              let delegate = delegate,
              let baseViewController = baseViewController else { return }
        self.currentContentContext = self.previousContentContext
        self.currentDowngradeTipPanelMaterial = self.previousDowngradeTipPanelMaterial
        let customShareVC = LarkShareActionPanel(shareTypes: shareTypes,
                                                 shareSettingDataSource: self.currentShareSettingGroups,
                                                 popoverMaterial: self.popoverMaterial,
                                                 delegate: delegate,
                                                 self.productLevel,
                                                 self.scene)
        customShareVC.panelHeader.title = headerTitle
        customShareVC.isRotatable = self.isRotatable
        if #available(iOS 13, *), self.currentUserInterfaceStyle != .unspecified {
            customShareVC.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
        }
        self.shareActionPanel = customShareVC
        baseViewController.present(customShareVC, animated: true) { [weak self] in
            guard let self = self else { return }
            self.currentPanelType = .actionPanel
            self.isDismissed = false
            _Self.logger.info("[LarkSharePanel] custom share panel did show")
            SharePanelTracker.trackerPublicSharePanelView(productLevel: self.productLevel, scene: self.scene)
        }
    }

    /// 检测是否只有一个分享选项 且为 常用类型
    private func onlyOneSnsItem(_ items: [LarkShareItemType]) -> LarkShareItemType? {
        if items.count == 1, let item = items.first(where: { (item) -> Bool in
            LarkShareItemType.snsItems().contains(item)
        }) {
            return item
        }
        return nil
    }

    /// 是否触发降级
    private func triggleDowngrade(_ itemType: LarkShareItemType) -> Bool {
        if case .local = mode, downgradeInterceptor != nil {
            return needDowngradeChecker?(itemType) ?? false
        }
        return false
    }

    /// 分享区按钮点击事件回调
    func shareItemDidClick(itemType: LarkShareItemType) {
        _Self.logger.info("[LarkSharePanel] item <\(itemType.rawValue)> did click")
        self.delegate?.clickShareItem(at: itemType, in: self.currentPanelType)
        SharePanelTracker.trackerPublicSharePanelClick(productLevel: self.productLevel,
                                                       scene: self.scene,
                                                       clickItem: itemType,
                                                       clickOther: nil,
                                                       panelType: self.currentPanelType)
        handleShareAction(by: itemType)
    }

    /// 关闭回调
    func sharePanelDidClosed() {
        _Self.logger.info("[LarkSharePanel] user cancel manually")
        self.shareCallback?(.failure(.userCanceledManually, "userCanceledManually"), .unknown)
    }
}

// MARK: - App Share Awake
extension LarkSharePanel {
    private func transItemTypeToSnsType(itemType: LarkShareItemType) -> SnsType? {
        var snsType: SnsType? = nil
        switch itemType {
        case .wechat, .timeline:
            snsType = .wechat
        case .qq:
            snsType = .qq
        case .weibo:
            snsType = .weibo
        default:
            break
        }
        return snsType
    }

    private func getToastWindow() -> UIWindow? {
        return self.baseViewController?.view.window
    }

    private func showShareSDKAuthTips(snsType: SnsType) {
        guard let window = self.getToastWindow() else { return }
        let text = LarkShareBasePresenter.shared.getShareSdkDenyTipText(snsType: snsType)
        UDToast.showFailure(with: text, on: window)
    }

    private func handleShareAction(by itemType: LarkShareItemType) {
        //分享类型涉及分享SDK，且无SDK权限时，拦截并弹提示
        if let snsType = self.transItemTypeToSnsType(itemType: itemType),
           !LarkShareBasePresenter.shared.checkShareSDKAuthority(snsType: snsType) {
            self.showShareSDKAuthTips(snsType: snsType)
            dismissSharePanelIfNeeded()
            dismissImagePanelIfNeeded()
            return
        }
        // 如果 mode = local，则检测业务方是否有提供降级拦截
        if triggleDowngrade(itemType), let interceptor = downgradeInterceptor {
            interceptor(itemType)
            dismissSharePanelIfNeeded()
            dismissImagePanelIfNeeded()
            shareCallback?(.failure(.triggleDowngradeHandle, "triggleDowngradeHandle"), itemType)
            return
        }
        handleCustomAppShare(type: itemType)
    }

    private func handleCustomAppShare(type: LarkShareItemType) {
        guard let baseViewController = self.baseViewController else {
            assertionFailure("baseViewController can not be nil")
            return
        }

        self.currentItemType = type

        switch type {
        case .wechat:
            if doDynamicDowngradeIfNeeded(panelItem: .wechatSession, ShareHandler: { [weak self] in
                guard let self = self else { return }
                handleThirdApplicationShare(
                    snsType: .wechat,
                    snsScenes: .wechatSession,
                    shareContentContext: self.currentContentContext
                )
            }) { return }
        case .timeline:
            if doDynamicDowngradeIfNeeded(panelItem: .wechatTimeline, ShareHandler: { [weak self] in
                guard let self = self else { return }
                handleThirdApplicationShare(
                    snsType: .wechat,
                    snsScenes: .wechatTimeline,
                    shareContentContext: self.currentContentContext
                )
            }) { return }
        case .weibo:
            if doDynamicDowngradeIfNeeded(panelItem: .weibo, ShareHandler: { [weak self] in
                guard let self = self else { return }
                handleThirdApplicationShare(
                    snsType: .weibo,
                    snsScenes: nil,
                    shareContentContext: self.currentContentContext
                )
            }) { return }
        case .qq:
            if doDynamicDowngradeIfNeeded(panelItem: .qq, ShareHandler: { [weak self] in
                guard let self = self else { return }
                if case .text = self.currentContentContext {
                    assertionFailure("text is not support for qq platform, please check!")
                    return
                }
                handleThirdApplicationShare(
                    snsType: .qq,
                    snsScenes: .qqSpecifiedSession,
                    shareContentContext: self.currentContentContext
                )
            }) { return }
        case .copy:
            dismissSharePanelIfNeeded()
            if case .text(let textPrepare) = self.currentContentContext {
                handleCopyAction(content: textPrepare.content)
            } else if case .webUrl(let webUrlPrepare) = self.currentContentContext {
                handleCopyAction(content: webUrlPrepare.webpageURL)
            } else {
                assertionFailure("copy just support for text or weburl share, please check!")
            }
        case .more:
            handleSystemShare(presentFrom: baseViewController, contentContext: self.currentContentContext)
            return
        case .save:
            if case .image(let imagePrepare) = self.currentContentContext {
                handleSaveAction(image: imagePrepare.image)
            } else {
                assertionFailure("save just support for image, please check!")
            }
        case .shareImage:
            dismissSharePanelIfNeeded()
            checkToPresentImagePanel(on: baseViewController)
        case .custom(let shareContext):
            dismissSharePanelIfNeeded()
            dismissImagePanelIfNeeded()
            shareContext.action(shareContext.content, baseViewController, self.currentPanelType)
            return
        default: break
        }
        if currentItemType == .shareImage {
            dismissSharePanelIfNeeded()
        } else {
            dismissSharePanelIfNeeded()
            dismissImagePanelIfNeeded()
        }
    }

    private func doDynamicDowngradeIfNeeded(panelItem: PanelItem, ShareHandler: () -> Void) -> Bool {
        dismissSharePanelIfNeeded()
        dismissImagePanelIfNeeded()

        if case .dynamic = mode,
           let conf = self.currentShareConfiguration,
           conf.answerTypeMapping.contains(where: { (kv) -> Bool in
               return kv.key == panelItem
           }),
           let answerType = conf.answerTypeMapping[panelItem],
           let baseViewController = baseViewController {

            switch answerType {
            case .ban,
                 .downgradeToSystemShare:
                handleSystemShare(presentFrom: baseViewController, contentContext: self.currentContentContext)
            case .downgradeToWakeupByTip where self.currentDowngradeTipPanelMaterial != nil:
                handleDowngradeWakeupByTip(panelItem: panelItem,
                                           presentFrom: baseViewController,
                                           contentContext: self.currentContentContext)
            default:
                _Self.logger.error("enter exception flow，currentShareConfiguration = \(conf)")
                handleSystemShare(presentFrom: baseViewController, contentContext: self.currentContentContext)
            }
            return true
        } else {
            ShareHandler()
            return false
        }
    }

    /// 降级策略 - 弹窗
    // nolint: duplicated_code 老组件代码下线后将不再重复
    private func handleDowngradeWakeupByTip(panelItem: PanelItem, presentFrom: UIViewController, contentContext: ShareContentContext) {
        if let snsType = panelItem.toSnsType(), var material = currentDowngradeTipPanelMaterial {
            // 如果业务方没有提供粘贴板展示内容，那么将本次的分享内容作为展示内容
            if case .text(let panelTitle, let content) = currentDowngradeTipPanelMaterial, content == nil {
                switch contentContext {
                case .text(let textPrepare):
                    material = .text(panelTitle: panelTitle, content: textPrepare.content)
                case .image(let imagePrepare):
                    material = .text(panelTitle: panelTitle, content: imagePrepare.description)
                case .webUrl(let webUrlPrepare):
                    material = .text(panelTitle: panelTitle, content: webUrlPrepare.webpageURL)
                case .miniProgram(let miniProgram):
                    material = .text(panelTitle: panelTitle, content: miniProgram.webPageURLString)
                }
                currentDowngradeTipPanelMaterial = material
            }

            func presentAwakePanel() {
                self.presentTipPanel(
                    snsType: snsType,
                    panelItem: panelItem,
                    presentFrom: presentFrom,
                    contentContext: contentContext,
                    material: material
                )
            }

            if case .image = material {
                do {
                    try Utils.checkPhotoWritePermission(token: Self.beforeShowDowngradeTipToken) { [weak self] (granted) in
                        guard granted else {
                            _Self.logger.info("""
                                [LarkSnsShare] handleDowngradeWakeupByTip, no photo write permission
                            """)
                            self?.shareCallback?(
                                .failure(.saveImageFailed,
                                         BundleI18n.LarkSnsShare.Lark_Legacy_AssetBrowserPhotoDenied),
                                panelItem.toShareItem())
                            return
                        }
                        presentAwakePanel()
                    }
                } catch {
                    _Self.logger.error("[LarkSnsShare] handleDowngradeWakeupByTip, checkPhototWritePermission failed, error: \(error)")
                }
            } else {
                presentAwakePanel()
            }
        }
    }
    // enable-lint: duplicated_code
    
    private func copyToPasteBoard(content: String) {
        if self.pasteConfig == nil {
            assertionFailure("pasteConfig param better be set, default can't paste externally")
        }
        switch self.pasteConfig {
        case .scPaste, .none:
            let config = PasteboardConfig(token: Self.token)
            SCPasteboard.general(config).string = content
        case .scPasteImmunity:
            let config = PasteboardConfig(token: Self.token, shouldImmunity: true)
            SCPasteboard.general(config).string = content
        }
        _Self.logger.info("""
            [LarkSharePanel] copy text to pasteBoard,
            paste config: \(self.pasteConfig?.rawValue ?? "")
        """)
    }

    private func presentTipPanel(
        snsType: SnsType,
        panelItem: PanelItem,
        presentFrom: UIViewController,
        contentContext: ShareContentContext,
        material: DowngradeTipPanelMaterial
    ) {
        self.isDismissed = false
        let tipPanel = SnsDowngradeTipPanel(snsType: snsType, material: material) { [weak self] _ in
            switch material {
            case .text(_, let content):
                if let content = content {
                    self?.recordCopyContent(content)
                    self?.copyToPasteBoard(content: content)
                }
            case .image:
                if case .image(let imageData) = contentContext {
                    do {
                        try Utils.savePhoto(token: Self.saveImageInDowngradeTipToken, image: imageData.image) { [weak self] (success, granted) in
                            if success && granted {
                                _Self.logger.info("""
                                    [LarkSnsShare] handleDowngradeWakeupByTip,
                                    save image success, panelItem = \(panelItem.rawValue)
                                """)
                            } else {
                                _Self.logger.info("""
                                    [LarkSnsShare] handleDowngradeWakeupByTip,
                                    save image failed, hasSuccess = \(success), hasGranted = \(granted)
                                """)
                                self?.shareCallback?(
                                    .failure(.saveImageFailed,
                                             BundleI18n.LarkSnsShare.Lark_UD_SharePanelSaveFailRetryToast),
                                    panelItem.toShareItem())
                            }
                        }
                    } catch {
                        _Self.logger.error("[LarkSnsShare] handleDowngradeWakeupByTip, save photo failed, error: \(error)")
                    }
                } else {
                    assertionFailure("share content type must be `image`, please check!")
                }
            }
        } ctaButtonDidClick: { [weak self] (panel) in
            guard let self = self else { return }
            SharePanelTracker.trackerPublicSharePanelConfirmViewClick(productLevel: self.productLevel,
                                                                      scene: self.scene,
                                                                      click: "open",
                                                                      extra: ["target": "none"])
            let wakeupResult = LarkShareBasePresenter.shared.wakeup(snsType: snsType)
            if let error = wakeupResult.1, !wakeupResult.0 {
                switch error {
                case .notInstalled:
                    self.shareCallback?(
                        .failure(
                            .notInstalled,
                            BundleI18n.LarkSnsShare.Lark_UserGrowth_InvitePeopleContactsShareNotInstalled
                        ),
                        panelItem.toShareItem()
                    )
                case .sdkWakeupFailed:
                    self.shareCallback?(
                        .failure(
                            .snsDominError,
                            "wakeup failed, please check third share sdk log"
                        ),
                        panelItem.toShareItem()
                    )
                case .notSupported:
                    self.shareCallback?(
                        .failure(
                            .unknownError,
                            "this share channel do not support"
                        ),
                        panelItem.toShareItem()
                    )
                }
            } else {
                self.shareCallback?(.success, panelItem.toShareItem())
            }
            panel.dismiss()
            self.isDismissed = true
        } skipButtonDidClick: { [weak self] (panel) in
            guard let self = self else { return }
            SharePanelTracker.trackerPublicSharePanelConfirmViewClick(productLevel: self.productLevel,
                                                                      scene: self.scene,
                                                                      click: "cancel",
                                                                      extra: ["target": "none"])
            panel.dismiss()
            self.isDismissed = true
            self.shareCallback?(.failure(.userCanceledManually, "userCanceledManually"), .unknown)
        }
        if #available(iOS 13, *), self.currentUserInterfaceStyle != .unspecified {
            tipPanel.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
            tipPanel.modalPresentationCapturesStatusBarAppearance = true
        }
        presentFrom.present(tipPanel, animated: false, completion: { [weak self] in
            guard let self = self else { return }
            self.isDismissed = false
            SharePanelTracker.trackerPublicSharePanelConfirmView(productLevel: self.productLevel, scene: self.scene)
        })
    }

    /// 检测app是否安装
    private func preCheckAppInstall(_ snsType: SnsType) -> Bool {
        switch snsType {
        case .wechat:
            return LarkShareBasePresenter.shared.isAvaliable(snsType: .wechat)
        case .qq:
            return LarkShareBasePresenter.shared.isAvaliable(snsType: .qq)
        case .weibo:
            return LarkShareBasePresenter.shared.isAvaliable(snsType: .weibo)
        }
    }

    private func prepare(_ snsType: SnsType) {
        switch snsType {
        case .wechat, .qq, .weibo:
            if let lastDelegate = LarkShareBasePresenter.shared.delegate {
                lastBasePresenterDelegate = lastDelegate
            }
            LarkShareBasePresenter.shared.delegate = self
        }
    }

    private func handleThirdApplicationShare(
        snsType: SnsType,
        snsScenes: SnsScenes?,
        shareContentContext: ShareContentContext
    ) {
        guard preCheckAppInstall(snsType) else {
            _Self.logger.info("[LarkSharePanel] app not installed, snsType = \(snsType.rawValue)")
            shareCallback?(.failure(.notInstalled, BundleI18n.LarkSnsShare.Lark_UserGrowth_InvitePeopleContactsShareNotInstalled), currentItemType)
            return
        }

        prepare(snsType)

        switch shareContentContext {
        case .text(let textPrepare):
            _Self.logger.info("[LarkSharePanel] share text to \(snsScenes?.rawValue ?? "") of \(snsType.rawValue)")
            LarkShareBasePresenter.shared.sendText(
                navigatable: userResolver.navigator,
                snsType: snsType,
                snsScenes: snsScenes,
                text: textPrepare.content,
                customCallbackUserInfo: textPrepare.customCallbackUserInfo
            )
        case .image(let imagePrepare):
            _Self.logger.info("[LarkSharePanel] share image to \(snsScenes?.rawValue ?? "") of \(snsType.rawValue)")
            LarkShareBasePresenter.shared.sendImage(
                navigatable: userResolver.navigator,
                snsType: snsType,
                snsScenes: snsScenes,
                image: imagePrepare.image,
                title: imagePrepare.title,
                description: imagePrepare.description,
                customCallbackUserInfo: imagePrepare.customCallbackUserInfo
            )
        case .webUrl(let webUrlPrepare):
            _Self.logger.info("[LarkSharePanel] share webUrl to \(snsScenes?.rawValue ?? "") of \(snsType.rawValue)")
            LarkShareBasePresenter.shared.sendWebPageURL(
                navigatable: userResolver.navigator,
                snsType: snsType,
                snsScenes: snsScenes,
                webpageURL: webUrlPrepare.webpageURL,
                thumbnailImage: webUrlPrepare.thumbnailImage ?? Resources.share_icon_logo,
                imageURL: webUrlPrepare.imageURL,
                title: webUrlPrepare.title,
                description: webUrlPrepare.description,
                customCallbackUserInfo: webUrlPrepare.customCallbackUserInfo
            )
        case .miniProgram(let miniProgramPrepare):
            _Self.logger.info("[LarkSharePanel] share miniProgram to \(snsScenes?.rawValue ?? "") of \(snsType.rawValue)")
            LarkShareBasePresenter.shared.sendMiniProgram(
                navigatable: userResolver.navigator,
                snsType: snsType,
                snsScenes: snsScenes,
                title: miniProgramPrepare.title,
                webPageURLString: miniProgramPrepare.webPageURLString,
                miniProgramUserName: miniProgramPrepare.miniProgramUserName,
                miniProgramPath: miniProgramPrepare.miniProgramPath,
                launchMiniProgram: miniProgramPrepare.launchMiniProgram,
                thumbnailImage: miniProgramPrepare.thumbnailImage,
                description: miniProgramPrepare.description
            )
        }
    }

    private func handleSystemShare(presentFrom: UIViewController, contentContext: ShareContentContext) {
        var activityItems: [Any] = []
        switch contentContext {
        case .text(let textPrepare):
            activityItems.append(textPrepare.content)
        case .image(let imagePrepare):
            activityItems.append(imagePrepare.image)
        case .webUrl(let weburlPrepare):
            let link = LinkActivityItemProvider(title: weburlPrepare.title, url: weburlPrepare.webpageURL)
            activityItems.append(link)
            // 用以处理拷贝到剪切板时不复制图片
            let image = ActivityItemProvider(placeholderItem: weburlPrepare.thumbnailImage ?? Resources.share_icon_logo)
            activityItems.append(image)
            if let webpageUrl = URL(string: weburlPrepare.webpageURL) {
                let url = ActivityItemProvider(placeholderItem: webpageUrl)
                activityItems.append(url)
            }
        case .miniProgram(let miniProgramPrepare):
            activityItems.append(miniProgramPrepare.title)
            activityItems.append(miniProgramPrepare.thumbnailImage)
            if let webpageUrl = URL(string: miniProgramPrepare.webPageURLString) {
                activityItems.append(webpageUrl)
            }
        }
        dismissSharePanelIfNeeded()
        dismissImagePanelIfNeeded()
        _Self.logger.info("[LarkSharePanel] share \(contentContext.type().rawValue) by system share")
        presentSystemShareController(navigatable: userResolver.navigator, presentFrom: presentFrom, activityItems: activityItems)
    }

    /// 复制文本
    private func handleCopyAction(content: String) {
        recordCopyContent(content)
        copyToPasteBoard(content: content)
        shareCallback?(ShareResult.success, .copy)
    }

    private func recordCopyContent(_ copyContent: String) {
        // 记录本次粘贴到系统粘贴板的内容，防止本端设备在打开后误识别
        ShareTokenManager.shared.cachePasteboardContent(string: copyContent)
    }

    /// 保存图片
    private func handleSaveAction(image: UIImage?) {
        guard let image = image else { return }
        if case .imagePanel = self.currentPanelType {
            dismissImagePanelIfNeeded()
        }
        do {
            try Utils.savePhoto(token: Self.saveImageButtonClickedToken, image: image) { [weak self] (success, granted) in
                guard let self = self else { return }
                if success && granted {
                    _Self.logger.info("""
                        [LarkSnsShare] handleSaveAction,
                        save image success, currentItemType = \(self.currentItemType.rawValue)
                    """)
                    self.shareCallback?(.success, self.currentItemType)
                } else {
                    _Self.logger.info("""
                        [LarkSnsShare] handleSaveAction,
                        save image failed, hasSuccess = \(success), hasGranted = \(granted)
                    """)
                    self.shareCallback?(.failure(.saveImageFailed,
                                                 BundleI18n.LarkSnsShare.Lark_UD_SharePanelSaveFailRetryToast),
                                        self.currentItemType)
                }
            }
        } catch {
            _Self.logger.error("[LarkSnsShare] handleSaveAction, save photo failed, errro: \(error)")
        }
    }

    /// 分享图片
    private func checkToPresentImagePanel(on baseViewController: UIViewController) {
        if let setImageBlock = self.setImageBlock,
           let imageShareTypes = self.imageShareTypes {
            presentImagePanel(itemTypes: imageShareTypes,
                              on: baseViewController,
                              setImageBlock: setImageBlock)
        } else {
            assertionFailure("imageShareTypes shoud not be nil,maybe something wrong with shareTypes")
        }
    }

    /// 从上下文信息中获取图片名字
    private func getImageTitleFromContext() -> String {
        var title: String
        switch self.currentContentContext {
        case .text(let textPrepare):
            title = textPrepare.content
        case .image(let imagePrepare):
            title = imagePrepare.title
        case .webUrl(let webUrlPrepare):
            title = webUrlPrepare.title
        case .miniProgram(let miniProgram):
            title = miniProgram.title
        }
        return title
    }

    /// 弹出图片VC
    private func presentImagePanel(itemTypes: [LarkShareItemType],
                                   on baseViewController: UIViewController,
                                   setImageBlock: @escaping (LarkSharePanel) -> Void) {
        let imagePanel = LarkShareImagePanel(itemTypes, delegate: self, self.productLevel, self.scene)
        if #available(iOS 13, *), self.currentUserInterfaceStyle != .unspecified {
            imagePanel.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
        }
        self.shareImagePanel = imagePanel
        baseViewController.present(imagePanel, animated: true) { [weak self] in
            guard let self = self else { return }
            self.currentPanelType = .imagePanel
            self.isDismissed = false
            _Self.logger.info("[LarkSharePanel] image share panel did show")
            setImageBlock(self)
        }
    }

    /// 弹出系统分享
    private func presentSystemShareController(navigatable: Navigatable, presentFrom: UIViewController, activityItems: [Any]) {
        LarkShareBasePresenter.shared.presentSystemShareController(
            navigatable: navigatable,
            activityItems: activityItems,
            presentFrom: presentFrom,
            popoverMaterial: popoverMaterial) { [weak self] (type, _, _, error) in
            if error != nil {
                self?.shareCallback?(.failure(.snsDominError, "system share failed"), .more(.default))
            } else {
                self?.shareCallback?(.success, .more(.init(type: type)))
            }
        }
    }

    /// 关闭分享面板
    private func dismissSharePanelIfNeeded() {
        self.shareActionPanel?.dismiss(animated: true)
        self.isDismissed = true
    }

    /// 关闭图片面板
    private func dismissImagePanelIfNeeded() {
        self.shareImagePanel?.dismiss(animated: true)
        self.isDismissed = true
    }
}

// MARK: - App Share CallBack
extension LarkSharePanel {
    public func wechatWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?) {
        if let err = error {
            _Self.logger.error("[LarkSharePanel] wechatWrapperCallback failed, error = \(err.localizedDescription)")
            shareCallback?(.failure(.snsDominError, err.localizedDescription), currentItemType)
        } else {
            _Self.logger.error("[LarkSharePanel] wechatWrapperCallback success")
            shareCallback?(.success, currentItemType)
        }
    }

    public func qqWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?) {
        if let err = error {
            _Self.logger.error("[LarkSharePanel] qqWrapperCallback failed, error = \(err.localizedDescription)")
            shareCallback?(.failure(.snsDominError, err.localizedDescription), currentItemType)
        } else {
            _Self.logger.error("[LarkSharePanel] qqWrapperCallback success")
            shareCallback?(.success, currentItemType)
        }
    }

    public func weiboWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?) {
        if let err = error {
            _Self.logger.error("[LarkSharePanel] weiboWrapperCallback failed, error = \(err.localizedDescription)")
            shareCallback?(.failure(.snsDominError, err.localizedDescription), currentItemType)
        } else {
            _Self.logger.error("[LarkSharePanel] weiboWrapperCallback success")
            shareCallback?(.success, currentItemType)
        }
    }
}
