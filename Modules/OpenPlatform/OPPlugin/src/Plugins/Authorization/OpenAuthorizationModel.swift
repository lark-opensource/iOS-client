//
//  OpenAuthorizeModel.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/5/7.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkSetting

final class OpenAPIAuthorizationResult: OpenAPIBaseResult {
    public var data:[String:String]
    public init(data:[String:String]) {
        self.data = data
        super.init()
    }
    
    public override init() {
        data = [:]
        super.init()
    }
    
    public override func toJSONDict() -> [AnyHashable : Any] {
        if OpenAPIFeatureKey.authorize.isEnable() {
            return [:]
        } else {
            return ["data":self.data]
        }
    }
}



final class OpenAPIAuthorizationParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "scope",
                          validChecker: { !$0.isEmpty },
                          grayChecker: .checker(OpenAPIValidChecker.enum(authScopeChecker()),
                                                featureKey: OpenAPIFeatureKey.authorize.rawValue))
    public var scope: String

    public convenience init(scope: String) throws {
        let dict: [String: String] = ["scope":scope]
        // init dict here
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // set checkable properties here
        return [_scope]
    }
    
    private static func authScopeChecker() -> [String] {
        var base = [
            BDPScopeUserInfo,
            BDPScopeUserLocation,
            BDPScopeRecord,
            BDPScopeWritePhotosAlbum,
            BDPScopeClipboard,
            BDPScopeCamera,
            BDPScopeRunData,
        ]
        if EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyGadgetOpenAppBadge) {
            base.append(BDPScopeAppBadge)
        }
        // TODOZJX
        if FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: EEFeatureGatingKeyScopeBluetoothEnable)) {
            base.append(BDPScopeBluetooth)
        }
        return base
    }
}
