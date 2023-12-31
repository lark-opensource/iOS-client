//
//  SheetShareManager.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/10/22.
// swiftlint:disable file_length

import SKUIKit
import SKCommon
import SKFoundation
import SKResource
import HandyJSON
import UniverseDesignToast
import RxSwift
import UniverseDesignColor
import SpaceInterface
import SKInfra

protocol SheetShareManagerDelegate: AnyObject {
    func callJSService(_ callback: DocsJSCallBack, params: [String: Any])
    func presentViewController(_ vc: UIViewController, animated: Bool)
    func simulateJS(_ js: String, params: [String: Any])
    func trackBaseInfo() -> [String: Any]
}

class SheetShareManager {
    weak var registeredVC: BrowserViewController?
    
    weak var delegate: SheetShareManagerDelegate?
    private(set) var docsInfo: DocsInfo
    weak var navigator: BrowserNavigator?
    
    var shareType: SheetShareType = .image
    var shareText = ""
    var notifySharePanelHeightCallback = ""

    var isEditButtonVisible = false
    var sheetOperationCallback = "" //预览分享面板的callback
    var receiveImageCallback = "" //接收图像数据的callback
    
    var shareHeaderView: SheetShareCustomHeaderView?
    var shareHeaderViewIsShown = ReplaySubject<Bool>.create(bufferSize: 1)

    var loadingView = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)
    var loadingWrapperView: UIView?

    var shareTextView: UITextView?
    var shareTextViewShouldShow: Disposable?

    var sharePanelFromNormal: SheetSharePanel?
    var sharePanelFromAlert: SheetSharePanel?
    var panelWrapperView: UIView?
    var sharePanelViewIsShown = ReplaySubject<Bool>.create(bufferSize: 1)

    //接收图像数据
    var receiveStatue = ReveiveImageStatus.idle
    var loadImageType = GenerateImageType.preview
    var imageHelper: StitchImageHelper?
    // 前端第一次传输数据超时的操作
    var transferOverTimeWorkItem = DispatchWorkItem {}
    
    weak var snapshotAlertController: PopViewController?
    
    weak var alertView: SheetSnapshotAlertView?
    
    var prevShareAssistType = ShareAssistType.more
    
    var storeImagePath: SKFilePath?
    var prevOperatedSharePanel: SheetSharePanel?
    var previousStatusBarBackgroundColor: UIColor?
    var previousStatusBarStyle: UIStatusBarStyle = .default
    
    lazy var shareActionManager: ShareActionManager? = {
        let shareEntity = SKShareEntity.transformFrom(info: docsInfo)
        return ShareActionManager(shareEntity, fromVC: navigator?.currentBrowserVC)
    }()
    
    //track相关
    var source: String = "" // 一键生图场景下汇报 "source"，卡片分享场景下汇报 "mode"
    
    init(_ registeredVC: BrowserViewController, docsInfo: DocsInfo, navigator: BrowserNavigator?) {
        self.registeredVC = registeredVC
        self.docsInfo = docsInfo
        self.navigator = navigator
    }
    
    func callJSService(_ callback: DocsJSCallBack, params: [String: Any]) {
        self.delegate?.callJSService(callback, params: params)
    }
    
    private func showLoadingTip(type: ShareAssistType) {
        hideLoadingTip()
        var text = BundleI18n.SKResource.Doc_Share_ExportImageLoading
        if type == .saveImage {
            text = BundleI18n.SKResource.Doc_PicExport_ImageDnlding
        }
        guard let displayView = self.navigator?.currentBrowserVC?.view else {
            spaceAssertionFailure("cannot get current window")
            return
        }
        UDToast.showLoading(with: text, on: displayView, disableUserInteraction: false)
    }
    
    func hideLoadingTip() {
        guard let displayView = self.navigator?.currentBrowserVC?.view else {
            return
        }
        UDToast.removeToast(on: displayView)
    }
}


// MARK: 打开预览视图
extension SheetShareManager {
    func handleShowSheetPreview(_ params: [String: Any]) {
        sheetOperationCallback = params["callback"] as? String ?? ""
        source = params["source"] as? String ?? ""
        
        createAndShowSharePanel()
        createAndShowTextViewIfNeeded()
    
        //设置headerView为黑色模式
        shareHeaderView?.style = .dark
        //设置状态栏
        changeStatusBarStyle(isDark: true)
    }
    
