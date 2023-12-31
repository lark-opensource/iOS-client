//
//  CommentPluginType.swift
//  SKCommon
//
//  Created by huayufan on 2022/7/28.
//  


import UIKit
import RxDataSources
import Differentiator
import SpaceInterface
import SKCommon

// MARK: - class define


protocol CommentFastState {
    var activeCommentId: String? { get }
    var activeComment: Comment? { get }
    var docsInfo: DocsInfo? { get }
    var mode: CardCommentMode? { get }
    var preMode: CardCommentMode? { get }
    var localCommentIds: [String] { get }
    var copyAnchorLink: String { get }
    var commentPermission: CommentPermission { get }
    var followRole: FollowRole? { get }
}

/// 负责转发action和提供state给外部
protocol CommentSchedulerType: AnyObject {
    /// 负责派发action给其他plugin处理
    func dispatch(action: CommentAction)

    /// 产出state
    func reduce(state: CommentState)

    /// 提供上下文给插件
    func apply(context: CommentServiceContext)

    /// 加载插件
    func connect(plugins: [CommentPluginType])
    
    /// 卸载插件
    func uninstall(plugins: [CommentPluginType.Type])

    /// 根据标识返回插件实例
    func plugin<T: CommentPluginType>(with pluginType: T.Type) -> T?
    
    /// 提供一些基本的状态
    var fastState: CommentFastState { get }
    
    func fetchCache<T>(by key: String) -> T?
}

public enum CommentModulePattern: String {
    case aside
    case float
    case drive
}

/// 提供给plugin的上下文
protocol CommentServiceContext: AnyObject {

    var scheduler: CommentSchedulerType? { get }
    
    var tableView: UITableView? { get }
    
    var vcToolbarHeight: CGFloat { get }
    
    var businessDependency: DocsCommentDependency? { get }
    
    var topMost: UIViewController? { get }
    
    var commentPluginView: UIView { get }

    var pattern: CommentModulePattern { get }
    
    var banCanComment: Bool { get }
    
    var commentVC: UIViewController? { get }
}

extension CommentServiceContext {
    var banCanComment: Bool { return false }
    
    var commentVC: UIViewController? { return nil }
}

extension CommentServiceContext {
    var docsInfo: DocsInfo? {
        return scheduler?.fastState.docsInfo
    }
}


/// 评论插件，按照不同的功能来划分，插件实现应当遵守单一职责
/// 非当前业务的职责可以通过scheduler进行转发
protocol CommentPluginType: AnyObject {

    /// 提供给每个插件的上下文，通过上下文可以进行事件转发以及
    /// 获取公共状态信息
    func apply(context: CommentServiceContext)
    
    /// 处理action
    func mutate(action: CommentAction)
    
    /// 每个插件的唯一标识
    static var identifier: String { get }
}

protocol CommentCachePluginType {
    func cache<T>(key: String) -> T?
}
