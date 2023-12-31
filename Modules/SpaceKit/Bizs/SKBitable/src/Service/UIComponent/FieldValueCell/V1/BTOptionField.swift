//
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
//
// Description:

import Foundation
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignColor
import SKBrowser

final class BTOptionField: BTBaseField, BTFieldOptionCellProtocol {

    private lazy var optionView: BTCapsuleCollectionView = {
        BTCapsuleCollectionView().construct { it in
            it.isUserInteractionEnabled = true
            it.layoutConfig = BTFieldLayout.Const.optionFieldCapsuleLayout
            it.delegate = self
        }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(startPicking))
        tapGR.numberOfTapsRequired = 1
        containerView.addGestureRecognizer(tapGR)
        
        let doubleTapGR = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTapGR.numberOfTapsRequired = 2
        containerView.addGestureRecognizer(doubleTapGR)
        
        tapGR.require(toFail: doubleTapGR)

        containerView.addSubview(panelIndicator)
        panelIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.right.equalToSuperview().offset(-BTFieldLayout.Const.panelIndicatorRightMargin)
            make.width.height.equalTo(BTFieldLayout.Const.panelIndicatorWidthHeight)
        }

        containerView.addSubview(optionView)
        containerView.sendSubviewToBack(optionView)
        optionView.snp.makeConstraints { it in
            it.left.equalToSuperview().offset(BTFieldLayout.Const.containerPadding)
            it.top.equalToSuperview().offset(BTFieldLayout.Const.containerPadding)
            it.bottom.equalToSuperview().offset(-BTFieldLayout.Const.containerPadding)
            it.right.equalToSuperview().offset(-BTFieldLayout.Const.containerPadding)
        }
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

        panelIndicator.isHidden = !fieldModel.editable
        
        optionView.snp.updateConstraints { make in
            let offset: CGFloat
            if fieldModel.editable {
                offset = BTFieldLayout.Const.panelIndicatorRightMargin + BTFieldLayout.Const.panelIndicatorWidthHeight
            } else {
                offset = BTFieldLayout.Const.containerPadding
            }
            make.right.equalToSuperview().offset(-offset)
        }

        if model.property.optionsType == .dynamicOption {
            //级联选项
            allOptions = fieldModel.dynamicOptions
            selectedOptionIDs = fieldModel.dynamicOptions.compactMap({ $0.id })
        }

        optionView.dataSource = BTUtil.getSelectedOptions(
            withIDs: selectedOptionIDs,
            colors: colors,
            allOptionInfos: allOptions
        )
        // 需要重新 layout，不然选项加载可能不完整
        setNeedsLayout()
    }

    override func updateBorderMode(_ mode: BorderMode) {
        super.updateBorderMode(mode)
        panelIndicator.image = mode == .editing ? pickingIndicator : normalIndicator
    }
}

extension BTOptionField: BTCapsuleCollectionViewDelegate {
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
