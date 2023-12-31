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
        showIcon: Bool = true
    ) {
        self.descriptionView.text = description
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
            self.descriptionIcon.image = getVerticalLineImage()
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
    
    private func getVerticalLineImage() -> UIImage {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 1, height: 16)
        let view = UIView()
        view.frame = CGRect(x: 0, y: 2, width: 1, height: 12)
        view.backgroundColor = UIColor.ud.lineDividerDefault
        containerView.addSubview(view)
        UIGraphicsBeginImageContextWithOptions(containerView.frame.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        containerView.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
