//
//  FeedFilterListCell.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/8.
//

import UIKit
import Foundation
import LarkBizAvatar
import ByteWebImage
import RustPB
import LarkUIKit
import UniverseDesignColor
import LarkOpenFeed

public final class FeedFilterListCell: UITableViewCell {
    static var identifier: String = "FeedFilterListCell"
    private var highlightColor = UIColor.ud.fillHover
    private var selectedColor = UDMessageColorTheme.imFeedFeedFillActive
    private var cellViewModel: FeedFilterListItemInterface?
    private enum CellLayout {
        static let badgeLabelOffset: CGFloat = 4.0
    }

    private lazy var iconButton: UIButton = {
        let button = UIButton()

        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var badgeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .right
        return label
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.setupBackgroundViews(highlightOn: true)
        self.setBackViewLayout(UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8), 6)
        self.setupSubViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        contentView.addSubview(iconButton)
        iconButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.left.equalToSuperview().inset(24)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.iconButton.snp.right).offset(14)
            make.top.bottom.equalToSuperview()
        }

        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.left.equalTo(self.titleLabel.snp.right).offset(CellLayout.badgeLabelOffset)
            make.right.equalToSuperview().inset(24)
            make.top.bottom.equalToSuperview()
        }
    }

    func set(_ cellViewModel: FeedFilterListItemInterface) {
        self.cellViewModel = cellViewModel
        updateCellContent()
    }

    private func updateCellContent() {
        guard let vm = cellViewModel as? FeedFilterListItemModel else { return }

        let needHideBadge = vm.filterType == .done
        badgeLabel.text = !needHideBadge ? vm.unreadContent : ""
        badgeLabel.textColor = vm.selectState ? UIColor.ud.textLinkHover : UIColor.ud.textCaption
        badgeLabel.snp.remakeConstraints { make in
            make.left.equalTo(self.titleLabel.snp.right).offset(vm.unreadContent.isEmpty ? 0 : CellLayout.badgeLabelOffset)
            make.right.equalToSuperview().inset(24)
            make.top.bottom.equalToSuperview()
        }

        let needHint = vm.unread > 0 && ![.delayed, .flag, .done, .mute].contains(vm.filterType)
        titleLabel.text = vm.title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: (vm.selectState || needHint) ? .medium : .regular)
        titleLabel.textColor = vm.selectState ? UIColor.ud.textLinkHover :
                               needHint ? UIColor.ud.textTitle : UIColor.ud.textCaption

        if let source = FeedFilterTabSourceFactory.source(for: vm.filterType) {
            iconButton.setImage(source.normalIcon, for: .normal)
            iconButton.setImage(source.selectedIcon, for: .selected)
        } else {
            iconButton.setImage(Resources.sidebar_filtertab_message, for: .normal)
            iconButton.setImage(Resources.sidebar_filtertab_message_selected, for: .selected)
        }
        iconButton.isSelected = vm.selectState

        setBackViewColor(backgroundColor())
    }

    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if !Display.pad {
            self.setBackViewColor(backgroundColor(highlighted))
        }
    }

    func backgroundColor(_ highlighted: Bool = false) -> UIColor {
        if let selectState = cellViewModel?.selectState, selectState {
            return selectedColor
        } else {
            return highlighted ? self.highlightColor : UIColor.ud.bgBody
        }
    }
}

public final class FeedFilterListSubItemCell: UITableViewCell {
    static var identifier: String = "FeedFilterListSubItemCell"
    private static let downsampleSize = CGSize(width: 20, height: 20)
    private var highlightColor = UIColor.ud.fillHover
    private var selectedColor = UDMessageColorTheme.imFeedFeedFillActive
    private var avatarView = BizAvatar()
    private var iconImageView = UIImageView()
    private var cellViewModel: FeedFilterListItemInterface?
    private enum CellLayout {
        static let badgeLabelOffset: CGFloat = 4.0
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var badgeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .right
        return label
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.setupBackgroundViews(highlightOn: true)
        self.setBackViewLayout(UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8), 6)
        self.setupSubViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(44)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(44)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.avatarView.snp.right).offset(10)
            make.top.bottom.equalToSuperview()
        }

        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.left.equalTo(self.titleLabel.snp.right).offset(CellLayout.badgeLabelOffset)
            make.right.equalToSuperview().inset(24)
            make.top.bottom.equalToSuperview()
        }
    }

    func set(_ cellViewModel: FeedFilterListItemInterface) {
        self.cellViewModel = cellViewModel
        updateCellContent()
    }

    private func updateCellContent() {
        guard let vm = cellViewModel as? FeedFilterListItemModel else { return }

        badgeLabel.text = vm.unreadContent
        badgeLabel.textColor = vm.selectState ? UIColor.ud.textLinkHover : UIColor.ud.textCaption
        badgeLabel.snp.remakeConstraints { make in
            make.left.equalTo(self.titleLabel.snp.right).offset(vm.unreadContent.isEmpty ? 0 : CellLayout.badgeLabelOffset)
            make.right.equalToSuperview().inset(24)
            make.top.bottom.equalToSuperview()
        }

        titleLabel.text = vm.title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: (vm.selectState || vm.unread > 0) ? .medium : .regular)
        titleLabel.textColor = vm.selectState ? UIColor.ud.textLinkHover :
                               (vm.unread > 0 ? UIColor.ud.textTitle : UIColor.ud.textCaption)
        avatarView.backgroundColor = UIColor.clear
        if let avatarInfo = vm.avatarInfo, !avatarInfo.avatarId.isEmpty, !avatarInfo.avatarKey.isEmpty {
            iconImageView.isHidden = true
            avatarView.setAvatarByIdentifier(
                avatarInfo.avatarId,
                avatarKey: avatarInfo.avatarKey,
                scene: .Feed,
                options: [.downsampleSize(Self.downsampleSize)],
                avatarViewParams: .init(sizeType: .size(Self.downsampleSize.width)),
                completion: { result in
                    if case let .failure(error) = result {
                        let errorMsg = "teamAvatarId \(avatarInfo.avatarId), \(error)"
                        let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
                        FeedExceptionTracker.Filter.threeColumns(node: .setAvatarImage, info: info)
                    }
                })
            avatarView.isHidden = false
        } else {
            avatarView.isHidden = true
            iconImageView.image = vm.avatarImage
            iconImageView.isHidden = false
        }

        setBackViewColor(backgroundColor())
    }

    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if !Display.pad {
            self.setBackViewColor(backgroundColor(highlighted))
        }
    }

    func backgroundColor(_ highlighted: Bool = false) -> UIColor {
        if let selectState = cellViewModel?.selectState, selectState {
            return selectedColor
        } else {
            return highlighted ? self.highlightColor : UIColor.ud.bgBody
        }
    }
}
