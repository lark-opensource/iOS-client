//
//  EntityParametersConfig.swift
//  LarkMessengerInterface
//
//  Created by ByteDance on 2022/11/3.
//

import Foundation

// MARK: - Condition
/// 把转发目标按“租户”维度划分
/// all: 不区分是否内外租户
/// inner: 仅展示内部用户
/// outer: 仅展示外部用户
public enum TenantCondition: String, Codable {
    case all
    case inner
    case outer
}

/// 把转发目标按“在职”维度划分
public enum ResignCondition: String, Codable {
    /// 不区分是否在职
    case all
    /// 仅展示离职用户
    case resigned
    /// 仅展示在职用户
    case unresigned
}

/// 把转发目标按“自己”维度划分
/// all: 不区分是否是自己
/// me: 仅展示自己
/// other: 仅展示他人
public enum SelfCondition: String, Codable {
    case all
    case me
    case other
}

/// 是否是管理员, 例如是否是我管理的群组, 是否是我的文档
public enum OwnerCondition: String, Codable {
    /// 不区分是否是管理员
    case all
    /// 仅展示我管理的
    case ownered
}

/// 是否关闭以人搜群功能
public enum ChatSearchByUserCondition: String, Codable {
    /// 开启
    case all
    /// 关闭以人搜群功能
    case closeSearchByUser
}

/// 把转发目标按“聊过”维度划分
/// all: 不区分是否聊过天
/// talked: 仅展示聊过
/// untalked: 仅展示未聊过
public enum TalkCondition: String, Codable {
    case all
    case talked
    case untalked
}

/// 把转发目标按“群聊类型”维度划分
/// all: 不区分会话类型
/// normal: 仅展示普通群聊
/// thread: 仅展示话题群/话题模式群
public enum GroupChatTypeCondition: String, Codable {
    case all
    case normal
    case thread
}

/// 按“密盾”维度划分
public enum ShieldCondition: String, Codable {
    /// 不区分会话类型
    case all
    /// 仅展示密盾类型
    case shield
    /// 仅展示非密盾类型
    case noShield
}

/// “是否加入”维度划分
public enum JoinCondition: String, Codable {
    /// 不区分是否加入
    case all
    /// 仅展示加入的
    case joined
    /// 仅展示未加入的
    case unjoined
}

/// "公开" "私有"维度划分
public enum PublicTypeCondition: String, Codable {
    ///  不区分是否公开
    case all
    ///  仅公开类型
    case `public`
    ///  仅私有类型
    case `private`
}

/// 把转发目标按“话题类型”维度划分
/// all: 不区分话题类型
/// normal: 仅展示普通话题
/// message: 仅展示消息话题
public enum ThreadTypeCondition: String, Codable {
    case all
    case normal
    case message
}

/// 是否是冻结的实体, 例如冻结群(解散但保留的群)
public enum FrozenCondition: String, Codable {
    /// 不区分是否冻结
    case all
    /// 不包含被冻结的实体
    case noFrozened
}

/// 是否是加密的实体, 例如密聊(目前仅使用于群聊)
public enum CryptoCondition: String, Codable {
    /// 不区分是否加密
    case all
    /// 不包含被加密的实体
    case normal
    /// 仅包含被加密的实体
    case crypto
}

/// 是否外部好友, 外部(租户)联系人 = 外部好友 + 关联组织用户
public enum ExternalFriendCondition: String, Codable {
    /// 不区分是否好友
    case all
    /// 不包含外部好友
    case noExternalFriend
}

/// 是否是关联组织所属实体
public enum RelatedOrganizationCondition: String, Codable {
    /// 包含所有实体
    case all
    /// 仅属于关联组织的
    case belongRelatedOrganization
}

/// 归属于用户范围
public enum BelongUserCondition {
    /// 不限时所属人, 搜索全部人员的内容
    case all
    /// 搜索指定所属人的内容
    case belong([String])
}

/// 归属于群范围
public enum BelongChatCondition {
    /// 不限时所属群, 搜索全部群组的内容
    case all
    /// 搜索指定所属群的内容
    case belong([String])
}

/// 归属于用户范围
public enum TimeRangeCondition {
    /// 不限时
    case all
    /// 指定搜索时间范围, 第一个为开始时间, 第二个为结束时间
    /// nil, nil 时, 为全部时间
    /// nil, b, 为b时间之前
    /// a, nil, 为a时间之后
    case range(Int64?, Int64?)
}

/// 是否仅搜索存在企业邮箱的用户
public enum ExistsEnterpriseEmailCondition: String, Codable {
    /// 不区分是否存在企业邮箱
    case all
    /// 仅搜索存在企业邮箱的用户
    case onlyExistsEnterpriseEmail
}

// MARK: - Properties configuration
public protocol TenantConfigurable {
    var tenant: TenantCondition { get set }
}

public protocol ResignConfigurable {
    var resign: ResignCondition { get set }
}

public protocol SelfConfigurable {
    var selfType: SelfCondition { get set }
}

public protocol OwnerConfigurable {
    var owner: OwnerCondition { get set }
}

public protocol TalkConfigurable {
    var talk: TalkCondition { get set }
}

public protocol GroupChatTypeConfigurable {
    var chatType: GroupChatTypeCondition { get set }
}

public protocol ShieldConfigurable {
    var shield: ShieldCondition { get set }
}

public protocol ChatJoinConfigurable {
    var join: JoinCondition { get set }
}

public protocol PublicTypeConfigurable {
    var publicType: PublicTypeCondition { get set }
}

public protocol ThreadTypeConfigurable {
    var threadType: ThreadTypeCondition { get set }
}

public protocol FrozenConfigurable {
    var frozen: FrozenCondition { get set }
}

public protocol BelongUserConfigurable {
    var belongUser: BelongUserCondition { get set }
}

public protocol BelongChatConfigurable {
    var belongChat: BelongChatCondition { get set }
}

public protocol TimeRangeConfigurable {
    var timeRange: TimeRangeCondition { get set }
}
