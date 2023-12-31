//
//  InMeetFollowViewModel+Onboarding.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/4/13.
//

import Foundation
import RxSwift
import ByteViewCommon

extension InMeetFollowViewModel {

    var onboardingGuideTrigger: Observable<Void> {
        manualGuideTrigger.asObservable()
    }

    func needsToShowNavBackGuide() -> Bool {
        if self.magicShareLocalDocumentsRelay.value.count > 1, service.shouldShowGuide(.followNavBack) {
            return true
        }
        return false
    }

    func didShowNavBackGuide() {
        service.didShowGuide(.followNavBack)
    }

    func needsToShowFollowerFreeSkimGuide() -> Bool {
        if case .following = self.manager.status, service.shouldShowGuide(.followerFreeBrowse) {
            return true
        }
        return false
    }

    func didShowFollowerFreeSkimGuide() {
        service.didShowGuide(.followerFreeBrowse)
    }

    func needsToShowFollowerFollowPresenterGuide() -> Bool {
        if case .free = self.manager.status, service.shouldShowGuide(.followerFollowPresenter) {
            return true
        }
        return false
    }

    func didShowFollowerFollowPresenterGuide() {
        service.didShowGuide(.followerFollowPresenter)
    }

    func needsToShowFullScreenMicBarGuide(container: InMeetViewContainer) -> Bool {
        Display.pad
        && container.context.meetingLayoutStyle == .fullscreen
        && !container.context.isFullScreenMicHidden
        && container.context.meetingContent == .follow
        && container.context.meetingScene == .thumbnailRow
        && service.shouldShowGuide(.followExpandToolbar)
    }

    func didShowFullScreenMicBarGuide() {
        service.didShowGuide(.followExpandToolbar)
    }

    /// MS场景首次进入沉浸模式，OnBoarding提示“点击「共享指示区」可唤起工具栏”
    func needsToShowFollowExapndToolbarSharingBarGuide() -> Bool {
        if case .fullscreen = self.context.meetingLayoutStyle, service.shouldShowGuide(.followExapndToolbarSharingBar) {
            return true
        }
        return false
    }

    func didShowFollowExapndToolbarSharingBarGuide() {
        service.didShowGuide(.followExapndToolbarSharingBar)
    }

    /// MS场景首次不跟随且在沉浸态，OnBoaring提示“当前您处于「自由浏览」。点击共享人头像可「跟随浏览」。”
    func needsToShowFollowClickAvatarToFollowGuide() -> Bool {
        if case .fullscreen = self.context.meetingLayoutStyle,
           case .free = self.manager.status,
           service.shouldShowGuide(.followClickAvatarToFollow) {
            return true
        }
        return false
    }

    func didShowFollowClickAvatarToFollowGuide() {
        service.didShowGuide(.followClickAvatarToFollow)
    }
}
