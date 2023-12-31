//
//  LobbyViewController+Toolbar.swift
//  ByteView
//
//  Created by Prontera on 2020/6/30.
//

import Foundation
import Action
import AVFoundation
import AVKit
import RxCocoa
import RxSwift
import UniverseDesignIcon
import ByteViewSetting
import ByteViewNetwork

extension LobbyViewController {

    func setUpToolbar() {
        view.addSubview(bottomBar)
        bottomBar.snp.remakeConstraints { (maker) in
            maker.left.right.equalTo(view.safeAreaLayoutGuide)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(Display.pad ? 3 : 0)
            maker.height.equalTo(Display.phone ? 44 : 64)
        }
        if !viewModel.isCamMicHidden {
            setUpMicButton()
            setUpCameraButton()
        }
        setUpAudioButton()
        setUpToolbarHangupButton()
    }

    private func setUpMicButton() {
        viewModel.microphoneImage
            .drive { [weak self] image in
                self?.bottomBar.micItemView.image = image
            }.disposed(by: rx.disposeBag)

        viewModel.joinTogetherRoomRelay.asDriver()
            .drive(onNext: { [weak self] room in
                guard let self = self else { return }
                if room == nil {
                    self.bottomBar.micItemView.corner.cornerType = .empty
                    self.bottomBar.micItemView.imageView.tintColor = nil
                } else {
                    self.bottomBar.micItemView.corner.cornerType = .room(.disabled)
                    self.bottomBar.micItemView.imageView.tintColor = .ud.iconDisabled
                }
            }).disposed(by: rx.disposeBag)

        Driver.combineLatest(Privacy.micAccess.asDriver(), viewModel.joinTogetherRoomRelay.asDriver(), viewModel.isPadMicSpeakerDisabled.asDriver())
            .drive(onNext: { [weak self] (micAccess, room, isPadMicSpeakerDisabled) in
                guard let self = self else { return }
                self.bottomBar.micItemView.warningImageView.isHidden = room != nil || micAccess.isAuthorized || self.viewModel.audioMode == .pstn || self.viewModel.audioMode == .noConnect || isPadMicSpeakerDisabled
                let isDisabled: Bool
                if room != nil {
                    self.bottomBar.micItemView.title = I18n.View_G_ClickRoomMic_Button
                    isDisabled = true
                } else {
                    isDisabled = !self.viewModel.audioMode.micEnabled || isPadMicSpeakerDisabled
                    switch self.viewModel.audioMode {
                    case .internet:
                        self.bottomBar.micItemView.title = I18n.View_G_MicAbbreviated
                    case .pstn:
                        self.bottomBar.micItemView.title = I18n.View_G_Phone
                    case .noConnect:
                        self.bottomBar.micItemView.title = I18n.View_G_NoAudio_Icon
                    default:
                        self.bottomBar.micItemView.title = I18n.View_G_MicAbbreviated
                    }
                }
                let isDisabledColor = isDisabled || !micAccess.isAuthorized
                let normalColor = Display.phone ? UIColor.ud.textCaption : UIColor.ud.textTitle
                self.bottomBar.micItemView.titleColor = isDisabledColor ? UIColor.ud.textDisabled : normalColor
                self.bottomBar.micItemView.isUserInteractionEnabled = !isDisabled
            }).disposed(by: rx.disposeBag)

        bottomBar.micItemView.button.rx.tap.asDriver()
            .throttle(.milliseconds(600), latest: false)
            .drive(onNext: { [weak self] in
                self?.viewModel.handleMicrophone()
            }).disposed(by: rx.disposeBag)
    }

    private func setUpCameraButton() {
        // Camera
        viewModel.cameraImage
            .drive { [weak self] image in
                self?.bottomBar.cameraItemView.image = image
            }.disposed(by: rx.disposeBag)

        Privacy.cameraAccess
            .asDriver()
            .map { $0.isAuthorized }
            .drive(onNext: { [weak self] isAuthorized in
                self?.bottomBar.cameraItemView.warningImageView.isHidden = isAuthorized
                let normalColor = Display.phone ? UIColor.ud.textCaption : UIColor.ud.textTitle
                self?.bottomBar.cameraItemView.titleColor = isAuthorized ? normalColor : UIColor.ud.textDisabled
            })
            .disposed(by: rx.disposeBag)

        bottomBar.cameraItemView.button.addTarget(self, action: #selector(clickCameraBtn(sender:)), for: .touchUpInside)
        bottomBar.cameraItemView.button.rx.tap.asDriver()
            .throttle(.milliseconds(600), latest: false)
            .drive(onNext: { [weak self] in
                self?.viewModel.handleCamera()
            }).disposed(by: rx.disposeBag)
    }

    private func setUpAudioButton() {
        // Audio Switch
        bottomBar.speakerItemView.button.rx.tap.asDriver()
            // nolint-next-line: magic number
            .throttle(.milliseconds(600), latest: false)
            .drive(onNext: { [weak self] in
                self?.didClickSpeaker()
            }).disposed(by: rx.disposeBag)
        viewModel.joinTogetherRoomRelay.asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.bottomBar.isSpeakerItemHidden = $0 != nil || !self.viewModel.audioMode.audioEnabled
        }).disposed(by: rx.disposeBag)
        bottomBar.isSpeakerItemHidden = !viewModel.audioMode.audioEnabled
    }

    private func setUpToolbarHangupButton() {
        bottomBar.hangupButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.viewModel.hangUp()
            }).disposed(by: rx.disposeBag)
    }
}

private extension ParticipantSettings.AudioMode {
    var micEnabled: Bool {
        self != .noConnect
    }

    var audioEnabled: Bool {
        self == .internet || self == .unknown
    }
}
