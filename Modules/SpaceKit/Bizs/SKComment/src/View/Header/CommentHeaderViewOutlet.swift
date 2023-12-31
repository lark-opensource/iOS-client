//
//  CommentHeaderViewOutlet.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/18.
//  

import Foundation
import SpaceInterface
/// 评论顶部的对外输出接口
protocol CommentHeaderViewDelegate: AnyObject {

    /// 点击返回按钮
    func didClickBackButton()

    /// 退出编辑
    func didExitEditing(needReload: Bool)

    /// 点击解决按钮
    func didClickResolveButton(_ fromView: UIView, comment: Comment?)
}
