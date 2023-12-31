//
// Created by duanxiaochen.7 on 2021/3/15.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import SnapKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignLoading
import SKResource
import SKCommon
import SKFoundation

final class BTFormulaField: BTInlineReadOnlyTextField {
    private let stateSpin: UDSpin = {
        return UDSpin(
            config: UDSpinConfig(
                indicatorConfig: UDSpinIndicatorConfig(
                    size: 20.0,
                    color: UDColor.primaryContentDefault
                ),
                textLabelConfig: nil
            )
        )
    }()
    
    private let statePendingLabel: UILabel = {
        let vi = UILabel()
        vi.textColor = UDColor.textPlaceholder
        vi.font = UDFont.body2
        vi.text = BundleI18n.SKResource.Bitable_Form_Calculating
        return vi
    }()
    
    private let stateFailedLabel: UILabel = {
        let vi = UILabel()
        vi.textColor = UDColor.textPlaceholder
        vi.font = UDFont.body2
        vi.text = BundleI18n.SKResource.Bitable_Form_CalculationFailed
        return vi
    }()
    
    private let stateContainer: UIView = {
        UIView()
    }()
    
    private let placeholderLabel: UILabel = {
        let vi = UILabel()
        vi.text = BundleI18n.SKResource.Bitable_Form_ShowCalculationResults
        vi.textColor = UDColor.textPlaceholder
        vi.font = UDFont.body2
        return vi
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        subviewsInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        subviewsInit()
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        if UserScopeNoChangeFG.ZYS.formSupportFormula, model.isInForm {
            updateCalcState(with: model)
        } else {
            textView.isHidden = false
            stateContainer.isHidden = true
            placeholderLabel.isHidden = true
        }
        super.loadModel(model, layout: layout)
    }
    
    private func subviewsInit() {
        containerView.addSubview(stateContainer)
        containerView.addSubview(placeholderLabel)
        stateContainer.addSubview(stateSpin)
        stateContainer.addSubview(statePendingLabel)
        stateContainer.addSubview(stateFailedLabel)
        
        stateContainer.isHidden = true
        placeholderLabel.isHidden = true
        
        stateContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
        }
        stateSpin.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }
        statePendingLabel.snp.makeConstraints { make in
            make.left.equalTo(stateSpin.snp.right).offset(8)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(12)
        }
        stateFailedLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview()
        }
        placeholderLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
        }
    }
    
    private func updateCalcState(with model: BTFieldModel) {
        guard let state = model.calcState else {
            textView.isHidden = false
            stateContainer.isHidden = true
            placeholderLabel.isHidden = !model.textValue.isEmpty
            return
        }
        switch state {
        case .pending:
            stateContainer.isHidden = false
            stateSpin.isHidden = false
            statePendingLabel.isHidden = false
            stateFailedLabel.isHidden = true
            textView.isHidden = true
            placeholderLabel.isHidden = true
        case .success:
            stateContainer.isHidden = true
            textView.isHidden = false
            placeholderLabel.isHidden = !model.textValue.isEmpty
        case .failed:
            stateContainer.isHidden = false
            stateSpin.isHidden = true
            statePendingLabel.isHidden = true
            stateFailedLabel.isHidden = false
            textView.isHidden = true
            placeholderLabel.isHidden = true
        }
    }

}
