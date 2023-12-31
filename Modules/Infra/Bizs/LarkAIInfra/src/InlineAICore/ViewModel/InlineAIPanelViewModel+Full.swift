//
//  InlineAIPanelViewModel+Full.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/18.
//  


import Foundation
import RustPB
import ServerPB
import RxSwift
import UniverseDesignTheme
import UniverseDesignDialog
import LarkEMM
import LarkSensitivityControl
import EENavigator

extension InlineAIPanelViewModel {
    
    var loadingString: String {
        return "..."
    }

    func initData() {
        guard config.isFullSDK else { return }
        subscribePushNotification()
        getRecentPrompt()
    }
    
    func showPanel(promptGroups: [AIPromptGroup]) {
        update(promptGroups: promptGroups)
        initTaskIfNeed()
        let model = getWaitingData(promptGroups: aiState.promptGroups)
        showPanelRelay.accept(model)
    }
    
    // 业务方主动hide
    func hidePanel(quitType: String) {
        tracker.quit(aiState: aiState, quitTpyeStr: quitType)
        aiState.reset()
        setVisible = false
    }
    
    /// 第一次show时创建一个空白的task
    func initTaskIfNeed() {
        guard aiState.totalTasksCount == 0 else { return }
        aiState.addNewTask(task: .defaultTask)
    }
    
    func handleEventInternal(event: InlineAIEvent) {
        switch event {
        case let .choosePrompt(prompt):
            choosePromptInFullMode(prompt: prompt)
            
        case let .textViewDidChange(text):
            textViewDidChangeInFullMode(text)
            
        case let .chooseOperator(operate):
            chooseOperatorInFullMode(operate: operate)
            tracker.resultActionClick(aiState: aiState, operationKey: operate.type ?? "", isStopAction: false)
            
        case .clickMaskErea:
            guard model?.dragBar?.doubleConfirm == true, config.needQuitConfirm else {
                if aiState.status == .prepareWriting, config.needQuitConfirm {
                    self.output.accept(.showAlert)
                    tracker.doubleCheckView(aiState: aiState)
                } else {
                    self.output.accept(.dismissPanel)
                    self.tracker.quit(aiState: aiState, quitType: .clickAnywhere)
                }
                return
            }
            switch aiState.status {
            case .writing, .prepareWriting, .finished:
                // 点击空白关闭 （需弹窗）
                self.output.accept(.showAlert)
                tracker.doubleCheckView(aiState: aiState)
            default:
                break
            }
            
        case .closePanel:
            self.output.accept(.dismissPanel)
            self.tracker.quit(aiState: aiState, quitType: .swipeDown)
            
        case .clickPrePage:
//            self.aiDelegate?.onClickHistory(pre: true)
            clickPrePageInFullMode()
            tracker.historyToggleClick(aiState: aiState, isNext: false)
            
        case .clickNextPage:
//            self.aiDelegate?.onClickHistory(pre: true)
            clickNextPageInFullMode()
            tracker.historyToggleClick(aiState: aiState, isNext: true)
            
        case .clickThumbUp:
            clickThumbUpInFullMode()
            
        case .clickThumbDown:
            clickThumbDownInFullMode()
            
    
        case let .keyboardDidSend(richTextContent):
            keyboardDidSendInFullMode(richTextContent)
            
        case .stopGenerating:
            tracker.resultActionClick(aiState: aiState, operationKey: "", isStopAction: true)
            handleStopGenerating()
            
        case let .panelHeightChange(height):
            self.aiFullDelegate?.onHeightChange(height: height)
            
        case .vcDismissed:
            if !setVisible {
                isShowing.accept(false)
                aiState.reset()
            } else {
                LarkInlineAILogger.info("ui is inVisible in vcDismissed state")
            }
            self.getRecentPrompt()
            
        case .vcPresented:
            if !setVisible {
                isShowing.accept(true)
                tracker.show(aiState: aiState)
            } else {
                LarkInlineAILogger.info("ui is inVisible in vcPresented state")
            }
            
        case .alertCancel:
            tracker.doubleCheckClick(aiState: aiState, isQuit: true)
            self.output.accept(.dismissPanel)
            if model?.dragBar?.doubleConfirm == true {
                tracker.quit(aiState: aiState, quitType: .swipeDown)
            } else {
                tracker.quit(aiState: aiState, quitType: .clickAnywhere)
            }

        case .alertContinue:
            tracker.doubleCheckClick(aiState: aiState, isQuit: false)
    
        case let .deleteHistoryPrompt(prompt):
            self.handelDeleteHistoryPrompt(prompt: prompt)

        case let .openURL(urlString):
            guard let url = URL(string: urlString) else {
                LarkInlineAILogger.error("urlString is not url object")
                return
            }
            guard let vc = self.aiFullDelegate?.getShowAIPanelViewController() else {
                LarkInlineAILogger.error("show vc is nil")
                return
            }
            self.config.userResolver.navigator.push(url, from: vc)
            
        case .clickCheckbox, .chooseSheetOperation, .clickAt:
            break
        
        default:
            break
        }
    }

    struct TempState {
        var content: String
        var rustState: RustTaskStatus
    }
    
}

