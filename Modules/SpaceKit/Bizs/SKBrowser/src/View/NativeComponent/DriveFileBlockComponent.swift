//
//  DriveFileBlockParams.swift
//  SKBrowser
//
//  Created by bupozhuang on 2021/9/15.
//
// swiftlint:disable file_length

import SKFoundation
import WebKit
import SKUIKit
import SKCommon
import LarkWebviewNativeComponent
import LarkUIKit
import UniverseDesignColor
import EENavigator
import ECOProbe
import LarkOpenAPIModel
import UniverseDesignProgressView
import SpaceInterface
import SKInfra
import LarkContainer

enum DriveFileBlockMethod: String {
    case onCreateView = "onCreateView"
    case moveOut = "performMoveOut"
    case preload = "performPreload"
    case render = "performRender"
    case progress = "progressUpdate"
}

struct DriveFileBlockIdentifier {
    let isInVCFollow: Bool
    let mountPoint: String
    let mountNodePoint: String
    let fileToken: String
    let componentId: String
    
    init(componentId: String, params: DriveFileBlockParams? = nil) {
        isInVCFollow = params?.isInVCFollow ?? false
        mountPoint = params?.mountPoint ?? ""
        mountNodePoint = params?.mountNodePoint ?? ""
        fileToken = params?.fileID ?? ""
        self.componentId = componentId
    }
    
    init(fileToken: String, mountNodePoint: String, mountPoint: String, isInVCFollow: Bool) {
        self.fileToken = fileToken
        self.mountNodePoint = mountNodePoint
        self.mountPoint = mountPoint
        self.isInVCFollow = isInVCFollow
        self.componentId = ""
    }
    
    /// 唯一标识，用作日志打点（同层组件id + 文档挂载位置token + 文件token）
    var uniqueId: String {
        return componentId + "_" + mountPoint + DocsTracker.encrypt(id: mountNodePoint) + "_" + DocsTracker.encrypt(id: fileToken)
    }
    
    var id: String {
        if isInVCFollow {
            // 在 VCFollow 下，前端是无法知道同层框架的 ComponentId，导致打开附件时无法找到对应的 VC，这里提供不一样的标记(无 componentId 进行拼接)
            return mountPoint + DocsTracker.encrypt(id: mountNodePoint) + "_" + DocsTracker.encrypt(id: fileToken)
        } else {
            return uniqueId
        }
    }
}
//  swiftlint:disable type_body_length
class DriveFileBlockComponent: OpenNativeBaseComponent {
    weak var previewVC: DriveFileBlockVCProtocol?
    private weak var browserVC: BrowserViewController?
    private var insertParamsObject: DriveFileBlockParams?
    private lazy var vcManager: DKPreviewVCManagerProtocol = DocsContainer.shared.resolve(DKPreviewVCManagerProtocol.self)!
    private let view: DriveFileBlockView
    var identifier: DriveFileBlockIdentifier {
        guard let params = insertParamsObject else {
            DocsLogger.info("DriveFileBlockComponent -- component not created componentID \(componentID)")
            return DriveFileBlockIdentifier(componentId: componentID)
        }
        return DriveFileBlockIdentifier(componentId: componentID, params: params)
    }
    
    private lazy var loadingView: DriveFileBlockLoadingProtocol = {
        return DocsContainer.shared.resolve(DriveFileBlockLoadingProtocol.self)!
    }()
    
    private(set) lazy var progressLoadingView: UDProgressView = {
        let progressViewLayoutConfig = UDProgressViewLayoutConfig(
                                           valueLabelWidth: 40,
                                           valueLabelHeight: 20,
                                           circleProgressWidth: 20,
                                           circleProgressLineWidth: 4,
                                           circularHorizontalMargin: 4,
                                           circularverticalMargin: 2)
        let config = UDProgressViewUIConfig(type: .circular, barMetrics: .default)
        let view = UDProgressView(config: config, layoutConfig: progressViewLayoutConfig)
        return view
    }()
    
