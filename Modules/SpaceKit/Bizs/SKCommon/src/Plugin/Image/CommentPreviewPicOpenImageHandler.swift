//
//  CommentPreviewPicOpenImageHandler.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/9/24.
//  评论卡片里的图片查看器

import SKFoundation
import LarkUIKit
import SKResource
import SKUIKit
import LarkAssetsBrowser
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignDialog
import ByteWebImage
import UIKit
import SpaceInterface
import LarkContainer
import SKInfra

public protocol CommentPicOpenImageProtocol: AnyObject {
    func willSwipeTo(_ index: Int)
    func skAssetBrowserVCWillDismiss(assetVC: SKAssetBrowserViewController)
    func scanQR(code: String)
}

public protocol CommentPreviewPicOpenTransitionDelegate: AnyObject {
    func getTopMostVCForCommentPreview() -> UIViewController?
    func getTopMostVCForCommentPreviewWithoutDismissing(completion: @escaping ((UIViewController?) -> Void))
}

extension CommentPreviewPicOpenTransitionDelegate {
    public func getTopMostVCForCommentPreviewWithoutDismissing(completion: @escaping ((UIViewController?) -> Void)) {
        completion(self.getTopMostVCForCommentPreview())
    }
}

public protocol CommentImageContainerType: AnyObject {
    
    /// 当前容器是否能作为评论图片的合法容器
    func isLegal(for currentController: UIViewController) -> Bool
    
    func safePresent(callback: @escaping (UIViewController?) -> Void)
}

public final class CommentPreviewPicOpenImageHandler: NSObject {
    public var docsInfo: DocsInfo?
    public weak var delegate: CommentPicOpenImageProtocol?
    public weak var transitionDelegate: CommentPreviewPicOpenTransitionDelegate?
    public var fromCommentItem: CommentItem?
    private var deleteAlertInfo = DeleteAlertInfo()
    
    public weak var commentImageContainerType: CommentImageContainerType?

    private var docsAssetBrowserVC: DocsAssetBrowserViewController? {
        return skopenImagePlugin?.assetBrowserVC as? DocsAssetBrowserViewController
    }

    public init(delegate: CommentPicOpenImageProtocol? = nil, transitionDelegate: CommentPreviewPicOpenTransitionDelegate?, docsInfo: DocsInfo? = nil) {
        self.delegate = delegate
        self.transitionDelegate = transitionDelegate
        self.docsInfo = docsInfo
    }

    private var _skopenImagePlugin: BaseOpenImagePlugin?
    //处理图片查看的逻辑
    private var skopenImagePlugin: BaseOpenImagePlugin? {
        if let plugin = _skopenImagePlugin {
            return plugin
        }
        guard var commmentImageCache = DocsContainer.shared.resolve(CommentImageCacheInterface.self) as? SKImageCacheService else {
            return nil
        }
        
        var config = SKBaseOpenImagePluginConfig(cacheServce: commmentImageCache, from: .comment)
        config.AssetBrowserVCType = DocsAssetBrowserViewController.self
        config.actionHandlerGenerator = { [weak self] in
            let actionHandler = AssetBrowserActionHandler()
            actionHandler.actionDelegate = self
            actionHandler.scanQR = { [weak self] code in
                self?.docsAssetBrowserVC?.dismiss(animated: true, completion: {
                    self?.delegate?.scanQR(code: code)
                })
            }
            return actionHandler
        }
        let plugin = BaseOpenImagePlugin(config)
        plugin.pluginProtocol = self
        _skopenImagePlugin = plugin
        return plugin
    }

    public func closeImage() {
        DocsLogger.info("closeImage", component: LogComponents.commentPic)
        docsAssetBrowserVC?.representEnable = false
        docsAssetBrowserVC?.dismiss(animated: false, completion: nil)
        skopenImagePlugin?.assetBrowserVC = nil
    }

    public func openImage(openImageData: OpenImageData) {
        skopenImagePlugin?.openImage(openImageData: openImageData)
    }
    
    /// 多张图片统一设置:保存按钮是否置灰，只影响保存按钮的alpha值，不影响点击事件
    public func setSaveButtonGray(_ isGray: Bool) {
        docsAssetBrowserVC?.savePhotoButtoGrayStyle = isGray
    }
    
    /// 多张图片统一设置:保存按钮是否隐藏
    public func setSaveButtonHidden(_ isHidden: Bool) {
        docsAssetBrowserVC?.setSaveButtonHidden(isHidden)
    }
}

extension CommentPreviewPicOpenImageHandler: BaseOpenImagePluginProtocol {

