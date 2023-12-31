//
//  TeamMemberCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/4.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import LarkBizAvatar

typealias TeamCellTapHandler = (_ cell: UITableViewCell) -> Void

// MARK: - 成员 - item
struct TeamMemberCellViewModel: TeamCellViewModelProtocol {
    var type: TeamCellType
    var cellIdentifier: String
    var style: TeamCellSeparaterStyle
    var title: String
    var descriptionText: String
    var memberList: [TeamMemberHorizItem]
    var isShowMember: Bool
    var isShowAddButton: Bool
    var isShowDeleteButton: Bool
    var countText: String

    var tapHandler: TeamCellTapHandler
    var addNewMember: TeamCellTapHandler
    var deleteMember: TeamCellTapHandler?
    var selectedMember: (TeamMemberHorizItem) -> Void
}

private let avatarWH: CGFloat = 32
private let avatarSpace: CGFloat = 12

// MARK: - 成员 - cell
final class TeamMemberCell: TeamBaseCell {
    fileprivate var titleLabel: UILabel = .init()
    fileprivate var countLabel: UILabel = .init()
    var arrow = UIImageView(image: Resources.right_arrow)
    fileprivate var membersView: TeamMemberView = .init(frame: .zero)
    private var maxWidth: CGFloat = UIScreen.main.bounds.width

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = UIColor.ud.textPlaceholder
        countLabel.textAlignment = .right

        contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { (maker) in
            maker.top.right.equalToSuperview().inset(UIEdgeInsets(top: 13.5, left: 0, bottom: 0, right: 31))
            maker.height.equalTo(20)
        }

        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 0, right: 0))
            maker.right.lessThanOrEqualTo(countLabel.snp.left).offset(-12)
            maker.height.equalTo(22.5)
        }

        membersView = TeamMemberView()
        contentView.addSubview(membersView)
        membersView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 43, left: 0, bottom: 14, right: 0))
            maker.height.equalTo(32)
        }

        contentView.addSubview(arrow)
        arrow.snp.remakeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel)
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? TeamMemberCellViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        countLabel.text = item.countText
        membersView.set(memberList: item.memberList,
                        width: self.maxWidth,
                        isShowAddButton: item.isShowAddButton,
                        isShowDeleteButton: item.isShowDeleteButton)
        membersView.addNewMember = { [weak self] in
            if let `self` = self {
                item.addNewMember(self)
            }
        }
        membersView.deleteMemberHandler = { [weak self] in
            if let `self` = self {
                item.deleteMember?(self)
            }
        }
        membersView.selectedMemeber = item.selectedMember
        layoutSeparater(item.style)
    }

    override func updateAvailableMaxWidth(_ width: CGFloat) {
        self.maxWidth = width
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let memberItem = item as? TeamMemberCellViewModel {
            memberItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

final class TeamMemberView: UIView {
    fileprivate var addButton: UIButton = {
        let button = UIButton()
        button.setImage(Resources.icon_circle_add, for: .normal)
        button.setImage(Resources.icon_circle_add, for: .selected)
        button.adjustsImageWhenDisabled = false
        return button
    }()
    fileprivate var deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(Resources.icon_circle_delete, for: .normal)
        button.setImage(Resources.icon_circle_delete, for: .selected)
        button.adjustsImageWhenDisabled = false
        return button
    }()
    fileprivate var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    fileprivate var memberList: [TeamMemberHorizItem] = []
    fileprivate var hasAccess: Bool = false
    var addNewMember: (() -> Void)?
    var deleteMemberHandler: (() -> Void)?
    var selectedMemeber: ((TeamMemberHorizItem) -> Void)?
    let leftPadding: CGFloat = 16
    let rightPadding: CGFloat = 20
    let itemOffset: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)

        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: defaultLayout())
        collectionView.isScrollEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TeamMemberAvatarCell.self, forCellWithReuseIdentifier: TeamMemberAvatarCell.reuseIdentifier)
        collectionView.backgroundColor = UIColor.clear
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
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
            maker.right.lessThanOrEqualTo(-20)
            maker.left.equalTo(addButton.snp.right).offset(12)
            maker.width.equalTo(avatarWH)
        }
    }

    func set(memberList: [TeamMemberHorizItem],
             width: CGFloat,
             isShowAddButton: Bool,
             isShowDeleteButton: Bool) {
        self.memberList = memberList
        let addButtonWidth: CGFloat = isShowAddButton ? avatarWH : 0
        let deleteButtonWidthAndOffset: (CGFloat, CGFloat) = isShowDeleteButton ? (avatarWH, itemOffset) : (0, 0)
        addButton.snp.updateConstraints { (maker) in
            maker.width.equalTo(addButtonWidth)
        }
        deleteButton.snp.updateConstraints { (maker) in
            maker.width.equalTo(deleteButtonWidthAndOffset.0)
            maker.left.equalTo(addButton.snp.right).offset(deleteButtonWidthAndOffset.1)
        }
        // 根据vc宽度进行运算得到能显示的最大宽度
        var maxCollectionViewWidth: CGFloat = width - addButtonWidth - deleteButtonWidthAndOffset.0 - deleteButtonWidthAndOffset.1 - leftPadding - rightPadding
        // 将多余的空间减去, 保证是头像加偏移的整数倍
        maxCollectionViewWidth = CGFloat(CGFloat((Int)(maxCollectionViewWidth / (avatarWH + avatarSpace))) * (avatarWH + avatarSpace))
        // 计算出合适的collectionView宽度
        let collectionViewWidth = min(maxCollectionViewWidth, CGFloat(memberList.count) * (avatarWH + avatarSpace))
        collectionView.snp.remakeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
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
        layout.minimumLineSpacing = 12
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

final class TeamMemberAvatarCell: UICollectionViewCell {
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

    override func prepareForReuse() {
        super.prepareForReuse()
        avatar.image = nil
    }

    func setAvatar(identifier: String, key: String) {
        avatar.image = nil
        avatar.setAvatarByIdentifier(identifier, avatarKey: key, avatarViewParams: .defaultThumb)
    }

    func setAvatar(by image: UIImage) {
        avatar.image = image
    }
}

extension TeamMemberView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < memberList.count {
            selectedMemeber?(memberList[indexPath.item])
        }
    }
}

extension TeamMemberView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return memberList.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TeamMemberAvatarCell.reuseIdentifier,
            for: indexPath)

        if let cell = cell as? TeamMemberAvatarCell, indexPath.item < memberList.count, indexPath.item < memberList.count {
            let item = memberList[indexPath.item]
            cell.setAvatar(identifier: item.memberId, key: item.avatarKey)
            return cell
        }
        return cell
    }
}
