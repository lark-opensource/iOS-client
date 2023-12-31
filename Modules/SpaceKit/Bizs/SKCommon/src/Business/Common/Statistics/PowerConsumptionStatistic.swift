//
//  PowerConsumptionStatistic.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/9/4.
//  


import Foundation
import SKFoundation
import LarkMonitor

/// 5.22版本，功耗统计工具类-基础场景
public final class PowerConsumptionStatistic {
    
    typealias EventParamDict = ThreadSafeDictionary<String, Any>
    
    /// BDPowerLogManager 默认 session 的事件参数暂存，key 为 token, value 为 事件参数的字典
    private static var tempParams = ThreadSafeDictionary<String, EventParamDict>()
    
    public class func markStart(token: String, scene: PowerConsumptionStatisticScene) {
        guard !token.isEmpty else { return }
        let id = DocsTracker.encrypt(id: token)
        BDPowerLogManager.beginEvent(scene.name, params: [PowerConsumptionStatisticParamKey.encryptedId: id])
        updateParams(id, forKey: PowerConsumptionStatisticParamKey.encryptedId, token: token, scene: scene)
        
        PowerConsumptionExtendedStatistic.markStart(scene: scene)
        PowerConsumptionExtendedStatistic.updateParams(id, forKey: PowerConsumptionStatisticParamKey.encryptedId, scene: scene)
    }
    
    public class func markEnd(token: String, scene: PowerConsumptionStatisticScene) {
        guard let dict = tempParams.value(ofKey: token) else { return } // 没有和start成对的end调用，会被忽略
        let id = DocsTracker.encrypt(id: token)
        let merged = dict.merge(other: [PowerConsumptionStatisticParamKey.encryptedId: id])
        BDPowerLogManager.endEvent(scene.name, params: merged)
        tempParams.removeValue(forKey: token) // 上报完成后，清理暂存参数
        
        PowerConsumptionExtendedStatistic.markEnd(scene: scene)
    }

    public class func updateParams(_ value: Any, forKey: String, token: String, scene: PowerConsumptionStatisticScene) {
        let dictForToken: EventParamDict
        if let dict = tempParams.value(ofKey: token) {
            dictForToken = dict
        } else {
            dictForToken = EventParamDict.init()
        }
        dictForToken.updateValue(value, forKey: forKey)
        tempParams.updateValue(dictForToken, forKey: token)
        
        PowerConsumptionExtendedStatistic.updateParams(value, forKey: forKey, scene: scene)
    }
}

private extension ThreadSafeDictionary {
    
    func merge(other: [Key: Value]) -> [Key: Value] {
        for (key, value) in other {
            self.updateValue(value, forKey: key)
        }
        return self.all()
    }
}
