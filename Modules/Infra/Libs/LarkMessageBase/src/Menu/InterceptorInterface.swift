//
//  InterceptorInterface.swift
//  LarkMessageBase
//
//  Created by Zigeng on 2023/1/5.
//
import Foundation
import LarkModel
import LarkContainer
import RustPB

/// 若存在重复拦截, 最上面的拦截器优先级最高, 决定最终ActionMenuItem被拦截的类型(MessageActionInterceptedType)
public enum MessageActionSubInterceptorType: Int, Hashable, CaseIterable {
    /// 撤回消息: 不展示菜单
    case recall = 0
    /// 服务端已将将消息物理清除,不展示菜单
    case cleaned
    /// 局部选择态
    case partialSelect
    /// 临时消息
    case ephemeral
    /// 消息发送状态拦截器
    case messageState
    /// 消息类型拦截器,非IM业务方可通过`OpenMessageTypeActionSubInterceptor`来实现拦截
    case messageType
    /// 外部联系人单聊
    case crossTenantP2P
    /// 服务端下发消息操作权限 https://bytedance.feishu.cn/docx/T1CHdNEchoX5jOx5f5Gcx8uKnKc
    case server
    /// DLP 企业安全管控
    case dlp
    /// 保密消息需求 https://bytedance.feishu.cn/docx/ViXydmVOconuEBxJvplcgNitnec
    case messageRestricted
    /// 群被冻结
    case chatForzen
    /// 群聊防泄密(保密群)
    case sercetChat
    /// 密盾聊
    case privateMode
    /// My AI消息：https://bytedance.feishu.cn/docx/Rn9kdvsX6okJyTxoGtYcygJBn2A
    case myAI
    /// 密聊解密失败消息
    case isSecretChatDecryptedFailed
    /// 保存到功能
    case saveTo
}

public enum MessageActionInterceptedType {
    public typealias ActionDisableBlock = (() -> Void)
    /// 隐藏
    case hidden
    /// 不可以用
    /// String 不可用原因
    case disable(String)
}

/// 全上下文拦截器, 暂不考虑对外开放
/// 业务方自己消息类型期望拒绝Action请使用已开放的 OpenMessageTypeActionSubInterceptor
public protocol MessageActionInterceptor: AnyObject {
    init()
    func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType]
}


public protocol MessageActioSubnInterceptor: MessageActionInterceptor {
    static var subType: MessageActionSubInterceptorType { get }
}

public struct MessageActionInterceptorContext {
    public let message: Message
    public let chat: Chat
    /// 当前是否是MyAI的分会场
    public let myAIChatMode: Bool
    public let isInPartialSelect: Bool
    public let isPrivateThread: Bool
    public let userResolver: LarkContainer.UserResolver

    public init(message: Message,
                chat: Chat,
                myAIChatMode: Bool,
                isInPartialSelect: Bool,
                userResolver: LarkContainer.UserResolver) {
        self.message = message
        self.chat = chat
        self.isInPartialSelect = isInPartialSelect
        self.myAIChatMode = myAIChatMode
        self.isPrivateThread = false
        self.userResolver = userResolver
    }
}
