//
//  FocusVideoManager.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/7/5.
//

import Foundation
import RxSwift
import ByteViewNetwork

class FocusVideoManager: InMeetDataListener {

    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private let gridViewModel: InMeetGridViewModel
    private let disposeBag = DisposeBag()

    required init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        self.gridViewModel = resolver.resolve()!
        meeting.data.addListener(self)
        listenReceiveReclaimHostPopup()
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if inMeetingInfo.focusingUser != oldValue?.focusingUser {
            showFocusVideoToast(inMeetingInfo.focusingUser, oldUser: oldValue?.focusingUser)
        }
    }

    private func showFocusVideoToast(_ user: ByteviewUser?, oldUser: ByteviewUser?) {
        if let focusUser = user {
            // 对于主持人角色自己，不论是主持人自己操作还是会管操作，均显示焦点视频设置成功/已取消焦点视频
            if focusUser == meeting.account {
                let toast = meeting.myself.meetingRole != .host ? I18n.View_MV_HasSetYouAsFocus_Toast : I18n.View_G_FocusVideoSet
                Toast.showOnVCScene(toast)
            } else {
                let isHost = meeting.myself.isHost
                let isSelfSharingContent = meeting.shareData.isSelfSharingContent
                var toast: String?
                if gridViewModel.isUsingCustomOrder && !gridViewModel.isGridOrderSyncing && (isHost || isSelfSharingContent) {
                    // 主持人、主共享人，进入焦点视频时若有自定义视频顺序，需要异化toast
                    if isHost {
                        toast = I18n.View_G_FocusVideoRevertDefault
                    } else {
                        toast = I18n.View_G_HostFocusVideoRevertDefault
                    }
                } else if isHost {
                    toast = I18n.View_G_FocusVideoSet
                } else {
                    // 需要调用participantService获取name，放到下面闭包里同步执行
                }
                let showToastIfNeeded = { [weak self] in
                    guard let self = self else { return }
                    // 入会时焦点视频toast可能被audio的toast覆盖。但焦点视频toast必须要展示，所以暂时屏蔽audioToast
                    // 「Toast优先级」需求上线后此处可优化
                    self.meeting.canShowAudioToast = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        self?.meeting.canShowAudioToast = true
                    }

                    if let toast = toast {
                        Toast.showOnVCScene(toast)
                    } else {
                        if let participant = self.meeting.participant.find(user: focusUser, in: .activePanels) {
                            let participantService = self.meeting.httpClient.participantService
                            participantService.participantInfo(pid: participant, meetingId: self.meeting.meetingId) { info in
                                Toast.showOnVCScene(I18n.View_MV_SetNameFocus_Toast(info.name))
                            }
                        }
                    }
                }
                // nolint-next-line: magic number
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showToastIfNeeded()
                }
            }
        } else if let oldUser = oldUser {
            if oldUser == meeting.account {
                let toast = meeting.myself.isHost ? I18n.View_G_UnfocusVideoForAll_Toast : I18n.View_MV_YouCancelFocus_Toast
                Toast.showOnVCScene(toast)
            } else {
                let toast = meeting.myself.isHost ? I18n.View_G_UnfocusVideoForAll_Toast : I18n.View_MV_HostCancelFocus_Toast
                Toast.showOnVCScene(toast)
            }
        }
    }

    // server推送弹窗，入会需自动收回host时可能出现此case
    func listenReceiveReclaimHostPopup() {
        NoticeService.shared.hasReceivedReclaimAlertObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notice in
                guard let self = self, !notice.isHandled else { return }
                ParticipantsViewModel.showReclaimHostAlert(meeting: self.meeting)
                notice.isHandled = true
            }).disposed(by: disposeBag)
    }
}
