//
//  BTLynxContainerAPI.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/17.
//

import Foundation
import LarkLynxKit
import BDXLynxKit
import SKFoundation
import LarkContainer

public final class BTLynxGetContainerSizeAPI: NSObject, BTLynxAPI {
    @Injected private var containerEnvService: BTLynxContainerEnvService
    static let apiName = "getContainerSize"
    /**
     调用OpenAPI

     - Parameters:
       - apiName: API名
       - params: 调用API时的入参
       - callback: Lynx JSBridge回调
     */
    func invoke(params: [AnyHashable : Any],
                lynxContext: LynxContext?,
                bizContext: LynxContainerContext?,
                callback:  BTLynxAPICallback<BTLynxAPIBaseResult>?) {
        guard let lynxView = lynxContext?.getLynxView() else {
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "info", value: "lynx view is nil")))
            return
        }
        let result = ["width": Int(lynxView.frame.size.width), "height":  Int(lynxView.frame.size.height)]
        callback?(.success(data: BTLynxAPIBaseResult(dataString: result.jsonString)))
    }
}
    
fileprivate extension String {
    func KeyForLynxStorageAPI() -> String {
        return "BTLynxStorageAPI_\(self)"
    }
}


private var bitableChartTokenKey: Void?
extension LynxView {
    
    // 数据更新
    var bitableChartToken: String? {
        get {
            return objc_getAssociatedObject(self, &bitableChartTokenKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &bitableChartTokenKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}


public final class BTLynxOpenFullscreenAPI: NSObject, BTLynxAPI {
    @Injected private var containerEnvService: BTLynxContainerEnvService
    static let apiName = "openFullscreen"
    /**
     调用OpenAPI

     - Parameters:
       - apiName: API名
       - params: 调用API时的入参
       - callback: Lynx JSBridge回调
     */
    func invoke(params: [AnyHashable : Any],
                lynxContext: LynxContext?,
                bizContext: LynxContainerContext?,
                callback:  BTLynxAPICallback<BTLynxAPIBaseResult>?) {
        guard let lynxContext = lynxContext,
            let lynxView = lynxContext.getLynxView() else {
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "lynxContext", value: "lynxContext is nil")))
            return
        }
        guard let chartToken = lynxView.bitableChartToken  else {
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "bitableChartToken", value: "bitableChartToken is nil")))
            return
        }
        NotificationCenter.default.post(name: .init(SKBitableConst.triggerOpenFullscreenNoti),
                                        object: nil,
                                        userInfo: ["chartToken": chartToken])
        callback?(.success(data: BTLynxAPIBaseResult(dataString: nil)))
    }
}
