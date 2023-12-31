//
//  CurrentMeetingService.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/21.
//

import Foundation
import ByteViewCommon
import ByteViewInterface
import ByteViewUI
import LarkContainer
import RustPB
import LarkRustClient
import Heimdallr
#if LarkMod
import LarkSecurityComplianceInterface
import LarkMonitor
import LarkShortcut
#endif

final class CurrentMeetingService {
    private let logger = Logger.getLogger("CurrentMeetingService")
    let observer: MeetingObserver?
    #if LarkMod
    private var powerMonitor: VCMeetingPowerMonitor?
    private lazy var interceptorHandler = VCMeetingActionInterceptorHandler(userResolver: userResolver)
    #endif
    @RwAtomic private var isInActiveMeeting = false

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.observer = try? userResolver.resolve(assert: MeetingService.self).createMeetingObserver()
        self.observer?.setDelegate(self)
    }
}

extension CurrentMeetingService: MeetingObserverDelegate {
    func meetingObserver(_ observer: MeetingObserver, meetingChanged meeting: Meeting, oldValue: Meeting?) {
        if self.isInActiveMeeting, meeting.state == .end, !observer.meetings.contains(where: { $0.isActive }) {
            self.isInActiveMeeting = false
            self.didLeaveMeeting()
        } else if !self.isInActiveMeeting, meeting.isActive {
            self.isInActiveMeeting = true
            self.didEnterMeeting()
        }

        if meeting.isPending { return }
        #if LarkMod
        if meeting.state == .onTheCall {
            if self.powerMonitor == nil {
                self.powerMonitor = VCMeetingPowerMonitor(meeting: meeting)
            } else {
                self.powerMonitor?.updateMeeting(meeting)
            }
        } else if oldValue?.state == .onTheCall {
            self.powerMonitor = nil
        }
        #endif
    }
}

private extension CurrentMeetingService {
    func didEnterMeeting() {
        // 视频会议/加密通话期间开启Slardar日志上报平滑模式，减少带宽冲击。
        let hmdReportConfig = HMDCustomReportConfig(configWith: .sizeLimit)
        // nolint-next-line: magic number
        hmdReportConfig.thresholdSize = 200 * 1000
        hmdReportConfig.uploadInterval = 5
        HMDCustomReportManager.default().start(with: hmdReportConfig)
        if let rust = try? userResolver.resolve(assert: RustService.self) {
            var request = Videoconference_V1_NoticeByteviewEventRequest()
            request.type = .enter
            Logger.meeting.info("VC meeting client NoticeByteviewEventRequest.enter, rustService: \(rust)")
            rust.async(RequestPacket(message: request), callback: { (_: ResponsePacket<Void>) in })
        }

        #if LarkMod
        _ = self.interceptorHandler
        #endif
        Logger.meeting.info("VC meeting client mutex state: idle -> non-idle.")
        NotificationCenter.default.post(name: NSNotification.Name("VCWillStartNotification"), object: nil)
    }

    func didLeaveMeeting() {
        HMDCustomReportManager.default().stop(withCustomMode: .sizeLimit)
        if let rust = try? userResolver.resolve(assert: RustService.self) {
            var request = Videoconference_V1_NoticeByteviewEventRequest()
            request.type = .leave
            Logger.meeting.info("VC meeting client NoticeByteviewEventRequest.leave, rustService: \(rust)")
            rust.async(RequestPacket(message: request), callback: { (_: ResponsePacket<Void>) in })
        }

        #if LarkMod
        self.interceptorHandler.remainTimeOfSecurityCompliance = nil
        #endif
        Logger.meeting.info("VC meeting client mutex state: non-idle -> idle.")
        NotificationCenter.default.post(name: NSNotification.Name("VCWillEndNotification"), object: nil)
    }
}

