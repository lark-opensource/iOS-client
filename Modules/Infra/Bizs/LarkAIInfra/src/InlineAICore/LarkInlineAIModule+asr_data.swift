//
//  LarkInlineAIModule+asr_data.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/9/26.
//

import Foundation

extension InlineAIAsrSDKImpl {
    
    /// 通过请求拉取指令列表，保存在缓存中
    func fetchPrompts(result: ((Result<[AIPromptGroup], Error>) -> Void)?) {
        
        let needOnboarding = aiModule.aiOnboardingService?.needOnboarding.value ?? false
        if needOnboarding { // 需要onboarding时返回空数据
            result?(.success([]))
            return
        }
        
        let completion: (Result<[InlineAIQuickAction], Error>) -> Void = { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success(let actions):
                var prompts = actions.map { action in
                    let icon = self.getIconKeyOfExtraMap(extraMap: action.extraMap)
                    let extraMap = self.getCommentOfExtraMap(extraMap: action.extraMap)
                    let type = (extraMap["key"] as? String) ?? "" // 给业务方埋点用
                    let result = AIPrompt(id: action.id,
                                          icon: icon,
                                          text: action.name,
                                          type: type,
                                          callback: .empty)
                    result.extraMap = extraMap
                    return result
                }
                prompts = self.constructPromptList(origin: prompts)
                let groups = [AIPromptGroup(title: "", prompts: prompts)]
                self.updatePromptsCache(groups)
                result?(.success(groups))
            case .failure(let error):
                result?(.failure(error))
            }
        }
        
        aiModule.viewModel.getPrompt(triggerParamsMap: [:], result: completion)
    }
    
    /// 执行特定指令
    func excutePrompt(_ prompt: AIPrompt, param: [String: String], callback: InlineAIAsrCallback) {
        if prompt.children.isEmpty { // 一级指令
            excuteSinglePrompt(prompt, param: param, callback: callback)
        } else { // 子级指令
            viewModel.resetCache()
            
            let tabTitles = prompt.children.map { $0.text }
            voiceContentView?.setTabTitles(tabTitles)
            
            voiceContentView?.tabIndexChanged = { [weak self] index in
                guard let self = self else { return }
                guard (0 ..< prompt.children.count).contains(index) else { return }
                let childPrompt = prompt.children[index]
                let cacheKey = childPrompt.id ?? ""
                if let model = self.viewModel.getModelCache(key: cacheKey) { // 使用缓存
                    let isFinish = model.input?.status == 0
                    self.voiceContentView?.updateContent(model.content ?? "",
                                                         theme: model.theme ?? "",
                                                         conversationId: model.conversationId,
                                                         taskId: model.taskId,
                                                         isFinish: isFinish)
                    self.voiceContentView?.setState(.finished(.success(())))
                } else {
                    self.aiModule.viewModel.stopCurrentUnfinishedTask()
                    self.excuteSinglePrompt(childPrompt, param: param, callback: callback)
                    let writingPanelModel = self.aiModule.viewModel.getWritingData(content: self.aiModule.viewModel.loadingString)
                    self.aiModule.viewModel.output.accept(.show(model: .init(panelModel: writingPanelModel,
                                                                             imageModels: [])))
                    self.aiModule.viewModel.showPanelRelay.accept(self.aiModule.viewModel.getPrepareWritingData())
                }
            }
            
            if let firstChildPrompt = prompt.children.first {
                excuteSinglePrompt(firstChildPrompt, param: param, callback: callback)
            }
        }
    }
    
    private func excuteSinglePrompt(_ prompt: AIPrompt, param: [String: String], callback: InlineAIAsrCallback) {
        
        let extraParam = param
        
        let excute: () -> Void = { [weak self] in
            prompt.callback = AIPrompt.AIPromptCallback(onStart: {
                AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: extraParam)
            }, onMessage: { _ in
                
            }, onError: { [weak callback, weak self] err in
                callback?.onError(err)
                self?.isShowing.accept(false)
            }, onFinish: { _ in
                []
            })
            self?.aiModule.viewModel.sendPrompt(prompt: prompt, extraParam: extraParam, byOutside: true)
        }
        
        if cachedPromptGroup.isEmpty {
            getPrompts { [weak self] in
                switch $0 {
                case .success(let groups):
                    self?.aiModule.showPanel(promptGroups: groups) // TODO.chensi 移到UI逻辑中
                    excute()
                case .failure(let error):
                    LarkInlineAILogger.error("get prompt list error: \(error)")
                }
            }
        } else {
            aiModule.showPanel(promptGroups: cachedPromptGroup)
            excute()
        }
    }
}

extension InlineAIAsrSDKImpl {
    
    private func getIconKeyOfExtraMap(extraMap: [String: String]) -> String {
        let commentMap = getCommentOfExtraMap(extraMap: extraMap)
        if let icon = commentMap["icon"] as? String {
            return icon
        }
        return PromptIcon.imDefault.rawValue // 兜底
    }

    private func getCommandTypeOfExtraMap(extraMap: [String: String]) -> String? {
        let commentMap = getCommentOfExtraMap(extraMap: extraMap)
        return commentMap["command_type"] as? String
    }

    private func getCommentOfExtraMap(extraMap: [String: String]) -> [String: Any] {
        guard let jsonString = extraMap["Comment"] else { return [:] }
        if let jsonData = jsonString.data(using: .utf8) {
            let options: JSONSerialization.ReadingOptions = [.mutableLeaves, .fragmentsAllowed]
            return (try? JSONSerialization.jsonObject(with: jsonData, options: options) as? [String: Any]) ?? [:]
        }
        return [:]
    }
    
    /// 处理子级指令相关逻辑
    private func constructPromptList(origin: [AIPrompt]) -> [AIPrompt] {
        var topPrompts = [String: AIPrompt]() // 一级指令
        var subPrompts = [AIPrompt]() // 子级指令
        
        for prompt in origin {
            let parent_key = prompt.extraMap["parent_key"] as? String
            if let parent_key = parent_key, !parent_key.isEmpty { // 存在parent_key代表是`子级指令`
                subPrompts.append(prompt)
            } else {
                let key = prompt.extraMap["key"] as? String
                if let key = key, !key.isEmpty {
                    topPrompts[key] = prompt
                }
            }
        }
        
        subPrompts = subPrompts.sortedByPriority() // subPrompts按照优先级排序
        
        for prompt in subPrompts {
            let parent_key = prompt.extraMap["parent_key"] as? String ?? ""
            if let parent = topPrompts[parent_key] {
                parent.children.append(prompt)
                topPrompts[parent_key] = parent
            }
        }
        
        var result = [AIPrompt]()
        for (_, value) in topPrompts {
            result.append(value) //TODO.chensi 优化不必要的遍历
        }
        result = result.sortedByPriority() // topPrompts按照优先级排序
        return result
    }
}

private extension Array where Element == AIPrompt {
    
    func sortedByPriority() -> [AIPrompt] {
        var result = self
        result.sort { prompt1, prompt2 in
            let priority1 = prompt1.extraMap["priority"] as? Int ?? 0
            let priority2 = prompt2.extraMap["priority"] as? Int ?? 0
            return priority1 < priority2
        }
        return result
    }
}

extension AIPrompt.AIPromptCallback {
    
    public static var empty: AIPrompt.AIPromptCallback {
        return .init {
            .init(isPreviewMode: true, param: [:])
        } onMessage: { _ in
            
        } onError: { _ in
            
        } onFinish: { _ in
            []
        }
    }
}
