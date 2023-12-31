//
//  QuotaAlertService.swift
//  SpaceInterface
//
//  Created by bupozhuang on 2021/3/31.
//

import Foundation

public enum QuotaAlertType: Int {
    // 租户容量弹出
    case upload = 0
    case translate = 1
    case makeCopy = 2
    case saveToSpace = 3
    case createByTemplate = 4
    case saveAsTemplate = 5
    // 用户容量
    case userQuotaLimited = 6
    case cannotEditFullCapacity = 7
    case bigFileUpload = 8
    case bigFileToCopy = 9
    case bigFileSaveToSpace = 10
}

public protocol QuotaAlertService {
    // 租户容量提示
    func showQuotaAlert(type: QuotaAlertType, from: UIViewController)
    // 用户容量提示
    // 如果是上传文件到文档，需要传mountNodeToken和mountPoint, 其他情况传nil
    // mountNodeToken: 文档token
    // mountPoint: 挂载点，比如doc
    func showUserQuotaAlert(mountNodeToken: String?, mountPoint: String?, from: UIViewController)
    var enableUserQuota: Bool { get }
    var enableTenantQuota: Bool { get }
}
