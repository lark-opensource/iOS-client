//
//  UtilKeyDownRecordService.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/11/4.
//

import SKFoundation
import SKCommon
import SKUIKit

public final class UtilKeyDownRecordService: BaseJSService { }

extension UtilKeyDownRecordService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.keyDownRecord]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard let spaceKeydownTimestamp = params["date"] as? Int,
              let spacePressesBeginTimestamp = model?.browserInfo.spacePressesBeginTimestamp,
              spaceKeydownTimestamp > spacePressesBeginTimestamp else {
            return
        }
        DocsLogger.debug("KeyDownRecordService, spaceKeydownTimestamp: \(spaceKeydownTimestamp), spacePressesBeginTimestamp: \(spacePressesBeginTimestamp)")
        #if DEBUG || BETA
        #else
        let params = ["pressesBegan": spacePressesBeginTimestamp, "keydownNotify": spaceKeydownTimestamp]
        if spaceKeydownTimestamp - spacePressesBeginTimestamp > 100 || twentyPercentageProbability() {
            DocsTracker.newLog(enumEvent: .chineseInputNativeCost, parameters: params)
        }
        #endif
    }

    // 20%的采样率上报率
    private func twentyPercentageProbability() -> Bool {
        return Int.random(in: 1...5) == 1
    }
}
