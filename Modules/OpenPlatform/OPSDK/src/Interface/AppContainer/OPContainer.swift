//
//  OPContainer.swift
//  OPSDK
//
//  Created by yinyuan on 2020/10/27.
//

import Foundation
import ECOProbe
import OPFoundation

/// Container 对外的接口
@objc public protocol OPContainerProtocol: OPNodeProtocol {
    
    /// Container 的上下文
    var containerContext: OPContainerContext { get }
    
    var bridge: OPBridgeProtocol { get }
    
    var updater: OPContainerUpdaterProtocol? { get }

    /// 开放容器运行时环境的版本号，目前在业务层只对 Block 生效，对 gadget 屏蔽
    var runtimeVersion: String { get }

    var sandbox: BDPSandboxProtocol? { get }
    /// 是否支持 dark mode
    var isSupportDarkMode: Bool { get }

    func addLifeCycleDelegate(delegate: OPContainerLifeCycleDelegate)
    
    /// 加载渲染到指定位置
    ///
    /// 如果之前已调用过 mount 但还未 unmount，会自动调用一次 unmount 然后重新 mount
    func mount(data: OPContainerMountDataProtocol, renderSlot: OPRenderSlotProtocol)
    
    /// 从界面移除，不再显示
    ///
    /// 可能会回收一部分界面相关的内存
    func unmount(monitorCode: OPMonitorCode)
    
    
    /// 重新加载
    func reload(monitorCode: OPMonitorCode)
    
    /// 销毁并完全退出
    ///
    /// - Note: ⚠️ 调用 destroy 后，请不要再调用该 Container 实例的任何接口，否则可能会触发 Crash 等严重后果
    func destroy(monitorCode: OPMonitorCode)
    
    
    /// 宿主需要在 slot 显示时调用
    func notifySlotShow()
    
    /// 宿主需要在 slot 隐藏时调用
    func notifySlotHide()
    
    /// 通知需要暂停运行（例如整个App进程退到后台或者冻结）
    func notifyPause()
    
    /// 通知需要恢复运行（例如整个App进程回到前台或者解除冻结），但应用是否最终能够恢复运行还与其他条件有关，这里不是唯一的决定因素
    func notifyResume()

    /// 通知当前主题有变化
    func notifyThemeChange(theme: String)
    
    func removeTemporaryTab()
    
}


/// Container 上下文
///
/// - Note: ⚠️该对象在体系内广泛传播和被持有，因此不允许强引用持有大的对象，否则可能会造成严重的内存泄露。如果一定要持有大对象，请使用 weak。
/// - Note: ⚠️只有在体系内被广泛传播和使用的信息，才有资格放入Context对象之内。该对象的所有增加项都应当得到充分的考虑和严谨的评估。
@objcMembers public final class OPContainerContext: NSObject {
    
    /// Application 上下文
    public let applicationContext: OPApplicationContext
    
    /// Container 唯一ID
    public let uniqueID: OPAppUniqueID
    
    /// 可用性
    public internal(set) var availability: OPContainerAvailability = .unload
    
    /// 活跃
    public internal(set) var activeState: OPContainerActiveState = .active          // 默认 active 状态
    
    /// 可见性
    public internal(set) var visibility: OPContainerVisibility = .invisible
    
    /// mount 状态(mount 不等于 可见)
    public internal(set) var mountState: OPContainerMountState = .unmount
    
    /// 容器创建时的配置，创建后不能再更改
    public let containerConfig: OPContainerConfigProtocol
    
    /// 该 Container 实例首次 mount 时传入的初始化数据
    public var firstMountData: OPContainerMountDataProtocol?
    
    /// 该  Container 最近一次 mount 时传入的初始化数据
    public var currentMountData: OPContainerMountDataProtocol?
    
    /// 是否正在 reload（需要兼容一些小程序的现状，待优化）
    public var isReloading: Bool = false
    
    /// UI表现配置
    public let apprearenceConfig: OPContainerApprearenceConfig = OPContainerApprearenceConfig()
    
    /// 应用所在的 window (如果有)，可用于支持 iPad 多 Scene
    public weak var window: UIWindow?

    /// 属于当前容器的错误恢复器
    public lazy var recoverier: Recoverier? = createRecoverier()

    /// 当前 container 的 trace 对象
    public var trace: OPTrace?

    /// 当前 container 为 block 时向BlockTrace类型中转的trace对象
    public var baseBlockTrace: OPLogProtocol?

    /// 当前 container 的元数据
    public var meta: OPBizMetaProtocol?
    
    public init(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID, containerConfig: OPContainerConfigProtocol) {
        self.uniqueID = uniqueID
        self.applicationContext = applicationContext
        self.containerConfig = containerConfig
    }
}


@objcMembers public final class OPContainerApprearenceConfig: NSObject {
        
    public var forceNavigationBarHidden: Bool = false   // 不显示导航栏
    
    public var forceTabBarHidden: Bool = false          // 不显示Tab栏
    
    public var forceExtendedLayoutIncludesOpaqueBars: Bool = false      // 为 Controller 开启 extendedLayoutIncludesOpaqueBars 属性，在不透明的导航栏下也显示（Tab小程序会用到）
    
    public var showDefaultLoadingView: Bool = false       // 显示默认的 LoadingView
    
    public var forbidUpdateWhenRunning: Bool = false        // 禁用应用的运行时更新能力
}
