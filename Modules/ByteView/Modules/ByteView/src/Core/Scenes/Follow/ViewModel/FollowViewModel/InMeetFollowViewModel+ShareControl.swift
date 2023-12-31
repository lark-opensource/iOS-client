//
//  InMeetFollowViewModel+ShareControl.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/8/25.
//

import Foundation
import RxSwift

extension InMeetFollowViewModel {
    /// 自己正在共享内容
    var isSelfSharingContent: Bool { meeting.shareData.isSelfSharingContent }
    /// 有人正在共享内容
    var isSharingContent: Bool { meeting.shareData.isSharingContent }
    /// 有发起共享内容的权限
    var canShareContent: Bool { meeting.setting.canShareContent }
    /// 有在其他人共享内容时，发起新共享的权限
    var canReplaceShareContent: Bool { meeting.setting.canReplaceShareContent }
}
