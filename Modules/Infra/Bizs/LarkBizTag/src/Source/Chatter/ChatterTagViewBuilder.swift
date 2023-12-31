//
//  File.swift
//  LarkBizTag
//
//  Created by 白镜吾 on 2022/11/22.
//

/// https://bytedance.feishu.cn/docs/doccnMQQWw8yCe0tH9SkruSN5zf#4Qbyvn
import Foundation
public final class ChatterTagViewBuilder: TagViewBuilder {

    /// Chatter 标签互斥约束
    ///
    /// * Chatter Tag 展示优先级：个人状态标签 > 群内身份标签 > 机器人/组织身份标签
    /// * 1. 个人状态
    /// *   a. 假勤状态标签中：【请假】与【勿扰】不同时展示，【请假】时不展示【勿扰】
    /// *   b. 组织账号状态标签中：【未激活】、【已暂停 / 冻结】、【已离职】不同时展示
    /// *   注：假勤状态标签 与 组织账号状态标签 不同时展示
    /// * 2. 群内身份
    /// *   a. 【群主】和【群管理员】不同时展示
    /// * 3. 组织身份
    /// *   a. 群内不展示行政组织架构中的组织【管理员】及【超级管理员】标签
    /// *   b. 家校场景群不展示【外部】，【外部】与【班主任/老师】不同时展示，【班主任】>【老师】
    public override var mutexTags: [[TagType]] {
        return customMutexTags ??
        [
            [.unregistered, .isFrozen, .onLeave, .doNotDisturb],
            [.groupOwner, .groupAdmin],
            [.relation, .connect, .external]
        ]
    }

    /// 机器人
    public func isRobot(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .robot)
        return self
    }

    /// 星标联系人
    public func isSpecialFocus(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .specialFocus)
        return self
    }

    /// 免打扰，用在除密聊chat头部以外的地方
    public func isDoNotDisturb(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .doNotDisturb)
        return self
    }

    /// 请假
    public func isOnLeave(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .onLeave)
        return self
    }

    /// 账号冻结
    public func isFrozen(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .isFrozen)
        return self
    }

    /// 未注册
    public func isUnregistered(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .unregistered)
        return self
    }

    /// 群主
    public func isGroupOwner(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .groupOwner)
        return self
    }

    /// 群管理员
    public func isGroupAdmin(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .groupAdmin)
        return self
    }

    /// 团队负责人
    public func isTeamOwner(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .teamOwner)
        return self
    }

    /// 团队管理员
    public func isTeamAdmin(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .teamAdmin)
        return self
    }

    /// 团队成员
    public func isTeamMember(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .teamMember)
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
