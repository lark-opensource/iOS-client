//
//  BusinessTracker.swift
//  Minutes_iOS
//
//  Created by panzaofeng on 2020/12/23.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import LKCommonsTracker
import MinutesFoundation
import MinutesInterface
import LarkContainer
import LarkAccountInterface

public enum BusinessTrackerName: String {
    case listPage = "vc_mm_list_page"
    case pageView = "vc_mm_page_view"
    case clickButton = "vc_mm_click_button"
    case pageAlive = "predefine_page_alive"
    case recordingPage = "vc_mm_recording_page"
    case podcastPage = "vc_mm_podcast_page"
    case miniView = "vc_mm_mini_view"
    case miniPodcast = "vc_mm_mini_podcast"
    case feedbackOwner = "vc_mm_feedback_page_owner"
    case feedbackNotOwner = "vc_mm_feedback_page"
    case detailSettingView = "vc_minutes_detail_setting_view"

    case podcastStatus = "vc_minutes_podcast_status"

    case popupView = "vc_minutes_popup_view"
    case popupClick = "vc_minutes_popup_click"

    case listView = "vc_minutes_list_view"
    case listClick = "vc_minutes_list_click"

    case feedbackView = "vc_minutes_feedback_view"
    case feedbackClick = "vc_minutes_feedback_click"

    case deleteLoadingView = "vc_minutes_detail_loading_view"
    case deleteView = "vc_minutes_delete_view"
    case deleteClick = "vc_minutes_delete_click"

    case detailMoreView = "vc_minutes_detail_more_view"
    case detailMoreClick = "vc_minutes_detail_more_click"
    case detailMoreInfoView = "vc_minutes_more_information_view"

    case recordingView = "vc_minutes_recording_view"
    case recordingClick = "vc_minutes_recording_click"

    case recordingMiniView = "vc_minutes_recording_mini_view"
    case recordingMiniClick = "vc_minutes_recording_mini_click"

    case permissionView = "vc_minutes_permission_view"
    case permissionClick = "vc_minutes_permission_click"

    case detailView = "vc_minutes_detail_view"
    case detailStatus = "vc_minutes_detail_status"
    case detailClick = "vc_minutes_detail_click"

    case playbarClick = "vc_minutes_playbar_click"
    case playbarClipView = "vc_minutes_playbar_clip_view"
    case playbarClipClick = "vc_minutes_playbar_clip_click"

    case detailSettingClick = "vc_minutes_detail_setting_click"

    case shareView = "vc_minutes_share_view"
    case shareClick = "vc_minutes_share_click"

    case podcastView = "vc_minutes_podcast_view"
    case podcastClick = "vc_minutes_podcast_click"

    case podcastSettingView = "vc_minutes_podcast_setting_view"
    case podcastSettingClick = "vc_minutes_podcast_setting_click"

    case podcastMiniView = "vc_minutes_podcast_mini_view"
    case podcastMiniClick = "vc_minutes_podcast_mini_click"

    case removeView = "vc_minutes_remove_view"
    case removeClick = "vc_minutes_remove_click"

    case clearView = "vc_minutes_delete_permanently_view"
    case clearClick = "vc_minutes_delete_permanently_click"

    case speakerDescriptionClick = "vc_minutes_speaker_description_click"

    case voiceprintClick = "vc_minutes_voiceprint_click"

    case clipListClick = "vc_minutes_clip_list_click"

    case minutesDetailViewDev = "vc_minutes_detail_view_dev"
    case minutesListViewDev = "vc_minutes_list_view_dev"
    case minutesPodcastViewDev = "vc_minutes_podcast_view_dev"
    case minutesRecordingClickDev = "vc_minutes_recording_click_dev"
    
    //智能纪要总结
    case feelgoodPopAIMainPoint = "vc_minutes_feelgood_summary_ai_main_point_dev"
    //智能纪要待办
    case feelgoodPopAIMainTodo = "vc_minutes_feelgood_summary_ai_todo_dev"
    //章节纪要
    case feelgoodPopAIMainAgenda = "vc_minutes_feelgood_agenda_dev"
    //发言人总结
    case feelgoodPopSpeakerSummary = "vc_minutes_feelgood_speaker_summary_dev"
    
    case feelgoodPop = "vc_minutes_feelgood_pop_dev"
    // 录音生成完整率
    case audioCompleteLocal = "vc_minutes_audio_complete_local_dev"
    // 完整率新key
    case minutesDev = "vc_minutes_dev"
    // 分片上传完整率
    case audioFragmentsUploadCompleted = "vc_minutes_audio_fragments_completed_dev"
    // 请求报错
    case requestError = "vc_minutes_request_error_dev"
}

enum BusinessTrackerActionName: String {
    case videoPlay = "video_play"
    case videoPause = "video_pause"
    case speedChange = "speed_change"
    case progressBarChange = "progress_bar_change"
    case apply = "apply"
    case openShareLink = "open_share_link"
    case headerPageDelete = "header_page_delete"
    case more = "more"
    case copyLink = "copy_link"
    case headerShareActionName = "header_share"
    case linkShare = "link_share"
    case chatShare = "chat_share"
    case byteMomentsShare = "byte_moments_share"
    case moreShare = "more_share"
    case reactionDisplay = "reaction_display"
    case commentDisplay = "comment_display"
    case display = "display"
    case delete = "delete"
    case confirm = "confirm"
    case cancel = "cancel"
    case startRecording = "start_recording"
}

enum BusinessTrackerFromSource: String {
    case controller
    case player
    case playerView = "player_view"
    case headerShareFromSource = "header_share"
    case podcast
    case deleteSource = "delete"
}

enum BusinessTrackerPageName: String {
    case permissionPage = "permission_page"
}

extension Dictionary where Key == AnyHashable, Value == Any {
    mutating func append(_ action: BusinessTrackerActionName) {
        self["action_name"] = action.rawValue
    }

    mutating func append(_ source: BusinessTrackerFromSource) {
        self["from_source"] = source.rawValue
    }

    mutating func append(_ source: BusinessTrackerPageName) {
        self["page_name"] = source.rawValue
    }

    mutating func append(actionEnabled: Bool) {
        self["action_enabled"] = actionEnabled ? 1 : 0
    }
}

/// class MinutesTracker
public class BusinessTracker {
    @Provider var passportService: PassportService // Global

    public init() {
    }

    public func tracker(name: BusinessTrackerName, params: [AnyHashable: Any]) {
        let event = TeaEvent(name.rawValue)
        var paramsSend: [AnyHashable: Any] = self.commonParamsGenerat()
        params.forEach { (k, v) in
            paramsSend[k] = v
        }
        event.params = paramsSend
        event.md5AllowList = ["token", "file_id"]
        Tracker.post(event)
    }

    func commonParamsGenerat() -> [AnyHashable: Any] {
        var params: [AnyHashable: Any] = [:]
        params["sub_platform"] = "ios_native"
        params["is_login"] = passportService.foregroundUser == nil ? "0" : "1"
        params["conference_id"] = "none"
        params["is_page_owner"] = false
        params["token"] = "none"
        params["object_type"] = "none"
        params["is_page_editor"] = false

        return params
    }
}