// MARK: - handler
extension InlineAIPanelViewModel {
    func clickThumbUpInFullMode() {
        let task = self.aiState.currentTask
        var feedbackType: LarkInlineAITracker.FeedbackType = .like
        if task?.feedbackChoice == .like {
            task?.feedbackChoice = .unselected
            feedbackType = .cancelLike
        } else {
            task?.feedbackChoice = .like
            guard let currentTask = aiState.currentTask else {
                return
            }
            let aiMessageId = currentTask.aiMessageID
            let scenario = config.scenario.requestKey
            let queryRawdata: String
            if let text = currentTask.selectedPrompt?.text {
                queryRawdata = text
            } else if let text = currentTask.userInputText?.textValue {
                queryRawdata = text
            } else {
                queryRawdata = ""
            }
            let answerRawdata = currentTask.content ?? ""
            let config = LarkInlineAIFeedbackConfig(isLike: true,
                                                    aiMessageId: aiMessageId,
                                                    scenario: scenario,
                                                    queryRawdata: queryRawdata,
                                                    answerRawdata: answerRawdata)
            if self.lastLikeState == true {
                self.sendLikeFeedback(config: config)
            }
        }
        tracker.resultFeedbackClick(aiState: aiState, feedbackType: feedbackType)
    }
    
    func clickThumbDownInFullMode() {
        let task = self.aiState.currentTask
        var feedbackType: LarkInlineAITracker.FeedbackType = .dislike
        if task?.feedbackChoice == .dislike {
            task?.feedbackChoice = .unselected
            feedbackType = .cancelDislike
        } else {
            task?.feedbackChoice = .dislike
            guard let currentTask = aiState.currentTask else {
                return
            }
            let queryData: String
            if let text = currentTask.selectedPrompt?.text {
                queryData = text
            } else if let text = currentTask.userInputText?.textValue {
                queryData = text
            } else {
                queryData = ""
            }
            let config = LarkInlineAIFeedbackConfig(isLike: false,
                                            aiMessageId: currentTask.aiMessageID,
                                            scenario: config.scenario.requestKey,
                                            queryRawdata: queryData,
                                            answerRawdata: currentTask.content ?? "")
            if self.lastLikeState == false {
                self.output.accept(.showFeedbackAlert(config))
            }
        }
        tracker.resultFeedbackClick(aiState: aiState, feedbackType: feedbackType)
    }
    
    func textViewDidChangeInFullMode(_ text: String) {
        guard aiState.status == .waiting else {
            LarkInlineAILogger.info("text change at: \(aiState.status) is going to be ignored ")
            promptSearchUtils.searchText = text
            return
        }
        aiState.currentTask?.userInputText = nil
        let data = promptSearchUtils.search(searchText: text)
        let model = getWaitingData(promptGroups: [], innnerGroups: data)
        self.showPanelRelay.accept(model)
    }
    
    func chooseOperatorInFullMode(operate: InlineAIPanelModel.Operate) {
        guard let currentTask = aiState.currentTask else { return }
        for op in currentTask.operators {
            if op.key == operate.type {
                if let promptGroups = op.promptGroups {
                    let uiPrompts = promptGroups.toInlineAIPromptGroups()
                    let model = InlineAIPanelModel.Prompts(show: true, overlap: false, data: uiPrompts)
                    output.accept(.showPromptPanel(model: model, dragBar: .init(show: true, doubleConfirm: false)))
                } else {
                    op.perform(content: currentTask.content ?? "")
                }
                return
            }
        }
        LarkInlineAILogger.error("prompt \(operate.btnType) not found")
    }

    func keyboardDidSendInFullMode(_ richTextContent: RichTextContent) {
        guard let currentTask = self.aiState.currentTask else {
            return
        }
        switch richTextContent.data {
        case .quickAction(let quickAction):
            
            let displayName = quickAction.displayName
            for promptGroup in self.aiState.promptGroups {
                for prompt in promptGroup.prompts {
                    guard let templates = prompt.templates,
                          prompt.templates?.templatePrefix == displayName else {
                        continue
                    }
                    // userInput
                    let templateList = quickAction.paramDetails.map {
                        let key = $0.key
                        let name = templates.templateList.first { temp in
                            return temp.key == key
                        }.map { $0.templateName }
                        return PromptTemplate(templateName: name ?? $0.name, key: $0.key, defaultUserInput: $0.content)
                    }
                    currentTask.userInputText = .template(PromptTemplates(templatePrefix: quickAction.displayName, templateList: templateList), richTextContent.attributedString)
                
                    var extraParam: [String: String] = [:]
                    for paramDetail in quickAction.paramDetails {
                        extraParam[paramDetail.key] = paramDetail.content
                    }
                    let isClickQuickBefore = aiState.isClickQuickBefore
                    self.sendPrompt(prompt: prompt, extraParam: extraParam)
                    self.tracker.sendPrompt(aiState: aiState, prompt: prompt, isClickQuickBefore: isClickQuickBefore)
                    return
                }
            }
            LarkInlineAILogger.error("can not find prompt displayName:\(displayName) to send")
        case .freeInput:
            let text = richTextContent.attributedString.string
            // 检验是否符合无参模版指令(历史指令使用此结构)
            guard handleNoParamsTemplatePrompt(text: text) == false else {
                LarkInlineAILogger.info("send no params templatePrompt")
                return
            }
            
            if aiState.status == .finished {
                aiState.addNewTask(task: .defaultTask)
            }
            aiState.currentTask?.userInputText = .normal(text: text)
            guard let aiFullDelegate else {
                return
            }
            let prompt = aiFullDelegate.getUserPrompt()
            let isClickQuickBefore = aiState.isClickQuickBefore
            self.sendPrompt(prompt: prompt)
            self.tracker.sendPrompt(aiState: aiState, prompt: prompt, isClickQuickBefore: isClickQuickBefore)
        }
    }
    

