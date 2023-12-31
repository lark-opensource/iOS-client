//
//  MinutesRemoveContentView.swift
//  Minutes
//
//  Created by chenlehui on 2021/7/26.
//

import UIKit
import UniverseDesignColor
import MinutesFoundation

class MinutesRemoveContentView: UIView {

    lazy var titleLabel: UILabel = {
        let lab = UILabel()
        lab.text = BundleI18n.Minutes.MMWeb_M_Home_SharedRemoveFromAllList_PopupText
        lab.textColor = UIColor.ud.textTitle
        lab.font = .systemFont(ofSize: 17)
        lab.numberOfLines = 0
        return lab
    }()

    lazy var checkButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(BundleResources.Minutes.minutes_home_remove_unselected, for: .normal)
        button.setImage(BundleResources.Minutes.minutes_home_remove_selected, for: .selected)
        button.addTarget(self, action: #selector(checkAction(_:)), for: .touchUpInside)
        return button
    }()

    lazy var checkLabel: UILabel = {
        let lab = UILabel()
        lab.text = BundleI18n.Minutes.MMWeb_M_Home_MyDeleteOriginalFile_Checkbox
        lab.textColor = UIColor.ud.textCaption
        lab.font = .systemFont(ofSize: 14)
        return lab
    }()

    private lazy var button: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(checkAction(_:)), for: .touchUpInside)
        return button
    }()

    var isSelected: Bool {
        return checkButton.isSelected
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        addSubview(checkButton)
        checkButton.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.width.height.equalTo(20)
            make.bottom.equalToSuperview()
        }

        addSubview(checkLabel)
        checkLabel.snp.makeConstraints { make in
            make.left.equalTo(checkButton.snp.right).offset(8)
            make.centerY.equalTo(checkButton)
        }

        addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalTo(checkLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func checkAction(_ sender: UIButton) {
        checkButton.isSelected = !checkButton.isSelected
    }

}
