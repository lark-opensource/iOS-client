//
//  OPBlockContainerConfig.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/18.
//

import Foundation
import OPSDK
import LarkFeatureGating
import ECOProbe
import ECOInfra
import Swinject
import OPFoundation

public enum OPBlockUpdateInfo {
    case `default`(String?)
    case bug(String?)
    case feature(String?)
    public static func map(updateType: OPAppExtensionMetaUpdateType?, updateDescription: String?) -> OPBlockUpdateInfo {
        guard let type = updateType else {
            return .default(nil)
        }
        switch type {
        case .bug:
            return .bug(updateDescription)
        case .feature:
            return .feature(updateDescription)
        default:
            return .default(nil)
        }
    }
}

public enum OPBlockHost: String {
    case workplace
    case search
}

public enum OPBlockScene: String {
    case workplace_dsl
    case workplace_h5
    case search_dsl
    case search_h5
}

/// block 初始化数据协议的默认实现
@objcMembers public final class OPBlockContainerConfig: OPContainerConfig, OPBlockContainerConfigProtocol {

    public private(set) var blockLaunchMode: OPBlockLaunchMode = .default

    public var customApis: [[AnyHashable : Any]]?

    public let host: String

    public var blockInfo: OPBlockInfo?

    public var uniqueID: OPAppUniqueID

    public var blockLaunchType: OPBlockLaunchType = .default

    public var dataCollection: [AnyHashable: Any]?
    
    public var containerID: String?
    
    public var isCustomLifecycle = false
    
    public var useCacheWhenEntityFetchFails = false

    public var useCustomRenderLoading = false

	public let blockContext: OPBlockContext

    // 是否将picker显示在最上层
    public var showPickerInWindow: Bool = false
    
    public let trace: OPTrace = OPTraceService.default().generateTrace()

    public var errorPageCreator: OPBlockErrorPageCreator?

    /// Biz-level timeout interval (ms), -1 means no timer
    public var bizTimeoutInterval: Int = -1

    public init(uniqueID: OPAppUniqueID,
                blockLaunchMode: OPBlockLaunchMode,
                previewToken: String,
                host: String) {
        self.uniqueID = uniqueID
        self.blockLaunchMode = blockLaunchMode
        self.host = host
		self.blockContext = OPBlockContext(uniqueID: uniqueID, trace: trace)
        super.init(previewToken: previewToken, enableAutoDestroy: false)
    }

    public override var description: String {
        return "blockLaunchMode:\(blockLaunchMode.rawValue), host:\(host)"
    }
}

/// Block 容器特有的生命周期函数

public protocol OPBlockContainerLifeCycleDelegate: OPContainerLifeCycleDelegate {

    /// 异步 meta 及 pkg 更新
    func containerUpdateReady(info: OPBlockUpdateInfo, context: OPBlockContext)

    /// creator 模式启动成功
    /// - Parameter param: block setBlockInfo 业务传递过来的参数
    func containerCreatorDidReady(param: [AnyHashable: Any], context: OPBlockContext)

    /// creator 模式启动失败，业务端调用
    func containerCreatorDidCancel(context: OPBlockContext)

    /// Biz-level timeout
    func containerBizTimeout(context: OPBlockContext)

    /// Biz-level render success
    func containerBizSuccess(context: OPBlockContext)

    /// Share enable state update
    func containerShareStatusUpdate(context: OPBlockContext, enable: Bool)

    /// Share info ready
    func containerShareInfoReady(context: OPBlockContext, info: OPBlockShareInfo)

    func tryHideBlock(context: OPBlockContext)
}

public extension OPBlockContainerLifeCycleDelegate {

    func containerUpdateReady(info: OPBlockUpdateInfo, context: OPBlockContext) {}

    func containerCreatorDidReady(param: [AnyHashable: Any], context: OPBlockContext) {}

    func containerCreatorDidCancel(context: OPBlockContext) {}

    func containerBizTimeout(context: OPBlockContext) {}

    func containerBizSuccess(context: OPBlockContext) {}

    func containerShareStatusUpdate(context: OPBlockContext, enable: Bool) {}

    func containerShareInfoReady(context: OPBlockContext, info: OPBlockShareInfo) {}

    func tryHideBlock(context: OPBlockContext) {}
}

@objc
public enum OPBlockDebugLogLevel: Int {
    case info
    case warn
    case error
}

/// Block --> Host
@objc
public protocol OPBlockHostProtocol: NSObjectProtocol {
    /// Block 收到日志消息
    func didReceiveLogMessage(_ sender: OPBlockEntityProtocol, level: OPBlockDebugLogLevel, message: String, context: OPBlockContext)

