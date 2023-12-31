//
//  InlineAIViewModel + PanelBuild.swift
//  Calendar
//
//  Created by pluto on 2023/10/15.
//

import Foundation
import LarkAIInfra
import UniverseDesignColor


// MARK: - Panel Model组装
extension InlineAIViewModel {

    //搜索面板
    func getSearchInlineAIPanelModel(text: String) -> InlineAIPanelModel {
        let prompts = genInlineAIPanelModelPrompts(text: text)

        let input = genInlineAIPanelModelInput(show: true,
                                               status: 0,
                                               text: text,
                                               placeHolder: I18n.Calendar_G_TellAIWhatToDo_Placeholder)
        let dragbar = InlineAIPanelModel.DragBar(show: true, doubleConfirm: true)

        let model = InlineAIPanelModel(show: true,
                                       dragBar: prompts.show ? dragbar : nil,
                                       prompts: prompts,
                                       input: input,
                                       maskType: MaskType.fullScreen.rawValue,
                                       conversationId: "",
                                       taskId: "",
                                       lock: true)
        return model
    }

    /// 初始化面板
    func getInitialInlineAIPanelModel() -> InlineAIPanelModel {
        
        let prompts = genInlineAIPanelModelPrompts()
        
        let input = genInlineAIPanelModelInput(show: true,
                                               status: 0,
                                               text: "",
                                               placeHolder: I18n.Calendar_G_TellAIWhatToDo_Placeholder)
        let dragbar = InlineAIPanelModel.DragBar(show: true, doubleConfirm: true)

        let model = InlineAIPanelModel(show: true,
                                       dragBar: prompts.show ? dragbar : nil,
                                       prompts: prompts,
                                       input: input,
                                       maskType: MaskType.fullScreen.rawValue,
                                       conversationId: "",
                                       taskId: "",
                                       lock: true)
        return model
    }
    
    /// 进行中面板
    func getWorkingOnItAIPanelModel() -> InlineAIPanelModel {
        let input = genInlineAIPanelModelInput(show: true,
                                               status: 1,
                                               text: "",
                                               placeHolder: I18n.Calendar_G_TellAIWhatToDo_Placeholder,
                                               showKeyboard: false,
                                               writingText: I18n.Calendar_G_GeneratingEventInfo_Desc,
                                               showStopBtn: true)
        
        let model = InlineAIPanelModel(show: true,
                                       prompts: nil,
                                       input: input,
                                       maskType: MaskType.aroundPanel.rawValue,
                                       conversationId: "",
                                       taskId: uniqueTaskID,
                                       lock: true)
        return model
    }
    
    /// 完成态面板
    func getFinishedAIPanelModel(hasHistory: Bool, feedBack: FeedBackStatus = .unknown, errorTips: String = "") -> InlineAIPanelModel {
        let isError: Bool = !errorTips.isEmpty
        let operates = genOperatesModel(isError: isError)
        let feedback = genFeedbackModel(hasHistory: hasHistory, feedBack:feedBack)
        let tips = genTipsModel(text: I18n.Calendar_G_AIDisclaimer_Desc)
        var history: InlineAIPanelModel.History? = nil
        if hasHistory {
            history = genHistoryModel()
        }
        
        let model = InlineAIPanelModel(show: true,
                                       content: errorTips,
                                       prompts: nil,
                                       operates: operates,
                                       input: nil,
                                       tips: tips,
                                       feedback: feedback,
                                       history: history,
                                       maskType: MaskType.aroundPanel.rawValue,
                                       conversationId: "",
                                       taskId: "",
                                       lock: false)
        return model
    }
    
    /// 模版指令上屏
    func getTempleteInputPanel(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) -> InlineAIPanelModel {
        
        let paramDetailsList = getTemplateParamModel(params: prompt.template ?? "")
        let textContentList = InlineAIPanelModel.QuickAction(displayName: prompt.text, paramDetails: paramDetailsList)
        let input = genInlineAIPanelModelInput(show: true,
                                               status: 0,
                                               text: "",
                                               placeHolder: I18n.Calendar_G_TellAIWhatToDo_Placeholder,
                                               showKeyboard: true,
                                               showStopBtn: false,
                                               textContentList: textContentList)
        let model = InlineAIPanelModel(show: true,
                                       prompts: nil,
                                       input: input,
                                       maskType: MaskType.fullScreen.rawValue,
                                       conversationId: "",
                                       taskId: "",
                                       lock: true)
        return model
    }
    
