//
//  BlockitService.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/10.
//

import EENavigator
import OPSDK
import OPBlockInterface
import ECOProbe
import OPFoundation

public typealias BlockitDelegate = BlockitLifeCycleDelegate & OPBlockHostProtocol & OPBlockWebLifeCycleDelegate

public protocol BlockitService: AnyObject {

    /// 生成 blockID
    /// - Parameters:
    ///   - domain: 业务域
    ///   - uuid: 对应到唯一的业务实体
    ///   - blockTypeID: 开发者后台生成 (套件业务)
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    func generateBlockID(domain: String,
                         uuid: String,
                         blockTypeID: String,
                         success: @escaping (String) -> Void,
                         failure: @escaping (Error) -> Void)

    // 上面的区别主要是上面的面向字节自己的第一方 block
    // 这个面向三方业务
    func createBlockID(param: BlockInfoReq,
                       success: @escaping (String) -> Void,
                       failure: @escaping (Error) -> Void)


    /// 快速生成本地的 blockID
    /// - Parameters:
    ///   - domain: 业务域
    ///   - uuid: 对应到唯一的业务实体
    ///   - blockTypeID: 开发者后台生成 (套件业务)
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    func generateBlockIDFromLocal(domain: String,
                                  uuid: String,
                                  blockTypeID: String,
                                  success: @escaping (String) -> Void,
                                  failure: @escaping (Error) -> Void)

    /// 根据blockID 获取 blockEntity
    /// - Parameters:
    ///   - trace: OPTraceProtocol
    ///   - blockIDs: blockIDs 数组
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    func getBlockEntity(blockIDs: [String],
                        trace: OPTraceProtocol,
                        success: @escaping ([BlockInfo]) -> Void,
                        failure: @escaping (Error) -> Void)
    
    /// 根据blockID 获取 blockEntity
    /// - Parameters:
    ///   - blockIDs: blockIDs 数组
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    func getBlockEntity(blockIDs: [String],
                        success: @escaping ([BlockInfo]) -> Void,
                        failure: @escaping (Error) -> Void)

    /// 生成 Block
    /// - Parameters:
    ///   - blockID: {domain}-{uuid}
    ///   - blockTypeID: 指定渲染方式，需要在平台注册
    ///   - sourceLink: 跳转+溯源
    ///   - sourceData: 提供渲染所需要的数据
    ///   - sourceMeta: 通过sourceMeta拉取sourceData进行渲染
    ///   - preview: 图片预览
    ///   - summary: 摘要信息预览
    /// - Returns: BlockInfo
    func generateBlock(blockID: String,
                       blockTypeID: String,
                       sourceLink: String,
                       sourceData: String?,
                       sourceMeta: String,
                       preview: String?,
                       summary: String) -> BlockInfo

    /// 根据原始数据，挂载一个 block 实例到宿主
    /// - Parameters:
    ///   - entity: block 的数据实体
    ///   - slot: 宿主容器，由业务方提供作为 block 的父视图
    ///   - data: 业务场景数据，比如工作台，消息等
    ///   - plugins: 业务自定义 API
    ///   - config: 初始化 block 涉及到的配置
    ///   - delegate: container 实例的生命周期代理
    func mountBlock(byEntity entity: OPBlockInfo,
                    slot: OPRenderSlotProtocol,
                    data: OPBlockContainerMountDataProtocol,
                    config: OPBlockContainerConfigProtocol,
                    plugins: [OPPluginProtocol],
                    delegate: BlockitDelegate)

    /// 根据 blockID，挂载一个 block 实例到宿主
    /// - Parameters:
    ///   - byID: blockID
    ///   - slot: 宿主容器，由业务方提供作为 block 的父视图
    ///   - data: 业务场景数据，比如工作台，消息等
    ///   - plugins: 业务自定义 API
    ///   - config: 初始化 block 涉及到的配置
    ///   - delegate: container 实例的生命周期代理
    func mountBlock(byID id: String,
                    slot: OPRenderSlotProtocol,
                    data: OPBlockContainerMountDataProtocol,
                    config: OPBlockContainerConfigProtocol,
                    plugins: [OPPluginProtocol],
                    delegate: BlockitDelegate)

