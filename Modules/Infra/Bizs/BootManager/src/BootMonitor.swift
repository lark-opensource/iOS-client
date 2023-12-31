//
//  BootMonitor.swift
//  BootManager
//
//  Created by KT on 2020/6/29.
//

import UIKit
import Foundation
import os.signpost
import ThreadSafeDataStructure
import LKCommonsTracker

/// 启动阶段关键节点
public enum BootKeyNode: String {
    case unKnown = "unknown"                        //未知
    case beforeLoginNode = "beforeLoginNodel"       //登录前
    case afterLoginNode = "afterLoginNode"          //登录后
    case firstUIRenderNodel = "firstUIRenderNodel"  //首屏UI渲染
}

/*
 启动监控
*/
 public class BootMonitor {
    static public let shared = BootMonitor()

    private var lastTaskTime = CACurrentMediaTime()
    private var isLoggerInit = false
    ///关键节点信息-[key: (start, end)]
    public internal(set) var keyNodeDic: SafeDictionary<BootKeyNode, (TimeInterval, TimeInterval)> = [:] + .readWriteLock
    ///统计实际执行的每个flow的task的个数
    private var flowTaskCountDic: [String: Int] = [:]

    ///task状态监控
    internal func update(task: BootTask, old: TaskState, new: TaskState) {
        NewBootManager.logger.info("boot_LaunchTask: --> \(task.identify ?? "") from: \(old) to: \(new)")
        if new == .end {
            //按flow统计实际执行task的Count
            if let flowType = task.flow?.flowType {
                if var flowTaskCount = flowTaskCountDic["\(flowType.rawValue)TaskCount"] {
                    flowTaskCount += 1
                    flowTaskCountDic["\(flowType.rawValue)TaskCount"] = flowTaskCount
                } else {
                    flowTaskCountDic["\(flowType.rawValue)TaskCount"] = 1
                }
            }
            //按时序打印task执行和耗时
            let cost = (CACurrentMediaTime() - lastTaskTime) * 1_000
            if task.identify == "SetupLoggerTask" { isLoggerInit = true }
            NewBootManager.logger.info("boot_LaunchTask: --> \(task.identify ?? ""), cost: \(cost)")
        }
        self.lastTaskTime = CACurrentMediaTime()
    }
    
    /// 启动关键节点监听
    ///-parameters
    ///  -state: 状态
    ///  - isEnd: 是否结束
    /// 启动框架首屏渲染时序： 初始化bootManager -> beforeLogin -> afterLogin -> firstRender
    func doBootKeyNode(keyNode: BootKeyNode, isEnd: Bool = false) {
        //只有启动时候上报
        guard !NewBootManager.shared.context.hasBootFinish else {
            return
        }
        guard keyNode != .unKnown else {
            return
        }
        NewBootManager.logger.info("boot_doBootKeyNode:\(keyNode)_isEnd:\(isEnd)")
        //firstRender 起止时间点，从启动框架初始化到首屏渲染完成。
        if (keyNode == .firstUIRenderNodel), isEnd {
            self.keyNodeDic[keyNode] = (NewBootManager.shared.bootManagerStartTime, CACurrentMediaTime())
        }

        //设置启动框架关键阶段的起止时间点
        if let start = self.keyNodeDic[keyNode]?.0, start > 0, isEnd {//设置结束时间点
            self.keyNodeDic[keyNode]?.1 = CACurrentMediaTime()
        } else if self.keyNodeDic[keyNode]?.0 == nil, !isEnd { //设置开始结点，之前设置过不覆盖(因为启动任务的continue会重新执行这个flow)
            self.keyNodeDic[keyNode] = (CACurrentMediaTime(), 0)
        }

        //首屏结束，上报埋点和日志。
        if keyNode == .firstUIRenderNodel, isEnd {
            //计算关键节点耗时
            var keyNodesCostDic: [String: TimeInterval] = [:]
            self.keyNodeDic.forEach { (key: BootKeyNode, value: (TimeInterval, TimeInterval)) in
                if value.1 > 0 && value.0 > 0 {
                    keyNodesCostDic["\(key.rawValue)Cost"] = (value.1 - value.0) * 1_000
                }
            }
            //计算afterLogin结束到首屏渲染之间耗时
            var afterLoginEndToFirstRenderEnd: TimeInterval = 0
            if let afterLoginEnd = self.keyNodeDic[.afterLoginNode]?.1, let firstRenderEnd = self.keyNodeDic[.firstUIRenderNodel]?.1 {
                afterLoginEndToFirstRenderEnd = (firstRenderEnd - afterLoginEnd) * 1_000
            }
            //计算启动到beforeLogin之间耗时
            var bootInitToBeforeLoginCost: TimeInterval = 0
            if let beforeLoginStart = self.keyNodeDic[.beforeLoginNode]?.0 {
                bootInitToBeforeLoginCost = (beforeLoginStart - NewBootManager.shared.bootManagerStartTime) * 1_000
            }
            //对启动任务耗时进行排序 高->低
            let taskCostSortedData = NewBootManager.shared.bootTaskCostData.sorted(by: {
                $0.1 > $1.1
            })
            var taskCostFormat: [String] = []
            taskCostSortedData.forEach { (key: String, value: Double) in
                taskCostFormat.append("\(key):\(value)")
            }
            //写日志
            NewBootManager.logger.info("boot_firstRender--->flowTaskCount:\(flowTaskCountDic)--->keyNodesCost:\(keyNodesCostDic)--->loadToBeforeLoginCost:\(bootInitToBeforeLoginCost)--->afterLoginEndToFirstRenderEnd:\(afterLoginEndToFirstRenderEnd)--->taskCostSortedData:\(taskCostFormat)")
            
            //上报埋点
            var param: [String: Any] = ["afterLoginEndToFirstRenderEnd": afterLoginEndToFirstRenderEnd]
            param.merge(flowTaskCountDic) { _, new in
                new
            }
            param.merge(keyNodesCostDic) { _, new in
                new
            }
            #if !DEBUG
            Tracker.post(TeaEvent("appr_boot_first_render", params: param))
            #endif
        }
    }
}
