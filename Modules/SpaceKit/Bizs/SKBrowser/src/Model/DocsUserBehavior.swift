//
//  DocsUserBehavior.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/2/6.
//  


import Foundation
import SKCommon

public class DocsTypeUsage: Codable, CustomStringConvertible {
    
    private(set) var lastOpenTime: TimeInterval
    private(set) var recentOpenCount: [Int]
    
    internal init(lastOpenTime: TimeInterval, recentOpenCount: [Int]) {
        self.lastOpenTime = lastOpenTime
        self.recentOpenCount = recentOpenCount
    }
    
    internal init() {
        self.lastOpenTime = 0
        self.recentOpenCount = []
    }
    
    func updateOpenTime() {
        lastOpenTime = NSDate().timeIntervalSince1970
    }
    
    func appendNewRecord() {
        recentOpenCount.append(0)
    }
    
    func increaseOpenCount() {
        updateOpenTime()
        if recentOpenCount.isEmpty {
            recentOpenCount.append(1)
        } else {
            recentOpenCount[recentOpenCount.count - 1] = recentOpenCount[recentOpenCount.count - 1] + 1
        }
    }
    
    func cutdownIfNeed(maxSize: Int) {
        if recentOpenCount.count > maxSize {
            self.recentOpenCount = Array(recentOpenCount.suffix(maxSize))
        }
    }
    
    func totalOpenCount() -> Int {
        let totalOpenCount = recentOpenCount.reduce(0, +)
        return totalOpenCount
    }
    
    public var description: String {
        return "recentCount:\(self.recentOpenCount), openTime:\(self.lastOpenTime)"
    }
}
