//
//  MonitorSocketReceiveModel.swift
//  LarkPrivacyMonitor
//
//  Created by huanzhengjie on 2023/3/4.
//

import UIKit

/// 通信的回调方法
typealias MonitorSocketReceiveAction = (String, [AnyHashable: Any]) -> [AnyHashable: Any]

final class MonitorSocketReceiveModel: NSObject {
    let methodName: String
    let action: MonitorSocketReceiveAction

    init(methodName: String, action: @escaping MonitorSocketReceiveAction) {
        self.methodName = methodName
        self.action = action
    }
}
