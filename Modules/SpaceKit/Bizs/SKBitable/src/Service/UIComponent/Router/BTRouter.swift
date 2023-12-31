//
//  BTRouter.swift
//  SKBitable
//
//  Created by yinyuan on 2022/12/28.
//

import Foundation
import SKCommon
import SKResource

struct BTRouterResult {
    // 是否可以打开
    let canOpen: Bool
    // 如果不能打开, 错误提示（ nil 表示不需要提示）
    let tips: String?
}

/// Bitable 打开新页面跳转的逻辑都应收敛至此
final class BTRouter {
    
    /// 判断是否可以打开 BTAtModel 对应的文档
    static func canOpen(_ atInfo: BTAtModel, from hostDocsInfo: DocsInfo) -> BTRouterResult {
        guard !atInfo.token.isEmpty else {
            return BTRouterResult(canOpen: false, tips: nil)
        }
        if let url = URL(string: atInfo.link), URLValidator.isDocsVersionUrl(url) {
            // 目标链接是版本链接，可判定为不是同一篇文档
            return BTRouterResult(canOpen: true, tips: nil)
        }
        // 是否同一篇文档
        if hostDocsInfo.objToken == atInfo.token {
            return BTRouterResult(canOpen: false, tips: BundleI18n.SKResource.Doc_Normal_SamePageTip)
        }
        return BTRouterResult(canOpen: true, tips: nil)
    }
    
}
