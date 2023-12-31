//
//  NewThreadKeyboardView.swift
//  LarkThread
//
//  Created by JackZhao on 2021/9/3.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import LarkModel
import LarkUIKit
import LarkCore
import LarkKeyboardView
import LarkMessengerInterface
import LarkMessageBase
import LarkFeatureGating
import LarkChatOpenKeyboard
import LarkBaseKeyboard

final class NewThreadKeyboardView: ThreadKeyboardView {

    fileprivate let disposeBag = DisposeBag()

    private var fontPanelSubModule: ThreadKeyboardFontSubModule? {
        let module = self.viewModel.module.getPanelSubModuleInstanceForModuleClass(ThreadKeyboardFontSubModule.self) as? ThreadKeyboardFontSubModule
        return module
    }

    init(chatWrapper: ChatPushWrapper,
         viewModel: IMKeyboardViewModel,
         pasteboardToken: String,
         keyboardNewStyleEnable: Bool) {
        let supportRealTimeTranslate = viewModel.module.context.getFeatureGating(.init(stringLiteral: "im.chat.manual_open_translate"))
        super.init(chatWrapper: chatWrapper,
                   viewModel: viewModel,
                   pasteboardToken: pasteboardToken,
                   keyboardNewStyleEnable: keyboardNewStyleEnable,
                   supportRealTimeTranslate: supportRealTimeTranslate)
        inputManager.addParagraphStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func inputTextViewDidChange(input: LKKeyboardView) {
        fontPanelSubModule?.onTextViewLengthChange(input.inputTextView.attributedText.length)
    }

    func updateKeyboardStatusIfNeed(_ item: ComposePostItem?) {
        if let item = item {
            self.updateTextViewData(item)
            fontPanelSubModule?.updateWithUIWithFontBarStatusItem(item.fontBarStatus)
        } else {
            self.becomeFirstResponder()
        }
    }

    private func updateTextViewData(_ item: ComposePostItem) {
        if let responderInfo = item.firstResponderInfo {
            if responderInfo.1 {
                inputTextView.becomeFirstResponder()
                inputTextView.selectedRange = NSRange(location: responderInfo.0.location, length: 0)
            }
        } else {
            inputTextView.becomeFirstResponder()
        }
    }

    override func trimCharacterSetForAttributedString() -> CharacterSet {
        return .whitespacesAndNewlines
    }

    override func updateKeyboardAttributedText(_ value: NSAttributedString) {
        /// 这里需要清空一下
        self.attributedString = NSAttributedString(string: "")
        threadKeyboardDelegate?.updateAttachmentSizeFor(attributedText: value)
        self.attributedString = value
    }

    override func updateUIForKeyboardJob(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        super.updateUIForKeyboardJob(oldJob: oldJob, currentJob: currentJob)
        let currentJob = keyboardStatusManager.currentKeyboardJob
        fontPanelSubModule?.updateFontBarSpaceStyle(currentJob.isFontBarCompactLayout ? .compact : .normal)
    }

    override func didApplyPasteboardInfo() {
        self.threadKeyboardDelegate?.didApplyPasteboardInfo()
    }
}
