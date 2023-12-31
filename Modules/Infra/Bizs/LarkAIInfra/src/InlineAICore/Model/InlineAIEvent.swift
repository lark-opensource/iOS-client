//
//  InlineAIEvent.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/4/26.
//  


import Foundation
import LarkKeyboardKit
import UIKit

enum InlineAIEvent {
    case updateModel(model: InlineAIPanelModel)
    case textViewDidChange(text: String)
    case textViewDidEndEditing
    case textViewDidBeginEditing
    case keyboardDidSend(RichTextContent)
    case keyboardEventChange(event: KeyboardEvent)
    case stopGenerating
    case chooseOperator(operate: InlineAIPanelModel.Operate)
    case chooseSheetOperation
    case choosePrompt(prompt: InlineAIPanelModel.Prompt)
    case clickMaskErea
    case closePanel
    case clickOverlapPromptMaskArea
    case clickPrePage
    case clickNextPage
    case clickThumbUp(isSelected: Bool)
    case clickThumbDown(isSelected: Bool)
    case clickAt(selectedRange: NSRange)
    case panGestureRecognizerChange(gestureRecognizer: UIPanGestureRecognizer)
    case panGestureRecognizerEnable(enabled: Bool)
    case getEncryptId(completion: (String?) -> Void)
    case textViewHeightChange
    case panelHeightChange(height: CGFloat)
    case clickCheckbox(InlineAICheckableModel)
    case clickAIImage(InlineAICheckableModel)
    case autoActiveKeyboard
    case vcDismissed
    case vcPresented
    case vcViewDidLoad
    case alertCancel
    case alertContinue
    case updateTheme
    case contentRenderEnd
    case deleteHistoryPrompt(prompt: InlineAIPanelModel.Prompt)
    case sendRecentPrompt(prompt: InlineAIPanelModel.Prompt)
    case openURL(String)
}
