//
//  PreviewContentView.swift
//  ByteView
//
//  Created by kiri on 2022/5/19.
//

import Foundation
import UIKit
import ByteViewCommon
import AVFoundation
import UniverseDesignIcon
import RxSwift
import ByteViewUI
import UniverseDesignColor
import ByteViewMeeting
import ByteViewRtcBridge
import ByteViewSetting

/// 内容区域，z-index: video -> avatar -> labButton -> assistLabel
final class PreviewContentView: PreviewChildView, StreamRenderViewListener {
    private let disposeBag = DisposeBag()
    private var isCameraOn: Bool
    private var isPrelobby: Bool = false

    private let camera: PreviewCameraManager
    private(set) lazy var streamRenderView: StreamRenderView = {
        let renderMode: ByteViewRenderMode = Display.phone ? .renderModeHidden : .renderModeFit
        let streamRenderView = StreamRenderView()
        streamRenderView.renderMode = renderMode
        streamRenderView.bindMeetingSetting(setting)
        streamRenderView.setStreamKey(.local)
        return streamRenderView
    }()

    private(set) lazy var avatarImageView: AvatarView = {
        let imageView = AvatarView()
        imageView.layer.masksToBounds = true
        imageView.removeMaskView()
        return imageView
    }()

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.vcTokenMeetingBgVideoOff
        view.layer.cornerRadius = 8
        view.addSubview(avatarImageView)
        return view
    }()

    private(set) lazy var labButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.vc.setBackgroundColor(UIColor.ud.N00.withAlphaComponent(0.8), for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.N00, for: .highlighted)
        button.addInteraction(type: .lift)
        return button
    }()

    private lazy var labButtonView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.layer.ud.setShadow(type: .s2Down)
        view.addSubview(labButton)
        labButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    private(set) lazy var assistLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.backgroundColor = .clear
        label.attributedText = NSAttributedString(string: I18n.View_G_SpeakUseRoomNotComputer_Desc(Display.pad ? I18n.View_G_Pad_Desc : I18n.View_G_Phone_Desc), config: .tinyAssist, alignment: .center, textColor: .ud.textTitle)
        label.numberOfLines = 2
        label.textInsets = .init(top: 10, left: 10, bottom: 12, right: 12)
        label.isHidden = true
        return label
    }()

    let session: MeetingSession
    let service: MeetingBasicService
    var setting: MeetingSettingManager { service.setting }
    init(session: MeetingSession, service: MeetingBasicService, isCameraOn: Bool,
         isPrelobby: Bool = false, camera: PreviewCameraManager) {
        self.session = session
        self.service = service
        self.isCameraOn = isCameraOn
        self.camera = camera
        super.init(frame: .zero)
        /// 会前等候室的 UI 需要在 PrelobbyViewController 中处理
        self.isPrelobby = isPrelobby

        clipsToBounds = true
        layer.cornerRadius = 8
        backgroundColor = UDColor.vcTokenMeetingBgVideoOff
        addSubview(streamRenderView)
        addSubview(backgroundView)
        addSubview(labButtonView)
        addSubview(assistLabel)

        backgroundView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(streamRenderView)
        }

        streamRenderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        avatarImageView.snp.makeConstraints { (maker) in
            maker.center.equalTo(streamRenderView)
            maker.size.equalTo(backgroundView.snp.height).multipliedBy(0.5)
        }
        labButtonView.snp.makeConstraints { (maker) in
            maker.size.equalTo(36)
            maker.top.right.equalToSuperview().inset(12)
        }

        assistLabel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(38)
        }

        streamRenderView.addListener(self)
        updateCameraOn(isCameraOn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCameraOn(_ isOn: Bool) {
        self.isCameraOn = isOn
        let isRendering = self.streamRenderView.isRendering
        self.backgroundView.isHidden = isOn && isRendering
        let color = isOn ? UIColor.ud.N00.withAlphaComponent(0.8) : UIColor.ud.vcTokenMeetingBgFloat.withAlphaComponent(0.8)
        let highlightColor = isOn ? UIColor.ud.N00 : UIColor.ud.vcTokenMeetingBgFloat
        self.labButton.vc.setBackgroundColor(color, for: .normal)
        self.labButton.vc.setBackgroundColor(highlightColor, for: .highlighted)
        self.assistLabel.backgroundColor = isOn ? .ud.N00.withAlphaComponent(0.8) : .ud.N900.withAlphaComponent(0.03)
    }

    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {
        self.updateCameraOn(isCameraOn)
    }

    func updateAvatarImageSize(isDenied: Bool) {
        avatarImageView.snp.remakeConstraints { (maker) in
            maker.center.equalTo(streamRenderView)
            maker.size.equalTo(backgroundView.snp.height).multipliedBy(isDenied ? 0.4 : 0.5)
        }
    }
}
