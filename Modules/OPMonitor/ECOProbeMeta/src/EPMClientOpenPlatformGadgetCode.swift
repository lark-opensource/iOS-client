// DO NOT EDIT.
//
// Generated by the iOS generator for OPMonitorCode.
// Source:   

import Foundation

@objcMembers
public final class EPMClientOpenPlatformGadgetCode: OPMonitorCodeBase {

    /** 不合法的参数 */
    public static let invalid_params = EPMClientOpenPlatformGadgetCode(code: 10000, level: OPMonitorLevelError, message: "invalid_params")

    /** init 失败 */
    public static let init_error = EPMClientOpenPlatformGadgetCode(code: 10001, level: OPMonitorLevelError, message: "init_error")

    /** 加载 page-frame.html 异常 */
    public static let load_page_frame_html_error = EPMClientOpenPlatformGadgetCode(code: 10002, level: OPMonitorLevelError, message: "load_page_frame_html_error")

    /** 加载 page-frame.js 异常 */
    public static let load_page_frame_script_error = EPMClientOpenPlatformGadgetCode(code: 10003, level: OPMonitorLevelError, message: "load_page_frame_script_error")

    /** 加载 {path}-frame.js 异常 */
    public static let load_path_frame_script_error = EPMClientOpenPlatformGadgetCode(code: 10004, level: OPMonitorLevelError, message: "load_path_frame_script_error")

    /** webview 加载异常 */
    public static let webview_load_exception = EPMClientOpenPlatformGadgetCode(code: 10005, level: OPMonitorLevelError, message: "webview_load_exception")

    /** 从文件读取js文件内容失败 */
    public static let read_script_content_from_file_error = EPMClientOpenPlatformGadgetCode(code: 10006, level: OPMonitorLevelError, message: "read_script_content_from_file_error")

    /** 批量从文件读取js文件内容失败 */
    public static let batch_read_script_content_from_file_error = EPMClientOpenPlatformGadgetCode(code: 10007, level: OPMonitorLevelError, message: "batch_read_script_content_from_file_error")

    /** 从URL加载js文件失败 */
    public static let load_script_from_url_error = EPMClientOpenPlatformGadgetCode(code: 10008, level: OPMonitorLevelError, message: "load_script_from_url_error")

    /** webview crash */
    public static let webview_crash = EPMClientOpenPlatformGadgetCode(code: 10009, level: OPMonitorLevelError, message: "webview_crash")

    /** 执行JS异常 */
    public static let evaluate_javascript_error = EPMClientOpenPlatformGadgetCode(code: 10010, level: OPMonitorLevelWarn, message: "evaluate_javascript_error")

    /** schema 检查不通过 */
    public static let schema_check_error = EPMClientOpenPlatformGadgetCode(code: 10011, level: OPMonitorLevelError, message: "schema_check_error")

    /** js runtime 抛出异常 */
    public static let js_runtime_error = EPMClientOpenPlatformGadgetCode(code: 10012, level: OPMonitorLevelError, message: "js_runtime_error")

    /** 未知异常 */
    public static let unknown_error = EPMClientOpenPlatformGadgetCode(code: 10014, level: OPMonitorLevelError, message: "unknown_error")

    /** 获取小程序Common信息失败 */
    public static let invalid_common_info = EPMClientOpenPlatformGadgetCode(code: 10015, level: OPMonitorLevelError, message: "invalid_common_info")

    /** 图片url不合法 */
    public static let illegal_image_url = EPMClientOpenPlatformGadgetCode(code: 10016, level: OPMonitorLevelError, message: "illegal_image_url")

    /** 未实现该API */
    public static let client_not_impl_the_api = EPMClientOpenPlatformGadgetCode(code: 10017, level: OPMonitorLevelError, message: "client_not_impl_the_api")

    /** 失败 */
    public static let fail = EPMClientOpenPlatformGadgetCode(code: 10018, level: OPMonitorLevelError, message: "fail")

    /** 取消 */
    public static let cancel = EPMClientOpenPlatformGadgetCode(code: 10019, level: OPMonitorLevelWarn, message: "cancel")

    /** 成功 */
    public static let success = EPMClientOpenPlatformGadgetCode(code: 10020, level: OPMonitorLevelNormal, message: "success")

    /** 加载 app-service.js 异常 */
    public static let load_app_service_script_error = EPMClientOpenPlatformGadgetCode(code: 10021, level: OPMonitorLevelError, message: "load_app_service_script_error")

    /** 页面闪退重试次数超过限制（iOS：最多50次） */
    public static let webview_crash_overload = EPMClientOpenPlatformGadgetCode(code: 10023, level: OPMonitorLevelError, message: "webview_crash_overload")

    /** Socket Debug Disconnected */
    public static let debug_exit = EPMClientOpenPlatformGadgetCode(code: 10024, level: OPMonitorLevelNormal, message: "debug_exit")

    /** Socket Debug 断点时退出 */
    public static let debug_hit_breakpoint_exit = EPMClientOpenPlatformGadgetCode(code: 10025, level: OPMonitorLevelNormal, message: "debug_hit_breakpoint_exit")

