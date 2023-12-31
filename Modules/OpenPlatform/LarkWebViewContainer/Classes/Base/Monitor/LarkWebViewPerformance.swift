//
//  LarkWebViewPerformance.swift
//  LarkWebViewContainer
//
//  Created by bytedance on 2022/9/15.
//

import UIKit
import LarkSetting

public enum WebviewTimeConsumingPhase : String {
    case navigationPolicy
    case navigationStart
    case navigationResponse
    case webCommit
    case webChallenge
    case webRedirect
    case webSecLink
    case webCreate
    case webContainerDidLoad
}

@objc
final class LarkWebViewPerformanceItem: NSObject {
    // MARK: 属性
    var name : String
    var timeConsuming : UInt64 = 0
    var countTimes : UInt64 = 0
    lazy var childConsumingMap : [String: LarkWebViewPerformanceItem] = {
        let childMap : [String: LarkWebViewPerformanceItem] = [:]
        return childMap
    }()
    
    var performanceDict: [String: Any] {
        var result:[String: Any] = pInfoDict
        var childInfoArray:Array<Any> = []
        for item in self.childConsumingMap.values {
            if(item.timeConsuming >= 1) {
                childInfoArray.append(item.pInfoDict)
            }
        }
        if !childInfoArray.isEmpty {
            result.updateValue(childInfoArray, forKey: "child")
        }
        return result
    }
    
    var pInfoDict: [String: Any] {
        return [
            "n": name,
            "t": "\(timeConsuming)",
            "ct": "\(countTimes)",
        ]
    }
    
    // MARK: 方法
    init(name: String) {
        self.name = name
    }
}

@objc
public final class LarkWebViewPerformance: NSObject {
    //MARK: 属性
    lazy var performanceMap : [WebviewTimeConsumingPhase:LarkWebViewPerformanceItem] = {
        var map:[WebviewTimeConsumingPhase:LarkWebViewPerformanceItem] = [:]
        map.updateValue(LarkWebViewPerformanceItem.init(name:WebviewTimeConsumingPhase.navigationPolicy.rawValue), forKey:.navigationPolicy)
        map.updateValue(LarkWebViewPerformanceItem.init(name:WebviewTimeConsumingPhase.navigationStart.rawValue), forKey:.navigationStart)
        map.updateValue(LarkWebViewPerformanceItem.init(name:WebviewTimeConsumingPhase.navigationResponse.rawValue), forKey:.navigationResponse)
        map.updateValue(LarkWebViewPerformanceItem.init(name:WebviewTimeConsumingPhase.webCommit.rawValue), forKey:.webCommit)
        map.updateValue(LarkWebViewPerformanceItem.init(name:WebviewTimeConsumingPhase.webRedirect.rawValue), forKey:.webRedirect)
        map.updateValue(LarkWebViewPerformanceItem.init(name:WebviewTimeConsumingPhase.webChallenge.rawValue), forKey:.webChallenge)
        map.updateValue(LarkWebViewPerformanceItem.init(name:WebviewTimeConsumingPhase.webSecLink.rawValue), forKey:.webSecLink)
        map.updateValue(LarkWebViewPerformanceItem.init(name:WebviewTimeConsumingPhase.webCreate.rawValue), forKey:.webCreate)
        map.updateValue(LarkWebViewPerformanceItem.init(name:WebviewTimeConsumingPhase.webContainerDidLoad.rawValue), forKey:.webContainerDidLoad)
        return map
    }()
 
    //MARK: public方法
    public func recordTimeConsumingIn(phase: WebviewTimeConsumingPhase, duration: TimeInterval) {
        guard duration > 0 else{
            return
        }
        let mseconds:UInt64 = UInt64(duration * 1000)
        if (mseconds >= 1){
            var item = self.performanceMap[phase]
            item?.timeConsuming +=  mseconds
            item?.countTimes += 1
        }
    }
    
    public func recordExtensionItemTimeConsumingIn(phase: WebviewTimeConsumingPhase,  duration: TimeInterval, itemName: String) {
            guard duration > 0 else{
                return
            }
            let mseconds:UInt64 = UInt64(duration * 1000)
            guard mseconds >= 1 else {
                return
            }
            guard let parentItem = self.performanceMap[phase] else {
                return
            }
            if let childItem = parentItem.childConsumingMap[itemName] {
                childItem.timeConsuming +=  mseconds
                childItem.countTimes += 1
                
            }else{
                var childItem = LarkWebViewPerformanceItem.init(name:itemName)
                childItem.timeConsuming = mseconds
                childItem.countTimes = 1
                parentItem.childConsumingMap.updateValue(childItem, forKey:itemName)
            }
        }

    public func fetchTimeConsumingInfo() -> Array<Any> {
        var infoArray:Array<Any> = []
        for item in self.performanceMap.values {
            if(item.timeConsuming >= 1) {
                infoArray.append(item.performanceDict)
            }
        }
        return infoArray
    }
}
