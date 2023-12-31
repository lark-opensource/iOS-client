//
//  ShareAreaOptionCell.swift
//  LarkSnsPanel
//
//  Created by Siegfried on 2021/11/22.
//

import Foundation
import UIKit
import UniverseDesignIcon
import FigmaKit

final class ShareOptionCell: UICollectionViewCell {
    public static let idenContentString = "ShareOptionCellIdenContentString"
    private let titleBaselineOffset = (ShareCons.ShareTitleFontHeight - ShareCons.shareIconTitleFont.lineHeight) / 2.0 / 2.0
    private let mutableParagraphStyle: NSMutableParagraphStyle = {
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = ShareCons.ShareTitleFontHeight
        mutableParagraphStyle.maximumLineHeight = ShareCons.ShareTitleFontHeight
        mutableParagraphStyle.alignment = .center
        mutableParagraphStyle.lineBreakMode = .byWordWrapping
        mutableParagraphStyle.lineBreakMode = .byTruncatingTail
        return mutableParagraphStyle
    }()

    var icon: UIImage? {
        didSet {
            guard let icon = icon else { return }
            iconImageView.image = icon
        }
    }

    var title: String? {
        didSet {
            guard let title = title else { return }
            iconTitleLabel.attributedText = NSAttributedString(
                string: title,
                attributes: [
                    .baselineOffset: titleBaselineOffset,
                    .paragraphStyle: mutableParagraphStyle,
                    .font: ShareCons.shareIconTitleFont,
                    .foregroundColor: ShareColor.shareTitleColor
                ]
              )
        }
    }

    private lazy var iconContainer: SquircleView = {
        let iconContainer = SquircleView()
        iconContainer.cornerRadius = ShareCons.shareIconCornerRadius
        iconContainer.backgroundColor = ShareColor.shareIconBackgroundColor
        return iconContainer
    }()

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        return iconImageView
    }()

    private lazy var iconTitleLabel: UILabel = {
        let title = UILabel()
        title.numberOfLines = ShareCons.shareTitleMaxLineNums
        return title
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubViews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubViews() {
        iconContainer.addSubview(iconImageView)
        self.addSubview(iconContainer)
        self.addSubview(iconTitleLabel)
    }

    private func setupConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(ShareCons.shareIconImageWidth)
        }

        iconContainer.snp.makeConstraints { make in
            make.width.height.equalTo(ShareCons.shareIconContainerWidth)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }

        iconTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainer.snp.bottom).offset(ShareCons.shareIconTitleSpacing)
            make.width.equalTo(ShareCons.shareTitleMaxWidth)
            make.centerX.equalToSuperview()
        }
    }

    private func setupAppearance() {
        self.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.title = nil
        self.icon = nil
    }

    func configure(type: LarkShareItemType) {
        switch type {
        case .custom(let shareContext):
            self.icon = shareContext.itemContext.icon
            self.title = shareContext.itemContext.title
        default:
            self.icon = shareOptionMapping[type]?.icon
            self.title = shareOptionMapping[type]?.title
        }
    }
}
