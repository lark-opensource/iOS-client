//
//  MultiLanguageItemView.swift
//  LarkMine
//
//  Created by ByteDance on 2023/10/8.
//

import Foundation
import UIKit
import UniverseDesignCheckBox
import LarkUIKit
import ByteDanceKit
import RxSwift
import RxCocoa

final public class MultiLanguageOptionView: UIView {
    public let tapRelay = PublishRelay<Void>()

    public var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    public var userName: String = "" {
        didSet {
            userNameLabel.text = userName
        }
    }

    public var isSelected: Bool = false {
        didSet {
            checkBox.isSelected = isSelected
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(checkBox)
        addSubview(titleLabel)
        addSubview(contentView)
        contentView.addSubview(blueView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(userNameLabel)

        checkBox.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.checkBoxLeftPadding)
            make.top.equalToSuperview().offset(Const.checkBoxTopPadding)
            make.size.equalTo(CGSize(width: Const.checkBoxSize, height: Const.checkBoxSize))
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(checkBox.snp.right).offset(Const.checkBoxRightPadding)
            make.centerY.equalTo(checkBox)
        }

        contentView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.contentViewLeftPadding)
            make.top.equalTo(checkBox.snp.bottom).offset(Const.contentViewTopPading)
            make.height.equalTo(Const.contentViewHeight)
            make.right.equalToSuperview().offset(Const.contentViewRightPadding)
            make.bottom.equalToSuperview()
        }

        blueView.snp.makeConstraints { make in
            make.left.top.equalTo(1)
            make.right.equalTo(-1)
            make.height.equalTo(Const.gradientViewHeight)
        }

        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.avatarImageViewLeftPadding)
            make.size.equalTo(CGSize(width: Const.avatarImageViewSize, height: Const.avatarImageViewSize))
            make.centerY.equalTo(blueView.snp.bottom)
        }

        userNameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView)
            make.height.equalTo(Const.userNameLabelHeight)
            make.top.equalTo(avatarImageView.snp.bottom).offset(Const.userNameLabelTopMargin)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        addGestureRecognizer(tap)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        contentView.layer.borderColor = UIColor.ud.lineDividerDefault.cgColor
    }

    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        if checkBox.isSelected {
            return
        }
        tapRelay.accept(())
    }

    private lazy var checkBox: UDCheckBox = {
        let checkbox = UDCheckBox()
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body2
        label.textAlignment = .left
        return label
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.ud.lineDividerDefault.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = Const.cornerRadius
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var blueView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.B100
        view.layer.cornerRadius = Const.cornerRadius - 1
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.image = BundleResources.LarkProfile.multi_language_avatar
        return imageView
    }()

    private lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.headline
        label.textColor = UIColor.ud.textTitle
        return label
    }()
}

extension MultiLanguageOptionView {
    enum Const {
        public static let checkBoxSize: CGFloat = 20
        public static let checkBoxLeftPadding: CGFloat = 21
        public static let checkBoxTopPadding: CGFloat = 24
        public static let checkBoxRightPadding: CGFloat = 8
        public static let contentViewTopPading: CGFloat = 13
        public static let contentViewLeftPadding: CGFloat = 50
        public static let contentViewRightPadding: CGFloat = -20
        public static let contentViewHeight: CGFloat = 124
        public static let gradientViewHeight: CGFloat = 52
        public static let cornerRadius: CGFloat = 8
        public static let avatarImageViewLeftPadding: CGFloat = 19
        public static let avatarImageViewSize: CGFloat = 54
        public static let userNameLabelHeight: CGFloat = 24
        public static let userNameLabelTopMargin: CGFloat = 8
    }
}