    func handleNoParamsTemplatePrompt(text: String) -> Bool {
        var searchPrompt: AIPrompt?
        for group in aiState.promptGroups {
            guard let aiPrompt = findAIPromptByPrefix(text: text, with: group.prompts) else {
                continue
            }
            searchPrompt = aiPrompt
            break
        }
        if let prompt = searchPrompt {
            aiState.currentTask?.userInputText = .normal(text: text)
            if aiState.status == .finished {
                aiState.addNewTask(task: .defaultTask)
            }
            let isClickQuickBefore = aiState.isClickQuickBefore
            self.sendPrompt(prompt: prompt)
            tracker.sendPrompt(aiState: aiState, prompt: prompt, isClickQuickBefore: isClickQuickBefore)
            return true
        } else {
            return false
        }
    }
    
    func clickPrePageInFullMode() {
        guard aiState.status == .finished else {
            LarkInlineAILogger.error("click history pre page is not finished status: \(aiState.status)")
            return
        }
        guard let task = aiState.goToPreTask() else {
            LarkInlineAILogger.error("pre task is nil")
            return
        }
        self.aiFullDelegate?.onHistoryChange(text: task.content ?? "")
        showPanelRelay.accept(getFinishedData())
    }
    
    func clickNextPageInFullMode() {
        guard aiState.status == .finished else {
            LarkInlineAILogger.error("click history next page is not finished status: \(aiState.status)")
            return
        }
        guard let task = aiState.goToNextTask() else {
            LarkInlineAILogger.error("next task is nil")
            return
        }
        self.aiFullDelegate?.onHistoryChange(text: task.content ?? "")
        showPanelRelay.accept(getFinishedData())
    }

    func choosePromptInFullMode(prompt: InlineAIPanelModel.Prompt) {
        var promptGroups = aiState.promptGroups
        let operatorsGroup = self.aiState.currentTask?.operators.flatMap({ $0.promptGroups ?? [] }) ?? []
        promptGroups.append(contentsOf: operatorsGroup)
        for group in promptGroups {
            guard let aiPrompt = findAIPromptById(id: prompt.localId ?? "", with: group.prompts) else {
                continue
            }
            if let templates = aiPrompt.templates { // 模版指令
                self.output.accept(.clearTextView)
                if aiState.status == .waiting {
                    showPanelRelay.accept(getWaitingData(promptGroups: [],
                                                         selectedPrompt: aiPrompt,
                                                         quickAction: templates.toQuickAction()))
                } else if aiState.status == .finished {
                    showPanelRelay.accept(getFinishedData(quickAction: templates.toQuickAction()))
                }
                tracker.clickPrompt(aiState: aiState, type: aiPrompt.type)
            } else if !aiPrompt.children.isEmpty {  // 二级
                let uiPrompts = [AIPromptGroup(title: "", prompts: aiPrompt.children)].toInlineAIPromptGroups()
                let model = InlineAIPanelModel.Prompts(show: true, overlap: false, data: uiPrompts)
                self.output.accept(.showPromptPanel(model: model,
                                                    dragBar: .init(show: true,
                                                                   doubleConfirm: false)))
            } else {
                self.output.accept(.resignInputFirstResponder)
                self.output.accept(.clearTextView)
                if aiState.status == .finished {
                    aiState.addNewTask(task: .defaultTask)
                }
                self.sendPrompt(prompt: aiPrompt)
                tracker.clickPrompt(aiState: aiState, type: prompt.type)
            }
            return
        }
        LarkInlineAILogger.error("prompt \(prompt.id) not found")
    }
    
    private func findAIPromptById(id: String, with prompts: [AIPrompt]) -> AIPrompt? {
        guard !id.isEmpty, !prompts.isEmpty else { return nil }
        for aiPrompt in prompts {
            if aiPrompt.localId == id {
                return aiPrompt
            } else if let prompt = findAIPromptById(id: id, with: aiPrompt.children) {
                return prompt
            }
        }
        return nil
    }
    
    
    /// 根据发送内容，搜索无参模版指令
    private func findAIPromptByPrefix(text: String, with prompts: [AIPrompt]) -> AIPrompt? {
        guard !text.isEmpty, !prompts.isEmpty else { return nil }
        for aiPrompt in prompts {
            if let templates = aiPrompt.templates,
               templates.templateList.isEmpty, // 无参数
               text.hasPrefix(templates.templatePrefix) {
                return aiPrompt
            } else if let prompt = findAIPromptByPrefix(text: text, with: aiPrompt.children) {
                return prompt
            }
        }
        return nil
    }


