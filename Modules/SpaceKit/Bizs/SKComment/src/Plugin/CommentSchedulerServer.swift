//
//  CommentSchedulerServer.swift
//  SKCommon
//
//  Created by huayufan on 2022/7/28.
//  


import UIKit
import SKFoundation
import RxSwift
import RxCocoa
import SpaceInterface
import SKCommon


protocol CommentViewInteractionType: AnyObject {
    func emit(action: CommentAction.UI)
}

class CommentSchedulerServer {
     
    private var plugins: [CommentPluginType] = []
    
    private var unique: [String: CommentPluginType] = [:]
    
    var state = BehaviorRelay<CommentState>(value: .loading(false))
}

extension CommentSchedulerServer: CommentSchedulerType {
    func dispatch(action: CommentAction) {
        if !action.description.isEmpty {
            DocsLogger.info("[dispatch action]:\(action)", component: LogComponents.comment)
        }
        plugins.forEach {
            $0.mutate(action: action)
        }
    }
    
    func reduce(state: CommentState) {
        DocsLogger.info("[reduce state]:\(state)", component: LogComponents.comment)
        self.state.accept(state)
    }
    
    func apply(context: CommentServiceContext) {
        plugins.forEach {
            $0.apply(context: context)
        }
    }
    
    func connect(plugins: [CommentPluginType]) {
        plugins.forEach {
            let identifier = type(of: $0).identifier
            if unique[identifier] != nil {
                spaceAssertionFailure("plugin \(identifier) repeated")
            } else {
                unique[identifier] = $0
                self.plugins.append($0)
            }
        }
    }
    
    func uninstall(plugins: [CommentPluginType.Type]) {
        plugins.forEach {
            let identifier = $0.identifier
            if unique[identifier] != nil {
                unique[identifier] = nil
            }
            self.plugins = self.plugins.filter { type(of: $0).identifier != identifier }
        }
    }
    
    func plugin<T: CommentPluginType>(with pluginType: T.Type) -> T? {
        return unique[pluginType.identifier] as? T
    }
    
    func fetchCache<T>(by key: String) -> T? {
        for plugin in plugins where plugin is CommentCachePluginType {
            if let result: T = (plugin as? CommentCachePluginType)?.cache(key: key) {
                return result
            }
        }
        return nil
    }
}

// MARK: - CommentFastState
extension CommentSchedulerServer {
    
    struct FastStateImpl: CommentFastState {
        
        var activeCommentId: String?
        var activeComment: Comment?
        var docsInfo: DocsInfo?

        /// FloatComment才会返回
        var mode: CardCommentMode?
        var preMode: CardCommentMode?
        var localCommentIds: [String]
        var copyAnchorLink: String
        var commentPermission: CommentPermission
        var followRole: FollowRole?
    }
    
    var fastState: CommentFastState {
        let dataPlugins = plugins.compactMap { $0 as? CommentDiffDataPlugin }
        spaceAssert(dataPlugins.count == 1)
        let plugin = dataPlugins.first
        var activeComment = plugin?.commentSections.activeComment?.0
        if let floatDataPlugin = plugin as? CommentFloatDataPlugin {
            if case let .newInput(model) = floatDataPlugin.mode {
                activeComment = model.toCommentWrapper().comment
            }
            return FastStateImpl(activeCommentId: activeComment?.commentID,
                                 activeComment: activeComment,
                                 docsInfo: plugin?.docsInfo,
                                 mode: floatDataPlugin.mode,
                                 preMode: floatDataPlugin.preMode,
                                 localCommentIds: [],
                                 copyAnchorLink: floatDataPlugin.templateUrlString,
                                 commentPermission: floatDataPlugin.commentPermission,
                                 followRole: floatDataPlugin.role)
        } else if let driveDataPlugin = plugin as? CommentDriveDataPlugin {
            if case let .newInput(model) = driveDataPlugin.mode {
                activeComment = model.toCommentWrapper().comment
            }
            return FastStateImpl(activeCommentId: activeComment?.commentID,
                                 activeComment: activeComment,
                                 docsInfo: plugin?.docsInfo,
                                 mode: driveDataPlugin.mode,
                                 preMode: driveDataPlugin.preMode,
                                 localCommentIds: driveDataPlugin.localCommentIds,
                                 copyAnchorLink: "",
                                 commentPermission: driveDataPlugin.commentPermission)
        } else {
            var copyAnchorLink = ""
            if let dataPlugin = plugin as? CommentDiffDataPlugin {
                copyAnchorLink = dataPlugin.templateUrlString
            }
            return FastStateImpl(activeCommentId: activeComment?.commentID,
                                 activeComment: activeComment,
                                 docsInfo: plugin?.docsInfo,
                                 mode: nil,
                                 preMode: nil,
                                 localCommentIds: [],
                                 copyAnchorLink: copyAnchorLink,
                                 commentPermission: plugin?.commentPermission ?? [],
                                 followRole: plugin?.role)
        }
    }
}

extension CommentSchedulerServer: CommentViewInteractionType {
    func emit(action: CommentAction.UI) {
        dispatch(action: CommentAction.interaction(action))
    }
}
