//
//  NewProfileView.swift
//  LarkProfile
//
//  Created by Yuri on 2022/8/17.
//

import Foundation
import UIKit

final class NewProfileView: ProfileView {
    
    lazy var statusView = ProfileStatusView()
    
    private let newNameTagView = NewNameTagView()
    override var nameTagView: NameTagView {
        get { newNameTagView }
        set {}
    }
    
    var didPushUserDescriptionHandler: (() -> Void)?
    
    override func setup() {
        setupSubviews()
        setupDefaultConstraints()
    }
    override func setupBackgroundView() {
        backgroundImageView = ProfileBackgroundView(frame: .zero)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.isUserInteractionEnabled = true
        backgroundImageView.clipsToBounds = true
        backgroundImageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        headerView.addSubview(backgroundImageView)
    }
    
    override func setUserInfo(_ info: ProfileUserInfo) {
        setUserName(info)
        setUserTags(info)
        setFocusStatus(info)
        setUserCompany(info)
        setUserCustomBadges(info)
        setMetaUnitDescription(info)
        segmentedView.userID = info.id
    }
    
    func setupAvatarView(imageView: UIView) {
        avatarWrapperView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // nolint: duplicated_code - 本次需求没有QA，为了避免产生问题，会在后期FG下线技术需求统一处理
    private func setupDefaultConstraints() {
        navigationBar.snp.makeConstraints { make in
            make.top.left.trailing.equalToSuperview()
        }
        segmentedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(infoContentView.snp.top).offset(Cons.infoCornerRadius)
        }
        avatarWrapperView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Cons.avatarMargin)
            make.centerY.equalTo(infoContentView.snp.top)
            make.width.height.equalTo(Cons.avatarSize)
        }
        infoContentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(Cons.bgImageHeight - Cons.infoCornerRadius)
        }
        focusView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-20)
            make.leading.greaterThanOrEqualTo(avatarWrapperView.snp.trailing).offset(24)
        }
        nameTagView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Cons.avatarSize / 2 + 12)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
        }
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(nameTagView.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(16)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
        }
        buttonsContainerStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        customBadgeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.bottom.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.height.equalTo(18)
        }
        addContactView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        applyCommunicationView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        gradientMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        headerView.snp.makeConstraints {
            $0.bottom.equalTo(infoContentView)
        }
    }
    
    override func setupConstraints() {}
    
    func updateUserDescription(desc: ProfileState.UserDescription?) {
        if let desc = desc {
            if statusView.superview == nil {
                statusContainer.addSubview(statusView)
                statusView.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(8)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
            statusContainer.isHidden = false
            statusView.setStatus(originText: desc.text, attributedText: desc.attrText,
                                 urlRangeMap: desc.urlRanges ?? [:],
                                 textUrlRangeMap: desc.textRanges ?? [:],
                                 pushCallback: didPushUserDescriptionHandler)
        } else {
            statusContainer.isHidden = true
        }
    }
    
    override func setUserName(_ info: ProfileUserInfo) {
        // 姓名
        guard nameTagView is NewNameTagView else { return }
        if info.alias.isEmpty {
            navigationBar.titleLabel.text = info.name
            newNameTagView.update(name: info.name, tagViews: info.nameTag)
            aliasView.setAlias("")
        } else {
            navigationBar.titleLabel.text = info.alias
            newNameTagView.update(name: info.alias, tagViews: info.nameTag)
            aliasView.setAlias(info.name)
        }

        aliasView.isHidden = info.pronouns.isEmpty && info.alias.isEmpty
        aliasView.setPronouns(info.pronouns)
    }

    override func setUserTags(_ info: ProfileUserInfo) {}
}
