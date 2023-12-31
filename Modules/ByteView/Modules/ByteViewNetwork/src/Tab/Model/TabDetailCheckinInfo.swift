//
// Created by maozhixiang.lip on 2022/10/12.
//

import Foundation

public struct TabDetailCheckinInfo: Equatable {
    /// 归属会议ID
    public var meetingId: String
    /// 签到信息文档URL
    public var url: String
    /// 签到信息文档标题
    public var title: String
    /// 签到信息归属用户的UID
    public var ownerUserId: String
}

extension TabDetailCheckinInfo: CustomStringConvertible {
    public var description: String {
        "TabDetailCheckinInfo(mid: \(meetingId), title: \(title), ownerUserId: \(ownerUserId))"
    }
}
