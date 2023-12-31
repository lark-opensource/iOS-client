//
//  ShareLinkHeaderView.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/11.
//

import Foundation
import SKResource
import UniverseDesignColor

class ShareLinkHeaderView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.N600
        return label
    }()
    
    init(title: String) {
        super.init(frame: .zero)
        self.titleLabel.text = title
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBase
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(safeAreaLayoutGuide.snp.left).offset(16)
            make.bottom.equalToSuperview().offset(-4)
            make.height.equalTo(22)
        }
    }
}
