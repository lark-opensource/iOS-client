//
//  DetailHeaderView.swift
//  Moment
//
//  Created by zc09v on 2021/3/24.
//

import UIKit
import Foundation

final class DetailTitleView: UIView {
    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 9
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    private lazy var titleArrowImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.detailNavArrow)
        return imageView
    }()

    var didTapped: (() -> Void)?

    init(title: String, showArrow: Bool) {
        super.init(frame: .zero)
        titleLabel.text = title
        self.addSubview(titleStackView)
        titleStackView.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.top.bottom.equalToSuperview()
            make.center.equalToSuperview()
        }
        titleStackView.addArrangedSubview(titleLabel)
        if showArrow {
            titleStackView.addArrangedSubview(titleArrowImageView)
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
            self.addGestureRecognizer(tap)
        }
    }

    @objc
    private func tapped() {
        didTapped?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
