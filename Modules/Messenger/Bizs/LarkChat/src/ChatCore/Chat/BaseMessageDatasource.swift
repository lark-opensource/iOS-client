//
//  BaseMessageDatasource.swift
//  LarkChat
//
//  Created by qihongye on 2023/7/11.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkMessageCore
import LarkMessengerInterface
import ThreadSafeDataStructure
import LarkContainer

/// 处理一条消息
enum HandleMessageScene {
    case newMessage
    case updateMessage
    case messageSending
    case messageSendSuccess
    case messageSendFail
    case none
}

enum HeadTailAppendResult: Equatable {
    case none
    case hasMoreMessages
    case needRefresh
}

/// MessageCellProcessor, BaseMessageContainer, BaseMessageDatasource
///         BaseMessageDatasource
///            /(weak)              \
/// BaseMessageContainer    MesageCellProcessor

/// MessageCellProcessor 协议约束
/// @Description: 预处理CellVMType

protocol BaseMessageContainer: AnyObject {
    var userResolver: UserResolver { get }

    var contentPadding: CGFloat { get }

    /// 气泡内容推荐最大宽度
    func getContentPreferMaxWidth(_ message: LarkModel.Message) -> CGFloat

    /// 一些feature介绍，可以在如ChatDatasource头部展示。
    func getFeatureIntroductions() -> [String]

    var firstMessagePosition: Int32 { get } // 有效消息的上边界Position

    var lastMessagePosition: Int32 { get } // 有效消息的下边界Position
}

/// MessageDatasource 协议约束
/// 用于解决ChatMessagesVM对ChatCellViewModel的操作需求
protocol BaseMessageDatasource {
    /// TODO: @冯梓耕 这里的get约束性不强，后面看下是否可以改成函数
    var cellViewModels: [ChatCellViewModel] { get }
    var chat: () -> Chat { get }

    // 数据源中维护数据区间的最大值
    var maxMessagePosition: Int32 { get }
    // 数据源中维护数据区间的最小值
    var minMessagePosition: Int32 { get }

    var readPositionBadgeCount: Int32? { get set }

    var container: BaseMessageContainer? { get set }

    func reset(messages: [Message],
               totalRange: (minPostion: Int32, maxPostion: Int32)?,
               concurrent: (Int, (Int) -> Void) -> Void)

    /// 头尾插入
    func merge(messages: [Message],
               totalRange: (minPostion: Int32, maxPostion: Int32)?,
               concurrent: (Int, (Int) -> Void) -> Void)

    /// 插入消息
    func insert(messages: [Message], concurrent: (Int, (Int) -> Void) -> Void) -> Bool

    /// 处理某一个消息的更新
    func handle(message: Message, concurrent: (Int, (Int) -> Void) -> Void) -> HandleMessageScene

    /// 前插一段数据
    func headAppend(messages: [Message],
                    totalRange: (minPostion: Int32, maxPostion: Int32)?,
                    concurrent: (Int, (Int) -> Void) -> Void) -> HeadTailAppendResult

    /// 后插一段数据
    func tailAppend(messages: [Message], totalRange: (minPostion: Int32, maxPostion: Int32)?, concurrent: (Int, (Int) -> Void) -> Void) -> HeadTailAppendResult

    /// 外部更新某个message的属性(有些信号不是rustpush来的，不能保证这个消息的正确性，只能明确做个别属性的替换)
    /// doUpdate: (Message) -> Message? 外部可能不决定更新
    /// NOTE: 目前系统消息不会调用该函数，暂时不做处理
    func update(messageIds: [String], doUpdate: (Message) -> Message?) -> Bool

    /// 数据源会依次将当前所有数据依次反馈给上层，上层可根据需要更新message
    func update(original: (Message) -> Message?) -> Bool

    /// 通过messageId找到对应index
    func index(messageId: String, positive: Bool) -> Int?
    func index(messageId: String) -> Int?

    /// 通过cid找到对应index
    func index(cid: String) -> Int?

    /// 如果不提供messageId，只匹配成功消息的position; 否则以messageId为准进行匹配
    func index(messagePosition: Int32, messageId: String?) -> Int?
    func index(messagePosition: Int32) -> Int?

    /// 可以直接缓存记录状态
    func indexForNewMessageSignCell() -> Int?

    /// 透传CellVM能力。触发CellVM重布局、重渲染
    func refreshRenders()

    /// 透传CellVM能力。触发CellVM resize逻辑，重布局、重渲染
    func onResize()

    /// 透传CellVM能力。删除delete
    func delete(messageId: String) -> Bool

    /// TODO: @qhy，这个接口为啥一定要这么搞，待优化。
    /// 1. 避免外部直接设置nil,设置nil需要调用removeHighlightInfo
    /// 2. 该方法内里面有容错逻辑
    func setHighlightInfo(_ info: HighlightMessageInfo)

    /// TODO: @qhy，这个接口为啥一定要这么搞，待优化。
    /// 删除高亮
    func removeHighlightInfo() -> Int?
}
