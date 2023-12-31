//
//  ChatSecurityAuditService.swift
//  LarkMessengerInterface
//
//  Created by 赵家琛 on 2020/12/1.
//

import LarkModel
import Foundation

public enum ChatSecurityAuditEventType {
    case clickLink(url: String, chatId: String? = nil, chatType: Chat.TypeEnum? = nil)
    case saveImage(key: String)
    case saveVideo(key: String)
    case downloadFile(key: String)
    case fileOpenedWith3rdApp(chatId: String, chatType: Chat.TypeEnum, fileId: String, fileType: String, appId: String)
    // 在线预览非图片\视频文件
    case chatPreviewfile(chatId: String, chatType: Chat.TypeEnum, fileId: String, fileName: String, fileType: String)
    // 复制
    case copy(chatId: String, chatType: Chat.TypeEnum, messageType: Message.TypeEnum)
    // 编辑图片
    case chatEditImage(chatId: String, chatType: Chat.TypeEnum, imageKey: String)
    // 保存到我的空间
    case saveToSpace(chatId: String, chatType: Chat.TypeEnum, fileId: String, fileName: String, fileType: String)
    case ocrResult(length: Int, imageKey: String)
    case chatPin(type: ChatPinAuditEventType)
}

public enum ChatPinAuditEventType {
    case showChatPinList(chatId: String) //展开置顶看板
    case copyContent(chatId: String, pinId: Int64) //在置顶链接菜单内点击“复制链接”
    case clickBackToChat(chatId: String, pinId: Int64) //点击置顶消息 “回到原文”
    case clickOpenUrl(chatId: String, pinId: Int64) //点击置顶链接卡片后打开链接
    case showChatPinInChat(chatId: String, pinIds: [String]) //查看置顶内容（进入会话&且会话内有置顶内容就上报）
}

public protocol ChatSecurityAuditService {
    func auditEvent(_ event: ChatSecurityAuditEventType, isSecretChat: Bool)
}
