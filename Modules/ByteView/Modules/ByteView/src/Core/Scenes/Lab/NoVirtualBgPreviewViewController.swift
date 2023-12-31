//
//  NoVirtualBgPreviewViewController.swift
//  ByteView
//
//  Created by wangpeiran on 2022/12/9.
//

import Foundation
import SnapKit
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewCommon
import ByteViewMeeting
import ByteViewSetting
import ByteViewRtcBridge
import ByteViewUI

struct NoVirtualBgMuteParam {
    let muted: Bool
    let source: CameraActionSource
    var requestByHost: Bool = false
    var shouldShowToast: Bool = true
    var shouldHandleBgAllow: Bool = true
    var file: String = #fileID
    var function: String = #function
    var line: Int = #line
}

class NoVirtualBgPreviewViewController: BaseViewController {
    struct Layout {
        static let shortMargin: CGFloat = 8.0
        static let normalMargin: CGFloat = 12.0
        static let largeMargin: CGFloat = 16.0
        static let defaultHeight: CGFloat = 343.0
        static let buttonTopMargin: CGFloat = 24.0
        static let buttonHeight: CGFloat = 48.0
    }

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.bgBody
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    lazy var headerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault
        return view
    }()

    private lazy var closeButton: UIButton = {
        let button = EnlargeTouchButton(padding: 10)
        button.setImage(UDIcon.getIconByKey(.closeCircleColorful), for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return button
    }()

    private lazy var openCameraLable: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_ConfirmCamOnTitle
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private lazy var streamRenderView: StreamRenderView = {
        let streamRenderView = StreamRenderView()
        streamRenderView.renderMode = .renderModeHidden
        streamRenderView.setStreamKey(.local)
        streamRenderView.layer.cornerRadius = 10
        streamRenderView.layer.masksToBounds = true
        streamRenderView.bindMeetingSetting(setting)
        return streamRenderView
    }()

    private lazy var noticeLable: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: I18n.View_G_DisallowBackCheck, config: .bodyAssist)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        return label
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_G_ConfirmButton, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = .ud.primaryContentDefault
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        return button
    }()

    var openCameraBlock: (() -> Void)?

    private lazy var camera = RtcCamera(engine: service.rtc, scene: .inMeetLab)

    let service: MeetingBasicService
    var setting: MeetingSettingManager { service.setting }
    let effectManger: MeetingEffectManger

    init(service: MeetingBasicService, effectManger: MeetingEffectManger) {
        self.service = service
        self.effectManger = effectManger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        effectManger.virtualBgService.hasShowedNotAllowAlert = true

        isNavigationBarHidden = true
        setupViews()
        layoutViews()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if newContext.layoutChangeReason.isOrientationChanged || oldContext.layoutType != newContext.layoutType {
            self.layoutViews()
        }
    }

    func setupViews() {
        view.backgroundColor = .ud.bgMask
        if self.currentLayoutContext.layoutType.isRegular {
            view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else {
            view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }

        headerView.addSubview(openCameraLable)
        headerView.addSubview(closeButton)
        headerView.addSubview(lineView)

        containerView.addSubview(headerView)
        containerView.addSubview(streamRenderView)
        containerView.addSubview(noticeLable)
        containerView.addSubview(confirmButton)

        view.addSubview(containerView)

        layoutViews()
    }

    // disable-lint: duplicated code
    func layoutViews() {
        headerView.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }

        openCameraLable.snp.remakeConstraints { make in
            make.top.bottom.left.equalToSuperview().inset(12)
            make.right.equalTo(closeButton.snp.left).offset(8)
        }

        closeButton.snp.remakeConstraints { make in
            make.size.equalTo(24)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }

        lineView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1.0 / view.vc.displayScale)
        }

        if currentLayoutContext.layoutType.isRegular {  // ipad r视图
            streamRenderView.snp.remakeConstraints { make in
                make.top.equalTo(headerView.snp.bottom).offset(16)
                make.left.right.equalToSuperview().inset(16)
                make.size.equalTo(Layout.defaultHeight)
            }

            containerView.snp.remakeConstraints { make in
                make.width.equalTo(375)
                make.center.equalToSuperview()
                make.bottom.equalTo(confirmButton.snp.bottom).offset(24)
            }
        } else if currentLayoutContext.layoutType.isPhoneLandscape {  //横屏
            streamRenderView.snp.remakeConstraints { make in
                make.top.equalTo(headerView.snp.bottom).offset(12)
                make.centerX.equalToSuperview()
                if VCScene.bounds.height >= 375 {
                    make.height.equalTo(180)
                } else {
                    make.height.equalTo(120)
                }
                make.width.equalTo(streamRenderView.snp.height).multipliedBy(16.0 / 9.0)
            }

            containerView.snp.remakeConstraints { make in
                make.top.greaterThanOrEqualToSuperview().offset(8)
                make.width.equalTo(420)
                make.centerX.equalToSuperview()
                make.bottom.equalTo(self.view.snp.bottom)
                make.bottom.equalTo(confirmButton.snp.bottom).offset(40)
            }
        } else { // 竖屏
            streamRenderView.snp.remakeConstraints { make in
                make.top.equalTo(headerView.snp.bottom).offset(16)
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(streamRenderView.snp.width)
            }

            containerView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.view.snp.bottom)
                make.bottom.equalTo(confirmButton.snp.bottom).offset(40)
            }
        }

        noticeLable.snp.remakeConstraints { make in
            make.top.equalTo(streamRenderView.snp.bottom).offset(currentLayoutContext.layoutType.isPhoneLandscape ? 8 : 12)
            make.left.right.equalToSuperview().inset(16)
        }

        confirmButton.snp.remakeConstraints { make in
            make.top.equalTo(noticeLable.snp.bottom).offset(currentLayoutContext.layoutType.isPhoneLandscape ? 8 : 24)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
    }
    // enable-lint: duplicated code

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera.setMuted(false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        camera.setMuted(true)
    }

    deinit {
        Logger.lab.info("NoVirtualBgPreviewViewController deinit")
    }

    @objc private func closeAction() {
        self.dismiss(animated: true)
    }

    @objc private func confirmAction() {
        openCameraBlock?()
        self.dismiss(animated: true)
    }

    override var shouldAutorotate: Bool {
        return  false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}
