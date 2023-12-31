//
//  ProfileFieldPushCell.swift
//  EEAtomic
//
//  Created by 姚启灏 on 2021/6/29.
//

import Foundation
import UniverseDesignIcon
import UIKit

public final class ProfileFieldPushItem: ProfileFieldNormalItem {
    public var tapCallback: (() -> Void)?
    public var icon: UIImage?
    public var numberOfLines: Int
    public var textAlignment: NSTextAlignment

    public init(fieldKey: String = "",
                title: String = "",
                icon: UIImage? = nil,
                numberOfLines: Int = 1,
                contentText: String = "",
                textAlignment: NSTextAlignment = .right,
                tapCallback: (() -> Void)? = nil) {
        self.tapCallback = tapCallback
        self.icon = icon
        self.numberOfLines = numberOfLines
        self.textAlignment = textAlignment

        super.init(type: .push,
                   fieldKey: fieldKey,
                   title: title,
                   contentText: contentText,
                   enableLongPress: false)
    }
}

public final class ProfileFieldPushCell: ProfileFieldNormalCell {
    private lazy var pushIcon: UIImageView = UIImageView(image: UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3))

    private lazy var iconImageView: UIImageView = UIImageView()

    public override class func canHandle(item: ProfileFieldItem) -> Bool {
        guard let cellItem = item as? ProfileFieldPushItem else {
            return false
        }
        return cellItem.type == .push
    }

    override func commonInit() {
        super.commonInit()

        guard let cellItem = item as? ProfileFieldPushItem else {
            return
        }

        self.contentLabel.numberOfLines = cellItem.numberOfLines
        self.contentLabel.textAlignment = cellItem.textAlignment

        contentLabel.removeFromSuperview()

        contentLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        contentLabel.setContentHuggingPriority(.required, for: .vertical)

        contentLabel.isHidden = cellItem.contentText.isEmpty

        contentWrapperView.addSubview(iconImageView)
        contentWrapperView.addSubview(contentLabel)

        iconImageView.image = cellItem.icon
        contentLabel.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.left.greaterThanOrEqualToSuperview()
        }

        iconImageView.snp.remakeConstraints { make in
            if contentLabel.isHidden {
                make.right.equalToSuperview()
            } else {
                make.right.equalTo(contentLabel.snp.left).offset(-5)
            }
            make.top.equalTo(contentLabel.snp.top)
            make.left.greaterThanOrEqualToSuperview()
            make.width.height.equalTo(18)
        }

        contentView.addSubview(pushIcon)
        stackView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(Cons.vMargin)
            make.bottom.equalToSuperview().offset(-Cons.vMargin)
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.right.equalTo(pushIcon.snp.left).offset(-Cons.arrowSpacing)
        }
        pushIcon.snp.makeConstraints { make in
            make.width.height.equalTo(Cons.arrowSize)
            make.top.equalTo(contentLabel.snp.top)
            make.right.equalToSuperview().offset(-Cons.hMargin)
        }
    }

    public override func didTap() {
        super.didTap()

        guard let cellItem = item as? ProfileFieldPushItem else {
            return
        }

        cellItem.tapCallback?()
    }
}