    func handleHideSheetPreview(_ params: [String: Any]) {
        //分享面板
        shareTextView?.removeFromSuperview()
        shareTextViewShouldShow?.dispose()
        panelWrapperView?.removeFromSuperview()
        sharePanelViewIsShown.onNext(false)
        shareHeaderView?.removeFromSuperview()
        shareHeaderViewIsShown.onNext(false)
        restoreStatusBarStyle()
    }
    
    func changeStatusBarStyle(isDark: Bool) {
        // dark mode需求开始跟随系统颜色
//        guard let bvc = self.registeredVC else { return }
//        previousStatusBarBackgroundColor = bvc.statusBar.backgroundColor
//        previousStatusBarStyle = bvc.statusBarStyle
//        if isDark {
//            bvc.statusBar.backgroundColor = UIColor.ud.N900
//            bvc.statusBarStyle = .lightContent
//        } else {
//            bvc.statusBar.backgroundColor = UIColor.ud.N00
//            if #available(iOS 13.0, *) {
//                bvc.statusBarStyle = .darkContent
//            } else {
//                bvc.statusBarStyle = .default
//            }
//        }
//        bvc.setNeedsStatusBarAppearanceUpdate()
    }

    func restoreStatusBarStyle() {
        guard let bvc = self.registeredVC else { return }
        bvc.statusBar.backgroundColor = previousStatusBarBackgroundColor
        bvc.statusBarStyle = previousStatusBarStyle
        bvc.setNeedsStatusBarAppearanceUpdate()
    }

    func createSharePanel() -> SheetSharePanel {
        return SheetSharePanel().construct { (it) in
            it.delegate = self as SheetSharePanelDelegate
            var items: [ShareAssistItem]  = []
            
            if let shareActionManager = shareActionManager {
                if shareType == .text {
                    items.append(shareActionManager.item(.copyAllTexts))
                    items.append(shareActionManager.item(.feishu))
                    items.append(contentsOf: shareActionManager.availableOtherAppItemsForSheet())
                } else {
                    items.append(shareActionManager.item(.saveImage))
                    items.append(shareActionManager.item(.feishu))
                    items.append(contentsOf: shareActionManager.availableOtherAppItemsForSheet())
                }
                items.append(shareActionManager.item(.more))
//                it.style = .white
                self.shareActionManager = shareActionManager
            }
            
            it.dataSource = items
        }
    }
    
    func createAndShowSharePanel() {
        guard let bvc = self.registeredVC, let containerView = bvc.view else {
            return
        }
        
        DocsLogger.info("createAndShowSharePanel")
        sharePanelFromNormal = createSharePanel()
        let panelWrapperView = UIView()
        self.panelWrapperView?.removeFromSuperview()
        self.panelWrapperView = nil
        self.panelWrapperView = panelWrapperView
        
        if let sharePanel = sharePanelFromNormal {
            let panelHeight: CGFloat = SheetSharePanel.Const.preferredHeight
            containerView.addSubview(panelWrapperView)
            panelWrapperView.backgroundColor = UIColor.ud.bgBody
            
            panelWrapperView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(panelHeight + containerView.safeAreaInsets.bottom)
            }
            
            panelWrapperView.addSubview(sharePanel)
            sharePanel.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(panelHeight)
            }

