//
//  TMAPluginWebSocketMonitorUtils.swift
//  TTMicroApp
//
//  Created by 刘焱龙 on 2022/9/14.
//

import UIKit
import OPSDK
import ThreadSafeDataStructure

@objcMembers
public final class TMAPluginWebSocketMonitorUtils: NSObject {
    private static var results: [Int: OPMonitor] {
        get { _result.getImmutableCopy() }
        set { _result.replaceInnerData(by: newValue) }
    }

    private static var _result: SafeDictionary<Int, OPMonitor> = [:] + .semaphore

    @objc
    public static func start(taskId: Int, uniqueId: OPAppUniqueID, params: [String: String]) {
        let result = OPMonitor(kEventName_mp_socket_result)
                     .setUniqueID(uniqueId)
                     .addMap(params)
                     .setPlatform(.tea)
                     .timing()
        results[taskId] = result
    }

    @objc
    public static func end(taskId: Int, success: Bool, error: Error?) {
        guard let result = results[taskId] else { return }
        result.setError(error)
        if success {
            result.setResultTypeSuccess()
        } else {
            result.setResultTypeFail()
        }
        result.timing()
        // 旧数据兼容逻辑, 网络埋点用 from_request_start_duration 字段记录时长, 而非通用 duration
        if let duration = result.metrics?[OPMonitorEventKey.duration] {
            result.addMap([kTMAPluginNetworkMonitorDuration: duration])
        }
        result.flush()
        results.removeValue(forKey: taskId)
    }

    @objc
    public static func remove(taskId: Int) {
        results.removeValue(forKey: taskId)
    }
}