    /// Block 内容大小发生变化
    func contentSizeDidChange(_ sender: OPBlockEntityProtocol, newSize: CGSize, context: OPBlockContext)

    /// 隐藏宿主的 loading 页面
    func hideBlockHostLoading(_ sender: OPBlockEntityProtocol)

	/// block收到runtimeReady事件，代表onLoad事件发送到业务方了
	func onBlockLoadReady(_ sender: OPBlockEntityProtocol, context: OPBlockContext)
}

/// Host --> Block
/// 废弃协议，先删方法，后续外部适配
@objc
public protocol OPBlockEntityProtocol: NSObjectProtocol {
}

/// 用于向BlockContainer注入Service
@objc
public final class OPBlockServiceContainer: NSObject {

    private let container = Container()
    
    public func register<Service>(_ serviceType: Service.Type, factory: @escaping () -> Service) {
        container.register(serviceType) { _ in
            return factory()
        }.inObjectScope(.container)
    }
    public func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        return container.resolve(serviceType)
    }
}

@objc
public protocol OPBlockContainerProtocol: OPContainerProtocol, OPBlockEntityProtocol {
    /// 保存宿主的弱引用
    weak var hostDelegate: OPBlockHostProtocol? { get set }
    
    var serviceContainer: OPBlockServiceContainer { get }
    /// 宿主通知component重刷页面
    func reRednerCurrentPage()
}

public protocol OPBlockAbilityHandler {
    /// 检查Block包更新
    func checkBlockUpdate()
    
    /// 刷新OPBlockAbilityHandler中的localMetaVersion
    func setLocalMetaVersion(metaVersion: String)
}

// 预安装协议
public protocol OPBlockPreUpdateProtocol {
    /// 预安装block
    func preLoad(idList: [OPAppUniqueID])
}

/// 此协议为中间态，为了区分Block DSL 和 Block Web 不同的生命周期协议；后续重构后，将会废弃OPBlockWebLifeCycleDelegate和OPBlockHostProtocol，仅扩展和使用BlockitLifeCycleDelegate
/// 目前需要宿主实现OPBlockWebLifeCycleDelegate & OPBlockHostProtocol & BlockitLifeCycleDelegate三个协议
/// 该OPBlockWebLifeCycleDelegate协议目前为block web才会触发的生命周期事件；
/// OPBlockHostProtocol 为block lynx才会触发的生命周期事件；
/// BlockitLifeCycleDelegate 为不区分形态，即block lynx和block web均会触发的什么周期事件
public protocol OPBlockWebLifeCycleDelegate: NSObjectProtocol {

    // 页面开始加载, 会发送多次
    // 每次路由跳转新页面加载成功触发
    func onPageStart(url: String?, context: OPBlockContext)

    // 页面加载成功, 会发送多次
    // 每次路由跳转新页面加载成功触发
    func onPageSuccess(url: String?, context: OPBlockContext)

    // 页面加载失败，会发送多次
    // 每次路由跳转新页面加载失败触发
    func onPageError(url: String?, error: OPError, context: OPBlockContext)

    // 页面运行时崩溃，会发送多次
    // 目前web场景会发送此事件，每次收到web的ProcessDidTerminate触发
    func onPageCrash(url: String?, context: OPBlockContext)

    // block 内容大小发生变化，会发送多次
    func onBlockContentSizeChanged(height: CGFloat, context: OPBlockContext)

}

// block生命周期事件
public enum OPBlockLifeCycleTriggerEvent: String {
	case finishLoad
	case show
	case hide
	case destory
}

// 定义Block自定义生命周期触发协议，实现后塞到context里，以方便对不同生命周期做处理，最终流转到block内部状态机
public protocol OPBlockCustomLifeCycleTriggerProtocol {}

// 定义block内部自定义生命周期触发协议，由block内部触发
public protocol OPBlockInternalCustomLifeCycleTriggerProtocol: OPBlockCustomLifeCycleTriggerProtocol {
	func triggerBlockLifeCycle(_ trigger: OPBlockLifeCycleTriggerEvent)
}

// 定义block宿主自定义生命周期触发协议，由宿主状态内部触发
public protocol OPBlockHostCustomLifeCycleTriggerProtocol: OPBlockCustomLifeCycleTriggerProtocol {
	func hostViewControllerDidAppear(_ appear: Bool)
}

/// Block 生命周期内的上下文，遵循 ECONetworkServiceContext，方便在api、网络等各种通用环境中透传
public final class OPBlockContext: NSObject, ECONetworkServiceContext {