            sharePanelViewIsShown.onNext(true)
        }
    }
    
    func createAndShowTextViewIfNeeded() {
        guard shareType == .text, let bvc = registeredVC, let containerView = bvc.view else {
            DocsLogger.error("条件不足，无法显示 sheet share text view")
            return
        }

        let shareTextView = UITextView().construct { it in
            it.isEditable = false
            it.textContainerInset = UIEdgeInsets(top: 30, left: 24, bottom: 30, right: 24)
            it.backgroundColor = UIColor.ud.bgBody
            it.font = UIFont.systemFont(ofSize: 16)
            it.textContainer.lineFragmentPadding = 0
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 14
        let attributedString = NSAttributedString(string: shareText, attributes: [.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle])
        shareTextView.attributedText = attributedString
        self.shareTextView = shareTextView

        shareTextViewShouldShow?.dispose()
        shareTextViewShouldShow = Observable
            .combineLatest(shareHeaderViewIsShown, sharePanelViewIsShown)
            .subscribe(onNext: { [weak self, weak containerView] headerShowing, panelShowing in
                guard let self = self, let containerView = containerView else { return }
                guard headerShowing && panelShowing,
                      let headerView = self.shareHeaderView,
                      let shareTextView = self.shareTextView,
                      let panelView = self.panelWrapperView else {
                    DocsLogger.error("sheet share text 的 header 和 panel 都不在了，无法布局 textView")
                    self.shareTextView?.removeFromSuperview()
                    return
                }
                containerView.addSubview(shareTextView)
                shareTextView.snp.makeConstraints { (make) in
                    make.top.equalTo(headerView.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalTo(panelView.snp.top)
                }
                DispatchQueue.main.async { [weak self] in
                    self?.saveTextAndToast()
                }
            })
    }
}

// MARK: loading处理
extension SheetShareManager {
    func handleSheetHideLoading() {
        loadingWrapperView?.removeFromSuperview()
        loadingView?.stopAnimation()
    }
    
    func handleSheetShowLoading() {
        guard let registVC = self.registeredVC, let contentView = registVC.view else {
            return
        }
        
        let loadingWrapperView = UIView().construct { (it) in
            it.backgroundColor = UIColor.ud.N00
        }
        self.loadingWrapperView = loadingWrapperView
        contentView.addSubview(loadingWrapperView)
        let naviBar = registVC.navigationBar
        loadingWrapperView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(naviBar.snp.bottom)
        }
        if let loadingView = loadingView {
            loadingWrapperView.addSubview(loadingView.displayContent)
            loadingView.displayContent.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            loadingView.startAnimation()
        }
        self.loadingWrapperView = loadingWrapperView
    }
}

// MARK: 前端相关
extension SheetShareManager {
    func notifyFrontendSharePanelHeight(_ params: [String: Any]) {
        guard let typeStr = params["type"] as? String,
              let type = SheetShareType(rawValue: typeStr), // 当 type == .image 时 rawText 传空
              let rawText = params["data"] as? String, // 当 type == .text 时这里为对应表格文本
              let callback = params["callback"] as? String else {
            DocsLogger.info("sheetShareManager 前端传参错误", extraInfo: params)
            return
        }

        shareType = type
        shareText = rawText
        notifySharePanelHeightCallback = callback

        let content: [String: CGFloat]
        if let bvc = self.registeredVC, let containerView = bvc.view {
            content = ["viewHeight": SheetSharePanel.Const.preferredHeight + containerView.safeAreaInsets.bottom]
        } else {
            content = ["viewHeight": 0.0]
        }
        DocsLogger.info("sheetShareManager 通知前端分享面板高度 \(content)")
        callJSService(DocsJSCallBack(notifySharePanelHeightCallback), params: content)
    }
    
    func notifyFrontendUserDidTakeSnapshot() {
        if CacheService.isDiskCryptoEnable() {
            //KACrypto
            DocsLogger.error("[KACrypto] 开启KA加密不能截屏分享")
            return
        }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard DocPermissionHelper.validate(objToken: docsInfo.token,
                                         objType: docsInfo.inherentType,
                                               operation: .export).allow else {
                DocsLogger.error("has no Permission to TakeSnapshot")
                return
            }
        } else {
            if !DocPermissionHelper.checkPermission(.ccmExport,
                                                    docsInfo: docsInfo,
                                                    showTips: false) {
                DocsLogger.error("has no Permission to TakeSnapshot")
                return
            }
        }
        
