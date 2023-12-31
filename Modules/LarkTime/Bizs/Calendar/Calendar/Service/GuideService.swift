//
//  GuideService.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/27.
//

import UIKit
import Foundation
import LarkContainer
import LarkGuide
import LarkGuideUI
import UniverseDesignTheme

final class GuideService {
    @Provider static var newGuideManager: NewGuideService

    enum GuideKey: String {
        case calendarGuestPermission = "all_calendar_guestspermission"
        case switchCalendarSyncGuideKey = "all_calendar_switch_third_party"
        case eventSetVCGuideKey = "all_calendar_event_set_vc"
        case detailViewVCSettingKey = "event_detail_vc_pre_setting"
        case addAttendeeByEmailGuideKey = "all_calendar_add_email_attendee"
        case calendarOptimizeRedDotKey = "all_calendar_detail_guide"
        case calendarOptimizeGuideKey = "mobile_calendar_list_detail_guide"
        case eventEditZoomMeetingGuideKey = "all_calendar_zoom_guide"
        case calendarSettingGuideKey = "all_external_share_calendar"
        case calendarShareGuideKey = "mobile_external_share_calendar2"
        case eventEditMeetingNotesGuideKey = "all_calendar_note"
        case globalMyAIInitGuide = "global_my_ai_init_guide"
        case taskInCalendarOnboardingInHomeView = "mobile_taskincalendar_onboarding1"
        case taskInCalendarOnboardingInSidebar = "mobile_taskincalendar_onboarding2"
    }

    static func shouldShowGuideForGuestPermission(newGuideManager: NewGuideService) -> Bool {
        FG.guestPermission &&
        SettingService.shared().getSetting().guestPermission == .some(.guestCanModify) &&
        SettingService.shared().tenantSetting?.guestPermission == .some(.guestCanModify) &&
        newGuideManager.checkShouldShowGuide(key: GuideKey.calendarGuestPermission.rawValue)
    }

