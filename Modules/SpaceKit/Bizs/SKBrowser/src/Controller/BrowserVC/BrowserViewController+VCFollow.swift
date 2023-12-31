//
//  BrowserViewController+VCFollow.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/1.
//


import SKFoundation
import SpaceInterface
import SwiftyJSON
import RxSwift
import SKCommon
import SKUIKit
import UIKit

// 新版本FollowAPI
extension BrowserViewController: FollowableViewController {

    public var followTitle: String {
        return self.docsInfo?.title ?? ""
    }

    /// 返回当前Follow的ViewController
    public var followVC: UIViewController {
        return self
    }

    public var canBackToLastPosition: Bool {
        guard let docsInfo = docsInfo else {
            return false
        }
        return docsInfo.isDoc
    }

    public var followScrollView: UIScrollView? {
        return self.editor.scrollViewProxy.getScrollView()
    }

    public func onSetup(followAPIDelegate: SpaceFollowAPIDelegate) {
        self.spaceFollowAPIDelegate = followAPIDelegate
        self.editor.vcFollowDelegate = self
        self.editor.scrollViewProxy.getScrollView()?.bounces = false
        if UIApplication.shared.statusBarOrientation.isLandscape &&
            (docsInfo?.inherentType.landscapeHideNavBarEnteringVCFollow ?? false) &&
            SKDisplay.phone {
            setNavigationBarHidden(true, animated: false)
        }
        self.navigationBar.titleView.shouldShowTexts = false
         /// 如果当前是固定导航栏，那么就重置为 normal
        if let docsInfo = docsInfo {
            enableFullscreenScrolling = FullScreenUtil.isFullScreenScrollingEnable(docsInfo: docsInfo)
        }
        if topContainerState == .fixedShowing {
            topContainerState = .normal
        }
        self.topContainer.setNeedsLayout()
    }

    public func refreshFollow() {
        dismissFollowView()
        // 刷新页面前需要先关闭无权限页面，前端无法关闭该页面
        self.editor.dismissApplyPermissionView()
        self.dismissKeyDeleteHintView()
        self.editor.callFunction(DocsJSCallBack.windowReload, params: nil, completion: nil)
    }

    public func onDestroy() {
        self.editor.vcFollowDelegate = nil
        self.editor.callFunction(DocsJSCallBack.windowClear, params: nil, completion: nil)
        self.topContainerState = .normal
    }

    public func onOperate(_ operation: SpaceFollowOperation) {
        switch operation {
        case .onExitAttachFile(let isNewAttach):
            if isNewAttach {
                var params: [String: Any] = [:]
                if !currentTableId.isEmpty {
                    //在bitable at docx/doc里多个bitable subblock的场景下，需要告诉前端关闭的是哪个subblock相关的附件，所以需要把tableId传给前端
                    params["from_module"] = currentTableId
                }

                self.editor.callFunction(DocsJSCallBack.onAttachFileExit, params: params, completion: nil)
                currentTableId = ""
            } else {
                self.editor.callFunction(DocsJSCallBack.onFileExit, params: [:], completion: nil)
            }
        case .willSetFloatingWindow:
            self.isWindowFloating = true
            self.editor.simulateJSMessage(DocsJSService.commentCloseCards.rawValue, params: ["needCancel": true, "source": CommentSource.windowFloating.rawValue]) //关闭评论
            self.editor.simulateJSMessage(DocsJSService.commentHideInput.rawValue, params: ["needCancel": true])
            hideKeyboardAndNoticeWebIfNeed()
            addTextFieldForRecoverCursorOnIPad14IfNeed()
            (editor as? KeepActiveTimerOwner)?.startKeepActiveTimer()
            self.isWindowFloating = true
            self.editor.lifeCycleEvent.browserDidChangeFloatingWindow(isFloating: true)
        case .finishFullScreenWindow:
            self.isWindowFloating = false
            removeTextFieldForRecoverCursorOnIPad14IfNeed()
            (editor as? KeepActiveTimerOwner)?.stopKeepActiveTimer()
            self.isWindowFloating = false
            self.editor.lifeCycleEvent.browserDidChangeFloatingWindow(isFloating: false)
        default:
            break
        }
    }
 

    public func onRoleChange(_ newRole: FollowRole) {
        self.topContainerState = .normal
        customTCMangager.setCustomTopContainerHidden(false)
        switch newRole {
        case .none:
            let isInLandscape = UIApplication.shared.statusBarOrientation.isLandscape && (docsInfo?.inherentType.landscapeHideNavBarEnteringVCFollow ?? false) && SKDisplay.phone
             // 防止在跟随转为非跟随，导航栏显示过程中误触。case: https://meego.feishu.cn/larksuite/issue/detail/3373588?parentUrl=%2Flarksuite%2FissueView%2FSBg67fTcn
            DispatchQueue.main.async { [weak self] in
                self?.setNavigationBarHidden(isInLandscape, animated: false)
            }
        case .presenter:
            let isInLandscape = UIApplication.shared.statusBarOrientation.isLandscape && (docsInfo?.inherentType.landscapeHideNavBarEnteringVCFollow ?? false) && SKDisplay.phone
            setNavigationBarHidden(isInLandscape, animated: false)
            requestHideKeyboard()
        case .follower:
            becomeFollower()
            setNavigationBarHidden(true, animated: false)
        }
        self.editor.simulateJSMessage(DocsJSService.simulateOnRoleChange.rawValue, params: ["role": newRole])
    }

