//
//  FilterTabSelectedTabView.swift
//  Todo
//
//  Created by baiyantao on 2022/8/19.
//

import Foundation
import UIKit
import UniverseDesignShadow
import UniverseDesignIcon
import UniverseDesignFont

final class FilterTabSelectedTabView: UIView {

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var exitHandler: (() -> Void)?

    private lazy var containerView = initContainerView()
    private lazy var titleLabel = initTitleLabel()
    private lazy var exitIcon = initExitIcon()

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.N300
        layer.cornerRadius = 16
        layer.masksToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(doClick))
        addGestureRecognizer(tap)

        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(2)
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(20)
        }

        containerView.addSubview(exitIcon)
        exitIcon.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(titleLabel.snp.right).offset(14)
            $0.right.equalToSuperview().offset(-10)
            $0.width.height.equalTo(12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initContainerView() -> UIView {
        let view = UIView()
        view.backgroundColor = FilterTab.imFeedBgBody
        view.layer.cornerRadius = 14
        view.layer.masksToBounds = true
        return view
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = FilterTab.imFeedTextPriSelected
        label.font = UDFont.body1
        return label
    }

    private func initExitIcon() -> UIImageView {
        let view = UIImageView()
        view.image = UDIcon.closeBoldOutlined.ud.withTintColor(FilterTab.imFeedIconPriSelected)
        return view
    }

    @objc
    private func doClick() {
        exitHandler?()
    }
}
