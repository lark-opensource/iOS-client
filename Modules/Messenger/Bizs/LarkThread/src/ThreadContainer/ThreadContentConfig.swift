//
//  ThreadContext.swift
//  LarkThread
//
//  Created by 李勇 on 2020/10/17.
//

import UIKit
import RxSwift
import RxCocoa
import LarkModel
import SnapKit
import LarkSDKInterface

/// ThreadContainerController中构造子VC时需要的一些上下文
struct ThreadContentConfig {
    let topicGroup: TopicGroup
    let chat: Chat
    /// 导航栏高度
    let navBarHeight: CGFloat

    /// 构造初始化方案
    public init(topicGroup: TopicGroup,
                chat: Chat,
                navBarHeight: CGFloat) {
        self.topicGroup = topicGroup
        self.chat = chat
        self.navBarHeight = navBarHeight
    }
}

/// ThreadGroupPreviewContainerController中构造子VC时需要的一些上下文
struct ThreadPreviewContentConfig {
    let topicGroup: TopicGroup
    let chat: Chat

    /// 构造初始化方案
    public init(topicGroup: TopicGroup,
                chat: Chat) {
        self.topicGroup = topicGroup
        self.chat = chat
    }
}
