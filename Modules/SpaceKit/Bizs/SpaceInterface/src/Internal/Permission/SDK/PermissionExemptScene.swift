//
//  PermissionExemptScene.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation

/// 定义有特殊豁免逻辑的场景
public enum PermissionExemptScene: CaseIterable, Equatable, Hashable {
    /// 对系统模板创建副本
    /// operation: .createCopy
    /// bizDomain: .ccm
    /// 豁免规则: 只判断 UserPermission
    case duplicateSystemTemplate
    /// 文档内使用模板 Banner 按钮是否 enable
    /// operation: .createCopy
    /// bizDomain: .ccm
    /// 豁免规则: 只判断 UserPermission 和条件访问控制
    case useTemplateButtonEnable
    /// Drive 附件 More 按钮的展示
    /// operation: .downloadAttachment
    /// bizDomain: ccm or im or calendar or mail
    /// 豁免规则: 只判断 UserPermission
    case driveAttachmentMoreVisable
    /// 文档内查看大图场景下载图片操作
    /// operation: .downloadAttachment
    /// bizDomain: ccm
    /// 豁免规则：只判断 DLP
    case downloadDocumentImageAttachmentWithDLP
    /// 预览 Space 文件夹
    /// operation: .view
    /// bizDomain: ccm
    /// 豁免规则: 只判断 UserPermission
    case viewSpaceFolder

    /// 文档内 DLP banner 是否需要展示
    /// operation: .shareToExternal
    /// bizDomain: ccm
    /// 豁免规则: 跳过 SecurityAudit admin 管控
    case dlpBannerVisable
}
