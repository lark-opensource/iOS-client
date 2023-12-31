//
//  DriveImageFollowState.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2022/2/23.
//  


import Foundation
import SwiftyJSON
import SKCommon
import SpaceInterface

struct DriveImageFollowState {
    var offsetX: Double
    var offsetY: Double
    var rotate: Double
    var scale: Double
    
    init?(json: JSON) {
        guard let scale = json["scale"].double else { return nil }
        self.scale = scale
        self.offsetX = json["offsetX"].double ?? 0
        self.offsetY = json["offsetY"].double ?? 0
        self.rotate = json["rotate"].double ?? 0
    }
    
    init(offsetX: Double, offsetY: Double, rotate: Double, scale: Double) {
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.rotate = rotate
        self.scale = scale
    }
    
    init(scale: Double) {
        self.offsetX = 0
        self.offsetY = 0
        self.rotate = 0
        self.scale = scale
    }
    
    static var `default`: Self {
        return DriveImageFollowState(offsetX: 0, offsetY: 0, rotate: 0, scale: 1)
    }
}

extension DriveImageFollowState: DriveFollowModuleState {
    
    static var module: String {
        return FollowNativeModule.image.rawValue
    }
    
    var actionType: String {
        return "drive_update"
    }
    
    var data: JSON {
        var data: [String: Any] = [:]
        data["scale"] = scale
        data["offsetX"] = offsetX
        data["offsetY"] = offsetY
        data["rotate"] = rotate
        return JSON(data)
    }
    
    init?(data: JSON) {
        self.init(json: data)
    }
}