#if LarkMod
private final class VCMeetingActionInterceptorHandler: NoPermissionActionInterceptorHandler {
    var bizPriority: Int { 100 }
    var bizName: NSString { "ByteView_interceptor" as NSString }
    let userResolver: UserResolver
    var service: MeetingService? { try? userResolver.resolve(assert: MeetingService.self) }
    private let logger = Logger.privacy

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        try? userResolver.resolve(assert: NoPermissionActionInterceptor.self).addInterceptorHandler(self)
        logger.info("SCActionInterceptor add VCMeetingActionInterceptorHandler")
    }

    deinit {
        logger.info("deinit VCMeetingActionInterceptorHandler")
    }

    func needIntercept() -> Bool {
        service?.currentMeeting?.isActive == true
    }

    func onReceiveSecurityAction(_ action: NSString, extra: [NSString: NSNumber]) {
        logger.info("securityComplianceInterruptingMeeting")
        self.interruptForSecurityCompliance()
    }

    func interruptForSecurityCompliance() {
        guard let meeting = self.service?.currentMeeting else {
            logger.info("securityComplianceInterruptingMeeting cancelled, currentMeeting is nil")
            return
        }
        logger.info("interruptForSecurityCompliance will hangup all meetings")
        // 判断是否是callkit方式的响铃，此时无window，但是也需要弹alert
        if meeting.isCallKit && meeting.state == .ringing {
            self.buildDismissAlert()
        } else if let shortcutClient = try? userResolver.resolve(assert: ShortcutService.self).getClient(.vc) {
            shortcutClient.run(FloatWindowAction(sessionId: meeting.sessionId, isFloating: false)) { [weak self] _ in
                self?.buildDismissAlert()
            }
        }
    }

    // 安全弹窗剩余时间
    var remainTimeOfSecurityCompliance: UInt?
    private func buildDismissAlert() {
        var duration: UInt = 30
        // 如果上次还剩时间，继续上次的时间，该场景仅出现在忙线状态中
        if let time = self.remainTimeOfSecurityCompliance {
            duration = time
        }
        ByteViewDialog.Builder()
            .id(.securityCompliance)
            .level(3)
            .colorTheme(.redLight)
            .title(I18n.View_G_NoSafeLeave)
            .message(nil)
            .rightTitle(I18n.View_G_LeaveButtonTime(duration))
            .rightHandler({ [weak self] _ in
                guard let meetings = self?.service?.meetings,
                      let client = try? self?.userResolver.resolve(assert: ShortcutService.self).getClient(.vc) else {
                    return
                }
                // 手动离会，清空时间
                self?.remainTimeOfSecurityCompliance = nil
                // 会中场景命中使用leaveBecauseUnsafe的reason，会前场景命中则走正常离会流程
                meetings.forEach {
                    client.run(LeaveMeetingAction(sessionId: $0.sessionId, reason: .securityInterruption))
                }
                // dismiss所有剩下的Alert，保证不会有页面逃逸出主端的安全页面
                ByteViewDialogManager.shared.dismissAllAlert()
            })
            .rightType(.autoCountDown(
                duration: duration,
                updator: { [weak self] in
                    duration = $0
                    // 获取剩余时间
                    self?.remainTimeOfSecurityCompliance = $0
                    return I18n.View_G_LeaveButtonTime(duration)
                }))
            .needAutoDismiss(true)
            .show()
    }
}

private final class VCMeetingPowerMonitor {
    private let params: [String: Any]
    private let logger: Logger

    @RwAtomic private var isCameraMuted = false
    @RwAtomic private var isCameraEffectOn = false
    @RwAtomic private var isSharingDocument = false

    init?(meeting: Meeting) {
        self.params = ["meetingId": meeting.meetingId]
        let tag = "[PowerMonitor(\(meeting.sessionId))][\(meeting.meetingId)]"
        self.logger = Logger.monitor.withContext(meeting.sessionId).withTag(tag)
        self.isCameraMuted = meeting.isCameraMuted
        self.isCameraEffectOn = meeting.isCameraEffectOn
        self.isSharingDocument = meeting.isSharingDocument
        startMonitor()
    }

    deinit {
        stopMonitor()
    }

    private func startMonitor() {
        beginEvent("vc_meeting_lark_entry")
        if !self.isCameraMuted {
            beginEvent("vc_meeting_camera_click")
            if self.isCameraEffectOn {
                beginEvent("vc_meeting_effect_status")
            }
        }
    }

    private func stopMonitor() {
        endEvent("vc_meeting_lark_entry")
        if !self.isCameraMuted {
            endEvent("vc_meeting_camera_click")
            if self.isCameraEffectOn {
                endEvent("vc_meeting_effect_status")
            }
        }
    }

    private func beginEvent(_ name: String) {
        logger.info("beginEvent: \(name)")
        BDPowerLogManager.beginEvent(name, params: params)
    }

    private func endEvent(_ name: String) {
        logger.info("endEvent: \(name)")
        BDPowerLogManager.endEvent(name, params: params)
    }

    func updateMeeting(_ meeting: Meeting) {
        if meeting.isCameraMuted != self.isCameraMuted {
            self.isCameraMuted = meeting.isCameraMuted
            self.isCameraEffectOn = meeting.isCameraEffectOn
            if self.isCameraMuted {
                endEvent("vc_meeting_camera_click")
                if self.isCameraEffectOn {
                    endEvent("vc_meeting_effect_status")
                }
            } else {
                beginEvent("vc_meeting_camera_click")
                if self.isCameraEffectOn {
                    beginEvent("vc_meeting_effect_status")
                }
            }
        } else if self.isCameraEffectOn != meeting.isCameraEffectOn {
            self.isCameraEffectOn = meeting.isCameraEffectOn
            if self.isCameraEffectOn {
                beginEvent("vc_meeting_effect_status")
            } else {
                endEvent("vc_meeting_effect_status")
            }
        }
        if self.isSharingDocument != meeting.isSharingDocument {
            self.isSharingDocument = meeting.isSharingDocument
            if self.isSharingDocument {
                beginEvent("vc_magic_share_first_action_dev")
            } else {
                endEvent("vc_magic_share_first_action_dev")
            }
        }
    }
}
#endif
