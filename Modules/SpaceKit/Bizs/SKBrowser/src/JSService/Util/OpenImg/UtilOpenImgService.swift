//
//  UtilOpenImgService.swift
//  SpaceKit
//
//  Created by Songwen Ding on 2018/6/13.
//
//  swiftlint:disable cyclomatic_complexity file_length

import SnapKit
import Foundation
import LarkUIKit
import SwiftyJSON
import EENavigator
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import Photos
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignDialog
import ByteWebImage
import UIKit
import SpaceInterface
import SKInfra
import LarkSensitivityControl

class UtilOpenImgService: BaseJSService {
    weak var commentBottomConstraint: Constraint?
    lazy private var newCacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)!

    //处理图片查看的逻辑
    private lazy var skopenImagePlugin: BaseOpenImagePlugin = {
        var config = SKBaseOpenImagePluginConfig(cacheServce: newCacheAPI, from: .webBridge)
        config.AssetBrowserVCType = DocsAssetBrowserViewController.self
        config.actionHandlerGenerator = { [weak self] in
            let actionHandler = AssetBrowserActionHandler()
            actionHandler.actionDelegate = self
            actionHandler.scanQR = { [weak self] code in
                guard let fromVC = self?.docsAssetBrowserVC?.presentingViewController else { return }
                self?.docsAssetBrowserVC?.dismiss(animated: true, completion: { [weak fromVC] in
                    if let _formVC = fromVC {
                        ScanQRManager.openScanQR(code: code,
                                              fromVC: _formVC,
                                              vcFollowDelegateType: .browser(self?.model?.vcFollowDelegate))
                    }
                })
            }
            return actionHandler
        }
        let plugin = BaseOpenImagePlugin(config)
        plugin.hostDocsInfo = self.hostDocsInfo
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        plugin.pluginProtocol = self
        return plugin
    }()
    
    weak var commentNavigationController: SKNavigationController?

    
    private var docsAssetBrowserVC: DocsAssetBrowserViewController? {
        return skopenImagePlugin.assetBrowserVC as? DocsAssetBrowserViewController
    }
    // Data
    private var keyboard: Keyboard = Keyboard()
    private var willShowHeight: CGFloat = 0 //记录键盘willShow时间的高度，仅用于过滤键盘willShow和willChange事件的重复布局
    private var photoComments: [PhotoUUID: PhotoCommentData]?
    private var photoImage: [PhotoImageData]?
    private var isShowInput: Bool = false
    private var needShowResolve: Bool = false
    private var needShowMore: Bool = false
    private var needShowVoice: Bool = false
    private var needShowReaction: Bool = false
    // 协同过程中删除图片需要的临时变量，需要给AlertAction传递参数用，有更好方法麻烦教一下Orz
    private var deleteAlertInfo = DeleteAlertInfo()

    private var commentable: Bool = false // 这个值目前只有 sheet 在用, sheet 评论的特殊逻辑
    private var source: String = "" // 这个值目前只有 sheet 在用, sheet 评论的特殊逻辑

    // 发送标记位
    private var hasSendComment = false

    // Diagram操作标记位
    private var diagramAction: DiagramActionType = .downloadDiagramPhoto
    // 上报操作标识类型
    private var photoType: SKPhotoType = .normal

    // 上报操作标识类型
    public private(set) var isShowCommentInput: Bool = false

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {

        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        model.permissionConfig.permissionEventNotifier.addObserver(self)
    }
}

extension UtilOpenImgService: BrowserViewLifeCycleEvent {
    public func browserDidDismiss() {
        skopenImagePlugin.closeImage()
    }
}

