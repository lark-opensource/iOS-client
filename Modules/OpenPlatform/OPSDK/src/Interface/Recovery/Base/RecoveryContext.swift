//
//  RecoveryContext.swift
//  OPSDK
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import LarkOPInterface

/// 记录一次错误恢复流程中的上下文信息，包括了执行该次错误恢复流程中需要用到的所有信息
@objcMembers
public final class RecoveryContext: NSObject {
    /// 此次恢复的是哪个错误
    public var recoveryError: OPError

    /// 上下文信息
    private var userInfo: [String: UserInfoValueWrapper] = [:]

    /// 将值设置进userInfo中
    public func setUserInfo(value: Any?, key: String, weakReference: Bool = true) {
        guard let value = value else {
            assertionFailure("value is nil")
            return
        }

        let wrapper = UserInfoValueWrapper(value: value, weakReference: weakReference)
        userInfo[key] = wrapper
    }

    /// 从userInfo中取值
    public func valueFromUserInfo(for key: String) -> Any? {
        guard let wrapper = userInfo[key] else {
            return nil
        }

        return wrapper.value
    }

    public init(error: OPError) {
        self.recoveryError = error
    }
}

private extension RecoveryContext {

    /// 对上下文中的值做一层包装
    class UserInfoValueWrapper {
        /// 对目标值是否是弱引用
        private let weakReference: Bool

        /// 弱引用，只有AnyObject类型才可以weak
        private weak var weakValue: AnyObject?
        /// 强引用
        private var strongValue: Any?

        init(value: Any, weakReference: Bool = true) {
            self.weakReference = weakReference
            if weakReference {
                // 这里必须使用as? 不要相信XCode中的警告
                weakValue = value as? AnyObject
            } else {
                strongValue = value
            }
        }

        /// 取得目标值
        var value: Any? {
            return weakReference ? weakValue : strongValue
        }
    }

}