    override init() {
        view = DriveFileBlockView()
        super.init()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.layer.cornerRadius = 6.0
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UDColor.lineBorderCard.cgColor
        // 兼容逻辑： 在render或者oncreate可能出现view还没有被插入到webview层级的情况，
        // 需要在didAddToSuperView重新挂载预览VC
        view.didAddToSuperView = { [weak self] in
            guard let self = self else { return }
            self.browserVC = self.currentViewController()
            DocsLogger.info("DriveFileBlockComponent -- view did add to supperView \(self.identifier.uniqueId), filetype: \(self.insertParamsObject?.fileType ?? "")")
            guard self.previewVC?.view.superview == nil && self.previewVC != nil else {
                DocsLogger.info("DriveFileBlockComponent -- preivewVC has been setuped \(self.identifier.uniqueId), filetype: \(self.insertParamsObject?.fileType ?? "")")
                return
            }
            spaceAssertionFailure("DriveFileBlockComponent -- 不应该走到这里 \(self.identifier.uniqueId)")
            self.setupChild()
        }
    }
    
    deinit {
        DocsLogger.info("DriveFileBlockComponent -- deinit \(identifier.uniqueId)")
        removePreviewVC()
    }
    
    // 组件标签名字
    public override class func nativeComponentName() -> String {
        return "drive_file_block"
    }
    
    // 组件插入接收
    // params：透传前端标签属性
    // 返回值：view
    public override func insert(params: [AnyHashable: Any]) -> UIView? {
        DocsLogger.info("DriveFileBlockComponent -- insert view with params: \(params.keys), componentID: \(componentID)")
        return view
    }

    // 组件更新
    // nativeView： 插入的视图
    // params：透传前端标签属性
    public override func update(nativeView: UIView?, params: [AnyHashable: Any]) {
        DocsLogger.info("DriveFileBlockComponent -- update with params: \(params.keys), componentID: \(componentID)")
        guard let insertParams = DriveFileBlockParams.createWithParams(params: params, docsInfo: browserVC?.docsInfo) else {
            DocsLogger.info("DriveFileBlockComponent -- invalid params, componentID: \(componentID)")
            return
        }
        self.insertParamsObject = insertParams
    }

    // 组件删除
    public override func delete() {
        DocsLogger.info("DriveFileBlockComponent -- delete \(identifier.uniqueId), filetype: \(insertParamsObject?.fileType ?? "")")
        removePreviewVC()
    }
    
