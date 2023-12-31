//
//  Blockit.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/10.
//

import LKCommonsLogging
import EENavigator
import LarkUIKit
import OPSDK
import OPBlockInterface
import Foundation
import LarkFeatureGating
import LarkOPInterface
import LarkSetting
import OPBlockInterface
import LarkContainer
import OPFoundation
import LarkStorage

public typealias BlockViewBuilder = (_ blockit: Blockit, _ blockInfo: BlockInfo, _ context: String?) -> UIView

public final class Blockit {

    public static let log = Logger.log(Blockit.self, category: "BlockitSDK")
    private let lock = MutexLock()

    /// 注册与 blockitEntity 关联的 propsView 和 callback
    private var propsViewMap = NSMapTable<BlockInfo, UIView>.strongToWeakObjects()
    private var propsUpdateHandlerMap = [BlockInfo: (PropsView?)->Void]()
    private var propsViewConfigMap = [BlockInfo: PropsViewConfig]()
    private var propsViewExtraMap = [BlockInfo: [String: Any]]()
    private static var blockViewBuilders = [String: BlockViewBuilder]()

    var forwardDelegates: [OPAppUniqueID: BlockitForwardDelegate] = [:]

    private let userResolver: UserResolver
    private let api: BlockitAPI
    private let syncMessageManager: BlockSyncMessageManager
    private let preLoadService: OPBlockPreUpdateProtocol

    private var userId: String {
        return userResolver.userID
    }

    private var useCacheFirst: Bool {
        let config: BlockEntityCacheConfig = userResolver.settings.staticSetting()
        return config.enable
    }

    private let componentUtils: BlockComponentUtils

    init(
        userResolver: UserResolver,
        api: BlockitAPI,
        syncMessageManager: BlockSyncMessageManager,
        preLoadService: OPBlockPreUpdateProtocol
    ) {
        self.userResolver = userResolver
        self.api = api
        self.syncMessageManager = syncMessageManager
        self.preLoadService = preLoadService
        self.componentUtils = BlockComponentUtils(
            blockWebComponentConfig: userResolver.settings.staticSetting(),
            apiConfig: userResolver.settings.staticSetting()
        )
    }
}

// MARK: - 接口 BlockitService

extension Blockit: BlockitService {

    /// 生成 blockID
    /// - Parameters:
    ///   - domain: 业务域
    ///   - uuid: 对应到唯一的业务实体
    ///   - blockTypeID: 开发者后台生成 (套件业务)
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    public func generateBlockID(domain: String,
                                uuid: String,
                                blockTypeID: String,
                                success: @escaping (String) -> Void,
                                failure: @escaping (Error) -> Void) {
        api.generateBlockID(domain: domain, uuid: uuid, blockTypeID: blockTypeID, success: success, failure: failure)
    }
    
    /// 快速生成本地的 blockID
    /// - Parameters:
    ///   - domain: 业务域
    ///   - uuid: 对应到唯一的业务实体
    ///   - blockTypeID: 开发者后台生成 (套件业务)
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    public func generateBlockIDFromLocal(domain: String,
                                  uuid: String,
                                  blockTypeID: String,
                                  success: @escaping (String) -> Void,
                                  failure: @escaping (Error) -> Void) {
        api.generateBlockID(
            domain: domain,
            uuid: uuid,
            blockTypeID: blockTypeID,
            isIdFromLocal: true,
            success: success,
            failure: failure
        )
    }

    /// 根据blockID 获取 blockEntity
    /// - Parameters:
    ///   - trace: OPTraceProtocol
    ///   - blockIDs: blockIDs 数组
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    public func getBlockEntity(blockIDs: [String],
                               trace: OPTraceProtocol,
                               success: @escaping ([BlockInfo]) -> Void,
                               failure: @escaping (Error) -> Void) {
        api.getBlockEntity(blockIDs: blockIDs, success: success, failure: failure, trace: trace)
    }
    
    /// 根据blockID 获取 blockEntity
    /// - Parameters:
    ///   - blockIDs: blockIDs 数组
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    public func getBlockEntity(blockIDs: [String],
                               success: @escaping ([BlockInfo]) -> Void,
                               failure: @escaping (Error) -> Void) {
        api.getBlockEntity(blockIDs: blockIDs, success: success, failure: failure)
    }