extension UtilOpenImgService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return  skopenImagePlugin.handleServices + [ .setOuterDocData, .utilDeleteImg, .commentHideInput, .commentResultNotify, .pickDiagramData]
    }

    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("UtilOpenImgService handle \(serviceName), isInVC: \(isInVideoConference)",
                        component: LogComponents.imgPreview,
                        traceId: browserTrace?.traceRootId)
        switch serviceName {
        case DocsJSService.utilOpenImage.rawValue:
            if let size = self.ui?.editorView.frame.size, let windowSize = self.ui?.hostView.window?.frame {
                skopenImagePlugin.imageOffset = CGPoint(x: windowSize.width - size.width, y: windowSize.height - size.height)
            }
            skopenImagePlugin.hostDocsInfo = self.model?.hostBrowserInfo.docsInfo
            skopenImagePlugin.handle(params: params, serviceName: serviceName)
            
            if let callback = params["callback"] as? String {
                docsAssetBrowserVC?.jsCallback = callback
            }
            if let toolStatus = params["tool_status"] as? [String: Any], let commentable = toolStatus["commentable"] as? Bool {
                self.commentable = commentable
            }
            if let source = params["source"] as? String {
                self.source = source
            } else {
                self.source = ""
            }
        
            if let imgDictionary = params["image"] as? [String: Any], let url = imgDictionary["src"] as? String {
                // vcFollow时，需求方想要知道打开图片的地址
                if OperationInterceptor.interceptOpenImageIfNeed(url,
                                                              from: self.navigator?.currentBrowserVC,
                                                                 followDelegate: model?.vcFollowDelegate) {
                    return
                }
            }
            
            docsAssetBrowserVC?.reloadCommentButton()
        case DocsJSService.closeImageViewer.rawValue:
            skopenImagePlugin.handle(params: params, serviceName: serviceName)
        case DocsJSService.setOuterDocData.rawValue:
            updateComment(with: params)
        case DocsJSService.utilDeleteImg.rawValue:
            if let result = params["success"] as? Bool, result == true {
                if let assetVC = docsAssetBrowserVC {
                    UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Facade_DeleteSuccessfully, on: assetVC.view)
                    assetVC.dismissViewController(completion: nil)
                }
            } else {
                if let assetVC = docsAssetBrowserVC {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_DeleteFailedNoNet, on: assetVC.view)
                }
            }
        case DocsJSService.pickDiagramData.rawValue:
            _handlePickDiagramData(params: params)
        default:
            break
        }
    }
}

private extension UtilOpenImgService {
    /// 更新评论数据
    func updateComment(with params: [String: Any]) {
        guard let data = params["data"] as? [String: Any] else { DocsLogger.error("收到的评论数据格式不对"); return }
        isShowInput = (params["show_input"] as? Bool) ?? false
        needShowResolve = (params["show_resolve"] as? Bool) ?? false
        needShowMore = (params["show_more"] as? Bool) ?? false
        needShowVoice = (params["show_voice"] as? Bool) ?? false
        needShowReaction = (params["show_reaction"] as? Bool) ?? false
        photoComments = [PhotoUUID: PhotoCommentData]()
        for (key, subJson) in JSON(data) {
            let photoCommentData = PhotoCommentData()
            if let canComment = subJson["commentable"].bool {
                photoCommentData.commentable = canComment
            }
            let dicts = (subJson.dictionaryObject?["comments"] as? [[String: Any]]) ?? []
            for rawComment in dicts {
                let comment = Comment()
                comment.serialize(dict: rawComment)
                photoCommentData.comments.append(comment)
            }
            // 根据 cur_comment_id 获取当前是第几个页面
            if let currentCommentID = params["cur_comment_id"] as? String,
               let index = photoCommentData.comments.firstIndex(where: { $0.commentID == currentCommentID }) {
                photoCommentData.currentPage = index
            }
            photoComments?[key] = photoCommentData
        }
        DocsLogger.info("[image comment] photoComments updated count: \(photoComments?.count ?? 0)", component: LogComponents.comment)
        
        docsAssetBrowserVC?.reloadCommentButton()
    }
}

extension UtilOpenImgService: ServiceStatistics { }
extension UtilOpenImgService {
    var shouldShowWatermark: Bool {
        return self.hostDocsInfo?.shouldShowWatermark ?? true
    }

}

//extension UtilOpenImgService: CCMCopyPermissionDataSource {}

extension UtilOpenImgService: AssetBrowserActionDelegate {
    func assetBrowserAction(_ assetBrowserAction: AssetBrowserActionHandler, statisticsAction: String) {
        DocsTracker.log(enumEvent: .clientImageOperation, parameters: statisticsParameters(with: statisticsAction))
    }

    func assetBrowserActionSaveImageStatistics(uuid: String) {
        if let hostDocsInfo = hostDocsInfo { //这里埋点就用host docsInfo吧
            let bizParam = SpaceBizParameter(module: .drive,
                                             fileID: hostDocsInfo.encryptedObjToken,
                                             fileType: .file,
                                             driveType: "png")
            var params = ["click": "download", "object_file_type": "png", "object_id": DocsTracker.encrypt(id: uuid)]
            params.merge(other: bizParam.params)
            DocsTracker.newLog(enumEvent: .driveFileOpenClick, parameters: params)
        }
    }

    func shareItem(with type: SKPhotoType, image: UIImage?, uuid: String) {
        switch type {
        case .normal:
            if let image = image {
                guard let fromVC = self.docsAssetBrowserVC else {
                    spaceAssertionFailure("fromVC cannot be nil")
                    return
                }
                navigator?.sendLarkOpenEvent(.shareImage(image, controller: fromVC))
            }
        case .diagramSVG:
            self.diagramAction = .shareDiagramPhoto
            self.executeCallback(skopenImagePlugin.assetBrowserVC?.jsCallback, type:.downloadImage, with: uuid)
        }
    }

