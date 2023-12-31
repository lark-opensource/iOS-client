//
//  AutoLoginService.swift
//  LarkAccountInterface
//
//  Created by Bytedance on 2022/12/6.
//

import Foundation

#if DEBUG || BETA || ALPHA
/// QA、单测需求：自动登录能力
public protocol AutoLoginService {
    /// 给定账号、密码、user_id进行登录 + 切换到指定租户
    func autoLogin(account: String, password: String, userId: String?, onSuccess: @escaping () -> Void)
}
#endif
