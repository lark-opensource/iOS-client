//
//  AITrackerEvent.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/8/14.
//  


import Foundation

enum AITrackerEvent: String {
    // == 技术埋点 ==
    case webviewTerminate = "inlineai_performance_webview_terminate_dev"
    case webviewLoadFail = "inlineai_performance_webview_load_fail_dev"
    
    
    // == 业务埋点 ==

    // AI浮窗的展示
    case floating_window_view = "ccm_ai_floating_window_view"

    // 退出浮窗
    case quit_floating_window_click = "ccm_ai_quit_floating_window_click"

    // AI浮窗上的快捷指令点击
    case quick_command_click = "ccm_ai_quick_command_click"

    // AI浮窗上的发送指令点击
    case send_command_click = "ccm_ai_send_command_click"

    // AI输出过程中或者输出结果后，对结果的操作
    case result_action_click = "ccm_ai_result_action_click"
    
    // 对AI输出结果的反馈
    case result_feedback_click = "ccm_ai_result_feedback_click"
    
    // 用户在唤起和关闭浮窗之间，进行了多轮对话，展示历史记录切换入口，对历史记录切换的点击
    case history_toggle_click = "ccm_ai_history_toggle_click"
    
    case doubleCheckView = "ccm_doc_ai_quit_double_check_view"
    
    case doubleCheckClick = "ccm_doc_ai_quit_double_check_click"
}
