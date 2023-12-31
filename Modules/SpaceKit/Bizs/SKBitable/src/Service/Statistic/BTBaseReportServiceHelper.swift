//
//  BTBaseReportServiceHelper.swift
//  SKBitable-Unit-Tests
//
//  Created by 刘焱龙 on 2023/12/3.
//

import Foundation
import SKBrowser
import SKCommon
import SKFoundation
import SKInfra

protocol BTStatisticReportHandleDelegate: AnyObject {
    var traceId: String? { get }
    var isBitable: Bool { get }
    var token: String? { get }
    var baseToken: String? { get }
    var objTokenInLog: String? { get }

    func addObserver(_ o: BrowserViewLifeCycleEvent)
}

protocol BTStatisticReportHandle {
    func handle(reportItem: BTBaseStatisticReportItem)
}

final class BTBaseReportServiceHelper {
    struct RouterKey {
        static let defaultRouterKey = "defaultRouter"
        static let nativeRenderViewCycle = "view_lifecycle"
    }
    
    private var routerHandles = [String: BTStatisticReportHandle]()

    func setupRouter(delegate: BTStatisticReportHandleDelegate) {
        routerHandles[RouterKey.defaultRouterKey] = BTStatisticOpenFileHandle(delegate: delegate)
        routerHandles[RouterKey.nativeRenderViewCycle] = BTStatisticNativeRenderHandle()
    }

    func handle(params: [String: Any], serviceName: String) {
        guard UserScopeNoChangeFG.LYL.enableStatisticTrace else {
            return
        }
        DocsLogger.btInfo("BTBaseReportService handle \(serviceName)")
        switch serviceName {
        case DocsJSService.baseReport.rawValue:
            internalHandle(params: params)
        default:
            DocsLogger.btError("unsupport serviceName \(serviceName)")
        }
    }

    private func internalHandle(params: [String: Any]) {
        guard UserScopeNoChangeFG.LYL.enableStatisticTrace else {
            return
        }
        let report = BTBaseStatisticReport.deserialized(with: params)
        guard let list = report.list else {
            return
        }
        for item in list {
            if let routers = item.router {
                for router in routers {
                    guard let handle = routerHandles[router] else {
                        return
                    }
                    handle.handle(reportItem: item)
                }
            } else {
                routerHandles[RouterKey.defaultRouterKey]?.handle(reportItem: item)
            }
        }
    }
}

struct BTBaseStatisticReport: SKFastDecodable {
    var list: [BTBaseStatisticReportItem]?

    static func deserialized(with dictionary: [String : Any]) -> BTBaseStatisticReport {
        var model = BTBaseStatisticReport()
        model.list <~ (dictionary, "list")
        return model
    }
}

struct BTBaseStatisticReportItem: SKFastDecodable {
    var event: String?
    var token: String?
    var time: Int?
    var extra: [String: Any]?
    var router: [String]?

    static func deserialized(with dictionary: [String : Any]) -> BTBaseStatisticReportItem {
        var model = BTBaseStatisticReportItem()
        model.event <~ (dictionary, "event")
        model.token <~ (dictionary, "token")
        model.time <~ (dictionary, "time")
        model.extra <~ (dictionary, "extra")
        model.router <~ (dictionary, "router")
        return model
    }
}
