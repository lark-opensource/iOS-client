//
//  OpenCommentImageService.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2020/11/17.
//

import SKFoundation
import SKUIKit
import RxSwift
import LarkWebViewContainer
import UIKit
import SKCommon
import SpaceInterface


public final class OpenCommentImageService: BaseJSService, GadgetJSServiceHandlerType {
    
    struct RelateCommentInfo: Codable {
        var commentId: String = ""
        var replyId: String = ""
    }

    private var disposeBag = DisposeBag()
    
    public var callbacks: [DocsJSService: DocWebBridgeCallback] = [:]

    private(set) lazy var openImagePlugin: CommentPreviewPicOpenImageHandler = {
        var handler = CommentPreviewPicOpenImageHandler(delegate: self, transitionDelegate: self, docsInfo: hostDocsInfo)
        handler.commentImageContainerType = self.model?.jsEngine.fetchServiceInstance(CommentShowCardsService.self)
        return handler
    }()

    public override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
    
    // MARK: - 小程序
    
    weak var delegate: GadgetJSServiceHandlerDelegate?
    
    public var gadgetInfo: DocsInfo?
    
    var dependency: CommentPluginDependency?

    private var relateCommentInfo: RelateCommentInfo?
    
    public required init(gadgetInfo: CommentDocsInfo, dependency: CommentPluginDependency, delegate: GadgetJSServiceHandlerDelegate) {
        super.init()
        self.dependency = dependency
        self.gadgetInfo = gadgetInfo as? DocsInfo
        self.delegate = delegate
    }
}

extension OpenCommentImageService: BrowserViewLifeCycleEvent {
    public func browserDidDismiss() {
        openImagePlugin.closeImage()
    }
}


// MARK: - CommentPreviewPicOpenTransitionDelegate
extension OpenCommentImageService: CommentPreviewPicOpenTransitionDelegate {
    public func getTopMostVCForCommentPreview() -> UIViewController? {
        if self.navigator?.currentBrowserVC != nil {
            return self.topMostOfBrowserVC()
        } else {
            return UIViewController.docs.topMost(of: self.topMostViewController)
        }
    }
    
    public func getTopMostVCForCommentPreviewWithoutDismissing(completion: @escaping ((UIViewController?) -> Void)) {
        if self.navigator?.currentBrowserVC != nil {
            self.topMostOfBrowserVCWithoutDismissing(completion: completion)
        } else {
            completion(UIViewController.docs.topMost(of: self.topMostViewController))
        }
    }
}

extension OpenCommentImageService: DocsJSServiceHandler {
    
    static var handleServices: [DocsJSService] {
        return [.openImageForComment,
                .simulateCloseCommentImage]
    }
    
    public var handleServices: [DocsJSService] {
        return Self.handleServices
    }
    
    public var gadgetJsBridges: [String] {
        return handleServices.map { $0.rawValue }
    }

    public static var gadgetJsBridges: [String] { Self.handleServices.map { $0.rawValue } }

    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        if let bridgeCallback = callback {
            callbacks[.openImageForComment] = DocWebBridgeCallback.lark(bridgeCallback)
        }

