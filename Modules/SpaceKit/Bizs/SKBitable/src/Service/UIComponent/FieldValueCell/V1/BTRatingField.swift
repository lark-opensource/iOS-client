//
//  BTRatingField.swift
//  SKBitable
//
//  Created by yinyuan on 2023/2/17.
//

import Foundation
import SKBrowser
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import SKCommon
import LarkTag
import SKFoundation
import SKResource

final class BTRatingField: BTBaseField, BTFieldRatingCellProtocol {
    
    private var ratingCollectionView: BTRatingCollectionView = BTRatingCollectionView()
    private var tapGesture: UITapGestureRecognizer?
    private var editAgent: BTRatingEditAgent?
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        let oldModle = fieldModel
        super.loadModel(model, layout: layout)
        if model.isInForm {
            ratingCollectionView.ratingDelegate = self    // 仅用于表单场景
            if model.editable != oldModle.editable {
                // 需要刷新布局
                ratingCollectionView.snp.remakeConstraints { make in
                    make.left.equalToSuperview().inset(model.editable ? 0 : BTFieldLayout.Const.containerPadding)
                    make.top.bottom.equalToSuperview().inset(model.editable ? 0 : BTFieldLayout.Const.containerPadding)
                    make.right.equalToSuperview().inset(model.editable ? 0 : BTFieldLayout.Const.containerPadding)
                }
                layoutIfNeeded()
            }
            panelIndicator.isHidden = true
            if model.editable {
                unbindTapGesture()
            } else {
                bindTapGesture()
            }
            
        } else {
            ratingCollectionView.ratingDelegate = nil
            panelIndicator.isHidden = !fieldModel.editable
            bindTapGesture()
        }
        ratingCollectionView.fieldModel = fieldModel
    }
    
    private func unbindTapGesture() {
        if let targetTapGesture = tapGesture {
            containerView.removeGestureRecognizer(targetTapGesture)
            tapGesture = nil
        }
    }
    
    private func bindTapGesture() {
        if tapGesture == nil {
            let targetTapGesture = UITapGestureRecognizer(target: self, action: #selector(ratingBarClick))
            containerView.addGestureRecognizer(targetTapGesture)
            tapGesture = targetTapGesture
        }
    }
    
    override func setupLayout() {
        super.setupLayout()
        
        containerView.addSubview(panelIndicator)
        panelIndicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-BTFieldLayout.Const.panelIndicatorRightMargin)
            make.width.height.equalTo(BTFieldLayout.Const.panelIndicatorWidthHeight)
        }
        
        containerView.addSubview(ratingCollectionView)
        ratingCollectionView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
            make.top.bottom.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
            make.right.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
        }
        layoutIfNeeded()    // 这行必须写，否则横竖屏转换时会有bug
    }

    func stopEditing() {
        updateBorderMode(.normal)
        fieldModel.update(isEditing: false)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    func startEditing() {
        updateBorderMode(.editing)
        fieldModel.update(isEditing: true)
        editAgent = BTRatingEditAgent(fieldID: fieldModel.fieldID, recordID: fieldModel.recordID, editInPanel: !fieldModel.isInForm)
        delegate?.startEditing(inField: self, newEditAgent: editAgent)
    }
    
    func panelDidStartEditing() {
        delegate?.panelDidStartEditingField(self, scrollPosition: nil)
    }
    
    override func updateBorderMode(_ mode: BorderMode) {
        if fieldModel.isInForm {
            super.updateBorderMode(.noBorder)   // 表单编辑模式无框
            return
        }
        super.updateBorderMode(mode)
        panelIndicator.image = mode == .editing ? pickingIndicator : normalIndicator
    }
    
    @objc
    private func ratingBarClick() {
        if fieldModel.editable {
            startEditing()
        } else {
            showUneditableToast()
        }
    }
}

extension BTRatingField: BTRatingViewDelegate {
    func ratingValueChanged(rateView: BTRatingView, value: Int?) {
        startEditing()
        editAgent?.commit(value: value)
        stopEditing()
    }
}