    public func createBlockID(param: BlockInfoReq, success: @escaping (String) -> Void, failure: @escaping (Error) -> Void) {
        api.createBlock(param: param, success: success, failure: failure)
    }
    
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
    public func generateBlock(blockID: String,
                              blockTypeID: String,
                              sourceLink: String,
                              sourceData: String?,
                              sourceMeta: String,
                              preview: String?,
                              summary: String) -> BlockInfo {
        return BlockInfo(blockID: blockID,
                         blockTypeID: blockTypeID,
                         sourceLink: sourceLink,
                         sourceData: sourceData,
                         sourceMeta: sourceMeta,
                         i18nPreview: preview,
                         i18nSummary: summary)
    }

    public func getAvailableBlockList(for param: BlockDetailReqParam,
                                      success: @escaping ([BlockDetail]) -> Void,
                                      failure: @escaping (Error) -> Void) {
        api.getAvailableBlockList(param: param, success: success, failure: failure)
    }

    /// 根据原始数据，挂载一个 block 实例到宿主
    /// - Parameters:
    ///   - entity: Block 数据实体
    ///   - slot: 宿主容器，由业务方提供作为 block 的父视图
    ///   - data: 业务场景
    ///   - plugins: 业务自定义 API
    ///   - config: 初始化 block 涉及到的配置
    ///   - delegate: Block 实例的生命周期代理
    public func mountBlock(byEntity entity: OPBlockInfo,
                           slot: OPRenderSlotProtocol,
                           data: OPBlockContainerMountDataProtocol,
                           config: OPBlockContainerConfigProtocol,
                           plugins: [OPPluginProtocol],
                           delegate: BlockitDelegate) {
        let startMountTime = Date()
        guard shouldStartMountBlock(config: config, delegate: delegate) else {
            return
        }

        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountEntity.block_entity_result)
        .tracing(config.trace)
        .addMap(["from": BlockDataFrom.host.rawValue,
                 "use_cache": true])
        .addMetricValue("duration", 0)
        .setResultTypeSuccess()
        .flush()
        
