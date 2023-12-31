//
//  BlockitForwardDelegate.swift
//  Blockit
//
//  Created by 王飞 on 2021/10/13.
//

import Foundation
import OPBlockInterface
import OPSDK
import LarkOPInterface
import ECOProbeMeta

/// 生命周期转发代理，OPBlock -> Blockit
class BlockitForwardDelegate: OPBlockContainerLifeCycleDelegate {

    weak var delegate: BlockitLifeCycleDelegate?
    weak var blockit: BlockitService?
    weak var container: OPBlockContainerProtocol?
    
    let beginDate = Date()
    let startMountTime: Date
    private let userId: String

    init(delegate: BlockitLifeCycleDelegate, blockit: BlockitService, startMountTime: Date, userId: String) {
        self.delegate = delegate
        self.blockit = blockit
        self.startMountTime = startMountTime
        self.userId = userId
    }


    /// creator 模式启动时容器内业务回传的参数
    /// - Parameter param: 回传的参数，里面会有的字段预期为 blockID 或 sourceMeta blockTypeID
    /// 如果回传 blockID 就代表这是一个服务端已经注册好的 block，可以直接使用，如果 sourceMeta blockTypeID 就代表这个 block 需要客户端主动到服务端创建
    func containerCreatorDidReady(param: [AnyHashable : Any], context: OPBlockContext) {
        let success: ([BlockInfo]) -> Void = { [self] in
            guard let info = $0.first else {
                self.containerCreatorDidCancel(context: context)
                return
            }
            self.delegate?.onBlockCreatorSuccess(info: info, context: context)
        }

        let failure: (Error) -> Void = { _ in
            self.containerCreatorDidCancel(context: context)
        }

        // request blockinfo
        if let blockID = param["blockID"] as? String {
            // get entity
            blockit?.getBlockEntity(blockIDs: [blockID],
                                    trace: context.trace,
                                    success: success,
                                    failure: failure)

        } else if let sourceMeta = param["sourceMeta"] as? String, let id = param["blockTypeID"] as? String {
            // create block and get entity
            let req = BlockInfoReq(blockTypeID: id, sourceMeta: sourceMeta)

            blockit?.createBlockID(param: req,
                                   success: { blockID in
                                    // get entity
                self.blockit?.getBlockEntity(blockIDs: [blockID],
                                             trace: context.trace,
                                             success: success,
                                             failure: failure)

                                   },
                                   failure: failure)
        } else {
            let error = NSError(domain: "setBlockInfo param exec", code: -1, userInfo: nil)
            failure(error)
        }

    }


    /// creator 模式启动失败
    func containerCreatorDidCancel(context: OPBlockContext) {
        delegate?.onBlockCreatorFailed(context: context)
    }

    /// Container 开始加载，此时 Container 处于 Loading 状态
    func containerDidLoad(container: OPContainerProtocol) {
        delegate?.onBlockLoadStart(context: container.containerContext.blockContext)
    }

    func containerBizTimeout(context: OPBlockContext) {
        let monitorCode = EPMClientOpenPlatformBlockitMountBizCode.blockit_biz_timeout
        OPMonitor(name: String.OPBlockitMonitorKey.eventName, code: monitorCode)
            .addCategoryValue("blockTypeId", context.uniqueID.identifier)
            .flush()
        delegate?.onBlockBizTimeout(context: context, error: OPError.error(monitorCode: OPMonitorCode(
            domain: monitorCode.domain,
            code: monitorCode.code,
            level: monitorCode.level,
            message: monitorCode.message
        )))
    }

    func containerBizSuccess(context: OPBlockContext) {
        delegate?.onBlockBizSuccess(context: context)
    }

    func containerShareStatusUpdate(context: OPBlockContext, enable: Bool) {
        delegate?.onBlockShareStatusUpdate(context: context, enable: enable)
    }

    func containerShareInfoReady(context: OPBlockContext, info: OPBlockShareInfo) {
        delegate?.onBlockShareInfoReady(context: context, info: info)
    }

    func tryHideBlock(context: OPBlockContext) {
        delegate?.tryHideBlock(context: context)
    }

    /// Container 加载完成，此时 Container 处于 Available 状态
    func containerDidReady(container: OPContainerProtocol) {
        let duration = Int(Date().timeIntervalSince(startMountTime) * 1000)
        OPMonitor(name: String.OPBlockitMonitorKey.eventName, code: OPBlockitMonitorCodeMountLaunch.success)
            .setResultTypeSuccess()
            .tracing(container.containerContext.blockContext.trace)
            .addMetricValue("duration", duration)
            .flush()
        let config = container.containerContext.containerConfig as? OPBlockContainerConfigProtocol
        let blockID = config?.blockInfo?.blockID
        BlockFirstBootRecordTool.recordBlockBoot(blockID: blockID, userId: userId)
        delegate?.onBlockLaunchSuccess(context: container.containerContext.blockContext)
    }

    /// Container 出现加载失败或运行时者崩溃，此时 Container 处于 Unavailable 状态
    func containerDidFail(container: OPContainerProtocol, error: OPError) {
        delegate?.onBlockLaunchFail(error: error, context: container.containerContext.blockContext)
    }

    /// Container 卸载，此时 Container 处于 Unavailable 状态
    func containerDidUnload(container: OPContainerProtocol) {
        delegate?.onBlockUnMount(context: container.containerContext.blockContext)
    }

    
    /// Container 销毁，全部内存回收，不可用无状态
    func containerDidDestroy(container: OPContainerProtocol) {
        delegate?.onBlockDestroy(context: container.containerContext.blockContext)
    }

    // MARK: - 可见性变化生命周期事件

    /// Container 从不可见状态变为可见状态，此时 Container 处于 Visible 状态
    func containerDidShow(container: OPContainerProtocol) {
        delegate?.onBlockShow(context: container.containerContext.blockContext)
    }

    /// Container 从可见状态变为不可见状态，此时 Container 处于 Invisible 状态
    func containerDidHide(container: OPContainerProtocol) {
        delegate?.onBlockHide(context: container.containerContext.blockContext)
    }


    // MARK: - 活跃性变化生命周期事件

    /// Container 从 active 状态变为 inactive 状态
    func containerDidPause(container: OPContainerProtocol) {
        delegate?.onBlockPause(context: container.containerContext.blockContext)
    }

    /// Container 从 inactive 状态变为 active 状态
    func containerDidResume(container: OPContainerProtocol) {
        delegate?.onBlockResume(context: container.containerContext.blockContext)
    }

    /// Container 包中的静态配置加载成功
    func containerConfigDidLoad(container: OPContainerProtocol, config: OPProjectConfig) {
        guard let config = config as? OPBlockProjectConfig else {
            
            return
        }
        delegate?.onBlockConfigLoad(config: config, context: container.containerContext.blockContext)
    }

    /// meta 及 pkg 已经更新完成
    func containerUpdateReady(info: OPBlockUpdateInfo, context: OPBlockContext) {
        delegate?.onBlockUpdateReady(info: info, context: context)
    }
}
