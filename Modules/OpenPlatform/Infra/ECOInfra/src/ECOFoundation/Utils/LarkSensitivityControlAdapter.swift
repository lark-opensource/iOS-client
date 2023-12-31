//
//  LarkSensitivityControlAdapter.swift
//  ECOInfra
//
//  Created by zhangxudong.999 on 2023/5/19.
//

import Foundation
import Photos
import LarkSensitivityControl
import LarkSetting

extension LarkSensitivityControlAdapter {
    static var fgDisableKey: String { "openplatform.location_api_use_psda.disable" }
    static func sensitivityControlEnable() -> Bool {
        // TODOZJX
        return !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: fgDisableKey))
    }
}
@objc public class LarkSensitivityControlAdapter: NSObject {
  
    @objc static public func photos_PHAssetCreationRequest_creationRequestForAsset(tokenIdentifier: String) throws  -> PHAssetCreationRequest {
        if sensitivityControlEnable() {
            let token = LarkSensitivityControl.Token(withIdentifier: tokenIdentifier)
            return try LarkSensitivityControl.AlbumEntry.forAsset(forToken: token)
        } else {
            return PHAssetCreationRequest.forAsset()
        }
    }
    

}

