//
//  UniverseDesignBadgeIconCell.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/29.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignBadge
import UniverseDesignIcon

class UniverseDesignBadgeIconCell: UniverseDesignBadgeBaseCell {
    private let avatar1 = UniverseDesignBadgeAvatar()
    private let avatar2 = UniverseDesignBadgeAvatar()
    private let avatar3 = UniverseDesignBadgeAvatar()

    override var contentHeight: CGFloat {
        return 60.0
    }

    init(title: String) {
        super.init(resultId: "UniverseDesignBadgeIconCell", title: title)

        content.addSubview(avatar1)
        content.addSubview(avatar2)
        content.addSubview(avatar3)

        avatar1.snp.makeConstraints { (make) in
            make.leading.centerY.equalToSuperview()
        }

        avatar2.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(avatar1.snp.trailing).offset(24.0)
        }

        avatar3.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(avatar2.snp.trailing).offset(24.0)
            make.size.equalTo(CGSize(width: 36.0, height: 36.0))
        }
        avatar3.image.layer.cornerRadius = 18.0

        let badge1 = avatar1.addBadge(.icon, anchor: .bottomRight, anchorType: .circle)
        badge1.config.icon = UDIcon.getIconByKey(.numberOutlined, iconColor: UDBadgeColorStyle.dotBorderWhite.color, size: CGSize(width: 10.0, height: 10.0))
        badge1.config.style = .dotBGGreen
        badge1.config.contentStyle = .dotCharacterText
        let badge2 = avatar2.addBadge(.icon, anchor: .bottomRight, anchorType: .circle)
        badge2.config.icon = UDIcon.getIconByKey(.speakerMuteFilled, iconColor: UDBadgeColorStyle.dotCharacterText.color, size: CGSize(width: 10.0, height: 10.0))
        badge2.config.style = .dotBGRed
        badge2.config.contentStyle = .dotCharacterText
        badge2.config.border = .outer
        badge2.config.borderStyle = .dotBorderWhite
        let badge3 = avatar3.addBadge(.icon, anchor: .bottomRight, anchorType: .circle)
        badge3.config.icon = UDIcon.getIconByKey(.speakerMuteFilled, iconColor: UDBadgeColorStyle.dotCharacterText.color, size: CGSize(width: 10.0, height: 10.0))
        badge2.config.style = .dotBGRed
        badge2.config.contentStyle = .dotCharacterText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
