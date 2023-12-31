//
//  FormConditionTitleView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/5/18.
//

import Foundation
import UniverseDesignColor

final class FormConditionTitleView: UIView {
    var context: BTDDUIContext?
    var model: FormConditionTitleWidgetModel?
    
    private lazy var cancelButton = UIButton().construct { it in
        it.backgroundColor = .clear
        it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        it.setTitleColor(UDColor.primaryPri500, for: .normal)
        it.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
    }

    private lazy var doneButton: UIButton = UIButton().construct { it in
        it.backgroundColor = .clear
        it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        it.setTitleColor(UDColor.primaryPri500, for: .normal)
        it.addTarget(self, action: #selector(didClickDoneButton), for: .touchUpInside)
    }

    private lazy var titleLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textColor = UDColor.textTitle
        it.textAlignment = .center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(cancelButton)
        addSubview(titleLabel)
        addSubview(doneButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        doneButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(cancelButton)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(cancelButton.snp.right).offset(12)
            make.right.lessThanOrEqualTo(doneButton.snp.left).offset(-12)
            make.centerY.equalTo(cancelButton)
        }
    }
    
    // MARK: - Private Func
    @objc
    private func cancelClick() {
        if let callbackId = model?.leftText?.onClick {
            context?.emitEvent(callbackId, args: [:])
        }
    }
    
    @objc
    private func didClickDoneButton() {
        if let callbackId = model?.rightText?.onClick {
            context?.emitEvent(callbackId, args: [:])
        }
    }
    
    func setData(_ model: FormConditionTitleWidgetModel, with context: BTDDUIContext?) {
        self.model = model
        if let context = context {
            self.context = context
        }
        cancelButton.setTitle(model.leftText?.text, for: .normal)
        if let leftTextColor = model.leftText?.textColor {
            cancelButton.setTitleColor(UIColor.docs.rgb(leftTextColor), for: .normal)
        }
        doneButton.setTitle(model.rightText?.text, for: .normal)
        if let rightTextColor = model.rightText?.textColor {
            doneButton.setTitleColor(UIColor.docs.rgb(rightTextColor), for: .normal)
        }
        titleLabel.text = model.centerText?.text
        if let titleColor = model.centerText?.textColor {
            titleLabel.textColor = UIColor.docs.rgb(titleColor)
        }
    }
}

