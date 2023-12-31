//
// Created by duanxiaochen.7 on 2021/3/11.
// Affiliated with SKBitable.
//
// Description:

import UIKit
import HandyJSON
import SKCommon
import SKBrowser
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignColor

final class BTPanelService: BaseJSService {

    var panelInfo: BTPanelItemActionParams?

    // 记录 popover 模式下指向的位置
    var sourceRect: CGRect?

    // 是否前端刚刚传空让我们 dismiss？如果是的话，所有在 transition 期间的前端请求，都会被延后到 dismiss completion block 里处理
    var isDismissing: Bool = false

    private var _hasCopyPermission = true // 允许被复制、截图
    private var hasCopyPermissionDeprecated: Bool { // 即将废弃删除，请不要再使用
        get {
            return _hasCopyPermission
        }
        set {
            _hasCopyPermission = newValue
        }
    }
    
    private weak var panelVC: BTPanelController?
    
    /// 绑定 sourceViewID 和 sourceView 的关系，其中 sourceID 会传给前端，前端会再传回
    private static var sourceViewMap: [String: Weak<UIView>] = [:]

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        if !UserScopeNoChangeFG.YY.bitableReferPermission {
            model.permissionConfig.hostPermissionEventNotifier.addObserver(self)
        }
    }
}

extension BTPanelService: BrowserViewLifeCycleEvent {
    func browserWillTransition(from: CGSize, to: CGSize) {
        if let presentedVC = registeredVC?.presentedViewController as? BTPanelController,
           presentedVC.modalPresentationStyle == .popover {
            presentedVC.view.isHidden = true
            panelControllerDidTapDismissZone(presentedVC)
        }
    }
}

extension BTPanelService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.bitablePanel, .commonList]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.bitablePanel.rawValue, DocsJSService.commonList.rawValue:
            showPanel(params)
        default:
            DocsLogger.btInfo("不支持的事件类型 \(serviceName)(\(params))")
        }
    }
}

extension BTPanelService {
    var shouldPopoverDisplay: Bool {
        return SKDisplay.pad && (ui?.hostView.isMyWindowRegularSize() ?? false)
    }

    func showPanel(_ param: [String: Any]) {
        guard let panelParams = BTPanelItemActionParams.deserialize(from: param) else {
            DocsLogger.btError("BTPanelItemActionParams 解析失败 \(param)")
            return
        }
        panelInfo = panelParams
        guard !isDismissing else {
            DocsLogger.btInfo("当前正在 dismiss 旧 panel，等 dismiss 完成之后会自动根据保留的 panelInfo 弹出新面板")
            return
        }
        let permissionObj = BasePermissionObj.parse(param)
        let baseToken = param["baseId"] as? String ?? ""
        let baseContext = BaseContextImpl(baseToken: baseToken, service: self, permissionObj: permissionObj, from: "showPanel")
        guard !panelParams.verifyEmpty else {
            DocsLogger.btInfo("前端 showPanel 传空，要 dismiss")
            if let panelVC = getTopPanelVC(param: panelParams) {
                if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, panelParams.independent == true {
                    DocsLogger.info("forceClose, just close panel")
                    if let nav = panelVC.navigationController {
                        isDismissing = true
                        nav.dismiss(animated: true) { [weak self] in
                            guard let self = self else { return }
                            self.isDismissing = false
                        }
                    } else {
                        isDismissing = true
                        panelVC.dismiss(animated: true) { [weak self] in
                            guard let self = self else { return }
                            self.isDismissing = false
                        }
                    }
                    return
                }
                DocsLogger.btInfo("dismiss befor present")
                isDismissing = true
                panelVC.hasNoticedDismissal = true
                registeredVC?.dismiss(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    if let panelInfo = self.panelInfo, !panelInfo.data.isEmpty {
                        self.presentPanelVC(panelParams: panelInfo, baseContext: baseContext)
                    }
                    self.isDismissing = false
                })
            }
            return
        }
        // 如果当前已经有 PanelController 被弹出，则判断是否要刷新或重新显示
        var panelVC = UIViewController.docs.topMost(of: registeredVC) as? BTPanelController
        if UserScopeNoChangeFG.ZJ.btCardReform {
            panelVC = getTopPanelVC(param: panelParams)
        }

