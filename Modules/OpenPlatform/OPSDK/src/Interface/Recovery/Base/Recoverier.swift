//
//  Recoverier.swift
//  OPSDK
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import LarkOPInterface
import LKCommonsLogging

/// 错误恢复器，承担错误恢复的入口处理与封装
public final class Recoverier {

    /// 使用错误恢复机制的具体的业务方，需要遵循RecoverableErrorHandler协议
    public weak var handler: RecoverableErrorHandler?

    public init(handler: RecoverableErrorHandler) {
        self.handler = handler
    }

    private static let logger = Logger.oplog(Recoverier.self, category: "Recoverier")

    /// 当发生一个错误时，对其进行恢复
    public func handleError(with error: OPError, contextUpdater: ((RecoveryContext)->Void)? = nil) {
        // 封装RecoveryContext
        let recoveryContext = RecoveryContext(error: error)
        contextUpdater?(recoveryContext)

        // 根据上下文信息生成一组RecoveryActions
        guard let actions = handler?.handle(with: recoveryContext) else {
            Self.logger.warn("handler is not exists or handler does not conform to RecoverableErrorHandler Protocol")
            assertionFailure("handler is not exists or handler does not conform to RecoverableErrorHandler Protocol")
            return
        }

        // 顺序执行生成的一组RecoveryActions
        actions.forEach { action in
            action.executeAction(with: recoveryContext)
        }
    }
}
