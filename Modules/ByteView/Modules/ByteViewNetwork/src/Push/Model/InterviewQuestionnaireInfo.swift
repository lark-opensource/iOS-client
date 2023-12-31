//
// Created by maozhixiang.lip on 2022/8/1.
//

import Foundation
import ServerPB

public struct InterviewQuestionnaireInfo {
    public var id: String
    public var link: String
    public var titleI18nKey: String
    public var guideI18nKey: String
    public var acceptButtonI18nKey: String
    public var refuseButtonI18nKey: String
    public var meetingID: String
    public var expireTime: TimeInterval // 过期时间(UnixTimestamp in seconds)
}

extension InterviewQuestionnaireInfo: CustomStringConvertible {
    public var description: String {
        "InterviewQuestionnaireInfo(id: \(id), meetingID: \(meetingID), expireTime: \(expireTime))"
    }
}

/// 面试满意度问卷推送(89376)
extension InterviewQuestionnaireInfo: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_PushInterviewQuestionnaireInfo

    init(pb: ProtobufType) {
        self.id = pb.questionnaireID
        self.link = pb.questionnaireLink
        self.titleI18nKey = pb.titleI18NKey
        self.guideI18nKey = pb.guideTextI18NKey
        self.acceptButtonI18nKey = pb.buttonTextI18NKey
        self.refuseButtonI18nKey = pb.closeTextI18NKey
        self.meetingID = pb.meetingID
        self.expireTime = TimeInterval(pb.expireTime / 1000)
    }
}
