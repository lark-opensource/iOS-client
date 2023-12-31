//
//  InMeetSecurityPickerCalendarCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/11.
//

import Foundation
import ByteViewCommon
import UniverseDesignIcon

final class InMeetSecurityPickerCalendarCell: InMeetSecurityPickerCell {
    private let expandButton = UIButton()
    var expandAction: ((InMeetSecurityPickerItem.CalendarHeaderInfo) -> Void)?

    override func setupViews() {
        super.setupViews()
        self.rightView.addSubview(expandButton)
        expandButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(52)
        }

        expandButton.addTarget(self, action: #selector(didClickExpand(_:)), for: .touchUpInside)
    }

    override func config(_ item: InMeetSecurityPickerItem, setting: MeetingSettingManager) {
        super.config(item, setting: setting)
        if case let .calendarHeader(info) = item {
            let icon = UDIcon.getIconByKey(info.isExpanded ? .upOutlined : .downOutlined,
                                           iconColor: info.status == .success ? .ud.iconN3 : .ud.iconDisabled,
                                           size: CGSize(width: 20, height: 20))
            self.expandButton.setImage(icon, for: .normal)
        }
    }

    @objc private func didClickExpand(_ sender: UIButton) {
        if let action = expandAction, let item = self.item, case let .calendarHeader(info) = item {
            action(info)
        }
    }
}

final class InMeetSecurityPickerCalendarGuestCell: InMeetSecurityPickerCell {
    override var showsCheckbox: Bool { false }
}
