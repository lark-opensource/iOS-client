//
//  IconError.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/14.
//

import Foundation

enum IconError: LocalizedError {
    // 图标下载为nil
    case downLoadIconNil
    // 图标下载url错误
    case downLoadIconUrlError
    // 图标下载url错误
    case emojiKeyChangeError
    
    var errorDescription: String? {
        switch self {
        case .downLoadIconNil:
            return "down load icon nil"
        case .downLoadIconUrlError:
            return "down Load Icon Url Error"
        case .emojiKeyChangeError:
            return "emoji Key Change Errorr"
        }
    }
}

