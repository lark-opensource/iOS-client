//
//  SKAssetBrowserViewController.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/17.
//  

import Foundation
import LarkUIKit
import LarkAssetsBrowser
import SKFoundation
import SKUIKit
import LarkEMM
import LarkContainer

public enum AssetBrowserUseModuleType {
    case normalImg
    case commentImg
    case none
}

open class SKAssetBrowserViewController: LKAssetBrowserViewController, HierarchyIndependentController {

    public var useModule: AssetBrowserUseModuleType = .none
    
    public var businessIdentifier: String = "SpaceAssetBrowser"
    public var representEnable: Bool = true
    public var hierarchyPriority: HierarchyIndependentPriority = .docImage
    /// loadview 中的初始size
    public var viewInitialSize: CGSize?
    public var photoImageDatas = [PhotoImageData]()
    private let actionHandler: SKAssetBrowserActionHandler
    public var onViewDidAppear: (() -> Void)?
    /// 获取防截图埋点参数的block,  (fileId, fileType)
    public var capturePreventerAnalyticsFileInfoBlock: (() -> (String?, String?))?
    /// 支持横屏展示评论
    var supportCommentWhenLandscape: Bool = false
    public var jsCallback: String? {
        didSet {
            DocsLogger.info("update assrtvc callback:\(jsCallback ?? "")")
        }
    }
    
    public var willDismissCallback: (() -> Void)?
    
    @Provider private var screenProtectionService: ScreenProtectionService
    private lazy var screenProtectionObserver: ScreenProtectionObserver = {
        let obj = ScreenProtectionObserver(identifier: "\(ObjectIdentifier(self))")
        obj.onChange = { [weak self] in
            self?.updatePreventStatus()
        }
        return obj
    }()
    
    public var currentPhotoData: PhotoImageData? {
        photoImageDatas.safe(index: currentPageIndex)
    }
    
    public func currentPhotoUdid() -> PhotoUUID? {
        guard photoImageDatas.count > currentPageIndex, let uuid = photoImageDatas[currentPageIndex].uuid else {
            skError("没有找到这张图片的udid")
            return nil
        }
        return uuid
    }
    
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [.superView, .windowOrVC, .thisView]
        preventer.setAnalyticsFileInfoGetter(block: { [weak self] () -> (String?, String?) in
            let params = self?.capturePreventerAnalyticsFileInfoBlock?()
            return params ?? (nil, nil)
        })
        return preventer
    }()
    
    required public init(assets: [LKDisplayAsset],
                         pageIndex: Int,
                         actionHandler: SKAssetBrowserActionHandler = SKAssetBrowserActionHandler()) {
        self.actionHandler = actionHandler
        super.init(assets: assets, pageIndex: pageIndex, actionHandler: actionHandler)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadView() {
        let initialSize: CGSize
        if let size = viewInitialSize {
            initialSize = size
        } else {
            initialSize = SKDisplay.windowBounds(self.view).size
            DocsLogger.info("SKAssetBrowserVC loadView use screen size: \(initialSize)")
        }
        viewCapturePreventer.contentView.frame = .init(origin: .zero, size: initialSize)
        view = viewCapturePreventer.contentView
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        DocsLogger.info("SKAssetBrowserVC loadView:\(String(describing: view))")
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !self.isBeingExchanging {
            screenProtectionService.unRegister(screenProtectionObserver)
        }
        if self.presentingViewController == nil, !self.isBeingExchanging {
            self.actionHandler.willExit(assetVC: self)
        } else {
            DocsLogger.info("vc is being exchanging", component: LogComponents.commentPic)
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        screenProtectionService.register(screenProtectionObserver)
        onViewDidAppear?()
    }

    override open func currentPageIndexWillChange(_ newValue: Int) {
        super.currentPageIndexWillChange(newValue)

        actionHandler.willSwipeTo(newValue)
    }
    
    private func updatePreventStatus() {
        _updateStatus(ccmAllow: viewCapturePreventer.isCaptureAllowed)
    }
    
    deinit {
        DocsLogger.info("deinit", component: LogComponents.commentPic)
    }

    private func _updateStatus(ccmAllow: Bool) {
        let larkAllow = !(screenProtectionService.isSecureProtection) // 主端开关
        if larkAllow {
            viewCapturePreventer.isCaptureAllowed = ccmAllow
            DocsLogger.info("SKAssetBrowserVC set CaptureAllowed: \(ccmAllow)")
        } else {
            viewCapturePreventer.isCaptureAllowed = false
            DocsLogger.info("SKAssetBrowserVC set CaptureAllowed: false")
        }
    }
    
    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        let enabled = !UserScopeNoChangeFG.LJW.docFix
        if !enabled {
            willDismissCallback?()
        }
        super.dismiss(animated: flag, completion: completion)
        if enabled,
           self.isBeingDismissed || self.isMovingFromParent {
            //只有当控制器本身真正在移除时才执行callback
            willDismissCallback?()
        }
        DocsLogger.info("SKAssetBrowserVC dismiss", component: LogComponents.commentPic)
    }
}

extension SKAssetBrowserViewController {
    
    public func setAllowCapture(_ allow: Bool) {
        _updateStatus(ccmAllow: allow)
    }
}

extension SKAssetBrowserViewController {
    // 为了避免 identifier 重名而创建个单独的类
    private class ScreenProtectionObserver: ScreenProtectionChangeAction {
        
        var onChange: (() -> Void)?
        
        let identifier: String
        
        init(identifier: String) {
            self.identifier = identifier
        }
        
        func onScreenProtectionChange() {
            onChange?()
        }
    }
}
