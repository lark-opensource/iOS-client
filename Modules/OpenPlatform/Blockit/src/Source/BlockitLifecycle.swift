//
//  BlockitLifecycle.swift
//  Blockit
//
//  Created by 王飞 on 2021/10/11.
//

import OPBlockInterface
import ECOInfra

public protocol BlockitLifeCycleDelegate: AnyObject {

    /// mountBlock 成功
    /// - Parameter container: 内部 block 的抽象容器
    func onBlockMountSuccess(container: OPBlockContainerProtocol, context: OPBlockContext)

    /// mountBlock 失败
    /// - Parameter error: 目前错误基本就几个，比如 id 网络请求失败，初始化参数错误
    func onBlockMountFail(error: OPError, context: OPBlockContext)

    /// block 设置为不可用状态，但是并没有销毁相关环境
    func onBlockUnMount(context: OPBlockContext)

    /// block 已经销毁
    func onBlockDestroy(context: OPBlockContext)


    /// block 加载开始，当前时机为容器创建完成，开始网络请求
    func onBlockLoadStart(context: OPBlockContext)

    /// block 配置解析完成
    /// - Parameter config: block 业务中的根目录 index.json 解析完成
    func onBlockConfigLoad(config: OPBlockProjectConfig, context: OPBlockContext)

    /// block 启动成功
    func onBlockLaunchSuccess(context: OPBlockContext)

    /// block 启动失败
    /// - Parameter error: 错误的信息，参照 OPBlockitMonitorCodeLaunch
    func onBlockLaunchFail(error: OPError, context: OPBlockContext)

    /// block 暂停
    func onBlockPause(context: OPBlockContext)

    /// block 重新运行
    func onBlockResume(context: OPBlockContext)

    /// block 可见状态
    func onBlockShow(context: OPBlockContext)

    /// block 不可见
    func onBlockHide(context: OPBlockContext)

    /// block 异步请求的 meta & pkg 下载完成
    func onBlockUpdateReady(info: OPBlockUpdateInfo, context: OPBlockContext)

    /// block 在 creator 模式下创建成功
    /// - Parameter info: block 对应的信息，使用该 info 即可以直接创建 block
    func onBlockCreatorSuccess(info: BlockInfo, context: OPBlockContext)

    /// block 在 creator 模式下创建失败
    /// 可能是业务侧主动取消，并不见得发生错误，关于 error 还有待商榷
    func onBlockCreatorFailed(context: OPBlockContext)

    /// Biz-level timeout
    /// The developer didn't call hideBlockLoading in certain seconds
    func onBlockBizTimeout(context: OPBlockContext, error: OPError)

    /// Biz-level render success
    func onBlockBizSuccess(context: OPBlockContext)

    /// Share enable state update
    func onBlockShareStatusUpdate(context: OPBlockContext, enable: Bool)

    /// Share info ready
    func onBlockShareInfoReady(context: OPBlockContext, info: OPBlockShareInfo)
    
    /// hide block
    func tryHideBlock(context: OPBlockContext)
}

public extension BlockitLifeCycleDelegate {

    func onBlockMountSuccess(container: OPBlockContainerProtocol, context: OPBlockContext) {}
    func onBlockMountFail(error: OPError, context: OPBlockContext) {}

    func onBlockUnMount(context: OPBlockContext) {}
    func onBlockDestroy(context: OPBlockContext) {}

    func onBlockLoadStart(context: OPBlockContext) {}
    func onBlockLoadEnd(context: OPBlockContext) {}

    func onBlockConfigLoad(config: OPBlockProjectConfig, context: OPBlockContext) {}

    func onBlockLaunchSuccess(context: OPBlockContext) {}
    func onBlockLaunchFail(error: OPError, context: OPBlockContext) {}

    func onBlockPause(context: OPBlockContext) {}
    func onBlockResume(context: OPBlockContext) {}

    func onBlockShow(context: OPBlockContext) {}
    func onBlockHide(context: OPBlockContext) {}

    func onBlockUpdateReady(info: OPBlockUpdateInfo, context: OPBlockContext) {}

    func onBlockCreatorSuccess(info: BlockInfo, context: OPBlockContext) {}
    func onBlockCreatorFailed(context: OPBlockContext) {}

    func onBlockBizTimeout(context: OPBlockContext, error: OPError) {}
    func onBlockBizSuccess(context: OPBlockContext) {}

    func onBlockShareStatusUpdate(context: OPBlockContext, enable: Bool) {}
    func onBlockShareInfoReady(context: OPBlockContext, info: OPBlockShareInfo) {}

    func tryHideBlock(context: OPBlockContext) {}
}
