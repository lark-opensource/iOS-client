//
//  OPBlockComponent.swift
//  OPSDK
//
//  Created by Limboy on 2020/11/11.
//

import Foundation
import Lynx
import SnapKit
import OPSDK
import OPBlockInterface
import OPFoundation
import ECOProbe
import LKCommonsLogging
import XElement
import TTMicroApp
import LarkSetting
import LarkFoundation
import LarkStorage
import LarkContainer

/// 用于 lynxView 设置 group name
fileprivate var blockGroupID = 1

private struct Constants {
    static let LynxModuleName = "BDLynxAPIModule"
    static let LynxEventTrigger = "trigger"
}

/// block init 时传入的初始数据
private enum BlockInitDataKey: String {
    // 初始化的数据结构
    case root = "block_init_data"
    // 宿主业务标识
    case host = "host"
    // info 数据，比如 source data，source link 等
    case info = "blockInfo"
    // 自定义 api
    case apis = "customApis"
    // 数据类型集合
    case collection = "typedDataCollection"
    // 是否使用 V2 版本的 request
    case useNewRequestAPI = "useNewRequestAPI"
}

@objcMembers
/// BlockComponent render 时需要的数据格式
class OPBlockComponentData: NSObject, OPComponentDataProtocol {

    private let containerContext: OPContainerContext

    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    var templateFilePath: String

    var initData: [String: Any] {
        [BlockInitDataKey.root.rawValue: blockInitData]
    }

    init(templateFilePath: String, containerContext: OPContainerContext) {
        self.templateFilePath = templateFilePath
        self.containerContext = containerContext
        super.init()
    }
    
    func updateBlockInfo(_ info: Any?) {
        trace.info("OPBlockComponentData.updateBlockInfo")
        updateBlockInitData(key: .info, value: info)
    }

    func updateHost(_ host: String?) {
        trace.info("OPBlockComponentData.updateHost")
        updateBlockInitData(key: .host, value: host)
    }

    func updateCustomAPIs(_ apis: [[AnyHashable: Any]]) {
        trace.info("OPBlockComponentData.updateCustomAPIs")
        updateBlockInitData(key: .apis, value: apis)
    }

    func updateDataCollection(_ collection: [AnyHashable: Any]?) {
        trace.info("OPBlockComponentData.updateDataCollection")
        updateBlockInitData(key: .collection, value: collection ?? [:])
    }

    func updateUseNewRequestAPI(_ enable: Bool) {
        trace.info("OPBlockComponentData.updateUseNewRequestAPI", additionalData: ["enable": "\(enable)"])
        updateBlockInitData(key: .useNewRequestAPI, value: enable)
    }
    
    // block_init_data: [{...}, {...}]
    private var blockInitData: [AnyHashable: Any] = [:]
    
    private func updateBlockInitData(key: BlockInitDataKey, value: Any?) {
        trace.info("OPBlockComponentData.updateBlockInitData info: update data type = \(key)")
        blockInitData[key.rawValue] = value
    }
    
    override var description: String {
        return "templateFilePath:\(templateFilePath)"
    }
}

@objcMembers
/// 更新 Template 时需要的 data 的数据格式，没有裸用 Dictionary 主要是考虑到后期的扩展性
class OPBlockComponentTemplateData: NSObject, OPComponentTemplateDataProtocol {
    var data: [String: Any]?
    init(data: [String: Any]?) {
        self.data = data
        super.init()
    }
}

@objc
public protocol OPBlockComponentProtocol: OPComponentProtocol, OPBlockEntityProtocol {
    /// 保存宿主的弱引用
    weak var hostDelegate: OPBlockHostProtocol? { get set }
}


private class OPBlockLynxTemplateProvider: NSObject, LynxTemplateProvider {

    // MARK: - LynxTemplateProvider

    /// 这个方法只有在使用 `loadTemplateFromURL:data` 时才会调用，目前这个交给了 loader 去实现，但是 LynxView 在初始化时又必须要提供一个 provider，🤷‍♂️
    /// - Parameters:
    ///   - url: 要加载的 URL
    ///   - callback: 下载结束后的回调
    public func loadTemplate(withUrl url: String!, onComplete callback: LynxTemplateLoadBlock!) {

    }
}

extension OPSDK.OPBundle {
    static var block: Bundle {
        get {
            if let bundleUrl = Bundle(for: self).url(forResource: "OPBlock", withExtension: "bundle") {
                return Bundle.init(url: bundleUrl)!
            }

            return Bundle.main
        }
    }
}

