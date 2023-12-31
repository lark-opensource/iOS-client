//
//  UniverseDesignBadgeTextCell1.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/28.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignBadge

class UniverseDesignBadgeSingleText: UniverseDesignBadgeCase {
    private let redBadge = UDBadge(config: .number)
    private let greyBadge = UDBadge(config: .number)

    override var contentHeight: CGFloat {
        return redBadge.intrinsicContentSize.height
    }

    override init(title: String) {
        super.init(title: title)

        addSubview(redBadge)
        addSubview(greyBadge)

        redBadge.config.style = .characterBGRed
        redBadge.config.number = 9
        redBadge.config.contentStyle = .dotCharacterText
        greyBadge.config.style = .characterBGGrey
        greyBadge.config.number = 9
        greyBadge.config.contentStyle = .dotCharacterText

        redBadge.snp.makeConstraints { (make) in
            make.leading.centerY.equalToSuperview()
        }

        greyBadge.snp.makeConstraints { (make) in
            make.leading.equalTo(redBadge.snp.trailing).offset(26.0)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeMultiText: UniverseDesignBadgeCase {
    private let badge99Red = UDBadge(config: .number)
    private let badge99Grey = UDBadge(config: .number)
    private let badge11Red = UDBadge(config: .number)
    private let badge11Grey = UDBadge(config: .number)
    private let badge999Red = UDBadge(config: .number)
    private let badge999Grey = UDBadge(config: .number)
    private let badgeNewRed = UDBadge(config: .text)
    private let badgeNewGrey = UDBadge(config: .text)

    override var contentHeight: CGFloat {
        return 16.0 * 2.0 + 24.0
    }

    override init(title: String) {
        super.init(title: title)

        badge99Red.config.number = 99
        badge99Grey.config.number = 99
        badge11Red.config.number = 11
        badge11Grey.config.number = 11
        badge999Red.config.number = 999
        badge999Red.config.maxNumber = 999
        badge999Grey.config.number = 999
        badge999Grey.config.maxNumber = 999
        badgeNewRed.config.text = "New"
        badgeNewGrey.config.text = "New"

        var xCursor: CGFloat = 0.0
        [badge99Red, badge11Red, badge999Red, badgeNewRed].forEach({
            $0.config.style = .characterBGRed
            $0.config.contentStyle = .dotCharacterText

            content.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.leading.equalToSuperview().offset(xCursor)
            }

            xCursor += $0.intrinsicContentSize.width + 26.0
        })

        xCursor = 0.0
        [badge99Grey, badge11Grey, badge999Grey, badgeNewGrey].forEach({
            $0.config.style = .characterBGGrey
            $0.config.contentStyle = .dotCharacterText

            content.addSubview($0)
            $0.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(24.0)
                make.leading.equalToSuperview().offset(xCursor)
            }

            xCursor += $0.intrinsicContentSize.width + 26.0
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeMoreNumber: UniverseDesignBadgeCase {
    private let moreRed = UDBadge(config: .number)
    private let moreGrey = UDBadge(config: .number)

    override var contentHeight: CGFloat {
        return 16.0 + 8.0
    }

    override init(title: String) {
        super.init(title: title)

        addSubview(moreRed)
        addSubview(moreGrey)

        moreRed.config.number = 100 // default max is 99
        moreRed.config.style = .dotBGRed // default style is dotBGRed
        moreRed.config.contentStyle = .dotCharacterLimitIcon // default style is dotCharacterText

        moreGrey.config.number = 100 // default max is 99
        moreGrey.config.style = .dotBGGrey // default style is dotBGGrey
        moreGrey.config.contentStyle = .dotCharacterLimitIcon // default style is dotCharacterText

        moreRed.snp.makeConstraints { (make) in
            make.centerY.leading.equalToSuperview()
        }

        moreGrey.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(moreRed.snp.trailing).offset(26.0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeTextCell1: UniverseDesignBadgeBaseCell {
    private let caseViews: [UniverseDesignBadgeCase] = [
        UniverseDesignBadgeSingleText(title: "单字符"),
        UniverseDesignBadgeMultiText(title: "多字符"),
        UniverseDesignBadgeMoreNumber(title: "多字符（省略）")
    ]

    override var contentHeight: CGFloat {
        return caseViews.reduce(0.0, { $0 + $1.height })
    }

    init(title: String) {
        super.init(resultId: "UniverseDesignBadgeTextCell1", title: title)

        var heightCursor: CGFloat = 0.0
        caseViews.enumerated().forEach { (_, caseView) in
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
