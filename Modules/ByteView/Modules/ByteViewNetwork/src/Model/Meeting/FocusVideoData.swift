//
//  FocusVideoData.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/1/7.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_InMeetingData.FocusVideoData
public struct FocusVideoData: Equatable {
    public init(focusUser: ByteviewUser, version: Int64) {
        self.focusUser = focusUser
        self.version = version
    }

    /// 被设为焦点视频的参会人
    public var focusUser: ByteviewUser

    public var version: Int64
}

extension FocusVideoData: CustomStringConvertible {

    public var description: String {
        String(
            indent: "FocusVideoData",
            "identifier: \(focusUser.participantId.identifier)"
        )
    }
}