    func handleStopGenerating() {
        dataProvider.cancelTask(taskId: aiState.currentTaskId)
        aiState.currentTask?.stopGenerating()

        if aiState.status == .prepareWriting {
            if aiState.totalTasksCount > 1 {
                // 如果有任务了，回到上一个任务？
                aiState.popLastTask()
                update(status: .waiting, tempState: nil)
            } else {
                if aiState.promptGroups.isEmpty {
                    output.accept(.dismissPanel)
                    tracker.quit(aiState: aiState, quitType: .clickAnywhere)
                } else {
                    update(status: .waiting, tempState: nil)
                }
            }
        } else if aiState.status == .writing {
            if aiState.totalTasksCount > 1, aiState.currentTask?.content == nil {
                aiState.popLastTask()
                aiState.update(status: .finished)
                showPanelRelay.accept(getFinishedData())
            } else {
                aiState.currentTask?.taskResult = .success
                let content = aiState.currentTask?.content ?? ""
                update(status: .finished, tempState: .init(content: content, rustState: .success))
            }
        } else {
            LarkInlineAILogger.error("stopGenerating status error ,error status:\(aiState.status)")
        }
    }
    
    /// 停止当前未完成的指令任务，使用场景：语音场景中的二级指令通过tabsView切换执行时，如果还未执行完成就切换到其他tab了需要将当前任务中止掉
    func stopCurrentUnfinishedTask() {
        
        if aiState.status == .writing {
            
            dataProvider.cancelTask(taskId: aiState.currentTaskId)
            aiState.currentTask?.stopGenerating()
            
            if aiState.totalTasksCount > 1, aiState.currentTask?.content == nil {
                aiState.popLastTask()
                aiState.update(status: .waiting)
            }
        } else {
            LarkInlineAILogger.error("stopGenerating status error ,error status:\(aiState.status)")
        }
    }
}

// MARK: - 状态流转
extension InlineAIPanelViewModel {
    func update(status: WritingStatus, tempState: TempState?) {
        LarkInlineAILogger.info("update state: \(self.aiState.status) --> \(status)")
        switch (self.aiState.status, status) {
        // 准备请求
        case (.waiting, .prepareWriting):
            showPanelRelay.accept(getPrepareWritingData())
            
        // 持续输出
        case (.writing, .writing), (.prepareWriting, .writing):
            let content = tempState?.content ?? ""
            aiState.currentTask?.content = content
            self.showPanelRelay.accept(getWritingData(content: content))
            
        // 输出完成/输出中中断
        case (.writing, .finished), (.prepareWriting, .finished):
           handleFinishState(tempState: tempState)
        
        // 等待中用户中断
        case (.prepareWriting, .waiting):
           showPanelRelay.accept(getWaitingData(promptGroups: self.aiState.promptGroups))
    
        // 二次交互
        case (.finished, .writing):
            showPanelRelay.accept(getWritingData(content: tempState?.content ?? loadingString))
        
        default:
            LarkInlineAILogger.error("\(self.aiState.status) --> \(status) is not supported")
        }
        
        self.aiState.update(status: status)
    }
    
    private func handleFinishState(tempState: TempState?) {
        if let selectedPrompt = self.aiState.currentTask?.selectedPrompt {
            if tempState?.content.isEmpty == false {
                self.aiState.currentTask?.content = tempState?.content
            }
            let isSuccess = (tempState?.rustState == .success)
            let operatorButtons = selectedPrompt.callback.onFinish(isSuccess ? AITask.successCode : -1)
            // 保存
            self.aiState.currentTask?.operators = operatorButtons
            
            // 处理异常状态下退出按钮
            var operates: InlineAIPanelModel.Operates?
            if let aiTask = aiState.currentTask,
               aiTask.taskResult == .unusual {
                var unusualOperators = self.getUnusualStateOperators()
                if config.debug {
                    unusualOperators.append(getDebugButton(aiTask: aiTask))
                }
                self.aiState.currentTask?.operators = unusualOperators
                operates = InlineAIPanelModel.Operates(show: true, data: unusualOperators.toAIOperateModels())
            }
            
            let model = getFinishedData(operates: operates)
            
            self.showPanelRelay.accept(model)
        } else {
            LarkInlineAILogger.error("selectedPrompt is nil")
        }
    }

}



// MARK: - Data Building
extension InlineAIPanelViewModel {
    
    func update(promptGroups: [AIPromptGroup]) {
        aiState.promptGroups = promptGroups
        // 增加历史指令
        if config.supportLastPrompt,
           !historyPrompts.isEmpty {
            let aiPrompts = historyPrompts.map { self.convertAIPrompt(action: $0) }
            var promptGroup: AIPromptGroup
            let maxMember = 5
            let recentTitle = BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAI_Recent_Title
            if historyPrompts.count <= maxMember {
                promptGroup = AIPromptGroup(title: recentTitle, prompts: aiPrompts)
                self.aiState.promptGroups.append(promptGroup)
            } else {
                var prompts = Array(aiPrompts[0..<maxMember])
                let morePrompt = moreAIPrompt(childen: Array(aiPrompts[maxMember...]))
                prompts.append(morePrompt)
                promptGroup = AIPromptGroup(title: recentTitle, prompts: prompts)
                self.aiState.promptGroups.append(promptGroup)
            }
        }
        promptSearchUtils.update(promptGroups: aiState.promptGroups.toInlineAIPromptGroups())
    }

