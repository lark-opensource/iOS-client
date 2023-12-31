//
//  InMeetSettingsMagicShareTracks.swift
//  ByteView
//
//  Created by liurundong.henry on 2020/4/27.
//

import Foundation
import ByteViewTracker

enum InMeetSettingsMagicShareTracks {
    static let meetingShareWindowPage = TrackEventName.vc_meeting_onthecall_share_window

    static func trackTapSearchBar() {
        VCTracker.post(name: meetingShareWindowPage,
                              params: [.action_name: "search"])
    }

    static func trackSelectSearchFile(fromRecommendList isList: Bool,
                                      rank: NSInteger,
                                      docType: NSInteger,
                                      docSubType: NSInteger,
                                      token: String) {
        let encToken = EncryptoIdKit.encryptoId(token)
        VCTracker.post(name: meetingShareWindowPage,
                              params: [.from_source: "recommend_list",
                                       .action_name: "docs_file",
                                       .extend_value: ["rank": rank,
                                                        "file_token": encToken,
                                                        "doc_type": docType,
                                                        "sub_type": docSubType]])
    }

    static func trackTapFileThumbnail(rank: NSInteger,
                                      docType: NSInteger,
                                      docSubType: NSInteger,
                                      token: String) {
        let encToken = EncryptoIdKit.encryptoId(token)
        VCTracker.post(name: meetingShareWindowPage,
                              params: [.from_source: "all",
                                       .action_name: "open_file",
                                       .extend_value: ["rank": rank,
                                                        "file_token": encToken,
                                                        "doc_type": docType,
                                                        "sub_type": docSubType]])
    }
}
