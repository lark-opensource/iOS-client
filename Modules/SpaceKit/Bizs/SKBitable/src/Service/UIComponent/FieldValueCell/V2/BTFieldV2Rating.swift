import Foundation
import SKBrowser
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import SKCommon
import LarkTag
import SKFoundation
import SKResource

final class BTFieldV2Rating: BTFieldV2Base, BTFieldRatingCellProtocol {
    
    private var ratingCollectionView: BTRatingCollectionView = BTRatingCollectionView()
    private var tapGesture: UITapGestureRecognizer?
    private var editAgent: BTRatingEditAgent?
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        let oldModle = fieldModel
        super.loadModel(model, layout: layout)
        ratingCollectionView.ratingDelegate = nil
        bindTapGesture()
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
    
    override func subviewsInit() {
        super.subviewsInit()
        containerView.addSubview(ratingCollectionView)
        ratingCollectionView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
        layoutIfNeeded()    // 这行必须写，否则横竖屏转换时会有bug
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        ratingBarClick()
    }

    func stopEditing() {
        fieldModel.update(isEditing: false)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    func startEditing() {
        fieldModel.update(isEditing: true)
        editAgent = BTRatingEditAgent(fieldID: fieldModel.fieldID, recordID: fieldModel.recordID, editInPanel: !fieldModel.isInForm)
        delegate?.startEditing(inField: self, newEditAgent: editAgent)
    }
    
    func panelDidStartEditing() {
        delegate?.panelDidStartEditingField(self, scrollPosition: nil)
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

extension BTFieldV2Rating: BTRatingViewDelegate {
    func ratingValueChanged(rateView: BTRatingView, value: Int?) {
        startEditing()
        editAgent?.commit(value: value)
        stopEditing()
    }
}
