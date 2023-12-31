//
//  ViewController.swift
//  LarkAIInfraDemo
//
//  Created by huayufan on 2023/4/25.
//  


import UIKit
@testable import LarkAIInfra
import UniverseDesignColor
import SnapKit
import LarkModel
import LarkContainer

class ViewController: UIViewController {
    var aiModule: LarkInlineAIUISDK?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        let entranceBtn = UIButton(type: .custom)
        entranceBtn.frame = CGRect(x: (self.view.frame.size.width - 100) / 2, y: (self.view.frame.size.height - 50) / 2, width: 140, height: 50)
        entranceBtn.setTitle("AI conversation", for: .normal)
        entranceBtn.setTitleColor(.blue, for: .normal)
        entranceBtn.addTarget(self, action: #selector(openAIPanenl), for: .touchUpInside)
        view.addSubview(entranceBtn)
        
    }

    @objc
    func openAIPanenl() {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = .orange
        textView.text = "With the emergence of ChatGPT, AIGC has entered a more extensive practical stage. In the field of documents, many peers at home and abroad have realized or are in the process of the combination of document creation and Al. Specifically, it can be seen that the analysis of AIGC products of this document is the direct comparison of the concept of flying book documents"

        
        let config = InlineAIConfig(userResolver: Container.shared.getCurrentUserResolver())
        aiModule = LarkInlineAIModuleGenerator.createUISDK(config: config, customView: nil, delegate: self)
        let model = constrcutPanelModel(showContent: false, showPanel: true, doubleConfirm: false)
        aiModule?.showPanel(panel: model)
    }
    
    func constrcutPanelModel(showContent: Bool, showPanel: Bool, doubleConfirm: Bool) -> InlineAIPanelModel {
        let dragBar = InlineAIPanelModel.DragBar(show: true, doubleConfirm: doubleConfirm)
        let tips = InlineAIPanelModel.Tips(show: false, text: "AI can be inaccurate or misleading")
        let feedBack = InlineAIPanelModel.Feedback(show: false, like: true, unlike: false)
        let history = InlineAIPanelModel.History(show: false, total: 8, curNum: 5, leftArrowEnabled: true, rightArrowEnabled: false)
        let ops = [InlineAIPanelModel.Operate(text: "replace", btnType: "primary"),
                   InlineAIPanelModel.Operate(text: "replace", btnType: "default"),
                   InlineAIPanelModel.Operate(text: "replace", btnType: "default"),
                   InlineAIPanelModel.Operate(text: "replace", btnType: "default"),
                   InlineAIPanelModel.Operate(text: "replace", btnType: "default"),
                   InlineAIPanelModel.Operate(text: "replace", btnType: "default")]
       let prompts = [InlineAIPanelModel.Prompt(id: "0", icon: "", text:"name"),
                     InlineAIPanelModel.Prompt(id: "1", icon: "", text: "name"),
                     InlineAIPanelModel.Prompt(id: "2", icon: "", text: "name"),
                     InlineAIPanelModel.Prompt(id: "3", icon: "", text: "name"),
                     InlineAIPanelModel.Prompt(id: "4", icon: "", text: "name"),
                      InlineAIPanelModel.Prompt(id: "9", icon: "", text: "name")]
        let groups = [InlineAIPanelModel.PromptGroups(title: "Basic Basic", prompts: prompts),
                     InlineAIPanelModel.PromptGroups(title: "Basic Basic", prompts: prompts)]
        let pm = InlineAIPanelModel.Prompts(show: true, overlap: false, data: groups)
        let operates = InlineAIPanelModel.Operates(show: false, data: ops)
        
        let imageData: [InlineAIPanelModel.ImageData] = [.init(url: "", id: "1"),
                                                         .init(url: "", id: "2"),
                                                         .init(url: "", id: "3"),
                                                         .init(url: "", id: "4")]
        let images = InlineAIPanelModel.Images(show: false, status: 0, data: imageData, checkList: [])
        let input = InlineAIPanelModel.Input(show: true, status: 0, text: "xxx<at type=\"22\" href=\"https://bytedance.larkoffice.com/docx/doxcnAQYYrxqeuaW9cuWDXNxQBf\" token=\"doxcnAQYYrxqeuaW9cuWDXNxQBf\">123 </at><at type=\"22\" href=\"https://bytedance.larkoffice.com/docx/doxcnAQYYrxqeuaW5cuWDXN0QBf\" token=\"doxcnAQYYrxqeuaW5cuWDXN0QBf\">456</at> 22：‌3333‌ ‌", placeholder: "AI Guide copy for the first time", writingText:"AI is writing...", showStopBtn: false, showKeyboard: false)
        let range = InlineAIPanelModel.SheetOperate(show: false, text: "12344", enable: true, suffixIcon: nil)
        let model =  InlineAIPanelModel(show: showPanel, dragBar: dragBar, content: showContent ? "With the emergence of ChatGPT, AIGC has entered a more extensive practical stage. In the field of documents, many peers at home and abroad have realized or are in the process of the combination of document creation and Al. Specifically, it can be seen that the analysis of AIGC products of this document is the direct comparison of the concept of flying book documents" : nil, images: images, prompts: pm, operates: operates, input: input, tips: tips, feedback: feedBack, history: history, range: range, conversationId: "", taskId: "")
        return model
    }
}

extension ViewController: LarkInlineAIUIDelegate {
    func onClickSheetOperation() {
        
    }
    
    func onClickFeedback(like: Bool, callback: ((LarkAIInfra.LarkInlineAIFeedbackConfig) -> Void)?) {
        
    }
    
    
    func imagesInsert(models: [InlineAICheckableModel]) {
        
    }

    func onClickImageCheckbox(imageData: LarkAIInfra.InlineAIPanelModel.ImageData, checked: Bool) {
        
    }

    func onClickSend(text: NSAttributedString) {
        
    }
    
    
    func onClickAtPicker(callback: @escaping (PickerItem?) -> Void) {
        
    }

    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? {
        return nil
    }
    
    func onClickSubPrompt(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) {
        
    }
    
    func onHeightChange(height: CGFloat) {
        
    }
    
    func panelDidDismiss() {
        
    }
    
    
    func onClickMaskArea(keyboardShow: Bool) {
        
    }
    
    func keyboardChange(show: Bool) {
        
    }
    
    func onSwipHidePanel(keyboardShow: Bool) {
        
    }
    
    func onClickHistory(pre: Bool) {
        
    }

    func onInputTextChange(text: String) {
        
    }
    
    func onClickPrompt(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) {
        let input = InlineAIPanelModel.Input(show: true, status: 1, text: "", placeholder: "AI Guide copy for the first time", writingText: "AI is writing...", showStopBtn: true, showKeyboard: false)
        let model = InlineAIPanelModel(show: true,
                           input: input,
                           conversationId: "",
                           taskId: "")
        
        aiModule?.showPanel(panel: model)
    }
    
    func onClickOperation(operate: LarkAIInfra.InlineAIPanelModel.Operate) {
        
    }
    
    func onClickHistory(direction: String) {
        
    }
    
    func onClickStop() {
        let model = constrcutPanelModel(showContent: false, showPanel: true, doubleConfirm: false)
        aiModule?.showPanel(panel: model)
    }
    
    func onClickFeedback(like: Bool) {

    }
    
    func getShowAIPanelViewController() -> UIViewController {
        return self
    }
}