        var isBeingDismissed = panelVC?.isBeingDismissed ?? false
        if UserScopeNoChangeFG.LYL.disablePanelCheckBeingDismissed {
            isBeingDismissed = false
        }

        if let panelVC = panelVC, !isBeingDismissed {
            // 判断是否为 popover 格式，且前端传了 source 过来
            if panelVC.modalPresentationStyle == .popover, // 当前正在显示的 panelVC 以 popover 方式显示
                let currentSourceView = panelVC.popoverPresentationController?.sourceView, // 当前存在正在被指向的 sourceView
                let targetSourceView = BTPanelService.getSourceView(panelParams.location?.sourceViewID) // 找到绑定的 sourceView
            {
                DocsLogger.btInfo("update panel with same source view")
                if currentSourceView == targetSourceView {
                    // 新的 sourceView 和当前正在显示的是同一个，直接 reload
                    panelVC.reload(params: panelParams)
                } else {
                    // 新的 sourceView 和当前正在显示的不是同一个，dismiss 当前的，重新显示新的
                    isDismissing = true
                    registeredVC?.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.isDismissing = false
                        self.presentPanelVC(panelParams: panelParams, baseContext: baseContext)
                    }
                }
            } else if panelVC.modalPresentationStyle == .popover, let sourceRect = sourceRect, let location = panelParams.location {
                let curSourceRect = CGRect(x: location.x, y: location.y - 4, width: location.width, height: location.height + 8)
                // 判断是否需要重新显示 popover
                if sourceRect.equalTo(curSourceRect) {
                    panelVC.reload(params: panelParams)
                } else {
                    if let hostView = ui?.hostView, ((curSourceRect.minY + curSourceRect.height) > hostView.frame.height || curSourceRect.minY + curSourceRect.height < 0) {
                        // 显示超过边界直接隐藏
                        isDismissing = true
                        registeredVC?.dismiss(animated: true) { [weak self] in
                            guard let self = self else { return }
                            self.isDismissing = false
                        }
                        
                    } else {
                        self.sourceRect = curSourceRect
                        isDismissing = true
                        registeredVC?.dismiss(animated: true) { [weak self] in
                            guard let self = self else { return }
                            self.isDismissing = false
                            self.presentPanelVC(panelParams: panelParams, baseContext: baseContext)
                        }
                    }
                }
            } else { // 其他情况直接刷新就行
                panelVC.reload(params: panelParams)
            }
        } else {
            if shouldDismissBeforePresent(panelParams: panelParams) {
                // 如果已经有其他业务的 presentedVC，先 dismiss
                DocsLogger.btInfo("dismiss before present")
                isDismissing = true
                registeredVC?.dismiss(animated: true) { [weak self] in
                    self?.isDismissing = false
                    self?.presentPanelVC(panelParams: panelParams, baseContext: baseContext)
                }
            } else { // 现在干净的很，直接 present 就好啦
                DocsLogger.btInfo("present directly")
                presentPanelVC(panelParams: panelParams, baseContext: baseContext)
            }
        }
    }
    
    private func shouldDismissBeforePresent(panelParams: BTPanelItemActionParams) -> Bool {
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, panelParams.independent == true {
            DocsLogger.info("force open, just show")
            return false
        }
        if SKDisplay.pad,
           let targetSourceView = BTPanelService.getSourceView(panelParams.location?.sourceViewID) {
            // iPad 上 有 sourceViewID 的情况下，直接弹出新窗口
            return false
        } else if registeredVC?.presentedViewController != nil {
            // 如果已经有其他业务的 presentedVC，先 dismiss
            return true
        } else { // 现在干净的很，直接 present 就好啦
            return false
        }
    }
    
    private func getTopPanelVC(param: BTPanelItemActionParams) -> BTPanelController? {
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, param.independent == true, let vc = panelVC, vc.presentingViewController != nil {
            DocsLogger.info("force close, return showing panelvc")
            return vc
        }
        if let nav = registeredVC?.presentedViewController as? SKNavigationController,
           let panelVC = nav.children.last as? BTPanelController {
            // registeredVC -> presented BTPanelController
            return panelVC
        } else if SKDisplay.pad,
                  let panelVC = UIViewController.docs.topMost(of: registeredVC) as? BTPanelController,
                  panelVC.modalPresentationStyle == .popover, // 当前正在显示的 panelVC 以 popover 方式显示
                  let sourceView = panelVC.popoverPresentationController?.sourceView, // 当前存在正在被指向的 sourceView
                  sourceView.window != nil {
            // registeredVC -> presented A -> presented BTPanelController
            // 适用场景：在 iPad 上，从 视图目录 中点击更多打开 popover 面板
            DocsLogger.btInfo("topvc multi presented")
            return panelVC
        }
        return nil
    }

    func presentPanelVC(panelParams: BTPanelItemActionParams, baseContext: BaseContext) {
        guard let hostVC = registeredVC else {
            DocsLogger.btInfo("no window for present")
            return
        }
        let newPanelVC = BTPanelController(params: panelParams, delegate: self, hostVC: hostVC, hostDocsInfo: hostDocsInfo, baseContext: baseContext)
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, panelParams.modalPresentationStyle == "formSheet" {
            DocsLogger.info("showpanel formSheet")
            newPanelVC.modalPresentationStyle = .formSheet
            if !UserScopeNoChangeFG.ZJ.btShowPanelIPadFixDisable {
                newPanelVC.presentationController?.delegate = newPanelVC.btAdaptivePresentationDelegate
            }
            newPanelVC.dismissalStrategy = [SKPanelDismissalStrategy.viewSizeChanged, SKPanelDismissalStrategy.larkSizeClassChanged, SKPanelDismissalStrategy.systemSizeClassChanged]
            presentVC(vc: newPanelVC)
        } else if shouldPopoverDisplay,
           let containerView = ui?.editorView,
           let location = panelParams.location {
            if let targetSourceView = BTPanelService.getSourceView(location.sourceViewID) {
                DocsLogger.btInfo("setupPopover with source view")
                setupPopover(to: newPanelVC, containerView: containerView, sourceView: targetSourceView)
            } else {
                DocsLogger.btInfo("setupPopover with source rect")
                let curSourceRect = CGRect(x: location.x, y: location.y - 4, width: location.width, height: location.height + 8)
                setupPopover(to: newPanelVC, containerView: containerView, sourceRect: curSourceRect)
                self.sourceRect = curSourceRect
            }
            if !UserScopeNoChangeFG.ZJ.btShowPanelIPadFixDisable {
                newPanelVC.presentationController?.delegate = newPanelVC.btAdaptivePresentationDelegate
            }
            newPanelVC.dismissalStrategy = [SKPanelDismissalStrategy.viewSizeChanged, SKPanelDismissalStrategy.larkSizeClassChanged, SKPanelDismissalStrategy.systemSizeClassChanged]
            presentVC(vc: newPanelVC)
        } else {
            newPanelVC.updateLayoutWhenSizeClassChanged = false
            newPanelVC.dismissalStrategy = []
            let nav = SKNavigationController(rootViewController: newPanelVC)
            nav.modalPresentationStyle = .overCurrentContext
            nav.update(style: .clear)
            nav.transitioningDelegate = newPanelVC.panelTransitioningDelegate
            presentVC(vc: nav)
        }
        self.panelVC = newPanelVC
        func presentVC(vc: UIViewController) {
            let allow = UserScopeNoChangeFG.YY.bitableReferPermission ? baseContext.hasCapturePermission : self.hasCopyPermissionDeprecated
            if let presentedViewController = registeredVC?.presentedViewController {
                DocsLogger.btInfo("present after presented vc")
                presentedViewController.present(vc, animated: true, completion: { [weak self] in
                    if !UserScopeNoChangeFG.YY.bitableReferPermission {
                        self?.panelVC?.setCaptureAllowed(allow)
                    }
                })
            } else {
                registeredVC?.present(vc, animated: true, completion: { [weak self] in
                    if !UserScopeNoChangeFG.YY.bitableReferPermission {
                        self?.panelVC?.setCaptureAllowed(allow)
                    }
                })
            }
        }
    }

    func setupPopover(to viewController: BTPanelController, containerView: UIView, sourceRect: CGRect) {
        // 由于是指向WebView中的元素，没有具体的sourceView，使用一个替代的View覆盖在其上面
        let tempTargetView = UIView(frame: sourceRect)
        tempTargetView.backgroundColor = .clear
        containerView.addSubview(tempTargetView)
        tempTargetView.snp.makeConstraints { (make) in
            make.left.equalTo(containerView.safeAreaLayoutGuide.snp.left).offset(sourceRect.minX)
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top).offset(sourceRect.minY)
            make.height.equalTo(sourceRect.height)
            make.width.equalTo(sourceRect.width)
        }
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.backgroundColor = UDColor.bgFloatBase.withAlphaComponent(0.9)
        viewController.popoverPresentationController?.sourceView = tempTargetView
        viewController.popoverPresentationController?.sourceRect = tempTargetView.bounds
        viewController.popoverPresentationController?.sourceView = containerView
        viewController.popoverPresentationController?.sourceRect = sourceRect
        viewController.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        viewController.popoverDisappearBlock = {
            tempTargetView.removeFromSuperview()
        }
    }
    
    func setupPopover(to viewController: BTPanelController, containerView: UIView, sourceView: UIView) {
        viewController.setupPopover(sourceView: sourceView, direction: [.up, .down])
        viewController.popoverPresentationController?.backgroundColor = UDColor.bgFloatBase.withAlphaComponent(0.9)
    }
}

