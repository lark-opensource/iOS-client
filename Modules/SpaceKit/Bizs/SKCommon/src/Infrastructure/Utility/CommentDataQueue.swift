//
//  CommentDataQueue.swift
//  SKCommon
//
//  Created by huayufan on 2023/1/9.
//  


import UIKit
import SKFoundation

public class CommentUpdateDataQueue<Action> {
    
    var nodes: [CommentDataQueueNode<Action>] = []
    
    public typealias ActionClosure = (CommentDataQueueNode<Action>) -> Void
    
    public var actionClosure: ActionClosure?
    
    public init() {}

    public func appendAction(_ action: Action) {
        let node = CommentDataQueueNode(action)
        node.fulfilClosure = { [weak self]  in
            // 移除已经处理完的
            spaceAssert(self?.nodes.first?.fulfill == true)
            self?.nodes.removeFirst()
            if let node = self?.nodes.first {
                // 处理队列下个任务
                self?.actionClosure?(node)
            } else {
                DocsLogger.info("[data queue] queue clear", component: LogComponents.comment)
            }
        }
        if let pre = nodes.last {
            if pre.fulfill { // 上个任务已经完成
                nodes.append(node)
                // 立即执行
                actionClosure?(node)
            } else {
                nodes.append(node)
                // 稍后执行
                DocsLogger.info("[data queue] suspend node", component: LogComponents.comment)
            }
        } else {
            nodes.append(node)
            // 立即执行
            actionClosure?(node)
        }
    }
}

public class CommentDataQueueNode<Action> {
    public let action: Action
    var fulfill = false
    
    var fulfilClosure: (() -> Void)?

    public init(_ action: Action) {
        self.action = action
    }
    public func markFulfill() {
        fulfill = true
        fulfilClosure?()
    }
}
