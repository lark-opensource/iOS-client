//
//  PKMType.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2022/11/30.
//

import Foundation
import OPSDK

public enum PKMType: UInt {
    case unknow = 0
    case gadget
    case webApp
    case widget = 6
    case block
    case dynamicComponent
    case JSSDK = 10
    case JSSDKBlock
    case JSSDKMsgCard
    
    public func toString() -> String {
        if (self.rawValue >= OPAppType.dynamicComponent.rawValue) {
            return "PKMType_\(self)"
        } else {
            return OPAppTypeToString(self.toAppType())
        }
    }
    
    public func toAppType() -> OPAppType {
        return OPAppType(rawValue: self.rawValue) ?? .unknown
    }
}


extension OPAppType {
    func toPKMType() -> PKMType {
        return PKMType(rawValue: self.rawValue) ?? .unknow
    }
}
