//
//  UtilBottomPopupService.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/30.
//

import Foundation
import EENavigator
import SKCommon
import SKUIKit
import SKFoundation

public final class UtilBottomPopupService: BaseJSService {
    var data: BottomPopupModel?
    var highlightRange: NSRange?
    var permStatistics: PermissionStatistics?
    weak var invitePopupMenuVC: UIViewController?
}

extension UtilBottomPopupService: DocsJSServiceHandler {

    public var handleServices: [DocsJSService] {
        return [.showBottomPopup]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []) else { return }
        guard let data = try? JSONDecoder().decode(BottomPopupModel.self, from: jsonData) else { return }
        self.data = data
        self.permStatistics = PermissionStatistics.getReporterWith(docsInfo: model?.browserInfo.docsInfo)
        self.permStatistics?.reportPermissionShareAtPeopleView()
        let config = BottomPopupViewUtil.config4AtPermission(data)
        if SKDisplay.pad,
           let position = self.data?.position,
           let editorView = ui?.editorView,
           let scrollProxy = self.ui?.scrollProxy {
            //使用popover样式
            let y = position.y - Double(scrollProxy.contentOffset.y)
            let rectInSelf = CGRect(x: position.x, y: y - 20, width: 2, height: 40)
            let alertVC = BottomPopupViewUtil.getPopupMenuViewInPoperOverStyle(delegate: self,
                                                                               config: config,
                                                                               permStatistics: self.permStatistics,
                                                                               rectInView: rectInSelf,
                                                                               soureViewHeight: editorView.frame.height)
            alertVC.popoverPresentationController?.delegate = BottomPopupViewUtil.shared
            alertVC.popoverPresentationController?.sourceView = editorView
            invitePopupMenuVC = alertVC
            navigator?.presentViewController(alertVC, animated: true, completion: nil)
        } else {
            let vc = BottomPopupViewController(config: config, permStatistics: permStatistics)
            vc.delegate = self
            navigator?.presentViewController(vc, animated: false, completion: nil)
        }
    }
}

extension UtilBottomPopupService: BottomPopupViewControllerDelegate {
    public func bottomPopupViewControllerOnClick(_ bottomPopupViewController: BottomPopupViewController, at url: URL) -> Bool {
        return handlerUrlClick(showVC: bottomPopupViewController, url: url)
    }

    public func bottomPopupViewControllerDidConfirm(_ bottomPopupViewController: BottomPopupViewController) {
        self.handleConfirmBtnClick(config: bottomPopupViewController.config)
    }

    public func bottomPopupViewControllerClosed(_ bottomPopupViewController: BottomPopupViewController) {
        if let callback = data?.callback {
            model?.jsEngine.callFunction(DocsJSCallBack(callback),
                                         params: ["id": "cancel",
                                                  "needSendLark": bottomPopupViewController.config.sendLark],
                                         completion: nil)
        }
    }
}

extension UtilBottomPopupService: BottomPopupVCMenuDelegate {
    public func menuDidConfirm(_ menu: BottomPopupMenuView) {
        self.invitePopupMenuVC?.dismiss(animated: false, completion: nil)
        self.handleConfirmBtnClick(config: menu.config)
    }
    public func menuOnClick(_ menu: BottomPopupMenuView, at url: URL) -> Bool {
        guard let vc = self.invitePopupMenuVC else { return true }
        return handlerUrlClick(showVC: vc, url: url)
    }
}

extension UtilBottomPopupService {
    private func handleConfirmBtnClick(config: PopupMenuConfig) {
        if let callback = data?.callback {
            if  config.actionSource == .globalComment,
                let uid = config.extraInfo as? String,
                let docInfo = model?.browserInfo.docsInfo {
                let context = InviteUserRequestContext(userId: uid, token: docInfo.token, type: docInfo.type, sendLark: config.sendLark, refreshPermision: false)
                AtPermissionManager.shared.inviteUserRequest(context: context) { suc in
                    self.model?.jsEngine.callFunction(DocsJSCallBack(callback),
                                                 params: ["result": suc],
                                                 completion: nil)
                }
            } else {
                model?.jsEngine.callFunction(DocsJSCallBack(callback),
                                             params: ["id": "confirm",
                                                      "needSendLark": config.sendLark],
                                             completion: nil)
            }
        }
    }

    private func handlerUrlClick(showVC: UIViewController, url: URL) -> Bool {
        if url.scheme == "lark", url.path == "/contact/personcard" {
            if let params = url.docs.fetchQuery(), let chatterId = params["chatterId"] {
                guard let fromVC = self.registeredVC else {
                    spaceAssertionFailure("fromVC cannot be nil")
                    return false
                }
                showVC.dismiss(animated: false) { [weak self] in
                    HostAppBridge.shared.call(ShowUserProfileService(userId: chatterId,
                                                                     fileName: self?.model?.browserInfo.docsInfo?.title,
                                                                     fromVC: fromVC))
                }
                return false
            }
        }
        return true
    }
}