protocol BTPanelDelegate: AnyObject {
    var browserBounds: CGRect { get }
    var isInVideoConference: Bool { get }
    func panelController(_ panelController: BTPanelController, didSelectItemId itemId: String, extra: String?)
    func panelControllerDidTapDismissZone(_ panelController: BTPanelController)
}

extension BTPanelService: BTPanelDelegate {

    var browserBounds: CGRect {
        guard let bvc = registeredVC as? BrowserViewController else { return .zero }
        return bvc.view.bounds
    }

    func panelController(_ panelController: BTPanelController, didSelectItemId itemId: String, extra: String?) {
        guard let callback = panelController.callback else {
            DocsLogger.btError("BTPanelService callback is nil")
            return
        }
        var param: [String: Any] = [
            "id": itemId
        ]
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, let extra = extra {
            param["extra"] = extra
        }
        model?.jsEngine.callFunction(callback, params: param, completion: nil)
    }

    func panelControllerDidTapDismissZone(_ panelController: BTPanelController) {
        guard let callback = panelController.callback else {
            DocsLogger.btError("BTPanelService callback is nil")
            return
        }
        panelController.hasNoticedDismissal = true
        let param: [String: Any] = ["id": "exit"]
        model?.jsEngine.callFunction(callback, params: param, completion: nil)
    }
}

