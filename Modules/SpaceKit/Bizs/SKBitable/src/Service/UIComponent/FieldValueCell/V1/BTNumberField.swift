// 
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import SKBrowser
import UniverseDesignColor
import UniverseDesignToast
import SKResource

final class BTNumberField: BTBaseTextField, BTFieldNumberCellProtocol {

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

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        textView.editPermission = model.editable
        textView.isScrollEnabled = false
        reloadData()
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
        let concatenatedString = strings.reduce("", { (partialResult, newStr) -> String in
            if partialResult.isEmpty {
                return "\(newStr)"
            } else {
                return "\(partialResult),\(newStr)"
            }
        })
        setupStyleInStage()
        let textColor = fieldModel.isPrimaryField ? UDColor.primaryPri900 : UDColor.textTitle
        let font = BTFieldLayout.Const.getFont(isPrimaryField: fieldModel.isPrimaryField)
        var attrs = BTUtil.getFigmaHeightAttributes(font: font, alignment: .left)
        attrs[.foregroundColor] = textColor
        let attrText = NSAttributedString(string: concatenatedString, attributes: attrs)
        textView.attributedText = attrText
        if fieldModel.isPrimaryField {
            textView.placeholderLabel.text = BundleI18n.SKResource.Bitable_Flow_RecordCard_Mobile_EnterHere_Placeholder
            textView.enablePlaceHolder(enable: true)
            textView.showsVerticalScrollIndicator = true
        }
        let newEditAgent = BTNumberEditAgent(fieldID: fieldID, recordID: fieldModel.recordID)
        newEditAgent.syncErrorHandle = { [weak self] message in
            guard let self = self else { return }
            UDToast.showFailure(with: message, on: self.window ?? self)
        }
        numberEditAgent = newEditAgent
    }

    override func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {
        super.btTextView(textView, didSigleTapped: sender)
    }

    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        setupCustomTypingAttributtes()
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
        setupCustomTypingAttributtes()
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
        textView.resignFirstResponder()
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
}