        __mountBlock(byEntity: entity,
                     slot: slot,
                     data: data,
                     config: config,
                     plugins: plugins,
                     delegate: delegate,
                     dataProviders: nil,
                     startMountTime: startMountTime)
    }

    /// 根据 blockID，挂载一个 block 实例到宿主
    /// - Parameters:
    ///   - byID: blockID
    ///   - slot: 宿主容器，由业务方提供作为 block 的父视图
    ///   - data: 业务场景
    ///   - plugins: 业务自定义 API
    ///   - config: 初始化 block 涉及到的配置
    ///   - delegate: Block 实例的生命周期代理
    public func mountBlock(byID id: String,
                           slot: OPRenderSlotProtocol,
                           data: OPBlockContainerMountDataProtocol,
                           config: OPBlockContainerConfigProtocol,
                           plugins: [OPPluginProtocol],
                           delegate: BlockitDelegate) {
        let startMountTime = Date()
        guard shouldStartMountBlock(config: config, delegate: delegate) else {
            return
        }
        
        __mountBlock(byID: id,
                     slot: slot,
                     data: data,
                     config: config,
                     plugins: plugins,
                     delegate: delegate,
                     startEntityTime: Date(),
                     startMountTime: startMountTime)
    }

    public func mountCreator(slot: OPRenderSlotProtocol,
                             config: OPBlockContainerConfigProtocol,
                             data: OPBlockContainerMountDataProtocol,
                             plugins: [OPPluginProtocol],
                             delegate: BlockitDelegate) {
        let startMountTime = Date()
        guard shouldStartMountBlock(config: config, delegate: delegate) else {
            return
        }
        if config.blockLaunchMode != .creator  {
            let monitorCode = OPBlockitMonitorCodeMountEntity.param_invalid
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .addMetricValue("luanch_mode", config.blockLaunchMode.rawValue)
                .addCategoryValue("biz_error_code", "\(OPBlockitMountParamErrorCode.mountCreatorParamInvalid.rawValue)")
                .setCommon(config)
                .setResultTypeFail()
                .tracing(config.trace)
                .flush()

            delegate.onBlockMountFail(error: monitorCode.error(message: "can not mountCreater when blockLaunchMode is \(config.blockLaunchMode.rawValue)"), context: config.blockContext)
            Self.log.error("Blockit mountCreator error, reason: param exec")
            return
        }
        __mountBlock(bySlot: slot,
                     data: data,
                     config: config,
                     plugins: plugins,
                     delegate: delegate,
                     dataProviders: nil,
                     startMountTime: startMountTime)
    }
    
    public func mountBlock(byParam param: BlockitParam) {
        let startMountTime = Date()
        guard shouldStartMountBlock(config: param.config, delegate: param.delegate) else {
            return
        }

        let startEntityTime = Date()
        var entity: OPBlockInfo?
        // 判断是否可以使用注入数据 && 是否有注入数据
        if param.mountType == .entity {
            if let entityProvider = param.dataProviders.getProvider(with: .entity) as? OPBlockDataProvider<OPBlockInfo> {
                let entityDataSourceService = BlockDataSourceService<OPBlockInfo>(dataProvider: entityProvider, dataInitMode: .lazyOnce)
                entity = entityDataSourceService.fetchData(dataType: .entity)
            } else {
                Self.log.info("Blockit mountBlockbyParam entityProvider is null")
            }
            
            if let entity = entity {
                OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                          code: OPBlockitMonitorCodeMountEntity.block_entity_result)
                .tracing(param.config.trace)
                .addMap(["from": BlockDataFrom.host.rawValue,
                         "use_cache": true])
                .setResultTypeSuccess()
                .addMetricValue("duration", Int(Date().timeIntervalSince(startEntityTime) * 1000))
                .flush()
                __mountBlock(byEntity: entity,
                             slot: param.slot,
                             data: param.data,
                             config: param.config,
                             plugins: param.plugins,
                             delegate: param.delegate,
                             dataProviders: param.dataProviders,
                             startMountTime: startMountTime)
            } else {
                let monitorCode = OPBlockitMonitorCodeMountEntity.param_invalid
                OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                          code: monitorCode)
                .setCommon(param.config)
                .setErrorMessage("mountBlockbyParam fail: entity is null")
                .setResultTypeFail()
                .addCategoryValue("biz_error_code", "\(OPBlockitMountParamErrorCode.mountByEntityParamInvalid.rawValue)")
                .flush()
                
                OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                          code: OPBlockitMonitorCodeMountEntity.block_entity_result)
                .setErrorMessage("mountBlockbyParam fail: entity is null")
                .addMap([
                    "from": BlockDataFrom.host.rawValue,
                    "use_cache": false,
                    "biz_error_code": "\(OPBlockitEntityResultErrorCode.invalidEntity.rawValue)"
                ])
                .setCommon(param.config)
                .addMetricValue("duration", Int(Date().timeIntervalSince(startEntityTime) * 1000))
                .tracing(param.config.trace)
                .setResultTypeFail()
                .flush()
                param.delegate.onBlockMountFail(error: monitorCode.error(message: "mountBlockbyParam fail: entity is null"), context: param.config.blockContext)
                return
            }
        } else {
            guard let blockID = param.blockID else {
                let monitorCode = OPBlockitMonitorCodeMountEntity.param_invalid
                OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                          code: monitorCode)
                .setCommon(param.config)
                .setResultTypeFail()
                .addCategoryValue("biz_error_code", "\(OPBlockitMountParamErrorCode.mountByBlockIdParamInvalid.rawValue)")
                .setErrorMessage("mountBlockbyParam fail: blockID is null")
                .flush()
                
                OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                          code: OPBlockitMonitorCodeMountEntity.block_entity_result)
                .setErrorMessage("mountBlockbyParam fail:  blockID is null")
                .addMetricValue("use_cache", false)
                .setCommon(param.config)
                .addMetricValue("duration", Int(Date().timeIntervalSince(startEntityTime) * 1000))
                .addCategoryValue("biz_error_code", "\(OPBlockitEntityResultErrorCode.invalidBlockId.rawValue)")
                .tracing(param.config.trace)
                .setResultTypeFail()
                .flush()
                
                param.delegate.onBlockMountFail(error: monitorCode.error(message: "mountBlockbyParam fail: blockID is null"), context: param.config.blockContext)
                return
            }
            __mountBlock(byID: blockID,
                         slot: param.slot,
                         data: param.data,
                         config: param.config,
                         plugins: param.plugins,
                         delegate: param.delegate,
                         dataProviders: param.dataProviders,
                         startEntityTime: startEntityTime,
                         startMountTime: startMountTime)
        }
    }
    
    private func shouldStartMountBlock(config: OPBlockContainerConfigProtocol, delegate: BlockitDelegate) -> Bool {
        let bootBefore = BlockFirstBootRecordTool.bootBefore(blockID: config.blockInfo?.blockID, userId: userId)
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountEntity.start_mount_block)
            .setCommon(config)
            .addCategoryValue("firstBoot", bootBefore.rawValue)
            .flush()
        let available = componentUtils.blockAvailable(for: config.host)
        if !available {
            let monitorCode = OPBlockitMonitorCodeMountEntity.internal_error
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setCommon(config)
                .setResultTypeFail()
                .setErrorMessage("block not available for \(config.host)")
                .addCategoryValue("biz_error_code", "\(OPBlockitMountInternalErrorCode.hostUnavailable.rawValue)")
                .flush()
            delegate.onBlockMountFail(error: monitorCode.error(message: "block not available for \(config.host)"), context: config.blockContext)
        } else {
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: OPBlockitMonitorCodeMountEntity.start_block_entity)
                .setCommon(config)
                .addMap(["enable_cache": useCacheFirst,
                         "use_cache_when_fetch_fail": config.useCacheWhenEntityFetchFails])
                .tracing(config.trace)
                .flush()
        }
        return available
    }

    /// 卸载 Block 并销毁
    public func unMountBlock(id: OPAppUniqueID) {
        let container = forwardDelegates[id]?.container
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountEntity.unmount_block)
            .tracing(container?.containerContext.blockContext.trace)
            .addMap(["app_id": id.appID,
                     "app_type": OPAppTypeToString(id.appType),
                     "identifier": id.identifier,
                     "version_type": OPAppVersionTypeToString(id.versionType)])
            .flush()
        if let conifg = container?.containerContext.containerConfig as? OPBlockContainerConfig, let blockid = conifg.blockInfo?.blockID{
            syncMessageManager.blockUnsubscribe(blockId: blockid)
        }

        (container?.containerContext.blockContext.lifeCycleTrigger as? OPBlockInternalCustomLifeCycleTriggerProtocol)?.triggerBlockLifeCycle(.destory)
        forwardDelegates[id] = nil
    }
    
    public func onShow(id: OPAppUniqueID) {
        let container = forwardDelegates[id]?.container
        container?.notifySlotShow()
    }
    
    public func onHide(id: OPAppUniqueID) {
        let container = forwardDelegates[id]?.container
        container?.notifySlotHide()
    }

    public func reloadPage(id: OPAppUniqueID) {
        let container = forwardDelegates[id]?.container
        container?.reRednerCurrentPage()
    }
    
    public func triggerPreInstall(idList: [OPAppUniqueID]) {
        preLoadService.preLoad(idList: idList)
    }
    
    /// 生成 PropsView
    /// - Parameters:
    ///   - blockInfo: blockInfo
    ///   - config: UI 配置
    ///   - completeHandler: 结果回调，携带可空的PropsView
    public func registerProps(blockInfo: BlockInfo,
                              config: PropsViewConfig?,
                              completeHandler: @escaping (PropsView?) -> Void) {
        self.registerProps(blockInfo: blockInfo, config: config, extra: nil, completeHandler: completeHandler)
    }
    
    public func registerProps(blockInfo: BlockInfo,
                              config: PropsViewConfig?,
                              extra: [String: Any]?,
                              completeHandler: @escaping (PropsView?) -> Void) {
        safeHandleTask { [weak self] in
            self?.propsUpdateHandlerMap[blockInfo] = completeHandler
        }

        if let config = config {
            handleTaskOnMainThread { [weak self] in
                self?.propsViewConfigMap[blockInfo] = config
                self?.propsViewExtraMap[blockInfo] = extra
            }
        }
    }

    /// 卸载 PropsView
    public func unRegisterProps(blockInfo: BlockInfo) {
        safeHandleTask { [weak self] in
            self?.propsUpdateHandlerMap.removeValue(forKey: blockInfo)
        }
        handleTaskOnMainThread {
            self.propsViewMap.removeObject(forKey: blockInfo)
            self.propsViewConfigMap.removeValue(forKey: blockInfo)
            self.propsViewExtraMap.removeValue(forKey: blockInfo)
        }
        Self.log.info("unRegisterProps: \(blockInfo.blockID)")
    }

    /// PropsView 显示时，需要调用
    public func onShow(blockInfo: BlockInfo) {
        assert(Thread.isMainThread, "onShow is only available on main thread")
        guard propsUpdateHandlerMap[blockInfo] != nil else { return }
    }

    /// PropsView 隐藏时 需要调用
    public func onHide(blockInfo: BlockInfo) {
        assert(Thread.isMainThread, "onHide is only available on main thread")
    }

    /// 调起 ActionPanel
    /// - Parameters:
    ///   - blockInfo: blockInfo
    ///   - context: 上下文，json格式的字符串，用于业务方透传一些数据
    ///   - from: controller
    public func doAction(blockInfo: BlockInfo, context: String?, from: UIViewController) {
        self.doAction(blockInfo: blockInfo, context: context, extra: nil, from: from)
    }

    public func doAction(blockInfo: BlockInfo, context: String?, extra: [String: Any]?, from: UIViewController) {
        handleTaskOnMainThread {
            let body = WorkTopicBody(blockInfo: blockInfo, blockit: self, context: context, extra: extra)
            self.doAction(body, from: from, prepare: { $0.modalPresentationStyle = .fullScreen }, animated: true)
        }
    }

    /// 调起 ActionPanel
    /// - Parameters:
    ///   - body: body
    ///   - from: controller
    public func doAction<T: PlainBody>(_ body: T,
                                       from: UIViewController,
                                       prepare: ((UIViewController) -> Void)?,
                                       animated: Bool) {
        handleTaskOnMainThread {
            // Pano 业务依赖的，后续可以下线了
            Container.shared.getCurrentUserResolver().navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: from,
                prepare: prepare,
                animated: animated
            )
        }
    }

    /// 生成Mention页面
    /// - Parameters:
    ///   - from: viewController
    ///   - context: 上下文
    ///   - complete: 拉起面板成功的callback
    ///   - cancel: 拉起面板取消的callback
    public func doMention(from: UIViewController,
                          context: String?,
                          extra: [String: Any]?,
                          complete: MentionBody.MentionSelectedHandler?,
                          cancel: MentionBody.MentionCancelHandler?) {
        handleTaskOnMainThread {
            let body = MentionBody(blockit: self,
                                   context: context,
                                   extra: extra,
                                   complete: complete,
                                   cancel: cancel)
            // Pano 业务依赖的，后续可以下线了
            Container.shared.getCurrentUserResolver().navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: from,
                prepare: { $0.modalPresentationStyle = .fullScreen },
                animated: true
            )
        }
    }

    /// 串联宿主trace和block trace
    /// - Parameter hostTrace: 宿主的trace
    /// - Parameter blockTrace: block生命周期内的trace
    public func linkBlockTrace(hostTrace: OPTraceProtocol, blockTrace: OPTraceProtocol) {
        OPMonitor(String.OPBlockitMonitorKey.traceLinkEventName)
            .tracing(hostTrace)
            .addCategoryValue(String.OPBlockitMonitorKey.traceLinkParam, blockTrace.traceId)
            .flush()
    }
}

