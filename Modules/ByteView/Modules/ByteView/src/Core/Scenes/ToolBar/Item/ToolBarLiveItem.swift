//
//  ToolBarLiveItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewUI
import ByteViewNetwork
import RxSwift
import RxCocoa
import UIKit
import ByteViewTracker
import ByteViewSetting

struct LiveCondition {
    let isVideoCall: Bool
    let isHost: Bool
    let isLiving: Bool
    let meetingHostEnable: Bool

    var isAskLiveEnabled: Bool {
        // meeting，非主持人，当前没在直播，且主持人在会中
        return !isVideoCall && !isHost && !isLiving && meetingHostEnable
    }

    var isCopyLiveLinkEnabled: Bool {
        // 非主持人，当前正在直播，且主持人在会中
        return !isHost && isLiving && meetingHostEnable
    }

    var isLiveEnabled: Bool {
        if isVideoCall {
            // 1. 1v1 任何人支持发起或结束直播
            return true
        } else {
            // 2. 会议中只有主持人并且在会中时才能发起或结束直播
            return isHost
        }
    }
}

final class ToolBarLiveItem: ToolBarItem {
    private var state: LiveState = .live
    private var placeholderId: String?
    private let liveViewModel: InMeetLiveViewModel
    private let disposeBag = DisposeBag()

    override var itemType: ToolBarItemType { .live }

    override var title: String {
        switch state {
        case .copyLiveURL: return I18n.View_M_CopyLivestreamingLinkNew
        case .live, .askLive: return I18n.View_M_LivestreamNew
        }
    }

    override var filledIcon: ToolBarIconType {
        switch state {
        case .copyLiveURL: return .icon(key: .sharelinkFilled)
        case .live, .askLive: return .icon(key: .livestreamFilled)
        }
    }

    override var outlinedIcon: ToolBarIconType {
        switch state {
        case .copyLiveURL: return .icon(key: .globalLinkOutlined)
        case .live, .askLive: return .icon(key: .livestreamOutlined)
        }
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsLive ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsLive ? .more : .none
    }

    private var _isEnabled = true
    override var isEnabled: Bool {
        _isEnabled
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.liveViewModel = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.data.addListener(self, fireImmediately: false)
        self.addBadgeListener()
        meeting.setting.addListener(self, for: [.showsLive, .canOperateLive, .hasHostAuthority])
        self.updateLiveItem(notifyListeners: false)

        Observable.combineLatest(self.liveViewModel.isVoting.map { $0.0 }, self.liveViewModel.isEnableStartLive) { ($0, $1) }
            .subscribe(onNext: { [weak self] (isVoting, isEnableStartLive) in
                guard let self = self else { return }
                var isEnabled = self._isEnabled
                switch self.state {
                case .live:
                    if meeting.setting.isLiveLegalEnabled {
                        isEnabled = !isVoting
                    } else {
                        isEnabled = true
                    }
                case .askLive:
                    if meeting.setting.isLiveLegalEnabled {
                        isEnabled = isEnableStartLive && !isVoting
                    } else {
                        isEnabled = isEnableStartLive
                    }
                default:
                    break
                }
                if isEnabled != self.isEnabled {
                    Logger.ui.info("Toolbar live item isEnabled state changed from \(self.isEnabled) to \(isEnabled)")
                    self._isEnabled = isEnabled
                    self.notifyListeners()
                }
            }).disposed(by: self.disposeBag)
    }

