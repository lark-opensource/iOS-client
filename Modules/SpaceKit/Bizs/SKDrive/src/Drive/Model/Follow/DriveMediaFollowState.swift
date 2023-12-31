//
//  DriveMediaFollowState.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2022/2/23.
//  


import Foundation
import SwiftyJSON
import SKCommon
import SpaceInterface

struct DriveMediaFollowState {
    enum VideoStatus: Int {
        case notStarted = 0
        case playing = 1
        case paused = 2
        case ended = 3
    }
    
    var status: VideoStatus
    var isFullscreen: Bool
    var playbackRate: Double
    var currentTime: Double
    var recordId: String
    
    init?(json: JSON) {
        guard let statusRaw = json["status"].int,
              let status = VideoStatus(rawValue: statusRaw) else {
            return nil
        }
        self.status = status
        self.isFullscreen = json["isFullscreen"].bool ?? false
        self.playbackRate = json["playbackRate"].double ?? 1
        self.currentTime = json["currentTime"].double ?? 0
        self.recordId = json["recordId"].string ?? ""
    }
    
    init(status: VideoStatus, currentTime: Double, recordId: String) {
        self.status = status
        self.isFullscreen = false
        self.playbackRate = 1
        self.currentTime = currentTime
        self.recordId = recordId
    }
}


extension DriveMediaFollowState: DriveFollowModuleState {
    static var module: String {
        return FollowNativeModule.video.rawValue
    }
    
    var actionType: String {
        return "drive_update"
    }
    
    var data: JSON {
        var data: [String: Any] = [:]
        data["status"] = status.rawValue
        data["isFullscreen"] = isFullscreen
        data["playbackRate"] = playbackRate
        data["currentTime"] = currentTime
        data["recordId"] = recordId
        return JSON(data)
    }
    
    init?(data: JSON) {
        self.init(json: data)
    }
}

extension DriveMediaFollowState: Equatable {
    static func == (lhs: DriveMediaFollowState, rhs: DriveMediaFollowState) -> Bool {
        return lhs.status == rhs.status && lhs.currentTime == rhs.currentTime
        && lhs.isFullscreen == rhs.isFullscreen && lhs.playbackRate == lhs.playbackRate
    }
}
