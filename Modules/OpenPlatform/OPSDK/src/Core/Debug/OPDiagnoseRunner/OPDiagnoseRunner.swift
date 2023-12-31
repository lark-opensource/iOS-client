//
//  OPDiagnoseRunner.swift
//  OPSDK
//
//  Created by 尹清正 on 2021/2/18.
//

import Foundation
import LarkOPInterface
import LKCommonsLogging
import LarkContainer

fileprivate let logger = Logger.oplog(OPDiagnoseBaseRunner.self, category: "OPDiagnoseBaseRunner")

/// 所有DiagnoseRunner的抽象父类
@objcMembers
open class OPDiagnoseBaseRunner: NSObject {
    
    public let userResolver: UserResolver
    
    /// 校验器，用于校验当前runner是否为可用状态
    let runnerValidator: OPDiagnoseRunnerValidator

    /// 当前Runner所支持的权限环境
    public let permission: OPDiagnoseRunnerPermission

    /// 在初始化一个Runner时，外部必须要传入该runner所支持的权限环境
    public init(resolver: UserResolver, permission: OPDiagnoseRunnerPermission, validator:  OPDiagnoseRunnerValidator? = nil) {
        userResolver = resolver
        self.permission = permission
        self.runnerValidator = validator ?? OPDiagnoseRunnerBaseValidator()
    }

    /// 该方法为对外公开的方法，通过调用该方法来执行当前runner，该方法不可以被子类重写
    @objc public final func fire(with context: OPDiagnoseRunnerContext) {
        logger.info("start to fire EMADiagnoseRunner: \(Self.self)")
        // 判断runner是否可用
        guard runnerValidator.validate(runner: self) else {
            let err = OPError.diagnoseRunnerError(
                monitorCode: OPSDKMonitorCode.retained_resource_not_exists,
                message: "diagnose runner is not available",
                openMessage: "not available")
            logger.error("start to fire EMADiagnoseRunner: \(Self.self) fail")
            context.execCallback(withError: err)
            return
        }
        logger.info("start to fire EMADiagnoseRunner: \(Self.self) success")

        // 如果可用，则调用子类的实现方法来执行具体runner的逻辑
        self.exec(with: context)
    }

    /// 该方法为抽象方法，子类必须实现该方法，在该方法中提供runner具体的运行逻辑
    open func exec(with context: OPDiagnoseRunnerContext) {
        fatalError("function exec of EMADiagnoseBaseRunner must be overrided by subclass!")
    }
}
