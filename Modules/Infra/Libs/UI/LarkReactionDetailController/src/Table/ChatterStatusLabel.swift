//
//  ChatterStatusLabel.swift
//  LarkReactionDetailController
//
//  Created by 李晨 on 2019/6/17.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit

final class ChatterStatusLabel: UIView {

    var font: UIFont = UIFont.systemFont(ofSize: 12) {
        didSet {
            descriptionView.font = self.font
        }
    }

    var textColor: UIColor = UIColor.ud.N500 {
        didSet {
            descriptionView.textColor = textColor
        }
    }

    override var backgroundColor: UIColor? {
        didSet {
            self.descriptionIcon.backgroundColor = backgroundColor
            self.descriptionView.backgroundColor = backgroundColor
        }
    }

    private(set) var showIcon: Bool = true {
        didSet {
            descriptionIcon.isHidden = !showIcon
        }
    }

    private(set) var descriptionIcon: UIImageView = UIImageView()
    private(set) var descriptionView: UILabel = UILabel()

    private(set) var descriptionType: Chatter.DescriptionType = .onDefault

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true

        let descriptionIcon = UIImageView()
        descriptionIcon.isUserInteractionEnabled = false
        self.addSubview(descriptionIcon)
        self.descriptionIcon = descriptionIcon

        descriptionView.backgroundColor = UIColor.clear
        descriptionView.textColor = textColor
        descriptionView.textAlignment = .left
        descriptionView.font = self.font
        descriptionView.isUserInteractionEnabled = true
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        descriptionView.lineBreakMode = .byTruncatingTail
        descriptionView.numberOfLines = 1
        self.addSubview(descriptionView)

        descriptionView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        descriptionView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        descriptionIcon.accessibilityIdentifier = "chatter.status.icon"
        descriptionView.accessibilityIdentifier = "chatter.status.label"

    }

    required  init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(
        description: String,
        descriptionType: Chatter.DescriptionType,
        showIcon: Bool = true
    ) {
        self.descriptionView.text = description
        self.descriptionType = descriptionType
        self.showIcon = showIcon
        self.updateUI()
    }

    func updateUI() {
        isHidden = false
        if self.descriptionView.text?.isEmpty ?? true {
            self.descriptionView.text = ""
            self.descriptionIcon.image = nil
            isHidden = true
        } else {
            self.descriptionIcon.image = Resources.verticalLineImage
        }

        descriptionIcon.snp.remakeConstraints { (make) in
            make.left.equalToSuperview()
            make.size.equalTo(self.descriptionIcon.image?.size ?? CGSize(width: 0, height: 0))
            make.right.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }

        descriptionView.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
            if showIcon {
                make.left.equalTo(self.descriptionIcon.snp.right).offset(8)
            } else {
                make.left.equalToSuperview()
            }
            make.right.lessThanOrEqualToSuperview()
        }
    }
}
