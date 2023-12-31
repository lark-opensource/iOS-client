//
//  OpenSearchJumpTableViewCell.swift
//  LarkSearch
//
//  Created by bytedance on 2022/3/9.
//

import Foundation
import UIKit
import LarkCore
import LarkUIKit
import LarkAccountInterface
import LarkAvatar
import LarkSearchCore
import UniverseDesignIcon
import LKCommonsLogging
import LarkSearchFilter

final class OpenSearchJumpNewTableViewCell: SearchNewDefaultTableViewCell {
    static let logger = Logger.log(OpenSearchJumpNewTableViewCell.self, category: "Module.IM.Search")

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled {
            infoView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(13)
                make.right.equalToSuperview().offset(-16)
                make.top.equalToSuperview().offset(8)
                make.bottom.equalToSuperview().offset(-8)
            }
            infoView.avatarView.snp.remakeConstraints({ make in
                make.size.equalTo(CGSize(width: 32, height: 32))
            })
            infoView.jumpButton.snp.remakeConstraints { make in
                make.size.equalTo(CGSize(width: 32, height: 32))
            }
            infoView.jumpButton.isEnabled = false
            infoView.jumpButton.setImage(UDIcon.getIconByKey(.rightBoldOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(.ud.iconN3), for: .disabled)
            infoView.jumpButton.imageEdgeInsets = UIEdgeInsets(top: (32 - 12) / 2, left: 32 - 12, bottom: (32 - 12) / 2, right: 0)
        } else {
            infoView.jumpButton.isHidden = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        guard let viewModel = viewModel as? OpenSearchJumpViewModel else { return }

        setupAvatarWith(viewModel: viewModel)
        setupInfoViewWith(viewModel: viewModel)
        if SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled {
            infoView.jumpButton.isHidden = false
        }
    }

    private func setupAvatarWith(viewModel: SearchCellViewModel) {
        let searchResult = viewModel.searchResult
        // 头像
        /// 恢复默认值，防止cell复用出问题
        infoView.avatarView.avatar.contentMode = .scaleToFill
        if let imageURL = URL(string: searchResult.imageURL) {
            infoView.avatarView.avatar.bt.setLarkImage(with: .default(key: imageURL.absoluteString),
                                                             placeholder: SearchImageUtils.generateAvatarImage(withTitle: "", bgColor: .ud.N500),
                                                             completion: { [weak self] result in
                if case let .failure(error) = result {
                    self?.setupDefaultAvatar()
                    Self.logger.error("[LarkSearch] openSearchJumpMore cell avatar load failed",
                                      additionalData: ["error": error.localizedDescription])
                }
            })
        } else {
            Self.logger.error("[LarkSearch] openSearchJumpMore cell avatar url not available: \(searchResult.imageURL)")
            setupDefaultAvatar()
        }
    }

    private func setupDefaultAvatar() {
        infoView.avatarView.avatar.contentMode = .center
        let defaultAvatarSize = SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled ? CGSize(width: 16, height: 16) : CGSize(width: 24, height: 24)
        infoView.avatarView.avatar.image = UDIcon.getIconByKey(.appDefaultFilled, size: defaultAvatarSize).ud.withTintColor(.ud.staticWhite)
        infoView.avatarView.backgroundColor = .ud.N500
    }

    private func setupInfoViewWith(viewModel: SearchCellViewModel) {
        let nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()
        nameStatusConfig.nameAttributedText = viewModel.searchResult.title
        infoView.nameStatusView.updateContent(content: nameStatusConfig)
    }
}
