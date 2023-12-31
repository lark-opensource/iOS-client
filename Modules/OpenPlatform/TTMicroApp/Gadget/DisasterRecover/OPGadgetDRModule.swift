//
//  OPGadgetDRModule.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/16.
//

import Foundation
import LarkCache
import Dispatch

/// 容灾模块优先级，数值越低，优先级越高
public enum DRModulePriority : Int, Encodable {
    case unknown = 0
    case jssdk = 1
    case pkm = 2
    case preload = 3
    case warmboot = 4
    case timout = 5
}

/// 容灾module name 定义:["JSSDK","PKM","PRELOAD","WARMBOOT"]
public enum DRModuleName: String, Equatable {
    case JSSDK = "JSSDK"
    case PKM = "PKM"
    case PRELOAD = "PRELOAD"
    case WARMBOOT = "WARMBOOT"
}


protocol OPGadgetDRModuleLifecycle: AnyObject {
     func moduleDidFinished(_ drModule: OPGadgetDRModule)
}

/// 小程序容灾Module 仅仅包含一个task 任务
class OPGadgetDRSingleTaskModule : OPGadgetDRModule {
    
    override class func getModuleName() -> String {
        return ""
    }
    
    override class func getPriority() -> DRModulePriority {
        return .unknown
    }
    
    override func startDRModule(config: OPGadgetDRConfig?) {
        self.config = config
        moduleDidFinished(self)
    }
    
}

/// 小程序容灾按照Module维度来组装，module 基类
class OPGadgetDRModule : NSObject, OPGadgetDRTaskLifecycle  {
    
    /// 所有任务集合
    private var moduleTasks: [OPGadgetDRTask]
    var config: OPGadgetDRConfig?
    private var taskIndex : Int = 0
    weak var moduleDelegate : OPGadgetDRModuleLifecycle?
    let lock: OPGadgetDRRecursiveLock = OPGadgetDRRecursiveLock()
    
    public required override init() {
        self.moduleTasks = []
    }
    
    class func getModuleName() -> String {
        return ""
    }
    
    class func getPriority() -> DRModulePriority {
        return .unknown
    }
    
    func getRecoverTasks(config: OPGadgetDRConfig?) -> [OPGadgetDRTask] {
        return []
    }
    
    /// 开始执行module 中中的任务
    /// - Parameter config: 根据配置信息进行清理逻辑处理
    func startDRModule(config: OPGadgetDRConfig?) {
        self.config = config
        let tasks = getRecoverTasks(config: self.config)
        lock.sync {
            self.moduleTasks.append(contentsOf: tasks)
        }
        startTaskIfNeed()
    }
    
    
    /// 当前有任务可以执行时，触发第一个任务执行；否则Module 结束并进行回调
    /// - Returns: 当前是否有新任务执行， true / fasle
    @discardableResult func startTaskIfNeed() -> Bool {
        var nextTask: OPGadgetDRTask? = nil
        lock.sync {
            if !self.moduleTasks.isEmpty , let firstTask = self.moduleTasks.first {
                nextTask = firstTask
            }
        }
        if let willRunTask = nextTask {
            willRunTask.execute(config: self.config)
            return true
        }else {
            moduleDidFinished(self)
            return false
        }
    }
    
    
    ///  ``OPGadgetDRTask`` 执行完成回调
    /// - Parameter curTask: 当前执行完成task
    func taskDidFinished(_ curTask: OPGadgetDRTask) {
        lock.sync {
            if self.moduleTasks.contains(curTask) {
                self.moduleTasks.lf_remove(object: curTask)
            }
        }
        startTaskIfNeed()
    }
    
    func moduleDidFinished(_ drModule: OPGadgetDRModule) {
        OPGadgetDRLog.logger.info("moduleDidFinished, module name:\(type(of: drModule).getModuleName())")
        self.moduleDelegate?.moduleDidFinished(self)
    }
    
}

/// 一次容灾任务，包含多个module, 每个module 又包含多个任务
class OPGadgetDRModuleGroup: NSObject, OPGadgetDRModuleLifecycle {
    // 容灾module class  和 module name 映射
    static var moduleTypeMap:[String:OPGadgetDRModule.Type] = [:]
    let moduleConfig: OPGadgetDRConfig
    // 容灾包含哪些module
    private var modules: [OPGadgetDRModule] = []
    weak var groupLifeCycle: OPGadgetDRModuleGroupLifecycle?
    internal let lock: OPGadgetDRRecursiveLock = OPGadgetDRRecursiveLock()
    private var timeoutItem: DispatchWorkItem? = nil
    var groupState: DRRunState = .unknown
    private var startTime : Date? = nil
    
    init(moduleConfig: OPGadgetDRConfig) {
        self.moduleConfig = moduleConfig
    }
    
    
    /// 注册容灾module name 和 Module Class 映射关系
    /// - Parameter moduleType: Module Class
    /// - Returns: void
    class func registerDRModule(_ moduleType: OPGadgetDRModule.Type) -> Void {
        let moduleName = moduleType.getModuleName()
        assert(!OPGadgetDRModuleGroup.moduleTypeMap.keys.contains(moduleName), "module with \(moduleName) name had register! ")
        OPGadgetDRModuleGroup.moduleTypeMap[moduleName] = moduleType
    }
    