        self.callJSService(DocsJSCallBack.sheetNotifySnapshot, params: [:])
    }
    
    func showSnapshotAlertView(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String, let imageSize = params["imageInfo"] as? [String: Int] else {
            DocsLogger.info("sheetShareManager 没有传递回调")
            return
        }
        guard let messages = params["messages"] as? String, let title = params["title"] as? String  else {
            DocsLogger.info("sheetShareManager 没有传递source")
            return
        }
        
        source = params["source"] as? String ?? ""
        makeTrack(isCard: false, action: "show_screenshot_dialog", opItem: nil)
        
        var alertInfo = SheetSnapshotAlertInfo(title: title, messages: messages)
        
        let width: CGFloat = CGFloat(imageSize["imageWidth"] ?? 0)
        let height: CGFloat = CGFloat(imageSize["imageHeight"] ?? 0)
        guard width != 0, height != 0 else {
            DocsLogger.info("sheetShareManager 前端传入的宽高异常")
            return
        }
        let ratio = width / height
        let sizeHeight = navigator?.currentBrowserVC?.view.window?.bounds.size.height ?? SKDisplay.activeWindowBounds.height
        let maxHeight = sizeHeight * 0.4
        let fixHeight = min(maxHeight, height)
        alertInfo.imageInfo = SheetImageInfo(imageWidth: width, imageHeight: fixHeight)
        
        if let imageInfo = alertInfo.imageInfo {
            let imageSize = CGSize(width: imageInfo.imageWidth, height: imageInfo.imageHeight)
            let alertView = SheetSnapshotAlertView(frame: .zero, imageViewSize: imageSize, ratio: ratio)
            alertView.changeOperationButton(false)
            let alert = PopViewController()
            alert.shouldDismissWhenTouchInOutsideOfContentView = false
            if SKDisplay.pad {
                alert.setContent(view: alertView, with: { make in
                    make.center.equalToSuperview()
                    make.width.equalTo(303)
                })
            } else {
                alert.setContent(view: alertView, padding: UIEdgeInsets(top: 0, left: 36, bottom: 0, right: 36))
            }
            alertView.setupWithAlertInfo(alertInfo)
            alertView.dismissAction = { [weak alert, weak self] in
                if let tAlert = alert {
                    tAlert.dismiss(animated: false, completion: nil)
                }
                //通知前端退出截屏
                self?.callJSService(DocsJSCallBack(callback), params: ["id": "exit"])
                self?.restoreStatusAndFreeCache()
                self?.loadImageType = .preview
                SheetTracker.report(event: .smartScreenCaptureClick(action: 2), docsInfo: self?.docsInfo)
            }
            alertView.saveAction = { [weak self] in
                guard let self = self else {
                    return
                }
                //前端出loading
                self.callJSService(DocsJSCallBack(callback), params: ["id": "leftBtn"])
                self.makeTrack(isCard: false, action: "click_share_export_image", opItem: "local")
                SheetTracker.report(event: .smartScreenCaptureClick(action: 0), docsInfo: self.docsInfo)
                if let path = self.storeImagePath {
                    self.saveImage(path, callback: { [weak self] _ in
                        guard let self = self else { return }
                        self.makeTrack(isCard: false,
                                       action: "share_export_image_success",
                                       opItem: "local")
                    })
                    return
                }
            }

            alertView.shareAction = { [weak self, weak alert] in
                guard let self = self, let alert = alert else {
                    return
                }

                let currentView = self.navigator?.currentBrowserVC?.view.window ?? UIView()
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    let response = DocPermissionHelper.validate(objToken: self.docsInfo.token,
                                                                objType: self.docsInfo.inherentType,
                                                                operation: .export)
                    response.didTriggerOperation(controller: currentView.affiliatedViewController ?? UIViewController())
                    guard response.allow else { return }
                } else {
                    guard DocPermissionHelper.checkPermission(.ccmExport,
                                                              docsInfo: self.docsInfo,
                                                              showTips: true,
                                                              securityAuditTips: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, hostView: currentView) else {
                        return
                    }
                }
                
                let subSharePanel = self.createSharePanel()
                subSharePanel.delegate = self
                let subAlert = PopViewController()
                let panelWrapper = UIView().construct {
                    $0.backgroundColor = UIColor.ud.N00
                }
                
                let panelHeight: CGFloat = SheetSharePanel.Const.preferredHeight
                
                panelWrapper.addSubview(subSharePanel)
                
                subSharePanel.snp.makeConstraints { (make) in
                    make.top.left.right.equalToSuperview()
                    make.height.equalTo(panelHeight)
                }
                
                subAlert.setContent(view: panelWrapper) { (make) in
                    make.left.right.equalToSuperview()
                    make.bottom.equalToSuperview()
                    make.height.equalTo(panelHeight + alert.view.safeAreaInsets.bottom)
                }
                alert.present(subAlert, animated: false, completion: nil)
                self.sharePanelFromAlert = subSharePanel

                self.callJSService(DocsJSCallBack(callback), params: ["id": "rightBtn"])
                SheetTracker.report(event: .smartScreenCaptureClick(action: 1), docsInfo: self.docsInfo)
            }
            
            self.alertView = alertView
            
            let navVC = SKNavigationController(rootViewController: alert)
            navVC.modalPresentationStyle = .overFullScreen
            navigator?.presentViewController(navVC, animated: false, completion: nil)
            self.loadImageType = .alert
            snapshotAlertController = alert
            SheetTracker.report(event: .smartScreencapture, docsInfo: self.docsInfo)
        }
    }
}


