//
//  MeetingDetailPreviewHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import ByteViewNetwork
import UniverseDesignIcon

class MeetingDetailPreviewHeaderComponent: MeetingDetailParticipantHeaderComponent {

    override func setupViews() {
        super.setupViews()

        let previewIcon = UIImageView()
        previewIcon.image = UDIcon.getIconByKey(.groupOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
        addSubview(previewIcon)
        previewIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.left.centerY.equalToSuperview()
        }

        addSubview(previewView)
        previewView.snp.makeConstraints { (make) in
            make.left.equalTo(previewIcon.snp.right).offset(12)
            make.top.bottom.equalToSuperview()
        }
    }

    override var shouldShow: Bool {
        guard let viewModel = viewModel, let commonInfo = viewModel.commonInfo.value else {
            return false
        }
        return viewModel.isWebinarMeeting == false && commonInfo.meetingType != .call
    }
}
