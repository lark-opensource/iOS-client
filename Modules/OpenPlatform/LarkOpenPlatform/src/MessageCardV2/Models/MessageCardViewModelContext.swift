//
//  MessageCardViewModelContext.swift
//  LarkOpenPlatform
//
//  Created by majiaxin.jx on 2022/12/2.
//

import Foundation
import LarkModel
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging

/**
 * 消息卡片 Context, 贯穿全局 Factory -> VM -> VMBinder -> Component
 * 用于 Lynx 版消息卡片
 * 从设计的角度应该与旧 DynamicContentViewModelContext 隔离
 *
 * 但从以下角度考虑:
 * 1. 功能与 DynamicContentViewModelContext 完全一致
 * 2.  代码增量: DynamicContentViewModelContext 有多个扩展类, 详见 CardContext,
 *   所有扩展类重新实现是很大的代码增量, 目前增量卡点非常严格
 * 3. 实现成本: 原代码有很多特化逻辑, 这部分在不清楚上下文情况下贸然挪动会造成额外影响
 *
 * 所以目前仅设为 DynamicContentViewModelContext 别名, 后续版本中再考虑改动
 */
typealias MessageCardViewModelContext = DynamicContentViewModelContext & PageContext
