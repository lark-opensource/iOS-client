//
//  MessageLinkEngineCellViewModelFactory.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/16.
//

import LarkMessageBase

// 和话题转发卡片场景的CellBinder不同，需要有个单独的类
public final class MessageLinkEngineCellViewModelFactory<C: PageContext>: MessageEngineCellViewModelFactory<C> {}