    var isPreviewMode: Bool {
        return aiState.currentTask?.promptConfirmOptions?.isPreviewMode ?? true
    }
    
    var maskType: InlineAIPanelModel.MaskType {
        switch config.maskType {
        case .default:
            return isPreviewMode ? .fullScreen : .aroundPanel
        case .fullScreen:
            return .fullScreen
        case .aroundPanel:
            return .aroundPanel
        }
    }

    var isLock: Bool {
        switch config.lock {
        case .default:
            return isPreviewMode
        case .lock:
            return true
        case .unLock:
            return false
        }
    }

    
    /// 指令列表页
    /// - Parameters:
    ///   - promptGroups: 业务方全量数据
    ///   - innnerGroups: 筛选后的数据，优先级比promptGroups高
    ///   - selectedPrompt: 模版指令，设置时会自动激活输入框并填充模版
    ///   - quickAction: 快捷指令缓存
    ///   - showInput: 是否展示输入框
    /// - Returns: UI模型数据
    func getWaitingData(promptGroups: [AIPromptGroup],
                        innnerGroups: [InlineAIPanelModel.PromptGroups] = [],
                        selectedPrompt: AIPrompt? = nil,
                        quickAction: InlineAIPanelModel.QuickAction? = nil,
                        showInput: Bool = true) -> InlineAIPanelModel {
        
        var cacheText: String = ""
        var attributedString: NSAttributedString?
        switch aiState.currentTask?.userInputText {
        case let .normal(text):
            cacheText = text
        case let .template(_, attributedStr):
            attributedString = attributedStr
        case .none:
            break
        }
        var innerShowKeyboard = self.isKeyboardShow
        var textContentList = quickAction
        if let prompt = selectedPrompt,
           let templates = prompt.templates {
            //多参
            if !templates.templateList.isEmpty {
                textContentList = templates.toQuickAction()
            } else {
                // 没有多参，就不使用富文本展示
                textContentList = nil
                cacheText = templates.templatePrefix
            }
            innerShowKeyboard = true
        }
        if textContentList != nil {
            innerShowKeyboard = true
        }

        var uiPrompts = promptGroups.toInlineAIPromptGroups()
        if !innnerGroups.isEmpty {
            uiPrompts = innnerGroups
        } else if !cacheText.isEmpty {
            uiPrompts = promptSearchUtils.search(searchText: cacheText)
        }
        let placeHolder = self.config.placeHolder
    
        // drageBar
        let dragBar = InlineAIPanelModel.DragBar(show: !uiPrompts.isEmpty, doubleConfirm: false)
        
        // 指令列表
        let prompts = InlineAIPanelModel.Prompts(show: true, overlap: false, data: uiPrompts)

        let writingText = aiState.currentTask?.promptConfirmOptions?.writingPlaceholder ?? placeHolder.writingPlaceHolder
        // input
        var input = InlineAIPanelModel.Input(show: showInput, status: 0, text: cacheText, placeholder: placeHolder.waitingPlaceHolder, writingText: writingText, showStopBtn: false, showKeyboard: innerShowKeyboard, textContentList: textContentList)
        if let attributedStr = attributedString {
            input.update(.init(attributedStr))
        }
        return InlineAIPanelModel(show: true,
                                  dragBar: dragBar,
                                  prompts: prompts,
                                  input: input,
                                  theme: self.getCurrentTheme(),
                                  maskType: self.maskType.rawValue,
                                  conversationId: aiState.sectionId,
                                  taskId: aiState.currentTaskId,
                                  lock: isLock)
    }
    
    
    // 指令请求中
    func getPrepareWritingData() -> InlineAIPanelModel {
        
        let placeHolder = self.config.placeHolder
        
        let writingText = aiState.currentTask?.promptConfirmOptions?.writingPlaceholder ?? placeHolder.writingPlaceHolder
        
        let input = InlineAIPanelModel.Input(show: true, status: 1, text: "", placeholder: placeHolder.waitingPlaceHolder, writingText: writingText, showStopBtn: true, showKeyboard: false)
        
        return InlineAIPanelModel(show: true,
                                  dragBar: nil,
                                  content: loadingString,
                                  input: input,
                                  theme: self.getCurrentTheme(),
                                  maskType: self.maskType.rawValue,
                                  conversationId: aiState.sectionId,
                                  taskId: aiState.currentTaskId,
                                  lock: isLock)
    }
    