// https://cloud.bytedance.net/appSettings-v2/detail/config/167880/detail/status
private struct LynxLogLevelConfig: SettingDefaultDecodable{
    static let settingKey = UserSettingKey.make(userKeyLiteral: "block_lynx_log_level")

	/// 默认最小透传日志级别
	let defaultMinLogLevel: Int
	/// 特定block最小透传日志级别
	let blockMinLogLevel: [String: Int]

    static let defaultValue = LynxLogLevelConfig(defaultMinLogLevel: 1, blockMinLogLevel: [:])
}

@objcMembers
class OPBlockComponent: OPNode, OPBlockComponentProtocol, OPBlockBridgeDelegate, OPBaseBridgeDelegate, LynxViewLifecycle {

    // OPSDK 未完整适配用户态隔离
    private var userResolver: UserResolver {
        return Container.shared.getCurrentUserResolver()
    }

	// lynx透传日志级别配置
    private var lynxLogLevelConfig: LynxLogLevelConfig {
        return userResolver.settings.staticSetting()
    }

    private var apiSetting: OPBlockAPISetting? {
        return try? userResolver.resolve(assert: OPBlockAPISetting.self)
    }

	// block 加载component流程是否不依赖lynx渲染结果（与Android端对齐）
    private var fixFinish: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableFixComponentFinish.key)
    }

	private let containerContext: OPContainerContext
    
    private let lock = BlockLock()

    private var isRuntimeReady = false
    
    private var eventBuffer: [Event] = []
    
    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    var context: OPComponentContext

    private var observation: NSKeyValueObservation?

    public let bridge: OPBridgeProtocol

    private var fileReader: OPPackageReaderProtocol
    
    private var apiBridge: OPBlockAPIBridge

    // 生命周期中转对象( Lynx 1.4 改为弱引用，因此这里改为强引用，否则会被释放)
    private lazy var  lynxViewLifecycleListener: LynxViewLifecycleListener = {
        return LynxViewLifecycleListener(
            userResolver: self.userResolver,
            delegate: self,
            containerContext: self.containerContext
        )
    }()

    private var lifeCycleListeners: Array<WeakReference<OPComponentLifeCycleProtocol>>
    
    /// Lynx使用的网络图片请求器（Lynx 弱引用这个对象）
    private lazy var imageFetcher: OPBlockImageFetcher = {
        return OPBlockImageFetcher(userResolver: userResolver, containerContext: containerContext)
    }()

    /// Lynx 使用的通用资源拦截器
    private lazy var resourceFetch = OPBlockResourceFetcher(containerContext: containerContext)

    // 非生命周期类的事件回调
    weak var hostDelegate: OPBlockHostProtocol?

    private var logID: Int?

    private var configForwardLogID: Int?

    private var startTime = Date()
    
    private lazy var lynxView: LynxView = {
        self.trace.info("OPBlockComponent: LynxView")
        var lynxView = LynxView { (builder) in
            if self.isCustomLifecycle {
                builder.enableAutoExpose = false
            }
            builder.isUIRunningMode = true
			#if IS_LYNX_DEVTOOL_OPEN
			if let blockMeta = self.containerContext.meta as? OPBlockMeta,
			   let socketAddress = blockMeta.devtoolSocketAddress,
			   !socketAddress.isEmpty {
				builder.debuggable = true
				self.trace.info("OPBlockComponent: LynxView devtool open")
			} else {
				self.trace.error("OPBlockComponent: LynxView devtool debuggable unusable")
			}
			#endif

            /// 这个目前在这里没有用，但由于不设会崩，所以设一个吧 🤷‍♂️
            /// LynxConfig 会强引用 provider，进而造成 lynxview -> config -> self -> lynxview 的循环引用，所以用一个中转类搞一波
            let config = LynxConfig(provider: OPBlockLynxTemplateProvider())
            /// param 里传的是 BlockBridge 的 Delgate，Bridge 内部会将它设为自己的 Delegate
            config.register(OPBlockBridge.self, param: OPBlockBridgeData(context: self.containerContext, delegate: self) )
            builder.config = config

            /// 设置 JSSDK
            let preloadScripts: [String]

            let blockJSSDKPath = OPVersionDirHandler.latestVersionBlockPath()
            let jssdkExist: Bool = AbsPath(blockJSSDKPath).exists

            if jssdkExist {
                var jssdkVersion = BDPVersionManager.localLibVersionString(.block)
                if let greyHash = BDPVersionManager.localLibGreyHash(.block), greyHash.count > 0 {
                    jssdkVersion = "\(BDPVersionManager.localLibVersionString(.block))_\(greyHash)"
                }
                OPMonitor("mp_use_jssdk")
                    .setUniqueID(self.context.uniqueID)
                    .addCategoryValue("use_dynamic_jssdk", true)
                    .addCategoryValue("jssdk_version", jssdkVersion)
                    .setResultTypeSuccess()
                    .flush()
            } else {
                OPMonitor("mp_use_jssdk")
                    .setUniqueID(self.context.uniqueID)
                    .addCategoryValue("use_dynamic_jssdk", true)
                    .setResultTypeFail()
                    .setErrorCode("10004")
                    .setErrorMessage("bundle_jssdk_file_empty")
                    .flush()
            }
            preloadScripts = ["file://\(blockJSSDKPath)"]
            
            let name: String
            // preview 模式不设置 group
            if self.useSingleGroupTagName() {
                // 设置该 tag 可以使 lynxView 使用独立的 jscontext
                name = LynxGroup.singleGroupTag()
            } else {
                name = "block\(self.getSetBlockGroupID())"
            }
            /// 同样的 group name 共享同一个 context，每一个 block 都是隔离的 Context
            let group = LynxGroup(name: name, withPreloadScript: preloadScripts, useProviderJsEnv: false, enableCanvas: true, enableCanvasOptimization: true)
            builder.group = group

        }
        //  Lynx弱引用这个imageFetcher
        lynxView.imageFetcher = imageFetcher
        lynxView.resourceFetcher = resourceFetch

        // 修复 Lynx iOS 16.5.1+ 闪黑条问题
        // https://meego.feishu.cn/larksuite/issue/detail/13837700
        lynxView.clipsToBounds = true
        lynxView.layer.masksToBounds = true
        return lynxView
    }()

    required public init(fileReader: OPPackageReaderProtocol, context: OPContainerContext) {
        self.containerContext = context
        self.fileReader = fileReader
        self.context = OPComponentContext(context: containerContext)
        self.lifeCycleListeners = []
        let bridge = OPBaseBridge()
        self.bridge = bridge
        self.apiBridge = OPBlockAPIBridge(containerContext: containerContext)

        super.init()
        bridge.delegate = self
        configForwardLogID = configForwardLog()

		#if IS_LYNX_DEVTOOL_OPEN
		tryConnectWebSocket()
		#endif

        trace.info("OPBlockComponent.init")
    }

	#if IS_LYNX_DEVTOOL_OPEN
	private func tryConnectWebSocket(_ close: Bool = false) {
		guard let blockMeta = self.containerContext.meta as? OPBlockMeta,
			let socketAddress = blockMeta.devtoolSocketAddress,
			!socketAddress.isEmpty else {
			trace.error("OPBlockComponent startConnectWebSocket fail")
			   return
		}
		let urlStr = close ? "lynx://remote_debug_lynx/disable?url=&room=" : socketAddress
		guard let url = URL(string: urlStr) else {
			trace.error("OPBlockComponent startConnectWebSocket fail")
			   return
		}

		let result = LynxDebugger.enable(url, withOptions:["App": LarkFoundation.Utils.appName, "AppVersion": LarkFoundation.Utils.appVersion])
		trace.info("OPBlockComponent ConnectWebSocket close\(close) result \(result)")
	}
	#endif

    /// 渲染内容到 slot
    /// - Parameters:
    ///   - slot: Block View 的容器，**注意**，这里的 view 的 frame 一定要已经设置好，内部会去取 frame 去做约束
    ///   - data: 具体类型为 `OPBlockComponentData`，不匹配会抛出异常
    /// - Throws: data 类型不匹配时会抛出异常
    func render(slot: OPViewRenderSlot, data: OPComponentDataProtocol) throws {

        trace.info("OPBlockComponent.render")

        guard let data = data as? OPBlockComponentData else {
            trace.error("OPBlockComponent.render error: data == nil || casting OPComponentData failed")
			if fixFinish {
				lifeCycleListeners.forEach { (listener) in
					listener.value?.onComponentFail?(err: OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail,
																		message: "cast to OPBlockComponentData failed"))
				}
				return
			} else {
				throw OPComponentError.paramError("cast to OPBlockComponentData failed")
			}
        }
        guard let slotView = slot.view else {
            trace.error("OPBlockComponent.render error: slot.view == nil")
			if fixFinish {
				lifeCycleListeners.forEach { (listener) in
					listener.value?.onComponentFail?(err: OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail,
																		message: "slot view has released"))
				}
				return
			} else {
				throw OPComponentError.paramError("slot view has released")
			}
        }
		if fixFinish {
			lifeCycleListeners.forEach { (listener) in
				listener.value?.onComponentReady?()
			}
		}
        setupLynxView(slot: slotView)
        let templateData = try fileReader.syncRead(file: data.templateFilePath)
        let templateInitData = LynxTemplateData(dictionary: data.initData)
        trace.info("OPBlockComponent.render templateData.size: \(templateData.count)")

        /// 下载的事情交给 Loader 处理，这里不需要再设置 URL，因此设为固定值
        lynxView.loadTemplate(templateData, withURL: "local", initData: templateInitData)
    }

    /// 添加生命周期 Listener
    /// - Parameter listener: 监听者，内部不会对 listener 去重，同一个 listener 加入多次，则会被触发多次
    func addLifeCycleListener(listener: OPComponentLifeCycleProtocol) {
        lifeCycleListeners.append(WeakReference(value: listener))
    }


    /// 更新显示数据
    /// - Parameter data: 具体类型为 `OPBlockComponentTemplateData`
    /// - Throws: 类型不匹配时会抛出异常
    func update(data: OPComponentTemplateDataProtocol) throws {
        trace.info("OPBlockComponent.update update OPComponentTemplateData")

        guard let data = data as? OPBlockComponentTemplateData else {
            trace.error("OPBlockComponent.update error: data == nil || casting OPBlockComponentTemplateData failed.")
            throw OPComponentError.paramError("cast to OPBlockComponentTemplateData failed")
        }
        lynxView.updateData(with: data.data)
    }

    // 该功能用于重刷当前页面，目前仅提供给web形态使用，lynx形态暂不提供页面重刷
    func reRender() {
        assertionFailure("rerender only usable for web block currently, should not enter here")
    }


    /// 接收到 Container 传来的 onShow 事件
    func onShow() {
        trace.info("OPBlockComponent.onShow isCustomLifecycle: \(isCustomLifecycle)")
        if isCustomLifecycle {
            lynxView.onEnterForeground()
        }
    }

    /// 接收到 Container 传来的 onHide 事件
    func onHide() {
        trace.info("OPBlockComponent.onHide isCustomLifecycle: \(isCustomLifecycle)")
        if isCustomLifecycle {
            lynxView.onEnterBackground()
        }
    }

    /// 接收 Container 传来的 onDestroy 事件
    func onDestroy() {
        /// 目前不需要做什么事
    }

    deinit {
        if let id = logID {
            LynxRemoveLogObserver(id)
        }
        if let configForwardLogID = configForwardLogID {
            LynxRemoveLogObserver(configForwardLogID)
        }
		#if IS_LYNX_DEVTOOL_OPEN
		tryConnectWebSocket(true)
		#endif
    }

    // MARK: - Private Methods

    /// 设置 LynxView
    /// - Parameter slot: lynxView 的显示容器
    private func setupLynxView(slot: UIView) {
        trace.info("OPBlockComponent.setupLynxView")

        /// 需要 slot 已经有确定的 frame，不然会出现无法显示的问题
        lynxView.preferredLayoutWidth = slot.frame.width
        lynxView.preferredLayoutHeight = slot.frame.height
        // 只限制宽度方向为 exact，高度方向可能灵活调整，如展开收起
        lynxView.layoutWidthMode = .exact

        slot.addSubview(lynxView)

        lynxView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        logID = configDebugLogger()
        // Fix for Lynx: 监听 containerView size 变化（LynxView 不支持 auto layout）
        let tempTrace = trace
        observation = slot.observe(\.bounds, options: [.old, .new]) {
            [weak self] (object, change) in
            guard let self = self, let newSize = change.newValue else {
                tempTrace.error("OPBlockComponent.setupLynxView slot.observe error: self == nil or change.newValue == nil")
                return
            }
            self.lynxView.preferredLayoutWidth = newSize.size.width
            self.lynxView.preferredLayoutHeight = newSize.size.height
            self.lynxView.triggerLayout()
        }

        /// 因为 lynxView 会强持有，所以给一个局部变量它
        lynxViewLifecycleListener.delegate = self
        lynxView.addLifecycleClient(lynxViewLifecycleListener)
        
        lynxView.triggerLayout()

        // 立即无脑进行一次 onshow
        onShow()
    }
    
    /// 获取旧的 groupID，同时自增 groupID，命名参考 redis 的 getset
    private func getSetBlockGroupID() -> String {
        trace.info("OPBlockComponent.getSetBlockGroupID")
        let groupID: String
        // 开关打开，则相同 BlockTypeID 的 Block 会共享上下文
        // lynx 对于具有相同 groupID 的 view 同步上下文环境
        if userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableMultiContext.key) {
            groupID = context.uniqueID.identifier
        } else {
            groupID = String(blockGroupID)
            blockGroupID += 1
        }
        return groupID
    }
    
    private func useSingleGroupTagName() -> Bool {
        if context.uniqueID.versionType == .preview {
            return true
        }
        if userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableBlockConsole.key) {
            // 这里其实应该还有个条件，需要开发者在 index.json 配置 {"workplace":{"consoleEnable": true}}
            // 但在 Block SDK 里面解析宿主配置不太合适，暂时先只通过 FG 来判断，后续再优化
            return true
        }
        return false
    }
    
    
    /// 是否使用宿主定制的生命周期，onShow onHide
    private var isCustomLifecycle: Bool {
        containerConfig?.isCustomLifecycle ?? false
    }
    
    private var containerConfig: OPBlockContainerConfigProtocol? {
        containerContext.containerConfig as? OPBlockContainerConfigProtocol
    }

    // 添加一个log，借以转发 lynx console
    private func configForwardLog() -> Int?  {
        let blockId = context.containerContext.uniqueID.identifier
        let defaultLogLevel = lynxLogLevelConfig.defaultMinLogLevel
        guard let level = LynxLogLevel(rawValue: lynxLogLevelConfig.blockMinLogLevel[blockId] ?? defaultLogLevel) else {
            trace.error("handle log level config failed", additionalData: [
                "config.defaultMinLogLevel": "\(lynxLogLevelConfig.defaultMinLogLevel)",
                "config.blockMinLogLevel": "\(lynxLogLevelConfig.blockMinLogLevel)"
            ])
            return nil
        }
        trace.info("OPBlockComponent.configForwardLog", additionalData: ["level": "\(level)"])
        let context = containerContext
        let observer = LynxLogObserver(logFunction: { level, logString in
            let appId = context.applicationContext.appID
            let blockTypeId = context.blockContext.uniqueID.identifier
            let blockId = context.blockContext.uniqueID.blockID
            let trace = context.blockContext.trace
            let message = "BlockLynxLog, appId=\(appId), blockTypeId=\(blockTypeId), blockId=\(blockId), \(logString ?? "")"
            switch level {
            case .info:
                trace.info(message)
            case .warning:
                trace.warn(message)
            case .error, .report, .fatal:
                trace.error(message)
            @unknown default:
                trace.error(message)
                break
            }
        }, minLogLevel: level)
        observer?.acceptSource = .naitve
        return LynxAddLogObserverByModel(observer)
    }


    // 配置 debug logger
    private func configDebugLogger() -> Int? {
        let tempTrace = trace
        let observer = LynxLogObserver(logFunction: { [weak self] logLevel, logString in
            guard let self = self else {
                tempTrace.error("OPBlockComponent.configDebugLogger error: self is released")
                return
            }

            guard let log = logString else {
                self.trace.error("OPBlockComponent.configDebugLogger error: no log string")
                return
            }

            let level: OPBlockDebugLogLevel
            switch logLevel {
            case .info:
                level = .info
            case .warning:
                level = .warn
            case .error, .report, .fatal:
                level = .error
            @unknown default:
                level = .error
                break
            }
            self.hostDelegate?.didReceiveLogMessage(self, level: level, message: log, context: self.containerContext.blockContext)
        }, minLogLevel: .info)

        observer?.shouldFormatMessage = false
        observer?.acceptSource = .JS
        observer?.acceptRuntimeId = lynxView.getLynxRuntimeId()?.intValue ?? 0

        return LynxAddLogObserverByModel(observer)
    }

    // MARK: - OPBlockBridgeDelegate

    /// 接收 Block 回调，调用 API Handler
    /// - Parameters:
    ///   - name: event name，通常是 api name
    ///   - param: event 携带的相关参数
    ///   - callback: lynxCallback, 处理结果通过这个 callback 给出去
    func invoke(name: String, param: [AnyHashable : Any], callback: LynxCallbackBlock?) {
        trace.info("OPBlockComponent.invoke apiName: \(name)")
        let eventContext = OPEventContext(userInfo: [:])
        let param = param as? [String: AnyHashable] ?? [:]

        let useAPIPlugin = apiSetting?.useAPIPlugin(
            host: containerContext.uniqueID.host,
            blockTypeId: containerContext.uniqueID.identifier,
            apiName: name
        ) ?? false
        if useAPIPlugin {
            apiBridge.invokeApi(apiName: name, param: param) { (status, response) in
                let data = OPBlockComponent.callbackData(name: name, status: status, response: response)
                callback?(data)
            }
        } else {
            /// TODO 添加 Component 的事件处理能力，现在先抛给 Container 去处理
            let _ = sendEvent(eventName: name, params: param, callbackBlock: { [weak trace](result) in
                trace?.info("OPBlockComponent.invoke apiName: \(name) result \(result.type)")
                let data = OPBlockComponent.callbackData(name: name, result: result)
                callback?(data)
            }, context: eventContext)
        }
    }
    
    class func callbackData(name: String, status: BDPJSBridgeCallBackType, response: [AnyHashable: Any]?) -> [AnyHashable: Any] {
        var data = response ?? [:]
        var errMsg = name + ":"
        switch status {
        case .success:
            errMsg += "ok"
        case .userCancel:
            errMsg += "cancel"
        case .noHandler:
            errMsg += "fail feature is not supported in app"
        default:
            errMsg += "fail"
        }
        if let msg = data["errMsg"] as? String {
            errMsg += msg
        }
        errMsg = errMsg.trimmingCharacters(in: .whitespacesAndNewlines)
        data["errMsg"] = errMsg

        return data
    }
    // 目前返回数据格式同小程序
    class func callbackData(name: String, result: OPEventResult) -> [AnyHashable: Any] {
        var data = result.data ?? [:]
        var errMsg = name + ":"
        // 对齐小程序之前的协议，否则 JSSDK 可能会无法解析报错
        if result.type == OPEventResultType.success.rawValue {
            errMsg += "ok"
        } else if result.type == OPEventResultType.cancel.rawValue {
            errMsg += "cancel"
        } else if result.type == OPEventResultType.noHandler.rawValue {
            errMsg += "fail feature is not supported in app"
        } else {
            errMsg += "fail"
        }
        if let msg = data["errMsg"] as? String {
            errMsg += msg
        }
        errMsg = errMsg.trimmingCharacters(in: .whitespacesAndNewlines)
        data["errMsg"] = errMsg

        return data
    }
    // MARK: - LynxViewLifecycle
    func lynxViewDidUpdate(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidUpdate")
    }
    
    func lynxViewDidFirstScreen(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidFirstScreen")
		if !fixFinish {
			lifeCycleListeners.forEach { (listener) in
				listener.value?.onComponentReady?()
			}
		}
    }

    func lynxViewDidStartLoading(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidstartloading")
    }

    func lynxView(_ view: LynxView!, didRecieveError error: Error!) {
        trace.error("OPBlockComponent.lynxView.didRecieveError error: \(error.localizedDescription)")
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: EPMClientOpenPlatformBlockitLynxCode.receive_lynx_error)
            .setUniqueID(context.uniqueID)
            .addCategoryValue("from", "lynx")
            .addCategoryValue("host", (containerContext.containerConfig as? OPBlockContainerConfig)?.host)
            .addCategoryValue("path", view.url?.md5())
            .setError(error)
            .tracing(containerContext.blockContext.trace)
            .flush()
    }

    func lynxView(_ view: LynxView!, didReceiveUpdatePerf perf: LynxPerformance!) {
        let perfDict = perf.toDictionary() as? [String: Any]
        trace.info("OPBlockComponent.lynxView.didReceiveUpdatePerf perf: \(perfDict)")
        /// TODO log & monitor
        OPMonitor("op_block_load_lynx_update_load")
            .setUniqueID(context.uniqueID)
            .addMap(perfDict)
            .flush()
    }

    func lynxView(_ view: LynxView!, didReceiveFirstLoadPerf perf: LynxPerformance!) {
        let perfDict = perf.toDictionary() as? [String: Any]
        trace.info("OPBlockComponent.lynxView.didReceiveFirstLoadPerf perf: \(perfDict)")
        /// TODO log & monitor
        OPMonitor("op_block_load_lynx_first_load")
            .setUniqueID(context.uniqueID)
            .addMap(perfDict)
            .flush()
    }

    func lynxViewDidChangeIntrinsicContentSize(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidChangeIntrinsicContentSize")
        hostDelegate?.contentSizeDidChange(self, newSize: view.intrinsicContentSize, context: containerContext.blockContext)
    }
    
    struct Event {
        let name: String
        let param: [AnyHashable: Any]?
        let callback: OPBridgeCallback?
    }
    
    func lynxViewDidConstructJSRuntime(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidConstructJSRuntime")
        
        lock.lock()

		hostDelegate?.onBlockLoadReady(self, context: containerContext.blockContext)
        
        isRuntimeReady = true
        do {
            try eventBuffer.forEach { event in
                try rawSendEventToBridge(eventName: event.name, params: event.param, callback: event.callback)
            }
        } catch let e {
            trace.error("OPBlockComponent.lynxViewDidConstructJSRuntime try rawSendEventToBridge error: \(e.localizedDescription)")
        }
        eventBuffer.removeAll()
        
        lock.unlock()
    }
    
    // MARK: - OPBaseBridgeDelegate {
    func sendEventToBridge(eventName: String, params: [AnyHashable : Any]?, callback: OPBridgeCallback?) throws {
        lock.lock()
        trace.info("OPBlockComponent.sendEventToBridge \(eventName), isRuntimeReady: \(isRuntimeReady)")
        if isRuntimeReady {
            try rawSendEventToBridge(eventName: eventName, params: params, callback: callback)
        } else {
            eventBuffer.append(Event(name: eventName, param: params, callback: callback))
        }
        lock.unlock()
    }
}

