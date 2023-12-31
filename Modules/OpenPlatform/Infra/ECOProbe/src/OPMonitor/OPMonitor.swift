//
//  OPMonitor.swift
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

import Foundation

/// Swift 语法封装，详见 OPMonitor.h
public final class OPMonitor {

    public let monitorEvent: OPMonitorEvent
    
    /*-------------------------------------------------------*/
    //                       构造函数
    /*-------------------------------------------------------*/

    public convenience init(name: String?,
                            code: OPMonitorCodeProtocol?) {
        self.init(service: nil, name: name, code: code)
    }

    public convenience init(_ code: OPMonitorCodeProtocol) {
        self.init(service: nil, name: nil, code: code)
    }

    public convenience init(_ name: String) {
        self.init(service: nil, name: name, code: nil)
    }

    public convenience init(service: OPMonitorServiceProtocol,
                            code: OPMonitorCodeProtocol) {
        self.init(service: service, name: nil, code: code)
    }

    public convenience init(service: OPMonitorServiceProtocol,
                            name: String) {
        self.init(service: service, name: name, code: nil)
    }

    public init(service: OPMonitorServiceProtocol?,
                name: String?,
                code: OPMonitorCodeProtocol?) {
        self.monitorEvent = OPMonitorEvent(service: service, name: name, monitorCode: code)
    }

    public init(service: OPMonitorServiceProtocol?,
                name: String?,
                code: OPMonitorCodeProtocol?,
                platform: OPMonitorReportPlatform) {
        self.monitorEvent = OPMonitorEvent(service: service, name: name, monitorCode: code, platform: platform)
    }

    public init(service: OPMonitorServiceProtocol? = nil,
                name: String?,
                metrics: [AnyHashable: Any]?,
                categories: [AnyHashable: Any]?) {
        self.monitorEvent = OPMonitorEvent(service: service, name: name, metrics: metrics, categories: categories)
    }

    /*-------------------------------------------------------*/
    //                        基本方法
    /*-------------------------------------------------------*/


    /// 开启线程安全模式，addCategoryValue 、addMetricsValue 使用线程安全的字典
    /// - Returns: self
    @discardableResult
    public func enableThreadSafe() -> OPMonitor {
        self.monitorEvent.enableThreadSafe()()
        return self
    }

    /// 添加一个自定义的 Key-Value，value 为值类型（可计算平均值）
    /// 重复设置相同key会覆盖
    @discardableResult
    public func addMetricValue(_ key: String, _ value: Any?) -> OPMonitor {
        self.monitorEvent.addMetricValue()(key, value)
        return self
    }

    /// 添加一个自定义的 Key-Value，value 为枚举/分类类型（可分类筛选)
    /// 重复设置相同key会覆盖
    @discardableResult
    public func addCategoryValue(_ key: String, _ value: Any?) -> OPMonitor {
        self.monitorEvent.addCategoryValue()(key, value)
        return self
    }

    /// 添加多个自定义的 Key-Value，value 为分类类型（可分类筛选)
    @discardableResult
    public func addCategoryMap(_ categoryMap: [String: Any?]) -> OPMonitor {
        self.monitorEvent.addCategoryMap(categoryMap as [String : Any])
        return self
    }

    /// 添加一个Tag，可以添加多个Tag
    @discardableResult
    public func addTag(_ tag: String?) -> OPMonitor {
        self.monitorEvent.addTag()(tag)
        return self
    }

    /// 添加一个map，快速添加一个集合数据。Number 类型会按照 metric 添加，其他类型会按照 category 添加
    @discardableResult
    public func addMap(_ map: [String: Any]?) -> OPMonitor {
        self.monitorEvent.addMap()(map)
        return self
    }

    /// 设置 traceID
    @discardableResult
    public func tracing(_ trace: OPTraceProtocol?) -> OPMonitor {
        self.monitorEvent.tracing()(trace)
        return self
    }

    /// 设置打点平台
    @discardableResult
    public func setPlatform(_ platform: OPMonitorReportPlatform) -> OPMonitor {
        self.monitorEvent.setPlatform()(platform)
        return self
    }

    /// 提交数据
    public func flush(
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) {
        self.monitorEvent.__flushWithContextInfo()(fileName.cString(using: .utf8), functionName.cString(using: .utf8), line);
    }


    /// 将埋点 flush 到特定 service 下，如 monitor.flushTo(trace) 批量上报场景
    ///
    /// **注意 OPTrace 可能会使用规则对埋点数据进行过滤**
    /// 故 monitor 必须符合 OPMonitor 定义，包含 domain、code 等信息
    /// * 相关文档可参考：https://bytedance.feishu.cn/wiki/wikcn8ZaXofrfWgtX2AERfm9bjS
    ///
    /// - Parameters:
    ///   - service: 自定义 servcie，如 trace
    public func flushTo(
        _ service: OPMonitorServiceProtocol,
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line) {
            let _fileName = self.file?.cString(using: .utf8)
            let funcName = functionName.cString(using: .utf8)
            self.monitorEvent.__flushWithContextInfoWithService()(service, _fileName, funcName, line)
    }

