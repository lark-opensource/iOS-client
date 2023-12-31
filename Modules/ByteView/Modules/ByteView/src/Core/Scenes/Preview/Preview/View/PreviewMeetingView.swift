//
//  PreviewMeetingView.swift
//  ByteView
//
//  Created by lutingting on 2023/5/31.
//

import Foundation
import AVFoundation
import ByteViewTracker
import RxSwift
import UniverseDesignTheme
import UniverseDesignIcon
import ByteViewUI
import ByteViewMeeting

struct PreviewViewModel {
    let session: MeetingSession
    let service: MeetingBasicService
    let isJoinByNumber: Bool
    let isJoiningMeeting: Bool
    let isJoinRoomEnabled: Bool
    let shouldShowUnderline: Bool
    let isLeftToRight: Bool
    let isWebinar: Bool
    var topic: String?
    let isCameraOn: Bool
    let camera: PreviewCameraManager
}

final class PreviewMeetingView: PreviewMeetingContainerView {

    struct Layout {
        static let replaceJoinTopMinOffset: CGFloat = 24
    }

    let model: PreviewViewModel

    override var leftItem: UIView { closeBtn }
    override var rightItem: UIView { connectRoomBtn }
    override var topView: UIView { headerView }
    override var middleView: UIView { contentView }
    override var bottomView: UIView { footerView }
    override var rightItemHeight: CGFloat { Display.pad ? 30 : 28 }

    private(set) lazy var closeBtn: UIButton = {
        let button = EnlargeTouchButton(padding: 10)
        let size: CGFloat = Display.pad ? 20 : 24
        let image = UDIcon.getIconByKey(Display.pad ? .closeOutlined : .closeSmallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: size, height: size))
        button.setImage(image, for: .normal)
        button.setImage(image, for: .highlighted)
        button.addInteraction(type: .highlight)
        return button
    }()

    private(set) lazy var connectRoomBtn: PreviewConnectRoomButton = {
        let btn = PreviewConnectRoomButton()
        btn.isHidden = true
        return btn
    }()

    private(set) lazy var headerView: PreviewChildView = model.isJoinByNumber ? meetingNumberHeaderView : topicHeaderView

    private(set) lazy var meetingNumberHeaderView: PreviewMeetingNumberHeaderView = {
        let view = PreviewMeetingNumberHeaderView()
        view.textField.firstBeginEditingAction = {
            VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "insert_title"])
        }
        return view
    }()

    private(set) lazy var topicHeaderView: PreviewTopicHeaderView = {
        let topic = model.isJoiningMeeting ? "" : model.topic ?? ""
        let view = PreviewTopicHeaderView(isLeftToRight: model.isLeftToRight, isEditable: model.shouldShowUnderline,
                                          topic: topic,
                                          isWebinar: model.isWebinar,
                                          isJoiningMeeting: model.isJoiningMeeting)
        view.textView.firstBeginEditingAction = {
            VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "insert_title"])
        }
        return view
    }()

    private(set) lazy var contentView = PreviewContentView(session: model.session, service: model.service, isCameraOn: model.isCameraOn, camera: model.camera)

    private(set) lazy var footerView = {
        let deviceView = PreviewDeviceView()
        let footerView = PreviewFooterView(deviceView: deviceView, isJoinMeeting: model.isJoiningMeeting, isPrelobby: false)
        let text = model.isJoiningMeeting ? I18n.View_G_JoinMeeting : I18n.View_M_MeetNow
        footerView.commitBtn.setTitle(text, for: .normal)
        return footerView
    }()

    var meetingNumberField: MeetingNumberField { meetingNumberHeaderView.textField }
    var errorLabel: UILabel { meetingNumberHeaderView.errorLabel }

    var avatarImageView: AvatarView { contentView.avatarImageView }
    var labButton: UIButton { contentView.labButton }


    var deviceView: PreviewDeviceView { footerView.deviceView }
    var micView: PreviewMicrophoneView { deviceView.micView }
    var speakerView: PreviewSpeakerView { deviceView.speakerView }
    var commitBtn: UIButton { footerView.commitBtn }

    init(model: PreviewViewModel) {
        self.model = model
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayout(_ isRegular: Bool) {
        super.updateLayout(isRegular)
        if Display.phone {
            overallLayoutGuide.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(footerView.phoneBottomHeight)
            }
        } else {
            bottomView.snp.remakeConstraints { make in
                make.top.equalTo(middleView.snp.bottom).offset(PreviewMeetingContainerView.Layout.bottomViewTopOffset)
                make.height.equalTo(PreviewMeetingContainerView.Layout.bottomViewHeight)
                make.left.right.equalTo(overallLayoutGuide)
                make.bottom.lessThanOrEqualTo(footerView.replaceJoinView.snp.top).offset(-Layout.replaceJoinTopMinOffset)
            }
        }
        footerView.updateLayout(isRegular: isRegular)
        footerView.updateReplaceJoinLayout(with: self)
    }
}
