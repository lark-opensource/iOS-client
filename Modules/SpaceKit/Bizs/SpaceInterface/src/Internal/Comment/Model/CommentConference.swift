//
//  CommentConference.swift
//  SKCommon
//
//  Created by huayufan on 2022/3/29.
//  


import UIKit
import SwiftyJSON

public protocol CommentConferenceSource: AnyObject {
    var commentConference: CommentConference { get }
}

public struct CommentConference {
    
    public var followRole: FollowRole?
    
    public private(set) var inConference: Bool
    
    public var context: ConferenceContext?
    
    public init(inConference: Bool, followRole: FollowRole?, context: ConferenceContext?) {
        self.followRole = followRole
        self.inConference = inConference
        self.context = context
    }
}

/// ms返回的会议信息
public struct ConferenceContext: CustomStringConvertible {
    
    public var participantCount: Int = 0
    public var presenterDeviceId: String = ""
    
    public init(_ params: [String: Any]) {
        let json = JSON(params)
        self.participantCount = json["participant_count"].intValue
        self.presenterDeviceId = json["presenter_device_id"].stringValue
    }
    
    public var description: String {
        return "participantCount:\(self.participantCount) presenterDeviceId:\(self.presenterDeviceId)"
    }
}
