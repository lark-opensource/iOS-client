//
//  OrganizableTasklistCell.swift
//  Todo
//
//  Created by wangwanxin on 2023/10/23.
//

import Foundation
import UniverseDesignFont
import LarkBizAvatar
import UniverseDesignTag
import LarkDocsIcon

final class OrganizableTasklistCell: UICollectionViewCell {

    var viewData: OrganizableTasklistItemData? {
        didSet {
            guard let viewData = viewData else { return }
            if let builder = viewData.leadingIconBuilder, let userResolver = viewData.userResolver {
                leadingImageView.isHidden = false
                leadingImageView.di.setIconImage(iconBuild: builder, userResolver: userResolver)
            } else {
                leadingImageView.isHidden = true
            }

            titleLabel.text = viewData.title

            if let tailingIcon = viewData.tailingIcon {
                tailingImageView.isHidden = false
                tailingImageView.image = tailingIcon
            } else {
                tailingImageView.isHidden = true
            }

            userView.snp.remakeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                make.width.equalTo(viewData.userInfo?.preferredMaxLayoutWidth ?? .zero)
            }
            userView.viewData = viewData.userInfo

            if let sectionData = viewData.sectionInfos, sectionData.isValid {
                userSectionDividingLine.isHidden = false
                sectionView.isHidden = false
                userSectionDividingLine.snp.remakeConstraints { make in
                    make.left.equalTo(userView.snp.right).offset(OrganizableTasklistItemData.Config.itemSpace)
                    make.width.equalTo(1)
                    make.height.equalTo(12)
                    make.centerY.equalToSuperview()
                }
                sectionView.snp.remakeConstraints { make in
                    make.left.equalTo(userSectionDividingLine.snp.right).offset(OrganizableTasklistItemData.Config.itemSpace)
                    make.width.equalTo(sectionData.preferredMaxLayoutWidth)
                    make.height.equalTo(20)
                    make.centerY.equalToSuperview()
                }
                sectionView.viewData = sectionData
            } else {
                userSectionDividingLine.isHidden = true
                sectionView.isHidden = true
            }
            invalidateIntrinsicContentSize()
        }
    }

    private var leadingImageView = UIImageView()

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var firstLineStackView = getStackView()

    private lazy var secondLineView = UIView()

    private lazy var userView = OrganizableTaskListUserView()

    private lazy var userSectionDividingLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var bottomDividingLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    private lazy var sectionView = OrganizableTasklistSectionView()

    private lazy var tailingImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(leadingImageView)
        contentView.addSubview(firstLineStackView)
        contentView.addSubview(secondLineView)
        contentView.addSubview(bottomDividingLine)
        secondLineView.addSubview(userView)
        secondLineView.addSubview(userSectionDividingLine)
        secondLineView.addSubview(sectionView)

        firstLineStackView.addArrangedSubview(titleLabel)
        firstLineStackView.addArrangedSubview(tailingImageView)
        tailingImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        leadingImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(OrganizableTasklistItemData.Config.padding)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(OrganizableTasklistItemData.Config.iconSize)
        }
        firstLineStackView.snp.makeConstraints { make in
            make.left.equalTo(leadingImageView.snp.right).offset(OrganizableTasklistItemData.Config.iconContentSpace)
            make.top.equalToSuperview().offset(OrganizableTasklistItemData.Config.padding)
            make.right.equalToSuperview().offset(-OrganizableTasklistItemData.Config.padding)
            make.height.equalTo(24)
        }
        secondLineView.snp.makeConstraints { make in
            make.top.equalTo(firstLineStackView.snp.bottom).offset(4)
            make.left.equalTo(firstLineStackView.snp.left)
            make.right.equalTo(firstLineStackView.snp.right)
            make.height.equalTo(24)
        }

        userSectionDividingLine.snp.makeConstraints { make in
            make.height.equalTo(12)
            make.width.equalTo(1)
        }

        bottomDividingLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getStackView() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }

}

final class OrganizableTasklistSectionView: UIView {

    private let space = 4.0

