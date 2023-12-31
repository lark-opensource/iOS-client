//
//  OpenStartPasswordVerifyResponseCode.swift
//  OPPlugin
//
//  Created by zhangxudong.999 on 2023/1/4.
//

import Foundation

enum OpenStartPasswordVerifyResponseCode: Int {
    /// 用户取消，验证失败
    case userCancel = 40101
    /// 密码错误，验证失败
    case passwordError = 40102
    /// 密码输入次数超限制，验证失败
    case retryTimeLimit = 40103
}
