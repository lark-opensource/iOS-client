//
//  FollowableViewController.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/9.
//
// swiftlint:disable unused_setter_value


import Foundation


/// 支持Follow的ViewController
public protocol FollowableViewController: AnyObject {

    /// 当前FollowAPI 所对应的 docs 文档标题
    var followTitle: String { get }

    /// 文档是否支持回到上次位置目前只有 doc和wiki-doc
    var canBackToLastPosition: Bool { get }

    /// 返回当前UIScrollView
    var followScrollView: UIScrollView? { get }

    var followVC: UIViewController { get }

    /// 配置实现Follow的ViewContoller
    func onSetup(followAPIDelegate: SpaceFollowAPIDelegate)

    /// 注入JS
    func injectJS(_ script: String)

    /// 刷新当前页面
    func refreshFollow()

    /// 释放 delegate
    func onDestroy()

    func onOperate(_ operation: SpaceFollowOperation)

    /// 角色变化
    func onRoleChange(_ newRole: FollowRole)
    
    /// VCfollow调用前端JS
    func executeJSFromVcfollow(operation: String, params: [String: Any]?)

    /// 需native处理的follow事件
//    func receiveEvent(actions: [[String: Any]])

    /// 返回当前是否为编辑态，这个使用时要注意，VC 端会根据这个字段来判断是否要拦截空白键事件。
    var isEditingStatus: Bool { get }
    
    /// 是否同层渲染的内容 Follow
    var isSameLayerFollow: Bool { get set }
    
    /// 是否设置 attachFile
    var canSetAttachFile: Bool { get }
}

extension FollowableViewController {

    public func injectJS(_ script: String) {}

    public func onDestroy() {}

    public func onOperate(_ operation: SpaceFollowOperation) {}

    public func onRoleChange(_ newRole: FollowRole) {}

    public func executeJSFromVcfollow(operation: String, params: [String: Any]?) {}

//    public func receiveEvent(actions: [[String: Any]]) {}

    public var canBackToLastPosition: Bool {
        return false
    }

    public var isSameLayerFollow: Bool {
        get { return false }
        set {}
    }
    
    public var canSetAttachFile: Bool {
        return true
    }
}

extension FollowableViewController where Self: UIViewController {
    public var followVC: UIViewController {
        return self
    }
}
