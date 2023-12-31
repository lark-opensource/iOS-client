//
//  PreloadFeedbackAnaly.swift
//  LarkPreload
//
//  Created by huanglx on 2023/7/13.
//

import Foundation
import LarkStorage
import ThreadSafeDataStructure

//MARK: 预加载反馈持久化model
struct PreloadFeedbackInfo: Codable {
    //预处理名称
    var preloadName: String
    //预处理所属业务
    var preloadBiz: String
    //预处理类型
    var preloadType: String
    //获取预加载结果的次数
    var feedbackCount: Int64 = 0
    //前台情况下持续总时长
    var totalTime: TimeInterval = 0
    //创建时间戳
    var createTime: TimeInterval = NSDate().timeIntervalSince1970
    
    init(preloadName: String, preloadBiz: String, preloadType: String) {
        self.preloadName = preloadName
        self.preloadBiz = preloadBiz
        self.preloadType = preloadType
    }
}

extension PreloadFeedbackInfo: KVNonOptionalValue {
    public typealias StoreWrapped = Self
}

/*
预加载行为习惯分析
    -累计在前台单位时间获取预加载产物的的次数
*/
class PreloadFeedbackAnalysis {
    //单位时间内某个业务的某个预加载功能的使用反馈次数 -[biz:[type:count]]
    static var feedbackInfo: SafeDictionary<String, [String : Double]> = [:] + .readWriteLock
    //预加载反馈信息array
    static var feedbackInfoArray: SafeArray<PreloadFeedbackInfo> = [] + .semaphore
    //进入前台时间戳
    static var enterForegroundTime: TimeInterval?
    //当前生命周期在前台的时间总和
    static var foregroundTime: TimeInterval = 0
    //单位时间内某个业务的某个预加载功能的使用反馈次数持久化key
    static private let feedbackInfoKey = "preload_feedbackInfoKey"
    //KVStore
    private static var store = KVStores.udkv(space: .global, domain: Domain.biz.core)
    
    //MARK: 预加载反馈
    static func feedbackPreload(preloadName: String, preloadBiz: PreloadBiz, preloadType: PreloadType) {
        //如果之前没有添加过，添加一条
        if self.feedbackInfoArray.filter({ info in
            info.preloadBiz == preloadBiz.rawValue && info.preloadType == preloadType.rawValue
        }).count < 1 {
           let info = PreloadFeedbackInfo(preloadName: preloadName, preloadBiz: preloadBiz.rawValue, preloadType: preloadType.rawValue)
           self.feedbackInfoArray.append(info)
        }
        let resultArray = self.feedbackInfoArray.map { feebackInfo in
            if feebackInfo.preloadBiz == preloadBiz.rawValue && feebackInfo.preloadType == preloadType.rawValue {
                var feebackInfoCopy = feebackInfo
                feebackInfoCopy.feedbackCount += 1
                return feebackInfoCopy
            } else {
                return feebackInfo
            }
        }
        self.convertNormalArrayToSafe(normalArry: resultArray, safeArray: self.feedbackInfoArray)
    }
    
    //获取预加载反馈分析信息
    static func loadFeedbackAnalysisInfo() {
        //初始进入前台的时间
        self.enterForegroundTime = CACurrentMediaTime()
        //获取单位时间获取预加载反馈信息
        if let infoArray: [PreloadFeedbackInfo] = self.store.value(forKey: self.feedbackInfoKey) {
            infoArray.forEach { info in
                //计算单位时间获取数
                let count = info.feedbackCount
                //分钟
                let totalTime = info.totalTime / 60.0
                var rate = -1.0
                if totalTime > 0, totalTime > PreloadSettingsManager.feedbackMinTime() {
                    rate = Double(count) / Double(totalTime)
                }
                //组装数据
                if let bizDic = feedbackInfo[info.preloadBiz] {
                    var bizDicCopy = bizDic
                    bizDicCopy[info.preloadType] = rate
                    feedbackInfo[info.preloadBiz] = bizDicCopy
                } else {
                    feedbackInfo[info.preloadBiz] = [info.preloadType: rate]
                }
            }
            self.convertNormalArrayToSafe(normalArry: infoArray, safeArray: self.feedbackInfoArray)
        }
    }
    
    //应用退到后台，统计在前台的累计时间
    static func applicationDidEnterBackground() {
        if let enterForegroundTime = enterForegroundTime {
            //当次前后台切换时间
            foregroundTime += CACurrentMediaTime() - enterForegroundTime
            //累计到总时间中
            let result = self.feedbackInfoArray.map { info in
                var infoCopy = info
                infoCopy.totalTime += foregroundTime
                return infoCopy
            }
            self.store.set(result, forKey: self.feedbackInfoKey)
            self.convertNormalArrayToSafe(normalArry: result, safeArray: self.feedbackInfoArray)
        }
    }
    
    //应用唤起到前台，重置恢复前台时间起点
    static func applicationDidEnterForeground() {
        self.enterForegroundTime = CACurrentMediaTime()
    }
    
    //安全数组转换成普通数组
    static func convertSafeArrayToNormal<T>(safeArray: T) -> [T] {
        var normalArray: [T] = []
        normalArray.forEach {value in
            normalArray.append(value)
        }
        return normalArray
    }
    
    //普通数组转换成安全数组
    static func convertNormalArrayToSafe<T>(normalArry: [T], safeArray: SafeArray<T>) {
        safeArray.removeAll()
        normalArry.forEach { value in
            safeArray.append(value)
        }
    }
}
