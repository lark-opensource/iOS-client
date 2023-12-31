//
//  OPApplicationAPIContext.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/22.
//

import Foundation

extension OPEventContext {
    
    public var applicationContext: OPApplicationContext? {
        get {
            contextInfo("applicationContext") as? OPApplicationContext
        }
        
        set {
            setContextInfo("applicationContext", value: newValue, weak: true)
        }
    }
}
