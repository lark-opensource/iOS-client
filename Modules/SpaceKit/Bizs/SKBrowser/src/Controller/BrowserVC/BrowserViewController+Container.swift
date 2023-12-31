//
//  BrowserViewController+Container.swift
//  SKBrowser
//
//  Created by huayufan on 2021/8/30.
//  


import SKCommon
import SKUIKit

extension BrowserViewController: DocsContainerType {
    
    public var webviewHeight: CGFloat {
        return view.frame.height - statusBar.frame.height - topContainer.frame.height
    }
    
    /// 调起全文评论输入框时用于计算高度并传给前端；如果在其他场景使用需要自己验证下
    public var webVisibleContentHeight: CGFloat {
        if SKDisplay.pad {
            return webviewHeight
        } else {
            // 在iPhone上，web上下滑动会显示隐藏导航栏，但是导航栏不算占用webview高度
            // 因此不减去topContainer(导航栏)的高度
            return view.frame.height - self.editor.frame.minY
        }
    }
}
