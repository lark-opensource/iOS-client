//
//  BTViewModel+Record.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/11.
//

import Foundation

extension BTViewModel {
    
    // 获取从快捷添加记录提交后跳转过来的 token
    var addToken: String? {
        get {
            if let url = dataService?.hostDocUrl, let addToken = url.queryParameters["add_token"] {
                return addToken
            }
            return nil
        }
    }
}
