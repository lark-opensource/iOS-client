//
//  RecordCompletedInfo.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2022/6/20.
//

import Foundation
import ServerPB

/// 推送录制完成/妙记生成的信息
/// ServerPB_Videochat_tab_v2_RecordCompletedInfo
public struct RecordCompletedInfo {

    public var meetingID: String

    public var recordInfo: TabDetailRecordInfo
}

extension RecordCompletedInfo: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_RecordCompletedInfo

    init(pb: ServerPB_Videochat_tab_v2_RecordCompletedInfo) {
        self.meetingID = pb.meetingID
        self.recordInfo = pb.recordInfo.vcType
    }
}
