//
//  DocsIconError.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/30.
//

import Foundation

enum DocsIconError: LocalizedError {
    // 图标mate解析失败
    case iconInfoParseError
    // icon需要下载
    case iconInfoNeedDownload(info: DocsIconInfo)

    var errorDescription: String? {
        switch self {
        case .iconInfoParseError:
            return "icon info parse error"
        case .iconInfoNeedDownload(info: _):
            return "icon Info Need Download"
        }
    }
}
