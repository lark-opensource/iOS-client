//
//  WATracker.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/30.
//

import Foundation
import SKFoundation
import LKCommonsTracker
import LKCommonsLogging

public final class WATracker {
    static let logger = Logger.log(WATracker.self, category: WALogger.TAG)
    let config: WebAppConfig
    
    private var eventStartTimes: [WATracker.EvetentType: Date] = [:]
    
    weak var container: WAContainer?
    
    public init(config: WebAppConfig) {
        self.config = config
    }
    
    public func log(event: WATracker.EvetentType, parameters: [String: Any]?) {
        // 添加公参
        var params: [String: Any] = ["appName": config.appName,
                                     "appId": config.appID]
        if let container {
            var extras = [String: Any]()
            if let currentZipVersion = container.hostOfflineManager?.currentZipVersion {
                extras[ReportKey.res_version.rawValue] = currentZipVersion
            }
            params.merge(other: extras)
        }
        params.merge(other: parameters)
        
        #if DEBUG
        WALogger.logger.debug("WATracker debug report: event is \(event.rawValue), params is \(params)")
        #else
        Tracker.post(TeaEvent(event.rawValue, params: params))
        #endif
    }
    
    public func start(event: WATracker.EvetentType) {
        guard eventStartTimes[event] == nil else {
            return
        }
        
        eventStartTimes[event] = Date()
        WALogger.logger.info("WATracker.perform: report event start for \(event.rawValue)")
    }
    
    public func end(event: WATracker.EvetentType) {
        guard let startDate = eventStartTimes[event] else {
            return
        }
        let costTime = round(Date().timeIntervalSince(startDate) * 1000)
        let params: [WATracker.ReportKey: Any] = [.costTime: costTime]
        
        WALogger.logger.info("WATracker.perform: report event end for \(event.rawValue)")
        log(event: event, parameters: params.mapKeyWithRawValue())
        eventStartTimes[event] = nil
    }
    
    func reportCommonError(errorType: WATrackerCommonErrorType, code: Int? = nil, msg: String? = nil) {
        var params: [String: Any] = [WATracker.ReportKey.error_type.rawValue: errorType.rawValue]
        if let code {
            params[ReportKey.code.rawValue] = code
        }
        if let msg {
            params[ReportKey.errorMsg.rawValue] = msg
        }
        self.log(event: .commonError, parameters: params)
    }
}

