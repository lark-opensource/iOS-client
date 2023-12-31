//
//  WAContainer.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/15.
//

import Foundation
import LarkWebViewContainer
import LarkContainer

public protocol WAContainer: AnyObject {
    
    var hostURL: URL? { get }
    
    var hostWebView: LarkWebView? { get }
    
    /// 真正打开页面时才会有值。在预加载时hostVC为nil
    var hostVC: WAContainerUIDelegate? { get }
    
    var hostBridge: WABridge? { get }
    
    var loader: WALoader? { get }
    
    var hostPluginManager: WAPluginManager? { get }
    
    var hostOfflineManager: WAOfflineManager? { get }
    
    var lifeCycleObserver: WAContainerLifeCycleObserver { get }
    
    var userResolver: UserResolver { get }
    
    var timing: WAPerformanceTiming { get }
    
    var tracker: WATracker { get }
}

extension WAContainer {
    
    /// 容器是否挂载在页面上
    public var isAttachOnPage: Bool { hostVC != nil }
}
