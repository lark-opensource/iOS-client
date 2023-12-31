//
//  PermissionRequest.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
// 依赖 FileBizDomain
import LarkSecurityComplianceInterface

// MARK: Entity 定义
extension PermissionRequest {
    public enum Entity: Equatable {
        /// DriveSDK 面向 CCM 外提供能力的业务域，有需要参与鉴权的特殊字段通过关联属性传递
        public enum DriveSDKPermissionDomain: Equatable {
            /// IM 内附件预览
            case imFile
            /// 开放平台小程序内附件预览
            case openPlatformAttachment
            /// 日历内附件预览
            case calendarAttachment
            /// 邮箱内附件预览
            case mailAttachment
        }

        /// CCM 业务域内使用，Space 上传校验等没有 token 的场景，token 传空字符串
        case ccm(token: String, type: DocsType, parentMeta: SpaceMeta? = nil)
        case driveSDK(domain: DriveSDKPermissionDomain, fileID: String)
    }
}

// MARK: Operation 定义
extension PermissionRequest {
    /// 业务内需要鉴权的操作点位
    /// 点位不与具体的业务域挂钩，即不应该存在 ccmCopy、imCopy，统一用 copy
    /// 点位可能与具体的场景挂钩，即可能存在 download、downloadAttachment (文档附件内下载)
    public enum Operation: Equatable {
        /// 导出
        case export
        /// 阅读(内容和标题)
        case view
        /// 预览文档标题，谨慎使用
        case perceive
        /// 预览文档内容，谨慎使用
        case preview
        /// 编辑
        case edit
        /// 内容复制
        case copyContent
        /// 创建副本
        case createCopy
        /// 文件上传
        case upload
        /// 文件下载
        case download
        /// IM 文件保存特化操作
        case save
        /// 用其他应用打开
        case openWithOtherApp
        /// 删除
        case delete
        /// 文档内附件下载
        case downloadAttachment
        /// 文档内附件上传
        case uploadAttachment
        /// 可评论
        case comment
        /// 管理协作者，容器或单页面
        case manageCollaborator
        ///  公共权限设置, 拥有容器FA或单页面FA都算有权限
        case managePermissionMeta
        /// 创建子节点
        case createSubNode
        /// 删除实体
        case deleteEntity
        /// 邀请fa协作者 -- 容器级别
        case inviteFullAccess
        /// 邀请可编辑协作者 -- 容器级别
        case inviteEdit
        /// 邀请可阅读协作者 -- 容器级别
        case inviteView
        /// 邀请fa协作者 -- 页面级别
        case inviteSinglePageFullAccess
        /// 邀请可编辑协作者 -- 页面级别
        case inviteSinglePageEdit
        /// 邀请可阅读协作者 -- 页面级别
        case inviteSinglePageView
        /// 被移动
        case moveThisNode
        /// 移动到子节点
        case moveSubNode
        /// 移动到本节点下
        case moveToHere
        /// 谁能快捷访问无权限的引用文档和快捷申请权限
        case applyEmbed
        /// 管理协作者 -- 容器级别
        case manageContainerCollaborator
        ///  公共权限设置 -- 容器级别
        case manageContainerPermissionMeta
        /// 管理协作者 -- 页面级别
        case manageSinglePageCollaborator
        /// 公共权限设置 -- 页面级别
        case manageSinglePagePermissionMeta
        /// 密级可见
        case secretLabelVisible
        /// 密级修改
        case modifySecretLabel
        /// 是否容器FA
        case isContainerFullAccess
        /// 是否是单页面FA
        case isSinglePageFullAccess
        /// 能否查看文档协同信息
        case viewCollaboratorInfo
        /// 重命名版本 & 创建版本
        case manageVersion
        /// 删除版本
        case deleteVersion
        /// 对外分享，管控权限设置的开关调整
        case shareToExternal
        /// 更新 Base 时区信息，preview + FA
        case updateTimeZone
        /// Drive 转在线文档
        case importToOnlineDocument
        /// sheet子表tab拖拽移动，与编辑权限相关
        case moveSheetTab
        // 这两个操作等价
        /// 是容器 FA 或单页面 FA
        public static let isFullAccess = Operation.managePermissionMeta
        /// Drive 保存到本地, 与用其他应用打开等价
        public static let saveFileToLocal = Operation.openWithOtherApp

        public var isOfflineEnabled: Bool {
            switch self {
            case .view, .copyContent, .moveSheetTab:
                return true
            default: return false
            }
        }
    }
}