// MARK: SheetSharePanelDelegate
extension SheetShareManager: SheetSharePanelDelegate {
    func sharePanel(_ sharePanel: SheetSharePanel, didClickType type: ShareAssistType) {
        if shareActionManager?.checkShareAdminAuthority(type: type, showTips: true) == false {
            DocsLogger.warning("share to \(type) has no Admin Authority")
            return
        }
        if let isAvaliable = self.shareActionManager?.isAvailable(type: type), !isAvaliable {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Share_AppNotInstalled, on: sharePanel.window ?? UIView())
            return
        }
        
        // 权限管控
        let currentView = navigator?.currentBrowserVC?.view.window ?? UIView()
        if type == .saveImage || type == .more {
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                let response = DocPermissionHelper.validate(objToken: docsInfo.token,
                                                            objType: docsInfo.inherentType,
                                                            operation: .export)
                response.didTriggerOperation(controller: navigator?.currentBrowserVC ?? UIViewController())
                guard response.allow else { return }
            } else {
                guard DocPermissionHelper.checkPermission(.ccmExport,
                                                          docsInfo: docsInfo,
                                                          showTips: true,
                                                          securityAuditTips: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, hostView: currentView) else {
                    return
                }
            }
        }
        
        if type == .copyAllTexts {
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                let response = DocPermissionHelper.validate(objToken: docsInfo.token, objType: docsInfo.inherentType, operation: .copyContent)
                response.didTriggerOperation(controller: navigator?.currentBrowserVC ?? UIViewController())
                guard response.allow else { return }
            } else {
                if !DocPermissionHelper.checkPermission(.ccmCopy,
                                                        docsInfo: docsInfo,
                                                        showTips: true,
                                                        securityAuditTips: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, hostView: currentView) {
                    DocsLogger.info("check Permission false, return")
                    return
                }
            }
        }

        if shareType == .image, CacheService.isDiskCryptoEnable() {
            //KACrypto
            DocsLogger.error("[KACrypto] 开启KA加密不能一键生图")
            let errMsg = type == .saveImage ? BundleI18n.SKResource.CreationMobile_ECM_SecuritySettingKAToast : BundleI18n.SKResource.CreationMobile_ECM_ShareSecuritySettingKAToast
            UDToast.showFailure(with: errMsg,
                                on: currentView)
            return
        }

        let opItem = convertOpItem(from: type)

        // 通过管控之后，有 texts 和 image 两条线，每条线都有可能点击 more 按钮，要分别处理
        if shareType == .text {
            callJSService(DocsJSCallBack(sheetOperationCallback), params: ["id": "text"]) // 埋点点击按钮
            switch type {
            case .copyAllTexts:
                makeTrack(isCard: true, action: "click_copy_card_text", opItem: opItem)
                saveTextAndToast()
                makeTrack(isCard: true, action: "copy_card_text_success", opItem: opItem)
                return
            default:
                makeTrack(isCard: true, action: "click_share_card_text", opItem: opItem)
                sharePanel.isUserInteractionEnabled = false
                prevOperatedSharePanel = sharePanel
                if type == .feishu {
                    shareTextToLark { [weak self] in
                        sharePanel.isUserInteractionEnabled = true
                        self?.makeTrack(isCard: true, action: "share_card_text_success", opItem: opItem)
                    }
                } else {
                    shareTextToOtherApp(type) { [weak self] in
                        sharePanel.isUserInteractionEnabled = true
                        self?.makeTrack(isCard: true, action: "share_card_text_success", opItem: opItem)
                    }
                }
                return
            }
        } else {
            // 先埋点击事件
            trackIfInCard {
                // 卡片分享的场景，根据 saveImage 区分 action
                if type != .saveImage {
                    makeTrack(isCard: true, action: "click_share_card_img", opItem: opItem)
                } else {
                    makeTrack(isCard: true, action: "click_download_card_img", opItem: opItem)
                }
            } else: {
                // 一键生图的场景，不关心是否为 saveImage，统统用 click_share_export_image
                makeTrack(isCard: false, action: "click_share_export_image", opItem: opItem)
            }

            reportDocumentActivity()

            sharePanel.isUserInteractionEnabled = false
            prevOperatedSharePanel = sharePanel

            guard let imageURL = storeImagePath else {
                showLoadingTip(type: type)
                callJSService(DocsJSCallBack(sheetOperationCallback), params: ["id": "load"])
                prevShareAssistType = type
                return
            }

            handleImageCore(imageURL, type) {
                sharePanel.isUserInteractionEnabled = true
            }

            if sharePanel == sharePanelFromAlert {
                DocsLogger.info("sheetShareManager alert 分享面板点击by alert")
            } else {
                DocsLogger.info("sheetShareManager 预览分享面板点击")
            }
        }
    }
    
    func checkDownloadPermission() -> Bool {
        //导出图片判断使用文档权限
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return DocPermissionHelper.validate(objToken: docsInfo.token,
                                                objType: docsInfo.inherentType,
                                                operation: .export).allow
        } else {
            return DocPermissionHelper.checkPermission(.ccmExport,
                                                       docsInfo: docsInfo,
                                                       showTips: false)
        }
    }

    private func reportDocumentActivity() {
        if let userID = User.current.basicInfo?.userID,
           let reporter = DocsContainer.shared.resolve(DocumentActivityReporter.self) {
            let activity = DocumentActivity(objToken: docsInfo.objToken, objType: docsInfo.type, operatorID: userID,
                                            scene: .download, operationType: .download)
            reporter.report(activity: activity)
        } else {
            spaceAssertionFailure()
        }
    }
}

