//
//  LarkMonitor.swift
//  MinutesFoundation
//
//  Created by 陈乐辉 on 2022/10/31.
//

import Foundation
import LarkMonitor

public struct LKMonitor {
    
    @RwAtomic
    static var sessions: [String: BDPowerLogSession] = [:]
    
    public static func beginEvent(event: String, params: [AnyHashable : Any]? = nil) {
        BDPowerLogManager.beginEvent(event, params: params)
        let session = BDPowerLogManager.beginSession(event)
        sessions[event] = session
    }
    
    public static func endEvent(event: String, params: [AnyHashable : Any]? = nil) {
        BDPowerLogManager.endEvent(event, params: params)
        if let session = sessions.removeValue(forKey: event) {
            BDPowerLogManager.end(session)
        }
    }
}