    // 接收JS派发的消息
    // methodName： JS派发到native的事件名字
    // data：透传的数据
    // swiftlint:disable cyclomatic_complexity
    public override func dispatchAction(methodName: String, data: [AnyHashable: Any]) {
        guard let  method = DriveFileBlockMethod(rawValue: methodName) else {
            DocsLogger.info("DriveFileBlockComponent -- dispatchAction unknown action: \(methodName), componentID: \(componentID)")
            return
        }
        let idForLog = identifier.uniqueId
        switch method {
        case .onCreateView:
            guard let insertParams = DriveFileBlockParams.createWithParams(params: data, docsInfo: browserVC?.docsInfo) else {
                spaceAssertionFailure("DriveFileBlockComponent -- invalid params, componentID: \(componentID)")
                return
            }
            self.insertParamsObject = insertParams
            DocsLogger.info("DriveFileBlockComponent -- dispatchAction onCreateView \(idForLog), filetype: \(insertParamsObject?.fileType ?? ""), superview: \(String(describing: view.superview))")
        case .render:
            if !paramsValid(insertParamsObject) {
                insertParamsObject = DriveFileBlockParams.createWithParams(params: data, docsInfo: browserVC?.docsInfo)
                guard paramsValid(insertParamsObject) else { return }
            }
            guard let insertParams = insertParamsObject else {
                spaceAssertionFailure("DriveFileBlockComponent -- invalid params, componentID: \(componentID)")
                return
            }
            DocsLogger.info("DriveFileBlockComponent -- dispatchAction render \(idForLog), filetype: \(insertParams.fileType), superview: \(String(describing: view.superview))")
            // 标记为moveIn避免被回收
            vcManager.component(with: identifier.id, moveInScreen: true)
            if previewVC == nil { // 预览VC被回收，需要重新恢复
                previewVC = vcManager.getPreviewVC(with: identifier.id, params: insertParams)
                setupChild()
            } else if previewVC?.view.superview == nil { // 可能vc正在全屏态
                DocsLogger.info("DriveFileBlockComponent -- dispatchAction render previewVC superview is nil, identifier: \(idForLog)")
                setupChild()
            } else { // 可能vc正在全屏态 or preload已经setup了vc
                addToFollowIfNeed()
                let superView = String(describing: previewVC?.view.superview)
                DocsLogger.info("DriveFileBlockComponent -- dispatchAction render already has vc currentView \(view), superView: \(superView), identifier: \(idForLog)")
            }
        case .preload:
            if !paramsValid(insertParamsObject) {
                insertParamsObject = DriveFileBlockParams.createWithParams(params: data, docsInfo: browserVC?.docsInfo)
            }
            reportPreload(resultCode: NativeComponentTracker.ResultCode.DEC0)
            DocsLogger.info("DriveFileBlockComponent -- dispatchAction preload \(idForLog), filetype: \(insertParamsObject?.fileType ?? ""), superview: \(String(describing: view.superview))")
            if previewVC == nil {
                DocsLogger.info("DriveFileBlockComponent -- dispatchAction preload show loading, fileName: \(insertParamsObject?.fileName ?? "")")
                showLoading(true)
            } else if let vc = previewVC, vc.view.superview == nil {
                let fileName = insertParamsObject?.fileName ?? ""
                DocsLogger.info("DriveFileBlockComponent -- dispatchAction preload vc already exist setup, fileName: \(fileName)")
                // 已经渲染出来，标记为moveIn避免被回收
                vcManager.component(with: identifier.id, moveInScreen: true)
                setupChild()
            } else {
                DocsLogger.info("DriveFileBlockComponent -- dispatchAction preload already has vc \(idForLog)")
            }
        case .progress:
            if !paramsValid(insertParamsObject) {
                insertParamsObject = DriveFileBlockParams.createWithParams(params: data, docsInfo: browserVC?.docsInfo)
            }
            DocsLogger.info("DriveFileBlockComponent -- dispatchAction progress \(idForLog), filetype: \(insertParamsObject?.fileType ?? ""), superview: \(String(describing: view.superview))")
            if previewVC == nil {
                DocsLogger.info("DriveFileBlockComponent -- dispatchAction progress show loading, fileName: \(insertParamsObject?.fileName ?? ""), fileProgress: \(insertParamsObject?.progress)")
                let progressVaule = insertParamsObject?.progress ?? 0.0
                showProgressLoading(true, progressVaule)
            } else if let vc = previewVC, vc.view.superview == nil {
                let fileName = insertParamsObject?.fileName ?? ""
                DocsLogger.info("DriveFileBlockComponent -- dispatchAction progress vc already exist setup, fileName: \(fileName)")
                // 已经渲染出来，标记为moveIn避免被回收
                vcManager.component(with: identifier.id, moveInScreen: true)
                setupChild()
            } else {
                DocsLogger.info("DriveFileBlockComponent -- dispatchAction progress already has vc \(idForLog)")
            }
        case .moveOut:
            DocsLogger.info("DriveFileBlockComponent -- dispatchAction moveOut \(idForLog), filetype: \(insertParamsObject?.fileType ?? ""), superview: \(String(describing: view.superview))")
            vcManager.component(with: identifier.id, moveInScreen: false)
            removeFromFollowContent()
        }
    }
    
    // 当触摸落在返回的view上时, 会禁用WKContentView中的UIWebTouchEventsGestureRecognizer和WKDeferringGestureRecognizer手势
    // 技术文档： https://bytedance.feishu.cn/docx/doxcniikjZUNXuW3bxW0p8PAprd
    public override func respondCustomGestureViews() -> [UIView]? {
        guard let customView = previewVC?.customGestureView else {
            return []
        }
        return [customView]
    }
    