    static func showGuideForGuestPermission(
        from controller: UIViewController,
        newGuideManager: NewGuideService,
        refreView: UIView?
    ) {
        guard let targetView = refreView else {
            return
        }

        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear, maskInteractionForceOpen: true)

        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(targetView), offset: -15),
            textConfig: TextInfoConfig(detail: I18n.Calendar_G_ParticipantAllowByDefaultOnboard))

        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig, maskConfig: maskConfig)

        newGuideManager.showBubbleGuideIfNeeded(
            guideKey: GuideKey.calendarGuestPermission.rawValue,
            bubbleType: .single(singleBubbleConfig),
            dismissHandler: nil
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            newGuideManager.closeCurrentGuideUIIfNeeded()
        }

    }

    static func checkShowTzInfoGuide(controller: UIViewController, newGuideManager: NewGuideService, referView: UIView?) {
        guard let targetView = referView else { return }
        showSingleBubbleGuide(
            newGuideManager: newGuideManager,
            guideKey: "mobile_calendar_multi_timezone_find_time",
            targetView: targetView,
            detail: BundleI18n.Calendar.Calendar_Timezone_GuideTips
        )
    }

    static func shouldShowGuideForSwitchingCalendar(newGuideManager: NewGuideService) -> Bool {
        newGuideManager.checkShouldShowGuide(key: GuideKey.switchCalendarSyncGuideKey.rawValue)
    }

    static func showGuideForSwitchingCalendar(
        from controller: UIViewController,
        newGuideManager: NewGuideService,
        referView: UIView?,
        completion: (() -> Void)?) {
        guard newGuideManager.checkShouldShowGuide(key: GuideKey.switchCalendarSyncGuideKey.rawValue) else {
            return
        }
        guard let targetView = referView, let dismissHandler = completion else {
            return
        }
        var targetAnchor = TargetAnchor(
            targetSourceType: .targetView(targetView),
            arrowDirection: .down
        )
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: targetAnchor,
            textConfig: TextInfoConfig(detail: BundleI18n.Calendar.Calendar_Sync_SwitchCalendarTip)
        )
        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig)
        newGuideManager.showBubbleGuideIfNeeded(
            guideKey: GuideKey.switchCalendarSyncGuideKey.rawValue,
            bubbleType: .single(singleBubbleConfig),
            dismissHandler: dismissHandler
        )
    }

    static func shouldShowGuideForSetVC(newGuideManager: NewGuideService) -> Bool {
        newGuideManager.checkShouldShowGuide(key: GuideKey.eventSetVCGuideKey.rawValue)
    }

    static func showGuideForSetVC(
        from controller: UIViewController,
        newGuideManager: NewGuideService,
        referView: UIView?,
        completion: (() -> Void)?) {
        guard newGuideManager.checkShouldShowGuide(key: GuideKey.eventSetVCGuideKey.rawValue) else {
            return
        }
        guard let targetView = referView, let dismissHandler = completion else {
            return
        }
        let targetAnchor = TargetAnchor(
            targetSourceType: .targetView(targetView),
            arrowDirection: .down
        )
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: targetAnchor,
            textConfig: TextInfoConfig(detail: BundleI18n.Calendar.Calendar_Edit_VCSettingsOnboarding)
        )
        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig)
        newGuideManager.showBubbleGuideIfNeeded(
            guideKey: GuideKey.eventSetVCGuideKey.rawValue,
            bubbleType: .single(singleBubbleConfig),
            dismissHandler: dismissHandler
        )
    }

    static func shouldShowGuideForAddingAttendeeByEmail(newGuideManager: NewGuideService) -> Bool {
        newGuideManager.checkShouldShowGuide(key: GuideKey.addAttendeeByEmailGuideKey.rawValue)
    }

    static func showGuideForAddingAttendeeByEmail(
        from controller: UIViewController,
        newGuideManager: NewGuideService,
        referView: UIView?,
        completion: (() -> Void)?) {
        guard newGuideManager.checkShouldShowGuide(key: GuideKey.addAttendeeByEmailGuideKey.rawValue) else {
            return
        }
        guard let targetView = referView, let dismissHandler = completion else {
            return
        }
        targetView.frame.origin.y -= 5
        showSingleBubbleGuide(
            newGuideManager: newGuideManager,
            guideKey: GuideKey.addAttendeeByEmailGuideKey.rawValue,
            targetView: targetView,
            detail: BundleI18n.Calendar.Calendar_EmailGuest_OnboardingToast,
            dismissHandler: dismissHandler
        )
    }

    static func showSingleBubbleGuide(newGuideManager: NewGuideService, guideKey: String, targetView: UIView, detail: String, title: String? = nil, dismissHandler: (() -> Void)? = nil) {

        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(targetView)),
            textConfig: TextInfoConfig(title: title, detail: detail))
        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig)
        newGuideManager.showBubbleGuideIfNeeded(
            guideKey: guideKey,
            bubbleType: .single(singleBubbleConfig),
            dismissHandler: dismissHandler
        )
    }

    static func showGuideForCalendarOptimize(
        from controller: UIViewController,
        newGuideManager: NewGuideService,
        referView: UIView?,
        completion: (() -> Void)?
    ) {
        guard isGuideNeedShow(newGuideManager: newGuideManager, key: .calendarShareGuideKey),
              let targetView = referView, let dismissHandler = completion else { return }
        let targetAnchor = TargetAnchor(
            targetSourceType: .targetView(targetView),
            arrowDirection: .up
        )
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: targetAnchor,
            textConfig: TextInfoConfig(detail: I18n.Calendar_Common_ClickToShare_Onboard)
        )
        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig)
        newGuideManager.showBubbleGuideIfNeeded(
            guideKey: GuideKey.calendarShareGuideKey.rawValue,
            bubbleType: .single(singleBubbleConfig),
            dismissHandler: dismissHandler
        )
        if let window = UIApplication.shared.keyWindow {
            window.backgroundColor = .clear
        }
    }

    // 仅在 FG.myAI 使用，其他地方请用 isGuideNeedShow(newGuideManager: NewGuideService, key: GuideKey) -> Bool
    // FG.myAI 下线时也要下线此方法，顺便删掉 @Provider static var newGuideManager: NewGuideService
    static func isGuideNeedShow(key: GuideKey) -> Bool {
        return newGuideManager.checkShouldShowGuide(key: key.rawValue)
    }

    static func isGuideNeedShow(newGuideManager: NewGuideService, key: GuideKey) -> Bool {
        return newGuideManager.checkShouldShowGuide(key: key.rawValue)
    }

    static func setGuideShown(newGuideManager: NewGuideService, key: GuideKey) {
        newGuideManager.didShowedGuide(guideKey: key.rawValue)
    }

    static func shouldShowGuideForZoom(newGuideManager: NewGuideService) -> Bool {
        newGuideManager.checkShouldShowGuide(key: GuideKey.eventEditZoomMeetingGuideKey.rawValue)
    }

    static func showGuideForZoom(
        from controller: UIViewController,
        newGuideManager: NewGuideService,
        referView: UIView?,
        completion: (() -> Void)?) {
            guard newGuideManager.checkShouldShowGuide(key: GuideKey.eventEditZoomMeetingGuideKey.rawValue) else {
                return
            }
            guard let targetView = referView, let dismissHandler = completion else {
                return
            }
            showSingleBubbleGuide(
                newGuideManager: newGuideManager,
                guideKey: GuideKey.eventEditZoomMeetingGuideKey.rawValue,
                targetView: targetView,
                detail: I18n.Calendar_Zoom_OnboardNote,
                dismissHandler: dismissHandler
            )
    }

    static func shouldShowGuideForMeetingNotes(newGuideManager: NewGuideService) -> Bool {
        return newGuideManager.checkShouldShowGuide(key: GuideKey.eventEditMeetingNotesGuideKey.rawValue)
    }

    static func showGuideForMeetingNotes(
        from controller: UIViewController,
        newGuideManager: NewGuideService,
        refreView: UIView?
    ) {
        guard let targetView = refreView else {
            return
        }

        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear, maskInteractionForceOpen: true)

        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(targetView), offset: -15),
            textConfig: TextInfoConfig(title: I18n.Calendar_Notes_Onboarding,
                                       detail: I18n.Calendar_Notes_OnboardingLonger))

        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig, maskConfig: maskConfig)

        newGuideManager.showBubbleGuideIfNeeded(
            guideKey: GuideKey.eventEditMeetingNotesGuideKey.rawValue,
            bubbleType: .single(singleBubbleConfig),
            dismissHandler: nil
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            newGuideManager.closeCurrentGuideUIIfNeeded()
        }
    }
    
    static func showGuideForTimeContainerSidebar(
        newGuideManager: NewGuideService,
        refreView: UIView,
        completion: (() -> Void)?
    ) {
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear, maskInteractionForceOpen: true)

        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(refreView), offset: -15, arrowDirection: .down),
            textConfig: TextInfoConfig(detail: I18n.Calendar_MV_HereToSeeTasks_Tooltip))

        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: bubbleConfig, maskConfig: maskConfig)

        newGuideManager.showBubbleGuideIfNeeded(
            guideKey: GuideKey.taskInCalendarOnboardingInSidebar.rawValue,
            bubbleType: .single(singleBubbleConfig),
            dismissHandler: completion
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            newGuideManager.closeCurrentGuideUIIfNeeded()
            completion?()
        }
    }
    
    static func showGuideForTimeContainerInHomeView(
        newGuideManager: NewGuideService,
        delegate: GuideSingleBubbleDelegate,
        refreView: UIView,
        completion: (() -> Void)?
    ) {
        let targetAnchor = TargetAnchor(
            targetSourceType: .targetView(refreView),
            arrowDirection: .up
        )
        let bubbleConfig = BubbleItemConfig(
            guideAnchor: targetAnchor,
            textConfig: .init(detail: I18n.Calendar_MV_NewFeatureForTasks_Title),
            bottomConfig: .init(leftBtnInfo: .init(title: I18n.Calendar_MV_NewFeatureGotIt_Button), rightBtnInfo: .init(title: I18n.Calendar_MV_GoTryOut_Button))
        )
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear, maskInteractionForceOpen: false)
        let singleBubbleConfig = SingleBubbleConfig(delegate: delegate, bubbleConfig: bubbleConfig, maskConfig: maskConfig)
        newGuideManager.showBubbleGuideIfNeeded(
            guideKey: GuideKey.taskInCalendarOnboardingInHomeView.rawValue,
            bubbleType: .single(singleBubbleConfig),
            dismissHandler: completion
        )
    }
}