        self.handle(params: params, serviceName: serviceName)
    }
    
    public func handle(params: [String: Any], extra: [String: Any], serviceName: String, callback: GadgetCommentCallback) {
        callbacks[.openImageForComment] = DocWebBridgeCallback.gadget(callback)
        self.handle(params: params, serviceName: serviceName)
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("OpenCommentImageService handle=\(serviceName)", component: LogComponents.comment)
        DocsLogger.debug("OpenCommentImageService", component: LogComponents.commentPic)
        let service = DocsJSService(serviceName)
        switch service {
        case .openImageForComment:
            //DispatchQueue.main.async是为了和CommentShowCardsService保持一致，不然可能有时序问题
            DispatchQueue.main.async {
                self.handleWithParam(params: params)
            }
        case .simulateCloseCommentImage:
            openImagePlugin.closeImage()
        default:
            spaceAssertionFailure()
        }
    }

    private func handleWithParam(params: [String: Any]) {
        if let active = params["active"] as? Int, let imageList = params["imageList"] as? [[String: Any]] {
            let msg = "[comment image] comment image active:\(active)"
            DocsLogger.info(msg, component: LogComponents.commentPic)
            CommentDebugModule.log(msg)
            if active == -1 {
                // 关闭图片查看器
                openImagePlugin.closeImage()
            } else if active >= 0, active < imageList.count {
                self.resetCommentInfo(with: params)
                self.openImage(active, imageRawArray: imageList)
            } else {
                DocsLogger.error("[comment image] param err", component: LogComponents.commentPic)
            }
        } else {
            DocsLogger.error("[comment image] param err2", component: LogComponents.commentPic)
        }
    }

     /// 重置评论信息。
    private func resetCommentInfo(with params: [String: Any]) {
        if let commentInfoData = params.json,
            let commentInfo = try? JSONDecoder().decode(RelateCommentInfo.self, from: commentInfoData) {
            self.relateCommentInfo = commentInfo
        } else {
            DocsLogger.error("OpenCommentImageService openImage without comemntInfo", component: LogComponents.commentPic)
        }
    }

    func openImage(_ activeIndex: Int, imageRawArray: [[String: Any]]) {
        DocsLogger.info("[comment image] OpenCommentImageService openImage, index=\(activeIndex)", component: LogComponents.commentPic)
        var currentShowImage: ShowPositionData?
        var imageList = [PhotoImageData]()
        var showIndex: Int = 0
        var anyImageToken = "" // 任一图片的token
        for (index, tempImage) in imageRawArray.enumerated() {
            let src = tempImage["src"] as? String
            let originalSrc = tempImage["originalSrc"] as? String
            if let srcStr = src, let srcUrl = URL(string: srcStr) {
                //这里同一用src.path做key,因为其他的值都可能为空
                let uuid = srcUrl.path
                let imageData = PhotoImageData(uuid: uuid, src: srcStr, originalSrc: originalSrc ?? srcStr)
                imageList.append(imageData)
                if activeIndex == index {
                    showIndex = index
                    currentShowImage = ShowPositionData(uuid: uuid, src: srcStr, originalSrc: originalSrc ?? srcStr, position: nil)
                }
            } else {
                DocsLogger.info("transform err", component: LogComponents.commentPic)
            }
            if let token = tempImage["token"] as? String, !token.isEmpty, anyImageToken.isEmpty {
                anyImageToken = token
            }
        }
        let allowCopyImg = model?.permissionConfig.hostCanCopy ?? false // 是否允许评论里的图片被复制，决定是否可以保存到相册&被截图
        let canDownload = self.commentImageCanDownloadInitValue
        let toolStatus = PhotoToolStatus(comment: nil, copy: allowCopyImg, delete: nil, export: canDownload)
        let openImageData = OpenImageData(showImageData: currentShowImage, imageList: imageList, toolStatus: toolStatus, callback: nil)
        openImagePlugin.openImage(openImageData: openImageData)
        updateDownloadButtonState(token: anyImageToken)

        //通知前端
        self.executeCallback(index: showIndex)
    }

    private func executeCallback(index: Int) {
        if let callback = callbacks[.openImageForComment] {
            callback.callFunction(action: nil, params: ["index": index])
        }
        notityToWebActivateImageChange(relateCommentInfo?.commentId, replyId: relateCommentInfo?.replyId ?? "", index: index)
    }
    
    private func notityToWebActivateImageChange(_ commentId: String?, replyId: String, index: Int) {
        DocsLogger.info("openimagechange, commentId=\(String(describing: commentId)), replyId=\(replyId), index=\(index)", component: LogComponents.commentPic)
        guard let commentIdTemp = commentId, commentIdTemp.isEmpty == false else {
            return
        }
        let param: [String: Any] = ["commentId": commentIdTemp,
                                    "replyId": replyId,
                                    "index": index]
        let jsService = self.model?.jsEngine.fetchServiceInstance(CommentNative2JSService.self)
        jsService?.callFunction(for: .activateImageChange, params: param)
    }

    // 刷新下载按钮状态, token传入任一图片的
    private func updateDownloadButtonState(token: String) {
        
        guard let service = model?.jsEngine.fetchServiceInstance(CommentShowCardsService.self) else { return }
        
        requestCommentImageDownloadPermission(imageToken: token, service: service) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .visible:
                self.openImagePlugin.setSaveButtonHidden(false)
                self.openImagePlugin.setSaveButtonGray(false)
            case .grayed:
                self.openImagePlugin.setSaveButtonHidden(false)
                self.openImagePlugin.setSaveButtonGray(true)
            case .hidden:
                self.openImagePlugin.setSaveButtonHidden(true)
            }
        }
    }
}

extension OpenCommentImageService: CommentImageDownloadPermissionProvider {

    public func commentImageDownloadDefaultValue() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else { return false }
            return permissionService.validate(operation: .download).allow
        } else {
            if let permission = model?.permissionConfig.hostUserPermissions {
                let canDownload = permission.canDownload() // 是否允许下载
                return canDownload
            } else {
                return false
            }
        }
    }
}

extension OpenCommentImageService: CommentPicOpenImageProtocol {
    public func willSwipeTo(_ index: Int) {
        DocsLogger.info("willSwipeTo, index=\(index)", component: LogComponents.commentPic)
        self.executeCallback(index: index)
    }

    public func skAssetBrowserVCWillDismiss(assetVC: SKAssetBrowserViewController) {
        DocsLogger.info("skAssetBrowserVCWillDismiss, index=\(-1)", component: LogComponents.commentPic)
        self.executeCallback(index: -1)
    }

    public func scanQR(code: String) {
        if let fromVC = UIViewController.docs.topMost(of: self.registeredVC) {
            DocsLogger.info("scanQR, code=\(code.count)", component: LogComponents.commentPic)
            ScanQRManager.openScanQR(code: code,
                                  fromVC: fromVC,
                                  vcFollowDelegateType: .browser(self.model?.vcFollowDelegate))
        }
    }
}

extension OpenCommentImageService {

    public var topMostViewController: UIViewController? {
        if let currentBrowserVC = self.navigator?.currentBrowserVC {
            return currentBrowserVC
        } else {
            return dependency?.topViewController
        }
    }
    
}