    /// 从同层态 Present 进入全屏页面
    /// - Returns: 是否成功 Prsent 出来
    @discardableResult
    func enterFullModel() -> Bool {
        guard let vc = previewVC else { return false }
        let containerVC = vcManager.makeAnimatedContainer(vc: vc)
        containerVC.childVCFrame = { [weak self] in
            return self?.currentFrame() ?? .zero
        }
        containerVC.resetChildVC = { [weak self] in
            self?.exitFullModeForVCFollow()
            self?.setupChild()
        }

        let nav = LkNavigationController(rootViewController: containerVC)
        nav.transitioningDelegate = containerVC
        containerVC.modalPresentationStyle = .overCurrentContext
        nav.modalPresentationStyle = .overCurrentContext
        
        guard let curVC = currentViewController() else {
            DocsLogger.warning("fileBlock enterFullMode failed no curVC")
            return false
        }
        DocsLogger.info("DriveFileBlockComponent -- fileBlock enterFullMode present fromvc: \(curVC), presentedVC: \(String(describing: curVC.presentedViewController)), id: \(identifier.uniqueId)")
        // presnet 前把当前的 presentedVC dismiss
        if let presentedVC = curVC.presentedViewController {
            presentedVC.dismiss(animated: false)
        }
        curVC.present(nav, animated: true) { [weak self] in
            // Present 动画结束后，再处理在 VCFollow 下弹出的 previewVC
            self?.enterFullModeForVCFollow(browserVC: curVC)
        }
        return true
    }
    
    private func setupChild() {
        guard let vc = previewVC, let curVC = currentViewController() ?? browserVC else {
            DocsLogger.info("DriveFileBlockComponent -- setupChild no previewVC \(identifier.uniqueId), filetype: \(insertParamsObject?.fileType ?? "")")
            return
        }
        guard vc.view.superview != view else {
            DocsLogger.info("DriveFileBlockComponent -- setupChild has already setuped \(identifier.uniqueId)")
            addToFollowIfNeed()
            return
        }
        if nil != vc.parent {
            DocsLogger.info("DriveFileBlockComponent -- parent is \(curVC) identifier: \(identifier.uniqueId)")
            vc.removeFromParent()
            vc.view.removeFromSuperview()
        }
        DocsLogger.info("DriveFileBlockComponent -- setupChild, superview frame: \(String(describing: vc.view.superview?.frame)), identifier: \(identifier.uniqueId)")
        showLoading(false)
        showProgressLoading(false)
        curVC.addChild(vc)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        view.addSubview(vc.view)
        vc.view.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        CATransaction.commit()
        self.view.layoutIfNeeded()
        vc.didChangeMode(.card)
        vc.clickEnterFull = { [weak self] in
            self?.enterFullModel()
        }
        vc.didMove(toParent: curVC)
        vc.fileBlockComponent = self
        vc.fileBlockMountToken = insertParamsObject?.mountNodePoint
        // 设置 VCFollow
        addToFollowIfNeed()
    }
    
    private func updateProgress(_ progress: Float) {
        let pro = max(min(progress / 100, 1.0), 0)
        progressLoadingView.setProgress(CGFloat(pro), animated: true)
    }
    
