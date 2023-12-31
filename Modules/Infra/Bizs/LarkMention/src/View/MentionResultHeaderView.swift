//
//  MentionResultHeaderView.swift
//  LarkMention
//
//  Created by Yuri on 2022/6/6.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignCheckBox

final class MentionResultHeaderView: UIView {
    private var stackView = UIStackView()
    var multiBtn = UIButton()
    var titleLabel = UILabel()
    var checkBox: UDCheckBox?
    var didSwitchGlobalCheckBoxHandler: ((Bool) -> Void)?
    
    var hasCheckBox: Bool
    init(hasCheckBox: Bool = false, checkBoxSelected: Bool = false) {
        self.hasCheckBox = hasCheckBox
        super.init(frame: .zero)
        setupUI()
        checkBox?.isSelected = checkBoxSelected
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        multiBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        multiBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        multiBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
        multiBtn.setTitle(BundleI18n.LarkMention.Lark_Mention_Multiselect_Mobile, for: .normal)
        multiBtn.setTitle(BundleI18n.LarkMention.Lark_Mention_Done_Mobile, for: [.selected, .highlighted])
        multiBtn.setTitle(BundleI18n.LarkMention.Lark_Mention_Done_Mobile, for: .selected)
        addSubview(multiBtn)
        multiBtn.snp.makeConstraints {
            $0.height.equalTo(22)
            $0.top.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-8)
            $0.trailing.equalToSuperview().offset(-16)
        }
        
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 8
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualTo(multiBtn.snp.leading).offset(-8)
        }
        
        if hasCheckBox {
            titleLabel.textColor = UIColor.ud.textTitle
            let checkBox = UDCheckBox(boxType: .multiple)
            checkBox.isUserInteractionEnabled = false
            stackView.addArrangedSubview(checkBox)
            checkBox.snp.makeConstraints {
                $0.size.equalTo(CGSize(width: 20, height: 20))
            }
            self.checkBox = checkBox
        } else {
            titleLabel.textColor = UIColor.ud.textCaption
        }
        
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.text = BundleI18n.LarkMention.Lark_Mention_Mention_Mobile
        stackView.addArrangedSubview(titleLabel)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onSwitchCheckBox))
        stackView.addGestureRecognizer(tap)
    }
    
    @objc private func onSwitchCheckBox() {
        guard let checkBox = checkBox else {
            return
        }
        checkBox.isSelected.toggle()
        didSwitchGlobalCheckBoxHandler?(checkBox.isSelected)
    }
}
