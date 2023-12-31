//
//  LocalShareTracks.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/6/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewMeeting

class LocalShareTracks {
    private static let ShareCodeView = TrackEventName.vc_meeting_sharecode_view
    private static let ShareCodeClick = TrackEventName.vc_meeting_sharecode_click
    private static let ShareWindowView = TrackEventName.vc_meeting_sharewindow_view
    private static let SharingRoomView = TrackEventName.vc_share_code_input_popup_view
    private static let SharingRoomClick = TrackEventName.vc_share_code_input_popup_click
    private static let ShareCodeInputView = TrackEventName.vc_share_code_input_view

    static func trackShareCodeInputAppear() {
        let inMeeting = MeetingManager.shared.hasActiveMeeting.description
        VCTracker.post(name: ShareCodeInputView, params: ["during_meeting": inMeeting])
    }

    static func trackShareCodeAppear() {
        VCTracker.post(name: ShareCodeView)
    }

    static func trackShareCodeClick(click: String) {
        VCTracker.post(name: ShareCodeClick, params: [.click: click])
    }

    static func trackDoubleCheckAppear(isExternal: Bool,
                                       shareMethod: String,
                                       shareType: String,
                                       duringMeeting: Bool) {
        VCTracker.post(name: SharingRoomView, params: [
            .content: isExternal ? "different_tenant" : "same_tenant",
            "share_method": shareMethod,
            "share_type": shareType,
            "during_meeting": duringMeeting
        ])
    }

    static func trackDoubleCheckClick(click: String,
                                      shareCode: String,
                                      isExternal: Bool,
                                      roomTenantID: Int64,
                                      shareMethod: String,
                                      shareType: String,
                                      duringMeeting: Bool) {
        var params: TrackParams = [.click: click,
                                   "share_code": shareCode,
                                   .content: isExternal ? "different_tenant" : "same_tenant",
                                   "share_method": shareMethod,
                                   "share_type": shareType,
                                   "during_meeting": duringMeeting]
        if isExternal {
            params["different_tenant_id"] = EncryptoIdKit.encryptoId(String(roomTenantID))
        }
        VCTracker.post(name: SharingRoomClick, params: params)
    }
}