    func showFailHub(message: String) {
        if let showView = docsAssetBrowserVC?.view {
            UDToast.showFailure(with: message, on: showView)
        }
    }

    func showSuccessHub(message: String) {
        if let showView = docsAssetBrowserVC?.view {
            UDToast.showSuccess(with: message, on: showView)
        }
    }

    func showTipHub(message: String) {
        if let showView = docsAssetBrowserVC?.view {
            UDToast.showTips(with: message, on: showView)
        }
    }

    func willSwipeTo(_ index: Int) {
        guard let openImageData = skopenImagePlugin.openImageData else { return }
        if index >= 0, index < openImageData.imageList.count {
            if let uuid = openImageData.imageList[index].uuid {
                self.executeCallback(skopenImagePlugin.assetBrowserVC?.jsCallback, type:.swipe, with: uuid)
            }
        }
    }

    func requestDiagramDataWith(uuid: String) {
        self.diagramAction = .downloadDiagramPhoto
        self.executeCallback(skopenImagePlugin.assetBrowserVC?.jsCallback, type:.downloadImage, with: uuid)
    }
    
    func checkDownloadPermission(_ showTips: Bool, isAttachment: Bool, imageDocsInfo: DocsInfo?) -> Bool {
        let imageDocsInfo = imageDocsInfo ?? self.hostDocsInfo
        if isAttachment {
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
                let cacCanDownload = checkCACCanDownload(showToast: showTips)
                if cacCanDownload {
                    let dlpCanDownload = checkDLPCanDownload(showToast: showTips, imageDocsInfo: imageDocsInfo)
                    return dlpCanDownload
                } else {
                    return false
                }
            }
        } else {
            guard let imageDocsInfo = imageDocsInfo else { return false }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                let response = DocPermissionHelper.validate(objToken: imageDocsInfo.token,
                                                            objType: imageDocsInfo.inherentType,
                                                            operation: .export,
                                                            tenantID: hostDocsInfo?.getBlockTenantId(srcObjToken: imageDocsInfo.objToken))
                if showTips {
                    response.didTriggerOperation(controller: navigator?.currentBrowserVC ?? UIViewController())
                }
                return response.allow
            }
            return DocPermissionHelper.checkPermission(.ccmExport,
                                                       docsInfo: imageDocsInfo,
                                                       showTips: showTips,
                                                       securityAuditTips: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, hostView: docsAssetBrowserVC?.view)
        }
    }

    // 查看大图场景下载按钮是否可见的特化逻辑
    // 只用 Drive 校验 CAC 逻辑
    private func checkDownloadAttachmentVisable(sourceToken: String) -> Bool {
        let tenantID = self.hostDocsInfo?.getBlockTenantId(srcObjToken: sourceToken)
        let response = DocPermissionHelper.validate(objToken: "", objType: .file, operation: .downloadAttachment, tenantID: tenantID)
        return response.allow
    }

    // 查看大图场景下载操作检验的特化鉴权逻辑
    // 用 drive 校验 CAC，在用文档校验 DLP
    // 7.3 版本 DLP 迁移后可简化为一次校验
    private func checkCanDownloadAttachment(sourceToken: String, sourceObjType: DocsType) -> Bool {
        let tenantID = hostDocsInfo?.getBlockTenantId(srcObjToken: sourceToken)
        let response = DocPermissionHelper.validateForDownloadImageAttachmentV2(objToken: sourceToken,
                                                                                objType: sourceObjType,
                                                                                tenantID: tenantID)
        response.didTriggerOperation(controller: navigator?.currentBrowserVC ?? UIViewController())
        return response.allow
    }

    /// 检测CAC是否允许下载
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func checkCACCanDownload(showToast: Bool) -> Bool {
        let tipsText = BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast
        return DocPermissionHelper.checkPermission(.ccmAttachmentDownload,
                                                   docType: .file,
                                                   token: "",
                                                   showTips: showToast,
                                                   securityAuditTips: tipsText,
                                                   hostView: docsAssetBrowserVC?.view)
    }
    
    /// 检测DLP是否允许下载
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func checkDLPCanDownload(showToast: Bool, imageDocsInfo: DocsInfo?) -> Bool {
        guard let imageDocsInfo = imageDocsInfo ?? self.hostDocsInfo else { return false }
        let dlpAction = DlpCheckAction.EXPORT
        let dlpStatus = DlpManager.status(with: imageDocsInfo.token,
                                          type: imageDocsInfo.inherentType,
                                          action: dlpAction)
        let dlpResult = (dlpStatus == .Safe)
        if dlpStatus != .Safe, showToast, let onView = docsAssetBrowserVC?.view {
            let tenantID = self.hostDocsInfo?.getBlockTenantId(srcObjToken: imageDocsInfo.token)
            let text = dlpStatus.text(action: dlpAction, tenantID: tenantID)
            let type: DocsExtension<UDToast>.MsgType = (dlpStatus == .Detcting) ? .tips : .failure
            UDToast.docs.showMessage(text, on: onView, msgType: type)
        }
        return dlpResult
    }
}

