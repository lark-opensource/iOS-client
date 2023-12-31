//
//  PersonCardUtility.swift
//  LarkByteView
//
//  Created by liuning.cn on 2020/4/28.
//

import Foundation
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift

struct PersonCardInfo {
    // refer to doc: https://bytedance.feishu.cn/docs/doccnlCxYN5ro5JkqkLmywQQ958#
    var sender: String
    var senderId: String
    var sourceId: String
    var sourceName: String

    // person card chatter id
    var chatterID: String
}

enum PersonCardUtility {
    static func personCardFriendSource(chatterAPI: ChatterAPI?,
                                       sponsorID: String,
                                       meetingId: String,
                                       meetingTopic: String,
                                       chatterID: String) -> Single<PersonCardInfo> {
        var info = PersonCardInfo(sender: "",
                                  senderId: sponsorID,
                                  sourceId: meetingId,
                                  sourceName: meetingTopic,
                                  chatterID: chatterID)

        if !meetingTopic.isEmpty {
            return .just(info)
        }

        guard let chatterAPI = chatterAPI else { return .just(info) }
        return chatterAPI.getChatter(id: sponsorID).map { chatter -> PersonCardInfo in
            if let cht = chatter {
                info.sender = cht.name
            }
            return info
        }
        .catchErrorJustReturn(info)
        .observeOn(MainScheduler.instance).asSingle()
    }

    static func personCardFriendSource(meetingTopic: String, sponsorName: String, sponsorId: String,
                                       meetingId: String, chatterID: String) -> PersonCardInfo {
        let sender = meetingTopic.isEmpty ? sponsorName : ""
        let info = PersonCardInfo(sender: sender, senderId: sponsorId,
                                  sourceId: meetingId, sourceName: meetingTopic,
                                  chatterID: chatterID)
        return info
    }

    static func personCardBody(friendSource: PersonCardInfo) -> PersonCardBody {
        return PersonCardBody(chatterId: friendSource.chatterID,
                              chatId: "",
                              fromWhere: .none,
                              senderID: friendSource.senderId,
                              sender: friendSource.sender,
                              sourceID: friendSource.sourceId,
                              sourceName: friendSource.sourceName,
                              source: .vc)
    }
}
