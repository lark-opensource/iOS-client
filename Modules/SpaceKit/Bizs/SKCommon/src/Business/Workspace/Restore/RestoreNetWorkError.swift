//
//  RestoreNetWorkError.swift
//  SKCommon
//
//  Created by majie.7 on 2022/11/4.
//

import Foundation

// 恢复文档报错
public enum RestoreNetWorkError: Error, LocalizedError {
    case permissionError(failedInfo: DocsRestoreFailedInfo)
    case unknown    // 未知错误, 非预期错误建议找后端沟通
}
