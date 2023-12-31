//
//  MeetingNumberField.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/8/16.
//

import UIKit
import RxCocoa
import RxSwift

class MeetingNumberField: UnderlineTextField {

    private var groupWidth: [UInt] = [3]
    private var groupKern: CGFloat = 5.0
    private(set) var maxLength: UInt = 9

    var returnkeyAction: ((String?) -> Void)?
    var firstBeginEditingAction: (() -> Void)?
    var isFirstEdit: Bool = true

    var editingDidChange: ((String?) -> Void)?

    weak override var delegate: UITextFieldDelegate? {
        get {
            super.delegate
        }
        set {
            guard let value = newValue,
                  value.isMember(of: MeetingNumberField.self) else {
                assertionFailure("delegate has been implemented")
                return
            }
            super.delegate = newValue
        }
    }

    init(groupWidth: [UInt],
         groupKern: CGFloat,
         maxLength: UInt) {
        self.groupWidth = groupWidth
        self.groupKern = groupKern
        self.maxLength = maxLength
        super.init(frame: CGRect.zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.addTarget(self, action: #selector(handleTextChanged(sender:)), for: .editingChanged)
        keyboardType = .asciiCapableNumberPad
        self.delegate = self
        updateIntrinsicSize()
    }

    @objc func handleTextChanged(sender: UITextField) {
        guard let text = self.text else {
            return
        }
        let selectedRange = selectedTextRange
        self.attributedText = convert(text: text)
        self.selectedTextRange = selectedRange
        editingDidChange?(text)
    }

    func setText(_ text: String) {
        let replace = text.trimmingCharacters(in: .whitespaces)
        let pattern = "[0-9]{1,9}"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matchStrings = regex?.matches(replace)

        var numberString = ""
        for number in matchStrings ?? [] {
            numberString.append(number)
        }

        if numberString.count > maxLength {
            numberString = String(numberString.prefix(Int(maxLength)))
        }
        if !numberString.isEmpty {
            attributedText = convert(text: numberString)
            editingDidChange?(attributedText?.string)
        }
    }

    private func convert(text: String) -> NSAttributedString {
        let attriStr = NSMutableAttributedString()
        let lastOffset = text.count - 1
        var previousOffset: Int = 0
        var groupIndex: Int = 0
        var currentWidth: UInt = groupWidth[groupIndex]

        for entry in text.enumerated() {
            if (entry.offset - previousOffset) % Int(currentWidth) == currentWidth - 1 && entry.offset != lastOffset {
                attriStr.append(NSAttributedString(string: String(entry.element), attributes: [
                    NSAttributedString.Key.kern: groupKern
                    ]))
                groupIndex += 1
                previousOffset = entry.offset + 1
                if groupIndex < groupWidth.count {
                    currentWidth = groupWidth[groupIndex]
                }
            } else {
                attriStr.append(NSAttributedString(string: String(entry.element)))
            }
        }

        return attriStr
    }

    private var _intrinsicSize: CGSize = .zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    private func updateIntrinsicSize() {
        guard let template = self.convert(text: String(repeating: "0", count: Int(maxLength))).mutableCopy() as? NSMutableAttributedString else {
            return
        }
        if let font = self.font {
            template.addAttributes([NSAttributedString.Key.font: font],
                                   range: NSRange(location: 0, length: template.length))
        }
        let rect = template.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                      height: CGFloat.greatestFiniteMagnitude),
                                         options: [],
                                         context: nil)
            .integral
        _intrinsicSize = rect.size
    }

    override var intrinsicContentSize: CGSize {
        return _intrinsicSize
    }

    override var font: UIFont? {
        didSet {
            self.updateIntrinsicSize()
        }
    }
}

extension MeetingNumberField {
    var selectedRange: NSRange {
        get {
            guard let range = self.selectedTextRange else { return NSRange(location: 0, length: 0) }
            let location = offset(from: beginningOfDocument, to: range.start)
            let length = offset(from: range.start, to: range.end)
            return NSRange(location: location, length: length)
        }
        set {
            guard let startPosition = position(from: beginningOfDocument, offset: newValue.location),
                let endPosition = position(from: beginningOfDocument, offset: newValue.location + newValue.length) else {
                    return
            }
            let selectionRange = textRange(from: startPosition, to: endPosition)
            self.selectedTextRange = selectionRange
        }
    }
}

extension MeetingNumberField: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        previewDelegate?.textFieldWillBeginEditing(textField)
        return true
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
        ) -> Bool {
        var text = textField.text ?? ""
        if string == "\n" {
            textField.resignFirstResponder()
        }
        guard let strRange = Range<String.Index>(range, in: text) else {
            return false
        }

        if string.count <= 1 {
            text.replaceSubrange(strRange, with: string)
            return text.count <= maxLength && text.allSatisfy { $0.isNumber && $0.isASCII }
        } else {
            var targetString = text
            let replace = string.trimmingCharacters(in: .whitespaces)
            let pattern = "(\\d{3}\\s*){3}"
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            var numberString = regex?.matches(replace).first ?? ""
            numberString = numberString.filter { !$0.isWhitespace }
            targetString.replaceSubrange(strRange, with: numberString)

            if string.count > maxLength {
                targetString = String(targetString.prefix(Int(maxLength)))
            }
            if !targetString.isEmpty {
                attributedText = convert(text: targetString)
                editingDidChange?(attributedText?.string)
                var location = range.location + numberString.count
                location = location > Int(maxLength) ? Int(maxLength) : location
                DispatchQueue.main.async {
                    self.selectedRange = NSRange(location: location, length: 0)
                    self.placeHolderLabel.isHidden = true
                }
            }
            return false
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.returnkeyAction?(textField.text)
        return textField.resignFirstResponder()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        trackClosure?()
        guard isFirstEdit else { return }
        isFirstEdit = false
        firstBeginEditingAction?()
    }
}

extension Reactive where Base == MeetingNumberField {
    var underlineColor: Binder<UIColor> {
        return Binder<UIColor>(self.base) { field, value in
            field.underlineColor = value
        }
    }
}
