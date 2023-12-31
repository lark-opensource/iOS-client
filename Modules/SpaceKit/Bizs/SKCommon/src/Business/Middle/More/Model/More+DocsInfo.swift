//
//  More+DocsInfo.swift
//  SKCommon
//
//  Created by lizechuang on 2021/3/4.
//

import Foundation
import SKFoundation

public extension DocsInfo {
    var canShowAddToAction: Bool {
        if isFromWiki {
            return false
        }
        if isFromPhoenix {
            return false
        }
        return true
    }
    var canShowPinAction: Bool {
        if isFromPhoenix {
            return false
        }
        return true
    }
    var canShowStarAction: Bool {
        return !isFromPhoenix
    }
    var canShowSubscribeAction: Bool {
        
        if inherentType == .doc || inherentType == .docX || inherentType == .sheet {
            return true
        }
        return false
    }
    
    var canShowSubscribeCommentAction: Bool {
        // FG关闭、文档owner不显示
        guard LKFeatureGating.followCommentEnable else {
            return false
        }
        guard isOwner == false else {
            return false
        }
        return inherentType == .doc || inherentType == .docX
    }
    
    var canShowManuOfflineAction: Bool {
        if isFromPhoenix {
            return false
        }
        return true
    }

    var canShowDeleteAction: Bool {
        // VC中隐藏删除
        if let isVC = isInVideoConference, isVC == true {
            return false
        }
        // wiki移动端暂不支持删除
        if let wikiNodeState = wikiInfo?.wikiNodeState {
            guard wikiNodeState.isShortcut,
                  wikiNodeState.originIsExternal else {
                // 如果是 Wiki，仅本体在 space 的 wiki shortcut 支持 删除，否则需要隐藏
                return false
            }
        }
        // phx 需要单独的接口做删除操作，后续适配
        if isFromPhoenix {
            return false
        }
        return true
    }

    var canShowRenameAction: Bool {
        // 这里不判断类型是否支持重命名，在调用处判断
        return !isFromPhoenix
    }

    var canShowCopyAction: Bool {
        guard type.isSupportCopy else {
            return false
        }
        // 对版本创建文档需要额外 FG 判断
        if isVersion {
            guard UserScopeNoChangeFG.WWJ.copyEditionEnable else {
                return false
            }
        }
        if isFromWiki, isVersion == false {
            return false
        }
        if isFromPhoenix {
            return false
        }
        return true
    }
}
