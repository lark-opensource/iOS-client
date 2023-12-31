//
//  InMeetParticipantGridCell+Binding.swift
//  ByteView
//
//  Created by liujianlong on 2021/6/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewCommon
import ByteViewNetwork

extension InMeetingParticipantGridCell {
    func bind(viewModel: InMeetGridCellViewModel) {
        let disposeBag = DisposeBag()
        self.disposeBag = disposeBag
        viewModel.isActiveSpeaker
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isTalking in
                self?.isTalking = isTalking
            })
            .disposed(by: disposeBag)
        self.participantView.bind(viewModel: viewModel, layoutType: "gallery")
    }
}

struct ParticipantUserInfoStatus: Equatable, CustomStringConvertible {
    var hasRoleTag: Bool
    var meetingRole: ParticipantMeetingRole
    var isSharing: Bool
    var isFocusing: Bool
    var isMute: Bool
    var isLarkGuest: Bool
    var name: String
    var attributedName: NSAttributedString?
    var isRinging: Bool
    var isMe: Bool
//    var showNameAndMicOnly: Bool
    var rtcNetworkStatus: RtcNetworkStatus?
    var audioMode: ParticipantSettings.AudioMode
    var is1v1: Bool
    var conditionEmoji: ParticipantSettings.ConditionEmojiInfo?
    let meetingSource: VideoChatInfo.MeetingSource?
    var isRoomConnected: Bool
    var isLocalRecord: Bool
    let isMicAuthorized = Privacy.micAccess.value.isAuthorized

    var description: String {
        "hasRoleTag: \(hasRoleTag), meetingRole: \(meetingRole.rawValue), isSharing: \(isSharing), isFocusing:\(isFocusing), isMute: \(isMute), name: \(name.hash), isRinging: \(isRinging), isMe: \(isMe), rtcNetworkStatus: \(rtcNetworkStatus) audioMode: \(audioMode), conditionEmoji: \(conditionEmoji), meetingSource: \(meetingSource), isRoomConnected: \(isRoomConnected), isLocalRecord: \(isLocalRecord)"
    }
}

// nolint: long_function
extension InMeetingParticipantView {
    func bind(viewModel: InMeetGridCellViewModel, enableConditionEmoji: Bool = true, layoutType: String) {
        let bag = DisposeBag()
        self.disposeBag = bag
        self.cellViewModel = viewModel
        viewModel.context.addListener(self, for: .containerLayoutStyle)
        Self.logger.info("bind participant view \(viewModel.pid)")
        self.streamRenderView.layoutType = layoutType
        streamRenderView.bindMeetingSetting(viewModel.meeting.setting)

        let participant = viewModel.participant.asObservable()
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)

