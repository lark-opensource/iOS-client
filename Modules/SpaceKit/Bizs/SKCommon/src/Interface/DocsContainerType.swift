//
//  DocsContainerType.swift
//  SKCommon
//
//  Created by huayufan on 2021/8/30.
//  


import UIKit

public protocol DocsContainerType {
    
    var webviewHeight: CGFloat { get }
    
    /// 调起全文评论输入框时用于计算高度并传给前端；如果在其他场景使用需要自己验证下
    var webVisibleContentHeight: CGFloat { get }
}