    override func clickAction() {
        guard meeting.setting.canOperateLive else {
            Toast.show(I18n.View_MV_FeatureNotOnYet_Hover)
            return
        }

        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            switch self.state {
            case .live:
                self.liveAction()
            case .askLive:
                self.askLiveAction()
            case .copyLiveURL:
                self.copyLiveURLAction()
            }
        }
    }

    // MARK: - Live

    private func liveAction() {
        guard provider != nil else { return }

        MeetingTracksV2.trackMeetingClickOperation(action: .clickLive,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: true)
        if Display.phone, VCScene.isLandscape {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .click_function)
        }
        MeetSettingTracks.trackTapLiveSettings(isLiving: liveViewModel.isLiving, liveId: liveViewModel.liveInfo?.liveID)
        meeting.httpClient.getResponse(GetLivePermissionRequest()) { [weak self] r in
            guard let self = self else { return }
            if let response = r.value {
                Util.runInMainThread {
                    if response.needVerification {
                        self.showCertAlert()
                    } else {
                        self.showUnavailableViewOrLiveSettings()
                    }
                }
            } else {
                if let error = r.error as? RustBizError {
                    MeetingTracksV2.trackClickLiveItemFail(errorCode: error.code, errorDescription: error.displayMessage)
                } else {
                    MeetingTracksV2.trackClickLiveItemFail()
                }
            }
        }
    }

    private func showUnavailableViewOrLiveSettings() {
        self.liveViewModel.getLiveProviderAvailableStatus()
            .subscribe(onSuccess: { [weak self] status in
                guard let self = self else { return }
                Util.runInMainThread {
                    if self.liveViewModel.shouldShowLiveUnavailableView {
                        self.showUnavailableView(liveProviderStatus: status)
                    } else {
                        self.showLiveSettings(liveProviderStatus: status)
                    }
                }
            }, onError: { _ in
                Toast.show(I18n.View_M_LivestreamingErrorTryAgainLaterNew)
            })
            .disposed(by: disposeBag)
    }

    private func showCertAlert() {
        ByteViewDialog.Builder()
            .id(.liveCert)
            .title(I18n.View_G_PersonalRealNameAuthentication)
            .message(I18n.View_G_AuthenticateToLivestreamLegal)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "identity_verification_popup", .action_name: "cancel"])
            })
            .rightTitle(I18n.View_G_GoToAuthentication).rightHandler({ [weak self] _ in
                VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "identity_verification_popup", .action_name: "confirm"])
                self?.showCertStage()
            })
            .show { _ in
                VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "identity_verification_popup", .action_name: "display"])
            }
    }

    private func showCertStage() {
        guard let from = self.provider?.hostViewController else { return }
        self.meeting.larkRouter.gotoLiveCert(from: from, wrap: NavigationController.self) { result in
            if result.isSuccess {
                VCTracker.post(name: .vc_live_setting_page, params: [.from_source: "identity_verification_success", .action_name: "display"])
                self.showUnavailableViewOrLiveSettings()
            }
        }
    }

    private func showLiveSettings(liveProviderStatus: LiveProviderAvailableStatus) {
        let vm = LiveSettingsViewModel(meeting: self.meeting, live: self.liveViewModel, liveProviderStatus: liveProviderStatus, liveSource: .host)
        let viewController = LiveSettingsViewController(viewModel: vm)
        meeting.router.presentDynamicModal(viewController,
                                          regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                          compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
    }

    private func showUnavailableView(liveProviderStatus status: LiveProviderAvailableStatus) {
        guard let response = status.response else { return }
        LiveSettingUnavailableAlert
            .unavailableAlert(type: status.byteLiveUnAvailableType, role: response.userInfo.role)
            .rightHandler({ _ in
                self.liveViewModel.showByteLiveAppIfNeeded()
                self.liveViewModel.showByteLiveBotAndSendMessageIfNeeded()
            })
            .show()
    }

    // MARK: - Ask Live

    private func askLiveAction() {
        MeetingTracksV2.trackMeetingClickOperation(action: .clickLive,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: true)
        didTapAskLive()
    }

    private func didTapAskLive() {
        if meeting.data.isOpenBreakoutRoom {
            Toast.show(I18n.View_G_BreakoutRoomsNoSupport)
            return
        }
        ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .sendLiveRequest)
        let title = I18n.View_G_AskHostToLivestreamQuestion
        let message = I18n.View_G_AskHostToLivestreamInfo

        ByteViewDialog.Builder()
            .id(.conformRequestLiving)
            .title(title)
            .message(message)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                MeetSettingTracks.trackConfirmRequstLiving(false)
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .sendLiveRequest,
                                                         action: "cancel")
            })
            .rightTitle(I18n.View_M_SendRequest)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                MeetSettingTracks.trackConfirmRequstLiving(true)
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .sendLiveRequest,
                                                         action: "send_request")
                if self.meeting.setting.hasHostAuthority {
                    Toast.show(I18n.View_G_CouldNotSendRequest)
                } else {
                    self.requestLive()
                }
            })
            .needAutoDismiss(true)
            .show()
    }

    private func requestLive() {
        MeetSettingTracks.trackTapLive(isLiving: self.liveViewModel.isLiving, liveId: self.liveViewModel.liveInfo?.liveID)
        self.liveViewModel.getLiveProviderAvailableStatus()
            .subscribe(onSuccess: { [weak self] status in
                guard let self = self else { return }
                if status.isProviderByteLive {
                    self.liveViewModel.updateByteLiveAction(action: .participantRequestStart,
                                                            user: nil,
                                                            livePermission: nil,
                                                            enableChat: nil,
                                                            layout: nil,
                                                            member: nil)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onCompleted: {
                        Toast.show(I18n.View_G_RequestSent)
                    }).disposed(by: self.disposeBag)
                } else {
                    self.liveViewModel.updateLarkLiveAction(action: .participantRequestStart,
                                                            user: nil,
                                                            voteID: nil,
                                                            privilege: nil,
                                                            enableChat: nil,
                                                            enablePlayback: nil,
                                                            layout: nil,
                                                            member: nil)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onCompleted: {
                        Toast.show(I18n.View_G_RequestSent)
                    }).disposed(by: self.disposeBag)
                }
            }, onError: { _ in
                Toast.show(I18n.View_G_CouldNotSendRequest)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Copy Live URL

    private func copyLiveURLAction() {
        MeetingTracksV2.trackMeetingClickOperation(action: .clickCopyLiveLink,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: true)
        LiveTracks.trackCopyLiveStreamingLink()
        guard let url = self.liveViewModel.liveInfo?.liveURL, !url.isEmpty else {
            Toast.show(I18n.View_M_CopyLivestreamLinkErrorTryAgainLaterNew, type: .error)
            return
        }
        if meeting.security.copy(url, token: .toolbarCopyLiveLink, shouldImmunity: true) {
            Toast.show(I18n.View_M_LivestreamingLinkCopiedNew)
        }
    }

    // MARK: - State Change

    private func updateLiveItem(notifyListeners notify: Bool = true) {
        guard meeting.setting.canOperateLive else { return }
        Util.runInMainThread {
            if self.meeting.type == .call || self.meeting.setting.hasHostAuthority {
                self.state = .live
            } else if self.meeting.data.isLiving {
                self.state = .copyLiveURL
            } else {
                self.state = .askLive
            }
            if notify {
                self.notifyListeners()
            }
        }
    }

    enum LiveState {
        case live, askLive, copyLiveURL
    }
}

extension ToolBarLiveItem: InMeetDataListener, MeetingSettingListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        updateLiveItem()
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        DispatchQueue.main.async {
            if key == .showsLive {
                self.notifyListeners()
            } else {
                self.updateLiveItem()
            }
        }
    }
}
