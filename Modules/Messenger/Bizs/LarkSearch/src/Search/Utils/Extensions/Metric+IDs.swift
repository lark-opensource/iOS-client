//
//  Metric+IDs.swift
//  LarkSearch
//
//  Created by lixiaorui on 2020/1/15.
//

import Foundation
import LKMetric
import CryptoSwift
import LarkCore
import LarkSearchCore
import LarkSDKInterface

extension MetricID {
    // domain: [11]
    static let openSearchID: MetricID = 1
    static let startSearchID: MetricID = 2
    static let refreshSearchUIID: MetricID = 3
    static let closeSearchID: MetricID = 4
    static let openDetailSearchID: MetricID = 5
    static let startDetailSearchID: MetricID = 6
    static let refreshDetailSearchUIID: MetricID = 7
    static let searchFailID: MetricID = 8
    static let detailSearchFailId: MetricID = 9

    // domain: [11,2]
    static let startNetSearchID: MetricID = 1
    static let handleNetSearchResultID: MetricID = 2
    static let netSearchSuccessID: MetricID = 3
    static let startDetailNetSearchID: MetricID = 4

    // domain: [11,3]
    static let startLocalSearchID: MetricID = 1
    static let handleLocalSearchResultID: MetricID = 2
    static let localSearchFinishID: MetricID = 3
    static let startDetailLocalSearchID: MetricID = 7
}

extension SearchMetrics {
    static func openDetailSearchID(key: String, session: SearchSession, scene: SearchSceneSection, datas: [SearchResultType], imprID: String? = nil) {
        let params: [String: String] = [
            "key": key.lf.dataMasking,
            "search_context": session.session,
            "datas": "\(datas.map({ SearchTrackUtil.encrypt(id: $0.id) }))",
            "scene": "\(scene)",
            "impr_id": imprID ?? ""]
            SearchMetrics.log(domain: Root.search.domain, type: .business, id: MetricID.openDetailSearchID, params: params)
    }
}
