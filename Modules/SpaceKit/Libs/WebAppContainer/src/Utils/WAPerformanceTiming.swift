//
//  WAPerformanceTiming.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/14.
//

import Foundation

public class WAPerformanceTiming {
    
    public var createWebView: Int64 = 0
    
    public var startLoadUrl: Int64 = 0
    
    var routeState = LoadStage.zero()
    
    var unzipState = LoadStage.zero()
    
    var preloadState = LoadStage.zero()
    
    var renderState = LoadStage.zero()
    
    var openCostTime: Int64 {
        renderState.end - routeState.start
    }
    
    static func getTimeStamp() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    static func convert(_ interval: TimeInterval) -> Int64 {
        return Int64(interval * 1000)
    }
}

struct LoadStage {
    var start: Int64
    var end: Int64
    
    var cost: Int64 {
        if start < end {
            return end - start
        }
        return 0
    }
    
    mutating func updateStart(_ newVal: Int64) {
        self.start = newVal
    }
    
    mutating func updateEnd(_ newVal: Int64) {
        self.end = newVal
    }
    
    //start有值时才更新
    mutating func updateEndIfNeed(_ newVal: Int64) {
        if start > 0 {
            self.end = newVal
        }
    }
    
    mutating func update(start: Int64, end: Int64) {
        self.start = start
        self.end = end
    }
    
    static func zero() -> LoadStage {
        return LoadStage(start: 0, end: 0)
    }
}
