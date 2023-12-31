//
//  LarkTracingUtil.swift
//  LarkMessageCore
//
//  Created by huanglixing on 2021/8/16.
//

import Foundation
import ThreadSafeDataStructure
import RustPB
import RustSDK
import LarkSetting
import LKCommonsTracker

// span节点信息
public final class SpanMetricExtra {
    var metricName: String = ""
    var spanID: UInt64 = 0
    var parentSpanID: UInt64 = 0
    var startTime: Int64 = 0
    var endTime: Int64 = 0

    init(metricName: String = "", spanID: UInt64 = 0, parentSpanID: UInt64 = 0, startTime: Int64 = 0, endTime: Int64 = 0) {
        self.metricName = metricName
        self.spanID = spanID
        self.parentSpanID = parentSpanID
        self.startTime = startTime
        self.endTime = endTime
    }
}

/*
    tracingLog工具类用来写入tracing日志-https://bytedance.feishu.cn/wiki/wikcn2jmY5qNhBso4bWyRzqk4Yd#
 */
public final class LarkTracingUtil {

    /*
     sendMessage-发消息相关spanName定义
     */
    // 发消息
    public static let sendMessage = "sendMessage"
    // 处理上屏消息
    public static let handOnScreenMessage = "handOnScreenMessage"
    // 消息上屏
    public static let messageOnScreen = "messageOnScreen"
    // 创建假消息
    public static let createQuasiMessage = "createQuasiMessage"
    // 调用发送接口
    public static let callSendMessageAPI = "callSendMessageAPI"
    // 处理发送成功消息
    public static let handSendSuccessMessage = "handSendSuccessMessage"

    /*
     enter chat-进chat相关spanName定义
     */
    // 进会话
    public static let enterChat = "enterChat"
    // 首屏UI创建
    public static let firstRender = "first_render"
    // 创建chatVC
    public static let chatVCInit = "chatVCInit"
    // 加载所有module
    public static let loadModule = "loadModule"
    // 加载数据和创建vm耗时
    public static let preLoadDataBuffer = "preLoadDataBuffer"
    // 获取chat
    public static let fetchChatCost = "fetchChatCost"
    // 创建业务组件
    public static let generateComponents = "generateComponents"
    // containerVC_生成正式视图之前处理
    public static let containerVCBeforeGenerateNormalViews = "containerVC_beforeGenerateNormalViews"
    // 生成正式视图之前处理
    public static let beforeGenerateNormalViews = "beforeGenerateNormalViews"
    // containerVC_创建常规视图
    public static let containerVCGenerateNormalViews = "containerVC_generateNormalViews"
    // 创建常规视图
    public static let generateNormalViews = "generateNormalViews"
    // containerVC_创建常规视图之后处理
    public static let containerVCAfterGenerateNormalViews = "containerVC_afterGenerateNormalViews"
    // 创建常规视图之后处理
    public static let afterGenerateNormalViews = "afterGenerateNormalViews"

    // 首屏消息数据信号链
    public static let firstScreenMessagesRender = "firstScreenMessagesRender"
    // 获取首屏数据
    public static let getChatMessages = "getChatMessages"
    // 加载消息
    public static let initMessages = "initMessages"
    // 处理数据
    public static let transCellVM = "transCellVM"
    // 发送刷新首屏信号
    public static let publishInitMessagesSignal = "publishInitMessagesSignal"
    // 刷新视图
    public static let refreshForInitMessages = "refreshForInitMessages"

    /*
     用来存放spanName和spanId映射关系
     key: spanName  value: spanID
     */
    private static var tracingInfoMap: SafeDictionary<String, UInt64> = [:] + .readWriteLock

    /*
     存放span和name映射关系
     */
    private static var metricExtraInfoMap: SafeDictionary<String, SpanMetricExtra> = [:] + .readWriteLock
    /*
     存放根span和子span的映射关系
     */
    private static var metricExtraMap: SafeDictionary<String, [SpanMetricExtra]> = [:] + .readWriteLock

    /*
     写日志的任务执行队列
     */
    private static var queue = DispatchQueue(label: "LarkTracingUtil", qos: .utility)

    // tracing是否可用
    @FeatureGatingValue(key: "lark.tracing.enable") internal static var tracingEnable: Bool

    // 只有bytest打包才会上传埋点
    #if IS_BYTEST_PACKAGE
    static var trackerToTeaEnable: Bool = true
    #else
    static var trackerToTeaEnable: Bool = false
    #endif

    /*
     开始一个根节点
     spanName: 根节点名称
     displaySpanName: 日志上显示的spanName默认是spanName。
     */
    public static func startRootSpan(spanName: String, displaySpanName: String? = nil) {
        guard self.tracingEnable else {
            return
        }
        // 目前只有进会话才支持上传埋点到T仅供bytest消费
        trackerToTeaEnable = (trackerToTeaEnable && spanName == self.enterChat ? true: false)
        let currentTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
        self.queue.async {
            let rootSpanName = displaySpanName ?? spanName
            let spanID = start_root_span2(rootSpanName, currentTime)
            guard spanID != 0 else {
                return
            }
            tracingInfoMap[spanName] = spanID
            // 处理埋点信息
            if self.trackerToTeaEnable {
                var metricExtra = SpanMetricExtra(metricName: spanName, spanID: spanID, startTime: currentTime)
                metricExtraInfoMap[spanName] = metricExtra

                var metricExtraInfoArray: [SpanMetricExtra] = []
                metricExtraInfoArray.append(metricExtra)
                metricExtraMap[spanName] = metricExtraInfoArray
            }
        }
    }

