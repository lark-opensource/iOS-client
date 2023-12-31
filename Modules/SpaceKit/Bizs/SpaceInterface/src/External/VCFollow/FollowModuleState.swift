//
//  FollowModuleState.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/30.
//  


import Foundation
import SwiftyJSON

/// VCFollow 模块状态
public struct FollowModuleState: Codable {
    public let module: String
    public let actionType: String
    public var data: JSON

    public init(module: String, actionType: String, data: JSON) {
        self.module = module
        self.actionType = actionType
        self.data = data
    }
}
public struct FollowLocationState: Codable {

    public struct Location: Codable {
        var x: Double
        var y: Double
        var space: String

        public init(x: Double, y: Double, space: String) {
            self.x = x
            self.y = y
            self.space = space
        }
    }

    let presenter: Location
    let follower: Location

    public init(presenter: FollowLocationState.Location, follower: FollowLocationState.Location) {
        self.presenter = presenter
        self.follower = follower
    }
}

/// 模块发送给RN的Event
public enum FollowModuleEvent {
    case stateChanged(FollowModuleState)     //FollowState变化事件
    case presenterLocationChanged(FollowLocationState)      //相对演讲者位置变化回调
}

/// 原生可支持 Follow 的模块
public enum FollowNativeModule: String {
    case pdf
    case video
    case image
}

/// 原生可监听的 Follow 模块
public enum FollowModule: String {
    case boxPreview = "BoxPreview" // 文档内附件
    case docxBoxPreview = "DocxBoxPreview" // 文档同层预览附件
}
