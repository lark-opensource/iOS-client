//
//  CommentPluginType+Ext.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/27.
//  


import Foundation
import SKFoundation
import SpaceInterface
import SKCommon

extension CommentPluginType {
    
    func canSupportInviteUser(_ docsInfo: DocsInfo?) -> Bool {
        guard let docsInfo = docsInfo else {
            DocsLogger.error("dodocsInfo is nil", component: LogComponents.comment)
            return false
        }
        guard docsInfo.isInCCMDocs else {
            // 小程序不支持
            return false
        }
        let types: [DocsType] = [.doc, .docX, .sheet, .bitable, .mindnote, .minutes, .slides]
        return types.contains(docsInfo.inherentType)
    }
}
