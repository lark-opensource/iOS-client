//
//  EventDetailTableWebinarSpeakerView.swift
//  Calendar
//
//  Created by tuwenbo on 2022/10/21.
//

import UIKit
import CalendarFoundation
import UniverseDesignIcon

final class EventDetailTableWebinarSpeakerView: EventDetailTableWebinarView {

    override func initView() {
        translatesAutoresizingMaskIntoConstraints = false

        let contentView = setupContentView()
        content = .customView(contentView)

        icon = .customImage(UDIcon.getIconByKey(.webinarOutlined, size: CGSize(width: 16, height: 16)).renderColor(with: .n3))
        iconAlignment = .topByOffset(12)

        accessory = .type(.next())
        accessoryAlignment = .centerYEqualTo(refView: avatarContainer)
    }
}
