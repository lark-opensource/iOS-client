//
//  ChatInfoMemberView.swift
//  Lark
//
//  Created by K3 on 2018/4/28.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkCore
import LarkBizAvatar
import UniverseDesignIcon

private let avatarWH: CGFloat = 32
private let avatarSpace: CGFloat = 12

final class MemberAvatarCell: UICollectionViewCell {
    static var reuseIdentifier: String { return String(describing: UICollectionViewCell.self) }

    fileprivate var avatar: LarkMedalAvatar!
    override init(frame: CGRect) {
        super.init(frame: frame)
        avatar = LarkMedalAvatar()
        contentView.addSubview(avatar)
        avatar.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 新版设置页新view
final class NewChatInfoMemberView: UIView {
    fileprivate func buttonWithBorder(_ key: UDIconType) -> UIButton {
        let button = UIButton()
        let color = UIColor.ud.iconN3
        let iconImg = UDIcon.getIconByKey(key, size: CGSize(width: 16, height: 16)).ud.withTintColor(color)
        button.setImage(iconImg, for: .normal)
        button.setImage(iconImg, for: .highlighted)
        button.setImage(iconImg, for: .selected)
        button.layer.cornerRadius = avatarWH / 2.0
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(color)
        button.adjustsImageWhenDisabled = false
        return button
    }
    fileprivate lazy var addButton: UIButton = {
        let button = buttonWithBorder(.addOutlined)
        return button
    }()
    fileprivate lazy var deleteButton: UIButton = {
        let button = buttonWithBorder(.reduceOutlined)
        return button
    }()
    fileprivate var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    fileprivate var avatarModels: [AvatarModel] = []
    fileprivate var memberIds: [String]!
    fileprivate var hasAccess: Bool = false
    var addNewMember: (() -> Void)?
    var deleteMemberHandler: (() -> Void)?
    var selectedMemeber: ((String) -> Void)?
    let leftPadding: CGFloat = 16
    let rightPadding: CGFloat = 16
    let tableViewPadding: CGFloat = 16 // 改动iOS15设置页风格后，cell两边多了padding
    let minimalIconSpacing: CGFloat = 12 // 图标之间允许的最小间距
    let maximalIconSpacing: CGFloat = 16 // 图标之间允许的最大间距

    override init(frame: CGRect) {
        super.init(frame: frame)

        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: defaultLayout())
        collectionView.isScrollEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MemberAvatarCell.self, forCellWithReuseIdentifier: MemberAvatarCell.reuseIdentifier)
        collectionView.backgroundColor = UIColor.clear
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(leftPadding)
            maker.width.greaterThanOrEqualTo(avatarWH)
        }
        collectionView.setContentCompressionResistancePriority(.required, for: .horizontal)

        addButton.addTarget(self, action: #selector(addMember), for: .touchUpInside)
        addSubview(addButton)
        addButton.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalTo(collectionView.snp.right)
            maker.width.equalTo(avatarWH)
        }

        deleteButton.addTarget(self, action: #selector(deleteMember), for: .touchUpInside)
        addSubview(deleteButton)
        deleteButton.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.right.lessThanOrEqualTo((-rightPadding))
            maker.left.equalTo(addButton.snp.right).offset(minimalIconSpacing)
            maker.width.equalTo(avatarWH)
        }
    }

    func getCollectionWidthAndIconSpacing(_ maxCellContentWidth: CGFloat,
                                          numOfAvatar: Int,
                                          isShowAddButton: Bool,
                                          isShowDeleteButton: Bool ) -> (CGFloat, CGFloat) {

        let totalIcons = numOfAvatar + (hasAccess ? 1 : 0) + (isShowDeleteButton ? 1 : 0)
        let realIconSpacing: CGFloat
        let collectionViewWidth: CGFloat
        if (avatarWH + maximalIconSpacing) * CGFloat(totalIcons) <= maxCellContentWidth { // 图标太少不足以撑满时
            collectionViewWidth = CGFloat(numOfAvatar) * (avatarWH + maximalIconSpacing)
            realIconSpacing = maximalIconSpacing
        } else { // 图标足够多，间距平分
            let numOfIconShowed: Int = Int(maxCellContentWidth / (avatarWH + minimalIconSpacing))
            let numOfAvatarShowed: Int = numOfIconShowed - (hasAccess ? 1 : 0) - (isShowDeleteButton ? 1 : 0)
            realIconSpacing = (maxCellContentWidth - CGFloat(numOfIconShowed) * avatarWH) / CGFloat(numOfIconShowed - 1)
            collectionViewWidth = CGFloat(numOfAvatarShowed) * (avatarWH + realIconSpacing)
        }
        return (collectionViewWidth, realIconSpacing)
    }

    func set(avatarModels: [AvatarModel],
             memberIds: [String],
             hasAccess: Bool,
             width: CGFloat,
             isShowDeleteButton: Bool) {
        self.avatarModels = avatarModels
        self.memberIds = memberIds
        self.hasAccess = hasAccess
        let maxCellContentWidth: CGFloat = width - 2 * tableViewPadding - leftPadding - rightPadding
        let (collectionViewWidth, realIconSpacing) = getCollectionWidthAndIconSpacing(maxCellContentWidth,
                                                                                      numOfAvatar: avatarModels.count,
                                                                                      isShowAddButton: hasAccess,
                                                                                      isShowDeleteButton: isShowDeleteButton)

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = realIconSpacing
        }

        addButton.snp.updateConstraints { (maker) in
            maker.width.equalTo(hasAccess ? avatarWH : 0)
        }
        deleteButton.snp.updateConstraints { (maker) in
            maker.width.equalTo(isShowDeleteButton ? avatarWH : 0)
            maker.left.equalTo(addButton.snp.right).offset(isShowDeleteButton ? realIconSpacing : 0)
        }
        collectionView.snp.remakeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(leftPadding)
            maker.width.equalTo(collectionViewWidth)
        }

        collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func defaultLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: avatarWH, height: avatarWH)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = minimalIconSpacing
        return layout
    }

    @objc
    fileprivate func addMember() {
        addNewMember?()
    }

    @objc
    fileprivate func deleteMember() {
        deleteMemberHandler?()
    }

    // 防止CollectionView空白处拦截点击事件
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView == self.collectionView ? nil : hitView
    }
}

extension NewChatInfoMemberView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < memberIds.count {
            selectedMemeber?(memberIds[indexPath.item])
        }
    }
}

extension NewChatInfoMemberView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return avatarModels.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MemberAvatarCell.reuseIdentifier,
            for: indexPath)

        if let cell = cell as? MemberAvatarCell, indexPath.item < avatarModels.count, indexPath.item < memberIds.count {
            cell.avatar.setAvatarByIdentifier(memberIds[indexPath.item],
                                              avatarKey: avatarModels[indexPath.item].avatarKey,
                                              medalKey: avatarModels[indexPath.item].medalKey,
                                              medalFsUnit: "",
                                              scene: .Chat,
                                              avatarViewParams: .defaultThumb)
            return cell
        }
        return cell
    }
}