    // 指令生成中
    func getWritingData(content: String) -> InlineAIPanelModel {
        if content.isEmpty {
            LarkInlineAILogger.info("writing content is empty ")
        }
        let placeHolder = self.config.placeHolder
        let dragBar = InlineAIPanelModel.DragBar(show: isPreviewMode, doubleConfirm: config.needQuitConfirm)
        let writingText = aiState.currentTask?.promptConfirmOptions?.writingPlaceholder ?? placeHolder.writingPlaceHolder
        let input = InlineAIPanelModel.Input(show: true, status: 1, text: "", placeholder: placeHolder.waitingPlaceHolder, writingText: writingText, showStopBtn: true, showKeyboard: false)
        return InlineAIPanelModel(show: true,
                                  dragBar: dragBar,
                                  content: isPreviewMode ? content : "",
                                  input: input,
                                  theme: self.getCurrentTheme(),
                                  maskType: self.maskType.rawValue,
                                  conversationId: aiState.sectionId,
                                  taskId: aiState.currentTaskId,
                                  lock: isLock)
    }
    
    // 指令生成完毕
    func getFinishedData(operates: InlineAIPanelModel.Operates? = nil,
                         quickAction: InlineAIPanelModel.QuickAction? = nil) -> InlineAIPanelModel {
        let task = self.aiState.currentTask
        
        let placeHolder = self.config.placeHolder
        let dragBar = InlineAIPanelModel.DragBar(show: true, doubleConfirm: config.needQuitConfirm)
        
        
        if config.debug, let aiTask = task {
            let debugButton = getDebugButton(aiTask: aiTask)
            let oldDebugButton = task?.operators.first(where: { debugButton.key == $0.key })
            if oldDebugButton == nil {
                task?.operators.append(debugButton)
            }
        }
        var operates = operates
        if operates == nil {
            operates = InlineAIPanelModel.Operates(show: true, data: task?.operators.toAIOperateModels() ?? [])
        }
        
        var like = false
        var unlike = false
        
        switch task?.feedbackChoice ?? .unselected {
        case .unselected:
            like = false
            unlike = false
        case .like:
            like = true
            unlike = false
        case .dislike:
            like = false
            unlike = true
        }
        
        let tips = InlineAIPanelModel.Tips(show: true, text: BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Caution_Description)
        
        let leftArrowEnabled = aiState.taskIndex > 0
        let rightArrowEnabled = aiState.taskIndex < aiState.totalTasksCount - 1
        let showHistory = aiState.totalTasksCount > 1
        let history = InlineAIPanelModel.History(show: showHistory,
                                   total: aiState.totalTasksCount,
                                   curNum: aiState.taskIndex + 1,
                                   leftArrowEnabled: leftArrowEnabled,
                                   rightArrowEnabled: rightArrowEnabled)
        let position = showHistory ? "history" : "tips"
        let feedback = InlineAIPanelModel.Feedback(show: true, like: like, unlike: unlike, position: position)
        
        var showKeyboard = self.isKeyboardShow
        if quickAction != nil {
            showKeyboard = true
        }

        var placehoderSelected: Bool?
        var recentPrompt: InlineAIPanelModel.Prompt?
        var placeholder = placeHolder.waitingPlaceHolder

        var inputQuickAction = quickAction
        if config.supportLastPrompt,
           let currentTask = self.aiState.currentTask,
           let selectedPrompt = currentTask.selectedPrompt {
            if selectedPrompt.id == nil {
                // 自由指令
                placehoderSelected = true
                recentPrompt = nil
                placeholder = currentTask.userInputText?.textValue ?? ""
            } else {
                if selectedPrompt.templates != nil,
                   case let .template(templates, attStr) = currentTask.userInputText { // 模版指令
                    placehoderSelected = true
                    inputQuickAction = InlineAIPanelModel.QuickAction.convert(templates: templates)
                    placeholder = attStr.string
                } else { // 普通快捷指令
                    placehoderSelected = false
                    recentPrompt = selectedPrompt.toInternalPrompt()
                    placeholder = selectedPrompt.text
                }
            }
        }
        
        let input = InlineAIPanelModel.Input(show: true,
                                             status: 0,
                                             text: self.inputText,
                                             placeholder: placeholder,
                                             writingText: placeHolder.finishedPlaceHolder,
                                             showStopBtn: false,
                                             showKeyboard: showKeyboard,
                                             textContentList: inputQuickAction,
                                             placehoderSelected: placehoderSelected,
                                             recentPrompt: recentPrompt)
        var content = ""
        let isUnusual = aiState.currentTask?.taskResult == .unusual
        if let aiContent = task?.content, isPreviewMode || isUnusual {
            content = aiContent
        }
        
        return InlineAIPanelModel(show: true,
                                  dragBar: dragBar,
                                  content: content,
                                  contentExtra: aiState.contentExtra,
                                  operates: operates,
                                  input: input,
                                  tips: tips,
                                  feedback: feedback,
                                  history: history,
                                  theme: self.getCurrentTheme(),
                                  maskType: self.maskType.rawValue,
                                  conversationId: aiState.sectionId,
                                  taskId: aiState.currentTaskId,
                                  lock: isLock)
    }
    
    //错误处理，自定义构建退出按钮
    func getUnusualStateOperators() -> [OperateButton] {
        let operators = OperateButton(key: "exit", text: BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Quit_Button,
                                      isPrimary: true) { [weak self] (_, _) in
            guard let self = self else { return }
            self.output.accept(.dismissPanel)
            self.tracker.quit(aiState: self.aiState, quitType: .resultPage)
        }
        return [operators]
    }
    
