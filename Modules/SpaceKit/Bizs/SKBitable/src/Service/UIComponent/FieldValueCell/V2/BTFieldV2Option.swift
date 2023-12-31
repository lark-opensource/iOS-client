//
//  BTFieldV2Option.swift
//  SKBitable
//
//  Created by zoujie on 2023/8/11.
//  


import Foundation
import SKCommon
import SKBrowser
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignButton

struct BTFieldUIDataOption {
    static func calculateOptionFieldFitSize(_ field: BTFieldModel, maxLineLength: CGFloat) -> (CGSize, Int) {
        var selectedOptionIDs = field.optionIDs
        let colors = field.colors
        var allOptions = field.property.options
        
        if field.property.optionsType == .dynamicOption {
            //级联选项
            allOptions = field.dynamicOptions
            selectedOptionIDs = field.dynamicOptions.compactMap({ $0.id })
        }
        
        let data = BTUtil.getSelectedOptions(
            withIDs: selectedOptionIDs,
            colors: colors,
            allOptionInfos: allOptions
        )
        
        let layoutConfig = BTFieldLayout.Const.optionFieldCapsuleLayout
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

final class BTFieldV2Option: BTFieldV2Base, BTFieldOptionCellProtocol {
    private lazy var optionView: BTCapsuleCollectionView = {
        BTCapsuleCollectionView().construct { it in
            it.isUserInteractionEnabled = true
            it.contentInsetAdjustmentBehavior = .never
            it.layoutConfig = BTFieldLayout.Const.optionFieldCapsuleLayout
            it.delegate = self
        }
    }()
    
    override func subviewsInit() {
        super.subviewsInit()
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(startPicking))
        tapGR.numberOfTapsRequired = 1
        containerView.addGestureRecognizer(tapGR)
        
        let doubleTapGR = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTapGR.numberOfTapsRequired = 2
        containerView.addGestureRecognizer(doubleTapGR)
        
        tapGR.require(toFail: doubleTapGR)

        containerView.addSubview(optionView)
        containerView.sendSubviewToBack(optionView)
        optionView.snp.makeConstraints { it in
            it.edges.equalToSuperview()
        }
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
        delegate?.panelDidStartEditingField(self, scrollPosition: .bottom)
    }

    func stopEditing(scrollPosition: UICollectionView.ScrollPosition? = nil) {
        updateBorderMode(.normal)
        delegate?.stopEditingField(self, scrollPosition: scrollPosition)
    }

    @objc
    private func startPicking() {
        if fieldModel.editable {
            delegate?.startEditing(inField: self, newEditAgent: nil)
        } else {
            showUneditableToast()
        }
    }
    
    @objc
    private func doubleTap(_ sender: UITapGestureRecognizer) {
        delegate?.didDoubleTap(self, field: fieldModel)
    }

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        var selectedOptionIDs = fieldModel.optionIDs
        let colors = fieldModel.colors
        var allOptions = fieldModel.property.options

        if model.property.optionsType == .dynamicOption {
            //级联选项
            allOptions = fieldModel.dynamicOptions
            selectedOptionIDs = fieldModel.dynamicOptions.compactMap({ $0.id })
        }

        let options = BTUtil.getSelectedOptions(
            withIDs: selectedOptionIDs,
            colors: colors,
            allOptionInfos: allOptions
        )
        
        optionView.dataSource = options
        optionView.isHidden = options.isEmpty
        // 需要重新 layout，不然选项加载可能不完整
        setNeedsLayout()
    }
}

extension BTFieldV2Option: BTCapsuleCollectionViewDelegate {
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, didDoubleTapCell model: BTCapsuleModel) {
        delegate?.didDoubleTap(self, field: fieldModel)
    }
    
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, didTapCell model: BTCapsuleModel) {
        startPicking()
    }
    
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, shouleAllowCellApplyAction action: BTTextViewMenuAction) -> Bool {
        return delegate?.textViewOfField(fieldModel, shouldAppyAction: action) ?? false
    }
}

