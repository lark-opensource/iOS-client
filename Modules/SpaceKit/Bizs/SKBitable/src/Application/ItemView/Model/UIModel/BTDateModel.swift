//
//  BTDateModel.swift
//  SpaceKit
//
//  Created by 吴珂 on 2020/7/13.
//  


import Foundation
import HandyJSON
import SKBrowser

/// 对应前端的NotifyStrategyId
enum BTReminderStrategy: Int {
  case atTimeOfEvent = 0
  case before5Minute = 1
  case befor15Minute = 2
  case before30Minute = 3
  case befor1Hour = 4
  case before2Hour = 5
  case atDatOfEvent = 6
  case before1Day = 7
  case before2Day = 8
  case before1Week = 9
}


struct BTReminderEntity: HandyJSON, Equatable {
    var fields: [String] = []
    var users: [BTUserModel] = []
}

struct BTReminderModel: HandyJSON, Equatable {
    static func == (lhs: BTReminderModel, rhs: BTReminderModel) -> Bool {
        return lhs.notifyEntities == rhs.notifyEntities
            && lhs.notifyTime == rhs.notifyTime
            && lhs.notifyStrategy == rhs.notifyStrategy
    }
    
    var notifyEntities: BTReminderEntity?
    var notifyTime: Double?
    var notifyStrategy: BTReminderStrategy = .atTimeOfEvent
}

struct BTDateModel: HandyJSON, Equatable {
    static func == (lhs: BTDateModel, rhs: BTDateModel) -> Bool {
        return lhs.value == rhs.value
            && lhs.reminder == rhs.reminder
    }
    
    var value: TimeInterval = 0
    var reminder: BTReminderModel?

    mutating func didFinishMapping() {
        value /= 1000 // 前端传过来的是毫秒，我们改成秒
    }
}
