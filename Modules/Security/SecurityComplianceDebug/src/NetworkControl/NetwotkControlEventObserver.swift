//
//  NetwotkControlEventObserver.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2023/4/12.
//

import Foundation
import LarkRustClient
import RustPB
import TSPrivacyKit
import LarkPrivacyMonitor

@objc
protocol NetworkControlPushTrackHandlerDelegate {
    func didReceiveNetworkEvent(key: String, category: String, metric: String)
}

final class NetworkControlPushTrackHandler: NSObject, TSPKSubscriber {
    
    weak var delegate: NetworkControlPushTrackHandlerDelegate?
    
    func uniqueId() -> String {
        return NSStringFromClass(Self.self)
    }

    func canHandelEvent(_ event: TSPKEvent) -> Bool {
        return true
    }

    func hanleEvent(_ event: TSPKEvent) -> TSPKHandleResult? {
        guard let networkEvent = event as? TSPKNetworkEvent else {
            return nil
        }

        TSPKThreadPool.shard()?.networkWorkQueue()?.async { [weak self] in
            guard let self = self, NetworkMonitor.shared.canReport(networkEvent) else {
                return
            }
            
            self.delegate?.didReceiveNetworkEvent(key: "pns_network", category: "\(self.convertNetworkModelToParams(networkEvent))", metric: "")
        }
        return nil
    }

    func convertNetworkModelToParams(_ networkEvent: TSPKNetworkEvent) -> [String: Any]? {
        let request = networkEvent.request
        // common
        var dict: [String: Any] = ["is_request": false]
        dict["method"] = request?.tspk_util_HTTPMethod ?? ""
        dict["event_type"] = request?.tspk_util_eventType ?? ""
        dict["event_source"] = request?.tspk_util_eventSource ?? ""
        dict["is_redirect"] = request?.tspk_util_isRedirect
        // NSURL
        /// request
        dict["domain"] = request?.tspk_util_url?.host ?? ""
        dict["path"] = TSPKNetworkUtil.realPath(from: request?.tspk_util_url) ?? ""
        dict["scheme"] = request?.tspk_util_url?.scheme ?? ""
        /// response
        dict["res_domain"] = networkEvent.response?.tspk_util_url?.host ?? ""
        dict["res_path"] = TSPKNetworkUtil.realPath(from: networkEvent.response?.tspk_util_url) ?? ""
        dict["res_scheme"] = networkEvent.response?.tspk_util_url?.scheme ?? ""
        // other infos
        dict["monitor_scenes"] = "network_anaylze"
        dict["is_login"] = NetworkMonitor.shared.env?.isLogin
        dict["user_brand"] = NetworkMonitor.shared.env?.userBrand
        dict["package_id"] = NetworkMonitor.shared.env?.packageId
        return dict
    }
}
