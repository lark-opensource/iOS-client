//
//  TransferFloatCard.swift
//  Calendar
//
//  Created by heng zhu on 2019/8/27.
//

import UIKit
import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import RichLabel
import UniverseDesignFont

final class TransferFloatCard: BaseMeetingFloatCardView {

    private lazy var contentLabelWidth: CGFloat = {
        let tagAttributes = [NSAttributedString.Key.font: UDFont.body2(.fixed)]
        return NSAttributedString(string: BundleI18n.Calendar.Calendar_Setting_ConvertGroupBanner,
                                  attributes: tagAttributes)
        .boundingRect(with: CGSize(width: 1000, height: 20), context: nil).size.width
    }()

    private lazy var transferButtonWidth: CGFloat = {
        let tagAttributes = [NSAttributedString.Key.font: UDFont.body2(.fixed)]
        return NSAttributedString(string: BundleI18n.Calendar.Calendar_Setting_TransformToNormalGroup,
                                  attributes: tagAttributes)
        .boundingRect(with: CGSize(width: 1000, height: 20), context: nil).size.width
    }()
    private var lastWidth: CGFloat = 0
    private let spacing: CGFloat = 7

    private lazy var contentLabel = {
        let label = LKLabel()
        label.backgroundColor = .clear
        label.numberOfLines = 0
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.minimumLineHeight = 20
        style.maximumLineHeight = 20
        let attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: style,
                                                         .font: UDFont.body2(.fixed),
                                                         .foregroundColor: UDColor.textTitle]
        label.attributedText = NSMutableAttributedString(string: BundleI18n.Calendar.Calendar_Setting_ConvertGroupBanner,
                                                         attributes: attributes)
        return label
    }()

    private lazy var transferButton = {
        let button = UIButton()
        let label = LKLabel()
        label.backgroundColor = .clear
        let attributes: [NSAttributedString.Key: Any] = [.font: UDFont.body2(.fixed),
                                                         .foregroundColor: UDColor.primaryContentDefault]
        label.attributedText = NSMutableAttributedString(string: BundleI18n.Calendar.Calendar_Setting_TransformToNormalGroup,
                                                         attributes: attributes)
        button.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview() }
        return button
    }()

    init(target: Any?,
         transferSelector: Selector,
         closeSelector: Selector) {
        super.init(icon: UDIcon.infoColorful, backgroundColor: UDColor.primaryFillSolid01)
        self.addCloseAction(target: target, action: closeSelector)
        self.transferButton.addTarget(target, action: transferSelector, for: .touchUpInside)
        setupContentView()
    }

    private func setupContentView() {
        self.contentView.addSubview(contentLabel)
        self.contentView.addSubview(transferButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if lastWidth != contentView.frame.width {
            contentLabel.preferredMaxLayoutWidth = contentView.frame.width
            lastWidth = contentView.frame.width
            if contentLabelWidth + spacing + transferButtonWidth > lastWidth {
                contentLabel.snp.remakeConstraints {
                    $0.top.left.right.equalToSuperview()
                    $0.height.greaterThanOrEqualTo(20)
                }
                transferButton.snp.remakeConstraints {
                    $0.top.equalTo(contentLabel.snp.bottom).offset(4)
                    $0.left.bottom.equalToSuperview()
                    $0.height.equalTo(20)
                }
            } else {
                contentLabel.snp.remakeConstraints {
                    $0.top.left.bottom.equalToSuperview()
                    $0.height.greaterThanOrEqualTo(20)
                }
                transferButton.snp.remakeConstraints {
                    $0.left.equalTo(contentLabel.snp.right).offset(spacing)
                    $0.height.equalTo(20)
                    $0.top.equalToSuperview()
                }
            }
            contentLabel.invalidateIntrinsicContentSize()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
