//
//  LarkSharePresenter.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/19.
//

import UIKit
import Foundation
import LKCommonsLogging
import RxSwift
import LarkShareToken
import LarkUIKit
import LarkFoundation
import LarkEMM
import LarkSensitivityControl
import UniverseDesignToast
import LarkContainer
import EENavigator

/// 分享组件Wrapper
@available(*, deprecated)
final class LarkSharePresenter: NSObject, LarkShareService, SnsShareDelegate, LarkShareActionSheetDelegate {
    private static var token = Token("LARK-PSDA-pasteboard_larksharepresenter")
    private static var beforeShowDowngradeTipToken = Token("LARK-PSDA-sharePresenter_before_show_downgradeTip")
    private static var saveImageInDowngradeTipToken = Token("LARK-PSDA-sharePresenter_auto_save_image_in_downgradeTip")
    private static var saveImageButtonClickedToken = Token("LARK-PSDA-sharePresenter_save_image_button_clicked")

    private typealias _Self = LarkSharePresenter
    private enum DatasourceMode {
        case dynamic
        case local
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // 为了不污染其他只使用 Base 能力的业务方，这边会暂时存储，不会直接替换
    private weak var lastBasePresenterDelegate: SnsShareDelegate?

    private weak var baseViewController: UIViewController?
    private var popoverMaterial: PopoverMaterial?
    private var currentTraceId: String?
    private var currentContentContext: ShareContentContext?
    private var currentShareConfiguration: ShareDynamicConfiguration?
    private var currentDowngradeTipPanelMaterial: DowngradeTipPanelMaterial?
    private var customShareContextMapping: [String: CustomShareContext]?
    private var needDowngradeChecker: ((LarkShareItemType) -> Bool)?
    private var downgradeInterceptor: ((_ itemType: LarkShareItemType) -> Void)?
    private var shareCallback: LarkShareCallback?

    private weak var shareActionSheet: LarkShareActionSheet?
    private lazy var dynamicConfParser: ShareConfigurationProvider = ShareDynamicConfigurationParser(shareDynamicAPI: try? userResolver.resolve(assert: ShareDynamicAPI.self))
    private static let logger = Logger.log(LarkSharePresenter.self, category: "lark.sns.share.wrapper.presenter")
    private var currentDisposable: Disposable?
    private var currentItemType: LarkShareItemType = .unknown
    private var mode: DatasourceMode = .local {
        willSet {
            if case .local = newValue {
                currentTraceId = nil
                currentShareConfiguration = nil
                currentDowngradeTipPanelMaterial = nil
            }
        }
    }
    /// 剪贴板配置
    private var pasteConfig: SnsPasteConfig?

