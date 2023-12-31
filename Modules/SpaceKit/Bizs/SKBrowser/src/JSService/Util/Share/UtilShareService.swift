//
//  ShareService.swift
//  Docs
//
//  Created by weidong fu on 5/2/2018.
//swiftlint:disable line_length

import Foundation
import EENavigator
import LarkUIKit
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import HandyJSON
import Kingfisher
import UniverseDesignToast
import UniverseDesignColor
import LarkWebViewContainer
import SpaceInterface

public struct SharePanelConfigInfo: HandyJSON, SharePanelConfigInfoProtocol {
    public var disables: [String] = []
    public var badges: [String] = []

    public init() {
        
    }
}



class UtilShareService: BaseJSService {
    var callback: String = ""
    var callbacks: [DocsJSService: APICallbackProtocol] = [:]
    
    
    lazy var sheetShareManager: SheetShareManager? = {
        if let dbvc = self.registeredVC as? BrowserViewController, let docsInfo = hostDocsInfo {
            var manager = SheetShareManager(dbvc, docsInfo: docsInfo, navigator: navigator)
            manager.delegate = self
            return manager
        }
        return nil
    }()
    
    lazy var watermarkViewConfig = WatermarkViewConfig()
    
    private weak var shareViewController: SKShareViewController?
    private var sharePanelConfig = SharePanelConfigInfo()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        
        _ = NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            guard let self = self else {
                return
            }
            
            self.notifyFrontendUserDidTakeSnapshot()
        }
    }
}

// 即将删除的代码，需要暂时兼容旧逻辑
extension UtilShareService: BitableAdPermSettingVCDelegate {
    
    var jsService: SKExecJSFuncService? {
        model?.jsEngine
    }
    
    func bitableAdPermBridgeDataDidChange(_ vc: BitableAdPermSettingVC, data: BitableBridgeData) {
        shareViewController?.updateBitableAdPermBridgeData(data)
    }
}

extension UtilShareService: BitableAdPermissionSettingListener {
    func onBitableAdPermBridgeDataChange(_ data: BitableBridgeData) {
        shareViewController?.updateBitableAdPermBridgeData(data)
    }
}

