//
//  MinutesEditSpeakerRemoveView.swift
//  Minutes
//
//  Created by admin on 2022/4/22.
//

import Foundation
import UIKit
import UniverseDesignCheckBox

protocol MinutesEditSpeakerRemoveViewDelegate: AnyObject {
    func checkBoxDidChangeStatus(isOn: Bool)
}

class MinutesEditSpeakerRemoveView: UIView {

    public weak var delegate: MinutesEditSpeakerRemoveViewDelegate?
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        return label
    }()

    public var checkBoxIsSelected:Bool {
        return checkBox.isSelected
    }

    private lazy var checkBox = UDCheckBox()

    private lazy var checkBoxTitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        return label
    }()

    public func setCheckBox(isOn: Bool) {
        checkBox.isSelected = isOn
    }

    init(contentText: String, checkBoxText: String?, frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(titleLabel)
        titleLabel.text = contentText
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        if let checkBoxText = checkBoxText {
            self.addSubview(checkBox)
            checkBox.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
                make.top.equalTo(titleLabel.snp.bottom).offset(19)
            }
            checkBox.tapCallBack = { [weak self] box in
                guard let self = self else { return }
                self.checkBox.isSelected = !self.checkBox.isSelected
                self.delegate?.checkBoxDidChangeStatus(isOn: self.checkBox.isSelected)
            }
            self.addSubview(checkBoxTitle)
            checkBoxTitle.text = checkBoxText
            checkBoxTitle.snp.makeConstraints { (make) in
                make.left.equalTo(checkBox.snp.right).offset(12)
                make.top.equalTo(checkBox.snp.top)
                make.right.lessThanOrEqualToSuperview()
                make.bottom.equalToSuperview().offset(-22)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