    /// 用 creator 模式启动 block
    /// - Parameters:
    ///   - slot: 宿主的占位视图，作为 block view 的坑位
    ///   - config: 初始化 block 涉及到的配置
    ///   - data: 业务场景数据，比如工作台，消息等
    ///   - plugins: 业务自定义 API
    ///   - delegate: blockit 的业务代理
    func mountCreator(slot: OPRenderSlotProtocol,
                      config: OPBlockContainerConfigProtocol,
                      data: OPBlockContainerMountDataProtocol,
                      plugins: [OPPluginProtocol],
                      delegate: BlockitDelegate)
    
    /// 根据 blockitParam，创建block
    /// - Parameters:
    ///   - byParam: blockitParam 使用BlockitParamBuilder创建
    func mountBlock(byParam param: BlockitParam)


    /// 销毁对应 id 的 block
    /// - Parameter id: block 对应的 uniqueID，这里的 id 一定要是 mountBlock 时候的 id，严禁变更导致 hash 修改
    func unMountBlock(id: OPAppUniqueID)
    
    /// 通知 block show
    func onShow(id: OPAppUniqueID)
    
    /// 通知 block hide
    func onHide(id: OPAppUniqueID)

    /// 重新渲染当前页面
    func reloadPage(id: OPAppUniqueID)
    
    /// 获取当前业务宿主下全部的 block 信息
    func getAvailableBlockList(for param: BlockDetailReqParam,
                               success: @escaping ([BlockDetail]) -> Void,
                               failure: @escaping (Error) -> Void)

    /// 批量预安装block
    func triggerPreInstall(idList: [OPAppUniqueID])

    /// 生成 PropsView
    /// - Parameters:
    ///   - blockInfo: blockInfo
    ///   - config: UI 配置
    ///   - completeHandler: 结果回调，携带可空的PropsView
    @available(*, deprecated, message:"Use newer registerProps(blockInfo, config, extra, completeHandler")
    func registerProps(blockInfo: BlockInfo, config: PropsViewConfig?, completeHandler: @escaping (PropsView?) -> Void)

    func registerProps(blockInfo: BlockInfo, config: PropsViewConfig?, extra: [String: Any]?, completeHandler: @escaping (PropsView?) -> Void)

    /// 卸载 PropsView
    func unRegisterProps(blockInfo: BlockInfo)

    /// PropsView 显示时，需要调用
    func onShow(blockInfo: BlockInfo)

    /// PropsView 隐藏时 需要调用
    func onHide(blockInfo: BlockInfo)

    /// 调起 ActionPanel
    /// - Parameters:
    ///   - blockInfo: blockInfo
    ///   - context: 上下文，json格式的字符串，用于业务方透传一些数据
    ///   - from: controller
    @available(*, deprecated, message:"Use newer doAction(blockInfo, context, extra, from")
    func doAction(blockInfo: BlockInfo, context: String?, from: UIViewController)

    func doAction(blockInfo: BlockInfo, context: String?, extra: [String: Any]?, from: UIViewController)

    /// 调起 ActionPanel
    /// - Parameters:
    ///   - body: body
    ///   - from: controller
    func doAction<T: PlainBody>(_ body: T,
                                from: UIViewController,
                                prepare: ((UIViewController) -> Void)?,
                                animated: Bool)


    /// 生成Mention页面
    /// - Parameters:
    ///   - from: viewController
    ///   - context: 上下文
    ///   - complete: 拉起面板成功的callback
    ///   - cancel: 拉起面板取消的callback
    func doMention(from: UIViewController,
                   context: String?,
                   extra: [String: Any]?,
                   complete: MentionBody.MentionSelectedHandler?,
                   cancel: MentionBody.MentionCancelHandler?)

    /// 串联宿主trace和block trace
    /// - Parameter hostTrace: 宿主的trace
    /// - Parameter blockTrace: block生命周期内的trace
    func linkBlockTrace(hostTrace: OPTraceProtocol, blockTrace: OPTraceProtocol)
}

