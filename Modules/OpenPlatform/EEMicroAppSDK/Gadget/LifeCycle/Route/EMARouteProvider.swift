//
//  EMARouteProvider.swift
//  EEMicroAppSDK
//
//  Created by baojianjun on 2023/6/1.
//

import Foundation
import OPFoundation
import LarkContainer
import LarkSetting

@objc
public final class EMARouteProvider: NSObject {
    @Provider
    private static var emaProtocol: EMAProtocol
    
    public enum FG {
        private static let key = "openplatform.architecture.eeroute.decoupling"
        
        // 每次都需要重新获取
        public static var value: Bool {
            let fg = FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: Self.key))
            return fg
        }
    }
    
    @objc
    public static func getEMADelegate() -> EMAProtocol? {
        if Self.FG.value {
            return self.emaProtocol
        } else {
            return getEERouteDelegate()
        }
    }
}
