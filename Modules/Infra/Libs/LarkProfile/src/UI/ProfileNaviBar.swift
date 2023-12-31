//
//  ProfileNaviBar.swift
//  LarkProfile
//
//  Created by Hayden Wang on 2021/7/14.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignIcon

public final class ProfileNaviBar: UIView {

    public var barTapHandle: (() -> (Void))?

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private lazy var barView: UIView = {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(barViewTapped))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    public lazy var backButton: UIButton = {
        let button = UIButton()
        button.tintColor = UIColor.ud.iconN1
        return button
    }()

    private lazy var centerContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }()

    private lazy var rightContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 20
        return stack
    }()

    public lazy var avatarView: ProfileAvatarView = {
        let avatar = ProfileAvatarView()
        avatar.borderColor = UIColor.ud.N00.alwaysLight
        avatar.borderWidth = 1.5
        return avatar
    }()

    public lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private var rightButtons: [UIButton] = [] {
        didSet {
            for button in oldValue {
                button.removeFromSuperview()
            }
            for button in rightButtons {
                if let normalIcon = button.image(for: .normal) {
                    let colorizedIcon = normalIcon.ud.resized(to: Cons.iconSize)
                        .withRenderingMode(.alwaysTemplate)
                    button.setImage(colorizedIcon, for: .normal)
                }
                button.setImage(nil, for: .highlighted)
                button.snp.makeConstraints { make in
                    make.size.equalTo(Cons.iconSize)
                }
                button.tintColor = isBarHidden ? UIColor.ud.primaryOnPrimaryFill : UIColor.ud.iconN1
                rightContainer.addArrangedSubview(button)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(backgroundView)
        addSubview(barView)
        addSubview(backButton)
        addSubview(centerContainer)
        addSubview(rightContainer)
        centerContainer.addArrangedSubview(avatarView)
        centerContainer.addArrangedSubview(titleLabel)
    }

    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        barView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(Cons.barHeight)
            make.top.equalTo(safeAreaLayoutGuide)
        }
        backButton.snp.makeConstraints { make in
            make.centerY.equalTo(barView)
            make.size.equalTo(Cons.iconSize)
            make.leading.equalToSuperview().offset(Cons.hMargin)
        }
        centerContainer.snp.makeConstraints { make in
            /*
            make.centerY.equalTo(barView)
            make.leading.equalTo(backButton.snp.trailing).offset(Cons.containerMargin)
            make.trailing.lessThanOrEqualTo(rightContainer.snp.leading).offset(-Cons.containerMargin)
             */
            make.centerY.equalTo(barView)
            make.leading.equalTo(backButton.snp.trailing).offset(Cons.containerMargin/2)
            make.trailing.equalTo(rightContainer.snp.leading).offset(-Cons.containerMargin)
        }
        rightContainer.snp.makeConstraints { make in
            make.centerY.equalTo(barView)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
        }
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(Cons.avatarSize)
        }
    }

    private func setupAppearance() {
        centerContainer.alpha = 0
    }

    private var isBarHidden = false
    private var prevProgress: CGFloat = -1

    @objc
    private func barViewTapped() {
        self.barTapHandle?()
    }
}

public extension ProfileNaviBar {

    /// Set navigation bar appearance by sliding progress.
    /// - Parameter progress: A CGFloat number ranges from 0 to 1.
    public func setAppearance(byProgress progress: CGFloat) {
        guard progress != prevProgress else { return }
        backgroundView.alpha = progress
        if progress > prevProgress, progress == 1.0 {
            centerContainer.alpha = 0
            centerContainer.transform = CGAffineTransform(translationX: 0, y: 5)
            UIView.animate(withDuration: 0.2) {
                self.centerContainer.alpha = 1
                self.centerContainer.transform = .identity
            }
        } else if progress < prevProgress, prevProgress == 1.0 {
            centerContainer.alpha = 1
            centerContainer.transform = .identity
            UIView.animate(withDuration: 0.2) {
                self.centerContainer.alpha = 0
                self.centerContainer.transform = CGAffineTransform(translationX: 0, y: 5)
            }
        }
        prevProgress = progress
    }

    func setNaviButtonStyle(_ style: UIStatusBarStyle) {
        switch style {
        case .lightContent:
            backButton.tintColor = UIColor.ud.primaryOnPrimaryFill
            for rightButton in rightButtons {
                rightButton.tintColor = UIColor.ud.primaryOnPrimaryFill
            }
        default:
            backButton.tintColor = UIColor.ud.iconN1
            for rightButton in rightButtons {
                rightButton.tintColor = UIColor.ud.iconN1
            }
        }
    }

    func setRightButtons(_ buttons: [UIButton]) {
        self.rightButtons = buttons
    }
}

extension ProfileNaviBar {

    enum Cons {
        static var hMargin: CGFloat = 14
        static var containerMargin: CGFloat = 16
        static var iconSize: CGSize = CGSize(width: 24, height: 24)
        static var avatarSize: CGFloat = 25.5
        static var mobileBarHeight: CGFloat = 44
        static var padBarHeight: CGFloat = 50
        static var barHeight: CGFloat = Display.pad ? Cons.padBarHeight : Cons.mobileBarHeight
    }
}
