//
//  LarkWebViewMonitorEvent.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/2.
//
import Foundation

/// LarkWebViewMonitor事件定义
/// - 参考文档 ：https://bytedance.feishu.cn/base/bascnJdCxqgg8VhCbB3frr0N0sf?table=tblfyP93EMqAfhDq&view=vewTf0ews2
enum LarkWebViewMonitorEvent: String {
    // MARK: - Common
    /// 创建WebView
    case createWebView = "wb_webview_create"
    /// LoadUrl开始
    case loadUrlStart = "wb_load_url_start"
    /// LoadUrl结束
    case loadUrlEnd = "wb_load_url_end"
    /// LoadUrl取消
    case loadUrlCancel = "wb_load_url_cancel"
    /// LoadUrl加载主文档
    case loadUrlCommit = "wb_load_url_commit"
    /// loadurl耗时
    case loadDuration = "wb_load_duration"
    /// webview deinit
    case destroyWebView = "wb_webview_destroy"
    /// webview 重定向
    case loadUrlOverride = "wb_override_url_loading"
    

    // MARK: - Quality
    /// 安全链接检测
    case seclinkCheck = "wb_seclink_check"
    /// url链接SecLink检测,与seclinkCheck的上报时机不同
    case urlSeclinkCheck = "wb_url_seclink_check"
    /// WebView进程挂了
    case renderProcessGone = "wb_render_process_gone"
    /// WebView性能数据
    case performanceTiming = "wb_performance_timing"
    /// 网页加载HTTP错误失败上报
    case loadReceivedError = "wb_load_received_error"

    // MARK: - Bridge
    /// API执行结果
    case apiInvokeResult = "wb_api_invoke_result"
    /// bridge 错误 event
    case bridgeErrorEvent = "wb_lark_webview_bridge_error"
    
    // MARK: - Pool
    case wbPoolTerminate = "wb_pool_terminate"
    case wbPoolFinishLoad = "wb_pool_finish_load"
    case wbPoolDidFailProvisionalNavigation = "wb_pool_didFailProvisionalNavigation"
    case wbPoolDidFail = "wb_pool_didFail"
}

/// LarkWebViewMonitor事件Key定义
/// - 参考文档 ：https://bytedance.feishu.cn/base/bascnJdCxqgg8VhCbB3frr0N0sf?table=tblZzL1klX4VG7en&view=vewjGji8sg
enum LarkWebViewMonitorEventKey: String {
    /// API名字
    case apiName = "api_name"
    /// API类型
    case apiType = "api_type"
    /// 所属业务
    case biz = "biz_type"
    /// TraceId
    case traceId = "trace_id"
    /// 使用次数
    case usedCount = "used_count"
    /// 页面url，需加密
    case url = "url"
    /// 页面url.host，目前只针对网页容器打印，已有安全同学确认
    case host = "host"
    /// 页面url.path，目前只针对网页容器打印，已有安全同学确认
    case path = "path"
    /// 性能数据
    case performance = "performance"
    /// 结果码
    case resultCode = "result_code"
    /// 错误码
    case errorCode = "error_code"
    /// 是否可见
    case visible = "visible"
    /// 可见crash次数
    case visibleCrashCount = "visible_crash_count"
    /// 不可见crash次数
    case invisibleCrashCount = "invisible_crash_count"
    /// 是否是崩溃状态
    case isTerminateState = "is_terminate_state"
    /// load url 次数
    case loadURLCount = "load_url_count"
    /// 是否是首页
    case isFirstPage = "is_first_page"
    /// app_id
    case appId = "app_id"
    /// 场景
    case scene = "scene"
    ///  webview不同阶段的耗时
    case timeConsuming = "phase_time_consuming"
    ///  webview使用过程中发生的一些自定义事件
    case customEventInfo = "customEventInfo"
    ///  webview预加载
    case webviewPreload = "webviewPreload"
    /// 应用类型
    case appType = "app_type"
}

/// 加载URL结果
enum LoadUrlResult: Int {
    case success = 0
    case failed = 1
    case closed = 2
    case cancaled = 3
    case terminated = 4
}
