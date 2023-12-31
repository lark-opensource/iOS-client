//
//  FilterDrawerHeaderView.swift
//  Todo
//
//  Created by baiyantao on 2022/8/17.
//

import Foundation
import UniverseDesignFont

final class FilterDrawerHeaderView: UIView {
    private lazy var titleLabel = initTitleLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.text = I18N.Todo_Task_Tasks
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 22, weight: .medium)
        return label
    }
}