// 点击 more 后弹出系统面板
extension SheetShareManager {
    func showMoreViewController(_ activityItems: [Any]) {
        let systemActivityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

        // 注册分享回调
        let completionHandler: UIActivityViewController.CompletionWithItemsHandler = { _, _, _, error in
            if error != nil {
                DocsLogger.error("分享长图失败")
            }
        }

        systemActivityController.completionWithItemsHandler = completionHandler

        if SKDisplay.pad,
           let prevOperatedSharePanel = prevOperatedSharePanel {
            systemActivityController.modalPresentationStyle = .popover
            systemActivityController.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            systemActivityController.popoverPresentationController?.permittedArrowDirections = .any
            systemActivityController.popoverPresentationController?.sourceView = prevOperatedSharePanel
            let sourceRect = prevOperatedSharePanel.bounds
            systemActivityController.popoverPresentationController?.sourceRect = CGRect(x: sourceRect.size.width / 2, y: 0, width: 1, height: 1)
        }
        if loadImageType == .alert {
            snapshotAlertController?.presentedViewController?.present(systemActivityController, animated: true, completion: nil)
        } else {
            DocsLogger.info("sheetShareManager 调用系统分享面板")
            self.delegate?.presentViewController(systemActivityController, animated: true)
        }
    }
    
    
    func forcePortraint(force: Bool) {
        guard let vc = self.registeredVC else {
            DocsLogger.error("can not find browser vc")
            return
        }
        if force {
            vc.orientationDirector?.dynamicOrientationMask = .portrait
            DocsLogger.info("sheetShareManager force Portraint")
        } else {
            vc.orientationDirector?.dynamicOrientationMask = nil
            DocsLogger.info("sheetShareManager cancel force Portraint")
        }
        if #available(iOS 16.0, *) {
            vc.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}