// MARK: - 主线程操作 & 锁操作
extension Blockit {

    fileprivate func handleTaskOnMainThread(_ task: @escaping (() -> Void)) {
        if Thread.isMainThread {
            task()
        } else {
            DispatchQueue.main.async {
                task()
            }
        }
    }

    fileprivate func safeHandleTask(_ task: @escaping (() -> Void)) {
        lock.lock()
        defer { lock.unlock() }
        task()
    }
}


// MARK: - MountBlock
extension Blockit {

    private func __mountBlock(bySlot slot: OPRenderSlotProtocol,
                              data: OPBlockContainerMountDataProtocol,
                              config: OPBlockContainerConfigProtocol,
                              plugins: [OPPluginProtocol],
                              delegate: BlockitDelegate,
                              dataProviders: BlockProviderSet?,
                              startMountTime: Date) {
        
        assert(Thread.isMainThread, "Blockit mountBlockByEntity must be invocated on MAIN_THREAD")
        Self.log.info("Blockit mountBlock Start")

        OPApplicationService.notify?()
        
        let forwardDelegate = BlockitForwardDelegate(
            delegate: delegate,
            blockit: self,
            startMountTime: startMountTime,
            userId: userId
        )
        forwardDelegates[config.uniqueID] = forwardDelegate

        let uniqueID = config.uniqueID

        let application: OPApplicationProtocol
        if let app = OPApplicationService.current.getApplication(appID: uniqueID.appID) {
            application = app
        } else {
            application = OPApplicationService.current.createApplication(appID: uniqueID.appID)
        }

        let container = application.createContainer(
            uniqueID: uniqueID,
            containerConfig: config
        )

        if let ctn = container as? OPBlockContainerProtocol {
            ctn.hostDelegate = delegate
            delegate.onBlockMountSuccess(container: ctn, context: config.blockContext)
            forwardDelegate.container = ctn

            registerServiceToContainer(dataProviders: dataProviders, container: ctn)
            
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: OPBlockitMonitorCodeMountEntity.success)
                .setCommon(config)
                .setResultTypeSuccess()
                .flush()
        } else {
            Self.log.error("Blockit mountBlock Failed")
            let monitorCode = OPBlockitMonitorCodeMountEntity.internal_error
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setCommon(config)
                .setResultTypeFail()
                .addCategoryValue("biz_error_code", "\(OPBlockitMountInternalErrorCode.containerNotFound.rawValue)")
                .flush()
            delegate.onBlockMountFail(error: monitorCode.error(message: "create container failed"), context: config.blockContext)
            assertionFailure("Blockit mountBlock Failed")
            return
        }