private extension UtilOpenImgService {

    enum CallbackType: String {
        case loadError  // 加载失败
        case exit       // 退出查看器
        case swipe      // 切换到另一张
        case comment    // 点击评论
        case downloadImage // 下载Diagram照片
    }

    private func executeCallback(_ callback: String?, type: CallbackType, with uuid: String) {
        if let callback = callback {
            self.model?.jsEngine.callFunction(
                DocsJSCallBack(callback),
                params: ["type": type.rawValue, "uuid": uuid],
                completion: nil
            )
            DocsLogger.info("UtilOpenImgService type: \(type.rawValue) callback is success", component: LogComponents.comment)
        } else {
            spaceAssertionFailure("assetVC callback is nil")
            DocsLogger.error("UtilOpenImgService type: \(type.rawValue) comment callback is nil", component: LogComponents.comment)
        }
    }
}

extension UtilOpenImgService: PhotoCommentDelegate {
    /// 显示评论卡片or评论框
    func showComment(with uuid: PhotoUUID) {
        // sheet 特殊处理, 不走标准的逻辑
        guard source != "sheet" else {
            DocsLogger.error("UtilOpenImgService source == sheet", component: LogComponents.comment)
            executeCallback(skopenImagePlugin.assetBrowserVC?.jsCallback, type: .comment, with: uuid)
            return
        }
        let loadEnable = SettingConfig.commentPerformanceConfig?.loadEnable == true
        if loadEnable {
            let simulateCallback = DocsJSService.simulateCommentEntrance.rawValue
            model?.jsEngine.simulateJSMessage(simulateCallback, params: ["clickFrom" : "image_comment", "clickTime": Date().timeIntervalSince1970 * 1000])
        }
        self.callFunction(for: .clickImageComment, params: ["imageId": uuid])

        if let hostDocsInfo = self.hostDocsInfo { //评论都使用hostDocsInfo
            let bizParam = SpaceBizParameter(module: .drive,
                                             fileID: hostDocsInfo.encryptedObjToken,
                                             fileType: .file,
                                             driveType: "png")
            var params = ["click": "comment", "object_file_type": "png", "object_id": DocsTracker.encrypt(id: uuid)]
            params.merge(other: bizParam.params)
            DocsTracker.newLog(enumEvent: .driveFileOpenClick, parameters: params)
        }
    }
    /// 当前卡片是否可以评论
    func commentable(with uuid: PhotoUUID) -> Bool {

        guard source != "sheet" else {
            return commentable
        }

        return photoComments?[uuid]?.commentable ?? false
    }
    /// 评论数目
    func commentCount(with uuid: PhotoUUID) -> Int {
        guard let comments = photoComments?[uuid]?.comments else { return 0 }
        var count = 0
        for comment in comments {
            let value = comment.commentList.realCount
            count += value
            DocsLogger.info("[image comment] added replyCount: \(value)", component: LogComponents.comment)
        }
        DocsLogger.info("[image comment] comments: \(comments.count), total: \(count)", component: LogComponents.comment)
        return count
    }
    /// 通知前端图片浏览器退出了
    func skAssetBrowserVCWillDismiss(assetVC: SKAssetBrowserViewController) {
        keyboard.stop()
        DocsTracker.log(enumEvent: .clientImageOperation, parameters: statisticsParameters(with: "quit"))
        let uuid = assetVC.currentPhotoUdid() ?? ""
        DocsLogger.info("executeCallback, uuid:\(uuid.encryptToShort),\(assetVC.jsCallback ?? "")")
        executeCallback(assetVC.jsCallback, type: .exit, with: uuid)
    }

    func docsAssetBrowser(_ docsAssetBrowserVC: DocsAssetBrowserViewController, statisticsAction: String) {
        DocsTracker.log(enumEvent: .clientImageOperation, parameters: statisticsParameters(with: statisticsAction))
    }

    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {

        model?.jsEngine.callFunction(function, params: params, completion: completion)
    }
}

extension UtilOpenImgService: PhotoDeleteActionDelegate {
    func deleteImg(with uuid: PhotoUUID) {
        model?.jsEngine.callFunction(DocsJSCallBack.deleteImg, params: ["uuid": uuid], completion: nil)
    }
}