// MARK: BizDomain 定义
extension PermissionRequest {
    /// 业务域的上下文信息，主要对接安全 SDK 所需的入参
    public enum BizDomain: Equatable {
        // 对应 CCMEntity
        case customCCM(fileBizDomain: FileBizDomain)
        // 对应 IMFileEntity
        case customIM(fileBizDomain: FileBizDomain,
                      senderUserID: Int64? = nil,
                      senderTenantID: Int64? = nil,
                      msgID: String? = nil,
                      fileKey: String? = nil,
                      chatID: Int64? = nil,
                      chatType: Int64? = nil)

        // 默认 CCM 业务使用
        public static var ccm: Self { .customCCM(fileBizDomain: .ccm) }
        // 对应 CalendarEntity，但日历场景目前还没有仔细梳理完，暂时仍继续使用 CCMEntity + calendar domain
        public static var calendar: Self { .customCCM(fileBizDomain: .calendar) }
        // 小程序等没有接入条件访问控制的场景， 安全 SDK 要求 FileBizDomain 用 unknown
        public static var openPlatform: Self { .customCCM(fileBizDomain: .unknown) }
        // IM 内文件预览场景，目前安全 SDK `不允许` 多传参数，只在特定的操作场景才传
        public static var im: Self { .customIM(fileBizDomain: .im) }
    }
}


// 因为 Request 定义在 SpaceInterface，而权限代码在 SKPermission 内，为了让 config 只在权限内可用，暂时通过一个空 protocol 传递
/// 豁免规则配置，空定义，业务方不需要关注
public protocol PermissionExemptConfig {}

/// 一些额外的需要业务方传入的上下文信息
public struct PermissionExtraInfo: Equatable {
    // 目前仅 CCM 业务内在 DLP 鉴权时需要使用
    // 不耦合进 Entity 是因为业务方大概率在构造 UserPermissionService 时无法确定此时的 tenantID，暂时只能后续拿到了再更新进 UserPermissionService
    /// entity 所属的 tenantID
    public var entityTenantID: String?
    
    public var overrideDLPMeta: SpaceMeta?

    public init(entityTenantID: String? = nil,
                dlpMeta: SpaceMeta? = nil) {
        self.entityTenantID = entityTenantID
        self.overrideDLPMeta = dlpMeta
    }

    public static var `default`: PermissionExtraInfo {
        PermissionExtraInfo()
    }
}

/// 发起一次权限 SDK 请求的参数集合
public struct PermissionRequest {
    public let entity: Entity
    public let operation: Operation
    public let bizDomain: BizDomain
    public let extraInfo: PermissionExtraInfo
    public let exemptConfig: PermissionExemptConfig?
    /// 日志定位用
    public let traceID: String
    /// CCM 内场景，使用 token + type 初始化
    public init(token: String,
                type: DocsType,
                operation: Operation,
                bizDomain: BizDomain,
                tenantID: String?) {
        let extraInfo = PermissionExtraInfo(entityTenantID: tenantID)
        self.init(entity: .ccm(token: token, type: type),
                  operation: operation,
                  bizDomain: bizDomain,
                  extraInfo: extraInfo)
    }

    /// DriveSDK 场景，使用 driveSDKDomain + fileID 初始化
    public init(driveSDKDomain: Entity.DriveSDKPermissionDomain,
                fileID: String,
                operation: Operation,
                bizDomain: BizDomain) {
        self.init(entity: .driveSDK(domain: driveSDKDomain, fileID: fileID),
                  operation: operation,
                  bizDomain: bizDomain)
    }

    public init(entity: Entity,
                operation: Operation,
                bizDomain: BizDomain,
                extraInfo: PermissionExtraInfo = .default) {
        self.entity = entity
        self.operation = operation
        self.bizDomain = bizDomain
        self.extraInfo = extraInfo
        self.exemptConfig = nil
        traceID = UUID().uuidString
    }

    /// 限权限模块内部使用，禁止业务方直接调用
    public init(entity: Entity,
                operation: Operation,
                bizDomain: BizDomain,
                extraInfo: PermissionExtraInfo,
                exemptConfig: PermissionExemptConfig) {
        self.entity = entity
        self.operation = operation
        self.bizDomain = bizDomain
        self.extraInfo = extraInfo
        self.exemptConfig = exemptConfig
        traceID = UUID().uuidString
    }
}