extension UtilShareService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        var services: [DocsJSService] = [.shareService, .sheetShowTitle, .sheetHideTitle, .sheetShowShareOpreationList, .sheetHideShareOpreationList, .sheetShowSnapshotAlert, .sheetShowLoading, .sheetHideLoading, .sheetPrepareWriteImage, .sheetReceiveImageData, .sheetGetSharePanelHeight, .sheetStopTransferImage, .sheetGetWatermarkInfo]
        return services
    }

    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("[UtilShareService] name: \(serviceName) ")
        switch serviceName {
        case DocsJSService.shareService.rawValue:
            handleShareService(params)
        //以下都是sheet的
        case DocsJSService.sheetShowTitle.rawValue:
            handleShowShareTitle(params)
        case DocsJSService.sheetHideTitle.rawValue:
            handleHideSheetTitle(params)
        case DocsJSService.sheetShowShareOpreationList.rawValue:
            handleShowSheetPreview(params)
        case DocsJSService.sheetHideShareOpreationList.rawValue:
            handleHideSheetPreview(params)
        case DocsJSService.sheetShowSnapshotAlert.rawValue:
            showSnapshotAlertView(params)
        case DocsJSService.sheetHideLoading.rawValue:
            handleSheetHideLoading()
        case DocsJSService.sheetShowLoading.rawValue:
            handleSheetShowLoading()
        case DocsJSService.sheetPrepareWriteImage.rawValue:
            handleStartWriteImage(params)
        case DocsJSService.sheetReceiveImageData.rawValue:
            handleReceiveImageData(params)
        case DocsJSService.sheetGetSharePanelHeight.rawValue:
            notifyFrontendSharePanelHeight(params)
        case DocsJSService.sheetStopTransferImage.rawValue:
            sheetShareManager?.cancelWriteImageTask(fromWeb: true)
        case DocsJSService.sheetGetWatermarkInfo.rawValue:
            handleSheetGetWatermarkInfo()
        default: break
        }
    }
    
    //记录处理回调
    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        callbacks[DocsJSService(rawValue: serviceName)] = callback
        self.handle(params: params, serviceName: serviceName)
    }
    
    func handleShareService(_ params: [String: Any]) {
        guard let urlString = params["url"] as? String, let url = URL(string: urlString) else {
            DocsLogger.info("share parames not right")
            return
        }

        guard let docsInfo = hostDocsInfo else {
            DocsLogger.info("docs info or authinfo is nil")
            spaceAssertionFailure()
            return
        }

        guard let hostViewController = navigator?.currentBrowserVC as? BaseViewController else {
            DocsLogger.info("navigator currentBrowserVC is nil")
            spaceAssertionFailure()
            return
        }
        
        // 版本的话，需要增加版本参数
        if docsInfo.isVersion, let versionInfo = docsInfo.versionInfo, !urlString.contains("edition_id="), let vurl = URL(string: urlString) {
            docsInfo.shareUrl = vurl.docs.addQuery(parameters: ["edition_id": versionInfo.version]).absoluteString
        } else {
            docsInfo.shareUrl = urlString
        }

        docsInfo.title = params["title"] as? String
        
        let shareEntity: SKShareEntity
        if let token = DocsUrlUtil.getFileToken(from: url),
           let docType = DocsUrlUtil.getFileType(from: url),
           docType == .sync {
            shareEntity = SKShareEntity(objToken: token, type: docType.rawValue, spaceSingleContainer: true)
        } else {
            shareEntity = SKShareEntity.transformFrom(info: docsInfo)
        }

        if UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance, let bizInfo = params["bizInfo"] as? [String: Any] {
            if let jsonDict = bizInfo["bitableProInfo"] as? [String: Any] {
                do {
                    let bitableAdPermInfo = try CodableUtility.decode(BitableBridgeData.self, withJSONObject: jsonDict)
                    shareEntity.bitableAdPermInfo = bitableAdPermInfo
                } catch {
                    DocsLogger.error("BitableBridgeData decode error", error: error)
                }
            }
        }

        let shareVC = SKShareViewController(shareEntity,
                                            delegate: self,
                                            router: self,
                                            source: .content,
                                            isInVideoConference: docsInfo.isInVideoConference ?? false,
                                            followAPIDelegate: model?.vcFollowDelegate)
        shareVC.watermarkConfig.needAddWatermark = hostDocsInfo?.shouldShowWatermark ?? true
        if docsInfo.inherentType.supportLandscapeShow {
            shareVC.supportOrientations = hostViewController.supportedInterfaceOrientations
        }
        shareViewController = shareVC
        let nav = LkNavigationController(rootViewController: shareVC)
        //点击fshare btn的上报
        self.reportClientContentManagement(docsInfo: hostDocsInfo)

        if SKDisplay.pad, ui?.editorView.isMyWindowRegularSize() ?? false {
            navigator?.currentBrowserVC?.view.window?.endEditing(true)
            shareVC.modalPresentationStyle = .popover
            shareVC.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            let browserVC = navigator?.currentBrowserVC as? BaseViewController
            var index = -1
            guard let trailingButtonItems = ui?.displayConfig.trailingButtonItems else { return }
            trailingButtonItems.enumerated().forEach { idx, item in
                if item.id == .share {
                    //如果导航栏上有分享按钮则在分享按钮上弹出
                    //至于index为啥要这么算，可看看下面的 showPopover 的实现
                    index = -idx - 1
                }
            }
            //TODO（LJW）：可以优化，业务只传入ItemID，由showPopover方法里决定在那个位置弹出
            browserVC?.showPopover(to: nav, at: index)
        } else {
            nav.modalPresentationStyle = .overFullScreen
            navigator?.presentViewController(nav, animated: false, completion: nil)
        }
        
        let callback = params["callback"] as? String ?? ""
        let badges = params["badges"] as? [String] ?? []
        let disables = params["disables"] as? [String] ?? []
        
        var configInfo = SharePanelConfigInfo()
        configInfo.badges = badges
        configInfo.disables = disables
        self.callback = callback
        sharePanelConfig = configInfo
        
        //红点处理
        let params: [String: Any] = ["panelName": BadgedItemIdentifier.sharePanel.rawValue, "badges": [ShareItemIdentifier.shareImage.rawValue]]
        
        self.model?.jsEngine.callFunction(DocsJSCallBack.sheetClearBadges, params: params, completion: nil)
    }
}



extension UtilShareService: ShareViewControllerDelegate, ShareRouterAbility {
//    func shareRouterToOtherApp(_ vc: UIViewController) {
//        if SKDisplay.pad, vc.modalPresentationStyle == .popover {
//            let browserVC = navigator?.currentBrowserVC as? BaseViewController
//            browserVC?.showPopover(to: vc, at: -2)
//        } else {
//            navigator?.presentViewController(vc, animated: true)
//        }
//    }


    func requestShareToLarkServiceFromViewController() -> UIViewController? {
        return navigator?.currentBrowserVC
    }
    