    @available(*, deprecated)
    public func present(
        by traceId: String,
        contentContext: ShareContentContext,
        baseViewController: UIViewController,
        downgradeTipPanelMaterial: DowngradeTipPanelMaterial?,
        customShareContextMapping: [String: CustomShareContext]?,
        defaultItemTypes: [LarkShareItemType],
        popoverMaterial: PopoverMaterial?,
        shareCallback: LarkShareCallback?
    ) {
        // 避免iPad多scene分享上下文交叉
        currentDisposable?.dispose()
        shareActionSheet?.dismiss(animated: false, completion: nil)
        reset()

        self.currentTraceId = traceId
        self.currentDowngradeTipPanelMaterial = downgradeTipPanelMaterial
        self.customShareContextMapping = customShareContextMapping

        currentDisposable = dynamicConfParser.parse(traceId: traceId).subscribe { [weak self] (configuration) in
            self?.mode = .dynamic
            self?.currentShareConfiguration = configuration

            // 这里需要额外mapping和填充custom item的分享上下文
            let transformedItemTypes = configuration.items.compactMap { (panelItem) -> LarkShareItemType? in
                if case .custom(let identifier) = panelItem {
                    if let context = self?.customShareContextMapping?[identifier] {
                        return .custom(context)
                    }
                    return nil
                }
                return panelItem.toShareItem()
            }
            self?.present(
                with: transformedItemTypes,
                contentContext: contentContext,
                baseViewController: baseViewController,
                popoverMaterial: popoverMaterial,
                needDowngrade: nil,
                downgradeInterceptor: nil,
                shareCallback: shareCallback
            )
        } onError: { [weak self] (error) in
            self?.mode = .local
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
                    [LarkSnsShare] parse dynamic conf failed,
                    traceId = \(traceId),
                    errCode = \(errorCode.rawValue)
                """)
                self?.trackShareFailure(errorCode: errorCode, errorMsg: errorMsg)
                shareCallback?(.failure(errorCode, errorMsg), .unknown)
                // 只要是解析过程中发生的错误，都会转成降级策略或兜底静态配置
                self?.present(
                    with: defaultItemTypes,
                    contentContext: contentContext,
                    baseViewController: baseViewController,
                    popoverMaterial: popoverMaterial,
                    needDowngrade: nil,
                    downgradeInterceptor: nil,
                    shareCallback: shareCallback
                )
            } else {
                _Self.logger.error("""
                    [LarkSnsShare] parse dynamic conf failed with unknown error,
                    traceId = \(traceId),
                    description = \(error.localizedDescription)
                """)
                self?.trackShareFailure(errorCode: .unknownError, errorMsg: "未知错误")
                shareCallback?(.failure(.unknownError, "未知错误，请联系 shizhengyu 进一步排查"), .unknown)
                // 重置分享物料
                self?.reset()
            }
        }
    }

    @available(*, deprecated)
    public func present(
        with staticItemTypes: [LarkShareItemType],
        contentContext: ShareContentContext,
        baseViewController: UIViewController,
        popoverMaterial: PopoverMaterial?,
        needDowngrade: ((LarkShareItemType) -> Bool)?,
        downgradeInterceptor: ((LarkShareItemType) -> Void)?,
        shareCallback: LarkShareCallback?
    ) {
        self.currentContentContext = contentContext
        self.baseViewController = baseViewController
        self.popoverMaterial = popoverMaterial
        self.needDowngradeChecker = needDowngrade
        self.downgradeInterceptor = downgradeInterceptor
        self.shareCallback = shareCallback

        _Self.logger.info("""
            [LarkSnsShare] start share!
            itemTypes = \(staticItemTypes.map { $0.rawValue }),
            shareContentType = \(contentContext.type().rawValue)
        """)

        func onlyOneSnsItem(_ items: [LarkShareItemType]) -> LarkShareItemType? {
            if filteredItems.count == 1, let item = filteredItems.first(where: { (item) -> Bool in
                LarkShareItemType.snsItems().contains(item)
            }) {
                return item
            }
            return nil
        }

        let filteredItems = staticItemTypes.filter { (itemType) -> Bool in
            return ShareSlimming.currentWhitelist().contains(itemType)
        }
        if filteredItems.isEmpty {
            handleSystemShare(presentFrom: baseViewController, contentContext: contentContext)
        } else if let item = onlyOneSnsItem(filteredItems) {
            // 如果只配置了仅一个sns相关的item，会直接模拟手动点击唤起app分享或进入降级流程
            handleShareAction(by: item, actionSheet: nil)
        } else {
            let customShareVc = LarkShareActionSheet(
                shareTypes: staticItemTypes,
                delegate: self
            )
            shareActionSheet = customShareVc
            if Display.pad, let popoverMaterial = popoverMaterial {
                customShareVc.modalPresentationStyle = .popover
                customShareVc.preferredContentSize = CGSize(width: 375, height: 154)
                if let popOver = customShareVc.popoverPresentationController {
                    popOver.sourceView = popoverMaterial.sourceView
                    popOver.sourceRect = popoverMaterial.sourceRect
                    popOver.permittedArrowDirections = popoverMaterial.direction
                    popOver.backgroundColor = UIColor.ud.N00
                }
            }
            baseViewController.present(customShareVc, animated: true) {
                _Self.logger.info("[LarkSnsShare] custom share panel did show")
            }
        }
    }

    public func present(
        by traceId: String,
        contentContext: ShareContentContext,
        baseViewController: UIViewController,
        downgradeTipPanelMaterial: DowngradeTipPanelMaterial?,
        customShareContextMapping: [String: CustomShareContext]?,
        defaultItemTypes: [LarkShareItemType],
        popoverMaterial: PopoverMaterial?,
        pasteConfig: SnsPasteConfig?,
        shareCallback: LarkShareCallback?
    ) {
        // 避免iPad多scene分享上下文交叉
        currentDisposable?.dispose()
        shareActionSheet?.dismiss(animated: false, completion: nil)
        reset()

        self.currentTraceId = traceId
        self.currentDowngradeTipPanelMaterial = downgradeTipPanelMaterial
        self.customShareContextMapping = customShareContextMapping
        self.pasteConfig = pasteConfig
        if pasteConfig == nil {
            assertionFailure("pasteConfig param better be set, default can't paste externally")
        }

        currentDisposable = dynamicConfParser.parse(traceId: traceId).subscribe { [weak self] (configuration) in
            self?.mode = .dynamic
            self?.currentShareConfiguration = configuration

            // 这里需要额外mapping和填充custom item的分享上下文
            let transformedItemTypes = configuration.items.compactMap { (panelItem) -> LarkShareItemType? in
                if case .custom(let identifier) = panelItem {
                    if let context = self?.customShareContextMapping?[identifier] {
                        return .custom(context)
                    }
                    return nil
                }
                return panelItem.toShareItem()
            }
            self?.present(
                with: transformedItemTypes,
                contentContext: contentContext,
                baseViewController: baseViewController,
                popoverMaterial: popoverMaterial,
                needDowngrade: nil,
                downgradeInterceptor: nil,
                pasteConfig: pasteConfig,
                shareCallback: shareCallback
            )
        } onError: { [weak self] (error) in
            self?.mode = .local
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
                    [LarkSnsShare] parse dynamic conf failed,
                    traceId = \(traceId),
                    errCode = \(errorCode.rawValue)
                """)
                self?.trackShareFailure(errorCode: errorCode, errorMsg: errorMsg)
                shareCallback?(.failure(errorCode, errorMsg), .unknown)
                // 只要是解析过程中发生的错误，都会转成降级策略或兜底静态配置
                self?.present(
                    with: defaultItemTypes,
                    contentContext: contentContext,
                    baseViewController: baseViewController,
                    popoverMaterial: popoverMaterial,
                    needDowngrade: nil,
                    downgradeInterceptor: nil,
                    pasteConfig: pasteConfig,
                    shareCallback: shareCallback
                )
            } else {
                _Self.logger.error("""
                    [LarkSnsShare] parse dynamic conf failed with unknown error,
                    traceId = \(traceId),
                    description = \(error.localizedDescription)
                """)
                self?.trackShareFailure(errorCode: .unknownError, errorMsg: "未知错误")
                shareCallback?(.failure(.unknownError, "未知错误，请联系 shizhengyu 进一步排查"), .unknown)
                // 重置分享物料
                self?.reset()
            }
        }
    }

    public func present(
        with staticItemTypes: [LarkShareItemType],
        contentContext: ShareContentContext,
        baseViewController: UIViewController,
        popoverMaterial: PopoverMaterial?,
        needDowngrade: ((LarkShareItemType) -> Bool)?,
        downgradeInterceptor: ((LarkShareItemType) -> Void)?,
        pasteConfig: SnsPasteConfig?,
        shareCallback: LarkShareCallback?
    ) {
        self.currentContentContext = contentContext
        self.baseViewController = baseViewController
        self.popoverMaterial = popoverMaterial
        self.needDowngradeChecker = needDowngrade
        self.downgradeInterceptor = downgradeInterceptor
        self.shareCallback = shareCallback
        self.pasteConfig = pasteConfig
        if pasteConfig == nil {
            assertionFailure("pasteConfig param better be set, default can't paste externally")
        }

        _Self.logger.info("""
            [LarkSnsShare] start share!
            itemTypes = \(staticItemTypes.map { $0.rawValue }),
            shareContentType = \(contentContext.type().rawValue)
        """)

        func onlyOneSnsItem(_ items: [LarkShareItemType]) -> LarkShareItemType? {
            if filteredItems.count == 1, let item = filteredItems.first(where: { (item) -> Bool in
                LarkShareItemType.snsItems().contains(item)
            }) {
                return item
            }
            return nil
        }

        let filteredItems = staticItemTypes.filter { (itemType) -> Bool in
            return ShareSlimming.currentWhitelist().contains(itemType)
        }
        if filteredItems.isEmpty {
            handleSystemShare(presentFrom: baseViewController, contentContext: contentContext)
        } else if let item = onlyOneSnsItem(filteredItems) {
            // 如果只配置了仅一个sns相关的item，会直接模拟手动点击唤起app分享或进入降级流程
            handleShareAction(by: item, actionSheet: nil)
        } else {
            let customShareVc = LarkShareActionSheet(
                shareTypes: staticItemTypes,
                delegate: self
            )
            shareActionSheet = customShareVc
            if Display.pad, let popoverMaterial = popoverMaterial {
                customShareVc.modalPresentationStyle = .popover
                customShareVc.preferredContentSize = CGSize(width: 375, height: 154)
                if let popOver = customShareVc.popoverPresentationController {
                    popOver.sourceView = popoverMaterial.sourceView
                    popOver.sourceRect = popoverMaterial.sourceRect
                    popOver.permittedArrowDirections = popoverMaterial.direction
                    popOver.backgroundColor = UIColor.ud.N00
                }
            }
            baseViewController.present(customShareVc, animated: true) {
                _Self.logger.info("[LarkSnsShare] custom share panel did show")
            }
        }
    }

    public func registerProvider(_ provider: ShareConfigurationProvider) {
        self.dynamicConfParser = provider
    }

    func shareItemDidClick(actionSheet: LarkShareActionSheet, itemType: LarkShareItemType) {
        _Self.logger.info("[LarkSnsShare] item <\(itemType.rawValue)> did click")
        handleShareAction(by: itemType, actionSheet: actionSheet)
    }

    func didClickCancel(actionSheet: LarkShareActionSheet) {
        _Self.logger.info("[LarkSnsShare] user cancel manually")
        trackShareFailure(errorCode: .userCanceledManually, errorMsg: "user cancel manually")
        shareCallback?(.failure(.userCanceledManually, "user cancel manually"), .unknown)
    }

    func triggleDowngrade(_ itemType: LarkShareItemType) -> Bool {
        if case .local = mode, downgradeInterceptor != nil {
            return needDowngradeChecker?(itemType) ?? false
        }
        return false
    }
}