    func getTemplateParamModel(params: String) -> [InlineAIPanelModel.ParamDetail] {
        guard let jsonData = params.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
            return []
        }
        
        let decoder = JSONDecoder()
        let models =  (try? decoder.decode([InlineAIPanelModel.ParamDetail].self, from: jsonData)) ?? []
        return models
   }
    
    /// 完成态Operates按钮model
    func genOperatesModel(isError: Bool) -> InlineAIPanelModel.Operates {
        let confirmOperate = InlineAIPanelModel.Operate(text: I18n.Calendar_Common_Done, type: OperateType.confirm.rawValue, btnType: OperateBtnType.primary.rawValue)
        let adjustOperate = InlineAIPanelModel.Operate(text: I18n.Calendar_G_AdjustIt_Button, type: OperateType.adjust.rawValue, btnType: OperateBtnType.default.rawValue)
        let retryOperate = InlineAIPanelModel.Operate(text: I18n.Calendar_Attachment_RetryUploadButtonTag, type: OperateType.retry.rawValue, btnType: OperateBtnType.default.rawValue)
        let cancelOperate = InlineAIPanelModel.Operate(text: I18n.Calendar_Common_Exit, type: OperateType.cancel.rawValue, btnType: OperateBtnType.default.rawValue)

        let operateDatas: [InlineAIPanelModel.Operate] = [confirmOperate,
                                                          adjustOperate,
                                                          retryOperate,
                                                          cancelOperate]
        let operateErrorDatas: [InlineAIPanelModel.Operate] = [retryOperate,
                                                               cancelOperate]
        let operates = InlineAIPanelModel.Operates(show: true, data: isError ? operateErrorDatas: operateDatas)
        return operates
    }
    
    /// 反馈按钮
    func genFeedbackModel(hasHistory: Bool, feedBack: FeedBackStatus) -> InlineAIPanelModel.Feedback {
        
        let feedBack = InlineAIPanelModel.Feedback(show: true,
                                                   like: feedBack == .like,
                                                   unlike: feedBack == .unlike,
                                                   position: hasHistory ? FeedBackPosition.history.rawValue : FeedBackPosition.tips.rawValue)
        return feedBack
    }
    
    /// 完成态提示
    func genTipsModel(text: String) -> InlineAIPanelModel.Tips {
        let tips = InlineAIPanelModel.Tips(show: true, text: text)
        return tips
    }
    
    /// 历史记录
    func genHistoryModel() -> InlineAIPanelModel.History {
        let totalHistoryCount = historyMap.count
        let showCurrentHistoryIndex = currentHistoryIndex + 1
        let leftArrowEnabled: Bool = showCurrentHistoryIndex > 1
        let rightArrowEnabled: Bool = showCurrentHistoryIndex < totalHistoryCount
        let history = InlineAIPanelModel.History(show: true,
                                                 total: totalHistoryCount,
                                                 curNum: showCurrentHistoryIndex,
                                                 leftArrowEnabled: leftArrowEnabled,
                                                 rightArrowEnabled: rightArrowEnabled)
        return history
    }
    
    /// 二级Panel
    func genSubPanelModel() -> InlineAISubPromptsModel {
        let adjustPromptGroups = InlineAIPanelModel.PromptGroups(prompts: genPromptsByGroup(groupType: .adjust))
        let dragbar = InlineAIPanelModel.DragBar(show: true, doubleConfirm: true)
        let model = InlineAISubPromptsModel(data: [adjustPromptGroups], dragBar: dragbar)
        return model
    }
    

    func genInlineAIPanelModelPrompts(text: String = "") -> InlineAIPanelModel.Prompts {
        var promptGroups: [InlineAIPanelModel.PromptGroups] = []
        let templatePrompts = genPromptsByGroup(groupType: .template, text: text)
        let templetePromptGroups = InlineAIPanelModel.PromptGroups(title: templatePrompts.isEmpty ? "" : I18n.Calendar_G_AITemplates_Desc,
                                                                   prompts: templatePrompts)
        if !templatePrompts.isEmpty {
            promptGroups.append(templetePromptGroups)
        }

        let basicPrompts = genPromptsByGroup(groupType: .basic, text: text)
        let basicPromptGroups = InlineAIPanelModel.PromptGroups(title: basicPrompts.isEmpty ? "" : I18n.Calendar_G_AIBasics_Desc,
                                                                prompts: basicPrompts)
        if !basicPrompts.isEmpty {
            promptGroups.append(basicPromptGroups)
        }

        let prompts = InlineAIPanelModel.Prompts(show: !promptGroups.isEmpty,
                                                 overlap: false,
                                                 data: promptGroups)
        
        return prompts
    }
    
    
    func genPromptsByGroup(groupType: QuickActionGroupType, text: String = "") -> [InlineAIPanelModel.Prompt] {

        var promptGroup: [InlineAIPanelModel.Prompt] = []
        
        switch groupType {
        case .template:
            for item in quickActionList {
                if let prompt = praseSinglePromptUtil(item: item, groupType: .template, text: text) {
                    promptGroup.append(prompt)
                }
            }

        case .basic:
            for item in quickActionList {
                if let prompt = praseSinglePromptUtil(item: item, groupType: .basic, text: text) {
                    promptGroup.append(prompt)
                }
            }

        case .adjust:
            for item in quickActionList {
                if let prompt = praseSinglePromptUtil(item: item, groupType: .adjust, text: text) {
                    promptGroup.append(prompt)
                }
            }

        }
        return promptGroup
    }
    
    func praseSinglePromptUtil(item: Server.AIInlineQuickAction,
                               groupType: QuickActionGroupType,
                               text: String = "") -> InlineAIPanelModel.Prompt? {
        guard let extraMap = item.extraMap["Comment"]?.data(using: .utf8) else {
            self.logger.error("error transfer quickActionList extraMap")
            return nil
        }
        do {
            let dictValue = try JSONSerialization.jsonObject(with: extraMap, options: []) as? [String: String]
            if dictValue?["group"] == groupType.rawValue {
                if !item.name.contains(text) && !text.isEmpty { return nil }
                var paramList: [InlineAIPanelModel.ParamDetail] = []
                item.paramDetails.map { item in
                    if item.needConfirm {
                        let param = InlineAIPanelModel.ParamDetail(name: item.displayName, key: item.name, placeHolder: item.placeHolder)
                        paramList.append(param)
                    }
                }
                let data = try JSONEncoder().encode(paramList)
                let template = String(data: data, encoding: String.Encoding.utf8)
                let promptType: String = dictValue?["type"] ?? ""
                let quickCommandMark: String = dictValue?["quick_action_command"] ?? ""
                let icon: PromptIcon = InlineAIUtils.getPomptIcon(type: EventEditCopilotQuickActionType(rawValue: promptType) ?? .unknown)
                                                                  
                var prompt = InlineAIPanelModel.Prompt(id: item.id,
                                                 icon: icon.rawValue,
                                                 text: item.name,
                                                 type: quickCommandMark,
                                                 template: template,
                                                 originText: promptType,
                                                 params: item.params,
                                                 extras: groupType.rawValue)

                prompt.attributedString = .init(buildSearchAttributeString(name: item.name, keyword: text))
                return prompt
            }
        } catch {
            self.logger.error("error transfer quickActionList extraMap")
        }
        return nil
    }
    
    private func buildSearchAttributeString(name: String, keyword: String) -> NSMutableAttributedString {
        let normalAttr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                          NSAttributedString.Key.foregroundColor: UDColor.textTitle]

        let attrString = NSMutableAttributedString(string: name, attributes: normalAttr)
        if let range = name.range(of: keyword) {
            let location = name.distance(from: name.startIndex, to: range.lowerBound)
            attrString.addAttribute(.foregroundColor,
                                    value: UDColor.primaryPri500,
                                    range: NSRange(location: location ,
                                                   length: keyword.count))
        }

        return attrString
    }

    func genInlineAIPanelModelInput(show: Bool,
                                            status: Int,
                                            text: String,
                                            placeHolder: String,
                                            showKeyboard: Bool? = nil,
                                            writingText: String = "",
                                            showStopBtn: Bool = false,
                                            textContentList: InlineAIPanelModel.QuickAction? = nil) -> InlineAIPanelModel.Input {
        
        let input = InlineAIPanelModel.Input(show: show,
                                             status: status,
                                             text: text,
                                             placeholder: placeHolder,
                                             writingText: writingText,
                                             showStopBtn: showStopBtn,
                                             showKeyboard: showKeyboard,
                                             textContentList: textContentList)
        return input
    }
}
