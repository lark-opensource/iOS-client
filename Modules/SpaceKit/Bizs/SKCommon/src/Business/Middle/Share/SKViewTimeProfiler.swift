//
//  SKViewTimeProfiler.swift
//  SKCommon
//
//  Created by peilongfei on 2022/6/20.
//  


import Foundation
import RxSwift

class SKViewTimeProfiler {
    
    enum Action: String {
        case begin
        case didLoad
        case appear
        case fetchData
        case end
    }
    
    private var actionTimes: [String: TimeInterval] = [
        Action.begin.rawValue: 0,
        Action.didLoad.rawValue: 0,
        Action.appear.rawValue: 0,
        Action.fetchData.rawValue: 0,
        Action.end.rawValue: 0
    ]
    
    private var durations: [String: TimeInterval] = [
        Action.begin.rawValue: 0,
        Action.didLoad.rawValue: 0,
        Action.appear.rawValue: 0,
        Action.fetchData.rawValue: 0,
        Action.end.rawValue: 0
    ]
    
    func record(with action: Action) {
        actionTimes[action.rawValue] = getCurrentTime()
        switch action {
        case .begin:
            durations[action.rawValue] = calculateDuration(curAction: .begin, preAction: .begin)
        case .didLoad:
            durations[action.rawValue] = calculateDuration(curAction: .didLoad, preAction: .begin)
        case .appear:
            durations[action.rawValue] = calculateDuration(curAction: .appear, preAction: .begin)
        case .fetchData:
            durations[action.rawValue] = calculateDuration(curAction: .fetchData, preAction: .didLoad)
        case .end:
            durations[action.rawValue] = calculateDuration(curAction: .end, preAction: .fetchData)
        }
    }
    
    func getDuration(of action: Action) -> TimeInterval {
        return durations[action.rawValue] ?? 0
    }
    
    func getTotalDuration() -> TimeInterval {
        return calculateDuration(curAction: .end, preAction: .begin)
    }
}

extension SKViewTimeProfiler {
    
    private func getCurrentTime() -> TimeInterval {
        return Date().timeIntervalSince1970 * 1000
    }
    
    private func calculateDuration(curAction: Action, preAction: Action) -> TimeInterval {
        guard let curTime = actionTimes[curAction.rawValue], let preTime = actionTimes[preAction.rawValue] else { return 0 }
        return (curTime - preTime)
    }
}
