//
//  RedPacketView.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2021/12/3.
//

/// figma: https://www.figma.com/file/XAkLYbCdTfiZdksYoGmQFt/%E7%BA%A2%E5%8C%85%E5%B0%81%E9%9D%A2?node-id=1865%3A110643

import UIKit
import Foundation
import ByteWebImage
import LarkModel
import SnapKit

public final class RedPacketView: UIView {

    enum BussinessIconStyle {
        case normal
        case B2C(CGFloat)
    }

    struct Config {
        static let descriptionLabelHeight: CGFloat = 14
        static let descriptionBackgroundViewHeight: CGFloat = 20
    }

    private var tapGestureAdded: Bool = false

    /// 点击开红包
    public var tapAction: (() -> Void)? {
        didSet {
            if tapGestureAdded { return }
            tapGestureAdded = true
            self.lu.addTapGestureRecognizer(action: #selector(redPacketDidTapped(_:)), target: self)
        }
    }

    var themeBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    var backgroundView: UIView = {
        let view = UIView()
        return view
    }()

    var containerView: UIView = {
        let view = UIView()
        return view
    }()

    let topViewHeight: CGFloat = 176

    var topView: ByteImageView = {
        let imageView = ByteImageView(image: BundleResources.hongbao_bg_top)
        imageView.autoPlayAnimatedImage = true
        return imageView
    }()

    var topShadowHeightConstraint: Constraint?
    let defaultTopShadowHeight: CGFloat = 108
    var topShadow: UIImageView = {
        let imageView = UIImageView(image: BundleResources.hongbao_bg_top_mask)
        return imageView
    }()

    var bottomView: UIImageView = {
        let imageView = UIImageView(image: BundleResources.hongbao_bg_bottom)
        return imageView
    }()

    var mainLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.Y200.alwaysLight
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    // 用来显示企业名
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.Y200.alwaysLight
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()

    // 头像、专属提示、领取状态的容器
    var centerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.distribution = .fill
        stack.alignment = .center
        return stack
    }()
    let centerStackHorizontalMargin: CGFloat = 12

    var descriptionBackgroundView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    var openImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    var statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.Y200.alwaysLight
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()

    var exclusiveAvatarListView: RedPacketExclusiveAvatarListView = {
        let exclusiveAvatarListView = RedPacketExclusiveAvatarListView()
        return exclusiveAvatarListView
    }()

    var exclusiveTipLabel: UILabel = {
        let exclusiveTipLabel = UILabel()
        exclusiveTipLabel.textColor = UIColor.ud.Y200.alwaysLight
        exclusiveTipLabel.textAlignment = .center
        exclusiveTipLabel.font = UIFont.systemFont(ofSize: 12)
        return exclusiveTipLabel
    }()

    var splitLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.3)
        return view
    }()

    var typeDescription: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 2
        return label
    }()

    var bussinessIcon: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(themeBackgroundView)
        themeBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.4)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(topViewHeight)
        }

        containerView.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(-40)
        }

        containerView.addSubview(topShadow)
        topShadow.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            topShadowHeightConstraint = make.height.equalTo(defaultTopShadowHeight).constraint
        }

        containerView.addSubview(mainLabel)
        mainLabel.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.left.equalTo(12)
            make.right.equalTo(-12)
        }

        containerView.addSubview(centerStack)
        centerStack.snp.makeConstraints { make in
            make.top.equalTo(mainLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(centerStackHorizontalMargin)
        }

        centerStack.addArrangedSubview(exclusiveAvatarListView)
        exclusiveAvatarListView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(RedPacketExclusiveAvatarLayoutEngine.exclusiveAvatarSize)
        }
        centerStack.addArrangedSubview(exclusiveTipLabel)
        centerStack.addArrangedSubview(statusLabel)

        containerView.addSubview(descriptionBackgroundView)
        containerView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(centerStack.snp.bottom).offset(14)
            make.height.equalTo(Self.Config.descriptionLabelHeight)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(20)
            make.right.lessThanOrEqualTo(-20)
        }

        descriptionBackgroundView.snp.makeConstraints { make in
            let verticalPadding = (Self.Config.descriptionBackgroundViewHeight - Self.Config.descriptionLabelHeight) / 2
            make.edges.equalTo(descriptionLabel).inset(UIEdgeInsets(top: -verticalPadding, left: -10, bottom: -verticalPadding, right: -10))
        }

        containerView.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(-40)
        }

        containerView.addSubview(openImageView)
        openImageView.snp.makeConstraints { make in
            make.bottom.equalTo(topView.snp.bottom).offset(22)
            make.width.height.equalTo(50)
            make.centerX.equalToSuperview()
        }

        containerView.addSubview(typeDescription)
        typeDescription.snp.makeConstraints { make in
            make.bottom.equalTo(-5)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }

        containerView.addSubview(splitLine)
        splitLine.snp.makeConstraints { make in
            make.bottom.equalTo(typeDescription.snp.top).offset(-6)
            make.width.equalToSuperview()
            make.height.equalTo(0.5)
        }

        containerView.addSubview(bussinessIcon)
        bussinessIcon.snp.makeConstraints { make in
            make.bottom.equalTo(-5)
            make.width.height.equalTo(15).priority(.required)
            make.right.equalTo(-10)
            make.left.greaterThanOrEqualTo(typeDescription.snp.right).offset(10)
        }
    }

    func setBussinessIconStyle(_ style: BussinessIconStyle) {
        switch style {
        case .normal:
            bussinessIcon.backgroundColor = UIColor.clear
            bussinessIcon.layer.cornerRadius = 0
            bussinessIcon.clipsToBounds = false
        case .B2C(let cornerRadius):
            bussinessIcon.backgroundColor = UIColor.ud.primaryOnPrimaryFill
            bussinessIcon.layer.cornerRadius = cornerRadius
            bussinessIcon.clipsToBounds = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func redPacketDidTapped(_ gesture: UIGestureRecognizer) {
        self.tapAction?()
    }

    func updateExclusiveAvatarList(_ previewChatters: [Chatter]) {
        let configs = RedPacketExclusiveAvatarLayoutEngine.layout(previewChatters, containerWidth: self.bounds.width - self.centerStackHorizontalMargin * 2)
        self.exclusiveAvatarListView.update(configs)
    }
}
