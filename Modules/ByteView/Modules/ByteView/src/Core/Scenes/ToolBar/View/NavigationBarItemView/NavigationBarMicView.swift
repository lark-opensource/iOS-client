//
//  NavigationBarMicView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/15.
//

import UIKit
import UniverseDesignIcon

class NavigationBarMicView: NavigationBarItemView {
    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        guard let item = item as? ToolBarMicItem else { return }
        if item.micState == .disconnect {
            iconView.image = UDIcon.getIconByKey(.disconnectAudioOutlined, iconColor: UIColor.ud.iconN1.withAlphaComponent(0.8), size: Self.iconSize)
        } else {
            iconView.image = nil
        }
    }
}
