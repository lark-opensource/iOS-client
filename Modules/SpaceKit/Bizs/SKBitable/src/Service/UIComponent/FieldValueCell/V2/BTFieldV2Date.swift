//
//  BTFieldV2Date.swift
//  SKBitable
//
//  Created by zoujie on 2023/8/12.
//  

import Foundation
import SKResource
import SKBrowser
import UniverseDesignColor
import UniverseDesignDatePicker
import UniverseDesignIcon
import UIKit

struct BTFieldUIDataDate{
    private(set) var fieldModel: BTFieldModel
    
    init(fieldModel: BTFieldModel) {
        self.fieldModel = fieldModel
    }
    
    private func getAttributes(textColor: UIColor, font: UIFont) -> [NSAttributedString.Key: Any] {
        let textFont = font
        let lineHeight = textFont.figmaHeight
        let baselineOffset = (lineHeight - textFont.lineHeight) / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.lineBreakMode = .byWordWrapping
        return [
            .font: textFont,
            .foregroundColor: textColor,
            .baselineOffset: baselineOffset,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    private func contentWithDateString(_ dateString: String, dateModel: BTDateModel?) -> NSAttributedString {
        let textColor = fieldModel.isPrimaryField ? UDColor.primaryPri900 : UDColor.textTitle
        let font = BTFV2Const.Font.fieldValue
        let attributeString = NSMutableAttributedString()
        let haveReminder = dateModel?.reminder != nil
        let color = haveReminder ? UDColor.primaryContentDefault : textColor
        let dateAttributeString = NSAttributedString(string: dateString, attributes: getAttributes(textColor: color, font: font))
        attributeString.append(dateAttributeString)
        if haveReminder {
            let attachment = NSTextAttachment()
            attachment.image = UDIcon.alarmClockFilled.ud.withTintColor(color)
            attachment.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
            let iconAttributeString = NSAttributedString(attachment: attachment)
            attributeString.append(NSAttributedString(string: " "))
            attributeString.append(iconAttributeString)
        }
        
        return attributeString
    }
    
    func getDateFieldAttr() -> NSAttributedString {
        let textColor = UDColor.textTitle
        let font = BTFV2Const.Font.fieldValue
        var mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString = fieldModel.dateValue.reduce(mutableAttributedString, { (partialString, dateModel) -> NSMutableAttributedString in
            let dateString = BTUtil.dateFormate(dateModel.value,
                                                dateFormat: fieldModel.property.dateFormat,
                                                timeFormat: fieldModel.property.timeFormat,
                                                timeZoneId: fieldModel.timeZone,
                                                displayTimeZone: fieldModel.property.displayTimeZone)
            if !partialString.string.isEmpty {
               
                partialString.append(NSAttributedString(string: ",", attributes: getAttributes(textColor: textColor, font: font)))
            }
            partialString.append(contentWithDateString(dateString, dateModel: dateModel))
            return partialString
        })
        
        return mutableAttributedString
    }
}


final class BTFieldV2Date: BTFieldV2Base, BTFieldDateCellProtocol {
    
    lazy var contentTextView = BTTextView().construct { it in
        it.isEditable = false
        it.btDelegate = self
        it.font = BTFV2Const.Font.fieldValue
    }
    
    override func subviewsInit() {
        super.subviewsInit()
        containerView.addSubview(contentTextView)
        contentTextView.snp.makeConstraints { it in
            it.top.bottom.equalToSuperview()
            it.left.equalToSuperview()
            it.right.equalToSuperview()
        }
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)

        contentTextView.attributedText = BTFieldUIDataDate(fieldModel: model).getDateFieldAttr()
    }
    
    @objc
    override func onFieldEditBtnClick(_ sender: UIButton) {
        didTapDateCell()
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        didTapDateCell()
    }
    
    func panelDidStartEditing() {
        updateBorderMode(.editing)
        delegate?.panelDidStartEditingField(self, scrollPosition: .bottom)
    }
    
    func stopEditing() {
        updateBorderMode(.normal)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    @objc
    private func didTapDateCell() {
        debugPrint("BTDateField test didTapDateCell \(fieldModel)")
        if fieldModel.editable {
            delegate?.startEditing(inField: self, newEditAgent: nil)
        } else {
            showUneditableToast()
        }
    }
}

extension BTFieldV2Date: BTTextViewDelegate {
    func btTextViewDidScroll(toBounce: Bool) {}
    
    func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {
        self.didTapDateCell()
    }
    
    func btTextView(_ textView: BTTextView, shouldApply action: BTTextViewMenuAction) -> Bool {
        return delegate?.textViewOfField(fieldModel, shouldAppyAction: action) ?? false
    }
}
