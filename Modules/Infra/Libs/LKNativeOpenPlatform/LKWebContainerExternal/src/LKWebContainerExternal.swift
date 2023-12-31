//
//  LKWebContainerExternal.swift
//  LKWebContainerExternal
//
//  Created by ByteDance on 2022/8/16.
//

import Foundation

@objcMembers
public class KAWebContainerButtonConfig: NSObject {
    public var text: String?
    public var eventName: String?
    public var eventExtra: String?
    public var hide: Bool?
}

@objcMembers
public class KAWebContainerErrorPageConfig: NSObject {
    public var title: String?
    public var contentTitle: String?
    public var content: String?
    public var hideBigImage: Bool?
    public var vpnConfig: KAWebContainerButtonConfig?
    public var refreshConfig: KAWebContainerButtonConfig?
}

@objc
public protocol KAWebContainerProtocol: AnyObject {
    /// 网页容器打开即将loadUrl的时候调用
    /// - Parameters:
    ///   - url: 加载的 h5 url
    ///   - onSuccess: 流程处理完，通知网页容器继续加载
    ///   - onFail: 流程处理异常，通知网页容器展示错误页
    ///           - code：异常的code值，网页容器根据code值进行相应的错误展示
    func onOpen(url: String, onSuccess: @escaping () -> Void, onFail: @escaping (_ code: Int) -> Void)
    /// 网页容器即将关闭的时候调用
    /// - Parameter url: 即将关闭的页面 h5 url
    func onClose(url: String)
    /// 当网页容器加载失败时，飞书会通过该接口获取错误页展示需要的配置信息
    /// - Returns: 错误页配置
    func errorPageConfig() -> KAWebContainerErrorPageConfig?
    /// 返回业务 tag
    /// - Returns: kaIdentity
    @objc optional func kaIdentity() -> String
}

@objcMembers
public class KAWebContainerExternal: NSObject {
    public override init() {
    }
    public static let shared = KAWebContainerExternal()
    public var container: KAWebContainerProtocol? {
        didSet {
            if let temp = container {
                containers.append(temp)
            }
        }
    }
    public private(set) var containers: [KAWebContainerProtocol] = []
}

public extension KAWebContainerProtocol {
    func getWholeIdentity() -> String {
        kaChannel() + kaIdentity()
    }
    
    func kaIdentity() -> String {
        ""
    }
    
    fileprivate func kaChannel() -> String {
        ""
    }
}
