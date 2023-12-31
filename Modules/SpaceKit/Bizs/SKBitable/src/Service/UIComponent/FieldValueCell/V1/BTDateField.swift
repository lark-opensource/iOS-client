// 
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
// 
// Description: 日期字段

import Foundation
import SKResource
import SKBrowser
import UniverseDesignColor
import UniverseDesignDatePicker
import UniverseDesignIcon
import UIKit

final class BTDateField: BTBaseField, BTFieldDateCellProtocol {
    
    lazy var contentTextView = BTTextView().construct { it in
        it.isEditable = false
        it.btDelegate = self
        it.font = UIFont.systemFont(ofSize: 14)
        it.textContainerInset = BTFieldLayout.Const.normalTextContainerInset
    }
    
    private func contentWithDateString(_ dateString: String, dateModel: BTDateModel?) -> NSAttributedString {
        let textColor = fieldModel.isPrimaryField ? UDColor.primaryPri900 : UDColor.textTitle
        let font = BTFieldLayout.Const.getFont(isPrimaryField: fieldModel.isPrimaryField)
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
    
    override func setupLayout() {
        super.setupLayout()
        containerView.addSubview(contentTextView)
        contentTextView.snp.makeConstraints { it in
            it.top.bottom.equalToSuperview()
            it.left.equalToSuperview()
            it.right.equalToSuperview()
        }
        
        containerView.addSubview(panelIndicator)
        panelIndicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-BTFieldLayout.Const.panelIndicatorRightMargin)
            make.width.height.equalTo(BTFieldLayout.Const.panelIndicatorWidthHeight)
        }
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        setupStyleInStage()
        debugPrint("BTDateField test loadModel \(model)")
        panelIndicator.isHidden = !model.editable
        let textColor = model.isPrimaryField ? UDColor.primaryPri900 : UDColor.textTitle
        let font = BTFieldLayout.Const.getFont(isPrimaryField: model.isPrimaryField)
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
        contentTextView.attributedText = mutableAttributedString
        if model.isPrimaryField {
            contentTextView.placeholderLabel.text = BundleI18n.SKResource.Bitable_Flow_RecordCard_Mobile_Date_Placeholder
            panelIndicator.isHidden = true
        }
    }
    
    func setupStyleInStage() {
        if fieldModel.isPrimaryField {
            contentTextView.textContainerInset = BTFieldLayout.Const.textContainerInsetInStageOfPrimaryField
            let font = BTFieldLayout.Const.primaryTextFieldFontInStage
            let placeHolderColor = UDColor.primaryPri900.withAlphaComponent(0.7)
            contentTextView.placeholderLabel.textColor = placeHolderColor
            contentTextView.placeholderLabel.font = font
            contentTextView.enablePlaceHolder(enable: true)
            contentTextView.showsVerticalScrollIndicator = true
        } else {
            contentTextView.textContainerInset = BTFieldLayout.Const.normalTextContainerInset
            contentTextView.enablePlaceHolder(enable: false)
        }
    }
    
    func getAttributes(textColor: UIColor, font: UIFont) -> [NSAttributedString.Key: Any] {
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
    
    
    func panelDidStartEditing() {
        updateBorderMode(.editing)
        delegate?.panelDidStartEditingField(self, scrollPosition: .bottom)
    }
    
    func stopEditing() {
        updateBorderMode(.normal)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    override func updateBorderMode(_ mode: BorderMode) {
        super.updateBorderMode(mode)
        panelIndicator.image = mode == .editing ? pickingIndicator : normalIndicator
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

extension BTDateField: BTTextViewDelegate {
    func btTextViewDidScroll(toBounce: Bool) {}
    
    func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {
        self.didTapDateCell()
    }
    
    func btTextView(_ textView: BTTextView, shouldApply action: BTTextViewMenuAction) -> Bool {
        return delegate?.textViewOfField(fieldModel, shouldAppyAction: action) ?? false
    }
}
