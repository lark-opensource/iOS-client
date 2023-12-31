//
//  InMeetReconnectingViewController.swift
//  ByteView
//
//  Created by kiri on 2020/11/5.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignCheckBox
import UniverseDesignColor
import UniverseDesignIcon

class InMeetReconnectingFloatingViewController: BaseViewController {
    struct Layout {
        static let loadingSize: CGFloat = 32
    }

    private lazy var vstack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.alignment = .center
        v.spacing = 4
        return v
    }()

    private lazy var loadingView = LoadingView(frame: CGRect(x: 0, y: 0, width: Layout.loadingSize, height: Layout.loadingSize), style: .blue)
    private lazy var loadingLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 1
        l.textColor = .ud.textCaption
        l.attributedText = .init(string: I18n.View_G_Connecting, config: .assist, alignment: .center)
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.vcTokenMeetingBgVideoOff
        view.layer.cornerRadius = 8.0
        view.layer.masksToBounds = true
        view.layer.ud.setBorderColor(UIColor.ud.lineDividerDefault)
        view.layer.borderWidth = 1.0
        view.addSubview(vstack)
        vstack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        vstack.addArrangedSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: Layout.loadingSize, height: Layout.loadingSize))
        }
        loadingView.play()

        vstack.addArrangedSubview(loadingLabel)
    }
}

class InMeetReconnectingViewController: BaseViewController {

    lazy var checkbox: UDCheckBox = UDCheckBox(boxType: .multiple) { [weak self] _ in
        self?.handleTapCheckBox()
    }

    lazy var backButton: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24 )), for: .normal)
        b.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
        return b
    }()

    lazy var leaveButton: UIButton = {
        let leaveButton = UIButton(type: .custom)
        leaveButton.layer.cornerRadius = 6
        leaveButton.layer.masksToBounds = true
        leaveButton.layer.borderWidth = 1
        leaveButton.layer.ud.setBorderColor(UIColor.ud.functionDangerContentDefault)
        leaveButton.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        leaveButton.setTitleColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        leaveButton.setTitle(I18n.View_M_LeaveMeetingButton, for: .normal)
        leaveButton.titleLabel?.font = .systemFont(ofSize: 17)
        leaveButton.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        leaveButton.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgDangerHover, for: .highlighted)
        leaveButton.addTarget(self, action: #selector(leave), for: .touchUpInside)
        return leaveButton
    }()

    lazy var pstnView: UIView = {
        let pstnView = UIView()
        pstnView.isHidden = true
        pstnView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapCheckBox)))
        return pstnView
    }()

    var isShowPstn = false
    private weak var meeting: InMeetMeeting?

    init(meeting: InMeetMeeting) {
        super.init(nibName: nil, bundle: nil)
        self.meeting = meeting
        if meeting.audioModeManager.isInCallMe {
            isShowPstn = true
            checkbox.isSelected = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBase

        let containerView = UIView()
        let container = UIView()
        self.view.addSubview(containerView)
        containerView.addSubview(container)

        container.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.right.equalToSuperview()
        }

        let loading = LoadingView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), style: .blue)
        container.addSubview(loading)
        loading.play()
        loading.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.centerX.equalToSuperview()
            maker.size.equalTo(CGSize(width: 40, height: 40))
        }

        let title = UILabel()
        title.attributedText = .init(string: I18n.View_VM_UnstableConnection, config: .body)
        title.textColor = UIColor.ud.textTitle
        container.addSubview(title)
        title.snp.makeConstraints { (maker) in
            maker.top.equalTo(loading.snp.bottom).offset(12)
            maker.centerX.equalToSuperview()
        }

        let content = UILabel(frame: CGRect.zero)
        content.attributedText = .init(string: I18n.View_G_TryingToReconnect, config: .bodyAssist)
        content.textColor = UIColor.ud.textPlaceholder
        content.numberOfLines = 0
        content.textAlignment = .center
        container.addSubview(content)
        content.snp.makeConstraints { (maker) in
            maker.top.equalTo(title.snp.bottom).offset(4)
            maker.centerX.equalToSuperview()
            maker.left.equalToSuperview().offset(16.0)
            maker.bottom.equalToSuperview()
        }

        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.left.equalTo(view.safeAreaLayoutGuide).offset(16)
        }

        self.view.addSubview(leaveButton)

        self.view.addSubview(pstnView)

        let pstnLabel = UILabel()
        pstnLabel.text = I18n.View_MV_StayConnectedByPhone
        pstnLabel.textColor = UIColor.ud.textTitle
        pstnLabel.font = .systemFont(ofSize: 16)

        pstnView.addSubview(checkbox)
        pstnView.addSubview(pstnLabel)

        pstnView.isHidden = !isShowPstn

        containerView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(leaveButton.snp.top)
            make.left.right.equalToSuperview()
        }

        layoutLeaveButton()

        pstnView.snp.makeConstraints { make in
            make.left.equalTo(checkbox.snp.left)
            make.right.equalTo(pstnLabel.snp.right)
            make.centerX.equalToSuperview()
            make.height.equalTo(22)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }

        checkbox.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.left.centerY.equalToSuperview()
        }

        pstnLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.equalTo(checkbox.snp.right).offset(8)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func layoutLeaveButton() {
        if currentLayoutContext.layoutType.isPhoneLandscape {
            leaveButton.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.equalTo(343)
                make.height.equalTo(48)
                make.bottom.equalTo(isShowPstn ? pstnView.snp.top : view.safeAreaLayoutGuide).offset(-16)
            }
        } else {
            leaveButton.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(48)
                make.bottom.equalTo(isShowPstn ? pstnView.snp.top : view.safeAreaLayoutGuide).offset(-16)
            }
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if newContext.layoutChangeReason.isOrientationChanged {
            self.layoutLeaveButton()
        }
    }

    @objc func leave() {
        logger.info("leave meeting from InMeetReconnectingViewController")
        guard let meeting = self.meeting else { return }
        if isShowPstn, checkbox.isSelected {
            meeting.camera.muteMyself(true, source: .callmeLeaveWithoutPstn, showToastOnSuccess: false, completion: nil)
        }
        meeting.leave(.userLeave(isHoldPstn: checkbox.isSelected))
    }

    @objc
    func handleTapCheckBox() {
        checkbox.isSelected = !checkbox.isSelected
    }

    @objc
    func backButtonAction() {
        meeting?.router.setWindowFloating(true)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
}
