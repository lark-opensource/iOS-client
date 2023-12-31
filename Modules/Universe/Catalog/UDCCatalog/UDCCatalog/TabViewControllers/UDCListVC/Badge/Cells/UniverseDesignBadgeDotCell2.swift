//
//  UniverseDesignBadgeDotCell2.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/28.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignBadge
import UniverseDesignIcon

class UniverseDesignBadgeAvatarDot: UniverseDesignBadgeCase {
    private let avatar1 = UniverseDesignBadgeAvatar()
    private let avatar2 = UniverseDesignBadgeAvatar()

    override var contentHeight: CGFloat {
        return 50.0
    }

    override init(title: String) {
        super.init(title: title)

        content.addSubview(avatar1)
        content.addSubview(avatar2)

        avatar1.snp.makeConstraints { (make) in
            make.leading.centerY.equalToSuperview()
        }

        avatar2.snp.makeConstraints { (make) in
            make.leading.equalTo(avatar1.snp.trailing).offset(50.0)
            make.centerY.equalToSuperview()
        }

        let badge1 = avatar1.addBadge(.dot, anchor: .topRight, anchorType: .circle)
        badge1.config.dotSize = .large

        let badge2 = avatar2.addBadge(.dot, anchor: .bottomRight, anchorType: .circle)
        badge2.config.dotSize = .large
        badge2.config.border = .outer
        badge2.config.borderStyle = .dotBorderWhite
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeLabelDot: UniverseDesignBadgeCase {
    private let contentLabel = UILabel(frame: .zero)
    private let dot = UDBadge(config: .dot)

    override var contentHeight: CGFloat {
        contentLabel.sizeToFit()
        return contentLabel.intrinsicContentSize.height + 10.0
    }

    override init(title: String) {
        super.init(title: title)

        dot.config.dotSize = .middle
        addSubview(contentLabel)
        addSubview(dot)

        dot.snp.makeConstraints { (make) in
            make.leading.centerY.equalToSuperview()
        }

        contentLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(dot.snp.trailing).offset(4.0)
            make.centerY.equalToSuperview()
        }

        contentLabel.text = "Sadie Hale, Tefeng Liu"
        contentLabel.textColor = UIColor.ud.textTitle
        contentLabel.font = .systemFont(ofSize: 18.0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeRectDot: UniverseDesignBadgeCase {
    private let label1 = UILabel(frame: .zero)
    private let label2 = UILabel(frame: .zero)
    private let icon = UIImageView(image: UDIcon.groupOutlined)

    override var contentHeight: CGFloat {
        label1.sizeToFit()
        label2.sizeToFit()
        icon.sizeToFit()
        return max(label1.intrinsicContentSize.height,
                   label2.intrinsicContentSize.height,
                   icon.intrinsicContentSize.height) + 8.0
    }

    override init(title: String) {
        super.init(title: title)

        addSubview(label1)
        addSubview(label2)
        addSubview(icon)

        let smallSize = UDBadgeDotSize.small.size
        let offsetX = (smallSize.width / 2.0) + 2.0

        icon.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        let badge1 = label1.addBadge(.dot,
                                     anchor: .topRight,
                                     anchorType: .rectangle,
                                     offset: CGSize(width: offsetX, height: 0.0))
        badge1.config.dotSize = .small

        let badge2 = label2.addBadge(.dot,
                                     anchor: .topRight,
                                     anchorType: .rectangle,
                                     offset: CGSize(width: offsetX, height: 0.0))
        badge2.config.dotSize = .small
        badge2.config.border = .inner
        badge2.config.borderStyle = .dotBorderDarkgrey
        badge2.config.style = .custom(.clear)

        let badge3 = icon.addBadge(.dot, anchor: .topRight, anchorType: .rectangle)
        badge3.config.dotSize = .small

        label1.text = "文字按钮"
        label1.textColor = UIColor.ud.colorfulBlue
        label1.font = .systemFont(ofSize: 13.0)
        label2.text = "文字按钮"
        label2.textColor = UIColor.ud.colorfulBlue
        label2.font = .systemFont(ofSize: 13.0)

        label1.snp.makeConstraints { (make) in
            make.leading.centerY.equalToSuperview()
        }

        label2.snp.makeConstraints { (make) in
            make.leading.equalTo(label1.snp.trailing).offset(32.0)
            make.centerY.equalToSuperview()
        }

        icon.snp.makeConstraints { (make) in
            make.leading.equalTo(label2.snp.trailing).offset(32.0)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeDotCell2: UniverseDesignBadgeBaseCell {
    private let cases: [UniverseDesignBadgeCase] = [
        UniverseDesignBadgeAvatarDot(title: "与头像组合时，应用 10x10px 尺寸"),
        UniverseDesignBadgeLabelDot(title: "位于列表、feed 流等场景时，应用 8x8px 尺寸"),
        UniverseDesignBadgeRectDot(title: "位于文字、图标按钮上时，应用 6x6px 尺寸")
    ]

    override var contentHeight: CGFloat {
        return cases.reduce(1.0, { $0 + $1.height })
    }

    init(title: String) {
        super.init(resultId: "UniverseDesignBadgeDotCell2", title: title)

        var heightCursor: CGFloat = 0.0
        cases.enumerated().forEach { (_, caseView) in
            content.addSubview(caseView)

            caseView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(caseView.height)
                make.top.equalToSuperview().offset(heightCursor)
            }

            heightCursor += caseView.height
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