    public let trace: OPTrace
    public let uniqueID: OPAppUniqueID
	public var lifeCycleTrigger: OPBlockCustomLifeCycleTriggerProtocol?
    public var blockAbilityHandler: OPBlockAbilityHandler?
    public var additionalInfo: [String: Any] = [:]

    public init(uniqueID: OPAppUniqueID, trace: OPTrace) {
        self.trace = trace
        self.uniqueID = uniqueID
        super.init()
    }

    public func getTrace() -> OPTrace {
        trace
    }
}

/// Block 启动模式
@objc
public enum OPBlockLaunchMode: Int {

	/// 启动默认首页
	case `default`

	/// 启动 creator 页
	case creator
}

@objc
public enum OPBlockLaunchType: Int {
	/// 缺省
	case `default`

	/// 标识当前为强制更新启动
	case forceUpdate
}

public protocol BaseBlockInfo {}

/// OPBlockInfo 其实就是 BlockInfo，未来会放弃 BlockInfo
@objc
public final class OPBlockInfo: NSObject, BaseBlockInfo {
	public let blockID: String
	public let blockTypeID: String
	public let sourceLink: String
	public let sourceData: [AnyHashable: Any]
	public let sourceMeta: [AnyHashable: Any]
	public let i18nPreview: String
	public let i18nSummary: String
	
	public init(blockID: String,
				blockTypeID: String,
				sourceLink: String = "",
				sourceData: [AnyHashable: Any] = [:],
				sourceMeta: [AnyHashable: Any] = [:],
				i18nPreview: String = "",
				i18nSummary: String = "") {
		self.blockID = blockID
		self.blockTypeID = blockTypeID
		self.sourceLink = sourceLink
		self.sourceData = sourceData
		self.sourceMeta = sourceMeta
		self.i18nPreview = i18nPreview
		self.i18nSummary = i18nSummary
	}
	
	public func toDictionary() -> [AnyHashable: Any] {
		[
			"blockID": blockID,
			"blockTypeID": blockTypeID,
			"sourceLink": sourceLink,
			"sourceData": sourceData,
			"sourceMeta": sourceMeta,
		]
	}
}


/// block 初始化数据协议
@objc
public protocol OPBlockContainerConfigProtocol: OPContainerConfigProtocol {

	var blockLaunchMode: OPBlockLaunchMode { get }
	
	var blockContext: OPBlockContext { get }

	var customApis: [[AnyHashable: Any]]? { get }

	/// 宿主标识，一些业务需要这个字段
	var host: String { get }

	var blockInfo: OPBlockInfo? { get set }

	var uniqueID: OPAppUniqueID { get }

	var blockLaunchType: OPBlockLaunchType { get }

	var dataCollection: [AnyHashable: Any]? { get set }

	var containerID: String? { get }
	
	var isCustomLifecycle: Bool { get }
	
	/// 是否开启 Block Entity 缓存兜底策略
	var useCacheWhenEntityFetchFails: Bool { get }
	
	/// 是否由宿主自定义显示render loading
	var useCustomRenderLoading: Bool { get }

	var trace: OPTrace { get }

    // 是否将picker显示在最上层
    var showPickerInWindow: Bool { get }

    var errorPageCreator: OPBlockErrorPageCreator? { get set }

    /// Biz-level timeout interval (ms), -1 means no timer
    var bizTimeoutInterval: Int { get set }
}

public extension OPContainerContext {
    // OPBlockContainerConfigProtocol为block初始化时使用的config协议，此处统一做强制类型转换
    var blockContext: OPBlockContext {
        let config = containerConfig as! OPBlockContainerConfigProtocol
        return config.blockContext
    }
}


/// Block share info
public struct OPBlockShareInfo: Codable {
    /// I18n title
    public let title: [String: String]?
    /// I18n imageKey
    public let imageKey: [String: String]?
    /// I18n detail button name
    public let detailBtnName: [String: String]?
    /// Redirect link for different platform
    public let detailBtnLink: [String: String]?
    /// I18n label
    public let customMainLabel: [String: String]?

    public init(title: [String : String]? = nil, imageKey: [String : String]? = nil, detailBtnName: [String : String]? = nil, detailBtnLink: [String : String]? = nil, customMainLabel: [String : String]? = nil) {
        self.title = title
        self.imageKey = imageKey
        self.detailBtnName = detailBtnName
        self.detailBtnLink = detailBtnLink
        self.customMainLabel = customMainLabel
    }
}