    func requestExportLongImage(controller: UIViewController) {
        controller.dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            
            self.handleExportImage()
        }
    }

    func requestSlideExport(controller: UIViewController) {
        guard self.ui != nil, self.model != nil else {
            return
        }
        controller.dismiss(animated: false) { [weak self] in
            guard let `self` = self else { return }
            self.model?.jsEngine.simulateJSMessage(DocsJSService.slideExportSelect.rawValue, params: [:])
        }
    }

    func requestDisplayShareViewAccessory() -> UIView? {
        return model?.shareAgent.browserViewRequestShareAccessory()
    }

    func requestExist(controller: UIViewController) {
        shareViewController = nil
    }

    func shouldDisplaySnapShotItem() -> Bool { 
        if self.model?.hostBrowserInfo.isInVideoConference ?? false {
            return false
        }
        return UtilShareService.shouldDisplaySnapShotItem(docsInfo: hostDocsInfo)
    }
    
    private static func shouldDisplaySnapShotItem(docsInfo: DocsInfo?) -> Bool {
        guard let type = docsInfo?.type else {
            return false
        }
        if type == .mindnote, docsInfo?.mindnoteInfo?.isMindMapType == false { //Mindnote导图模式中的分享面板不显示导出图片按钮
            return true
        }
        var snapShotPassTypes: Set<DocsType> = [.doc, .sheet, .docX]
        if snapShotPassTypes.contains(type) {
            return true
        }
        return false
    }
    
    
    func sharePanelConfigInfo() -> SharePanelConfigInfoProtocol? {
        return sharePanelConfig
    }

    func shouldDisplaySlideExport() -> Bool {
        // MinaConfigKey.slideExportEnable 已经GA
        if let type = hostDocsInfo?.type, type == .slides {
            return true
        }
        return false
    }

//    func currentViewController() -> UIViewController? {
//        return navigator?.currentBrowserVC as? BaseViewController
//    }
    
//    func shareRouterPresent(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
//        if SKDisplay.pad, vc.modalPresentationStyle == .popover {
//            let browserVC = navigator?.currentBrowserVC as? BaseViewController
//            browserVC?.showPopover(to: vc, at: -2)
//        } else {
//            navigator?.presentViewController(vc, animated: animated)
//        }
//    }
    
    func handleExportImage() {
        guard let docsInfo = hostDocsInfo, let hostView = self.ui?.hostView, let hostController = navigator?.currentBrowserVC else {
            DocsLogger.info("docs info or authinfo or hostView is nil")
            spaceAssertionFailure()
            return
        }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                spaceAssertionFailure("permissionService for host not found when export image")
                return
            }
            let response = permissionService.validate(operation: .export)
            response.didTriggerOperation(controller: hostController)
            guard response.allow else { return }
        } else {
            if DlpManager.showTipsIfUnSafe(on: hostView, with: docsInfo, action: .EXPORT) {
                return
            }
        }

        if CacheService.showFailureIfDiskCryptoEnable(on: hostView) {
            return
        }

        if docsInfo.isSheet {
            handleSheetExportImage()
        } else {
            handleDocExportImage()
        }
    }
    
    func handleDocExportImage() {

        self.model?.jsEngine.simulateJSMessage(DocsJSService.screenShotStart.rawValue, params: [:])
    }
    
    func handleSheetExportImage() {
        let params = ["id": ShareItemIdentifier.shareImage.rawValue]
        DocsLogger.info("处理sheet导出 \(callback), params: \(params)")
        self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
        
    }
    
    func onBitableAdPermPanelClick(_ data: BitableBridgeData) {
        guard UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance else {
            return
        }
        ui?.displayConfig.showBitableAdvancedPermissionsSettingVC(data: data, listener: self)
    }
}

extension UtilShareService: BrowserViewLifeCycleEvent {
    func browserDidDismiss() {
        shareViewController?.dismiss(animated: false, completion: nil)
        sheetShareManager?.hideLoadingTip()
        sheetShareManager?.cancelWriteImageTask()
    }
    
    func browserDidChangeOrientation(from: UIInterfaceOrientation, to newOrentation: UIInterfaceOrientation) {
        shareViewController?.didChangeStatusBarOrientation(to: newOrentation)
    }
}

extension UtilShareService {
    public func reportClientContentManagement(docsInfo: DocsInfo?) {
        var params: [String: String] = [:]
        params["source"] = "innerpage"
        params["status_name"] = ""
        params["action"] = "share"
        if docsInfo?.isFromWiki == true {
            params["file_id"] = DocsTracker.encrypt(id: docsInfo?.wikiInfo?.wikiToken ?? "")
            params["module"] = "wiki"
            params["file_type"] = "wiki"
        } else {
            params["file_id"] = DocsTracker.encrypt(id: docsInfo?.objToken ?? "")
            params["module"] = docsInfo?.type.name   //内页的module使用具体的fileType
            params["file_type"] = docsInfo?.type.name
        }
        DocsTracker.log(enumEvent: .clientContentManagement, parameters: params)
    }
}

extension UtilShareService {
    //回调水印参数
    func handleSheetGetWatermarkInfo() {
        let config = watermarkViewConfig.obviousWaterMarkPatternConfig()
        self.callbacks[.sheetGetWatermarkInfo]?.callbackSuccess(param: config)
        DocsLogger.info("handleSheetGetWatermarkInfo call back，config count: \(config.count)")
    }
}