extension UtilOpenImgService: PhotoEditActionDelegate {
    func clickEdit(photoToken: String, uuid: String) {
        guard let callback = skopenImagePlugin.assetBrowserVC?.jsCallback else {
            spaceAssertionFailure("docsAssetBrowserVC callback is nil")
            return
        }
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["type": "edit",
                                                                        "token": photoToken,
                                                                        "uuid": uuid], completion: nil)
    }
}
extension UtilOpenImgService: PhotoBrowserOrientationDelegate {
    func docsAssetBrowserTrackForOrientationDidChange(_ docsAssetBrowserVC: DocsAssetBrowserViewController) -> DocsInfo? {
        return hostDocsInfo
    }
}

extension UtilOpenImgService: BaseOpenImagePluginProtocol {

    func presentClearViewController(_ v: SKAssetBrowserViewController, animated: Bool) {
        v.useModule = .normalImg
        v.onViewDidAppear = { [weak self] in
            guard let self else { return }
            if self.isShowCurrentDocsImage {
                self.docsAssetBrowserVC?.setAllowCapture(self.hasCopyPermission)
            }
        }
        DocsLogger.info("UtilOpenImgService presentClearViewController:\(v)")
         /// 因为LKAssetBrowserViewController内部自定义了转场LKAssetBrowserPresentTransitioning，这里在vc场景下特殊处理下
        guard let fromBrowserVC = self.navigator?.currentBrowserVC else {
            DocsLogger.error("UtilOpenImgService, presentClearViewController, topMostVC = nil ")
            return
        }
        if isInVideoConference {
            v.viewInitialSize = fromBrowserVC.view.bounds.size
            v.view.frame = CGRect(origin: .zero, size: fromBrowserVC.view.bounds.size)
            presentAssetBrowserVCInMagicShare(v)
        } else {
            DocsLogger.info("UtilOpenImgService presentInVC useBrowserVC")
            v.viewInitialSize = fromBrowserVC.view.bounds.size
            fromBrowserVC.present(v, animated: animated, completion: nil)
        }
    }
    
    /// 在 MS 下弹出图片，需要做各种适配
    func presentAssetBrowserVCInMagicShare(_ assetBrowserVC: SKAssetBrowserViewController) {
        /// 抽取重复代码，用来弹出
        func _present(with topMostVC: UIViewController?) {
            if let topMost = topMostVC {
                assetBrowserVC.modalPresentationStyle = .overCurrentContext
                topMost.present(assetBrowserVC, animated: false, completion: nil)
                DocsLogger.info("UtilOpenImgService handle presentInVC, useTopMostToPresent inVC \(String(describing: topMost))")
            } else {
                self.navigator?.presentClearViewController(assetBrowserVC, animated: false)
                DocsLogger.info("UtilOpenImgService handle presentInVC, useDefaultVC inVC ))")
            }
        }
        
        self.topMostOfBrowserVCWithoutDismissing { [weak self] topVC in
            guard let topVC = topVC else {
                DocsLogger.error("UtilOpenImgService handle presentInVC fine topVC error")
                return
            }
            // 2. 当前由于评论组件的信号和正文不同步，会导致先打开正文图片再关闭评论图片的情况，所以这里保持原有老逻辑 0.25s，后再打开图片
            //  常见于抢共享人时有时序问题。
            let isCommentImgVC = (topVC as? SKAssetBrowserViewController)?.useModule == .commentImg
            if  isCommentImgVC {
                DocsLogger.info("UtilOpenImgService handle presentInVC topVC is CommentImgVC: \(isCommentImgVC)")
                let delayTime: TimeInterval = SKDisplay.pad ? 0 : 0.25
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { [weak self] in
                    _present(with: self?.topMostOfBrowserVC())
                }
                return
            }
            // 3. 如果当前是正文图片，说明有系统动画 badcase，需要将之前的给关闭掉再弹出
            if topVC is SKAssetBrowserViewController {
                DocsLogger.info("UtilOpenImgService handle presentInVC topVC is DocsAssetBrowserViewController")
                topVC.dismiss(animated: false, completion: {
                    self?.navigator?.presentClearViewController(assetBrowserVC, animated: false)
                })
                return
            }
            // 4. 其他情况下正常弹出
            _present(with: topVC)
        }
    }

