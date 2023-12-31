//
//  NameCardNavTitleView.swift
//  LarkContact
//
//  Created by Quanze Gao on 2022/4/19.
//

import Foundation
import UIKit
import UniverseDesignColor

final class NameCardNavTitleView: UIView {
    private lazy var contentStatckView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    private(set) lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = .systemFont(ofSize: 12)
        subTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subTitleLabel.textColor = UIColor.ud.textCaption
        return subTitleLabel
    }()

    init(title: String, subTitle: String) {
        super.init(frame: .zero)

        self.addSubview(contentStatckView)
        contentStatckView.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.top.bottom.equalToSuperview()
            make.center.equalToSuperview()
        }

        titleLabel.text = title
        subTitleLabel.text = subTitle

        contentStatckView.addArrangedSubview(titleLabel)
        contentStatckView.addArrangedSubview(subTitleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
