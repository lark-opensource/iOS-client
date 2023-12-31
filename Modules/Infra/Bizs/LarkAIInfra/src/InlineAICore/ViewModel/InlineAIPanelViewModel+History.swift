//
//  InlineAIPanelViewModel+History.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/11/6.
//  


import Foundation
import ServerPB
import RxSwift
import RxCocoa


extension InlineAIPanelViewModel {
    
    func getRecentPrompt() {
        guard config.supportLastPrompt else { return }
        let retryCount: Int = 3
        dataProvider.getRecentActions(scenario: config.scenario.rawValue)
                    .retry(retryCount)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] response in
            guard let self = self else { return }
            LarkInlineAILogger.info("get recentActions count: \(response.records.count)")
            if response.records != historyPrompts {
                self.historyPrompts = response.records
                self.reloadHistoryPrompts()
            }
        }, onError: { error in
            LarkInlineAILogger.error("getRecentActions error: \(error)")
        }).disposed(by: disposeBag)
    }
    
    func reloadHistoryPrompts() {
        self.update(promptGroups: aiState.promptGroups)
        if self.isShowing.value {
            self.updateUIPrompts()
        }
    }
    
    func updateUIPrompts(subpanelPrompts: [AIPrompt] = []) {
        // 构建UI层数据
        var uiPrompts = self.aiState.promptGroups.toInlineAIPromptGroups()
        let searchText = promptSearchUtils.searchText
        if !searchText.isEmpty {
            uiPrompts = promptSearchUtils.search(searchText: searchText)
        }
        self.currentModel?.panelModel.prompts?.update(data: uiPrompts)
        if let model = self.currentModel {
            self.output.accept(.show(model: model))
            
            // 二级面板更新
            if !subpanelPrompts.isEmpty {
                let subGroups = [AIPromptGroup(title: "", prompts: subpanelPrompts)].toInlineAIPromptGroups()
                let model = InlineAIPanelModel.Prompts(show: true, overlap: false, data: subGroups)
                let dragBar = InlineAIPanelModel.DragBar(show: true, doubleConfirm: false)
                self.output.accept(.updateSubPromptPanel(model: model, dragBar: dragBar))
            }
        }
    }
    
    func convertInternalPrompt(action: RecentAction) -> InlineAIPanelModel.Prompt {
        let type = InlineAIPanelModel.PromptType.historyPrompt.rawValue
        return InlineAIPanelModel.Prompt(id: action.id, localId: action.id, icon: PromptIcon.edit.rawValue, text: action.userPrompt, type: type)
    }
    
    func convertAIPrompt(action: RecentAction) -> AIPrompt {
        let type = InlineAIPanelModel.PromptType.historyPrompt.rawValue
        return AIPrompt(id: nil,
                        localId: action.id,
                        icon: PromptIcon.historyOutlined.rawValue,
                        text: action.userPrompt,
                        type: type,
                        templates: PromptTemplates(templatePrefix: action.userPrompt, templateList: []),
                        callback: defaultCallback())
    }
    
    private func defaultCallback() -> AIPrompt.AIPromptCallback {
        return AIPrompt.AIPromptCallback(onStart: { [weak self] in
            guard let self = self, let aiFullDelegate = self.aiFullDelegate else {
                return .init(isPreviewMode: false, param: [:])
            }
                return aiFullDelegate.getUserPrompt().callback.onStart()
            }, onMessage: { [weak self] msg in
                guard let self = self, let aiFullDelegate = self.aiFullDelegate else {
                    return
                }
                aiFullDelegate.getUserPrompt().callback.onMessage(msg)
            }, onError: { [weak self] err in
                guard let self = self, let aiFullDelegate = self.aiFullDelegate else {
                    return
                }
                aiFullDelegate.getUserPrompt().callback.onError(err)
            }, onFinish: { [weak self] code in
                guard let self = self, let aiFullDelegate = self.aiFullDelegate else {
                    return []
                }
                return aiFullDelegate.getUserPrompt().callback.onFinish(code)
            })
    }
    
    func moreAIPrompt(childen: [AIPrompt])-> AIPrompt {
        return AIPrompt(id: "history_more",
                        icon: PromptIcon.more.rawValue,
                        text: BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_More_Menu,
                        type: InlineAIPanelModel.PromptType.historyPrompt.rawValue,
                        children: childen,
                        callback: defaultCallback())
    }
    
    func handelDeleteHistoryPrompt(prompt: InlineAIPanelModel.Prompt) {
        guard let id = prompt.localId else {
            LarkInlineAILogger.error("[delete] deleteRecentAction id is nil")
            return
        }
        dataProvider.deleteRecentAction(scenario: config.scenario.rawValue, id: id)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        self?.output.accept(.showSuccessMsg(BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAI_PromptDeleted_Toast))
                        LarkInlineAILogger.error("[delete] deleteRecentAction success id:\(prompt.id)")
            self?.deleteLocalHistoryPrompt(by: id)
        }, onError: { [weak self] error in
            self?.output.accept(.showSuccessMsg(BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAI_PromptDeleteFailed_Toast))
            LarkInlineAILogger.error("[delete] deleteRecentAction error:\(error)")
        }).disposed(by: disposeBag)
    }
    
    func deleteLocalHistoryPrompt(by id: String) {
        let type = InlineAIPanelModel.PromptType.historyPrompt.rawValue

        var needUpdateChildren: [AIPrompt] = []
        for group in self.aiState.promptGroups {
            group.prompts.removeAll {
                $0.type == type && $0.localId == id
            }
            // 目前只有二级面板，只需要处理第二层数据即可
            let prompts = group.prompts.filter { !$0.children.isEmpty }
            guard !prompts.isEmpty else {
                continue
            }

            for prompt in prompts {
                var children = prompt.children
                guard !children.isEmpty else {
                    continue
                }
                let preCount = children.count
                children.removeAll {
                    $0.type == type && $0.localId == id
                }
                prompt.children = children
                if children.count != preCount {
                    needUpdateChildren = children
                }
                if children.isEmpty {
                    LarkInlineAILogger.info("[delete] dismiss fater deleting subPanel item")
                    self.output.accept(.hideAllSubPromptView)
                    needUpdateChildren = []
                    break
                }
            }
        }
        self.aiState.promptGroups.removeAll { $0.prompts.isEmpty }
        if self.isShowing.value {
            self.updateUIPrompts(subpanelPrompts: needUpdateChildren)
        }
    }
}
