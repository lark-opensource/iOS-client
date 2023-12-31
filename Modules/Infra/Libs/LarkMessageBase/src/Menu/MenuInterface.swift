//
//  MenuProtocol.swift
//  LarkCore
//
//  Created by 李晨 on 2019/2/28.
//

import UIKit
import Foundation
import class LarkModel.Chat
import class LarkModel.Message
import LarkReleaseConfig
import LarkContainer

// 所有业务如果需要接入消息菜单，需要声明业务对应枚举
public enum MessageActionType: String, CaseIterable {
    case unknown           // 未指定,会触发断言!
    case debug             // IM消息debug按钮(仅在Alpha\Beta\Debug并在高级调试中打开开关后有效)

    /* IM & Core */
    case urgent             // 加急
    case recall             // 撤回
    case multiEdit          // 二次编辑
    case reply              // 回复
    case forward            // 转发
    case forwardThread      // 转发话题
    case createThread       // 创建话题
    case openThread         // 打开话题
    case multiSelect        // 多选
    case copy               // 复制
    case cardCopy           // 卡片复制
    case saveTo             // 添加到
    case pin                // pin/unpin
    case topMessage         // 消息置顶/取消消息置顶
    case chatPin            // 新版群架构内置顶固定消息
    case addToSticker       // 添加到表情
    case jumpToChat         // 跳转到会话
    case toOriginal         // 消息详情界面回到原文，跳转至会话中
    case delete             // 删除
    case restrict           // 设为/取消保密消息
    case mutePlay           // 静音播放
    case audioPlayMode      // 切换语音消息播放模式: 耳机播放/听筒播放
    case flag               // 标记
    case favorite           // 收藏
    case messageLink        // 消息链接化
    case imageEdit          // 图片编辑
    case reaction           // reaction
    case like               // 对MyAI回复消息进行点赞
    case dislike            // 对MyAI回复消息进行点踩
    case quickActionInfo    // 展示消息的快捷指令信息，调试使用
    case ka                 // KA的菜单都用这个类型

    /* TODO */
    case todo               // todo，添加任务

    /* ASL */
    case translate          // 翻译
    case switchLanguage     // 切换语言
    case selectTranslate    // 划词翻译
    case search             // 搜索
    case audioText          // 显示/隐藏语音文字

    /* Meego */
    case meego              // meego 创建工作项

    /* OpenPlatform */
    case takeActionV2       // take an action V2 快捷操作
    case viewGenerationProcess  // myai 查看消息生成过程
}

public struct MessageMenuInfo {
    // 触发 menu 的 view， eg： 长按唤出菜单的 message bubble cell
    public let trigerView: UIView
    // 触发 menu point，是相对于 trigerView 的相对位置，eg: 长按手势对于 message bubble cell 的相对位置
    public let trigerLocation: CGPoint?
    // menu dismiss 回调 block
    public let dismissBlock: (() -> Void)?
    // 返回不可以被遮挡的view, 参数 uiview 为 trigerView, eg: 例如 chat 列表中支持区域copy的label
    public let displayViewBlcok: ((UIView) -> UIView?)?
    /// 自定义 recentReactions 数据。nil时使用默认的recentReactions。
    public let customRecentReactions: [String]?
    /// 自定义inserts。nil时使用默认的inserts
    public let customInserts: UIEdgeInsets?
    /// 是否显示面板的时候直接显示全部表情(默认false)
    public let isDirectShowMoreEmoji: Bool
    /// 翻译支持原文、译文、原文+译文不同显示效果，后面menu逻辑依赖具体触发的content,需要记录点击时content的类型，此处加入extraInfo属性，为了不针对具体业务场景
    /// 目前用到的key以及含义:
    /// 1、copyType copy维度，原文、译文、消息
    /// 2、contentLabelKey newchat里标示哪个label被选中
    /// 3、contentLabelTag chat里标示哪个label被选中
    public let extraInfo: [String: Any]

    public init(trigerView: UIView,
                trigerLocation: CGPoint?,
                customRecentReactions: [String]? = nil,
                customInserts: UIEdgeInsets? = nil,
                dismissBlock: (() -> Void)? = nil,
                displayViewBlcok: ((UIView) -> UIView?)? = nil,
                extraInfo: [String: Any] = [:],
                isDirectShowMoreEmoji: Bool = false) {
        self.trigerView = trigerView
        self.customInserts = customInserts
        self.trigerLocation = trigerLocation
        self.dismissBlock = dismissBlock
        self.customRecentReactions = customRecentReactions
        self.displayViewBlcok = displayViewBlcok
        self.extraInfo = extraInfo
        self.isDirectShowMoreEmoji = isDirectShowMoreEmoji
    }
}

public enum MeunABTestResult {
    case none
    case gentle
    case radical

    public var rawValue: String {
        switch self {
        case .none:
            return "none"
        case .gentle:
            return "gentle"
        case .radical:
            return "radical"
        }
    }
}

public protocol MenuInteractionABTestService: AnyObject {
    var abTestResult: MeunABTestResult { get }
    func hitABTest(chat: Chat?) -> Bool
    func replyMenuIcon(chat: Chat?) -> UIImage?
    func replyMenuTitle(chat: Chat?) -> String?
    func threadReplyMenuTitle(chat: Chat?) -> String?
}