    func pluginWillRefreshImage(_ plugin: BaseOpenImagePlugin, type: SKPhotoType) {
        self.photoType = type
        DocsTracker.log(enumEvent: .clientImageOperation, parameters: statisticsParameters(with: "refresh_image"))
    }
    func pluginWillOpenImage(_ plugin: BaseOpenImagePlugin, type: SKPhotoType, showImageData: ShowPositionData?) {
        self.photoType = type
        let showImageUUID = showImageData?.uuid ?? ""
        if let imageDocsInfo = showImageData?.imageDocsInfo ?? self.hostDocsInfo {
            let driveType = (type == .normal) ? "png" : "SVG"
            let bizParam = SpaceBizParameter(module: .drive,
                                             fileID: imageDocsInfo.encryptedObjToken,
                                             fileType: .file,
                                             driveType: driveType)
            var params = ["preview_viable": "1", "object_file_type": driveType, "object_id": DocsTracker.encrypt(id: showImageUUID)]
            params.merge(other: bizParam.params)
            DocsTracker.newLog(enumEvent: .drivePageView, parameters: params)
        }
        DocsTracker.log(enumEvent: .clientImageOperation, parameters: statisticsParameters(with: "enter"))
    }
    func didCreateAssetBrowerVC(_ assertBrowserVC: SKAssetBrowserViewController, openImageData: OpenImageData) {
        guard let vc = assertBrowserVC as? DocsAssetBrowserViewController else {
            spaceAssertionFailure()
            return
        }
        let imageDocsInfo = openImageData.showImageData?.imageDocsInfo ?? self.hostDocsInfo
        vc.capturePreventerAnalyticsFileInfoBlock = { [weak self] () -> (String?, String?) in
            let fileId = DocsTracker.encrypt(id: self?.hostDocsInfo?.token ?? "")
            let fileType = self?.hostDocsInfo?.inherentType.name ?? ""
            DocsLogger.info("ViewCapture Event: UtilOpenImgService fileId: \(fileId), fileType: \(fileType)")
            return (fileId, fileType)
        }
        vc.isAlwayHideCommentButton = isInVideoConference
        
        if let showImageData = openImageData.showImageData {
            updateViewToolStatus(vc: vc,
                                 imageData: showImageData.toPhotoImageData(),
                                 mainToolStatus: openImageData.toolStatus)
        } else {
            spaceAssertionFailure("openImageData showImageData cannot be nil")
        }
        
        vc.jsCallback = openImageData.callback
        vc.watermarkConfig.needAddWatermark = self.hostDocsInfo?.shouldShowWatermark ?? true
        vc.commentDelegate = self
        vc.deleteDelegate = self
        vc.editDelegate = self
        vc.orientationDelegate = self
        vc.browserVCDelegate = self
    }

    func realImageUrlStrFor(_ originalUrl: String) -> String {
        return originalUrl.replacingOccurrences(of: DocSourceURLProtocolService.scheme, with: "https")
    }

