//
//  CCMTypeFilterHeaderView.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/5/17.
//

import UIKit
import SnapKit
import UniverseDesignColor

final class CCMTypeFilterHeaderView: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private let sepratorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(16)
            make.right.lessThanOrEqualToSuperview().inset(-16)
            make.top.equalToSuperview().inset(6)
            make.height.greaterThanOrEqualTo(20)
        }

        addSubview(sepratorView)
        sepratorView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}
