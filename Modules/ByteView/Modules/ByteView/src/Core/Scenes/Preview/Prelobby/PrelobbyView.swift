//
//  PrelobbyView.swift
//  ByteView
//
//  Created by lutingting on 2023/5/31.
//

import Foundation
import RxCocoa
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewSetting
import ByteViewMeeting

struct PrelobbyContainerViewModel {
    let session: MeetingSession
    let service: MeetingBasicService
    let isCameraOn: Bool
    let camera: PreviewCameraManager
    let isWebinarAttendee: Bool
}

final class PrelobbyView: PreviewMeetingContainerView {
    let model: PrelobbyContainerViewModel

    override var leftItem: UIView { backButton }
    override var rightItem: UIView { connectRoomBtn }
    override var topView: UIView { headerView }
    override var middleView: UIView { contentView }
    override var bottomView: UIView { footerView }

    // 缩小变为悬浮窗按钮
    lazy var backButton: UIButton = {
        var btn = UIButton()
        btn.isExclusiveTouch = true
        let image = UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24))
        btn.setImage(image, for: .normal)
        let highlightedImage = UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN1.withAlphaComponent(0.5), size: CGSize(width: 24, height: 24))
        btn.setImage(highlightedImage, for: .highlighted)
        btn.addInteraction(type: .highlight)
        return btn
    }()

    lazy var connectRoomBtn: PreviewConnectRoomButton = {
        let btn = PreviewConnectRoomButton()
        btn.isHidden = true
        return btn
    }()

    lazy var headerView = PrelobbyHeaderView()
    lazy var contentView = PreviewContentView(session: model.session, service: model.service, isCameraOn: model.isCameraOn, isPrelobby: true, camera: model.camera)

    lazy var footerView: PreviewFooterView = {
        let deviceView = PreviewDeviceView()
        if model.isWebinarAttendee {
            deviceView.style = .webinarAttendee
        }
        deviceView.micView.switchAudioButton.isEnabled = false
        deviceView.isLongMic = false
        if let audioOutput = model.session.audioDevice?.output {
            deviceView.speakerView.bindAudioOutput(audioOutput)
        }

        let view = PreviewFooterView(deviceView: deviceView, isJoinMeeting: true, isPrelobby: true)

        let btn = view.commitBtn
        btn.setTitle(I18n.View_VM_LeaveButton, for: .normal)
        btn.setTitleColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgDangerPressed, for: .highlighted)
        btn.layer.borderWidth = 1.0
        btn.layer.ud.setBorderColor(UIColor.ud.functionDangerContentDefault)
        deviceView.micView.bindMeetingSetting(model.service.setting)
        return view
    }()

    init(model: PrelobbyContainerViewModel) {
        self.model = model
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayout(_ isRegular: Bool) {
        super.updateLayout(isRegular)
        footerView.updateLayout(isRegular: isRegular)
    }
}
