//
//  BTProgressField.swift
//  SKBitable
//
//  Created by yinyuan on 2022/12/10.
//


import Foundation
import SKBrowser
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignProgressView
import UniverseDesignIcon
import SKCommon
import LarkTag
import SKFoundation
import SKResource

final class BTProgressField: BTBaseField, BTFieldProgressCellProtocol {
    
    private var progressCollectionView: BTProgressCollectionView = BTProgressCollectionView()

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        reloadData()
    }
    
    override func setupLayout() {
        super.setupLayout()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(progressBarClick))
        containerView.addGestureRecognizer(tapGesture)
    }

    func stopEditing() {
        updateBorderMode(.normal)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    func updateEditingStatus(_ editing: Bool) {
        fieldModel.update(isEditing: editing)
    }
    
    func panelDidStartEditing() {
        updateBorderMode(.editing)
        delegate?.panelDidStartEditingField(self, scrollPosition: nil)
    }
    
    override func updateBorderMode(_ mode: BorderMode) {
        super.updateBorderMode(mode)
        panelIndicator.image = mode == .editing ? pickingIndicator : normalIndicator
    }
    
    @objc
    private func progressBarClick() {
        if fieldModel.editable {
            delegate?.startEditProgress(forField: self)
        } else {
            showUneditableToast()
        }
    }
    
    func reloadData() {
        panelIndicator.removeFromSuperview()
        containerView.addSubview(panelIndicator)
        panelIndicator.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-BTFieldLayout.Const.panelIndicatorRightMargin)
            make.width.height.equalTo(BTFieldLayout.Const.panelIndicatorWidthHeight)
        }
        panelIndicator.isHidden = !fieldModel.editable
        
        progressCollectionView.removeFromSuperview()
        containerView.addSubview(progressCollectionView)
        progressCollectionView.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
            make.top.bottom.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
            if fieldModel.editable {
                make.right.equalTo(panelIndicator.snp.left).offset(-BTFieldLayout.Const.containerPadding)
            } else {
                make.right.equalToSuperview().offset(-BTFieldLayout.Const.containerPadding)
            }
        }
        layoutIfNeeded()
        
        progressCollectionView.fieldModel = fieldModel
    }
}
