//
//  LogDesensitize.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/7/26.
//

import Foundation

//
// 脱敏：输出日志去除敏感信息 session，username, 等等
//
protocol LogDesensitize {
    associatedtype T
    func desensitize() -> T
}
