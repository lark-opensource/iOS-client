//
//  WikiMemberSectionHeaderView.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/23.
//  

import UIKit
import SnapKit
import UniverseDesignColor

class WikiMemberSectionHeaderView: UIView {

    private lazy var recentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ct.systemMedium(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        setupUI()
        recentLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(recentLabel)
        recentLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
    }
}