// MARK: - App Share Awake
private extension LarkSharePresenter {
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

    private func getToastWindow() -> UIView? {
        return self.baseViewController?.view.window
    }

    private func showShareSDKAuthTips(snsType: SnsType) {
        guard let window = self.getToastWindow() else { return }
        let text = LarkShareBasePresenter.shared.getShareSdkDenyTipText(snsType: snsType)
        UDToast.showFailure(with: text, on: window)
    }

    func handleShareAction(by itemType: LarkShareItemType, actionSheet: LarkShareActionSheet?) {
        //分享类型涉及分享SDK，且无SDK权限时，拦截并弹提示
        if let snsType = self.transItemTypeToSnsType(itemType: itemType),
           !LarkShareBasePresenter.shared.checkShareSDKAuthority(snsType: snsType) {
            self.showShareSDKAuthTips(snsType: snsType)
            dismissSharePanelIfNeeded()
            return
        }
        // 如果 mode = local，则检测业务方是否有提供降级拦截
        if triggleDowngrade(itemType), let interceptor = downgradeInterceptor {
            interceptor(itemType)
            dismissSharePanelIfNeeded()
            trackShareFailure(errorCode: .triggleDowngradeHandle, errorMsg: "triggleDowngradeHandle")
            shareCallback?(.failure(.triggleDowngradeHandle, "triggleDowngradeHandle"), itemType)
            return
        }
        handleCustomAppShare(type: itemType, actionSheet: actionSheet)
    }

