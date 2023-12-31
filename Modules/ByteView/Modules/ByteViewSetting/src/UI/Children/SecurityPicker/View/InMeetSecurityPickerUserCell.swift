//
//  InMeetSecurityPickerUserCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/10.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

final class InMeetSecurityPickerUserCell: InMeetSecurityPickerCell {
    private lazy var statusView = UserFocusTagView()
    private lazy var flagLabel = InMeetSecurityUserFlagLabel()

    override func setupViews() {
        super.setupViews()

        self.titleAccessoryViews = [statusView, flagLabel]
        titleView.addSubview(statusView)
        titleView.addSubview(flagLabel)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        flagLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        flagLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        flagLabel.onUpdateFlagType = { [weak self] in
            self?.updateTitleAccessoryLayout()
        }
    }

    override func config(_ item: InMeetSecurityPickerItem, setting: MeetingSettingManager) {
        super.config(item, setting: setting)
        self.flagLabel.setFlag(for: item, setting: setting)
        self.statusView.setStatus(for: item)
    }
}
