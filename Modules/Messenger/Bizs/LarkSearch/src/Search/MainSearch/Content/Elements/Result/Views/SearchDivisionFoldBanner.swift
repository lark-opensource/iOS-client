//
//  SearchDivisionFoldBanner.swift
//  LarkSearch
//
//  Created by ByteDance on 2022/11/1.
//

import UIKit
import Foundation
import FigmaKit

class SearchDivisionFoldBanner: NiblessView {
    private let actionLabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.textAlignment = .right
        return label
    }()
    private let titleLabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    private let iconView = UIImageView()
    struct Param {
        let title: String
        let actionText: String
        let icon: UIImage
    }

    private let content = UIView()
    private lazy var blurView: BackgroundBlurView = {
        let view = BackgroundBlurView()
        view.blurRadius = 20
        view.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.75)
        return view
    }()

    let param: Param
    var didTapHeader: (() -> Void)?

    init(param: Param) {
        self.param = param
        super.init(frame: .zero)
        setupView()
    }

    private func setupView() {
        titleLabel.text = param.title
        actionLabel.text = param.actionText
        iconView.image = param.icon
        lu.addTapGestureRecognizer(action: #selector(didClickHeader), target: self)

        addSubview(blurView)
        addSubview(content)
        content.addSubview(titleLabel)
        content.addSubview(actionLabel)
        content.addSubview(iconView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        content.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(10)
        }
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.snp.makeConstraints { make in
            make.left.bottom.top.equalToSuperview()
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(iconView.snp.left)
        }

        actionLabel.font = UIFont.systemFont(ofSize: 14)
        actionLabel.textColor = UIColor.ud.textPlaceholder
        actionLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.right.equalTo(actionLabel.snp.left).inset(-4.5)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 12))
        }
    }

    func updateBannerUI(newIcon: UIImage, newActionText: String) {
        iconView.image = newIcon
        actionLabel.text = newActionText
        setNeedsLayout()
    }

    @objc
    private func didClickHeader() {
        didTapHeader?()
    }
}
