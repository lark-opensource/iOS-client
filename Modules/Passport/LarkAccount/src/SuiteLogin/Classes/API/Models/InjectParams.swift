//
//  InjectParams.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/4/17.
//

import Foundation
import LKCommonsLogging

/*
 - pattern=空
 - 白板走设置姓名然后3选1
 - 非白板选择已有身份登录或者注册、加入
 - pattern=1
 - 白板走创建租户
 - 非白板选择已有身份登录或者注册、加入
 - pattern=2
 - 白板走创建小B
 - 非白板选择已有身份登录或者注册、加入
 - pattern=3
 - 白板走创建小B
 - 非白板选择已有身份登录
 */

/// Params injected outside SuiteLogin
class InjectParams {

    let logger = Logger.plog(InjectParams.self)

    var pattern: String?
    var regParams: [String: Any]?

    /// init
    /// - Parameters:
    ///   - pattern: createSimpleBDirectly is default value,
    ///   - regParams: currently set by UG
    init(pattern: String? = nil,
         regParams: [String: Any]? = nil) {
        self.pattern = pattern
        self.regParams = regParams
    }

    func addTo(params: [String: Any]) -> [String: Any] {
        var data: [String: Any] = [:]
        if let pattern = pattern {
            data[CommonConst.InjectKey.pattern] = pattern
        }

        if let regP = regParams {
            data[CommonConst.InjectKey.regParams] = regP.jsonString()
        }
        return params.merging(data) { (old, _) in
            logger.error("inject params key conflict not used")
            assertionFailure("inject params key conflict with SuiteLogin")
            return old
        }
    }

    func reset() {
        pattern = nil
        regParams = nil
    }
}