    /*
     开始一个子节点
     spanName: 子节点名称
     parentSpanId: 父节点id
     displaySpanName: 日志上显示的spanName默认是spanName。
     */
    private static func startChildSpan(spanName: String, parentSpanId: UInt64, displaySpanName: String? = nil, currentTime: Int64) {
        let childSpanName = displaySpanName ?? spanName
        let childSpanID = start_child_span2(parentSpanId, childSpanName, currentTime)
        guard childSpanID != 0 else {
            return
        }
        tracingInfoMap[spanName] = childSpanID
        // 处理埋点信息
        if self.trackerToTeaEnable, let rootMetricExtra = self.getRootSpanMetricExtra(parentSpanId: parentSpanId), var metricExtraInfoArray = metricExtraMap[rootMetricExtra.metricName] {
            var metricExtra = SpanMetricExtra(metricName: spanName, spanID: childSpanID, parentSpanID: parentSpanId, startTime: currentTime)
            metricExtraInfoMap[spanName] = metricExtra
            metricExtraInfoArray.append(metricExtra)
            metricExtraMap[rootMetricExtra.metricName] = metricExtraInfoArray
        }
    }

    // 获取根span
    private static func getRootSpanMetricExtra(parentSpanId: UInt64) -> SpanMetricExtra? {
       var parentSpan = LarkTracingUtil.metricExtraInfoMap.values.filter { metricExtra in
            metricExtra.spanID == parentSpanId
        }
        guard parentSpan.count == 1 else {
            return nil
        }
        var pSpan = parentSpan[0]
        if pSpan.parentSpanID == 0 {
            return pSpan
        } else {
            return self.getRootSpanMetricExtra(parentSpanId: pSpan.parentSpanID)
        }
    }

    /*
     开始一个子节点
     spanName: 子节点名称
     parentName: 父节点名称
     displaySpanName: 日志上显示的spanName默认是spanName。
     */
    public static func startChildSpanByPName(spanName: String, parentName: String, displaySpanName: String? = nil) {
        guard tracingEnable else {
            return
        }
        let currentTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
        self.queue.async {
            guard let parentSpanId = tracingInfoMap[parentName] else {
                return
            }
            startChildSpan(spanName: spanName, parentSpanId: parentSpanId, displaySpanName: displaySpanName, currentTime: currentTime)
        }
    }

    /*
     结束节点
     spanId: 节点id
     tag: 传递参数
     */
    private static func endSpanByID(spanId: UInt64, tag: String?, currentTime: Int64) {
        end_span2(spanId, tag, currentTime)
    }

    /*
     结束节点
     spanName: 节点名称
     tag: 传递参数
     */
    public static func endSpanByName(spanName: String, tags: [String: Any]? = nil, error: Bool? = false) {
        guard tracingEnable else {
            return
        }
        let currentTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
        self.queue.async {
            guard let spanId = tracingInfoMap[spanName] else {
                return
            }
            var tagStr: String?
            if let tags = tags {
                var newTags = tags
                if error ?? false {
                    newTags["error"] = "true"
                }
                if let data = try? JSONSerialization.data(withJSONObject: newTags, options: []) {
                    tagStr = String(data: data, encoding: .utf8) ?? ""
                }
            }
            endSpanByID(spanId: spanId, tag: tagStr, currentTime: currentTime)
            tracingInfoMap.removeValue(forKey: spanName)
            if self.trackerToTeaEnable, var metricExtra = metricExtraInfoMap[spanName] {
                metricExtra.endTime = currentTime
                metricExtraInfoMap.removeValue(forKey: spanName)
                if metricExtra.parentSpanID == 0 {// 根节点
                    var eventName = "\(metricExtra.metricName)_dev"
                    let total = metricExtra.endTime - metricExtra.startTime
                    var metricExtraArray: [SpanMetricExtra]? = metricExtraMap[spanName]
                     metricExtraMap.removeValue(forKey: spanName)
                    // T上报
                    if let metricExtraArray = metricExtraArray {
                        var metric: [String: Any] = ["total": total]
                        var metricExtraArray = metricExtraArray.map { (info) -> [String: Any] in
                            metric.updateValue(info.endTime - info.startTime, forKey: info.metricName)
                            var dic: [String: Any] = ["metric_name": info.metricName,
                                       "start_time": info.startTime,
                                       "end_time": info.endTime]
                            return dic
                        }
                        if let metricExtraData = try? JSONSerialization.data(withJSONObject: metricExtraArray, options: []), let metricExtraStr = String(data: metricExtraData, encoding: .utf8) {
                            [metric.updateValue(metricExtraStr, forKey: "metric_extra")]
                            #if !DEBUG
                                Tracker.post(TeaEvent(eventName, params: metric))
                            #endif
                        }
                    }
                }
            }
        }
    }

    /*
     根据Name获取spanID
     */
    public static func getSpanIDByName(spanName: String) -> UInt64? {
        guard self.tracingEnable else {
            return 0
        }
        return tracingInfoMap[spanName]
    }

    /*
     移除一个节点的映射
     spanName：节点名称
     */
    public static func stopSpanByName(spanName: String) {
        guard self.tracingEnable else {
            return
        }
        tracingInfoMap.removeValue(forKey: spanName)
    }

    /*
     移除所有节点映射
     */
    public static func stopAllSpan() {
        guard self.tracingEnable else {
            return
        }
        tracingInfoMap.removeAll()
    }

    /*
     修改映射关系中的spanName,适用多线程场景spanName重复导致spanID获取错乱的问题。
     */
    public static func replaceOldNameByNewName(oldName: String, newName: String) {
        guard let parentSpanId = tracingInfoMap[oldName], tracingEnable else {
            return
        }
        tracingInfoMap[newName] = parentSpanId
        tracingInfoMap.removeValue(forKey: oldName)
    }
}
