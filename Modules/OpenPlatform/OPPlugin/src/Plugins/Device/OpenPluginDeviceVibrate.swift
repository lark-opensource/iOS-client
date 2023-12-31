//
//  OpenPluginDeviceVibrate.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/4.
//

import Foundation
import AudioToolbox
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import LarkContainer

class OpenPluginDeviceVibrate: OpenBasePlugin {

    public func vibrateShort(callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        AudioServicesPlaySystemSound(1519);
        callback(.success(data: nil))
    }

    public func vibrateLong(callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "vibrateShort", pluginType: Self.self) { (this, _, context, callback) in
            
            this.vibrateShort(callback: callback)
        }
        registerInstanceAsyncHandler(for: "vibrateLong", pluginType: Self.self) { (this, _, context, callback) in
            
            this.vibrateLong(callback: callback)
        }
    }
}
