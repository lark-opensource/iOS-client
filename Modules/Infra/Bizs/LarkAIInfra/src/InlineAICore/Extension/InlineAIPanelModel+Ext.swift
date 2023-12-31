//
//  InlineAIPanelModel+Ext.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/5/18.
//  


import Foundation
import UniverseDesignColor
import UniverseDesignTheme

protocol AIPanelDisplayType {
    var canDisplay: Bool { get }
    var uiType: UIType { get }
}

extension InlineAIPanelModel: CustomStringConvertible {
    public var description: String {
        let contentShow = content?.isEmpty == false
        return "show:\(show) dragBar:\(dragBar) contentShow:\(contentShow) \(images) prompts:\(prompts) operates:\(operates) input:\(input) tips:\(tips) feedback:\(feedback) history:\(history) theme:\(theme) maskType:\(maskType) cId:\(conversationId) tId:\(taskId)"
    }
}

extension InlineAIPanelModel.Images: Equatable, AIPanelDisplayType, CustomStringConvertible {

    public static func == (lhs: InlineAIPanelModel.Images, rhs: InlineAIPanelModel.Images) -> Bool {
        return lhs.show == rhs.show && lhs.status == rhs.status && lhs.data == rhs.data
    }
    var canDisplay: Bool {
        return show
    }
    var uiType: UIType { .images }
    public var description: String {
        return "images: show:\(self.show) count:\(data ?? []) status:\(status)"
    }
    
    mutating func removeIdFromCheckList(id: String) {
        self.checkList.removeAll { $0 == id }
    }
    
    mutating func addIdToCheckList(id: String) {
        guard !checkList.contains(id) else {
            LarkInlineAILogger.error("image id has added")
            return
        }
        self.checkList.append(id)
    }
}

extension InlineAIPanelModel.ImageData: Equatable, CustomStringConvertible {
    public static func == (lhs: InlineAIPanelModel.ImageData, rhs: InlineAIPanelModel.ImageData) -> Bool {
        return lhs.url == rhs.url
    }
    public var description: String {
        return "\(url.md5())"
    }
}

extension InlineAIPanelModel.Tips: Equatable, AIPanelDisplayType, CustomStringConvertible {

    public static func == (lhs: InlineAIPanelModel.Tips, rhs: InlineAIPanelModel.Tips) -> Bool {
        return lhs.show == rhs.show && lhs.text == rhs.text
    }
    var canDisplay: Bool { return show  }
    var uiType: UIType { .tips }
    public var description: String {
        return "tips: show:\(self.show)"
    }
}


extension InlineAIPanelModel.DragBar: Equatable, AIPanelDisplayType, CustomStringConvertible  {

    public static func == (lhs: InlineAIPanelModel.DragBar, rhs: InlineAIPanelModel.DragBar) -> Bool {
        return lhs.show == rhs.show && lhs.doubleConfirm == rhs.doubleConfirm
    }
    var canDisplay: Bool { return show  }
    var uiType: UIType { .dragBar }
    public var description: String {
        return "dragBar: show:\(self.show) doubleConfirm:\(self.doubleConfirm)"
    }
}

extension InlineAIPanelModel.Prompts: Equatable, AIPanelDisplayType, CustomStringConvertible {

    public static func == (lhs: InlineAIPanelModel.Prompts, rhs: InlineAIPanelModel.Prompts) -> Bool {
        return lhs.show == rhs.show &&
               lhs.overlap == rhs.overlap &&
               lhs.data == rhs.data
    }

    var canDisplay: Bool {
        return show && !data.isEmpty && !overlap
    }
    var uiType: UIType { .prompt }
    public var description: String {
        return "prompts: show:\(self.show) overlap:\(self.overlap) group: \(self.data)"
    }
}

extension InlineAIPanelModel.PromptGroups: Equatable, CustomStringConvertible {

    public static func == (lhs: InlineAIPanelModel.PromptGroups, rhs: InlineAIPanelModel.PromptGroups) -> Bool {
        return lhs.title == rhs.title &&
               lhs.prompts == rhs.prompts
    }
    public var description: String {
        return "prompts: [\(self.prompts.count)]"
    }
}

extension InlineAIPanelModel.Prompt: Equatable {

    public static func == (lhs: InlineAIPanelModel.Prompt, rhs: InlineAIPanelModel.Prompt) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.icon == rhs.icon &&
               lhs.rightArrow == rhs.rightArrow &&
               lhs.type == rhs.type &&
               lhs.template == rhs.template
    }
}

extension InlineAIPanelModel.Feedback: Equatable, AIPanelDisplayType, CustomStringConvertible  {

    public static func == (lhs: InlineAIPanelModel.Feedback, rhs: InlineAIPanelModel.Feedback) -> Bool {
        return lhs.show == rhs.show &&
               lhs.like == rhs.like &&
               lhs.unlike == rhs.unlike &&
               lhs.position == rhs.position
    }
    var canDisplay: Bool { show }
    var uiType: UIType { .feedback }
    public var description: String {
        return "feedback: show:\(self.show) position:\(String(describing: position))"
    }
}

extension InlineAIPanelModel.History: Equatable, AIPanelDisplayType, CustomStringConvertible {

    public static func == (lhs: InlineAIPanelModel.History, rhs: InlineAIPanelModel.History) -> Bool {
        return lhs.show == rhs.show &&
               lhs.total == rhs.total &&
               lhs.curNum == rhs.curNum &&
               lhs.leftArrowEnabled == rhs.leftArrowEnabled &&
               lhs.rightArrowEnabled == rhs.rightArrowEnabled
    }
    var canDisplay: Bool { show }
    var uiType: UIType { .history }
    public var description: String {
        return "history: show:\(self.show)"
    }
}


