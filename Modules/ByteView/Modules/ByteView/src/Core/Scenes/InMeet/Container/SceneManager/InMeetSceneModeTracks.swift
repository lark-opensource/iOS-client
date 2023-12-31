//
// Created by liujianlong on 2022/9/6.
//

import Foundation
import ByteViewTracker

extension InMeetSceneManager.SceneMode {
    var trackString: String {
        switch self {
        case .speech: return "speaker"
        case .gallery: return "gallery"
        case .thumbnailRow: return "thumbnail"
        case .webinarStage: return "webinar_stage"
        }
    }
}
enum InMeetSceneTracks {
    static func trackClickLayout(
            newScene: InMeetSceneManager.SceneMode,
            beforeScene: InMeetSceneManager.SceneMode,
            isSharing: Bool,
            isSharer: Bool) {
        VCTracker.post(name: .vc_meeting_layout_click, params: [
            "click": newScene.trackString,
            "before_name": beforeScene.trackString,
            "is_sharing": isSharing,
            "is_sharer": isSharer,
            "if_landscape_screen": InMeetOrientationToolComponent.isLandscapeOrientation
        ])
    }

    static func trackToggleVideoBar(
            videoBarFold: Bool,
            scene: InMeetSceneManager.SceneMode,
            isSharing: Bool,
            isSharer: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [
            "click": videoBarFold ? "fold_video_bar" : "unfold_video_bar",
            "layout_type": scene.trackString,
            "is_sharing": isSharing,
            "is_sharer": isSharing ? (isSharer ? "true" : "false") : "none",
            "if_landscape_screen": InMeetOrientationToolComponent.isLandscapeOrientation
        ])
    }

    static func trackHaulVideoBar(
            videoBarFold: Bool,
            scene: InMeetSceneManager.SceneMode,
            isSharing: Bool,
            isSharer: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [
            "click": "haul_video_bar",
            "layout_type": scene.trackString,
            "is_sharing": isSharing,
            "is_sharer": isSharing ? (isSharer ? "true" : "false") : "none",
            "video_bar_fold": videoBarFold,
            "if_landscape_screen": InMeetOrientationToolComponent.isLandscapeOrientation
        ])
    }

    static func trackClickHideSelf(
            isHideSelf: Bool,
            location: String,
            scene: InMeetSceneManager.SceneMode) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [
            "click": isHideSelf ? "hide_selfview" : "show_selfview",
            "location": location,
            "layout_type": scene.trackString
        ])
    }

    static func trackSwitchHideNoVideoUser(isHide: Bool) {
        VCTracker.post(name: .vc_meeting_layout_click, params: [
            "click": "hide_non_video_users",
            "is_check": isHide
        ])
    }

    static func trackClickHideNoVideoUser(isHide: Bool,
                                          scene: InMeetSceneManager.SceneMode) {
        VCTracker.post(name: .vc_meeting_layout_click, params: [
            "click": isHide ? "hide_non_video_user" : "show_non_video_user",
            "location": "user_icon",
            "layout_type": scene.trackString
        ])
    }

    static func trackDragGrid(fromIndex: Int,
                              toIndex: Int,
                              isSharing: Bool,
                              isSharer: Bool,
                              scene: InMeetSceneManager.SceneMode) {
        VCTracker.post(name: .vc_meeting_layout_click, params: [
            "click": "drag_video_order",
            "from_num": fromIndex,
            "to_num": toIndex,
            "is_sharing": isSharing,
            "is_sharer": isSharer,
            "layout_type": scene.trackString
        ])
    }

    static func trackClickResetOrder(isSharing: Bool,
                                     isSharer: Bool,
                                     scene: InMeetSceneManager.SceneMode) {
        VCTracker.post(name: .vc_meeting_layout_click, params: [
            "click": "reset_video_order",
            "is_sharing": isSharing,
            "is_sharer": isSharer,
            "layout_type": scene.trackString
        ])
    }

    static func trackClickSyncOrder(isSharing: Bool,
                                    isSharer: Bool,
                                    scene: InMeetSceneManager.SceneMode) {
        VCTracker.post(name: .vc_meeting_layout_click, params: [
            "click": "host_sync_video_order",
            "is_sharing": isSharing,
            "is_sharer": isSharer,
            "layout_type": scene.trackString
        ])
    }

    static func trackClickShowSpeaker(onMain: Bool) {
        VCTracker.post(name: .vc_meeting_layout_click, params: [
            "click": onMain ? "pin_active_speaker" : "unpin_active_speaker"
        ])
    }

    static func trackBackToShare(from: BackToShareFrom,
                                 location: BackToShareLocation,
                                 scene: InMeetSceneManager.SceneMode,
                                 isSharing: Bool,
                                 isSharer: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [
            "click": "back_to_share_content",
            "return_from": from.trackString,
            "location": location.trackString,
            "is_sharing": isSharing,
            "is_sharer": isSharer,
            "layout_type": scene.trackString
        ])
    }

    static func trackClickChangeOrder(fromIndex: Int,
                                      isSharing: Bool,
                                      isSharer: Bool,
                                      scene: InMeetSceneManager.SceneMode) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [
            "click": "change_video_order",
            "from_num": fromIndex,
            "is_sharing": isSharing,
            "is_sharer": isSharer,
            "layout_type": scene.trackString
        ])
    }

    static func trackChangeOrderBySearch(fromIndex: Int) {
        VCTracker.post(name: .vc_meeting_popup_click, params: [
            "click": "change_video_order_select",
            "from_num": fromIndex,
            "content": "change_video_order_toolbar"
        ])
    }

    static func trackToggleCustomOrderPopup(name: String, confirm: Bool) {
        VCTracker.post(name: .vc_meeting_popup_click, params: [
            "click": confirm ? "confirm" : "cancel",
            "content": name
        ])
    }

    static func trackToggleReorder(confirm: Bool) {
        VCTracker.post(name: .vc_meeting_popup_click, params: [
            "click": confirm ? "sync_video_order" : "cancel_sync_video_order",
            "content": "update_host_sync_video_order"
        ])
    }
}

extension BackToShareFrom {
    var trackString: String {
        switch self {
        case .pinActiveSpeaker:
            return "pin_active_speaker"
        case .galleryLayout:
            return "gallery_layout"
        }
    }
}

extension BackToShareLocation {
    var trackString: String {
        switch self {
        case .userMenu:
            return "user_menu"
        case .topBar:
            return "top_bar"
        case .singleClickSpeaker:
            return "single_click_speaker_window"
        case .doubleClickSharing:
            return "double_click_sharing_window"
        }
    }
}
