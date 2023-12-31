//
//  ConnectFailedViewController.swift
//  ByteView
//
//  Created by huangshun on 2019/3/31.
//

import Foundation
import RxCocoa
import RxSwift
import SnapKit
import ByteViewMeeting
import ByteViewUI
import UniverseDesignToast

class ConnectFailedViewController: VMViewController<ConnectFailedViewModel> {
    let topicLable: UILabel = UILabel(frame: CGRect.zero)

    // 加入会议
    let failView: UIView = UIView(frame: CGRect.zero)
    let closeButton: UIButton = UIButton(type: .custom)
    let rejoinButton: UIButton = UIButton(type: .custom)

    // loading
    let rejoinView: UIView = UIView(frame: CGRect.zero)
    let cancelButton: UIButton = UIButton(type: .custom)
    private let disposeBag = DisposeBag()

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgBase
        makeFailedUI()
        makeConnectingUI()
    }

    func makeFailedUI() {
        view.addSubview(failView)
        failView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
            maker.centerY.equalToSuperview().offset(currentLayoutContext.layoutType.isPhoneLandscape ? 0 : -71)
        }

        let imageView = UIImageView(image: CommonResources.ConnectFailWiFi)
        failView.addSubview(imageView)
        imageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(currentLayoutContext.layoutType.isPhoneLandscape ? 120 : 125)
            maker.top.equalToSuperview()
            maker.centerX.equalToSuperview()
        }

        let title = UILabel()
        title.textColor = UIColor.ud.textTitle
        title.attributedText = .init(string: I18n.View_M_YouLeftMeeting, config: .h4)
        failView.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        let content = UILabel()
        content.textColor = UIColor.ud.textCaption
        content.attributedText = .init(string: I18n.View_M_CheckConnectionRejoin, config: .bodyAssist)
        content.numberOfLines = 0
        content.textAlignment = .center
        failView.addSubview(content)
        content.snp.makeConstraints { (make) in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
        }

        closeButton.layer.cornerRadius = 4
        closeButton.layer.masksToBounds = true
        closeButton.layer.borderWidth = 1
        closeButton.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        closeButton.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        closeButton.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        closeButton.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        closeButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        closeButton.setTitle(I18n.View_G_CloseButton, for: .normal)
        failView.addSubview(closeButton)
        closeButton.snp.makeConstraints { (maker) in
            maker.width.greaterThanOrEqualTo(76)
            maker.height.equalTo(36)
            maker.top.equalTo(content.snp.bottom).offset(24)
            maker.bottom.equalToSuperview()
            maker.right.equalTo(failView.snp.centerX).offset(-8)
        }

        rejoinButton.layer.cornerRadius = 4
        rejoinButton.layer.masksToBounds = true
        rejoinButton.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        rejoinButton.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        rejoinButton.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        rejoinButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        rejoinButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        rejoinButton.setTitle(I18n.View_G_RejoinButton, for: .normal)
        failView.addSubview(rejoinButton)
        rejoinButton.snp.makeConstraints { (maker) in
            maker.width.greaterThanOrEqualTo(76)
            maker.height.equalTo(closeButton)
            maker.centerY.equalTo(closeButton)
            maker.left.equalTo(failView.snp.centerX).offset(8)
        }
    }

    func makeConnectingUI() {
        self.view.addSubview(rejoinView)
        rejoinView.isHidden = true
        rejoinView.snp.makeConstraints { (maker) in
            maker.left.right.equalTo(failView)
            maker.centerY.equalToSuperview()
        }

        let loading = LoadingView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), style: .blue)
        rejoinView.addSubview(loading)
        loading.play()
        loading.snp.makeConstraints { (maker) in
            maker.centerX.top.equalToSuperview()
            maker.top.equalToSuperview()
            maker.width.height.equalTo(40)
        }

        let connectingLabel = UILabel()
        connectingLabel.textColor = UIColor.ud.textTitle
        connectingLabel.attributedText = .init(string: I18n.View_G_Connecting, config: .body)
        rejoinView.addSubview(connectingLabel)
        connectingLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(loading.snp.bottom).offset(12)
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().offset(-60)
        }

        cancelButton.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
        cancelButton.layer.cornerRadius = 4
        cancelButton.layer.borderWidth = 2
        cancelButton.layer.ud.setBorderColor(.ud.lineBorderComponent)
        cancelButton.layer.masksToBounds = true
        cancelButton.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        cancelButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        cancelButton.setTitle(I18n.View_G_CancelButton, for: .normal)
        cancelButton.isHidden = true
        rejoinView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(connectingLabel.snp.bottom).offset(24)
            maker.width.greaterThanOrEqualTo(76)
            maker.height.equalTo(36)
            maker.centerX.equalToSuperview()
        }
    }

    override func bindViewModel() {
        rejoinButton.addTarget(self, action: #selector(rejoin), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    }

    @objc func rejoin() {
        if let session = MeetingManager.shared.currentSession, session.isActive {
            let text = session.state == .ringing ? I18n.View_V_IncomingCallCannotVideo : I18n.View_G_CurrentlyInCall
            Toast.show(text)
            return
        }

        rejoinView.isHidden = false
        failView.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak self] in
            self?.cancelButton.isHidden = false
        }
        let meetingRole = self.viewModel.session.myself?.meetingRole ?? .participant
        viewModel.session.rejoinMeeting(forceDeblock: false, meetingRole: meetingRole, leaveOnError: false) { [weak self] r in
            guard let self = self else { return }
            if let error = r.error {
                let description = error.description
                if error == .participantsOverload {
                    Toast.show(description, type: .error)
                } else {
                    Toast.show(description)
                }
                if error == .hostIsInVC {
                    Self.logger.info("leave from rejoin by info")
                    self.showRejoinAlert()
                } else {
                    Self.logger.info("leave from rejoin by error")
                    self.leave()
                }
            }
        }
    }

    private func showRejoinAlert() {
        let meetingRole = self.viewModel.session.myself?.meetingRole ?? .participant
        ByteViewDialog.Builder()
            .id(.exitCallByJoinMeeting)
            .colorTheme(.firstButtonBlue)
            .needAutoDismiss(true)
            .title(I18n.View_M_JoinMeetingQuestion)
            .message(I18n.View_M_LeaveAndJoinQuestion)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ [weak self] _ in
                self?.leave()
            })
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                // 生成hud
                let hud = UDToast.showLoading(with: I18n.View_VM_Loading, on: self.view)
                self.viewModel.session.rejoinMeeting(forceDeblock: true, meetingRole: meetingRole, leaveOnError: true) { _ in
                    hud.remove()
                }
            })
            .show()
    }

    @objc func close() {
        logger.info("leave from connect failed by close")
        leave()
    }

    @objc func cancel() {
        logger.info("leave from connect failed by cancel")
        leave()
    }

    private func leave() {
        self.viewModel.session.leave()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
}