        container.addLifeCycleDelegate(delegate: forwardDelegate)
        container.registerPlugins(plugins: plugins)
        container.mount(data: data, renderSlot: slot)
        Self.log.info("Blockit mountBlock Success")
        guard let blockId = config.blockInfo?.blockID else{
            Self.log.error("__mountBlock without blockid")
            assert(false, "__mountBlock without blockid")
            return
        }
        syncMessageManager.subscribeSyncMessage(blockId: blockId, container: container)
    }
    
    private func registerServiceToContainer(dataProviders: BlockProviderSet?, container: OPBlockContainerProtocol) {
        // 将guideInfoService注入到serviceContainer
        container.serviceContainer.register(BlockDataSourceService<OPBlockGuideInfo>.self) {
            Self.log.info("BlockContainerService register guideinfoService")
            let dataProvider: OPBlockDataProvider<OPBlockGuideInfo>? = dataProviders?.getProvider(with: .guideInfo)
            return BlockDataSourceService(dataProvider: dataProvider, dataInitMode: .lazyOnce)
        }
    }

    private func __mountBlock(byEntity entity: OPBlockInfo,
                              slot: OPRenderSlotProtocol,
                              data: OPBlockContainerMountDataProtocol,
                              config: OPBlockContainerConfigProtocol,
                              plugins: [OPPluginProtocol],
                              delegate: BlockitDelegate,
                              dataProviders: BlockProviderSet?,
                              startMountTime: Date) {
        
        Self.log.info("Blockit mountBlockByEntity Start")
        config.blockInfo = entity
        __mountBlock(bySlot: slot,
                     data: data,
                     config: config,
                     plugins: plugins,
                     delegate: delegate,
                     dataProviders: dataProviders,
                     startMountTime: startMountTime)
    }
    
    struct BlockEntityCacheConfig: SettingDefaultDecodable{
        static let settingKey = UserSettingKey.make(userKeyLiteral: "block_cache_MGetBlockEntityV2")
        static var defaultValue = BlockEntityCacheConfig(enable: false)

        let enable: Bool
    }

    private func __mountBlock(byID id: String,
                              slot: OPRenderSlotProtocol,
                              data: OPBlockContainerMountDataProtocol,
                              config: OPBlockContainerConfigProtocol,
                              plugins: [OPPluginProtocol],
                              delegate: BlockitDelegate,
                              dataProviders: BlockProviderSet? = nil,
                              startEntityTime: Date,
                              startMountTime: Date) {

        if useCacheFirst {
            mountBlockByCacheFirst(byID: id,
                                   slot: slot,
                                   data: data,
                                   config: config,
                                   plugins: plugins,
                                   delegate: delegate,
                                   startEntityTime: startEntityTime,
                                   startMountTime: startMountTime)
        } else {
            mountBlockByNetWorkFirst(byID: id,
                                     slot: slot,
                                     data: data,
                                     config: config,
                                     plugins: plugins,
                                     delegate: delegate,
                                     startEntityTime: startEntityTime,
                                     startMountTime: startMountTime)
        }
    }
    
    /// 优先使用缓存去mountBlock，没有缓存，再发起网络请求
    private func mountBlockByCacheFirst(byID id: String,
                                        slot: OPRenderSlotProtocol,
                                        data: OPBlockContainerMountDataProtocol,
                                        config: OPBlockContainerConfigProtocol,
                                        plugins: [OPPluginProtocol],
                                        delegate: BlockitDelegate,
                                        startEntityTime: Date,
                                        startMountTime: Date) {
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.block.child(id))
            .mmkv()

        let cacheTimestamp = store.integer(forKey: BlockCacheKey.Block.entityTimestamp)
        let duration = Int(Date().timeIntervalSince(startEntityTime) * 1000)
        let entityResult = OPMonitor(
            name: String.OPBlockitMonitorKey.eventName, code: OPBlockitMonitorCodeMountEntity.block_entity_result
        )
            .addMetricValue("duration", duration)
            .tracing(config.trace)
            .addMap([
                "enable_cache": true,
                "use_cache_when_fetch_fail": config.useCacheWhenEntityFetchFails,
                "cache_timestamp": cacheTimestamp
            ])

        // 获取 entity 缓存
        let cacheEntity: BlockInfo? = store.value(forKey: BlockCacheKey.Block.entityData)

        var usedCache = false
        if let cacheEntity = cacheEntity {
            usedCache = true
            self.handleTaskOnMainThread {
                entityResult
                    .addMetricValue("use_cache", true)
                    .addMetricValue("from", BlockDataFrom.cache.rawValue)
                    .setResultTypeSuccess()
                    .flush()
                self.__mountBlock(
                    byEntity: cacheEntity.toOPInfo(),
                    slot: slot,
                    data: data,
                    config: config,
                    plugins: plugins,
                    delegate: delegate,
                    dataProviders: nil,
                    startMountTime: startMountTime
                )
                Self.log.warn("Blockit mountBlockByID using cache, id: \(id)")
            }
        } else {
            Self.log.error("Blockit mountBlockByID entity cache decode error")
        }

        getBlockEntity(blockIDs: [id], trace: config.trace) { infos in
            self.handleTaskOnMainThread {
                guard let info = infos.first else {
                    let monitorCode = OPBlockitMonitorCodeMountEntity.fetch_block_entity_biz_error
                    if !usedCache {
                        entityResult
                            .setErrorMessage("getBlockEntity infos is empty")
                            .setResultTypeFail()
                            .addMetricValue("use_cache", false)
                            .addMetricValue("from", BlockDataFrom.network.rawValue)
                            .addCategoryValue("biz_error_code", "\(OPBlockitEntityResultErrorCode.invalidInfos.rawValue)")
                            .flush()
                        delegate.onBlockMountFail(error: monitorCode.error(message: "getBlockEntity return empty blockInfo"), context: config.blockContext)
                    }
                    Self.log.error("Blockit mountBlockByID error: invalid_init_params")
                    return
                }

                store.set(Int(Date().timeIntervalSince1970), forKey: BlockCacheKey.Block.entityTimestamp)
                store.set(info, forKey: BlockCacheKey.Block.entityData)

                if !usedCache {
                    entityResult
                        .setResultTypeSuccess()
                        .addMetricValue("use_cache", false)
                        .addMetricValue("from", BlockDataFrom.network.rawValue)
                        .flush()
                    self.__mountBlock(
                        byEntity: info.toOPInfo(),
                        slot: slot,
                        data: data,
                        config: config,
                        plugins: plugins,
                        delegate: delegate,
                        dataProviders: nil,
                        startMountTime: startMountTime
                    )
                }
            }
        } failure: { error in
            let err = error as? OPError ?? OPBlockitMonitorCodeMountEntity.internal_error.error(message: "get block entity error")
            if !usedCache {
                entityResult
                    .setResultTypeFail()
                    .addMetricValue("use_cache", false)
                    .addMetricValue("from", BlockDataFrom.network.rawValue)
                    .setError(err)
                    .flush()
                delegate.onBlockMountFail(error: err, context: config.blockContext)
            }
            Self.log.error("Blockit mountBlockByID error: invalid_init_params")
        }
    }

    /// 优先网络数据去mountBlock，网络请求失败，再使用缓存
    private func mountBlockByNetWorkFirst(byID id: String,
                                          slot: OPRenderSlotProtocol,
                                          data: OPBlockContainerMountDataProtocol,
                                          config: OPBlockContainerConfigProtocol,
                                          plugins: [OPPluginProtocol],
                                          delegate: BlockitDelegate,
                                          startEntityTime: Date,
                                          startMountTime: Date) {
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.block.child(id))
            .mmkv()

        let entityCacheEnable = config.useCacheWhenEntityFetchFails
        let duration = Int(Date().timeIntervalSince(startEntityTime) * 1000)
        let entityResult = OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                                     code: OPBlockitMonitorCodeMountEntity.block_entity_result)
                               .addMetricValue("duration", duration)
                               .tracing(config.trace)
                               .addMap(["enable_cache": false,
                                        "use_cache_when_fetch_fail": entityCacheEnable])
        getBlockEntity(blockIDs: [id], trace: config.trace) { infos in
            self.handleTaskOnMainThread {
                guard let info = infos.first else {
                    let monitorCode = OPBlockitMonitorCodeMountEntity.fetch_block_entity_biz_error
                    entityResult
                        .setErrorMessage("getBlockEntity infos is empty")
                        .addMetricValue("from", BlockDataFrom.network.rawValue)
                        .addMetricValue("use_cache", false)
                        .addCategoryValue("biz_error_code", "\(OPBlockitEntityResultErrorCode.invalidInfos.rawValue)")
                        .setResultTypeFail()
                        .tracing(config.trace)
                        .flush()
                    delegate.onBlockMountFail(error: monitorCode.error(message: "getBlockEntity return empty blockInfo"), context: config.blockContext)
                    Self.log.error("Blockit mountBlockByID error: invalid_init_params")
                    return
                }
                if entityCacheEnable {
                    store.set(info, forKey: BlockCacheKey.Block.entityData)
                    store.set(Int64(Date().timeIntervalSince1970), forKey: BlockCacheKey.Block.entityTimestamp)
                }
                entityResult
                    .setResultTypeSuccess()
                    .addMetricValue("use_cache", false)
                    .addMetricValue("from", BlockDataFrom.network.rawValue)
                    .flush()
                self.__mountBlock(byEntity: info.toOPInfo(),
                                  slot: slot,
                                  data: data,
                                  config: config,
                                  plugins: plugins,
                                  delegate: delegate,
                                  dataProviders: nil,
                                  startMountTime: startMountTime)
            }
        } failure: { error in
            if entityCacheEnable {
                Self.log.info("Blockit mountBlockByID using cache fg enable!")

                let cacheEntity: BlockInfo? = store.value(forKey: BlockCacheKey.Block.entityData)
                if let cacheEntity = cacheEntity {
                    Self.log.info("Blockit mountBlockByID cache entity read success!")

                    self.handleTaskOnMainThread {
                        entityResult
                            .setResultTypeSuccess()
                            .addMap(["use_cache": true])
                            .addMetricValue("from", BlockDataFrom.cache.rawValue)
                            .flush()
                        self.__mountBlock(
                            byEntity: cacheEntity.toOPInfo(),
                            slot: slot,
                            data: data,
                            config: config,
                            plugins: plugins,
                            delegate: delegate,
                            dataProviders: nil,
                            startMountTime: startMountTime
                        )

                        Self.log.warn("Blockit mountBlockByID using cache, id: \(id)")
                    }
                    // ⚠️ 缓存 Entity mount 成功，注意 return 不要触发 onBlockMountFail
                    return
                }
            }

            let err = error as? OPError ?? OPBlockitMonitorCodeMountEntity.internal_error.error(message: "get block entity error")
            entityResult
                .setError(err)
                .setResultTypeFail()
                .addMetricValue("use_cache", false)
                .addCategoryValue("biz_error_code", "\(OPBlockitEntityResultErrorCode.getEntityFail.rawValue)")
                .flush()
            delegate.onBlockMountFail(error: err, context: config.blockContext)
            Self.log.error("Blockit mountBlockByID error: \(error.localizedDescription)")
        }
    }
}
