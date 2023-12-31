//
//  OPContainerLifeCycle.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/16.
//

import Foundation
import LarkOPInterface

/// Container 的活跃状态
///
/// 非活跃状态将可能会停止一些不必要的耗电行为
@objc public enum OPContainerActiveState: Int {
    case inactive   // 非活跃状态
    case active     // 活跃状态
}

/// Container 的可用状态
///
/// 未加载、加载中、或者加载失败时，应用都不可用
@objc public enum OPContainerAvailability: Int {
    case unload         // 不可用状态
    case loading        // 加载中状态
    case ready          // 可用状态
    case failed         // 失败状态
    case destroyed      // 已销毁(不可逆状态)
}

/// Container 的可见状态
///
/// 应用是否正在前台展示
@objc public enum OPContainerVisibility: Int {
    case invisible      // 不可见状态
    case visible        // 可见状态
}

/// Container 的Mount状态
///
/// Container 是否已被Mount，需要注意已Mount的Container未必正在显示
@objc public enum OPContainerMountState: Int {
    case mounted        // 已装载到视图容器中（但不一定可见，是否可见还与视图容器是否显示有关）
    case unmount        // 未装载到视图容器中（一定不可见）
}

/// Container 对外的生命周期事件
///
/// 需要注意，不是所有的生命周期事件都需要对外，这里只放必要的即可
/// 需要区分，对外的生命周期事件的目标用户(需要监听Container生命周期的人) 与 Container 接口的目标用户(使用 Container 的人) 可能是不同的，不要混淆
@objc public protocol OPContainerLifeCycleDelegate: AnyObject {
    
    // MARK: - 加载生命周期事件
    
    /// Container 开始加载，此时 Container 处于 Loading 状态
    func containerDidLoad(container: OPContainerProtocol)
    
    /// Container 加载完成，此时 Container 处于 Available 状态
    func containerDidReady(container: OPContainerProtocol)
    
    /// Container 出现加载失败或运行时者崩溃，此时 Container 处于 Unavailable 状态
    func containerDidFail(container: OPContainerProtocol, error: OPError)
    
    /// Container 卸载，此时 Container 处于 Unavailable 状态
    func containerDidUnload(container: OPContainerProtocol)
    
    /// Container 销毁，全部内存回收，不可用无状态
    func containerDidDestroy(container: OPContainerProtocol)
    
    
    // MARK: - 可见性变化生命周期事件
    
    /// Container 从不可见状态变为可见状态，此时 Container 处于 Visible 状态
    func containerDidShow(container: OPContainerProtocol)
    
    /// Container 从可见状态变为不可见状态，此时 Container 处于 Invisible 状态
    func containerDidHide(container: OPContainerProtocol)
    
    
    // MARK: - 活跃性变化生命周期事件
    
    /// Container 从 active 状态变为 inactive 状态
    func containerDidPause(container: OPContainerProtocol)
    
    /// Container 从 inactive 状态变为 active 状态
    func containerDidResume(container: OPContainerProtocol)
    
    // MARK: - 其他事件
    
    /// Container 包中的静态配置加载成功
    func containerConfigDidLoad(container: OPContainerProtocol, config: OPProjectConfig)


}
