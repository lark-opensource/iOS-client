//
//  SearchMessageInChatTableViewCell.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/23.
//

import UIKit
import Foundation
import LarkCore
import LarkModel
import LarkExtensions
import LarkSearchCore

final class SearchMessageInChatTableViewCell: BaseSearchInChatTableViewCell {
    let timeLabel: UILabel
    private var webImageDownloader: SearchWebImagesDownloader?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        timeLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = UIColor.ud.textPlaceholder

        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = UIColor.ud.textTitle

        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.ud.textPlaceholder
        self.textWarrperView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        })

        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.lessThanOrEqualTo(timeLabel.snp.left).offset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(viewModel: SearchInChatCellViewModel, currentSearchText: String) {
        super.update(viewModel: viewModel, currentSearchText: currentSearchText)
        webImageDownloader = nil

        guard let searchResult = viewModel.data, case .message(let meta) = searchResult.meta else { return }

        // avatar
        let avatarKey = meta.fromAvatarKey.isEmpty ? searchResult.avatarKey : meta.fromAvatarKey
        let title = searchResult.title(by: "fromName")
        avatarView.setAvatarByIdentifier(viewModel.avatarID,
                                         avatarKey: avatarKey,
                                         avatarViewParams: .init(sizeType: .size(avatarSize)))
        // title
        titleLabel.attributedText = title
        // subTitle
        var summary = searchResult.summary
        if !meta.docExtraInfosType.isEmpty {
            summary = Utils.replaceUrl(meta: meta, subtitle: summary, font: subtitleLabel.font)
        }
        timeLabel.isHidden = false
        timeLabel.text = Date.lf.getNiceDateString(TimeInterval(meta.createTime))
        if SearchFeatureGatingKey.enableSupportURLIconInline.isEnabled {
            subtitleLabel.attributedText = NSMutableAttributedString(attributedString: summary).updateSearchImage(font: subtitleLabel.font, tintColor: subtitleLabel.textColor)
        } else {
            subtitleLabel.attributedText = summary
        }

        if let _summary = subtitleLabel.attributedText, SearchFeatureGatingKey.enableSupportURLIconInline.isEnabled {
            var mutableSummary = NSMutableAttributedString(attributedString: _summary)
            let imageKeys = mutableSummary.searchWebImageKeysInAttachment
            if !imageKeys.isEmpty {
                webImageDownloader = SearchWebImagesDownloader(with: imageKeys)
                webImageDownloader?.download(completion: { [weak self] result in
                    guard let self = self else { return }
                    mutableSummary = mutableSummary.updateSearchWebImageView(withImageResource: result, font: self.subtitleLabel.font, tintColor: self.subtitleLabel.textColor)
                    if Thread.current.isMainThread {
                        self.subtitleLabel.attributedText = mutableSummary
                    } else {
                        DispatchQueue.main.async {
                            self.subtitleLabel.attributedText = mutableSummary
                        }
                    }
                })
            }
        }
    }
}
