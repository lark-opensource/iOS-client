//
//  Observer.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/8/31.
//

import Foundation
import LarkSnCService

public enum Event {
    /// 决策环境发生变化（特征、策略），需要重新计算
    case decisionContextChanged
    case ipFactorChanged // ip 特征变更
}

public protocol Observer: AnyObject {
    func notify(event: Event)
}

extension WeakManager where T == Observer {
    func sendEvent(event: Event) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.weakObjects.forEach {
                ($0.value as? T)?.notify(event: event)
            }
        }
    }
}