    public func presentClearViewController(_ assetVC: SKAssetBrowserViewController, animated: Bool) {
        assetVC.useModule = .commentImg
        DocsLogger.info("[comment image] CommentPreviewPicOpenImageHandler presentClearViewController:\(assetVC)", component: LogComponents.commentPic)
        /// 因为LKAssetBrowserViewController内部自定义了转场LKAssetBrowserPresentTransitioning，这里在vc场景下特殊处理下
        let isInVC = docsInfo?.isInVideoConference ?? false
        if isInVC {
            self.transitionDelegate?.getTopMostVCForCommentPreviewWithoutDismissing { [weak self] fromVcTopMost in
                guard let fromVcTopMost = fromVcTopMost, let self = self else { return }
                if let container = self.commentImageContainerType,
                   container.isLegal(for: fromVcTopMost) == false {
                    // 可能当前评论正在展示，此时获取的topMost不准确，导致展示失败
                    // 需要等到评论展示完成再present
                    container.safePresent { [weak self] from in
                        self?.present(from: from ?? fromVcTopMost, assetVC: assetVC)
                    }
                } else {
                    self.present(from: fromVcTopMost, assetVC: assetVC)
                }
            }
        } else if let fromVcTopMost = self.transitionDelegate?.getTopMostVCForCommentPreview() {
            DocsLogger.info("[comment image] CommentPreviewPicOpenImageHandler, userTopMostToPresent", component: LogComponents.commentPic)
            assetVC.viewInitialSize = fromVcTopMost.view.bounds.size
            fromVcTopMost.present(assetVC, animated: true, completion: nil)
        } else {
            DocsLogger.error("[comment image] CommentPreviewPicOpenImageHandler, presentClearViewController, topMostVC = nil ", component: LogComponents.commentPic)
        }
    }
    
    func present(from: UIViewController, assetVC: SKAssetBrowserViewController) {
        assetVC.viewInitialSize = from.view.bounds.size
        // fromVcTopMost
        assetVC.view.bounds = from.view.bounds
        assetVC.view.frame.origin = CGPoint.zero
        assetVC.modalPresentationStyle = .overCurrentContext
        from.present(assetVC, animated: true, completion: nil)
        DocsLogger.info("[comment image] CommentPreviewPicOpenImageHandler, isInVC, fromVcTopMost=\(from)", component: LogComponents.commentPic)
    }

    public func pluginWillRefreshImage(_ plugin: BaseOpenImagePlugin, type: SKPhotoType) {
        DocsLogger.info("pluginWillRefreshImage", component: LogComponents.commentPic)
//        DocsTracker.log(enumEvent: .clientImageOperation, parameters: statisticsParameters(with: "refresh_image"))
    }
    public func pluginWillOpenImage(_ plugin: BaseOpenImagePlugin, type: SKPhotoType, showImageData: ShowPositionData?) {
        DocsLogger.info("pluginWillOpenImage", component: LogComponents.commentPic)
        let showImageUUID = showImageData?.uuid ?? ""
        if let imageDocsInfo = showImageData?.imageDocsInfo ?? self.docsInfo {
            let driveType = (type == .normal) ? "png" : "SVG"
            let bizParam = SpaceBizParameter(module: .drive,
                                             fileID: imageDocsInfo.encryptedObjToken,
                                             fileType: .file,
                                             driveType: driveType)
            var params = ["preview_viable": "1", "object_file_type": driveType, "object_id": DocsTracker.encrypt(id: showImageUUID)]
            params.merge(other: bizParam.params)
            DocsTracker.newLog(enumEvent: .drivePageView, parameters: params)
        }
//        DocsTracker.log(enumEvent: .clientImageOperation, parameters: statisticsParameters(with: "enter"))
    }
    public func didCreateAssetBrowerVC(_ assertBrowserVC: SKAssetBrowserViewController, openImageData: OpenImageData) {
        guard let vc = assertBrowserVC as? DocsAssetBrowserViewController else {
            spaceAssertionFailure()
            return
        }
        let allowCopy = openImageData.toolStatus?.copy ?? false
        vc.setAllowCapture(allowCopy)
        if UserScopeNoChangeFG.CS.commentImageUseDocAttachmentPermission == false {
            let allowExport = openImageData.toolStatus?.export ?? false
            vc.showSavePhotoButton = allowExport
            vc.updateBottomLayout()
        }
        vc.watermarkConfig.needAddWatermark = docsInfo?.shouldShowWatermark ?? true
    }