    func handleCustomAppShare(type: LarkShareItemType, actionSheet: LarkShareActionSheet?) {
        guard let contentContext = currentContentContext else {
            assertionFailure("ShareContentContext can not be nil")
            return
        }
        guard let baseViewController = baseViewController else {
            assertionFailure("baseViewController can not be nil")
            return
        }

        currentItemType = type

        switch type {
        case .wechat:
            if doDynamicDowngradeIfNeeded(panelItem: .wechatSession, snsShareHandler: {
                handleThirdApplicationShare(
                    snsType: .wechat,
                    snsScenes: .wechatSession,
                    shareContentContext: contentContext
                )
            }) { return }
        case .timeline:
            if doDynamicDowngradeIfNeeded(panelItem: .wechatTimeline, snsShareHandler: {
                handleThirdApplicationShare(
                    snsType: .wechat,
                    snsScenes: .wechatTimeline,
                    shareContentContext: contentContext
                )
            }) { return }
        case .qq:
            if doDynamicDowngradeIfNeeded(panelItem: .qq, snsShareHandler: {
                if case .text = contentContext {
                    assertionFailure("text is not support for qq platform, please check!")
                    return
                }
                handleThirdApplicationShare(
                    snsType: .qq,
                    snsScenes: .qqSpecifiedSession,
                    shareContentContext: contentContext
                )
            }) { return }
        case .weibo:
            if doDynamicDowngradeIfNeeded(panelItem: .weibo, snsShareHandler: {
                handleThirdApplicationShare(
                    snsType: .weibo,
                    snsScenes: nil,
                    shareContentContext: contentContext
                )
            }) { return }
        case .more:
            dismissSharePanelIfNeeded()
            handleSystemShare(presentFrom: baseViewController, contentContext: contentContext)
            return
        case .copy:
            if case .text(let textPrepare) = contentContext {
                handleCopyAction(content: textPrepare.content)
                break
            }
            if case .webUrl(let webUrlPrepare) = contentContext {
                handleCopyAction(content: webUrlPrepare.webpageURL)
                break
            }
            assertionFailure("copy just support for text or weburl share, please check!")
        case .save:
            if case .image(let imagePrepare) = contentContext {
                handleSaveAction(image: imagePrepare.image)
            } else {
                assertionFailure("save just support for image, please check!")
            }
        case .custom(let shareContext):
            shareContext.action(shareContext.content, actionSheet ?? baseViewController, .actionPanel)
            return
        default: break
        }

        dismissSharePanelIfNeeded()
    }

