//
//  LarkInlineAITracker.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/18.
//

import Foundation
import LKCommonsTracker


final class LarkInlineAITracker {
    // roadster白屏上报
    static func trackWebViewTerminate(count: Int, isBackground: Bool, isVisible: Bool) {
        let params: [AnyHashable: Any] = ["terminateCount": count, "background": isBackground ? 1:0, "isVisible": isVisible ? 1:0]
        post(event: .webviewTerminate, params: params)
    }
    
    static func trackWebViewFail(error: Error) {
        guard let urlError = error as? URLError else {
            return
        }
        let params: [AnyHashable: Any] = ["errCode": urlError.code, "errReason": urlError.underlyingError.localizedDescription]
        post(event: .webviewLoadFail, params: params)
    }
    
    static func trackUnZipFail(error: Error) {
        // nolint-next-line: magic number
        let params: [AnyHashable: Any] = ["errCode": -404, "errReason": "\(error.localizedDescription)"]
        post(event: .webviewLoadFail, params: params)
    }
    
    static func post(event: AITrackerEvent, params: [AnyHashable: Any]) {
        Tracker.post(TeaEvent(event.rawValue,
                              category: "InlineAI",
                              params: params))
    }
    
    var baseParqams: (() -> [AnyHashable: Any])
    
    var productType: String

    init(baseParqams: @escaping () -> [AnyHashable: Any], scenario: InlineAIConfig.ScenarioType) {
        self.baseParqams = baseParqams
        self.productType = scenario.productType
    }
    
    
    private func post(event: AITrackerEvent, params: [AnyHashable: Any]) {
        var tempParams = params
        tempParams["product_type"] = productType
        tempParams.merge(baseParqams()) { (_, new) in new }
        Tracker.post(TeaEvent(event.rawValue,
                              category: "InlineAI",
                              params: tempParams))
    }
}


// MARK: - 业务埋点

extension LarkInlineAITracker {
    
    enum QuitType: String {
        case clickAnywhere = "click_anywhere"
        case swipeDown = "swipe_down"
        case resultPage = "click_button_on_result_page"
        case otherCommandButton = "click_other_command_button"
    }
    
    
    func show(aiState: InlineAIState) {
        self.post(event: .floating_window_view, params: [:])
    }
    
    
    func quit(aiState: InlineAIState, quitTpyeStr: String) {
        let params: [AnyHashable: Any] = ["target": "none",
                                     "quit_type": quitTpyeStr,
                                     "status": aiState.status.rawValue,
                                     "command_type": aiState.currentTask?.selectedPrompt?.type ?? "user_prompt",
                                     "click": "quit"]
        self.post(event: .quit_floating_window_click, params: params)
    }
    
    func quit(aiState: InlineAIState, quitType: QuitType) {
        var status = aiState.status
        if status == .prepareWriting {
            status = .writing
        }
        self.quit(aiState: aiState, quitTpyeStr: status.rawValue)
    }
    
    
    enum SendPromptType: String {
        case click
        case enter
    }
    
    func currentTaskId(aiState: InlineAIState) -> String {
        var taskID = aiState.currentTaskId
        if aiState.currentTaskId == "placeholder" {
            taskID = ""
        }
        return taskID
    }
    
    func clickPrompt(aiState: InlineAIState, type: String?) {
        let taskID = currentTaskId(aiState: aiState)
        let pathType = aiState.status == .finished ? "adjustment" : "firt_time"
        let params: [AnyHashable: Any] = ["click": "command",
                                     "target": "none",
                                     "click_type": "click",
                                     "command_type": type ?? "",
                                     "path_type": pathType,
                                     "taskID": taskID]
        
        self.post(event: .quick_command_click, params: params)
    }
    
    func sendPrompt(aiState: InlineAIState, prompt: AIPrompt, isClickQuickBefore: Bool) {
        let taskID = currentTaskId(aiState: aiState)
        let pathType = aiState.status == .finished ? "adjustment" : "firt_time"
        let sendLocation = aiState.status == .finished ? "after_result" : "first_time"
        let params: [AnyHashable: Any] = ["click": "send",
                                     "target": "none",
                                     "click_type": "enter",
                                     "is_click_quick_command_before": "\(isClickQuickBefore)",
                                     "send_location": sendLocation,
                                     "command_type": prompt.type,
                                     "path_type": pathType,
                                     "taskID": taskID]
        
        self.post(event: .send_command_click, params: params)
    }
    
    func resultActionClick(aiState: InlineAIState, operationKey: String, isStopAction: Bool) {
        let sendLocation = aiState.status == .finished ? "after_result" : "first_time"
        let params: [AnyHashable: Any] = ["click": "action",
                                     "target": "none",
                                     "action_type": operationKey,
                                     "action_time_type": isStopAction ? "during_output" : "after_output",
                                     "send_location": sendLocation,
                                     "command_type": aiState.currentTask?.selectedPrompt?.type ?? "user_prompt",
                                     "taskID": aiState.currentTaskId]
        
        self.post(event: .result_action_click, params: params)
    }
    
    
    enum FeedbackType: String {
        case like
        case dislike
        case cancelLike = "cancel_like"
        case cancelDislike = "cancel_dislike"
    }

    func resultFeedbackClick(aiState: InlineAIState, feedbackType: FeedbackType) {
        let params: [AnyHashable: Any] = ["click": "feedback",
                                     "target": "none",
                                     "feedback_type": feedbackType.rawValue,
                                     "command_type": aiState.currentTask?.selectedPrompt?.type ?? "user_prompt",
                                     "taskID": aiState.currentTaskId]
        
        self.post(event: .result_feedback_click, params: params)
    }
    
    
    func historyToggleClick(aiState: InlineAIState, isNext: Bool) {
        let curNum = aiState.taskIndex + 1
        let params: [AnyHashable: Any] = ["click": "switch",
                                     "target": "none",
                                     "switch_type": isNext ? "next" : "forward",
                                     "click_number": "\(curNum)",
                                     "total_number": "\(aiState.totalTasksCount)"]
        
        self.post(event: .history_toggle_click, params: params)
    }
    
    func doubleCheckView(aiState: InlineAIState) {
        let params: [AnyHashable: Any] = ["command_type": aiState.currentTask?.selectedPrompt?.type ?? "user_prompt",]
        self.post(event: .doubleCheckView, params: params)
    }
    
    func doubleCheckClick(aiState: InlineAIState, isQuit: Bool) {
        let params: [AnyHashable: Any] = ["click": "button",
                                     "target": "none",
                                     "command_type": aiState.currentTask?.selectedPrompt?.type ?? "user_prompt",
                                     "button_type": isQuit ? "quit" : "continue"]
        self.post(event: .doubleCheckClick, params: params)
    }
}


extension InlineAIConfig.ScenarioType {
    
    var productType: String {
        return self.requestKey.lowercased()
    }
}
