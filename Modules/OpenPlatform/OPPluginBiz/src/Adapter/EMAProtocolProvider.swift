//
//  EMAProtocolProvider.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/5/16.
//

import Foundation
import OPFoundation
import EEMicroAppSDK
import LarkContainer
import LarkSetting

@objc
public final class EMAProtocolProvider: NSObject {
    
    @InjectedSafeLazy
    private static var liveFaceDelegate: EMALiveFaceProtocol // Global
    
    private static var fg: Bool {
        EMARouteProvider.FG.value
    }
    
    @objc
    public static func getEMADelegate() -> EMAProtocol? {
        return EMARouteProvider.getEMADelegate()
    }
    
    public static func getLiveFaceDelegate() -> EMALiveFaceProtocol? {
        if fg {
            return self.liveFaceDelegate
        } else {
            return EERoute.shared().liveFaceDelegate
        }
    }
}
