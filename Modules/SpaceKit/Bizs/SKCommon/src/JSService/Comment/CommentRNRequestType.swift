//
//  CommentRNRequestType.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/25.
//  


import UIKit
import SpaceInterface

public protocol CommentRNRequestType: AnyObject {
    /// 发送评论的能力
    var commentManager: RNCommentDataManager? { get }
    
    /// 发送reaction的能力
    var commonManager: RNCommonDataManager? { get }
    
    /// 如果有webview参与，RN接口请求成功后需要将部分回调传给前端
    func callAction(_ action: CommentEventListenerAction, _ data: [String: Any]?)
}

public extension CommentRNRequestType {
    func callAction(_ action: CommentEventListenerAction, _ data: [String: Any]?) {}
}