    //重新跟随
    func becomeFollower() {
        self.topContainerState = .fixedHiding
        customTCMangager.setCustomTopContainerHidden(true)
        requestHideKeyboard()
        hideCatalog()
        self.editor.simulateJSMessage(DocsJSService.feedCloseMessage.rawValue, params: [:]) //关闭通知
        self.editor.simulateJSMessage(DocsJSService.reactionClose.rawValue, params: [:]) //关闭全文评论 reaction。
        self.editor.simulateJSMessage(DocsJSService.commentHideInput.rawValue, params: ["needCancel": true]) //关闭回复框
        self.editor.simulateJSMessage(DocsJSService.commentHideReaction.rawValue, params: ["needCancel": true]) //关闭评论的表情菜单
        self.editor.simulateJSMessage(DocsJSService.simulateCloseCommentImage.rawValue, params: [:]) //关闭评论图片
        self.editor.simulateJSMessage(DocsJSService.simulateHideAIPanel.rawValue, params: [:]) //关闭AI面板图片
    }

    func dismissFollowView(isRefresh: Bool = true) {
        guard self.isInVideoConference else { return }
        self.editor.simulateJSMessage(DocsJSService.simulateCloseCommentImage.rawValue, params: [:]) //关闭评论图片
        if isRefresh {
            self.editor.simulateJSMessage(DocsJSService.commentCloseCards.rawValue, params: ["needCancel": true]) //关闭评论
        }
        self.editor.simulateJSMessage(DocsJSService.closeImageViewer.rawValue, params: [:]) //关闭图片预览
        self.editor.simulateJSMessage(DocsJSService.feedCloseMessage.rawValue, params: [:]) //关闭通知
    }

    func hideCatalog() {
        if SKDisplay.phone {
            // 隐藏 iphone 目录详情。
            self.editor.catalog?.hideCatalogDetails()
        } else {
            // 收起 ipad 目录
            self.editor.simulateJSMessage(DocsJSService.setCatalogVisible.rawValue, params: ["visible": false])
        }
    }

    public func executeJSFromVcfollow(operation: String, params: [String: Any]?) {
        if operation == DocsJSCallBack.notifyAttachFileOpen.rawValue,
           let tableId = params?["table_id"] as? String {
            //bitable记录当前打开附件的tableId，用于回传前端
            currentTableId = tableId
        }
        self.editor.callFunction(DocsJSCallBack(rawValue: operation), params: params, completion: nil)
    }

    public var isEditingStatus: Bool {
        return self.editor.isEditingStatus
    }
}


// MARK: - BrowserVCFollowDelegate
// 将BrowserView中的follow动作转发到followAPIDelegate
extension BrowserViewController: BrowserVCFollowDelegate {

    public var isFloatingWindow: Bool { self.isWindowFloating }
    
    public func follow(onOperate operation: SpaceFollowOperation) {
        DocsLogger.vcfInfo("follow(onOperate: \(operation)")
        spaceFollowAPIDelegate?.follow(nil, onOperate: operation)
    }

    public func followDidReady() {
        DocsLogger.vcfInfo("followDidReady")
        spaceFollowAPIDelegate?.followDidReady(nil)
    }

    public func followDidRenderFinish() {
        DocsLogger.vcfInfo("followDidRenderFinish")
        spaceFollowAPIDelegate?.followDidRenderFinish(nil)
    }

    public func followWillBack() {
        DocsLogger.vcfInfo("followWillBack")
        spaceFollowAPIDelegate?.followDidRenderFinish(nil)
    }

    public func didReceivedJSData(data outData: [String: Any]) {
        DocsLogger.vcfInfo("didReceivedJSData")
        spaceFollowAPIDelegate?.didReceivedJSData(data: outData)
    }
}


// MARK: - Tool
fileprivate extension BrowserViewController {
    func requestHideKeyboard() {
        self.editor.resignFirstResponder()
    }
}


// MARK: cursor fix
extension BrowserViewController {
    
    private static var textFieldForRecoverCursorOnIpad14AssociatedKey = "BrowserViewController.textFieldForRecoverCursorOnIpad14AssociatedKey"
    
    var textFieldForRecoverCursorOnIPad14: UITextField? {
        get {
            return objc_getAssociatedObject(self, &BrowserViewController.textFieldForRecoverCursorOnIpad14AssociatedKey) as? UITextField
        }
        set {
            objc_setAssociatedObject(self, &BrowserViewController.textFieldForRecoverCursorOnIpad14AssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 这个是为了修复 iPad 14 系统上，小窗回来重新编辑不显示光标的问题。需要在小窗时用个隐藏的 textField 来转移第一响应者。
    /// https://meego.feishu.cn/larksuite/issue/detail/4691170
    func addTextFieldForRecoverCursorOnIPad14IfNeed() {
        guard SKDisplay.pad && (UIDevice.current.systemVersion > "13" && UIDevice.current.systemVersion < "15") && isInVideoConference else { return }
        rootTracing.info("enable textFieldForRecoverCursorOnIpad14")
        let textField: UITextField
        if let _textF = textFieldForRecoverCursorOnIPad14 {
            textField = _textF
        } else {
            textField = UITextField()
            textField.backgroundColor = .clear
            textField.frame = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
            textFieldForRecoverCursorOnIPad14 = textField
        }
        self.view.insertSubview(textField, at: 0)
        textFieldForRecoverCursorOnIPad14?.becomeFirstResponder()
    }
    /// 在回复大窗时进行移除
    func removeTextFieldForRecoverCursorOnIPad14IfNeed() {
       textFieldForRecoverCursorOnIPad14?.removeFromSuperview()
    }

}
