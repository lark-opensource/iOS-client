//
//  MyAIActionInterceptor.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/4/18.
//

import Foundation
import LarkMessageBase
import LarkAccountInterface

/// My AI的消息需要禁止部分菜单项：https://bytedance.feishu.cn/docx/Rn9kdvsX6okJyTxoGtYcygJBn2A
public final class MyAIActionInterceptor: MessageActioSubnInterceptor {
    public static var subType: MessageActionSubInterceptorType { .myAI }

    public required init() { }

    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]

        // 如果消息正在流式状态，则不展示任何菜单项
        if context.message.streamStatus == .streamTransport || context.message.streamStatus == .streamPrepare {
            MessageActionType.allCases.forEach { interceptedActions.updateValue(.hidden, forKey: $0) }
            return interceptedActions
        }

        // 如果是AI单聊则菜单项需要单独处理，不展示reaction等：https://bytedance.feishu.cn/docx/AV5qdvYpUoU3MXx9SGtcnrNTn6f
        if context.chat.isP2PAi {
            var blockList: [MessageActionType] = [.reaction, .reply, .createThread, .delete, .takeActionV2, .multiEdit, .recall, .urgent]
            // 如果是分会场
            if context.myAIChatMode {
                // 不支持创建任务：通过任务接口发的消息，服务端无法带上AIChatModeID
                blockList.append(.todo)
                // 把Chat相对于ReplyInThread多注册的去掉
                blockList.append(contentsOf: [.topMessage, .meego])
                // 不支持多选：目前PM要求MyAI场景支持合并转发、逐条转发、复制消息链接，但是这些都有问题，下面就列一点
                //         合并转发：根消息转发出去是Thread样式，用户点击会跳转到ReplyInThread详情，预期也应该是跳转到分会场成平铺样式
                //         逐条转发：之前ReplyInThread就不支持逐条转发
                //         复制消息链接：根消息链接化渲染是Thread的样式，用户预期就是一条普通消息样式
                blockList.append(.multiSelect)
                // 根消息，跳转时没有在主会场展开则没反应
                if context.message.threadPosition == -1 {
                    blockList.append(contentsOf: [.pin, .chatPin, .flag])
                    // messageLink消息链接化渲染是Thread的样式
                    blockList.append(contentsOf: [.messageLink])
                }
                // 回复消息
                else {
                    // pin因为会pin到主会场的pin列表，跳转会到ReplyInThread详情；flag因为标记列表跳转时会到ReplyInThread详情
                    blockList.append(contentsOf: [.pin, .chatPin, .flag])
                    // ChatMessageLinkMessageActionSubModule接口会报错，用ReplyThreadMessageLinkMessageActionSubModule可以成功
                    blockList.append(contentsOf: [.messageLink])
                }
            }
            // 如果是主会场中展开的分会场消息，测试发现和上面分会场表现一致（也应该一致）
            else if context.message.aiChatModeID > 0 {
                // 不支持创建任务：通过任务接口发的消息，服务端无法带上AIChatModeID
                blockList.append(.todo)
                // meego线上没开启无法测试，先屏蔽
                blockList.append(.meego)
                // 不支持多选：目前PM要求MyAI场景支持合并转发、逐条转发、复制消息链接，但是这些都有问题，下面就列一点
                //         合并转发：根消息转发出去是Thread样式，用户点击会跳转到ReplyInThread详情，预期也应该是跳转到分会场成平铺样式
                //         逐条转发：之前ReplyInThread就不支持逐条转发，主会场里分会场消息就是Thread，逻辑应该和ReplyInThread一致
                //         复制消息链接：根消息链接化渲染是Thread的样式，用户预期就是一条普通消息样式
                blockList.append(.multiSelect)
                // 根消息，跳转时没有在主会场展开则没反应
                if context.message.threadPosition == -1 {
                    blockList.append(contentsOf: [.pin, .chatPin, .flag])
                    // messageLink消息链接化渲染是Thread的样式
                    blockList.append(contentsOf: [.messageLink])
                    // topMessage跳转没有高亮
                    blockList.append(contentsOf: [.topMessage])
                }
                // 回复消息，跳转时没有在主会场展开则没反应
                else {
                    // pin列表跳转会到ReplyInThread详情；flag列表跳转时会到ReplyInThread详情
                    blockList.append(contentsOf: [.pin, .chatPin, .flag])
                    // messageLink：ChatMessageLinkMessageActionSubModule接口会报错，用ReplyThreadMessageLinkMessageActionSubModule可以成功
                    blockList.append(contentsOf: [.messageLink])
                    // topMessage跳转无法定位
                    blockList.append(contentsOf: [.topMessage])
                }
            }
            // 针对卡片引导消息，屏蔽多余选项
            if context.message.aiMessageType == .guideMessage {
                // GuideMessage 保留菜单项：
                // 主对话：转发、多选、debugInfo、标记、复制消息链接、翻译、添加任务
                // 分对话：转发、DebugInfo、翻译
                blockList.append(contentsOf: [.like, .dislike, .copy, .cardCopy, .pin, .chatPin])
                if context.myAIChatMode {
                    blockList.append(contentsOf: [.multiSelect, .flag, .messageLink])
                }
            }

            blockList.forEach { interceptedActions.updateValue(.hidden, forKey: $0) }
            return interceptedActions
        }

        return interceptedActions
    }
}
