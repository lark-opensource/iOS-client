//
//  GetMessageErrorDefine.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2020/10/15.
//

import Swinject
import LKCommonsLogging
import LarkAccountInterface
import RxSwift

/// 接口定义 https://bytedance.feishu.cn/docs/doccnaSO7Huz3pAgz26hiWIFA3X#fwEjqT
struct GetMessageError {
    let code: NSInteger
    let errorMessage: String
    static let errorDomain = "GetMessageDetailFailed"
    /// 原始Error Key
    static let sourceErrorKey = "SourceErrorDescriptionKey"
    /// 依赖服务不可用
    static let serviceNotValid = GetMessageError(code: 42_306, errorMessage: "service is not valid")
    /// 获取消息详情失败
    static let getMessageFailed = GetMessageError(code: 42_305, errorMessage: "get message detail failed")
    /// triggercode 不合法
    static let triggercodeNotValid = GetMessageError(code: 42_302, errorMessage: "invalid triggerCode")
    /// triggercode 为空
    static let triggercodeIsEmpty = GetMessageError(code: 42_301, errorMessage: "triggerCode is empty")
    /// 转换为Error
    func toError(userInfo: [String: Any]? = nil) -> Error {
        var errUserInfo = userInfo ?? [String: Any]()
        errUserInfo[NSLocalizedDescriptionKey as String] = errorMessage
        return NSError(domain: GetMessageError.errorDomain,
                       code: code,
                       userInfo: errUserInfo)
    }
}
