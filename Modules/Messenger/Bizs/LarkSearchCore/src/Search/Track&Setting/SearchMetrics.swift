//
//  SearchMetrics.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/6/8.
//

import Foundation
import LKMetric
import RustPB
import LarkModel
import LKCommonsLogging
import LarkSDKInterface

let searchLogger = Logger.log(SearchMetrics.self, category: "Search")
// swiftlint:disable nesting
/// 该类用于封装Search的Metrics相关接口方法
/// https://bytedance.feishu.cn/wiki/wikcn9O8RTEFm3d4qZvKew90W7o
public enum SearchMetrics {
    public static func log(
        domain: MetricDomain, type: MetricType, id: MetricID, params: [String: String] = [:], error: Error? = nil
    ) {
        LKMetric.log(domain: domain, type: type, id: id, params: params, error: error)
        #if DEBUG
        searchLogger.debug("LKMetric: \(domain.value) \(type) \(id)", additionalData: params, error: error)
        #endif
    }
    public enum LocalBackup {
        struct SubDomainValue: MetricDomainEnum {
            var rawValue: Int32 = 5
        }
        static var domain: MetricDomain { Root.search.s(SubDomainValue()) }
        enum ID: MetricID {
            /// 远端返回空
            case serverEmpty = 1
            /// 远端失败
            case serverError = 2
            /// 本地失败
            case localError = 3
        }
        private static func metric(query: String, session: SearchSession.Captured, scene: SearchScene, impr_id: String?, error: Error? = nil, id: ID) {
            /// 对于这类封装的API，由封装API统一保证数据安全，接口直接传原始数据即可。
            var params = [
                "query": query.lf.dataMasking,
                "session": session.session,
                "scene": String(scene.rawValue)
            ]
            if let impr_id = impr_id { params["impr_id"] = impr_id }
            SearchMetrics.log(domain: LocalBackup.domain, type: .business, id: id.rawValue, params: params, error: error)
        }
        public static func serverEmpty(query: String, session: SearchSession.Captured, scene: SearchScene, impr_id: String?) {
            metric(query: query, session: session, scene: scene, impr_id: impr_id, id: .serverEmpty)
        }
        public static func serverError(query: String, session: SearchSession.Captured, scene: SearchScene, impr_id: String? = nil, error: Error) {
            metric(query: query, session: session, scene: scene, impr_id: impr_id, error: error, id: .serverError)
        }
        public static func localError(query: String, session: SearchSession.Captured, scene: SearchScene, impr_id: String? = nil, error: Error) {
            metric(query: query, session: session, scene: scene, impr_id: impr_id, error: error, id: .localError)
        }
    }
}
// swiftlint:enable nesting