    // 自定义构建调试信息按钮
    func getDebugButton(aiTask: AITask) -> OperateButton {
        let title = BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_CopyDebug_Button
        let button = OperateButton(key: "debug", text: title) { [weak self] (_, _) in
            guard let self = self else { return }
            self.output.accept(.debugInfo(aiTask))
        }
        return button
    }
    
    //当前主题
    func getCurrentTheme() -> String {
        InlineAIPanelModel.getCurrentTheme()
    }
    
}



// MARK: - 数据请求 
extension InlineAIPanelViewModel {
    
    func getPrompt(triggerParamsMap: [String: String], result: @escaping (Result<[InlineAIQuickAction], Error>) -> Void) {
         dataProvider.requestQuickActionsList(scenario: config.scenario.rawValue,
                                     triggerParamsMap: triggerParamsMap)
                     .observeOn(MainScheduler.instance)
                     .subscribe(onNext: {
                         LarkInlineAILogger.info("get prompt list success count:\($0.actions.count)")
                         result(.success($0.actions))
                     }, onError: { error in
                         LarkInlineAILogger.error("get prompt list error: \(error)")
                         result(.failure(error))
        }).disposed(by: disposeBag)
    }

    func sendPrompt(prompt: AIPrompt, extraParam: [String: String] = [:], byOutside: Bool = false) {
        var promptConfirmOptions = prompt.callback.onStart()
        if !extraParam.isEmpty {
            promptConfirmOptions.update(param: extraParam)
        }
        let uniqueTaskID = UUID().uuidString
        var actionType: PromptActionType
        if prompt.id == nil {
            // 自由指令
            actionType = .userPrompt
        } else {
            // 新指令
            actionType = .quickAction
        }
        
        aiState.currentTask?.taskId = uniqueTaskID
        aiState.currentTask?.selectedPrompt = prompt
        aiState.currentTask?.promptConfirmOptions = promptConfirmOptions
        if byOutside {
            self.tracker.clickPrompt(aiState: aiState, type: prompt.type)
        }
        
        if aiState.status == .finished { // 当前页面开始请求
            update(status: .writing, tempState: .init(content: loadingString, rustState: .processing))
        } else { // waiting页面请求
            update(status: .prepareWriting, tempState: nil)
        }

        let currentTask = aiState.currentTask
        currentTask?.prepare()

        dataProvider.sendPrompt(sectionID: aiState.sectionId,
                                uniqueTaskID: uniqueTaskID,
                                scenario: self.config.scenario.rawValue,
                                actionID: prompt.id,
                                actionType: actionType,
                                userPrompt: currentTask?.userInputText?.userPrompt,
                                displayContent: currentTask?.userInputText?.textValue ?? "",
                                params: promptConfirmOptions.param)
                     .observeOn(MainScheduler.instance)
                     .subscribe(onNext: { [weak self] in
                         guard let self = self else { return }
                         if self.aiState.sectionId.isEmpty {
                             self.aiState.update(sectionId: $0.sessionID)
                         } else if self.aiState.sectionId != $0.sessionID {
                             LarkInlineAILogger.error("[net] ❌❌❌ current sectionId:\(self.aiState.sectionId) rust sessionId:\( $0.sessionID) mismatch ❌❌❌  taskId: \(uniqueTaskID)")
                         }
                         LarkInlineAILogger.info("prepare to writing")
                  }, onError: { [weak self] error in
                      LarkInlineAILogger.error("send prompt error: \(error) taskId: \(uniqueTaskID)")
                      self?.handelErrorCode(error: error as NSError, with: prompt)
                 }).disposed(by: disposeBag)
    }
    
    func handelErrorCode(error: NSError, with prompt: AIPrompt) {
        guard let aiInfo = aiInfoService else {
            LarkInlineAILogger.error("can not resolver AIInfoService from current userResolver")
            return
        }
        let aiBrandName = aiInfo.defaultResource.name
        if let msg = AIRustErrorCode(rawValue: error.code)?.errMsg(nickName: nickName, aiBrandName: aiBrandName) {
            self.output.accept(.showErrorMsg(msg))
        }
        self.output.accept(.dismissPanel)
        prompt.callback.onError(error)
    }
    
    func retryCurrentPrompt() {
        guard let currentTask = aiState.currentTask,
              let selectedPrompt = currentTask.selectedPrompt else {
            LarkInlineAILogger.error("retry task is nil")
            return
        }
        LarkInlineAILogger.info("retry prompt...")
        aiState.addNewTask(task: currentTask.copyRetryTask())
        sendPrompt(prompt: selectedPrompt)
    }
}


// MARK: - Push数据处理
extension InlineAIPanelViewModel {
    