/// 单独抽这么一个类，主要是因为 LynxView 内部会强持有 Listener，被迫通过这个类中转下 🤷‍♂️
class LynxViewLifecycleListener: NSObject, LynxViewLifecycle {
    weak var delegate: LynxViewLifecycle?

    private let containerContext: OPContainerContext

    // block picker支持配置显示层级（显示在window上或显示在当前vc）
    private var showPickerInWindow: Bool {
        userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableShowPickerInWindow.key)
    }

    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    private let userResolver: UserResolver

    init(
        userResolver: UserResolver,
        delegate: LynxViewLifecycle,
        containerContext: OPContainerContext
    ) {
        self.userResolver = userResolver
        self.delegate = delegate
        self.containerContext = containerContext
    }

    func lynxViewDidUpdate(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidUpdate")
        delegate?.lynxViewDidUpdate?(view)
    }

    func lynxViewDidFirstScreen(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidFirstScreen")
		OPMonitor(name: String.OPBlockitMonitorKey.eventName,
				  code: EPMClientOpenPlatformBlockitLynxCode.lynx_first_screen)
			.setUniqueID(containerContext.uniqueID)
			.addCategoryValue("from", "lynx")
			.addCategoryValue("host", (containerContext.containerConfig as? OPBlockContainerConfig)?.host)
			.addCategoryValue("path", view.url?.md5())
			.setResultTypeSuccess()
			.tracing(containerContext.blockContext.trace)
			.flush()
        delegate?.lynxViewDidFirstScreen?(view)
    }

    func lynxViewDidStartLoading(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidStartLoading")
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchComponent.start_render_page)
            .setUniqueID(containerContext.uniqueID)
            .addMap(["render_type": "block_dsl", "path": view.url?.md5()])
            .tracing(containerContext.blockContext.trace)
            .flush()
        delegate?.lynxViewDidStartLoading?(view)
    }

    func lynxView(_ view: LynxView!, didLoadFinishedWithUrl url: String!) {
        trace.info("OPBlockComponent.lynxView.didLoadFinishedWithUrl url: \(String(describing: NSString.safeURLString(url)))")
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchComponent.render_page_result)
            .addMap(["render_type": "block_dsl",
                     "path": view.url?.md5()])
            .setResultTypeSuccess()
            .tracing(containerContext.blockContext.trace)
            .flush()
        delegate?.lynxView?(view, didLoadFinishedWithUrl: url)
    }

    func lynxView(_ view: LynxView!, didRecieveError error: Error!) {
        trace.error("OPBlockComponent.lynxView.didRecieveError error: \(error.localizedDescription)")
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchComponent.render_page_result)
            .addMap(["render_type": "block_dsl",
                     "path": view.url?.md5()])
            .setResultTypeFail()
            .setError(error)
            .tracing(containerContext.blockContext.trace)
            .flush()
        delegate?.lynxView?(view, didRecieveError: error)
    }

    func lynxView(_ view: LynxView!, didReceiveUpdatePerf perf: LynxPerformance!) {
        trace.info("OPBlockComponent.lynxView.didReceiveUpdatePerf perf: \(perf.toDictionary())")
        delegate?.lynxView?(view, didReceiveUpdatePerf: perf)
    }

    func lynxView(_ view: LynxView!, didReceiveFirstLoadPerf perf: LynxPerformance!) {
        trace.info("OPBlockComponent.lynxView.didReceiveFirstLoadPerf perf: \(perf.toDictionary())")
        delegate?.lynxView?(view, didReceiveFirstLoadPerf: perf)
    }
    
    func lynxViewDidConstructJSRuntime(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidConstructJSRuntime")
		OPMonitor(name: String.OPBlockitMonitorKey.eventName,
				  code: EPMClientOpenPlatformBlockitLynxCode.lynx_runtime_ready)
			.setUniqueID(containerContext.uniqueID)
			.addCategoryValue("from", "lynx")
			.addCategoryValue("host", (containerContext.containerConfig as? OPBlockContainerConfig)?.host)
			.addCategoryValue("path", view.url?.md5())
			.setResultTypeSuccess()
			.tracing(containerContext.blockContext.trace)
			.flush()
        delegate?.lynxViewDidConstructJSRuntime?(view)
    }
    
    func lynxViewDidChangeIntrinsicContentSize(_ view: LynxView!) {
        trace.info("OPBlockComponent.lynxViewDidChangeIntrinsicContentSize")
        delegate?.lynxViewDidChangeIntrinsicContentSize?(view)
    }
    
    func lynxViewDidCreateElement(_ element: LynxUI<UIView>!, name: String!) {
        // 设置swiper组件默认值
        if let swiperView = element.view() as? BDXLynxSwiperView {
            swiperView.isCircle = false
            swiperView.autoScrollInterval = 5
        }

        if showPickerInWindow,
            let pickerView = element as? BDXLynxUIPicker,
           let showInWindow = (containerContext.containerConfig as? OPBlockContainerConfig)?.showPickerInWindow {
            pickerView.showInWindow = showInWindow
        }
    }

	func lynxView(_ view: LynxView!, didReportComponentInfo componentSet: Set<String>!) {
		OPMonitor(name: String.OPBlockitMonitorKey.eventName,
				  code: EPMClientOpenPlatformBlockitLynxCode.lynx_report_component)
			.setUniqueID(containerContext.uniqueID)
			.addCategoryValue("from", "lynx")
			.addCategoryValue("host", (containerContext.containerConfig as? OPBlockContainerConfig)?.host)
			.addCategoryValue("path", view.url?.md5())
			.addCategoryValue("components", componentSet)
			.setResultTypeSuccess()
			.tracing(containerContext.blockContext.trace)
			.flush()
	}
}

extension OPBlockComponent {
    
    func rawSendEventToBridge(eventName: String, params: [AnyHashable : Any]?, callback: OPBridgeCallback?) throws {
        trace.info("OPBlockComponent.rawSendEventToBridge eventName: \(eventName)")
        defer {
            callback?(nil)
        }
        guard let apiModule = lynxView.getJSModule(Constants.LynxModuleName) else {
            trace.error("OPBlockComponent.rawSendEventToBridge error: \(Constants.LynxModuleName) not found")
            throw OPSDKMonitorCode.unknown_error.error(message: "\(Constants.LynxModuleName) not found")
        }

        var eventParam = ""
        if params != nil {
            let data = try JSONSerialization.data(withJSONObject: params!, options: [])
            eventParam = String(data: data, encoding: .utf8) ?? ""
        }

        apiModule.fire(Constants.LynxEventTrigger, withParams: [eventName, eventParam])
    }
}