        if viewModel.pid == viewModel.meeting.account {
            Self.logger.info("ParticipantView is showing local video")
            self.streamRenderView.setStreamKey(.local)
        } else {
            viewModel.isPortraitMode
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] isPortrait in
                    guard let self = self else {
                        return
                    }
                    if isPortrait {
                        Self.logger.info("ParticipantView is in portrait mode when sharing screen")
                        self.streamRenderView.setStreamKey(nil)
                    } else {
                        Self.logger.info("ParticipantView is showing remote video")
                        self.streamRenderView.setStreamKey(.stream(uid: viewModel.rtcUid,
                                                                   sessionId: viewModel.meeting.sessionId),
                                                           isSipOrRoom: viewModel.pid.isSipOrRoom)
                    }
                })
                .disposed(by: bag)

        }

        viewModel.participantInfo
            .map { $0.1.avatarInfo }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] avatarInfo in
                guard let self = self else { return }
                self.imageInfo = avatarInfo
            })
            .disposed(by: bag)

        userInfoView.isHidden = true
        viewModel.isConnected
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isConnected in
                self?.isConnected = isConnected
            })
            .disposed(by: bag)

        participant
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] participant in
                guard let self = self else {
                    return
                }
                self.showsRipple = participant.status != .onTheCall
            })
            .disposed(by: bag)

        viewModel.participantInfo
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] userInfo in
                guard let self = self else {
                    return
                }
                self.systemCallingStatusValue = userInfo.0.settings.mobileCallingStatus
            })
            .disposed(by: bag)

        let isMe = viewModel.isMe
        let is1V1 = viewModel.meeting.participant.currentRoom.nonRingingCount == 2

        Observable.combineLatest(viewModel.sharingUserIdentifiers,
                                 viewModel.focusingUser,
                                 viewModel.participantInfo,
                                 viewModel.hasRoleTag,
                                 viewModel.rtcNetworkStatus,
                                 InMeetOrientationToolComponent.isLandscapeModeRelay.asObservable(),
                                 Privacy.micAccess.asObservable())
        .map({ (sharingUsers: Set<ByteviewUser>, focusingUser: ByteviewUser?, participantInfo: (Participant, ParticipantUserInfo), hasRoleTag: Bool, rtcNetworkStatus: RtcNetworkStatus?, isLandscapeMode: Bool, _) in
            // 其他别名显示收敛在InMeetParticipantService中。此处用户名展示异化为：当参会人在“呼叫中”时，仅显示原名或别名
            let anotherName = viewModel.meeting.setting.isShowAnotherNameEnabled ? participantInfo.1.user?.anotherName ?? participantInfo.1.originalName : participantInfo.1.originalName
            return Self.makeUserInfoStatus(
                sharingUsers: sharingUsers,
                focusingUser: focusingUser,
                name: participantInfo.1.name,
                originalName: anotherName,
                participant: participantInfo.0,
                hasRoleTag: hasRoleTag,
                rtcNetworkStatus: rtcNetworkStatus,
                isMe: isMe,
                isLandscapeMode: isLandscapeMode,
                is1V1: is1V1,
                meetingSource: viewModel.meeting.info.meetingSource)
        })
        .distinctUntilChanged()
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] userInfo in
            guard let self = self else {
                return
            }
            self.userInfoView.isHidden = false
            self.reloadUserStatusInfoView2(userInfo: userInfo)
            if enableConditionEmoji {
                self.updateStatusEmojiInfo(statusEmojiInfo: userInfo.conditionEmoji)
            }
        })
        .disposed(by: bag)
        if !enableConditionEmoji {
            self.updateStatusEmojiInfo(statusEmojiInfo: nil)
        }

        if viewModel.isMe {
            // 宫格视图刚创建时，userInfoView 的状态可能未更新，直到上面的 subscribe 方法执行前存在一段真空期，
            // 此时userInfoView 的麦克风图标可能跟实际状态不符，因此这里延迟一段时间注册监控
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                guard let self = self, self.cellViewModel?.isMe == true else { return }
                viewModel.meeting.syncChecker.registerCamera(self, for: self.syncCheckId)
                viewModel.meeting.syncChecker.registerMicrophone(self, for: self.syncCheckId)
            })
        } else {
            viewModel.meeting.syncChecker.unregisterCamera(self, for: syncCheckId)
            viewModel.meeting.syncChecker.unregisterMicrophone(self, for: syncCheckId)
        }

        Observable.combineLatest(viewModel.participant, viewModel.meetingLayoutStyle)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (participant, layoutStyle) in
                guard let self = self else { return }
                if layoutStyle == .fullscreen {
                    self.switchCameraButton.isHidden = true
                } else if !Privacy.cameraAccess.value.isAuthorized || Util.isiOSAppOnMacSystem || !self.shouldShowSwitchCamera {
                    self.switchCameraButton.isHidden = true
                } else {
                    self.switchCameraButton.isHidden = !isMe || participant.settings.isCameraMutedOrUnavailable
                }
            })
            .disposed(by: bag)
        switchCameraButton.rx.action = switchCameraAction

        let localParticipant = viewModel.meeting.myself
        // webinarAttendee 屏蔽双击全屏操作
        let isWebinarAttendee = viewModel.meeting.isWebinarAttendee
        self.streamRenderView.isUserInteractionEnabled = !isWebinarAttendee
        Observable.combineLatest(self.styleRelay.asObservable(),
                                 participant,
                                 viewModel.hasHostAuthority,
                                 viewModel.couldCancelInvite,
                                 viewModel.meetingLayoutStyle)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _, participant, hasHostAuthority, couldCancelInvite, meetingLayoutStyle in
                guard let self = self else {
                    return
                }
                let isSingleVideoEnable = self.styleConfig.isSingleVideoEnabled && participant.status == .onTheCall
                let showMoreSelectionToReplaceCancelButton = self.styleConfig.isSingleRow || self.styleConfig.isSpeechFloat
                self.cancelButton.isHidden = showMoreSelectionToReplaceCancelButton || !couldCancelInvite || meetingLayoutStyle == .fullscreen
                if isWebinarAttendee,
                   participant.user != localParticipant.user {
                    // webinarAttendee 对非自己不展示 moreSelectionButton
                    self.moreSelectionButton.isHidden = true
                } else if meetingLayoutStyle == .fullscreen {
                    self.moreSelectionButton.isHidden = true
                } else if couldCancelInvite {
                    self.moreSelectionButton.isHidden = !showMoreSelectionToReplaceCancelButton
                } else if participant.status == .ringing {
                    self.moreSelectionButton.isHidden = true
                } else if self.styleConfig.isSingleRow || hasHostAuthority || isMe {
                    self.moreSelectionButton.isHidden = false
                } else {
                    var enableConveniencePSTN: Bool = false
                    if let meeting = self.cellViewModel?.meeting {
                        enableConveniencePSTN = ConveniencePSTN.enableInviteParticipant(participant, local: localParticipant,
                                                                                        featureManager: meeting.setting, meetingTenantId: meeting.info.tenantId, meetingSubType: meeting.subType)
                    }
                    self.moreSelectionButton.isHidden = !isSingleVideoEnable && !enableConveniencePSTN
                }
            })
            .disposed(by: bag)

        userInfoView.didTapUserName = { [weak self] in
            guard let self = self, let participant = self.cellViewModel?.participant.value else { return }
            self.didTapUserName?(participant)
        }

        self.avatar.isHidden = false
        self.cameraHaveNoAccessImageView.isHidden = true
        self.streamRenderView.isHidden = true
        Observable.combineLatest(participant,
                                 viewModel.isPortraitMode,
                                 self.isRenderingRelay,
                                 Privacy.cameraAccess)
            .distinctUntilChanged({ $0 == $1 })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] participant, isPortraitMode, isRendering, _ in
                guard let self = self else {
                    return
                }
                self.updateAvatarVisibility2(participant: participant,
                                             isMe: isMe,
                                             isPortraitMode: isPortraitMode,
                                             isRendering: isRendering)
            })
            .disposed(by: bag)

        self.updateLayoutWith(style: viewModel.context.meetingLayoutStyle)
    }

    private static func makeUserInfoStatus(sharingUsers: Set<ByteviewUser>,
                                           focusingUser: ByteviewUser?,
                                           name: String,
                                           originalName: String,
                                           participant: Participant,
                                           hasRoleTag: Bool,
                                           rtcNetworkStatus: RtcNetworkStatus?,
                                           isMe: Bool,
                                           isLandscapeMode: Bool,
                                           is1V1: Bool,
                                           meetingSource: VideoChatInfo.MeetingSource) -> ParticipantUserInfoStatus {
        let isSharingContent = sharingUsers.contains(participant.user)
        let isFocusing = focusingUser == participant.user
        let meetingRole: ParticipantMeetingRole = participant.meetingRole
        let isMute = participant.settings.isMicrophoneMutedOrUnavailable
        let isLarkGuest = participant.isLarkGuest
        let name = name
        let isRinging = participant.status == .ringing
        let userInfoStatus = ParticipantUserInfoStatus(
            hasRoleTag: hasRoleTag,
            meetingRole: meetingRole,
            isSharing: isSharingContent,
            isFocusing: isFocusing,
            isMute: isMute,
            isLarkGuest: isLarkGuest,
            name: isRinging ? originalName : name,
            isRinging: isRinging,
            isMe: isMe,
//            showNameAndMicOnly: false,
            rtcNetworkStatus: rtcNetworkStatus,
            audioMode: participant.settings.audioMode,
            is1v1: is1V1,
            conditionEmoji: participant.settings.conditionEmojiInfo,
            meetingSource: meetingSource,
            isRoomConnected: participant.settings.targetToJoinTogether != nil,
            isLocalRecord: participant.settings.localRecordSettings?.isLocalRecording == true)
        return userInfoStatus
    }

    private func reloadUserStatusInfoView2(userInfo: ParticipantUserInfoStatus) {
        Self.logger.info("\(self.cellViewModel?.pid.deviceId), reloadUserInfo \(userInfo)")
        userInfoView.userInfoStatus = userInfo
    }

    private func updateAvatarVisibility2(participant: Participant,
                                         isMe: Bool,
                                         isPortraitMode: Bool,
                                         isRendering: Bool) {
        let settings = participant.settings

        Self.logger.info("\(participant.rtcUid) isMe: \(isMe), isMuted: \(settings.isCameraMuted), status: \(settings.cameraStatus), isRendering: \(isRendering)")

        if isMe && !Privacy.cameraAccess.value.isAuthorized {
            Self.logger.info("\(participant.rtcUid) show cameraHaveNoAccessImageView")
            avatar.isHidden = true
            cameraHaveNoAccessImageView.isHidden = false
            self.streamRenderView.isHidden = true
        } else if !settings.isCameraMutedOrUnavailable && isRendering && !isPortraitMode {
            Self.logger.info("\(participant.rtcUid) show streamRenderView")
            avatar.isHidden = true
            cameraHaveNoAccessImageView.isHidden = true
            self.streamRenderView.isHidden = false
        } else {
            Self.logger.info("\(participant.rtcUid) show avatar")
            avatar.isHidden = false
            cameraHaveNoAccessImageView.isHidden = true
            self.streamRenderView.isHidden = true
        }

    }
}

extension InMeetingParticipantView: MicrophoneStateRepresentable, CameraStateRepresentable {
    static let syncCheckId = "Grid"

    var cameraIdentifier: String {
        Self.syncCheckId
    }

    var isCameraMuted: Bool? {
        // 仅检测用户rust摄像头状态为关闭且宫格流可见时，视频不能处于渲染状态
        if isVisible && cellViewModel?.participant.value.settings.isCameraMutedOrUnavailable == true {
            return streamRenderView.isHidden
        }
        // 其他情况一律绕过检测
        return nil
    }

    var micIdentifier: String {
        Self.syncCheckId
    }

    var isMicMuted: Bool? {
        if isVisible {
            return userInfoView.isMicMuted
        } else {
            Logger.privacy.info("[Mic] Self grid is invisible")
            return nil
        }
    }

    private var isVisible: Bool {
        let isAttachedToWindow = window != nil
        let isActive = UIApplication.shared.applicationState != .background
        return isCellVisible && isAttachedToWindow && isActive
    }
}
