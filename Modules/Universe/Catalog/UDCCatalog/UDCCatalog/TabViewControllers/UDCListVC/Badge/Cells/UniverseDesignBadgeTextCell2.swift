//
//  UniverseDesignBadgeTextCell2.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/28.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignBadge
import UniverseDesignIcon

class UniverseDesignBadgeTextCase<V: UIView>: UIView {
    private let view9: V
    private let view99: V
    private let view999: V
    private let viewMore: V

    let viewSize: CGSize

    init(
        creator: () -> V,
        extendType: UDBadgeAnchorExtendType = .leading,
        anchorType: UDBadgeAnchorType = .rectangle,
        viewSize: CGSize
    ) {
        self.view9 = creator()
        self.view99 = creator()
        self.view999 = creator()
        self.viewMore = creator()
        self.viewSize = viewSize
        super.init(frame: .zero)

        let badge9 = view9.addBadge(.number, anchor: .topRight, anchorType: anchorType)
        let badge99 = view99.addBadge(.number, anchor: .topRight, anchorType: anchorType)
        let badge999 = view999.addBadge(.number, anchor: .topRight, anchorType: anchorType)
        let badgeMore = viewMore.addBadge(.number, anchor: .topRight, anchorType: anchorType)
        [badge9, badge99, badge999, badgeMore].forEach({
            $0.config.style = .characterBGRed
            $0.config.anchorExtendType = extendType
            $0.config.contentStyle = .dotCharacterText
            $0.config.maxNumber = 999
        })
        badge99.config.border = .outer
        badge99.config.borderStyle = .dotBorderWhite
        badge9.config.number = 9
        badge99.config.number = 99
        badge999.config.number = 999
        badgeMore.config.number = 1000

        var xOffset: CGFloat = 0.0
        [view9, view99, view999, viewMore].forEach({
            addSubview($0)

            $0.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().offset(xOffset)
            }

            xOffset += 32.0 + viewSize.width
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeLabel: UIView {
    private let label = UILabel(frame: .zero)

    override var intrinsicContentSize: CGSize {
        return label.intrinsicContentSize
    }

    init() {
        super.init(frame: .zero)

        label.text = "文字按钮"
        label.textColor = UIColor.ud.colorfulBlue
        label.font = .systemFont(ofSize: 14.0)

        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeTextCell2: UniverseDesignBadgeBaseCell {
    private let leadingPaddings: [UniverseDesignBadgeTextCase<UIView>] = [
        UniverseDesignBadgeTextCase(
            creator: { UniverseDesignBadgeAvatar() },
            anchorType: .circle,
            viewSize: CGSize(width: 48.0, height: 48.0)
        ),
        UniverseDesignBadgeTextCase(
            creator: { UIImageView(image: UDIcon.groupOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)) },
            viewSize: CGSize(width: 24.0, height: 24.0)
        ),
        UniverseDesignBadgeTextCase(
            creator: { UniverseDesignBadgeLabel() },
            viewSize: CGSize(width: 58.0, height: 25.0)
        )
    ]

    private let paddingLabel = UILabel(frame: .zero)

    private let trailingPaddings: [UniverseDesignBadgeTextCase<UIView>] = [
        UniverseDesignBadgeTextCase(
            creator: { UniverseDesignBadgeAvatar() },
            extendType: .trailing,
            anchorType: .circle,
            viewSize: CGSize(width: 48.0, height: 48.0)
        ),
        UniverseDesignBadgeTextCase(
            creator: { UIImageView(image: UDIcon.groupOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)) },
            extendType: .trailing,
            viewSize: CGSize(width: 24.0, height: 24.0)
        ),
        UniverseDesignBadgeTextCase(
            creator: { UniverseDesignBadgeLabel() },
            extendType: .trailing,
            viewSize: CGSize(width: 58.0, height: 25.0)
        )
    ]

    override var contentHeight: CGFloat {
        paddingLabel.sizeToFit()
        return leadingPaddings.reduce(0.0, { $0 + $1.viewSize.height + 16.0 })
            + paddingLabel.intrinsicContentSize.height
            + trailingPaddings.reduce(0.0, { $0 + $1.viewSize.height + 16.0 })
    }

    init(title: String) {
        super.init(resultId: "UniverseDesignBadgeTextCell2", title: title)

        var height: CGFloat = 0.0
        leadingPaddings.enumerated().forEach { (_, element) in
            content.addSubview(element)

            element.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(height)
                make.height.equalTo(element.viewSize.height)
            }

            height += element.viewSize.height + 16.0
        }

        paddingLabel.text = "右侧延伸"
        paddingLabel.textColor = UIColor.ud.textTitle
        paddingLabel.font = .systemFont(ofSize: 13.0)

        content.addSubview(paddingLabel)
        paddingLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.top.equalTo(leadingPaddings.last!.snp.bottom).offset(16.0)
        }

        paddingLabel.sizeToFit()
        height += paddingLabel.intrinsicContentSize.height
        height += 8.0

        trailingPaddings.enumerated().forEach { (_, element) in
            content.addSubview(element)

            element.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(height)
                make.height.equalTo(element.viewSize.height)
            }

            height += element.viewSize.height + 16.0
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
