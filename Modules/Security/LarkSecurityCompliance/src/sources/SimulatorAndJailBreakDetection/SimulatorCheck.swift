//
//  SimulatorCheck.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/8/30.
//

import Foundation
import LarkSecurityComplianceInfra

public final class SimulatorCheck {
    
    public class func check() -> Bool {
        var checkMethods = [() -> Bool]()
        checkMethods.append(checkProcessInfo)
        
        for checkMethod in checkMethods where checkMethod() {
            return true
        }
        return false
    }
    
    private class func checkProcessInfo() -> Bool {
        Logger.info("simulatorCheck1: checkProcessInfo")
        return ProcessInfo().environment["SIMULATOR_DEVICE_NAME"] != nil
    }
}
