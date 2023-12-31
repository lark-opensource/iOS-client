//
//  UniverseDesignBadgeDotCell1.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/28.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignBadge

class UniverseDesignBadgeDotStyle: UIView {
    private let smallBadge = UDBadge(config: .dot)
    private let middleBadge = UDBadge(config: .dot)
    private let largeBadge = UDBadge(config: .dot)
    private let label = UILabel(frame: .zero)

    init(
        styles: [UDBadgeColorStyle],
        border: UDBadgeBorder = .none,
        borderStyle: UDBadgeColorStyle = .custom(.clear),
        desc: String
    ) {
        super.init(frame: .zero)

        smallBadge.config.dotSize = .small
        smallBadge.config.style = styles[0]
        smallBadge.config.border = border
        smallBadge.config.borderStyle = borderStyle
        // middleBadge.config.dotSize = .middle // default
        middleBadge.config.style = styles[1]
        middleBadge.config.border = border
        middleBadge.config.borderStyle = borderStyle
        largeBadge.config.dotSize = .large
        largeBadge.config.style = styles[2]
        largeBadge.config.border = border
        largeBadge.config.borderStyle = borderStyle

        label.font = .systemFont(ofSize: 13.0)
        label.text = desc
        label.textColor = UIColor.ud.textTitle

        addSubview(smallBadge)
        addSubview(middleBadge)
        addSubview(largeBadge)
        addSubview(label)

        smallBadge.snp.makeConstraints { (make) in
            make.leading.centerY.equalToSuperview()
        }

        middleBadge.snp.makeConstraints { (make) in
            make.leading.equalTo(smallBadge.snp.trailing).offset(48.0)
            make.centerY.equalToSuperview()
        }

        largeBadge.snp.makeConstraints { (make) in
            make.leading.equalTo(middleBadge.snp.trailing).offset(48.0)
            make.centerY.equalToSuperview()
        }

        label.snp.makeConstraints { (make) in
            make.leading.equalTo(largeBadge.snp.trailing).offset(48.0)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeDotCell1: UniverseDesignBadgeBaseCell {
    private let dots: [UniverseDesignBadgeDotStyle] = [
        UniverseDesignBadgeDotStyle(styles: [.dotBGRed, .dotBGRed, .dotBGRed], desc: "红色（强提示）"),
        UniverseDesignBadgeDotStyle(styles: [.dotBGGrey, .dotBGGrey, .dotBGGrey], desc: "灰色（弱提示）"),
        UniverseDesignBadgeDotStyle(styles: [.dotBGBlue, .dotBGBlue, .dotBGBlue], desc: "蓝色（小程序更新提示）"),
        UniverseDesignBadgeDotStyle(styles: [.dotBGGreen, .dotBGGreen, .dotBGGreen], desc: "绿色（被人提及已读）"),
        UniverseDesignBadgeDotStyle(styles: [.custom(.clear),
                                              .custom(.clear),
                                              .custom(.clear)],
                                     border: .inner,
                                     borderStyle: .dotBorderDarkgrey,
                                     desc: "仅内描边（被人提及未读）"),
        UniverseDesignBadgeDotStyle(styles: [.custom(.cyan),
                                              .custom(.purple),
                                              .custom(.orange)],
                                     desc: "自定义")
    ]

    override var contentHeight: CGFloat {
        return CGFloat(dots.count) * 24.0
    }

    init(title: String) {
        super.init(resultId: "UniverseDesignBadgeDotCell1", title: title)

        dots.enumerated().forEach { (index, element) in
            content.addSubview(element)

            let height: CGFloat = 24.0
            element.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(height * CGFloat(index))
                make.height.equalTo(height)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