    private func currentImageHasBeenDeleted(assects: [LKDisplayAsset], imgList: [PhotoImageData]) {
        defer {
            refreshDeleteAlertInfoIfNeeded(assects: assects, imgList: imgList)
        }
        // 若已经展示了【删除确认】的Alert 则重新设置Alert的confirm闭包，而不重复弹出
        guard deleteAlertInfo.deletedAlertDialog == nil else {
            DocsLogger.error("deletedAlertDialog aleady exsit")
            return
        }
        DocsLogger.info("currentImageHasBeenDeleted")
        if deleteAlertInfo.deletedAlertDialog == nil {
            let dialog = UDDialog()
            dialog.setContent(text:BundleI18n.SKResource.Doc_Doc_ImageDeletedTip)
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
                self?.docsAssetBrowserVC?.confirmDeleted(with: self?.deleteAlertInfo)
                self?.deleteAlertInfo.clearInfo()
            })
            deleteAlertInfo.deletedAlertDialog = dialog
        }
        
        if let vc = deleteAlertInfo.deletedAlertDialog {
            if docsAssetBrowserVC?.presentedViewController != nil {
                //如果有presentedVC，先干掉
                docsAssetBrowserVC?.presentedViewController?.dismiss(animated: false) { [weak self] in
                    self?.docsAssetBrowserVC?.present(vc, animated: false, completion: nil)
                }
            } else {
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

    func refreshSuccFor(assects: [LKDisplayAsset], imgList: [PhotoImageData]) {
        refreshDeleteAlertInfoIfNeeded(assects: assects, imgList: imgList)
    }

    func currentImageHasBeenDeletedWhenRefresh(assects: [LKDisplayAsset], imgList: [PhotoImageData]) {
        currentImageHasBeenDeleted(assects: assects, imgList: imgList)
    }

    var imageRequesetModifier: RequestModifier? {
        return { [weak self] request in
            var r = request
            self?.model?.requestAgent.requestHeader.forEach({ (key, value) in
                r.setValue(value, forHTTPHeaderField: key)
            })
            return r
        }
    }

    var modelConfig: BrowserModelConfig? {
        return self.model
    }
}

extension UtilOpenImgService: DocsAssetBrowserViewControllerDelegate {
    func updateViewToolStatus(vc: DocsAssetBrowserViewController, imageData: PhotoImageData, mainToolStatus: PhotoToolStatus?) {
        let imageDocsInfo = imageData.imageDocsInfo ?? self.hostDocsInfo
        /// 权限管控
        let isDiagramSVG = imageData.uuid?.isDiagramSVG ?? false
       
        let adminAttachmentDownload: Bool //附件下载权限
        let adminDocDownload: Bool  //文档下载权限
        let canCopy: Bool
        if let imageDocsInfo = imageDocsInfo {
            canCopy = model?.permissionConfig.checkCanCopy(for: .referenceDocument(objToken: imageDocsInfo.token)) ?? false
            adminDocDownload = self.checkDownloadPermission(false, isAttachment: false, imageDocsInfo: imageDocsInfo)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                adminAttachmentDownload = checkDownloadAttachmentVisable(sourceToken: imageDocsInfo.token)
            } else {
                adminAttachmentDownload = checkCACCanDownload(showToast: false)
            }
        } else {
            adminAttachmentDownload = true
            adminDocDownload = true
            canCopy = false
        }
        var openImagePermission = OpenImagePermission(canCopy:canCopy,
                                                      canShowDownload: true,  //dlp管控时隐藏，其它都给展示
                                                      canDownloadDoc: adminDocDownload,
                                                      canDownloadAttachment: adminAttachmentDownload)
        let canAdminDownload = isDiagramSVG ? openImagePermission.canDownloadDoc : openImagePermission.canDownloadAttachment
        
        if let s = mainToolStatus {
            let copy = s.copy.map { $0 && openImagePermission.canCopy }
            let toolStatus = PhotoToolStatus(comment: s.comment, copy: copy, delete: s.delete, export: s.export)
            vc.toolStatus = toolStatus //对比旧版本，这里每次都更新了一次，只是根据image对应的imageDocsInfo更新了copy权限，不影响
            if let shouldShowComment = toolStatus.comment {
                vc.showCommentButton = shouldShowComment
            }
            if let shouldShowDelete = toolStatus.delete {
                vc.showDeleteButton = shouldShowDelete
            }

            var allowDownload = false
            if let export = toolStatus.export {
                allowDownload = export
            } else {
                allowDownload = false
            }
            // 修正下载按钮显示逻辑
            openImagePermission.canShowDownload = allowDownload
            vc.showSavePhotoButton = openImagePermission.canShowDownload
            vc.savePhotoButtoGrayStyle = (allowDownload && canAdminDownload) ? false : true

            if let allowCopy = toolStatus.copy {
                vc.setAllowCapture(allowCopy)
            }
        }

        // 加入前端设置了single_tool_status，需要对这种情况单独配置
        if let s = imageData.subToolStatus {
            let copy = s.copy.map { $0 && openImagePermission.canCopy }
            let subToolStatus = PhotoToolStatus(comment: s.comment, copy: copy, delete: s.delete, export: s.export)
            if let shouldShowComment = subToolStatus.comment {
                vc.showCommentButton = shouldShowComment
            }
            if let shouldShowDelete = subToolStatus.delete {
                vc.showDeleteButton = shouldShowDelete
            }

            var allowDownload = false
            if let export = subToolStatus.export {
                allowDownload = export
            } else {
                allowDownload = false
            }
            // 修正下载按钮显示逻辑
            openImagePermission.canShowDownload = allowDownload
            vc.showSavePhotoButton = openImagePermission.canShowDownload
            vc.savePhotoButtoGrayStyle = (allowDownload && canAdminDownload) ? false : true

            if let allowCopy = subToolStatus.copy {
                vc.setAllowCapture(allowCopy)
            }
        }
        
        vc.updateBottomLayout()
        
        DocsLogger.info("update ImageView ToolStatus: main:\(String(describing: mainToolStatus)), sub:\(String(describing: imageData.subToolStatus)), perm:\(openImagePermission)")
    }
}


// PRIVATE METHOD
extension UtilOpenImgService {

