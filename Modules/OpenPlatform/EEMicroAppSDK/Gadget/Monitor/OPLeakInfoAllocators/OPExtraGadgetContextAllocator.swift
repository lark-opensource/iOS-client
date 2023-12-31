//
//  OPExtraGadgetContextAllocator.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/3/23.
//

import Foundation
import LarkOPInterface

/// 埋点字段的key
/// 当前内存中所有jsRuntime对象的信息
fileprivate let jsRuntimeInfoKey = "js_runtime_objects_info"
/// 当前jsRuntime对象限制的最大数量
fileprivate let jsRuntimeOvercountNumberKey = "js_runtime_overcount_number"
/// 当前内存中所有BDPAppPage对象的信息
fileprivate let appPageInfoKey = "app_page_objects_info"
/// 当前BDPAppPage对象限制的最大数量
fileprivate let appPageOvercountNumberKey = "app_page_runtime_overcount_number"
/// 当前内存中所有BDPTask对象的信息
fileprivate let taskInfoKey = "task_objects_info"
/// 当前BDPTask对象限制的最大数量
fileprivate let taskOvercountNumberKey = "task_overcount_number"
/// 当前内存中BDPTask对象的数量
fileprivate let currentTaskNumberKey = "current_task_number"
/// 当前内存中BDPAppPage对象的数量
fileprivate let currentAppPageNumberKey = "current_app_page_number"
/// 当前内存中BDPJSRuntime对象的数量
fileprivate let currentJSRuntimeNumberKey = "current_js_runtime_number"

/// 对象信息字典中的key
/// 对象本身的信息（类名、hashValue）
fileprivate let objectKey = "object"
/// 与之关联的uniqueID信息
fileprivate let uniqueIDKey = "uniqueID"
/// 与之关联的当前小程序所在页面路径信息
fileprivate let currentPagePathKey = "currentPagePath"
/// 与之关联的当前小程序所在页面参数信息
fileprivate let currentPageQueryKey = "currentPageQuery"

/// 负责收集额外监控的一些对象中与小程序相关的上下文信息
struct OPExtraGadgetContextAllocator: OPMemoryInfoAllocator {

    func allocateMemoryInfo(with target: NSObject, monitor: OPMonitor) {

        let jsRuntimes = (OPCountDetector.shared.getCurrentObjectsWith(typeIdentifier: OPMicroAppJSRuntime.typeIdentifier) + OPCountDetector.shared.getCurrentObjectsWith(typeIdentifier: OPMicroAppJSRuntime.typeIdentifier)).compactMap{$0.value}
        if let jsRuntimeInfos = getObjectsInfoStr(jsRuntimes) {
            _ = monitor.addCategoryValue(jsRuntimeInfoKey, jsRuntimeInfos)
        }
        _ = monitor.addMetricValue(jsRuntimeOvercountNumberKey, OPMicroAppJSRuntime.overcountNumber)
        _ = monitor.addMetricValue(currentJSRuntimeNumberKey, jsRuntimes.count)

        let appPages = OPCountDetector.shared.getCurrentObjectsWith(typeIdentifier: BDPAppPage.typeIdentifier).compactMap{$0.value}
        if let appPageInfos = getObjectsInfoStr(appPages) {
            _ = monitor.addCategoryValue(appPageInfoKey, appPageInfos)
        }
        _ = monitor.addMetricValue(appPageOvercountNumberKey, BDPAppPage.overcountNumber)
        _ = monitor.addMetricValue(currentAppPageNumberKey, appPages.count)

        let tasks = OPCountDetector.shared.getCurrentObjectsWith(typeIdentifier: BDPTask.typeIdentifier).compactMap{$0.value}
        if let taskInfos = getObjectsInfoStr(tasks) {
            _ = monitor.addCategoryValue(taskInfoKey, taskInfos)
        }
        _ = monitor.addMetricValue(taskOvercountNumberKey, BDPTask.overcountNumber)
        _ = monitor.addMetricValue(currentTaskNumberKey, tasks.count)
    }

    /// 获取多个对象与小程序相关联的上下文信息，最后的结果是字典数组转换得到的json字符串
    private func getObjectsInfoStr(_ objects: [NSObject]) -> String? {
        let objectInfos = objects.compactMap { object -> [String: String]? in
            return getObjectInfo(object)
        }
        if let jsonData = try? JSONEncoder().encode(objectInfos) {
            return String(data: jsonData, encoding: .utf8)
        } else {
            return nil
        }
    }

    /// 获取一个对象与小程序相关联的上下文信息，以字典的方式存储
    private func getObjectInfo(_ object: NSObject) -> [String: String] {
        var infoDict = [String: String]()
        infoDict["object"] = String(describing: object)
        if let uniqueID = OPAllocatorUtil.getUniqueID(with: object) {
            infoDict["uniqueID"] = uniqueID.fullString
        }
        if let currentPagePath = OPAllocatorUtil.getCurrentPagePath(with: object) {
            infoDict["currentPagePath"] = currentPagePath
        }
        if let currentPageQuery = OPAllocatorUtil.getCurrentPageQuery(with: object) {
            infoDict["currentPageQuery"] = currentPageQuery
        }

        return infoDict
    }

}
