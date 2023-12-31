//
//  HomeRequestDefines.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/7/9.
//

import Foundation

public enum MinutesOwnerType: Int {
    case byAnyone = 1
    case byMe = 2
    case shareWithMe = 3
    case recentlyCreate = 4
    case recentlyOpen = 5
}

public enum MinutesSpaceType: Int {
    case home = 1
    case my = 2
    case share = 3
    case trash = 4
}

extension MinutesSpaceType {
    public var stringValue: String {
        String(self.rawValue)
    }
}


public enum MinutesRankType: Int {
    case createTime = 1
    case shareTime = 2
    case openTime = 3
    case expireTime = 4
    case schedulerExecuteTime = 5
}

public enum MinutesSchedulerType: Int, Codable, ModelEnum {
    
    public static var fallbackValue: MinutesSchedulerType = .unknown

    case none = 0
    case autoDelete = 1
    case autoDegrade = 2
    case unknown = -999
}
