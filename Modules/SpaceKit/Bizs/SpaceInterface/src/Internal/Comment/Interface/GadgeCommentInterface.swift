//
//  GadgeCommentInterface.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/28.
//  

public class GadgetCommentCallback {
    public enum Result {
        case success(data: [String: Any])
        case failure(error: Error)
    }

    var callback: (Result) -> Void

    public init(callback: @escaping (Result) -> Void) {
        self.callback = callback
    }

    public func callAsFunction(_ result: Result) {
        self.callback(result)
    }
}


public protocol GadgetJSServiceHandlerDelegate: AnyObject {
    
    func simulateJSMessage(token: String?, _ msg: String, params: [String: Any])
    
    func fetchServiceInstance<H>(token: String?, _ service: H.Type) -> H? where H: GadgetJSServiceHandlerType
    
    func openURL(url: URL)
    
    func openProfile(id: String)
    
    var minaSession: Any? { get }
}

public protocol GadgetJSServiceHandlerType: AnyObject {
    
    var gadgetInfo: CommentDocsInfo? { get }
    
    var gadgetJsBridges: [String] { get }
    static var gadgetJsBridges: [String] { get }
    
    init(gadgetInfo: CommentDocsInfo, dependency: CommentPluginDependency, delegate: GadgetJSServiceHandlerDelegate)
    
    func handle(params: [String: Any], extra: [String: Any], serviceName: String, callback: GadgetCommentCallback)
    
    func gadegetSessionHasUpdate(minaSession: Any)
}

extension GadgetJSServiceHandlerType {
    public var gadgetInfo: CommentDocsInfo? {
        return nil
    }
    public func gadegetSessionHasUpdate(minaSession: Any) {}
}


/// 依赖开放平台提供的字段/接口
public protocol CommentPluginDependency: AnyObject {
    
    /// 顶层控制器
    var topViewController: UIViewController? { get }
    
    /// 是否展示水印
    var shouldShowWatermark: Bool { get }
}
