//
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
//
// Description:

import SKUIKit
import Foundation
import SKBrowser
import UniverseDesignColor
import UniverseDesignToast
import SKResource

struct BTFieldUIDataNumber: BTFieldUIData {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.draftValue == rhs.draftValue
    }
    
    private(set) var attributedText = NSAttributedString()
    
    var draftValue: String? {
        didSet {
            updateAttributedText()
        }
    }
    
    init(numbers: [BTNumberModel] = [], draftValue: String? = nil) {
        self.numbers = numbers
        self.draftValue = draftValue
        
        updateAttributedText()
    }
    
    // MARK: - private
    
    private let numbers: [BTNumberModel]
    
    private mutating func updateAttributedText() {
        let content: String
        if let draftValue = draftValue {
            content = draftValue
        } else {
            content = numbers.map(\.formattedValue).reduce("", { (partialResult, newStr) -> String in
                if partialResult.isEmpty {
                    return "\(newStr)"
                } else {
                    return "\(partialResult),\(newStr)"
                }
            })
        }
        let attrs = BTFV2Const.TextAttributes.fieldValue
        let attrText = NSAttributedString(string: content, attributes: attrs)
        attributedText = attrText
    }
}


final class BTFieldV2Number: BTFieldV2BaseText, BTFieldNumberCellProtocol {

    var numbers: [Double] = []

    var strings: [String] = []

    var numberEditAgent: BTNumberEditAgent?
    
    var commonTrackParams: [String: Any]? {
        didSet {
            if let kbView = textView.inputView as? BTNumberKeyboardView {
                kbView.commonTrackParams = commonTrackParams
            }
        }
    }
    
    override func subviewsInit() {
        super.subviewsInit()
    }

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        textView.editPermission = model.editable
        textView.isScrollEnabled = false
        reloadData()
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        guard fieldModel.editable else {
            showUneditableToast()
            return
        }
        if textView.canBecomeFirstResponder {
            textView.becomeFirstResponder()
        }
    }
    
    override func handleKeyboardShow(options: Keyboard.KeyboardOptions) {
        switch options.event {
        case .willShow, .didShow:
            //滚动字段到可视区，避免被键盘遮挡
            numberEditAgent?.scrollTillFieldVisible()
        default: break
        }
    }

    func reloadData() {
        numbers = fieldModel.numberValue.map(\.rawValue)
        strings = fieldModel.numberValue.map(\.formattedValue)
        if fieldModel.editable {
            let kbView = BTNumberKeyboardView(target: textView)
            kbView.commonTrackParams = commonTrackParams
            textView.inputView = kbView
        } else {
            textView.inputView = nil
        }
        textView.attributedText = fieldModel.numberUIData.attributedText

        textView.showsVerticalScrollIndicator = true
        let newEditAgent = BTNumberEditAgent(fieldID: fieldID, recordID: fieldModel.recordID)
        newEditAgent.syncErrorHandle = { [weak self] message in
            guard let self = self else { return }
            UDToast.showFailure(with: message, on: self.window ?? self)
        }
        numberEditAgent = newEditAgent
    }

    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        resetTypingAttributes()
        return fieldModel.editable
    }

    override func textViewDidBeginEditing(_ textView: UITextView) {
        fieldModel.update(isEditing: true)
        let stringFormatter = NumberFormatter()
        stringFormatter.maximumFractionDigits = 310
        stringFormatter.maximumIntegerDigits = 310
        if let number = numbers.first,
            let txt = stringFormatter.string(from: NSNumber(value: number)),
            let currentAttrText = textView.attributedText {
            textView.textStorage.replaceCharacters(in: NSRange(location: 0, length: currentAttrText.length),
                                                   with: txt)
        }
        super.textViewDidBeginEditing(textView)
        if let numberEditAgent = numberEditAgent {
            delegate?.startEditing(inField: self, newEditAgent: numberEditAgent)
        }
    }
    
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            return numberEditAgent?.finishEdit() ?? false
        }
        resetTypingAttributes()
        return super.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }

    override func textViewDidChange(_ textView: UITextView) {
        numberEditAgent?.userDidModifyText()
    }

    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        numberEditAgent?.didEndEditingNumber()
        fieldModel.update(isEditing: false)
    }

    override func stopEditing() {
        let _ = textView.resignFirstResponder()
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
}