extension InlineAIPanelModel.Input: Equatable, AIPanelDisplayType, CustomStringConvertible {

    public static func == (lhs: InlineAIPanelModel.Input, rhs: InlineAIPanelModel.Input) -> Bool {
        return lhs.show == rhs.show &&
               lhs.status == rhs.status &&
               lhs.text == rhs.text &&
               lhs.placeholder == rhs.placeholder &&
               lhs.writingText == rhs.writingText &&
               lhs.showStopBtn == rhs.showStopBtn &&
               lhs.showKeyboard == rhs.showKeyboard
    }
    var canDisplay: Bool { show }
    var uiType: UIType { .input }
    public var description: String {
        #if DEBUG
        return "input: show:\(show) status:\(status) stopBtn:\(showStopBtn) keyboard:\(showKeyboard) text:\(text.count) placeholder:\(placeholder) wText:\(writingText) pSelected:\(placehoderSelected)"
        #else
        return "input: show:\(show) status:\(status) showStopBtn:\(showStopBtn) showKeyboard:\(showKeyboard) tLen:\(text.count) pLen:\(placeholder.count) wLen:\(writingText.count) pSelected\(placehoderSelected)"
        #endif
    }
}

extension InlineAIPanelModel.Operates: Equatable, AIPanelDisplayType, CustomStringConvertible {

    public static func == (lhs: InlineAIPanelModel.Operates, rhs: InlineAIPanelModel.Operates) -> Bool {
        return lhs.show == rhs.show &&
               lhs.data == rhs.data
    }
    var canDisplay: Bool {
        return show && !data.isEmpty
    }
    var uiType: UIType { .operate }
    public var description: String {
        return "operate: show:\(show) count:\(data.count)"
    }
}

extension InlineAIPanelModel.Operate: Equatable {

    public static func == (lhs: InlineAIPanelModel.Operate, rhs: InlineAIPanelModel.Operate) -> Bool {
        return lhs.type == rhs.type &&
               lhs.text == rhs.text &&
               lhs.btnType == rhs.btnType &&
               lhs.template == rhs.template
    }
}


extension InlineAIPanelModel {
    var allDisplayModels: [AIPanelDisplayType] {
        var models: [AIPanelDisplayType] = []
        if let dragBar = self.dragBar {
            models.append(dragBar)
        }
        if let prompts = self.prompts {
            models.append(prompts)
        }
        if let operates = self.operates {
            models.append(operates)
        }
        if let input = self.input {
            models.append(input)
        }
        if let tips = self.tips {
            models.append(tips)
        }
        if let feedback = self.feedback {
            models.append(feedback)
        }
        if let history = self.history {
            models.append(history)
        }
        return models
    }
}

extension InlineAIPanelModel {
    // 当前主题
    public static func getCurrentTheme() -> String {
        guard #available(iOS 13.0, *) else {
            return "light"
        }
        let currntTheme = UDThemeManager.getRealUserInterfaceStyle()
        if currntTheme == .dark {
            return "dark"
        }
        return "light"
    }
}

struct ModelDescription {
    var visiableViews: Set<UIType>
    var changes: Set<UIType>

    init(visiableViews: Set<UIType>, changes: Set<UIType>) {
        self.visiableViews = visiableViews
        self.changes = changes
    }
    
    var isInSearchingPromptsView: Bool {
        let dst: [UIType] = [.dragBar, .prompt, .input]
        if visiableViews.count == dst.count {
            for type in dst {
                if !visiableViews.contains(type) {
                    return false
                }
            }
            return true
        } else {
            return false
        }
    }

    var contentChange: Bool {
        return changes.contains(.content)
    }
    
    var imagesChange: Bool {
        return changes.contains(.images)
    }
}


// MARK: - 数据层模型结构

extension Array where Element == OperateButton {
    
    func toAIOperateModels() -> [InlineAIPanelModel.Operate] {
        var result: [InlineAIPanelModel.Operate] = []
        for (idx, model) in self.enumerated() {
            let isPrimary = model.isPrimary
            result.append(InlineAIPanelModel.Operate(text: model.text, type: model.key, btnType: isPrimary ? "primary" : "default", disabled: false))
        }
        return result
    }
}


extension Array where Element == AIPromptGroup {
    
    func toInlineAIPromptGroups() -> [InlineAIPanelModel.PromptGroups] {
        return self.map {
            let prompts = $0.prompts.map {
                $0.toInternalPrompt()
            }
            return InlineAIPanelModel.PromptGroups(title: $0.title, prompts: prompts)
        }
    }
}

extension AIPrompt {
    func toInternalPrompt() -> InlineAIPanelModel.Prompt {
        let normalAttr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                          NSAttributedString.Key.foregroundColor: UDColor.textTitle]
        let attrString = NSMutableAttributedString(string: self.text, attributes: normalAttr)
        return InlineAIPanelModel.Prompt(id: "\(self.id ?? "")",
                                         localId: self.localId,
                                         icon: self.icon,
                                         text: self.text,
                                         rightArrow: !self.children.isEmpty,
                                         type: self.type,
                                         attributedString: .init(attrString))
    }
}

extension PromptTemplates {
    
    func toQuickAction() -> InlineAIPanelModel.QuickAction {
        let paramDetails = self.templateList.map {
            var detail = InlineAIPanelModel.ParamDetail(name: $0.templateName, key: $0.key, placeHolder: $0.placeHolder, content: $0.defaultUserInput)
            detail.updateComponents([.plainText($0.defaultUserInput ?? "")])
            return detail
        }
        return InlineAIPanelModel.QuickAction(displayName: templatePrefix, paramDetails: paramDetails)
    }
}

