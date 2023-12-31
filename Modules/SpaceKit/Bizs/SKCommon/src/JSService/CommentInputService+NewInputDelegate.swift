//
//  CommentInputService+NewInputDelegate.swift
//  SKBrowser
//
//  Created by huayufan on 2021/7/8.
//  


import UniverseDesignToast
import SKResource
import SKFoundation
import Foundation
import SpaceInterface
import SKInfra

struct CommentKeyboardInfo: SKKeyboardInfoProtocol {
    public static let key = "simulateKeyboard"
    var height: CGFloat
    var isShow: Bool
    var trigger: String = "comment"
    init(isShow: Bool, height: CGFloat) {
        self.isShow = isShow
        self.height = height
    }
}

extension CommentInputService {
    
    public func keyboardWillShow(height: CGFloat) {
        notifyKeyboardChange(isShow: true, height: height)
        
        let commentTracker = DocsContainer.shared.resolve(CommentTrackerInterface.self)
        commentTracker?.commentReport(action: "begin_edit",
                                     docsInfo: model?.browserInfo.docsInfo,
                                     cardId: showInputModel?.commentID,
                                     id: showInputModel?.replyID,
                                      isFullComment: showInputModel?.isWhole ?? false, extra: [:])
    }
    
    public func keyboardWillHide(height: CGFloat) {
        notifyKeyboardChange(isShow: false, height: height)
    }
    
    private func notifyKeyboardChange(isShow: Bool, height: CGFloat) {
        guard let model = model else {
            return
        }
        DocsLogger.info("notifyKeyboardChange isShow:\(isShow) height:\(height)", component: LogComponents.comment)
        let params: [String: Any] = [CommentKeyboardInfo.key: CommentKeyboardInfo(isShow: isShow, height: height)]
        model.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }
    
    public var webViewHeight: CGFloat? {
        guard let vc = registeredVC as? DocsContainerType else { return nil }
        return vc.webviewHeight
    }
    
    public func visibleContentHeight(with keyboardFrame: CGRect) -> CGFloat? {
        guard let vc = registeredVC as? (DocsContainerType & UIViewController) else { return nil }
        let keyboardTopInBrowserView = vc.view.convert(keyboardFrame, from: nil).top
        let toolbarBottomOffset = max(0, vc.view.frame.bottom - keyboardTopInBrowserView)
        return vc.webVisibleContentHeight - toolbarBottomOffset
    }

    public func inputViewsHeightChange(to: CGFloat) {
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateCommentInputViewHeight.rawValue, params: ["height": to])
    }

    public var currentWindow: UIWindow? {
        return ui?.editorView.window
    }
}
