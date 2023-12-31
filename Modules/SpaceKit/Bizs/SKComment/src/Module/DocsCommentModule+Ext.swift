//
//  DocsCommentModule+Ext.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/30.
//  


import Foundation
import SKFoundation
import SpaceInterface

// MARK: - 内部便利方法
extension DocsCommentModule {
    
    var topMost: UIViewController? {
        let topMostVc = UIViewController.docs.topMost(of: commentPluginView.window?.rootViewController)
        DocsLogger.info("topMostVC =\(String(describing: topMostVc))", component: LogComponents.comment)
        return topMostVc
    }
    
    var vcToolbarHeight: CGFloat {
        var height: CGFloat = 0
        if let currentWindow = commentPluginView.window {
            var keyWindow: UIWindow?
            if #available(iOS 15.0, *) {
                keyWindow = currentWindow.windowScene?.keyWindow
            } else {
                keyWindow = UIApplication.shared.keyWindow
            }
            if let keyWin = keyWindow {
                let frame = commentPluginView.convert(commentPluginView.frame, to: keyWin)
                let bottom = currentWindow.bounds.height - frame.maxY
                if bottom > 0 && bottom < 100 {
                    height = bottom
                }
            }
        }
        return height
    }
}


/// aside、float、drive评论的相同实现可以放在这里
extension DocsCommentModule {
    public func updateCopyTemplateURL(urlString: String) {
        if let module = self as? (DocsCommentModule & CommentServiceContext) {
            module._updateCopyTemplateURL(urlString: urlString)
        }
    }
    
    public func removeAllMenu() {
        if let module = self as? (DocsCommentModule & CommentServiceContext) {
            module._removeAllMenu()
        }
    }
}

extension DocsCommentModule where Self: CommentServiceContext {
    
    func _updateCopyTemplateURL(urlString: String) {
        guard !urlString.isEmpty else {
            DocsLogger.error("templateURL is empty", component: LogComponents.comment)
            return
        }
        scheduler?.dispatch(action: .updateCopyTemplateURL(urlString: urlString))
    }
    
    func _removeAllMenu() {
        scheduler?.dispatch(action: .removeAllMenu)
    }
}

