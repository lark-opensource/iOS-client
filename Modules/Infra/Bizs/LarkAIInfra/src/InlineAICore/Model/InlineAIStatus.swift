//
//  InlineAIStatus.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/18.
//  


import Foundation
import RxSwift
import RxCocoa

enum WritingStatus: String {
  case waiting // 指令选择页面
  case prepareWriting // 指令请求中
  case writing // AI生成中
  case finished // AI结果页
}

enum FeedbackChoice {
    case unselected
    case like
    case dislike
}

class InlineAIState {
    
    fileprivate(set) var sectionId: String
    
    fileprivate var tasks: [AITask] = []
    
    fileprivate var currentTaskIndex: Int = 0
    
    private var statusRelay = BehaviorRelay(value: WritingStatus.waiting)
    
    var status: WritingStatus { statusRelay.value }
    
    var promptGroups: [AIPromptGroup] = []

    var linkToMentions: [String: Any] = [:]
    
    var contentExtra: [String: AIAnyCodable]? {
        if linkToMentions.isEmpty {
            return nil
        } else {
            return ["linkToMention": AIAnyCodable(linkToMentions)]
        }
    }

    init(sectionId: String) {
        self.sectionId = sectionId
    }
    
    var taskIndex: Int {
        return currentTaskIndex
    }

    var totalTasksCount: Int {
        return tasks.count
    }

    func addNewTask(task: AITask) {
        guard tasks.contains(where: { $0.taskId == task.taskId }) == false else {
            LarkInlineAILogger.error("add task fail, taskId: \(task.taskId) already existed")
            return
        }
        tasks.append(task)
        currentTaskIndex = tasks.count - 1
        LarkInlineAILogger.info("add task: \(task.taskId) idx: \(currentTaskIndex)")
    }

    
    func update(sectionId: String) {
        LarkInlineAILogger.info("update sectionId: \(self.sectionId) --> \(sectionId)")
        self.sectionId = sectionId
    }
    
    func update(status: WritingStatus) {
        LarkInlineAILogger.info("update status: \(self.status) --> \(status)")
        self.statusRelay.accept(status)
    }
    
    func statusObservable() -> Observable<WritingStatus> {
        statusRelay.asObservable()
    }
    
    @discardableResult
    func popLastTask() -> AITask? {
        guard !tasks.isEmpty else { return nil }
        currentTaskIndex -= 1
        currentTaskIndex = max(currentTaskIndex, 0)
        return tasks.popLast()
    }

    func reset() {
        self.sectionId = ""
        self.promptGroups = []
        self.currentTaskIndex = 0
        self.statusRelay.accept(.waiting)
        self.tasks = []
    }
    
    var isClickQuickBefore: Bool {
        let sId = currentTask?.selectedPrompt?.id ?? ""
        return !sId.isEmpty
    }
    
}

extension InlineAIState {

    var currentTask: AITask? {
        guard currentTaskIndex < tasks.count else {
            LarkInlineAILogger.error("current task is nil")
            return nil
        }
        return tasks[currentTaskIndex]
    }
    
    var currentTaskId: String {
        guard currentTaskIndex < tasks.count else {
            return ""
        }
        return tasks[currentTaskIndex].taskId
    }
    
    func goToPreTask() -> AITask? {
        let preIndex = currentTaskIndex - 1
        guard preIndex < tasks.count, preIndex >= 0 else {
            return nil
        }
        currentTaskIndex = preIndex
        return tasks[currentTaskIndex]
    }
    
    func goToNextTask() -> AITask? {
        let nextIndex = currentTaskIndex + 1
        guard nextIndex < tasks.count, nextIndex >= 0 else {
            return nil
        }
        currentTaskIndex = nextIndex
        return tasks[currentTaskIndex]
    }
    
    var preTask: AITask? {
        let preIndex = currentTaskIndex - 1
        guard preIndex < tasks.count, preIndex > 0 else {
            return nil
        }
        return tasks[preIndex]
    }
}


class AITask {
    
    static let successCode = 0
    
    enum TaskResult {
        case success
        case unusual
    }

    var taskId: String
    var selectedPrompt: AIPrompt? // 上次选中内容
    var operators: [OperateButton] = []  // 结果页操作指令
    var content: String? // AI输出文本内容
    var image: InlineAIPanelModel.ImageData?
    var feedbackChoice: FeedbackChoice
    var userInputText: UserInputText?
    var promptConfirmOptions: AIPrompt.PromptConfirmOptions?
    var taskResult: TaskResult?
    var aiMessageID: String = ""

    private(set) var stop: Bool = false
    
    public init(taskId: String, selectedPrompt: AIPrompt? = nil, userInputText: UserInputText? = nil, operators: [OperateButton] = [], content: String? = nil, image: InlineAIPanelModel.ImageData? = nil, feedbackChoice: FeedbackChoice = .unselected) {
        self.taskId = taskId
        self.selectedPrompt = selectedPrompt
        self.userInputText = userInputText
        self.operators = operators
        self.content = content
        self.image = image
        self.feedbackChoice = feedbackChoice
    }
    
    static var defaultTask: AITask {
        return AITask(taskId: "placeholder")
    }
    
    func copyRetryTask() -> AITask {
        let task = Self.defaultTask
        task.content = nil
        task.userInputText = self.userInputText
        task.promptConfirmOptions = self.promptConfirmOptions
        task.selectedPrompt = self.selectedPrompt
        task.operators = self.operators
        return task
    }

    func stopGenerating() {
        self.stop = true
    }
    
    func prepare() {
        self.stop = false
    }
}

extension AITask {
    
    var ai_description: String {
        var dict = [String: Any]()
        dict["taskId"] = taskId
        dict["selectedPrompt"] = selectedPrompt?.ai_description ?? ""
        dict["operators"] = operators.map { $0.ai_description }
        dict["content"] = content ?? ""
        dict["image"] = String(describing: image)
        dict["feedbackChoice"] = "\(feedbackChoice)"
        dict["userInputText"] = String(describing: userInputText)
        dict["promptConfirmOptions"] = String(describing: promptConfirmOptions)
        dict["taskResult"] = String(describing: taskResult)
        dict["aiMessageID"] = aiMessageID
        dict["stop"] = stop
        return dict.sorted { $0.key < $1.key }.description
    }
}

enum UserInputText {
    case normal(text: String)
    case template(PromptTemplates, NSAttributedString)
    
    var textValue: String {
        switch self {
        case let .normal(text):
            return text
        case let .template(_, attributedString):
            return attributedString.string
        }
    }
    
    var userPrompt: String? {
        switch self {
        case let .normal(text):
            return text
        default:
            return nil
        }
    }
}
