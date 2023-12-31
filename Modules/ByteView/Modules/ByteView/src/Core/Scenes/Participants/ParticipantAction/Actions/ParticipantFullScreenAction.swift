//
//  ParticipantFullScreenAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation

class ParticipantFullScreenAction: BaseParticipantAction {

    override var title: String {
        source == .single ? I18n.View_G_ExitFullScreen : I18n.View_G_FullScreen
    }

    override var show: Bool { showFullScreen }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        ParticipantTracks.trackFullScreen(click: source == .single ? "more_exit_fullscreen" : "more_fullscreen")
        end(nil)
    }
}

extension ParticipantFullScreenAction {

    private var showFullScreen: Bool {
        if isSelf {
            return provider?.heterization.hasSignleVideo ?? false && (!meeting.camera.isMuted || source == .single) && Privacy.videoAuthorized
        }
        return !canCancelInvite && provider?.heterization.hasSignleVideo ?? false && (!participant.settings.isCameraMutedOrUnavailable || source == .single)
    }
}
