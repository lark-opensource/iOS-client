//
//  ProfileSectionSkeletonCell.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2022/1/6.
//

import Foundation
import UIKit
import UniverseDesignLoading
import SkeletonView

public enum ProfileSectionSkeletonCellStyle {
    case title
    case content
    case subtitle
}

public final class ProfileSectionSkeletonCell: ProfileSectionTabCell {
    private let gradient = SkeletonGradient(baseColor: UIColor.ud.N200.withAlphaComponent(0.5),
                                            secondaryColor: UIColor.ud.N200)

    lazy var titleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()

    lazy var subTitleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()

    lazy var contentLabel: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()

    lazy var pushView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 9
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()

    private var style: ProfileSectionSkeletonCellStyle = .title

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.showAnimatedGradientSkeleton(usingGradient: gradient)
        self.startSkeletonAnimation()
    }

    override func commonInit() {
        super.commonInit()
        self.contentView.addSubview(titleView)
        self.contentView.addSubview(subTitleView)
        self.contentView.addSubview(contentLabel)
        self.contentView.addSubview(pushView)
        self.isSkeletonable = true
        self.contentView.isSkeletonable = true
        titleView.isSkeletonable = true
        subTitleView.isSkeletonable = true
        contentLabel.isSkeletonable = true
        pushView.isSkeletonable = true
    }

    public func update(style: ProfileSectionSkeletonCellStyle) {
        self.style = style
        self.layoutView()
    }

    private func layoutView() {
        self.stopSkeletonAnimation()
        switch self.style {
        case .title:
            self.titleStyleLayout()
        case .content:
            self.contentStyleLayout()
        case .subtitle:
            self.subtitleStyleLayout()
        }

        self.showAnimatedGradientSkeleton(usingGradient: gradient)
        self.startSkeletonAnimation()
    }

    // nolint: duplicated_code - 方法名类似，误报
    private func titleStyleLayout() {
        self.subTitleView.isHidden = true
        self.contentLabel.isHidden = false
        self.pushView.isHidden = false

        self.titleView.snp.remakeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(75)
            make.height.equalTo(18)
        }

        self.setPushViewLayout()

        self.contentLabel.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(pushView.snp.left).offset(-4)
            make.width.equalTo(38)
            make.height.equalTo(18)
        }
    }

    private func subtitleStyleLayout() {
        self.subTitleView.isHidden = false
        self.contentLabel.isHidden = true
        self.pushView.isHidden = false

        self.titleView.snp.remakeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
            make.width.equalTo(140)
            make.height.equalTo(18)
        }

        self.subTitleView.snp.remakeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(200)
            make.height.equalTo(18)
        }

        self.setPushViewLayout()
    }

    func setPushViewLayout() {
        self.pushView.snp.remakeConstraints { make in
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }

    private func contentStyleLayout() {
        self.subTitleView.isHidden = true
        self.contentLabel.isHidden = false
        self.pushView.isHidden = true

        self.titleView.snp.remakeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(200)
            make.height.equalTo(18)
        }

        self.contentLabel.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(60)
            make.height.equalTo(18)
        }
    }
}
