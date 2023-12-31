//
//  MinutesSource.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/24.
//

import Foundation

public enum MinutesSource: String {
    case listPage = "list_page"
    case chatLink = "chat_link"
    case doc = "doc"
    case others = "others"
    case mentionFromComments = "mention_from_comments"
    case clipList = "clip_list"
    case info = "info"
    case clip = "clip"
    case podcast = "podcast"
    case viewClip = "view_clip"
    case clipGenerated = "clip_generated"
    case finishRecording = "finish_recording"
    case finishTranscripting = "finish_transcripting"
    case permissionChange = "permission_change"
    case autoDelete = "auto_delete"
}