    /** 低内存被杀死 */
    public static let memory_warning_kill = EPMClientOpenPlatformGadgetCode(code: 10026, level: OPMonitorLevelError, message: "memory_warning_kill")

    /** 在Loading界面点击重新加载 */
    public static let loading_view_reload = EPMClientOpenPlatformGadgetCode(code: 10027, level: OPMonitorLevelError, message: "loading_view_reload")

    /** Loading界面debug */
    public static let loading_view_debug = EPMClientOpenPlatformGadgetCode(code: 10028, level: OPMonitorLevelNormal, message: "loading_view_debug")

    /** 小程序白屏 */
    public static let blank_webview = EPMClientOpenPlatformGadgetCode(code: 10029, level: OPMonitorLevelError, message: "blank_webview")

    /** 用户点击按钮退出 */
    public static let close_button_dismiss = EPMClientOpenPlatformGadgetCode(code: 10030, level: OPMonitorLevelNormal, message: "close_button_dismiss")

    /** 应用 navigate back 退出小程序 */
    public static let navigate_back_dismiss = EPMClientOpenPlatformGadgetCode(code: 10031, level: OPMonitorLevelNormal, message: "navigate_back_dismiss")

    /** 自动化测试更新JSSDK时退出所有小程序 */
    public static let test_update_jssdk_dismiss = EPMClientOpenPlatformGadgetCode(code: 10032, level: OPMonitorLevelNormal, message: "test_update_jssdk_dismiss")

    /** 小程序启动失败时自动退出 */
    public static let auto_dismiss_when_load_failed = EPMClientOpenPlatformGadgetCode(code: 10033, level: OPMonitorLevelError, message: "auto_dismiss_when_load_failed")

    /** 小程序出现异常弹窗，用户点击退出 */
    public static let alert_dismiss_when_load_failed = EPMClientOpenPlatformGadgetCode(code: 10034, level: OPMonitorLevelError, message: "alert_dismiss_when_load_failed")

    /** JS 线程强制停止 */
    public static let js_running_thread_force_stopped = EPMClientOpenPlatformGadgetCode(code: 10035, level: OPMonitorLevelError, message: "js_running_thread_force_stopped")

    /** navigateBackMiniProgram 退出小程序 */
    public static let navigate_back_app_dismiss = EPMClientOpenPlatformGadgetCode(code: 10036, level: OPMonitorLevelNormal, message: "navigate_back_app_dismiss")

    /** 切换调试模式退出小程序 */
    public static let debug_switch_dismiss = EPMClientOpenPlatformGadgetCode(code: 10037, level: OPMonitorLevelNormal, message: "debug_switch_dismiss")

    /** 退出小程序的API调用 */
    public static let exit_app_api_dismiss = EPMClientOpenPlatformGadgetCode(code: 10038, level: OPMonitorLevelNormal, message: "exit_app_api_dismiss")

    /** 更新导致的重启 */
    public static let apply_update_reboot = EPMClientOpenPlatformGadgetCode(code: 10039, level: OPMonitorLevelNormal, message: "apply_update_reboot")

    /** 边缘滑动手势退出 */
    public static let edge_gesture_dismiss = EPMClientOpenPlatformGadgetCode(code: 10040, level: OPMonitorLevelNormal, message: "edge_gesture_dismiss")

    /** 生命周期接口调用关闭 */
    public static let life_cycle_dismiss = EPMClientOpenPlatformGadgetCode(code: 10041, level: OPMonitorLevelNormal, message: "life_cycle_dismiss")

    /** 关于页面重启小程序 */
    public static let about_restart = EPMClientOpenPlatformGadgetCode(code: 10042, level: OPMonitorLevelNormal, message: "about_restart")

    /** 更新连续失败次数超过限制 */
    public static let app_update_failed_too_many_times = EPMClientOpenPlatformGadgetCode(code: 10043, level: OPMonitorLevelWarn, message: "app_update_failed_too_many_times")

    /** 图片加载失败 */
    public static let image_load_failed = EPMClientOpenPlatformGadgetCode(code: 10044, level: OPMonitorLevelWarn, message: "image_load_failed")

    /** 内置 JSSDK 版本号解码失败 */
    public static let lib_version_decode_failed = EPMClientOpenPlatformGadgetCode(code: 10045, level: OPMonitorLevelError, message: "lib_version_decode_failed")

    /** 从文件解码数据失败 */
    public static let decode_data_from_path_failed = EPMClientOpenPlatformGadgetCode(code: 10046, level: OPMonitorLevelError, message: "decode_data_from_path_failed")

    /** 解压失败 */
    public static let unzip_file_failed = EPMClientOpenPlatformGadgetCode(code: 10047, level: OPMonitorLevelError, message: "unzip_file_failed")

    /** applink 路由事件 */
    public static let applink_route = EPMClientOpenPlatformGadgetCode(code: 10048, level: OPMonitorLevelNormal, message: "applink_route")

