//
//  BTFormTitleCell.swift
//  SKBitable
//
//  Created by zhouyuan on 2021/8/3.
//

import Foundation
import UIKit
import SnapKit
import SKResource
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor

final class BTFormTitleCell: UICollectionViewCell, BTReadOnlyTextViewDelegate, BTDescriptionViewDelegate, BTFieldModelLoadable {

    weak var delegate: BTFieldDelegate?

    var fieldModel = BTFieldModel(recordID: "")

    private lazy var titleView = BTReadOnlyTextView(frame: .zero, textContainer: nil)

    private lazy var descriptionView = BTDescriptionView(limitButtonFont: BTFieldLayout.Const.formDescriptionFont,
                                                         textViewDelegate: self,
                                                         limitButtonDelegate: self)

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(BTFieldLayout.Const.formTitleTopPadding)
            make.left.right.equalToSuperview().inset(BTFieldLayout.Const.containerLeftRightMargin)
        }

        contentView.addSubview(descriptionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        fieldModel = model
        var attributes = BTUtil.getFigmaHeightAttributes(font: BTFieldLayout.Const.formTitleFont, alignment: .center)
        attributes[.foregroundColor] = UDColor.textTitle
        titleView.attributedText = NSAttributedString(string: model.name, attributes: attributes)

        if let descriptionAttrText = formDescriptionAttrString(for: model),
           let descriptionHeight = layout.descriptionHeights[model.fieldID] {
            descriptionView.isHidden = false
            descriptionView.snp.remakeConstraints { make in
                make.top.equalTo(titleView.snp.bottom).offset(BTFieldLayout.Const.formTitleDescSpacing)
                make.left.right.equalToSuperview().inset(BTFieldLayout.Const.containerLeftRightMargin)
                make.height.equalTo(descriptionHeight)
            }
            layoutIfNeeded()
            descriptionView.setDescriptionText(descriptionAttrText, showingHeight: descriptionHeight)
        } else {
            descriptionView.isHidden = true
        }
    }

    private func formDescriptionAttrString(for model: BTFieldModel) -> NSAttributedString? {
        if let descriptionSegments = model.description?.content, !descriptionSegments.isEmpty {
            return BTUtil.convert(descriptionSegments, font: BTFieldLayout.Const.formDescriptionFont)
        }
        return nil
    }

    func readOnlyTextView(_ descriptionTextView: BTReadOnlyTextView, handleTapFromSender sender: UITapGestureRecognizer) {
        let attributes = BTUtil.getAttributes(in: descriptionTextView, sender: sender)
        if !attributes.isEmpty {
            delegate?.didTapView(withAttributes: attributes, inFieldModel: nil)
        }
    }

    func toggleLimitMode(to newMode: Bool) {
        delegate?.changeDescriptionLimitMode(forFieldID: BTFieldExtendedType.formTitle.mockFieldID,
                                             toLimited: newMode)
    }
}
