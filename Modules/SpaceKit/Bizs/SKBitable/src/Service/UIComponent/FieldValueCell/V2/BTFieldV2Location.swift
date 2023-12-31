//
//  BTLocationField.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/4/19.
//

import UIKit
import Foundation
import SKCommon
import SKBrowser
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignLoading

extension BTFieldModel {
    var locationAttributeText: NSAttributedString {
        let str = geoLocationValue.first?.fullAddress ?? ""
        let font = BTFV2Const.Font.fieldValue
        var attrs = BTUtil.getFigmaHeightAttributes(font: font, alignment: .left)
        attrs[.foregroundColor] = BTFV2Const.Color.fieldValueText
        return NSAttributedString(string: str, attributes: attrs)
    }
}

final class BTFieldV2Location: BTFieldV2BaseText, BTFieldLocationCellProtocol {

    var isClickDeleteMenuItem = false
    private var rightInsetOfTextView: CGFloat = 0
    
    override func subviewsInit() {
        super.subviewsInit()
        
        textView.isEditable = false
        textView.isSelectable = false
        self.isShowCustomMenuViewWhenLongPress = true
        textView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        
        textView.attributedText = model.locationAttributeText
    }
    
    override func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {
        if (fieldModel.geoLocationValue.first?.isEmpty ?? true) && !fieldModel.editable {
            showUneditableToast()
        }
        clickTextView()
    }

    override func stopEditing() {
        fieldModel.update(isEditing: false)
        updateBorderMode(.normal)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    @objc
    override func onFieldEditBtnClick(_ sender: UIButton) {
        onAssistButtonTap(sender)
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        if (fieldModel.geoLocationValue.first?.isEmpty ?? true) && !fieldModel.editable {
            showUneditableToast()
        }
        clickTextView()
    }
    
    @objc
    private func onAssistButtonTap(_ sender: UIButton) {
        guard fieldModel.editable else {
            showUneditableToast()
            return
        }
        fieldModel.update(isEditing: true)
        delegate?.startEditing(inField: self, newEditAgent: nil)
        switch fieldModel.editType {
        case .none, .dashLine, .placeholder:
            break
        case .fixedTopRightRoundedButton, .emptyRoundDashButton:
            trackOnClick(clickType: "edit")
        case .centerVerticallyWithIconText:
            trackOnClick(clickType: "blank")
        }
    }
    
    
    @objc
    override func clearContent() {
        if fieldModel.editable {
            isClickDeleteMenuItem = true
            delegate?.startEditing(inField: self, newEditAgent: nil)
        }
    }
    @objc
    private func clickTextView() {
        guard LKFeatureGating.bitableGeoLocationFieldEnable else {
            return
        }
        guard let geoLocation = fieldModel.geoLocationValue.first, !geoLocation.isEmpty else {
            return
        }
        delegate?.didClickOpenLocation(inField: self)
    }
    
    private func trackOnClick(clickType: String) {
        var params = [
            "target": "none",
            "input_type": fieldModel.property.inputType.trackText
        ]
        params["click"] = clickType
        delegate?.track(event: DocsTracker.EventType.bitableGeoCardClick.rawValue, params: params)
    }
}
