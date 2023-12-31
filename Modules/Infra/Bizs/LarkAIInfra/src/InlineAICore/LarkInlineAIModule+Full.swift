//
//  LarkInlineAIModule+Full.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/20.
//  


import Foundation
import RxSwift
import RxCocoa
import ServerPB

extension LarkInlineAIModule: LarkInlineAISDK {
    
    var isEnable: BehaviorRelay<Bool> {
        return viewModel.myAIEnable
    }
    
    func getPrompt(triggerParamsMap: [String : String], result: @escaping (Result<[InlineAIQuickAction], Error>) -> Void) {
        viewModel.getPrompt(triggerParamsMap: triggerParamsMap, result: result)
    }
    
    func collapsePanel(_ isCollapsed: Bool) {
        guard let panelVC = self.panelVC else { return }
        if isCollapsed {
            viewModel.setVisible = true
            panelVC.dismiss(animated: false)
        } else {
            if panelVC.presentingViewController == nil {
                let vc = self.viewModel.aiFullDelegate?.getShowAIPanelViewController()
                vc?.present(panelVC, animated: false)
            }
            viewModel.setVisible = false
        }
    }

    func showPanel(promptGroups: [AIPromptGroup]) {
        // 展示指令列表
        viewModel.showPanel(promptGroups: promptGroups)
    }
    
    func sendPrompt(prompt: AIPrompt, promptGroups: [AIPromptGroup]?) {
        if let proups = promptGroups {
            viewModel.update(promptGroups: proups)
        }
        viewModel.initTaskIfNeed()
        let inputNeeded = !(prompt.templates?.templatePrefix.isEmpty ?? true)
        if inputNeeded {
            let model = viewModel.getWaitingData(promptGroups: promptGroups ?? [],
                                                 selectedPrompt: prompt)
            showPanel(panel: model)
        } else if !prompt.children.isEmpty {
            let promptGroups = [AIPromptGroup(title: "", prompts: prompt.children)]
            viewModel.update(promptGroups: promptGroups)
            let model = viewModel.getWaitingData(promptGroups: promptGroups,
                                                 showInput: false)
            showPanel(panel: model)
        } else {
            viewModel.sendPrompt(prompt: prompt, byOutside: true)
        }
    }

    func retryCurrentPrompt() {
        viewModel.retryCurrentPrompt()
    }
    
    var isPanelShowing: BehaviorRelay<Bool> {
        return viewModel.isShowing
    }
}
