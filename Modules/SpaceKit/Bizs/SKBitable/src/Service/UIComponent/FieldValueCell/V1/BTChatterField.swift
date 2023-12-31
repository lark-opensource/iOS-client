//
//  BTChatterField.swift
//  SKBitable
//
//  Created by X-MAN on 2023/1/11.
//

import Foundation
import SKBrowser

// chatter类型以后都可以用这个
final class BTChatterField: BTBaseField, BTFieldChatterCellProtocol {
    
    private lazy var membersView: BTCapsuleCollectionView = {
        BTCapsuleCollectionView(.avatar).construct { it in
            it.delegate = self
            it.isUserInteractionEnabled = true
            it.layoutConfig = BTFieldLayout.Const.memberFieldCapsuleLayout
        }
    }()
    
    private let minimumTapInterval = 0.3 // 频率限制
    
    var addedMembers: [BTCapsuleModel] = []
    
    var chatterType: BTChatterType {
        return fieldModel.extendedType.chatterType ?? .group
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        switch chatterType {
        case .user:
            addedMembers = fieldModel.users.compactMap({ $0.asChatterFieldCapsuleModel(isSelected: false) })
        case .group:
            addedMembers = fieldModel.groups.compactMap({ $0.asChatterFieldCapsuleModel(isSelected: false) })
        }
        reloadData()
    }
    
    private func layoutMemebersView(_ uview: UIView) {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(startPicking))
        tapGR.delegate = self
        containerView.addGestureRecognizer(tapGR)
        
        let doubleTapGR = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTapGR.numberOfTapsRequired = 2
        containerView.addGestureRecognizer(doubleTapGR)
        
        tapGR.require(toFail: doubleTapGR)
        
        containerView.addSubview(panelIndicator)
        panelIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16) // user 需要设置更靠下才能视觉上居中
            make.right.equalToSuperview().offset(-BTFieldLayout.Const.panelIndicatorRightMargin)
            make.width.height.equalTo(BTFieldLayout.Const.panelIndicatorWidthHeight)
        }
        
        containerView.addSubview(uview)
        uview.snp.makeConstraints { it in
            it.left.equalToSuperview().offset(BTFieldLayout.Const.containerPadding)
            it.top.equalToSuperview().offset(BTFieldLayout.Const.containerPadding)
            it.bottom.equalToSuperview().offset(-BTFieldLayout.Const.containerPadding)
            if fieldModel.editable {
                it.right.equalToSuperview().offset(-BTFieldLayout.Const.panelIndicatorRightMargin - BTFieldLayout.Const.panelIndicatorWidthHeight)
            } else {
                it.right.equalToSuperview().offset(-BTFieldLayout.Const.containerPadding)
            }
        }
        layoutIfNeeded()
    }
    
    private func reloadData() {
        if membersView.superview != nil { membersView.removeFromSuperview() }
        panelIndicator.isHidden = !fieldModel.editable
        layoutMemebersView(membersView)
        membersView.dataSource = addedMembers
    }
    
    func panelDidStartEditing() {
        updateBorderMode(.editing)
        delegate?.panelDidStartEditingField(self, scrollPosition: nil)
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
    private func startPicking() {
        if fieldModel.editable {
            delegate?.startPickingChatter(forField: self)
        } else {
            showUneditableToast()
        }
    }
    
    @objc
    private func doubleTap(_ sender: UITapGestureRecognizer) {
        delegate?.didDoubleTap(self, field: fieldModel)
    }
}


extension BTChatterField: BTCapsuleCollectionViewDelegate {
    
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, didDoubleTapCell model: BTCapsuleModel) {
        delegate?.didDoubleTap(self, field: fieldModel)
    }
    
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, didTapCell model: BTCapsuleModel) {
        delegate?.didTapChatter(with: model)
    }
    
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, shouleAllowCellApplyAction action: BTTextViewMenuAction) -> Bool {
        return delegate?.textViewOfField(fieldModel, shouldAppyAction: action) ?? false
    }
    
}

extension BTChatterField: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if membersView.detectTouchIsInCell(touch) {
            return false
        }
        return true
    }
}
