//
//  RegisterError.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/12.
//

import Foundation

/// register时返回结果
public enum RegisterError {
    /// 没有错误
    case none
    /// 该任务提交数已达最大
    case tooManyTask
    /// 不支持此任务，目前只在iOS13以下提交ProcessingTask会报此错误
    case notSupport
    /// 其他错误
    case other
}
