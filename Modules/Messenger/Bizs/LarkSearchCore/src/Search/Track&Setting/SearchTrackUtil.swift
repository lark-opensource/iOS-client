//
//  SearchTrackUtil.swift
//  LarkSearch
//
//  Created by ChalrieSu on 2018/8/10.
//

import UIKit
import Foundation
import LarkModel
import LKCommonsTracker
import Homeric
import RxSwift

public final class SearchTrackUtil {
    // nolint: magic_number
    public static func encrypt(id: String) -> String {
        let md5str = "ee".md5()
        let prefix = md5str[md5str.startIndex..<md5str.index(md5str.startIndex, offsetBy: 6)]
        let subfix = md5str[md5str.index(md5str.endIndex, offsetBy: -6)..<md5str.endIndex]
        let uniqueID = (String(prefix) + (id + String(subfix)).md5()).sha1()
        return uniqueID
    }
    // enable-lint: magic_number
    public static func track(_ event: String, params: [String: Any]) {
        #if DEBUG
        print("track(\(event)): \(params)")
        #endif
        Tracker.post(TeaEvent(event, params: params))
    }

    /// should call after reloadData, to measure next runloop render time
    public static func track(requestTimeInterval: TimeInterval, query: String, status: String, location: String) {
        let renderBeginTime = Date()
        DispatchQueue.main.async {
            let renderTimerInterval = Date().timeIntervalSince(renderBeginTime)
            var params = [String: Any]()
            params["search_render_result_time"] = Int(renderTimerInterval * 1000)
            params["search_receive_result_time"] = Int(requestTimeInterval * 1000)
            params["search_location"] = location
            params["search_query_length"] = query.count
            params["search_status"] = status
            track(Homeric.SEARCH_RENDER_RESULT, params: params)
        }
    }

    static func trackChatterPickerItemSelect(_ index: Int) {
        Tracker.post(TeaEvent(Homeric.LARKW_PICKER_ITEM_CLICK,
                              params: ["source": "search",
                                       "order": index,
                                       "breadcrumb_depth": 1])
        )
    }
    public static func trackForStableWatcher(domain: String, message: String, metricParams: [String: Any]?, categoryParams: [String: Any]?) {
        guard enablePostTrack() else { return }
        guard !domain.isEmpty, !message.isEmpty else { return }
        var realCategoryParams: [String: Any] = [
            "asl_monitor_domain": domain,
            "asl_monitor_message": message
        ]
        categoryParams?.forEach({(key, value) in
            realCategoryParams[key] = value
        })
        Tracker.post(SlardarEvent(name: "asl_watcher_event",
                                  metric: metricParams ?? [:],
                                  category: realCategoryParams,
                                  extra: [:]))
    }
    public static func enablePostTrack() -> Bool {
        return SearchRemoteSettings.shared.enablePostStableTracker
    }
}

extension UITableView {
    /// - Parameters:
    ///   - indexPath: must be a valid indexPath
    /// - Returns: return 1-based absolute position, count previous section count
    public func absolutePosition(at indexPath: IndexPath) -> Int {
        var pos = 1
        for i in 0..<indexPath.section {
            pos += self.numberOfRows(inSection: i)
        }
        return pos + indexPath.row
    }
}
