//
//  CollaboratorInviteViewController+Model.swift
//  SKCommon
//
//  Created by guoqp on 2020/9/27.
//

import Foundation
import SwiftyJSON
import SKFoundation

enum CollaboratorInviteMode: Int {
    case manage = 0  //正常邀请协助者 有分享权限，链接分享on.  title = "协作者管理"
    case sendLink  //无分享权限，链接分享on   title = "发送链接"
    case askOwner //无分享权限，链接分享off  title= "请求所有者共享"
}

public struct CollaboratorInviteModeConfig {
    var mode: CollaboratorInviteMode
    var linkShareEnable: Bool  // 链接共享开关
    var sharePermissionEnable: Bool //分享权限有无
    var isFromSendLink: Bool {
        //是否 从发送链接界面 进入 请求所有者共享页面，这对上报有用
        if mode == .askOwner, linkShareEnable {
            return true
        }
        return false
    }

    static func config(with publicPermisson: PublicPermissionMeta?,
                       userPermisson: UserPermissionAbility?,
                       isBizDoc: Bool) -> CollaboratorInviteModeConfig {
        
        var linkShareEnable: Bool = false // 链接共享开关
        var sharePermissionEnable: Bool = false //分享权限有无

        if let publicMeta = publicPermisson {
            linkShareEnable = (publicMeta.linkShareEntity == .close) ? false : true
        }
        if let userPermission = userPermisson {
            sharePermissionEnable = userPermission.canShare()
        }

        var type: CollaboratorInviteMode = .manage
        if isBizDoc {
            if sharePermissionEnable {
                type = .manage
            } else if linkShareEnable {
                type = .sendLink
            } else {
                type = .askOwner
            }
        }

        return CollaboratorInviteModeConfig(mode: type, linkShareEnable: linkShareEnable, sharePermissionEnable: sharePermissionEnable)
    }

    mutating func updateLayoutType(_ type: CollaboratorInviteMode) {
        self.mode = type
    }
}
