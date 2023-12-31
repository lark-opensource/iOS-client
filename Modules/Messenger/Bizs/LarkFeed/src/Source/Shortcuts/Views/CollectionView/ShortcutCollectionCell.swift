//
//  ShortcutCollectionCell.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/15.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkRichTextCore
import EETroubleKiller
import LarkUIExtension
import LarkBizAvatar
import Kingfisher
import ByteWebImage
import LarkDocsIcon
import LarkFeedBase
import LarkModel

final class ShortcutCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "ShortcutCell"

    private lazy var avatarView: LarkMedalAvatar = {
        let avatarView = LarkMedalAvatar()
        avatarView.contentMode = .scaleAspectFit
        avatarView.topBadge.setMaxNumber(to: FeedCardAvatarView.topBadgeMaxCount)
        avatarView.topBadge.isZoomable = true
        avatarView.bottomBadge.isZoomable = true
        return avatarView
    }()
    private let nameLabel = UILabel.lu.labelWith(fontSize: ShortcutLayout.labelFont.pointSize, textColor: UIColor.ud.textPlaceholder)

    private(set) var cellViewModel: ShortcutCellViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear

        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(ShortcutLayout.avatarTopInset)
            make.size.equalTo(ShortcutLayout.avatarSize)
        }

        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor.ud.textPlaceholder
        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(avatarView.snp.bottom).offset(6)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }

    /// 从ViewModel中提取信息在Cell上展示
    func set(cellViewModel: ShortcutCellViewModel) {
        // 修改set(cellViewModel:)对ShortcutCellViewModel的字段依赖，需要同步反映在 ShortcutCellViewModel.isEquivalentTo(lhs:rhs:) 判等函数里
        self.cellViewModel = cellViewModel
        nameLabel.text = cellViewModel.renderData.name
        nameLabel.font = ShortcutLayout.labelFont
        nameLabel.textColor = UIColor.ud.textPlaceholder
        if let avatarVM = cellViewModel.renderData.avatarVM {
            setImage(avatarDataSource: avatarVM.centerAvatarDataSource,
                     size: ShortcutLayout.avatarSize,
                     feedId: avatarVM.feedId,
                     feedCardType: avatarVM.feedCardType)
            set(badgeInfo: avatarVM.shortcutBadgeInfo)
            setBoarder(isBorderVisible: avatarVM.isBorderVisible, borderSize: ShortcutLayout.avatarBorderSize)
            set(miniIcon: avatarVM.miniIconProps)
        }
    }

    func reset() {
        avatarView.avatar.backgroundColor = UIColor.clear
        avatarView.image = nil
    }

    func setImage(avatarDataSource: FeedCardAvatarDataSource,
                  size: CGFloat,
                  feedId: String,
                  feedCardType: FeedPreviewType) {
        switch avatarDataSource {
        case .remote(let avatarItem):
            let entityId = avatarItem.entityId
            let avatarKey = avatarItem.avatarKey
            guard !entityId.isEmpty, !avatarKey.isEmpty else {
                avatarView.image = nil
                let errorMsg = "avatar empty, entityId: \(entityId), avatarKey: \(avatarKey)"
                let info = FeedBaseErrorInfo(type: .error(), objcId: feedId, errorMsg: errorMsg)
                FeedExceptionTracker.FeedCard.render(node: .setAvatarImage, info: info)
                return
            }
            avatarView.setAvatarByIdentifier(
                entityId,
                avatarKey: avatarKey,
                medalKey: avatarItem.medal?.key ?? "",
                medalFsUnit: avatarItem.medal?.name ?? "",
                scene: .Feed,
                options: [.downsampleSize(CGSize(width: size, height: size))],
                avatarViewParams: .init(sizeType: .size(size)),
                completion: { result in
                    if case let .failure(error) = result {
                        let info = "id: \(feedId), "
                        + "type: \(feedCardType), "
                        + "avatarKey: \(avatarKey), "
                        + "entityId: \(entityId)"
                        let errorMsg = "avatar error, \(info)"
                        let errorInfo = FeedBaseErrorInfo(type: .error(), objcId: feedId, errorMsg: errorMsg, error: error)
                        FeedExceptionTracker.FeedCard.render(node: .setAvatarImage, info: errorInfo)
                    }
                })
        case .local(let avatarImage):
            // NOTE: setAvatarByIdentifier 是为了避免下载icon和本地icon之间的复用影响
            avatarView.setAvatarByIdentifier("", avatarKey: "", completion: { [weak avatarView] _ in
                avatarView?.backgroundColor = UIColor.clear
            })
            avatarView.image = avatarImage
        case .custom(let data):
            avatarView.image = nil
            avatarView.setCustomAvatar(model: data)
        @unknown default:
            break
        }
    }

    func set(badgeInfo: FeedCardBadgeInfo) {
        avatarView.updateBadge(badgeInfo.type, style: badgeInfo.style)
    }

    func setBoarder(isBorderVisible: Bool, borderSize: CGFloat) {
        FeedCardAvatarUtil.setBorderImage(avatarView: avatarView, isBorderVisible: isBorderVisible)
        avatarView.updateBorderSize(CGSize(width: borderSize, height: borderSize))
    }

    func set(miniIcon: MiniIconProps?) {
        avatarView.setMiniIcon(miniIcon)
    }
}

extension ShortcutCellViewModel {
    /// UI范畴内ShortcutCellViewModel判等
    static func isEquivalentTo(lhs: ShortcutCellViewModel, rhs: ShortcutCellViewModel) -> Bool {
//        let lhsPreview = lhs.preview.preview
//        let rhsPreview = rhs.preview.preview
        return
            // 基本shortcut数据
            lhs.shortcut == rhs.shortcut &&
            // ui 数据
            lhs.renderData == rhs.renderData &&
            // 基本feed数据
            lhs.feedID == rhs.feedID &&
            lhs.preview.basicMeta.feedCardType == rhs.preview.basicMeta.feedCardType &&
            lhs.unreadCount == rhs.unreadCount &&
            lhs.isRemind == rhs.isRemind &&
            lhs.hasAtInfo == rhs.hasAtInfo &&
            // TODO: open feed 业务 数据
            lhs.isCrypto == rhs.isCrypto &&
            lhs.isP2PAi == rhs.isP2PAi &&
            lhs.preview.preview.chatData.chatMode == rhs.preview.preview.chatData.chatMode
//            lhs.preview.chatMode == rhs.preview.chatMode &&
//            lhsPreview.openAppData == rhsPreview.openAppData &&
//            lhsPreview.subscriptionsData == rhsPreview.subscriptionsData &&
//            lhsPreview.docData == rhsPreview.docData
    }
}
