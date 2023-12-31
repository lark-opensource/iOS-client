//
//  FeedTagViewBuilder.swift
//  LarkBizTag
//
//  Created by aslan on 2022/11/29.
//

import Foundation

/// https://bytedance.feishu.cn/docs/doccnMQQWw8yCe0tH9SkruSN5zf#4Qbyvn
public final class FeedChatTagViewBuilder: TagViewBuilder {

    /// 标签互斥约束
    public override var mutexTags: [[TagType]] {
        return customMutexTags ??
        [
            [.officialOncall, .robot],
            [.officialOncall, .oncallOffline, .oncall],
            [.officialOncall, .connect],
            [.officialOncall, .relation, .connect, .external]
        ]
    }

    /// 官方服务台
    public func isOfficial(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .officialOncall)
        return self
    }

    /// 值班号
    public func isOncall(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .oncall)
        return self
    }

    /// helpdesk offline
    public func isOncallOffline(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .oncallOffline)
        return self
    }

    /// 机器人
    public func isRobot(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .robot)
        return self
    }

    /// 全员
    public func isAllStaff(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .allStaff)
        return self
    }

    /// 部门
    public func isTeam(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .team)
        return self
    }

    /// 公开
    public func isPublic(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .public)
        return self
    }

    /// 密聊
    public func isCrypto(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .crypto)
        return self
    }

    /// 勿扰
    public func isDoNotDisturb(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .doNotDisturb)
        return self
    }

    /// 密聊免打扰
    public func isCryptoDoNotDisturb(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .cryptoDoNotDisturb)
        return self
    }

    /// 超大群
    public func isSuperChat(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .superChat)
        return self
    }

    /// 密盾聊
    public func isPrivateMode(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .isPrivateMode)
        return self
    }

    /// 账号冻结/暂停
    public func isFrozen(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .isFrozen)
        return self
    }

    /// 互通
    public func isConnected(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .connect)
        return self
    }

    /// 外部 [显示外部两个字]
    @available(*, deprecated, message: "This Api is Only Use For 'External', Please Use 'func addTag(with tagDataItem: TagDataItem) -> TagViewBuilder'")
    public func isExternal(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .external)
        return self
    }
}
