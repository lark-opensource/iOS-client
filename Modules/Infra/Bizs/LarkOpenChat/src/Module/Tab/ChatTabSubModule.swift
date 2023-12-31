//
//  ChatTabSubModule.swift
//  LarkOpenChat
//
//  Created by 赵家琛 on 2021/6/16.
//

import Foundation
import LarkModel
import LarkBadge
import UIKit
import LarkOpenIM

open class ChatTabSubModule: Module<ChatTabContext, ChatTabMetaModel> {
    open var type: ChatTabType {
        assertionFailure("need be override")
        return .unknown
    }

    /// 顶部区域是否可被导航栏以及页签栏遮挡
    /// true: 可显示区域位于页签栏底部
    @available(*, deprecated, message: "old desgin")
    open var shouldDisplayContentTopMargin: Bool {
        return true
    }

    /// 内存中维护的总页签视图数超过阀值时是否可删除
    /// true: 可删除
    @available(*, deprecated, message: "old desgin")
    open var supportLRUCache: Bool {
        return true
    }

    /// subModule 初始化后提供给业务方时机去做额外逻辑
    open func setup(_ contextModel: ChatTabContextModel) {}

    /// tab 是否允许可见
    open func checkVisible(metaModel: ChatTabMetaModel) -> Bool { return true }

    /// tab 数据预处理
    open func preload(metaModel: ChatTabMetaModel) {}

    /// 跳转对应 tab
    open func jumpTab(model: ChatJumpTabModel) {}

    @available(*, deprecated, message: "old desgin")
    open func getContent(metaModel: ChatTabMetaModel, chat: Chat) -> ChatTabContentViewDelegate? {
        assertionFailure("need be override")
        return nil
    }

    /// 展示 tab 添加入口
    open func getChatAddTabEntry(_ addTabContext: ChatTabContextModel) -> ChatAddTabEntry? {
        return nil
    }

    /// 自定义添加 Tab
    open func beginAddTab(metaModel: ChatAddTabMetaModel) {}

    /// 自定义页签管理数据模型
    open func getTabManageItem(_ metaModel: ChatTabMetaModel) -> ChatTabManageItem? {
        assertionFailure("need be override")
        return nil
    }

    /// 自定义页签名
    open func getTabTitle(_ metaModel: ChatTabMetaModel) -> String {
        assertionFailure("need be override")
        return ""
    }
    
    /// 页签图片
    open func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        assertionFailure("need be override")
        return .image(UIImage())
    }

    /// 页签 badge path
    open func getBadgePath(_ metaModel: ChatTabMetaModel) -> Path? {
        return nil
    }

    /// 点击对应Tab上报的埋点信息
    /// return nil: 无需上报
    open func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
        return nil
    }

    /// 进入会话时上报的埋点信息
    open func getFirstScreenParams(_ metaModels: [ChatTabMetaModel]) -> [AnyHashable: Any] {
        return [:]
    }
}

/// Tab 页签管理数据模型
public struct ChatTabManageItem {
    public let name: String
    public let tabId: Int64
    public let canBeDeleted: Bool /// 是否可删除
    public let canEdit: Bool ///  是否可更新
    public let canBeSorted: Bool /// 是否可排序
    public let imageResource: ChatTabImageResource
    public let count: Int?
    public let badgePath: LarkBadge.Path?
    
    public init(name: String,
                tabId: Int64,
                canBeDeleted: Bool,
                canEdit: Bool,
                canBeSorted: Bool,
                imageResource: ChatTabImageResource,
                count: Int? = nil,
                badgePath: LarkBadge.Path? = nil
    ) {
        self.name = name
        self.tabId = tabId
        self.canBeDeleted = canBeDeleted
        self.canEdit = canEdit
        self.canBeSorted = canBeSorted
        self.imageResource = imageResource
        self.count = count
        self.badgePath = badgePath
    }
}
