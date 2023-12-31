//
//  AtPageCheckboxHeaderView.swift
//  SKCommon
//
//  Created by zengsenyuan on 2021/11/8.
//  


import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignCheckBox


class AtPageCheckboxHeaderView: UIView {
    
    struct Metric {
        static let textFont = UIFont.systemFont(ofSize: 16)
        static let checkBoxBtnSize: CGFloat = 20
        static let checkBoxLeftMargin: CGFloat = 16
        static let checkBoxRightMargin: CGFloat = 8
        static let textLabelRightMargin: CGFloat = 14
        static let textLabelVerticalMargin: CGFloat = 12
    }
    typealias CheckboxAction = ((_ isSelected: Bool) -> Void)
    
    var checkboxAction: CheckboxAction?
    
    private lazy var checkbox: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple, tapCallBack: { [weak self] _checkbox in
            self?.checkboxPressed(_checkbox)
        })
        return checkbox
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = Metric.textFont
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        return label
    }()
    
    var isSelected: Bool {
        return checkbox.isSelected
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func calculateHeight(with limitWidth: CGFloat, text: String) -> CGFloat {
        let usedWidth = Metric.checkBoxLeftMargin + Metric.checkBoxRightMargin + Metric.textLabelRightMargin
        let textWidth = limitWidth - usedWidth - Metric.checkBoxBtnSize
        return text.getHeight(withConstrainedWidth: textWidth, font: Metric.textFont) + (2 * Metric.textLabelVerticalMargin)
    }
    
    func updateCheckboxData(_ data: AtCheckboxData) {
        self.textLabel.text = data.text
        self.checkbox.isSelected = data.isSelected
    }
    
    private func checkboxPressed(_ checkbox: UDCheckBox) {
        self.checkbox.isSelected = !self.checkbox.isSelected
        checkboxAction?(checkbox.isSelected)
    }
    
    private func setupViews() {
        self.addSubview(checkbox)
        self.addSubview(textLabel)
        self.clipsToBounds = true
    }
    
    private func setupLayouts() {
        checkbox.snp.makeConstraints {
            $0.centerY.equalTo(textLabel)
            $0.left.equalToSuperview().inset(Metric.checkBoxLeftMargin)
            $0.width.height.equalTo(Metric.checkBoxBtnSize) //20 + 8*2
        }
        
        textLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(Metric.textLabelVerticalMargin)
            $0.left.equalTo(checkbox.snp.right).offset(Metric.checkBoxRightMargin)
            $0.right.equalToSuperview().inset(Metric.textLabelRightMargin)
        }
    }
}
