//
//  SearchLowNetworkBanner.swift
//  LarkSearch
//
//  Created by Patrick on 28/9/2022.
//

import UIKit
import Foundation
import FigmaKit

final class SearchLowNetworkBanner: NiblessView {
    struct Param {
        let title: String
        let actionText: String
        let icon: UIImage
        let showDivider: Bool
        let contentAlignmentType: ContentAlignmentType
        let showTopCorner: Bool
    }
    enum ContentAlignmentType {
        case center
        case bottom
    }
    private let iconView = UIImageView()
    private lazy var actionLabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.textAlignment = .right
        return label
    }()
    private lazy var divider = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault
        return view
    }()
    private let titleLabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
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
        content.addSubview(iconView)
        content.addSubview(titleLabel)
        content.addSubview(actionLabel)

        if param.showTopCorner {
            roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
            blurView.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        }

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        content.backgroundColor = .clear
        switch param.contentAlignmentType {
        case .center:
            content.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(16)
                make.top.bottom.equalTo(titleLabel)
            }
        case .bottom:
            content.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().inset(10)
                make.top.bottom.equalTo(titleLabel)
            }
        }

        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel).offset(1.5)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(4)
            make.right.equalTo(actionLabel.snp.left).offset(-4)
            make.centerY.equalToSuperview()
        }

        actionLabel.font = UIFont.systemFont(ofSize: 14)
        actionLabel.textColor = UIColor.ud.textLinkNormal
        actionLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        if param.showDivider {
            addSubview(divider)
            divider.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().inset(2)
                make.height.equalTo(1)
            }
        }
    }

    @objc
    private func didClickHeader() {
        didTapHeader?()
    }
}
