//
//  DocTimerObserverProtocol.swift
//  SKInfra
//
//  Created by ByteDance on 2023/4/7.
//  从DocGlobalTimer.swift下沉的协议

import Foundation

public protocol DocTimerObserverProtocol: AnyObject {

    var timeInterval: TimeInterval { get }

    func tiktok()
}

public extension DocTimerObserverProtocol {

    var timeInterval: TimeInterval { return 30.0 }

    func tiktok() {}
}