    func doDynamicDowngradeIfNeeded(
        panelItem: PanelItem,
        snsShareHandler: () -> Void
    ) -> Bool {
        if case .dynamic = mode,
           let conf = currentShareConfiguration,
           conf.answerTypeMapping.contains(where: { (kv) -> Bool in
                return kv.key == panelItem
           }),
           let answerType = conf.answerTypeMapping[panelItem],
           let baseViewController = baseViewController,
           let currentContentContext = currentContentContext {

            dismissSharePanelIfNeeded()

            switch answerType {
            case .ban,
                 .downgradeToSystemShare:
                handleSystemShare(presentFrom: baseViewController, contentContext: currentContentContext)
            case .downgradeToWakeupByTip where currentDowngradeTipPanelMaterial != nil:
                handleDowngradeWakeupByTip(panelItem: panelItem, presentFrom: baseViewController, contentContext: currentContentContext)
            default:
                _Self.logger.error("enter exception flow，currentShareConfiguration = \(conf)")
                handleSystemShare(presentFrom: baseViewController, contentContext: currentContentContext)
            }
            return true
        } else {
            snsShareHandler()
            return false
        }
    }

    // nolint: duplicated_code 老组件代码下线后将不再重复
    func handleDowngradeWakeupByTip(panelItem: PanelItem, presentFrom: UIViewController, contentContext: ShareContentContext) {
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
                self.presentDowngradePanel(
                    snsType: snsType,
                    panelItem: panelItem,
                    presentFrom: presentFrom,
                    contentContext: contentContext,
                    material: material
                )
            }

