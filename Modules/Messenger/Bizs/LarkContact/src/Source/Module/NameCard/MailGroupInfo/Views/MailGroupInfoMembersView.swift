//
//  MailGroupInfoMembersView.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/20.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignIcon
import LarkBizAvatar

final class MemberAvatarCell: UICollectionViewCell {
    static var reuseIdentifier: String { return String(describing: UICollectionViewCell.self) }

    fileprivate var avatar: BizAvatar = .init(frame: .zero)
    override init(frame: CGRect) {
        super.init(frame: frame)
        avatar = BizAvatar()
        contentView.addSubview(avatar)
        avatar.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private let kAvatarWH: CGFloat = 32

protocol MailGroupInfoMemberViewItem {
    var avatarId: String { get }

    var avatarKey: String { get }

    var avatarImage: UIImage? { get }
}

final class MailGroupInfoMemberView: UIView {
    fileprivate func buttonWithBorder(_ key: UDIconType) -> UIButton {
        let button = UIButton()
        let color = UIColor.ud.iconN3
        let iconImg = UDIcon.getIconByKey(key, size: CGSize(width: 16, height: 16)).ud.withTintColor(color)
        button.setImage(iconImg, for: .normal)
        button.setImage(iconImg, for: .highlighted)
        button.setImage(iconImg, for: .selected)
        button.layer.cornerRadius = kAvatarWH / 2.0
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
    fileprivate var memberItems: [MailGroupInfoMemberViewItem] = []
    fileprivate var hasAccess: Bool = false
    var addNewMember: (() -> Void)?
    var deleteMemberHandler: (() -> Void)?
    var selectedMemeber: ((String) -> Void)?
    let leftPadding: CGFloat = 16
    let rightPadding: CGFloat = 16
    let tableViewPadding: CGFloat = 16 // 改动iOS15设置页风格后，cell两边多了padding
    let minimalIconSpacing: CGFloat = 12 // 图标之间允许的最小间距

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
            maker.width.greaterThanOrEqualTo(kAvatarWH)
        }
        collectionView.setContentCompressionResistancePriority(.required, for: .horizontal)

        addButton.addTarget(self, action: #selector(addMember), for: .touchUpInside)
        addSubview(addButton)
        addButton.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalTo(collectionView.snp.right)
            maker.width.equalTo(kAvatarWH)
        }

        deleteButton.addTarget(self, action: #selector(deleteMember), for: .touchUpInside)
        addSubview(deleteButton)
        deleteButton.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.right.lessThanOrEqualTo((-rightPadding))
            maker.left.equalTo(addButton.snp.right).offset(minimalIconSpacing)
            maker.width.equalTo(kAvatarWH)
        }
    }

    func getCollectionWidthAndIconSpacing(_ maxCellContentWidth: CGFloat,
                                          numOfAvatar: Int,
                                          isShowAddButton: Bool,
                                          isShowDeleteButton: Bool ) -> (CGFloat, CGFloat) {
        let totalIcons = numOfAvatar + (hasAccess ? 1 : 0) + (isShowDeleteButton ? 1 : 0)
        let realIconSpacing: CGFloat = minimalIconSpacing
        let collectionViewWidth: CGFloat
        if (kAvatarWH + realIconSpacing) * CGFloat(totalIcons) <= maxCellContentWidth { // 图标太少不足以撑满时
            collectionViewWidth = CGFloat(numOfAvatar) * (kAvatarWH + realIconSpacing)
        } else { // 图标足够多
            let numOfIconShowed: Int = Int(floor(maxCellContentWidth / (kAvatarWH + realIconSpacing)))
            let numOfAvatarShowed: Int = numOfIconShowed - (hasAccess ? 1 : 0) - (isShowDeleteButton ? 1 : 0)
            collectionViewWidth = CGFloat(numOfAvatarShowed) * (kAvatarWH + realIconSpacing)
        }
        return (collectionViewWidth, realIconSpacing)
    }

    func set(memberItems: [MailGroupInfoMemberViewItem],
             hasAccess: Bool,
             width: CGFloat,
             isShowDeleteButton: Bool) {
        self.memberItems = memberItems
        self.hasAccess = hasAccess
        let maxCellContentWidth: CGFloat = width - 2 * tableViewPadding - leftPadding - rightPadding
        let (collectionViewWidth, realIconSpacing) = getCollectionWidthAndIconSpacing(maxCellContentWidth,
                                                                                      numOfAvatar: memberItems.count,
                                                                                      isShowAddButton: hasAccess,
                                                                                      isShowDeleteButton: isShowDeleteButton)

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = realIconSpacing
        }

        addButton.snp.updateConstraints { (maker) in
            maker.width.equalTo(hasAccess ? kAvatarWH : 0)
        }
        deleteButton.snp.updateConstraints { (maker) in
            maker.width.equalTo(isShowDeleteButton ? kAvatarWH : 0)
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
        layout.itemSize = CGSize(width: kAvatarWH, height: kAvatarWH)
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

extension MailGroupInfoMemberView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < memberItems.count {
            selectedMemeber?(memberItems[indexPath.item].avatarId)
        }
    }
}

extension MailGroupInfoMemberView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return memberItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MemberAvatarCell.reuseIdentifier,
            for: indexPath)

        if let cell = cell as? MemberAvatarCell, indexPath.item < memberItems.count, indexPath.item < memberItems.count {
            if let image = memberItems[indexPath.item].avatarImage {
                cell.avatar.image = image
            } else {
                cell.avatar.setAvatarByIdentifier(memberItems[indexPath.item].avatarId,
                                                  avatarKey: memberItems[indexPath.item].avatarKey,
                                                  avatarViewParams: .defaultThumb)
            }
            return cell
        }
        return cell
    }
}