    public func realImageUrlStrFor(_ originalUrl: String) -> String {
        return originalUrl.replacingOccurrences(of: DocSourceURLProtocolService.scheme, with: "https")
    }

    private func currentImageHasBeenDeleted(assects: [LKDisplayAsset], imgList: [PhotoImageData]) {
        // 若已经展示了【删除确认】的Alert 则重新设置Alert的confirm闭包，而不重复弹出
        let didShowAlert = (deleteAlertInfo.deletedAlertDialog != nil)
        if !didShowAlert {
            let dialog = UDDialog()
            dialog.setContent(text:BundleI18n.SKResource.Doc_Doc_ImageDeletedTip)
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
                self?.docsAssetBrowserVC?.confirmDeleted(with: self?.deleteAlertInfo)
                self?.deleteAlertInfo.clearInfo()
            })
            deleteAlertInfo.deletedAlertDialog = dialog
        }
        refreshDeleteAlertInfoIfNeeded(assects: assects, imgList: imgList)
        DocsLogger.info("currentImageHasBeenDeleted, didShowAlert:\(didShowAlert)")
        if !didShowAlert {
            if let vc = deleteAlertInfo.deletedAlertDialog {
                docsAssetBrowserVC?.present(vc, animated: false, completion: nil)
            }
        }

    }

    private func refreshDeleteAlertInfoIfNeeded(assects: [LKDisplayAsset], imgList: [PhotoImageData]) {
        if deleteAlertInfo.deletedAlertDialog == nil {
            return
        }
        deleteAlertInfo.tempAssects = assects
        deleteAlertInfo.tempImgList = imgList
    }

    public func refreshSuccFor(assects: [LKDisplayAsset], imgList: [PhotoImageData]) {
        refreshDeleteAlertInfoIfNeeded(assects: assects, imgList: imgList)
    }

    public func currentImageHasBeenDeletedWhenRefresh(assects: [LKDisplayAsset], imgList: [PhotoImageData]) {
        currentImageHasBeenDeleted(assects: assects, imgList: imgList)
    }

    public var imageRequesetModifier: RequestModifier? {
        let requestHeader = SpaceHttpHeaders()
            .addLanguage()
            .addCookieString()
            .merge(SpaceHttpHeaders.common)
            .merge(["User-Agent": UserAgent.defaultNativeApiUA])
            .dictValue
        return { request in
            var r = request
            requestHeader.forEach({ (key, value) in
                r.setValue(value, forHTTPHeaderField: key)
            })
            return r
        }
    }

    public var modelConfig: BrowserModelConfig? {
        return nil
    }
}


extension CommentPreviewPicOpenImageHandler: AssetBrowserActionDelegate {
    public func assetBrowserAction(_ assetBrowserAction: AssetBrowserActionHandler, statisticsAction: String) {
//        DocsTracker.log(enumEvent: .clientImageOperation, parameters: statisticsParameters(with: statisticsAction))
    }

    public func assetBrowserActionSaveImageStatistics(uuid: String) {
        if let docsInfo = docsInfo {
            let bizParam = SpaceBizParameter(module: .drive,
                                             fileID: docsInfo.encryptedObjToken,
                                             fileType: .file,
                                             driveType: "png")
            var params = ["click": "download", "object_file_type": "png", "object_id": DocsTracker.encrypt(id: uuid)]
            params.merge(other: bizParam.params)
            DocsTracker.newLog(enumEvent: .driveFileOpenClick, parameters: params)
        }
    }

    public func shareItem(with type: SKPhotoType, image: UIImage?, uuid: String) {
        switch type {
        case .normal:
            if let image = image {
                guard let fromVC = self.docsAssetBrowserVC else {
                    spaceAssertionFailure("fromVC cannot be nil")
                    return
                }
                NotificationCenter.default.post(name: Notification.Name(DocsSDK.mediatorNotification), object: LarkOpenEvent.shareImage(image, controller: fromVC))
            }
        case .diagramSVG: break
        }
    }

    public func showFailHub(message: String) {
        if let showView = docsAssetBrowserVC?.view {
            UDToast.showFailure(with: message, on: showView)
        }
    }
    
