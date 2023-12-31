//
//  CommentCACHelper.swift
//  SKCommon
//
//  Created by ByteDance on 2023/3/1.
//

import Foundation
import SKInfra
import SpaceInterface
import SKFoundation

/// 评论的`条件访问控制`权限
public struct CommentCACHelper {
    
    /// 评论文本可复制, 非妙计
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    public static func commentContentCanCopy(userCanCopy: Bool, docsInfo: DocsInfo) -> Bool {

        let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCopy,
                                                           fileBizDomain: .ccm,
                                                           docType: docsInfo.inherentType,
                                                           token: docsInfo.token)
        return result.allow && userCanCopy
    }
    
    /// 评论图片可预览, 非妙计
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    public static func commentImageCanPreview() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) else {
                return false
            }
            let request = PermissionRequest(token: "", type: .file, operation: .preview, bizDomain: .ccm, tenantID: nil)
            return permissionSDK.validate(request: request).allow
        } else {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFilePreView,
                                                               fileBizDomain: .ccm,
                                                               docType: .file,
                                                               token: nil)
            return result.allow
        }
    }
    
    /// 评论图片可下载, 非妙计
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    public static func commentImageCanDownload(userCanDownload: Bool) -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) else {
                return false
            }
            let request = PermissionRequest(token: "", type: .file, operation: .downloadAttachment, bizDomain: .ccm, tenantID: nil)
            return permissionSDK.validate(request: request).allow && userCanDownload
        } else {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmAttachmentDownload,
                                                               fileBizDomain: .ccm,
                                                               docType: .file,
                                                               token: nil)
            return result.allow && userCanDownload
        }
    }
}
