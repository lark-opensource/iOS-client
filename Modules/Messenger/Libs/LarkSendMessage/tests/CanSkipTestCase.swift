//
//  CanSkipTestCase.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/24.
//

import XCTest
import Foundation
import LarkSDKInterface // UserGeneralSettings
import LarkContainer // InjectedSafeLazy

/// 除AAAPreTestUnitTest外的case都应该继承此类，用于从Settings下发黑名单，跳过一些异常case的执行
class CanSkipTestCase: XCTestCase {
    /// 如果登陆失败，直接跳过所有case执行
    static var allCase: Bool = false
    @InjectedSafeLazy private var userGeneralSettings: UserGeneralSettings

    /// 单测执行前，会优先执行本方法
    override func setUp() {
        super.setUp()

        // 检查当前case是否在黑名单内
        guard let className = NSStringFromClass(Self.self).split(separator: ".").last else { return }
        guard CanSkipTestCase.allCase || self.userGeneralSettings.skipTestConfig.value.allCase || self.userGeneralSettings.skipTestConfig.value.caseNames.contains(String(className)) else { return }

        // 进行方法交换，把新增的测试case都交换成空实现
        var count: UInt32 = 0; if let methods = class_copyMethodList(Self.self, &count) {
            for i in 0..<count {
                // 没有获取到函数名 || 函数名不以test开头，不进行处理
                let name = method_getDescription(methods[Int(i)]).pointee.name?.description ?? ""; if name.isEmpty || !name.hasPrefix("test") { continue }
                // 把实现替换为空实现：无参，无返回值
                let block = { () -> Swift.Void in return }
                let castedBlock: AnyObject = unsafeBitCast( block as @convention(block) () -> Swift.Void, to: AnyObject.self)
                method_setImplementation(methods[Int(i)], imp_implementationWithBlock(castedBlock))
            }
        }
    }
}
