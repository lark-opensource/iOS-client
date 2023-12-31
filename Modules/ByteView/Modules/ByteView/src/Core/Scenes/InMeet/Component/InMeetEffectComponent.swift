//
//  InMeetEffectComponent.swift
//  ByteView
//
//  Created by wangpeiran on 2022/12/11.
//

import Foundation
import RxSwift
import UniverseDesignToast

final class InMeetEffectComponent: InMeetViewComponent {
    private weak var container: InMeetViewContainer?
    let disposeBag = DisposeBag()
    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver
    let dispose = DisposeBag()
    let effectManger: MeetingEffectManger?

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.meeting = viewModel.meeting
        self.resolver = viewModel.resolver
        self.container = container
        self.effectManger = meeting.effectManger
        meeting.camera.addListener(self)
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .effect
    }

    func containerDidFirstAppear(container: InMeetViewContainer) {
        if meeting.isCalendarMeeting {
            handleForCalendarEffect(view: container.view)
        }
    }

    deinit {
        meeting.camera.removeLisenter(self)
    }
}

extension InMeetEffectComponent: InMeetCameraListener {
    func didInterruptedByAllowVirtualBg(_ muteModel: NoVirtualBgMuteParam) {
        guard Privacy.videoAuthorized, let effectManger = meeting.effectManger else { return }
        meeting.camera.effect.enableBackgroundBlur(false)
        meeting.camera.effect.setBackgroundImage("")
        Util.runInMainThread { [weak self] in
            guard let meeting = self?.meeting else { return }
            let vc = NoVirtualBgPreviewViewController(service: meeting.service, effectManger: effectManger)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            vc.openCameraBlock = { [weak self] in // TODO: @wpr
                self?.meeting.camera.muteMyself(muteModel.muted, source: muteModel.source, requestByHost: muteModel.requestByHost, showToastOnSuccess: muteModel.shouldShowToast, shouldHandleBgAllow: false, completion: nil, file: muteModel.file, function: muteModel.function, line: muteModel.line)
            }
            meeting.router.present(vc)
        }
    }
}

extension InMeetEffectComponent {
    func handleForCalendarEffect(view: UIView) {
        Logger.lab.info("inmeet handleForCalendarEffect, status: \(effectManger?.virtualBgService.extrabgDownloadStatus), isCalendarMeeting: \(meeting.isCalendarMeeting)")
        if meeting.isCalendarMeeting, let labservice = effectManger?.virtualBgService {
            if labservice.calendarMeetingVirtual == nil { // 没处理
                setCalendarInfoForEffect(meeting: meeting, view: view)
            } else if meeting.subType == .webinar, !meeting.isWebinarAttendee, labservice.hasSetCalenderForUnWebinarAttendee == false {  // webinar会议 + 嘉宾 + 之前没设置过嘉宾 ，因为会中会可能观众转变为嘉宾
                setCalendarInfoForEffect(meeting: meeting, view: view)
            } else { // preview等处理过了，就根据当前的状态
                switch labservice.extrabgDownloadStatus {
                case .unStart:
                    setCalendarInfoForEffect(meeting: meeting, view: view)
                case .checking, .download:
                    effectManger?.virtualBgService.addCalendarListener(self)
                    effectManger?.pretendService.addCalendarListener(self)
                case .done, .failed:
                    ()
                }
            }
        }
    }

    private func setCalendarInfoForEffect(meeting: InMeetMeeting, view: UIView) {
        effectManger?.getForCalendarSetting(meetingId: meeting.meetingId, uniqueId: nil, isWebinar: meeting.subType == .webinar, isUnWebinarAttendee: !meeting.isWebinarAttendee)
        effectManger?.virtualBgService.addCalendarListener(self) //这里不fire,是因为这边是初次设置
        effectManger?.pretendService.addCalendarListener(self)
    }
}

extension InMeetEffectComponent: EffectVirtualBgCalendarListener, EffectPretendCalendarListener {
    func didChangeAnimojAllow(isAllow: Bool) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            Logger.effectPretend.info("inmeet handle animoji isAllow: \(isAllow), \(self.effectManger?.pretendService.isAnimojiOn())")
            if !isAllow, self.effectManger?.pretendService.isAnimojiOn() == true {
                self.effectManger?.pretendService.cancelAnimoji()
            }
        }
    }

    func didChangeExtrabgDownloadStatus(status: ExtraBgDownLoadStatus) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if status == .done, self.effectManger?.virtualBgService.calendarMeetingVirtual?.hasExtraBg == true,
               self.effectManger?.virtualBgService.calendarMeetingVirtual?.hasShowedExtraBgToast == false {
                let toast = AnchorToastDescriptor(type: .more, title: I18n.View_G_UniSetYouCanChange)
                AnchorToast.show(toast)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak toast] in
                    guard let toastNew = toast else { return }
                    AnchorToast.dismiss(toastNew)
                }
            }
        }
    }

    func didChangeVirtualBgAllow(allowInfo: AllowVirtualBgRelayInfo) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            Logger.lab.info("inmeet handle bg Allow: \(allowInfo.allow)")
            if !allowInfo.allow, !self.meeting.camera.isMuted, allowInfo.hasUsedBgInAllow == true {  // 不允许+摄像头打开+使用了虚拟背景
                self.meeting.camera.muteMyself(true, source: .notAllow_VirtualBg, showToastOnSuccess: false, completion: nil) // 先mute再去背景，保证隐私
                self.meeting.camera.effect.enableBackgroundBlur(false)
                self.meeting.camera.effect.setBackgroundImage("")
                Toast.hideAllToasts()
                Toast.show(I18n.View_G_DisallowBackCamAutoOff)
            } // 否则打开的时候再处理
        }
    }
}
