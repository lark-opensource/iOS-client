//
//  CCMDownloadPermissionDataSource.swift
//  SKCommon
//
//  Created by ByteDance on 2023/2/3.
//

import Foundation
import SKFoundation
import SpaceInterface

/*
public protocol CCMDownloadPermissionDataSource: AnyObject {
    /// 是否允许下载，目前用于评论中的图片
    func allowDownload() -> Bool
}

public extension CCMDownloadPermissionDataSource where Self: BaseJSService {
    
    func allowDownload() -> Bool {
        guard let docsInfo = model?.browserInfo.docsInfo else { return false }
        
        let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmAttachmentDownload,
                                                           fileBizDomain: .ccm,
                                                           docType: docsInfo.inherentType,
                                                           token: docsInfo.token)
        let cacAllow = result.allow
        let userAllow = model?.permissionConfig.userPermissions?.canDownload() ?? false
        return cacAllow && userAllow
    }
}
*/

// 评论图片下载按钮状态
@frozen
public enum CommentImageDownloadButtonState {
    case visible // 显示
    case grayed  // 置灰
    case hidden  // 隐藏
}

// 评论图片下载权限获取: 通用逻辑
public protocol CommentImageDownloadPermissionProvider: AnyObject {
    
    // FG 关闭时, 取该值
    func commentImageDownloadDefaultValue() -> Bool
    
    func requestCommentImageDownloadPermission(imageToken: String,
                                               service: CommentImagePermissionDataSource,
                                               completion: @escaping (CommentImageDownloadButtonState) -> Void)
}

public extension CommentImageDownloadPermissionProvider {
    
    func requestCommentImageDownloadPermission(imageToken: String,
                                               service: CommentImagePermissionDataSource,
                                               completion: @escaping (CommentImageDownloadButtonState) -> Void) {
        
        if UserScopeNoChangeFG.CS.commentImageUseDocAttachmentPermission {
            
            if let value = service.syncGetCommentImagePermission() {
                let state = getButtonState(value, token: imageToken)
                completion(state)
                return
            }
            
            service.asyncGetCommentImagePermission(token: imageToken) { [weak self] value in
                guard let self = self else {
                    completion(.hidden)
                    return
                }

                let state = self.getButtonState(value, token: imageToken)
                completion(state)
            }
        } else {
            let canDownload = commentImageDownloadDefaultValue()
            completion(canDownload ? .visible : .hidden)
        }
    }
    
    private func getButtonState(_ value: CommentImagePermission, token: String) -> CommentImageDownloadButtonState {
        let userCanDownload = value.canDownload
        let cacResult = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmAttachmentDownload,
                                                              fileBizDomain: .ccm,
                                                              docType: .file,
                                                              token: token)
        if (userCanDownload && cacResult.allow) || cacResult.validateSource == .fileStrategy {
            return cacResult.allow ? .visible : .grayed
        } else {
            return .hidden
        }
    }
    
    private func canDownloadAttachmentByCAC(token: String) -> Bool {
        DocPermissionHelper.checkPermission(.ccmAttachmentDownload,
                                            docType: .file,
                                            token: token,
                                            showTips: false,
                                            securityAuditTips: nil,
                                            hostView: nil)
    }
    
    /// `可下载`状态的初始值，用于FG兼容
    var commentImageCanDownloadInitValue: Bool? {
        if UserScopeNoChangeFG.CS.commentImageUseDocAttachmentPermission {
            return nil
        } else {
            return commentImageDownloadDefaultValue()
        }
    }
}
