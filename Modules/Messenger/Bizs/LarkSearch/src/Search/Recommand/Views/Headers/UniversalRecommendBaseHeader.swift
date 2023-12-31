//
//  UniversalRecommendBaseHeader.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/17.
//

import UIKit
import Foundation
import SnapKit

class UniversalRecommendBaseHeader: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .ud.textTitle
        return label
    }()

    lazy var container: UIView = {
        let view = UIView()
        view.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        contentView.backgroundColor = UIColor.ud.bgBase
        contentView.addSubview(container)
        container.addSubview(titleLabel)
        container.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(38)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(16)
        }
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}