    private func setupLoading() {
        if loadingView.superview == nil {
            DocsLogger.info("DriveFileBlockComponent -- setup loading identifier: \(identifier.uniqueId)")
            UIView.performWithoutAnimation {
                view.addSubview(loadingView)
                loadingView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
        } else {
            DocsLogger.info("DriveFileBlockComponent -- loading exist identifier: \(identifier.uniqueId)")
        }
    }
    
    private func setupProgressLoading() {
        if progressLoadingView.superview == nil {
            DocsLogger.info("DriveFileBlockComponent -- setup progressLoading identifier: \(identifier.uniqueId)")
            UIView.performWithoutAnimation {
                view.addSubview(progressLoadingView)
                progressLoadingView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
        } else {
            DocsLogger.info("DriveFileBlockComponent -- progressLoading exist identifier: \(identifier.uniqueId)")
        }
    }
    
    private func showLoading(_ show: Bool) {
        if show {
            loadingView.isHidden = false
            progressLoadingView.isHidden = true
            setupLoading()
            loadingView.startAnimate()
        } else {
            loadingView.removeFromSuperview()
        }
    }
    
    private func showProgressLoading(_ show: Bool, _ progress: Float = 0.0) {
        if show {
            loadingView.isHidden = true
            progressLoadingView.isHidden = false
            setupProgressLoading()
            updateProgress(progress)
        } else {
            progressLoadingView.removeFromSuperview()
        }
    }
    
    func currentViewController() -> BrowserViewController? {
        if let vc = findBrowserVCByResponder() {
            return vc
        } else {
            return findBrowserVCTByWebview()
        }
    }
    
    private func findBrowserVCByResponder() -> BrowserViewController? {
        var nextResponder = view.next
        while nextResponder != nil {
            guard let next = nextResponder else {
                DocsLogger.info("DriveFileBlockComponent -- next responder nil \(identifier.uniqueId)")
                return nil
            }
            DocsLogger.info("DriveFileBlockComponent -- next responder : \(next) \(identifier.uniqueId)")
            if next.isKind(of: BrowserViewController.self) {
                DocsLogger.info("DriveFileBlockComponent -- next responder return browser \(identifier.uniqueId)")
                return next as? BrowserViewController
            }
            nextResponder = next.next
        }
        DocsLogger.info("DriveFileBlockComponent -- next responder nil \(identifier.uniqueId)")
        return nil
    }
    
    private func findBrowserVCTByWebview() -> BrowserViewController? {
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        var superView = super.webView?.superview
        while superView != nil {
            if let browser = superView as? BrowserView,
               let vc = ur.docs.editorManager?.currentBrowserVC(browser) as? BrowserViewController {
                DocsLogger.info("DriveFileBlockComponent -- Found BrowserViewController \(identifier.uniqueId)")
                return vc
            } else {
                superView = superView?.superview
            }
        }
        return nil
    }
    
    func currentFrame() -> CGRect {
        guard let curVC = currentViewController() else { return .zero }
        return view.convert(view.bounds, to: curVC.view)
    }
    
    func removePreviewVC() {
        if previewVC?.view.superview == view {
            previewVC?.willMove(toParent: nil)
            previewVC?.removeFromParent()
            previewVC?.view.removeFromSuperview()
            previewVC?.didMove(toParent: nil)
        }
        previewVC = nil
        vcManager.delete(with: identifier.id)
    }
    
    private func paramsValid(_ params: DriveFileBlockParams?) -> Bool {
        guard let p = params else { return false }
        return !p.fileID.isEmpty && !p.appID.isEmpty && !p.mountNodePoint.isEmpty
    }
    
    /// 添加标记为可 VCFollow 的内容（触发setup将FollowAPI传递出去）
    private func addToFollowIfNeed() {
        guard insertParamsObject?.isInVCFollow == true else { return }
        guard let followableVC = previewVC as? FollowableViewController,
              let browserVC = currentViewController() else {
            DocsLogger.warning("AttachFollow: addToFollowIfNeed Fail")
            return
        }
        // 标记为同层Follow
        followableVC.isSameLayerFollow = true
        browserVC.spaceFollowAPIDelegate?.follow(browserVC, add: followableVC)
    }
    
    /// 移除可 VCFollow 的内容
    private func removeFromFollowContent() {
        guard insertParamsObject?.isInVCFollow == true else { return }
        guard let mountToken = insertParamsObject?.mountNodePoint else { return }
        let browserVC = currentViewController()
        browserVC?.spaceFollowAPIDelegate?.follow(browserVC, onOperate: .onRemoveFollowSameLayerFile(mountToken: mountToken))
    }
    
    /// VCFollow 下告知前端进入附件全屏预览
    private func enterFullModeForVCFollow(browserVC: BrowserViewController) {
        guard let params = insertParamsObject, params.isInVCFollow,
              let followableVC = previewVC as? FollowableViewController else { return }
        let attachFileParams: [String: Any] =
            ["bussinessId": "docx",
             "file_name": params.fileName,
             "file_token": params.fileID,
             "mount_node_token": params.mountNodePoint,
             "mount_point": params.mountPoint,
             "file_mime_type": "file"]
        let nativeStatus = SpaceFollowOperation.nativeStatus(funcName: DocsJSCallBack.notifyAttachFileOpen.rawValue,
                                                             params: attachFileParams)
        let followDelegate = browserVC.spaceFollowAPIDelegate
        followDelegate?.follow(browserVC, onOperate: nativeStatus)
        // 标记属于附件 Follow（非同层）
        followableVC.isSameLayerFollow = false
        followDelegate?.currentFollowAttachMountToken = params.mountNodePoint
        followDelegate?.follow(browserVC, add: followableVC)
        followDelegate?.followAttachDidReady()
    }
    
    private func exitFullModeForVCFollow() {
        guard insertParamsObject?.isInVCFollow == true else { return }
        // 告知前端附件退出
        currentViewController()?.spaceFollowAPIDelegate?.follow(nil, onOperate: .onExitAttachFile(isNewAttach: true))
        // 移除当前 Follow 的附件 Token
        currentViewController()?.spaceFollowAPIDelegate?.currentFollowAttachMountToken = nil
    }
    
    private func reportPreload(resultCode: String) {
        NativeComponentTracker.log(type: NativeComponentTracker.RenderViewType.driveFileBlock,
                                   stage: NativeComponentTracker.StageCode.drivePreload,
                                   viewID: self.componentID,
                                   resultCode: resultCode)
    }
}

extension DriveFileBlockComponent: DriveFileBlockComponentProtocol {
    func enterFullMode() -> Bool {
        return enterFullModel()
    }
}

extension DriveFileBlockComponent: OpenNativeComponentObserverble {
    
    static func receivedJSInsertEvent(with componentId: String, params: [AnyHashable: Any], error: Error?) {
        if let error = error as? OpenAPIError {
            NativeComponentTracker.log(type: NativeComponentTracker.RenderViewType.driveFileBlock,
                                       stage: NativeComponentTracker.StageCode.nativeCompoenentHander,
                                       viewID: componentId,
                                       resultCode: "\(error.code)",
                                       errorMessage: error.monitorMsg)
        } else {
            NativeComponentTracker.log(type: NativeComponentTracker.RenderViewType.driveFileBlock,
                                       stage: NativeComponentTracker.StageCode.nativeCompoenentHander,
                                       viewID: componentId,
                                       resultCode: NativeComponentTracker.ResultCode.DEC0)
        }
    }
    
    static func componentAdd(with componentId: String, params: [AnyHashable: Any], error: Error?) {
        if let error = error as? OpenAPIError {
            NativeComponentTracker.log(type: NativeComponentTracker.RenderViewType.driveFileBlock,
                                       stage: NativeComponentTracker.StageCode.nativeComponentViewAdd,
                                       viewID: componentId,
                                       resultCode: "\(error.innerCode)",
                                       errorMessage: error.monitorMsg)
        } else {
            NativeComponentTracker.log(type: NativeComponentTracker.RenderViewType.driveFileBlock,
                                       stage: NativeComponentTracker.StageCode.nativeComponentViewAdd,
                                       viewID: componentId,
                                       resultCode: NativeComponentTracker.ResultCode.DEC0)
        }
    }
    
    static func updateComponentBounds(with componentId: String, params: [AnyHashable: Any], error: Error?) {
        if let error = error as? OpenAPIError {
            NativeComponentTracker.log(type: NativeComponentTracker.RenderViewType.driveFileBlock, stage: NativeComponentTracker.StageCode.nativeComponentViewUpdateFrame,
                                       viewID: componentId,
                                       resultCode: "\(error.innerCode)",
                                       errorMessage: error.monitorMsg)
        } else {
            NativeComponentTracker.log(type: NativeComponentTracker.RenderViewType.driveFileBlock,
                                       stage: NativeComponentTracker.StageCode.nativeComponentViewUpdateFrame,
                                       viewID: componentId,
                                       resultCode: NativeComponentTracker.ResultCode.DEC0)
        }
    }
    
    static func renderViewOnCreate(with componentId: String, params: [AnyHashable: Any], error: Error?) {
        if let error = error as? OpenAPIError {
            NativeComponentTracker.log(type: NativeComponentTracker.RenderViewType.driveFileBlock,
                                       stage: NativeComponentTracker.StageCode.renderViewOnCreate,
                                       viewID: componentId,
                                       resultCode: "\(error.innerCode)",
                                       errorMessage: error.monitorMsg)
        } else {
            NativeComponentTracker.log(type: NativeComponentTracker.RenderViewType.driveFileBlock,
                                       stage: NativeComponentTracker.StageCode.renderViewOnCreate,
                                       viewID: componentId,
                                       resultCode: NativeComponentTracker.ResultCode.DEC0)
        }
    }
}