    private func _handlePickDiagramData(params: [String: Any]) {
        guard let result = params["result"] as? String, (params["uuid"] as? String) != nil, let base64String = params["base64String"] as? String else {
            DocsLogger.error("Pick Diagram base err: params is missing")
            return
        }
        var isSuccessSave = true
        if result == "1", let image = UIImage.docs.image(base64: base64String) {
            switch self.diagramAction {
            case .downloadDiagramPhoto:
                PHPhotoLibrary.shared().performChanges({
                    do {
                        try AlbumEntry.creationRequestForAsset(forToken: Token(PSDATokens.DocX.docx_diagram_do_download), fromImage: image)
                    } catch {
                            isSuccessSave = false
                            DocsLogger.error("AlbumEntry err: creationRequestForAsset")
                    }
                }, completionHandler: { [weak self] (isSuccess, _) in
                    DispatchQueue.main.async(execute: { () in
                        if isSuccess && isSuccessSave {
                            self?.showSuccessHub(message: BundleI18n.SKResource.Doc_Doc_SaveImage + BundleI18n.SKResource.Doc_Normal_Success)
                        } else {
                            self?.showFailHub(message: BundleI18n.SKResource.Doc_Doc_SaveImage + BundleI18n.SKResource.Doc_AppUpdate_FailRetry)
                            DocsLogger.error("AlbumEntry err: creationRequestForAsset")
                        }
                    })
                })
            case .shareDiagramPhoto:
                guard let fromVC = self.docsAssetBrowserVC else {
                    spaceAssertionFailure("fromVC cannot be nil")
                    return
                }
                navigator?.sendLarkOpenEvent(.shareImage(image, controller: fromVC))
            }
            DocsLogger.info("Pick Diagram base success")
        } else {
            DocsLogger.error("Pick Diagram base err: encode base64 failed")
        }
    }
}

extension UtilOpenImgService {
    func statisticsParameters(with action: String) -> [AnyHashable: Any]? {
        var parameters = makeParameters(with: action)
        parameters?["block_type"] = self.photoType.statisticsValue
        return parameters
    }
}

extension ServiceStatistics where Self: UtilOpenImgService {
    func makeParameters(with action: String) -> [AnyHashable: Any]? {
        let fileType = self.hostDocsInfo?.type ?? .docX
        return ["action": action,
                "file_id": encryptedToken,
                "file_type": fileType.rawValue,
                "module": module]
    }
}

extension UtilOpenImgService: CommentServiceType {
    
    func callFunction(for action: CommentEventListenerAction, params: [String: Any]?) {
        if let jsService = model?.jsEngine.fetchServiceInstance(CommentNative2JSService.self) {
            jsService.callFunction(for: action, params: params)
        }
    }

    public func openDocs(url: URL) {
        if isInVideoConference {
            commentNavigationController?.dismiss(animated: false, completion: nil)
        }
        
        if OperationInterceptor.interceptUrlIfNeed(url.absoluteString,
                                                   from: self.navigator?.currentBrowserVC,
                                                   followDelegate: self.model?.vcFollowDelegate) {
            return
        }
        
        guard let nav = commentNavigationController else {
            DocsLogger.error("openDocs nav cannot be nil", component: LogComponents.comment)
            return
        }
        let fragmentIsEmpty = url.fragment?.isEmpty ?? true
        if navigator?.pageIsExistInStack(url: url) == false {
            model?.userResolver.navigator.push(url, from: nav)
        } else if fragmentIsEmpty {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Normal_SamePageTip, on: nav.view.window ?? UIView())
        } else {
            DocsLogger.info("url fragment is empty", component: LogComponents.comment)
        }
    }
    
    public func showUserProfile(userId: String) {
        showUserProfile(userId: userId, from: nil)
    }
    
    public func showUserProfile(userId: String, from: UIViewController?) {
        if OperationInterceptor.interceptShowUserProfileIfNeed(userId,
                                                               from: self.navigator?.currentBrowserVC,
                                                               followDelegate: model?.vcFollowDelegate) {
            DocsLogger.info("showUserProfile has been intercept",component: LogComponents.comment)
        } else if let nav = from { // 优先使用指定了的导航
            HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: nav))
        } else if let nav = commentNavigationController {
            HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: nav))
        } else {
            DocsLogger.error("[image comment] showUserProfile nav cannot be nil inVC:\(isInVideoConference)", component: LogComponents.comment)
        }
    }
}


extension UtilOpenImgService: CommentConferenceSource {
    
    var commentConference: CommentConference {
        guard let baseVC = navigator?.currentBrowserVC as? BrowserViewController,
              let spaceFollowAPIDelegate = baseVC.spaceFollowAPIDelegate else {
           DocsLogger.error("browserVC or follow delegate is nil", component: LogComponents.comment)
                  return CommentConference(inConference: false, followRole: nil, context: nil)
        }
        return CommentConference(inConference: baseVC.isInVideoConference, followRole: spaceFollowAPIDelegate.followRole, context: nil)
    }
}

// MARK: 权限相关
extension UtilOpenImgService {
    
    var assetBrowserController: SKAssetBrowserViewController? {
        return docsAssetBrowserVC
    }
}
