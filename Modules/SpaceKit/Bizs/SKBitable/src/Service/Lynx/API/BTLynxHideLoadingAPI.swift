//
//  BTLynxHideLoadingAPI.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/9.
//

import Foundation
import SKFoundation
import LarkLynxKit
import BDXLynxKit

private var bitableChartStatusViewKey: Void?
extension LynxView {
    
    // 数据更新
    var bitableChartStatusView: BitableChartStatusView? {
        get {
            return objc_getAssociatedObject(self, &bitableChartStatusViewKey) as? BitableChartStatusView
        }
        set {
            objc_setAssociatedObject(self, &bitableChartStatusViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public final class BTLynxHideLoadingAPI: NSObject, BTLynxAPI {
    static let apiName = "hideLoading"
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
//        guard let chartToken = params["chartToken"] as? String else {
//            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "chartToken")))
//            return
//        }
        guard let lynxView = lynxContext?.getLynxView(),
           let chartStatusView = lynxView.bitableChartStatusView,
              chartStatusView.chartToken != nil else {
            let message = lynxContext?.getLynxView() == nil ? "lynx view is nil" : "chartStatusView is nil"
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "info", value: message)))
            return
        }
        DispatchQueue.main.async {
            lynxView.isHidden = false
            chartStatusView.updateViewWithStatus(.success)
        }
        callback?(.success(data: BTLynxAPIBaseResult()))
        
//        if let renderingChartToken = chartStatusView.chartToken,
//           renderingChartToken == chartToken {
//            DocsLogger.btInfo("chart token is matched, status loading view is going to hide")
//            DispatchQueue.main.async {
//                lynxView.isHidden = false
//                chartStatusView.updateViewWithStatus(.success)
//            }
//            callback?(.success(data: BTLynxAPIBaseResult()))
//        } else {
//            DocsLogger.btWarn("chart token not matching, when renderingChartToken is\(chartStatusView.chartToken?.encryptToShort) and chartToken is \(chartToken.encryptToken)" )
//            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "key", value: "chartToken")))
//        }
    }
}

