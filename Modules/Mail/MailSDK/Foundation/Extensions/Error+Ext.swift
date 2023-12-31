//
// Error+Ext.swift
// MailSDK
//
// Created by zhaoxiongbin on 2022/1/11.
//

import Foundation
import LarkRustClient

extension Error {
    /// 如果是RCError类型先尝试返回rust error code
    /// 否则，直接返回系统默认 NSError.code
    var mailErrorCode: Int {
        var errorCode: Int
        if let rcError = self as? RCError, case let .businessFailure(error) = rcError {
            // errorCode 是新版本的错误码，新版错误码 SDK 做了重定义。见 RustPB.Basic_V1_Auth_ErrorCode 枚举
            errorCode = Int(error.errorCode)
        } else {
            errorCode = (self as NSError).code
        }
        return errorCode
    }

    var isRequestTimeout: Bool {
        return (self as? URLError)?.code.rawValue == MailErrorCode.requestTimeout
    }

    var isRequestCanceled: Bool {
        return (self as? URLError)?.code.rawValue == MailErrorCode.requestCanceled
    }

    var debugMessage: String? {
      var debugMessage: String?
      if let rcError = self as? RCError, case let .businessFailure(error) = rcError {
        // errorCode 是新版本的错误码，新版错误码 SDK 做了重定义。见 RustPB.Basic_V1_Auth_ErrorCode 枚举
          debugMessage = String(error.debugMessage)
      } else {
          debugMessage = nil
      }
      return debugMessage
    }
}

extension Error {
    /// 脱敏错误日志信息，目前仅针对 `URLError` 特化处理
    var desensitizedMessage: String {
        if let err = self as? URLError {
            var errorInfo = err.errorUserInfo
            errorInfo.removeValue(forKey: "NSErrorFailingURLKey")
            errorInfo.removeValue(forKey: "NSErrorFailingURLStringKey")
            return "\(errorInfo)"
        } else {
            return "\(self)"
        }
    }
}

enum MailErrorCode {
    /// 请求超时
    static let requestTimeout: Int = -1001
    /// 请求取消
    static let requestCanceled: Int = -999
    /// Offline 模式
    static let offlineError: Int = 10008
    /// 网络出错
    static let networkError: Int = 10018
    /// 创建三方账号拒绝授权
    static let createTripartiteAccountReject: Int = 104002
    /// 创建三方账号地址重复
    static let createTripartiteAccountDuplicated: Int = 104003
    /// 创建三方账号取消操作
    static let createTripartiteAccountCancel: Int = 104004
    /// 搬家中，无法执行操作
    static let migrationReject: Int = 250304
    /// 删除文件夹，文件夹有子文件夹
    static let deleteFolderHasSubFolder: Int = 260000
    /// 删除文件夹，文件夹有邮件
    static let deleteFolderHasEmail: Int = 260001
    /// 拉取邮件列表，没有数据
    static let getMailListEmpty = 250401
    /// 草稿在其他设备被删除
    static let draftBeenDeleted = 104010
    /// 草稿在其他设备被发送
    static let draftBeenSent = 104011
    /// 目标地址含有外部地址且发信账号限制外发
    static let cantSendExternal = 104020
}