    /*-------------------------------------------------------*/
    //                    Monitor: 监控
    /*-------------------------------------------------------*/

    /// 设置埋点事件 monitorCode
    @discardableResult
    public func setMonitorCode(_ monitorCode: OPMonitorCodeProtocol?) -> OPMonitor {
        self.monitorEvent.setMonitorCode()(monitorCode)
        return self
    }

    /// 当发生异常时，设置埋点事件 monitorCode
    @discardableResult
    public func setMonitorCodeIfError(_ monitorCodeIfError: OPMonitorCodeProtocol?) -> OPMonitor {
        self.monitorEvent.setMonitorCodeIfError()(monitorCodeIfError)
        return self
    }

    /// 设置埋点级别（将覆盖 monitorCode 提供的建议级别）
    @discardableResult
    public func setLevel(_ level: OPMonitorLevel) -> OPMonitor {
        self.monitorEvent.setLevel()(level)
        return self
    }

    /*-------------------------------------------------------*/
    //                    Error: 异常采集
    /*-------------------------------------------------------*/

    /// 设置原始采集的code
    @discardableResult
    public func setErrorCode(_ errorCode: String?) -> OPMonitor {
        self.monitorEvent.setErrorCode()(errorCode)
        return self
    }

    /// 设置原始采集的 message 信息
    @discardableResult
    public func setErrorMessage(_ errorMessage: String?) -> OPMonitor {
        self.monitorEvent.setErrorMessage()(errorMessage)
        return self
    }

    /// 接收一个标准error对象，并吸收其有效数据(errorCode、errorMessage等)
    @discardableResult
    public func setError(_ error: Error?) -> OPMonitor {
        self.monitorEvent.setError()(error)
        return self
    }

    /*-------------------------------------------------------*/
    //                    Timing: 时间函数
    /*-------------------------------------------------------*/

    /// 手动指定时间(ms)，替换缺省时间
    @discardableResult
    public func setTime(_ time: TimeInterval) -> OPMonitor {
        self.monitorEvent.setTime()(time)
        return self
    }

    /// 记一次时间，在埋点时会自动将 最后一次 timing 时间减去 第一次 timing 时间得到 duration 进行上报
    @discardableResult
    public func timing() -> OPMonitor {
        self.monitorEvent.timing()();
        return self
    }

    /// 设置 duration 参数(ms)
    @discardableResult
    public func setDuration(_ duration: TimeInterval) -> OPMonitor {
        self.monitorEvent.setDuration()(duration)
        return self
    }

    /*-------------------------------------------------------*/
    //                    Data: 读取数据
    /*-------------------------------------------------------*/

    // 读取 metrics 数据
    public var metrics: [String: Any]? {
        return self.monitorEvent.metrics as? [String: Any]
    }

    // 读取 category 数据
    public var categories: [String: Any]? {
        return self.monitorEvent.categories as? [String: Any]
    }

    // 读取 category 数据和 metrics 数据
    public var data: [String: Any]? {
        return self.monitorEvent.data as? [String: Any]
    }

    // 读取 level
    public var level: OPMonitorLevel {
        return self.monitorEvent.level()
    }

    public var file: String? {
        return self.monitorEvent.fileName;
    }

    public var function: String? {
        return self.monitorEvent.funcName;
    }

    public var line: Int? {
        return self.monitorEvent.line >= 0 ? self.monitorEvent.line : nil;
    }

    /*-------------------------------------------------------*/
    //              Common Utils: result_type
    /*-------------------------------------------------------*/

    /// 设置 result_type
    @discardableResult
    public func setResultType(_ resultType: String?) -> OPMonitor {
        self.monitorEvent.setResultType()(resultType)
        return self
    }

    /// 设置 result_type: success
    @discardableResult
    public func setResultTypeSuccess() -> OPMonitor {
        self.monitorEvent.setResultTypeSuccess()()
        return self
    }

    /// 设置 result_type: fail
    @discardableResult
    public func setResultTypeFail() -> OPMonitor {
        self.monitorEvent.setResultTypeFail()()
        return self
    }

    /// 设置 result_type: cancel
    @discardableResult
    public func setResultTypeCancel() -> OPMonitor {
        self.monitorEvent.setResultTypeCancel()()
        return self
    }

    /// 设置 result_type: timeout
    @discardableResult
    public func setResultTypeTimeout() -> OPMonitor {
        self.monitorEvent.setResultTypeTimeout()()
        return self
    }
}

final class DispatchQueueSingleton {
    static let shared = DispatchQueueSingleton()

    private let queue = DispatchQueue(label: "com.bytedance.openplatform.monitor_queue", attributes: .concurrent)
    
    private init() {}

    func async(_ block: @escaping () -> Void) {
        queue.async(flags: .barrier) {
            block()
        }
    }
}
