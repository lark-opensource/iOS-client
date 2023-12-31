//
//  Logger.swift
//  ByteView
//
//  Created by kiri on 2020/8/26.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

typealias Logger = ByteViewCommon.Logger

extension Logger {
    static let tab = getLogger("MeetTab")
    static let tabBadge = getLogger("TabBadge")
    static let meetingList = getLogger("Meeting.List")
    static let meetingDetail = getLogger("Meeting.Detail")
}
