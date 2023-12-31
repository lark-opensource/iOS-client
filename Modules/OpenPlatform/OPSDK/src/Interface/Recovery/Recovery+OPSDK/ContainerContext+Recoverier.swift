//
//  ContainerContext+Recoverier.swift
//  OPSDK
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import LarkOPInterface
import LKCommonsLogging

/// 错误恢复框架针对开放应用的便捷入口

private let logger = Logger.oplog(OPContainerContext.self, category: "OPSDKRecoverier")


extension OPContainerContext {

    /// 帮助ContainerContext创建一个属于自己的错误恢复器Recoverier
    func createRecoverier() -> Recoverier? {
        // 根据uniqueID获取container
        guard let container = OPApplicationService.current.getContainer(uniuqeID: uniqueID) else {
            return nil
        }
        // 开放应用层，错误恢复框架的RecoverableErrorHandler由上层各个具体的容器去实现
        // 如果目标容器没有实现RecoverableErrorHandler协议，则认为目标类型容器没有接入错误恢复框架
        // 不予处理
        guard let handler = container as? RecoverableErrorHandler else {
            logger.warn("target container does not confirm to protocol RecoverableErrorHandler. Can not get a recoverier")
            return nil
        }

        return Recoverier(handler: handler)
    }

    /// 对Recoverier中的handleError方法的一层封装，提供了更加适合开放应用使用的入口
    /// 调用该接口会自动将uniqueID设置进context的userInfo中
    public func handleError(
        with error: OPError,
        scene: RecoveryScene,
        contextUpdater: ((RecoveryContext)->Void)? = nil) {
        // 如果context没有recoverier对象，说明对应的容器没有实现RecoverableErrorHandler协议，assert并不予处理
        guard let recoverier = recoverier else {
            assertionFailure("target container does not confirm to protocol RecoverableErrorHandler. Can not get a recoverier")
            return
        }

        logger.info("OPSDK try recovery with error: \(error), uniqueID: \(uniqueID)")

        recoverier.handleError(with: error) { [weak self] context in
            // 设置uniqueID
            context.uniqueID = self?.uniqueID
            // 设置错误发生的场景
            context.recoveryScene = scene
            if let contextUpdater = contextUpdater {
                contextUpdater(context)
            }
        }
    }
}