            if case .image = material {
                do {
                    try Utils.checkPhotoWritePermission(token: Self.beforeShowDowngradeTipToken) { (granted) in
                        guard granted else { return }
                        presentAwakePanel()
                    }
                } catch {
                    _Self.logger.error("[LarkSharePresenter] handleDowngradeWakeupByTip, checkPhototWritePermission failed, error: \(error)")
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
                [LarkSharePresenter] copy text to pasteBoard,
                paste config: \(self.pasteConfig?.rawValue ?? "")
            """)
        }

    func presentDowngradePanel(
        snsType: SnsType,
        panelItem: PanelItem,
        presentFrom: UIViewController,
        contentContext: ShareContentContext,
        material: DowngradeTipPanelMaterial
    ) {
        let downgradePanel = SnsDowngradeTipPanel(snsType: snsType, material: material) { [weak self] (_) in
            switch material {
            case .text(_, let content):
                if let content = content {
                    self?.recordCopyContent(content)
                    self?.copyToPasteBoard(content: content)
                }
            case .image:
                if case .image(let imagePrepare) = contentContext {
                    do {
                        try Utils.savePhoto(token: Self.saveImageInDowngradeTipToken, image: imagePrepare.image) { [weak self] (success, granted) in
                            if success && granted {
                                _Self.logger.info("""
                                    [LarkSharePresenter] handleDowngradeWakeupByTip,
                                    save image success, panelItem = \(panelItem.rawValue)
                                """)
                            } else {
                                _Self.logger.info("""
                                    [LarkSharePresenter] handleDowngradeWakeupByTip,
                                    save image failed, hasSuccess = \(success), hasGranted = \(granted)
                                """)
                                self?.trackShareFailure(errorCode: .saveImageFailed, errorMsg: "image save failed")
                                self?.shareCallback?(.failure(.saveImageFailed, "image save failed"), panelItem.toShareItem())
                            }
                        }
                    } catch {
                        _Self.logger.error("[LarkSharePresenter] presentDowngradePanel, savePhoto failed, error: \(error)")
                    }
                } else {
                    assertionFailure("share content type must be `image`, please check!")
                }
            }
        } ctaButtonDidClick: { [weak self] (panel) in
            let wakeupResult = LarkShareBasePresenter.shared.wakeup(snsType: snsType)
            if let error = wakeupResult.1, !wakeupResult.0 {
                switch error {
                case .notInstalled:
                    self?.trackShareFailure(
                        errorCode: .notInstalled,
                        errorMsg: BundleI18n.LarkSnsShare.Lark_UserGrowth_InvitePeopleContactsShareNotInstalled
                    )
                    self?.shareCallback?(
                        .failure(
                            .notInstalled,
                            BundleI18n.LarkSnsShare.Lark_UserGrowth_InvitePeopleContactsShareNotInstalled
                        ),
                        panelItem.toShareItem()
                    )
                case .sdkWakeupFailed:
                    self?.trackShareFailure(
                        errorCode: .snsDominError,
                        errorMsg: "wakeup failed"
                    )
                    self?.shareCallback?(
                        .failure(
                            .snsDominError,
                            "wakeup failed, please check third share sdk log"
                        ),
                        panelItem.toShareItem()
                    )
                case .notSupported:
                    self?.trackShareFailure(
                        errorCode: .unknownError,
                        errorMsg: "this share channel do not support"
                    )
                    self?.shareCallback?(
                        .failure(
                            .unknownError,
                            "this share channel do not support"
                        ),
                        panelItem.toShareItem()
                    )
                }
            } else {
                self?.trackShareSuccess()
                self?.shareCallback?(.success, panelItem.toShareItem())
            }
            panel.dismiss()
        }

        presentFrom.present(downgradePanel, animated: false, completion: nil)
    }

    func preCheckAppInstall(_ snsType: SnsType) -> Bool {
        switch snsType {
        case .wechat:
            return LarkShareBasePresenter.shared.isAvaliable(snsType: .wechat)
        case .qq:
            return LarkShareBasePresenter.shared.isAvaliable(snsType: .qq)
        case .weibo:
            return LarkShareBasePresenter.shared.isAvaliable(snsType: .weibo)
        }
    }

    func prepare(_ snsType: SnsType) {
        switch snsType {
        case .wechat, .qq, .weibo:
            if let lastDelegate = LarkShareBasePresenter.shared.delegate {
                lastBasePresenterDelegate = lastDelegate
            }
            LarkShareBasePresenter.shared.delegate = self
        }
    }

    func handleThirdApplicationShare(
        snsType: SnsType,
        snsScenes: SnsScenes?,
        shareContentContext: ShareContentContext
    ) {
        guard preCheckAppInstall(snsType) else {
            _Self.logger.info("[LarkSnsShare] app not installed, snsType = \(snsType.rawValue)")
            trackShareFailure(
                errorCode: .notInstalled,
                errorMsg: BundleI18n.LarkSnsShare.Lark_UserGrowth_InvitePeopleContactsShareNotInstalled
            )
            shareCallback?(
                .failure(
                    .notInstalled,
                    BundleI18n.LarkSnsShare.Lark_UserGrowth_InvitePeopleContactsShareNotInstalled
                ),
                currentItemType
            )
            return
        }

        prepare(snsType)

        switch shareContentContext {
        case .text(let textPrepare):
            _Self.logger.info("[LarkSnsShare] share text to \(snsScenes?.rawValue ?? "") of \(snsType.rawValue)")
            LarkShareBasePresenter.shared.sendText(
                navigatable: userResolver.navigator,
                snsType: snsType,
                snsScenes: snsScenes,
                text: textPrepare.content,
                customCallbackUserInfo: textPrepare.customCallbackUserInfo
            )
        case .image(let imagePrepare):
            _Self.logger.info("[LarkSnsShare] share image to \(snsScenes?.rawValue ?? "") of \(snsType.rawValue)")
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
            _Self.logger.info("[LarkSnsShare] share webpageUrl to \(snsScenes?.rawValue ?? "") of \(snsType.rawValue)")
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
            _Self.logger.info("[LarkSnsShare] share miniProgram to \(snsScenes?.rawValue ?? "") of \(snsType.rawValue)")
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

    func handleSystemShare(presentFrom: UIViewController, contentContext: ShareContentContext) {
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
        _Self.logger.info("[LarkSnsShare] share \(contentContext.type().rawValue) by system share")
        presentSystemShareController(navigatable: userResolver.navigator, presentFrom: presentFrom, activityItems: activityItems)
    }

    func handleCopyAction(content: String) {
        recordCopyContent(content)
        copyToPasteBoard(content: content)
        trackShareSuccess()
        shareCallback?(ShareResult.success, .copy)
    }

    func presentSystemShareController(navigatable: Navigatable, presentFrom: UIViewController, activityItems: [Any]) {
        LarkShareBasePresenter.shared.presentSystemShareController(
            navigatable: navigatable,
            activityItems: activityItems,
            presentFrom: presentFrom,
            popoverMaterial: popoverMaterial) { [weak self] (type, _, _, error) in
            if error != nil {
                self?.trackShareFailure(errorCode: .snsDominError, errorMsg: "system share failed")
                self?.shareCallback?(.failure(.snsDominError, "system share failed"), .more(.default))
            } else {
                self?.trackShareSuccess()
                self?.shareCallback?(.success, .more(.init(type: type)))
            }
            self?.mode = .local
        }
    }

    func handleSaveAction(image: UIImage?) {
        guard let image = image else { return }
        do {
            try Utils.savePhoto(token: Self.saveImageButtonClickedToken, image: image) { [weak self] (success, granted) in
                guard let `self` = self else { return }
                if success && granted {
                    _Self.logger.info("""
                        [LarkSharePresenter] handleSaveAction,
                        save image success, currentItemType = \(self.currentItemType.rawValue)
                    """)
                    self.trackShareSuccess()
                    self.shareCallback?(.success, self.currentItemType)
                } else {
                    _Self.logger.info("""
                        [LarkSharePresenter] handleSaveAction,
                        save image failed, hasSuccess = \(success), hasGranted = \(granted)
                    """)
                    self.trackShareFailure(errorCode: .saveImageFailed, errorMsg: "save image failed")
                    self.shareCallback?(.failure(.saveImageFailed, "save image failed"), self.currentItemType)
                }
            }
        } catch {
            _Self.logger.error("[LarkSharePresenter] handleSaveAction, save photo failed, error: \(error)")
        }
    }

    func recordCopyContent(_ copyContent: String) {
        // 记录本次粘贴到系统粘贴板的内容，防止本端设备在打开后误识别
        ShareTokenManager.shared.cachePasteboardContent(string: copyContent)
    }

    func dismissSharePanelIfNeeded(animated: Bool = true) {
        shareActionSheet?.dismiss(animated: animated, completion: {
            self.mode = .local
        })
    }

    func reset() {
        currentTraceId = nil
        currentDowngradeTipPanelMaterial = nil
        currentContentContext = nil
        currentShareConfiguration = nil
        downgradeInterceptor = nil
        shareCallback = nil
        currentDisposable = nil
        currentItemType = .unknown
        if let last = lastBasePresenterDelegate {
            LarkShareBasePresenter.shared.delegate = last
        }
    }
}

// MARK: - App Share CallBack
extension LarkSharePresenter {
    func wechatWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?) {
        if let err = error {
            trackShareFailure(errorCode: .snsDominError, errorMsg: err.localizedDescription)
            _Self.logger.error("[LarkSnsShare] wechatWrapperCallback failed, error = \(err.localizedDescription)")
            shareCallback?(.failure(.snsDominError, err.localizedDescription), currentItemType)
        } else {
            trackShareSuccess()
            _Self.logger.error("[LarkSnsShare] wechatWrapperCallback success")
            shareCallback?(.success, currentItemType)
        }
        reset()
    }

    func qqWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?) {
        if let err = error {
            trackShareFailure(errorCode: .snsDominError, errorMsg: err.localizedDescription)
            _Self.logger.error("[LarkSnsShare] qqWrapperCallback failed, error = \(err.localizedDescription)")
            shareCallback?(.failure(.snsDominError, err.localizedDescription), currentItemType)
        } else {
            trackShareSuccess()
            _Self.logger.error("[LarkSnsShare] qqWrapperCallback success")
            shareCallback?(.success, currentItemType)
        }
        reset()
    }

    func weiboWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?) {
        if let err = error {
            trackShareFailure(errorCode: .snsDominError, errorMsg: err.localizedDescription)
            _Self.logger.error("[LarkSnsShare] weiboWrapperCallback failed, error = \(err.localizedDescription)")
            shareCallback?(.failure(.snsDominError, err.localizedDescription), currentItemType)
        } else {
            trackShareSuccess()
            _Self.logger.error("[LarkSnsShare] weiboWrapperCallback success")
            shareCallback?(.success, currentItemType)
        }
        reset()
    }
}

// MARK: - Tracing Monitor
extension LarkSharePresenter {
    func trackShareSuccess() {
        ShareMonitor.shareTracing(
            by: currentTraceId,
            isSuccess: true,
            contentType: currentContentContext?.type() ?? .unknown,
            itemType: currentItemType
        )
    }

    func trackShareFailure(
        errorCode: ShareResult.ErrorCode,
        errorMsg: String
    ) {
        ShareMonitor.shareTracing(
            by: currentTraceId,
            isSuccess: false,
            contentType: currentContentContext?.type() ?? .unknown,
            itemType: currentItemType,
            errorCode: errorCode,
            errorMsg: errorMsg
        )
    }
}