    /// 根据配置组装modules
    /// - Returns: 组装module
    func buildDRModules() -> [OPGadgetDRModule] {
        var settingModule:[OPGadgetDRModule] = []
        moduleConfig.modules.forEach { moduleName in
            if let moduleType = Self.moduleTypeMap[moduleName] {
                settingModule.append(moduleType.init())
            }
        }
        return settingModule
    }
    
    /// 生成容灾任务
    /// - Returns: 返回需要执行容灾任务的Module 数组
    func buildGroupModules() -> [OPGadgetDRModule] {
        var modulesForScene : [OPGadgetDRModule] = buildDRModules()
        modulesForScene.forEach { drModule in
            drModule.moduleDelegate = self
        }
        modulesForScene.sort { firstModule, secondModule in
            type(of: firstModule).getPriority().rawValue > type(of: secondModule).getPriority().rawValue
        }
        
        return modulesForScene
    }
    
    
    /// 开始执行容灾，按照Module 为单元串行执行
    func executeModule() {
        startTime = Date()
        // 如果是setting 触发容灾，防止容灾执行时有小程序打开
        if moduleConfig.triggerScene == .serverSetting, BDPWarmBootManager.shared().hasCacheData() {
            OPGadgetDRLog.logger.info("DRModule group execute failed is there warmboot gadget")
            self.groupLifeCycle?.finishModuleGroup(moduleGroup: self)
            return
        }
        
        lock.sync {
            self.modules = buildGroupModules()
            self.groupState = .running
            // 设置容灾任务超时，超时强制任务结束
            let timeItem = DispatchWorkItem {[weak self] in
                self?.finishModuleGroup(state: .timeout)
            }
            let delayTime = DispatchTime.now() + .milliseconds(Int(OPGadgetDRManager.shareManager.timeoutSeconds()*1000))
            DispatchQueue.global().asyncAfter(deadline: delayTime, execute: timeItem)            
            self.timeoutItem = timeItem
        }
        storeDRState(state: .running)
        startModuleIfNeed()
        OPGadgetDRMonitor.monitorEvent(state: DRRunState.running.rawValue, params: moduleConfig.drMonitorParams(), totalTime: 0)
    }
    
    
    /// 执行moudle ，如果module 全部执行完成，当前容灾任务执行完成，回调给``OPGadgetDRManager``
    func startModuleIfNeed() {
        var nextModule: OPGadgetDRModule? = nil
        lock.sync {
            if !self.modules.isEmpty , let firstModule = self.modules.first {
                nextModule = firstModule
            }
        }
        if let willRunModule = nextModule {
            willRunModule.startDRModule(config: self.moduleConfig)
        }else {
            finishModuleGroup(state: .finished)
        }
    }
    
    /// 按照Module 维度执行完成回调，删除当前执行module ，并触发``startModuleIfNeed()``
    /// - Parameter drModule: finished ``OPGadgetDRModule`` object
    func moduleDidFinished(_ drModule: OPGadgetDRModule) {
        lock.sync {
            if self.modules.contains(drModule) {
                self.modules.lf_remove(object: drModule)
            }
        }
        self.startModuleIfNeed()
    }
    
    /// 全部Module 执行完成，记录相关配置信息，并触发相关回调
    /// - Parameter state: 当前执行状态
    func finishModuleGroup(state: DRRunState) {
        OPGadgetDRLog.logger.info("finish module group, trigger scene:\(self.moduleConfig.triggerScene), state:\(state)")
        var hadFinished = false
        lock.sync {
            if self.groupState == .finished || self.groupState == .timeout {
                hadFinished = true
            }
            self.groupState = state
            // 清除超时timer
            if let safeTimeoutItem = self.timeoutItem {
                safeTimeoutItem.cancel()
                self.timeoutItem = nil
            }
        }
        // 已经finished 或者 timeout，提前终止后续行为
        if hadFinished {
            OPGadgetDRLog.logger.warn("module group had finished !")
            return
        }
        
        // 如果是server setting 配置，记录执行完成状态
        storeDRState(state: state)
        
        // 手动触发larksetting 时，通过config 回调``CleanTask`` completion, 可以更通用一点，所有的场景都可以触发这种逻辑
        if self.moduleConfig.triggerScene == .larkSetting, let groupCompletion = self.moduleConfig.completion {
            if let taskResut = self.moduleConfig.taskResult  {
                groupCompletion(taskResut)
            }else {
                groupCompletion(TaskResult(completed: false, costTime: 0, size: .bytes(0)))
            }
        }
        self.groupLifeCycle?.finishModuleGroup(moduleGroup: self)
        
        // 计算容灾任务耗时
        var totalTime : Int64 = 0
        if let safeStartTime = startTime {
            totalTime = Int64(Date().timeIntervalSince(safeStartTime)*1000)
        }
        /// 任务执行结束上报埋点信息
        OPGadgetDRMonitor.monitorEvent(state: state.rawValue, params: moduleConfig.drMonitorParams(), totalTime: totalTime)
    }
    
    
    /// 如果是server setting 配置，记录执行完成状态
    /// - Parameter state: 容灾执行状态
    func storeDRState(state: DRRunState) {
        if moduleConfig.triggerScene == .serverSetting {
            DRCacheConfig.storeDRConfig(config: moduleConfig, state: state)
        }
    }
}