extension BTPanelService: DocsPermissionEventObserver {
    
    func onCopyPermissionUpdated(canCopy: Bool) {
        if UserScopeNoChangeFG.YY.bitableReferPermission {
            return
        }
        hasCopyPermissionDeprecated = canCopy
        DocsLogger.btInfo("BTPanelService set `isCaptureAllowed` -> \(canCopy)")
        panelVC?.setCaptureAllowed(canCopy)
    }
}

extension BTPanelService {
    
    /// weak 绑定 native source view
    /// - Parameter view: target view
    /// - Returns: viewSourceID
    public static func weakBindSourceView(view: UIView) -> String {
        if let keyValue = sourceViewMap.first { (_ key: String, value: Weak<UIView>) in
            return value.value == view
        } {
            return keyValue.key
        }
        let sourceViewID = UUID().uuidString
        sourceViewMap[sourceViewID] = Weak(view)
        return sourceViewID
    }
    
    public static func getSourceView(_ sourceViewID: String?) -> UIView? {
        guard let sourceViewID = sourceViewID, !sourceViewID.isEmpty else {
            return nil
        }
        guard let sourceView = BTPanelService.sourceViewMap[sourceViewID]?.value else {
            return nil
        }
        // 判断正在窗口上显示
        guard sourceView.window != nil else {
            return nil
        }
        return sourceView
    }
}

extension BTPanelService: BaseContextService {
    
}
