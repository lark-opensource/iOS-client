//
//  InlineAIManager+InlineAIUI.swift
//  Calendar
//
//  Created by pluto on 2023/10/16.
//

import Foundation
import LarkAIInfra
import UniverseDesignDialog

extension InlineAIViewController: LarkInlineAIUIDelegate {
    func getShowAIPanelViewController() -> UIViewController {
        return self.delegate?.getShowPanelViewController() ?? UIViewController()
    }
    
    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? {
        return nil
    }

    // 点击键盘的发送按键（有快捷指令 or mention url功能）
    func onClickSend(content: RichTextContent) {
        viewModel.promptClickSendHandler(content: content)
    }
    
    func onClickPrompt(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) {
        viewModel.promptClickHandler(prompt: prompt)
    }
    
    func onClickSubPrompt(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) {
        viewModel.adjustPromptClickHandler(prompt: prompt)
    }
    
    func onClickOperation(operate: LarkAIInfra.InlineAIPanelModel.Operate) {
        viewModel.operationClickHandler(operate: operate)
    }
    
    func onClickStop() {
        viewModel.stopTaskClickHandler()
    }
    
    func onClickFeedback(like: Bool, callback: ((LarkAIInfra.LarkInlineAIFeedbackConfig) -> Void)?) {
        viewModel.feedBackClickHandler(like: like, callback: callback)
    }
    
    func onClickHistory(pre: Bool) {
        viewModel.changeHistory(pre: pre)
    }
    
    func onClickMaskArea(keyboardShow: Bool) {
        switch viewModel.aiTaskStatus {
        case .processing:
            let alertVC = UDDialog(config: UDDialogUIConfig(style: .vertical))
            alertVC.setTitle(text: I18n.Calendar_G_ConfirmWantToExit_Title)
            alertVC.setContent(text: I18n.Calendar_G_ConfirmWantToExit_Desc(AiNickname: viewModel.getMyAINickName()))
            alertVC.addPrimaryButton(text: I18n.Calendar_G_ContinueGenerating_Button, dismissCompletion:  { [weak self] in
                self?.dismiss(animated: true)
            })
            
            alertVC.addSecondaryButton(text: I18n.Calendar_Common_Exit, dismissCompletion:  { [weak self] in
                self?.viewModel.workingOnQuit()
            })
            present(alertVC, animated: true, completion: nil)
            
        case .initial:
            viewModel.hideInlinePanel()
        case .finish:
            viewModel.confirmActionHandler()
        default: break
        }
    }
    
    func onInputTextChange(text: String) {
        viewModel.transferToInitalSearch(text: text)
    }

    /// 以下代理Calendar目前无需使用，暂不实现
    func panelDidDismiss() {}

    func onClickSheetOperation() {}

    func keyboardChange(show: Bool) {}
    
    func onSwipHidePanel(keyboardShow: Bool) {}
    
    func onHeightChange(height: CGFloat) {}
}
