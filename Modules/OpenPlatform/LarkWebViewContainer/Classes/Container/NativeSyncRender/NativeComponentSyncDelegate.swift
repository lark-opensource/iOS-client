//
//  NativeComponentSyncDelegate.swift
//  LarkWebViewContainer
//
//  Created by wangjin on 2022/10/20.
//

import Foundation
import WebKit

public protocol NativeComponentSyncDelegate: NSObjectProtocol {
    /// 插入组件视图
    func insertComponent(scrollView: UIScrollView, apiContext: APIContextProtocol)
}

public protocol APIContextProtocol {
    var renderId: String { get }
}