    /** 用户点击升级小程序事件 */
    public static let exit_app_ability_not_support = EPMClientOpenPlatformGadgetCode(code: 10049, level: OPMonitorLevelNormal, message: "exit_app_ability_not_support")

    /** 规则引擎，执行command失败 */
    public static let strategy_run_command_fail = EPMClientOpenPlatformGadgetCode(code: 10050, level: OPMonitorLevelError, message: "strategy_run_command_fail")

    /** JSCore 代理为空，WebView 与 JSCore 通信异常 */
    public static let jsruntime_delegate_empty = EPMClientOpenPlatformGadgetCode(code: 10051, level: OPMonitorLevelError, message: "jsruntime_delegate_empty")

    /** URLProtocol文件系统尝试获取 reader 失败 */
    public static let try_get_reader_failed = EPMClientOpenPlatformGadgetCode(code: 10052, level: OPMonitorLevelError, message: "try_get_reader_failed")

    /** 被废弃的代码超出预期运行，需要立即检查处理，否则一定会有问题 */
    public static let deprecated_code_runnnig = EPMClientOpenPlatformGadgetCode(code: 10053, level: OPMonitorLevelError, message: "deprecated_code_runnnig")

    /** schema 解析失败 */
    public static let parse_schem_error = EPMClientOpenPlatformGadgetCode(code: 10054, level: OPMonitorLevelError, message: "parse_schem_error")

    /** router 不合法 */
    public static let invalid_router = EPMClientOpenPlatformGadgetCode(code: 10055, level: OPMonitorLevelError, message: "invalid_router")

    /** preview实时预览自动重启 */
    public static let preview_restart = EPMClientOpenPlatformGadgetCode(code: 10057, level: OPMonitorLevelNormal, message: "preview_restart")

    /** 添加到多任务悬浮窗 */
    public static let add_to_floating_window = EPMClientOpenPlatformGadgetCode(code: 10058, level: OPMonitorLevelNormal, message: "add_to_floating_window")

    /** jsruntime触发documentOnReady的事件，无人来处理 */
    public static let jsruntime_document_ready_unconsumed = EPMClientOpenPlatformGadgetCode(code: 10060, level: OPMonitorLevelError, message: "jsruntime_document_ready_unconsumed")

    /** jsruntime发生Exception，无人来处理 */
    public static let jsruntime_exception_unconsumed = EPMClientOpenPlatformGadgetCode(code: 10061, level: OPMonitorLevelError, message: "jsruntime_exception_unconsumed")

    /** 小程序路由异常 */
    public static let gadget_navigation_exception = EPMClientOpenPlatformGadgetCode(code: 10062, level: OPMonitorLevelError, message: "gadget_navigation_exception")

    /** 小程序业务调用应用更新重启成功 */
    public static let apply_update = EPMClientOpenPlatformGadgetCode(code: 10070, level: OPMonitorLevelNormal, message: "apply_update")

    /** 小程序业务调用应用更新重启成功 */
    public static let apply_update_success = EPMClientOpenPlatformGadgetCode(code: 10070, level: OPMonitorLevelNormal, message: "apply_update_success")

    /** 小程序页面加载时jssdk文件不存在 */
    public static let jssdk_file_not_exist = EPMClientOpenPlatformGadgetCode(code: 10071, level: OPMonitorLevelError, message: "jssdk_file_not_exist")

    /** 小程序页面webview代理通知didFail */
    public static let navigation_delegate_did_fail = EPMClientOpenPlatformGadgetCode(code: 10072, level: OPMonitorLevelError, message: "navigation_delegate_did_fail")

    /** 小程序页面webview代理通知didFailProvisionalNavigation */
    public static let navigation_delegate_did_fail_provisional = EPMClientOpenPlatformGadgetCode(code: 10073, level: OPMonitorLevelError, message: "navigation_delegate_did_fail_provisional")

    /** 小程序更多菜单中重新加载小程序被电击 */
    public static let gadget_menu_reload = EPMClientOpenPlatformGadgetCode(code: 10074, level: OPMonitorLevelWarn, message: "gadget_menu_reload")

    /** 小程序错误恢复系统捕获到错误 */
    public static let recovery_error_catch = EPMClientOpenPlatformGadgetCode(code: 10075, level: OPMonitorLevelNormal, message: "recovery_error_catch")

    /** 小程序错误恢复系统捕获到错误并且小程序成功开始执行重试 */
    public static let recovery_error_retry = EPMClientOpenPlatformGadgetCode(code: 10076, level: OPMonitorLevelNormal, message: "recovery_error_retry")

    /** 小程序错误恢复成功，小程序顺利启动 */
    public static let recovery_success = EPMClientOpenPlatformGadgetCode(code: 10077, level: OPMonitorLevelNormal, message: "recovery_success")

    /** 小程序错误恢复遇到未知的错误Code */
    public static let recovery_unknown_error = EPMClientOpenPlatformGadgetCode(code: 10078, level: OPMonitorLevelWarn, message: "recovery_unknown_error")


    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: EPMClientOpenPlatformGadgetCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.gadget"
}