//
//  BTFieldV2Chatter.swift
//  SKBitable
//
//  Created by zoujie on 2023/8/11.
//  


import SKFoundation
import SKBrowser
import UniverseDesignIcon

extension BTUserModel {
    func asChatterFieldCapsuleModel(isSelected: Bool) -> BTCapsuleModel {
        if !UserScopeNoChangeFG.ZJ.btCardReform {
            return asCapsuleModel(isSelected: isSelected)
        } else {
            var model = asCapsuleModel(isSelected: isSelected)
            model.font = BTFV2Const.Font.fieldValue
            return model
        }
    }
}

extension BTGroupModel {
    func asChatterFieldCapsuleModel(isSelected: Bool) -> BTCapsuleModel {
        if !UserScopeNoChangeFG.ZJ.btCardReform {
            return asCapsuleModel(isSelected: isSelected)
        } else {
            var model = asCapsuleModel(isSelected: isSelected)
            model.font = BTFV2Const.Font.fieldValue
            return model
        }
    }
}

struct BTFieldChatterCaculate {
    static func calculateChatterFieldFitSize(_ field: BTFieldModel, maxLineLength: CGFloat) -> (CGSize, Int) {
        var data: [BTCapsuleModel] = []
        let chatterType = field.extendedType.chatterType ?? .group
        
        switch chatterType {
        case .user:
            data = field.users.compactMap({ $0.asChatterFieldCapsuleModel(isSelected: false) })
        case .group:
            data = field.groups.compactMap({ $0.asChatterFieldCapsuleModel(isSelected: false) })
        }
        
        let layoutConfig = BTFieldLayout.Const.newMemberFieldCapsuleLayout
        let (_, rects, row) =  BTCollectionViewWaterfallHelper.calculate(with: data,
                                                                         maxLineLength: maxLineLength,
                                                                         layoutConfig: layoutConfig)
        
        let width, height: CGFloat
        if row > 1 {
            width = maxLineLength
            height = CGFloat(row) * (layoutConfig.rowSpacing + layoutConfig.lineHeight) - layoutConfig.rowSpacing
        } else {
            width = min(rects.last?.maxX ?? 0, maxLineLength)
            height = row > 0 ? layoutConfig.lineHeight : 0
        }
        let size = CGSize(width: width, height: min(BTFV2Const.Dimension.optionUserLinkFieldMaxHeight, height))
        return (size, row)
    }
}

// chatter类型以后都可以用这个
final class BTFieldV2Chatter: BTFieldV2Base, BTFieldChatterCellProtocol {
    
    private lazy var membersView: BTCapsuleCollectionView = {
        BTCapsuleCollectionView(.avatar).construct { it in
            it.delegate = self
            it.isUserInteractionEnabled = true
            it.contentInsetAdjustmentBehavior = .never
            it.layoutConfig = BTFieldLayout.Const.newMemberFieldCapsuleLayout
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
        
        membersView.isHidden = addedMembers.isEmpty
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
        
        containerView.addSubview(uview)
        uview.snp.makeConstraints { it in
            it.edges.equalToSuperview()
        }
        
        layoutIfNeeded()
    }
    
    private func reloadData() {
        if membersView.superview != nil { membersView.removeFromSuperview() }
        layoutMemebersView(membersView)
        membersView.dataSource = addedMembers
    }
    
    @objc
    override func onFieldEditBtnClick(_ sender: UIButton) {
        startPicking()
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        startPicking()
    }
    
    func panelDidStartEditing() {
        updateBorderMode(.editing)
        delegate?.panelDidStartEditingField(self, scrollPosition: nil)
    }
    
    func stopEditing() {
        updateBorderMode(.normal)
        delegate?.stopEditingField(self, scrollPosition: nil)
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


extension BTFieldV2Chatter: BTCapsuleCollectionViewDelegate {
    
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, didDoubleTapCell model: BTCapsuleModel) {
        delegate?.didDoubleTap(self, field: fieldModel)
    }
    
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, didTapCell model: BTCapsuleModel) {
        if fieldModel.editable {
            startPicking()
        } else {
            delegate?.didTapChatter(with: model)
        }
    }
    
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, shouleAllowCellApplyAction action: BTTextViewMenuAction) -> Bool {
        return delegate?.textViewOfField(fieldModel, shouldAppyAction: action) ?? false
    }
    
}

extension BTFieldV2Chatter {
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view == containerView {
            return !membersView.detectTouchIsInCell(touch)
        }
        return super.gestureRecognizer(gestureRecognizer, shouldReceive: touch)
    }
}