    var viewData: OrganizableTasklistSectionData? {
        didSet {
            guard let viewData = viewData, let names = viewData.names else { return }
            subviews.forEach { $0.removeFromSuperview() }
            let maxWidth = viewData.preferredMaxLayoutWidth
            var leftMaxWidth = maxWidth, xPoint = 0.0
            for (index, value) in names.enumerated() {
                // 没有空间的时候退出
                if leftMaxWidth <= 0 { break }
                let tagView = UDTag(configuration: .text(value, tagSize: .mini))
                let tagWidth = tagView.intrinsicContentSize.width
                // 剩余数字,最小为1
                let leftCount = names.count - index - 1
                let countTagView = UDTag(configuration: .text("+\(max(names.count - index - 1, 1))", tagSize: .mini))
                let countWidth = countTagView.intrinsicContentSize.width
                if leftMaxWidth > tagWidth + countWidth + space {
                    // 数字+tag能放的下
                    addSubview(tagView)
                    tagView.snp.makeConstraints { make in
                        make.left.equalToSuperview().offset(xPoint)
                        make.top.bottom.equalToSuperview()
                        make.width.equalTo(tagWidth)
                    }
                    xPoint += tagWidth + space
                    leftMaxWidth = maxWidth - xPoint
                } else {
                    // 两个放不下，则需要优先放数字，剩下的放tag
                    if xPoint > 0 {
                        let countTagView = UDTag(configuration: .text("+\(max(names.count - index, 1))", tagSize: .mini))
                        let countWidth = countTagView.intrinsicContentSize.width
                        addSubview(countTagView)
                        countTagView.snp.makeConstraints { make in
                            make.left.equalToSuperview().offset(xPoint)
                            make.top.bottom.equalToSuperview()
                            make.width.equalTo(countWidth)
                        }
                    } else {
                        // 一个都没有时候, 说明第一个很长
                        if leftCount > 0 {
                            addSubview(countTagView)
                            countTagView.snp.makeConstraints { make in
                                make.top.right.bottom.equalToSuperview()
                                make.width.equalTo(countWidth)
                            }
                        }
                        addSubview(tagView)
                        tagView.snp.makeConstraints { make in
                            make.left.equalToSuperview()
                            if leftCount > 0 {
                                make.right.equalTo(countTagView.snp.left).offset(-space)
                            } else {
                                make.right.equalToSuperview()
                            }
                            make.top.bottom.equalToSuperview()
                        }
                    }
                    // 放不下则直接设置负数
                    leftMaxWidth = -1
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

final class OrganizableTaskListUserView: UIView {

    var viewData: OrganizableTasklistUserData? {
        didSet {
            guard let viewData = viewData else { return }
            if let avatarData = viewData.avatar {
                avatar.isHidden = false
                avatar.setAvatarByIdentifier(
                    avatarData.avatarId,
                    avatarKey: avatarData.avatarKey,
                    avatarViewParams: .init(
                        sizeType: .size(OrganizableTasklistItemData.Config.userIconSize.width),
                        format: .webp
                    )
                )
            } else {
                avatar.isHidden = true
            }
            titleLabel.text = viewData.name
            invalidateIntrinsicContentSize()
        }
    }

    private lazy var avatar: BizAvatar = BizAvatar()

    private lazy var titleLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = OrganizableTasklistItemData.Config.userFont
        nameLabel.textColor = UIColor.ud.textCaption
        nameLabel.numberOfLines = 1
        return nameLabel
    }()


    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(avatar)
        addSubview(titleLabel)

        avatar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(OrganizableTasklistItemData.Config.userPadding)
            make.left.equalToSuperview().offset(OrganizableTasklistItemData.Config.userPadding)
            make.bottom.equalToSuperview().offset(-OrganizableTasklistItemData.Config.userPadding)
            make.size.equalTo(OrganizableTasklistItemData.Config.userIconSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(avatar.snp.right).offset(OrganizableTasklistItemData.Config.userPadding + OrganizableTasklistItemData.Config.userIconTextSpace)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