    func subscribePushNotification() {
        PushDispatcher.shared
                      .pushResponse
                      .observeOn(MainScheduler.instance)
                      .subscribe(onNext: { [weak self] response in
            guard let self = self else { return }
            let inlineAiTaskStatus = response.inlineAiTaskStatus
            let taskId = self.aiState.currentTask?.taskId ?? ""
            let uniqueTaskId = inlineAiTaskStatus.uniqueTaskID
            guard taskId == uniqueTaskId else {
                LarkInlineAILogger.error("[push] current taskIdId:\(taskId) pushTaskId:\(uniqueTaskId) mismatch")
                return
            }
            guard self.aiState.currentTask?.stop == false else {
                LarkInlineAILogger.error("[push] taskId has stoped!")
                return
            }
            self.handleTaskStatus(inlineAiTaskStatus)
        }).disposed(by: disposeBag)
    }
    
    func handleTaskStatus(_ taskStatus: InlineAITaskStatus) {
        
        let status = RustTaskStatus(rawValue: taskStatus.taskStatus) ?? .unknow
        let content = taskStatus.content
        let taskId = aiState.currentTask?.taskId ?? ""
#if DEBUG
        LarkInlineAILogger.info("receive push content count: \(content) status: \(taskStatus.taskStatus) taskId:\(taskId)")
#else
        LarkInlineAILogger.info("receive push content count: \(content.count) status: \(taskStatus.taskStatus) taskId:\(taskId)")
#endif
        let tempState = TempState(content: content, rustState: status)
        aiState.currentTask?.aiMessageID = taskStatus.aiMessageID
        switch status {
        case .processing:
            if self.aiState.status == .finished {
                LarkInlineAILogger.error("push content when status is finished!")
                return
            }
            if !content.isEmpty {
                if settings.urlParseEnable {
                    self.urlParser.parse(with: content)
                }
                update(status: .writing, tempState: tempState)
                self.aiState.currentTask?.selectedPrompt?.callback.onMessage(content)
            } else {
                LarkInlineAILogger.warn("content is nil in processing !!!")
            }
        case .success:
            aiState.currentTask?.taskResult = .success
            update(status: .finished, tempState: tempState)
            if settings.urlParseEnable {
                self.urlParser.parse(with: content)
            }
            if content.isEmpty {
                LarkInlineAILogger.warn("content is nil in success !!!")
            }
        case .failed, .time_out, .off_line:
            if let content = self.model?.content,
               !content.isEmpty,
               content != loadingString {
                // 有内容直接进结果页
                aiState.currentTask?.taskResult = .unusual
                update(status: .finished, tempState: TempState(content: content, rustState: status))
            } else {
                // 关闭浮窗
                self.output.accept(.showErrorMsg(BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Custom_NotAvail_Toast(nickName)))
                self.output.accept(.dismissPanel)
                self.aiState.currentTask?.selectedPrompt?.callback.onError(NSError(domain: taskStatus.taskStatus, code: -1))
            }
        case .tns_block:
            // 直接进结果页
            if content.isEmpty {
                LarkInlineAILogger.warn("content is nil in tns_block !!!")
            }
            aiState.currentTask?.taskResult = .unusual
            update(status: .finished, tempState: tempState)
        case .unknow:
            LarkInlineAILogger.error("[push] there are still state:\(taskStatus.taskStatus) that have not been processed")
        }
    }
}

// MARK: - 赞踩请求
extension InlineAIPanelViewModel {
    
    /// 点赞请求
    func sendLikeFeedback(config: LarkInlineAIFeedbackConfig) {
        let aiMessageId = config.aiMessageId
        let scenario = config.scenario
        let queryRawdata = config.queryRawdata
        let answerRawdata = config.answerRawdata
        dataProvider.sendLikeFeedback(aiMessageId: aiMessageId,
                                      scenario: scenario,
                                      queryRawdata: queryRawdata,
                                      answerRawdata: answerRawdata,
                                      completion: { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                LarkInlineAILogger.error("send `Like` feedback failed: \(error)")
            }
        })
    }
}

// MARK: - 调试信息
extension InlineAIPanelViewModel {
    
    /// 获取调试信息
    func getDebugInfo(aiTask: AITask) {
        
        dataProvider.getDebugInfo(aiMessageId: aiTask.aiMessageID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let debugInfo):
                let contentString = "===taskInfo:\n" + aiTask.ai_description + "\n\n===debugInfo:\n" + debugInfo
                self.output.accept(.presentVC(AIDebugDialog.createDebugDialog(content: contentString) { [weak self] in
                    self?.output.accept(.showSuccessMsg(BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Copied_Toast))}))
            case .failure:
                let text = BundleI18n.LarkAIInfra.LarkCCM_MyAI_NetworkOrServiceError_Toast
                self.output.accept(.showErrorMsg(text))
            }
        }
    }
}

extension InlineAIPanelViewModel: InlineAIURLParserDelegate {
    
    func didFinishParse(result: [String: Any]) {
        var isNew = true
        for (key, _) in result {
            if self.aiState.linkToMentions[key] != nil {
                isNew = false
            }
        }
        self.aiState.linkToMentions.merge(result) { (_, new) in new }
        if self.aiState.status == .finished, isNew {
            self.currentModel?.panelModel.updateContentExtra(aiState.contentExtra)
            if let model = self.currentModel {
                self.output.accept(.show(model: model))
            }
        }
    }
}