    public func showDialog() {
        if let showView = docsAssetBrowserVC?.view {
            CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileDownload, fileBizDomain: .ccm, docType: .docX, token: nil)
        }
    }

    public func showSuccessHub(message: String) {
        if let showView = docsAssetBrowserVC?.view {
            UDToast.showSuccess(with: message, on: showView)
        }
    }

    public func showTipHub(message: String) {
        if let showView = docsAssetBrowserVC?.view {
            UDToast.showTips(with: message, on: showView)
        }
    }

    public func willSwipeTo(_ index: Int) {
        self.delegate?.willSwipeTo(index)
    }

    public func requestDiagramDataWith(uuid: String) {
    }

    public func skAssetBrowserVCWillDismiss(assetVC: SKAssetBrowserViewController) {
        self.delegate?.skAssetBrowserVCWillDismiss(assetVC: assetVC)
    }
    
    public func checkDownloadPermission(_ showTips: Bool, isAttachment: Bool, imageDocsInfo: DocsInfo?) -> Bool {
        let imageDocsInfo = imageDocsInfo ?? self.docsInfo
        //评论图片都算附件

        // 逻辑：
        // 显示置灰下载按钮的条件：CAC条件访问控制 == false
        // 置灰时点击处理：CAC条件访问控制 -> DLP控制，按顺序依次检测弹框或弹toast
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            if showTips {
                return checkCanDownloadAttachment(sourceToken: imageDocsInfo?.token ?? "",
                                                  sourceObjType: imageDocsInfo?.inherentType ?? .docX)
            } else {
                return checkDownloadAttachmentVisable(sourceToken: imageDocsInfo?.token ?? "")
            }
        } else {
            var token = ""
            if let vc = docsAssetBrowserVC, 0 <= vc.currentPageIndex, vc.currentPageIndex < vc.photoImageDatas.count {
                let currentImageData = vc.photoImageDatas[vc.currentPageIndex]
                token = currentImageData.token ?? ""
            }
            let cacCanDownload = checkCACCanDownload(showToast: showTips, token: token)
            if cacCanDownload {
                let dlpCanDownload = checkDLPCanDownload(showToast: showTips, imageDocsInfo: imageDocsInfo)
                return dlpCanDownload
            } else {
                return false
            }
        }
    }

    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        DocsLogger.info("不支持回调给前端，因为评论是native的")
    }
}

extension CommentPreviewPicOpenImageHandler {
    
    /// 检测CAC是否允许下载
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func checkCACCanDownload(showToast: Bool, token: String) -> Bool {
        let tipsText = BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast
        return DocPermissionHelper.checkPermission(.ccmAttachmentDownload,
                                                   docType: .file,
                                                   token: token,
                                                   showTips: showToast,
                                                   securityAuditTips: tipsText,
                                                   hostView: docsAssetBrowserVC?.view)
    }
    
    /// 检测DLP是否允许下载
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func checkDLPCanDownload(showToast: Bool, imageDocsInfo: DocsInfo?) -> Bool {
        guard let imageDocsInfo = imageDocsInfo ?? self.docsInfo else { return false }
        let dlpAction = DlpCheckAction.EXPORT
        let dlpStatus = DlpManager.status(with: imageDocsInfo.token,
                                          type: imageDocsInfo.inherentType,
                                          action: dlpAction)
        let dlpResult = (dlpStatus == .Safe)
        if dlpStatus != .Safe, showToast, let onView = docsAssetBrowserVC?.view {
            let tenantID = self.docsInfo?.getBlockTenantId(srcObjToken: imageDocsInfo.token)
            let text = dlpStatus.text(action: dlpAction, tenantID: tenantID)
            let type: DocsExtension<UDToast>.MsgType = (dlpStatus == .Detcting) ? .tips : .failure
            UDToast.docs.showMessage(text, on: onView, msgType: type)
        }
        return dlpResult
    }

    // 查看大图场景下载按钮是否可见的特化逻辑
    // 只用 Drive 校验 CAC 逻辑
    private func checkDownloadAttachmentVisable(sourceToken: String) -> Bool {
        let tenantID = docsInfo?.getBlockTenantId(srcObjToken: sourceToken)
        let response = DocPermissionHelper.validate(objToken: "", objType: .file, operation: .downloadAttachment, tenantID: tenantID)
        return response.allow
    }

    // 查看大图场景下载操作检验的特化鉴权逻辑
    // 用 drive 校验 CAC，在用文档校验 DLP
    // 7.3 版本 DLP 迁移后可简化为一次校验
    private func checkCanDownloadAttachment(sourceToken: String, sourceObjType: DocsType) -> Bool {
        let tenantID = docsInfo?.getBlockTenantId(srcObjToken: sourceToken)
        let response = DocPermissionHelper.validateForDownloadImageAttachmentV2(objToken: sourceToken,
                                                                                objType: sourceObjType,
                                                                                tenantID: tenantID)
        response.didTriggerOperation(controller: docsAssetBrowserVC ?? UIViewController())
        return response.allow
    }
}
