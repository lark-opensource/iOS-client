//
//  EventDetailNavigationBarViewModel+Report.swift
//  Calendar
//
//  Created by Rico on 2021/4/13.
//

import Foundation
import LarkAppConfig

extension EventDetailNavigationBarViewModel {
    func report() {

        CalendarTracerV2.EventMore.traceClick {
            $0.click("report").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }

        if let schema = event.dt.schemaLink(key: .report) {
            rxRoute.accept(.url(url: schema))
            return
        }

        guard let event = model.event else {
            return
        }

        guard let reportHost = appConfiguration?.settings[DomainSettings.suiteReport]?.first else {
            return
        }

        let uid = event.key
        let originalTime = String(event.originalTime)
        var data = [String: String]()
        data["uid"] = uid
        data["original_time"] = originalTime
        data["calendar_id"] = calendarManager?.calendar(with: event.calendarID)?.serverId
        /// map to jsonstring
        guard let paramsJSONData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else { return }
        guard let paramsJSONString = String(data: paramsJSONData, encoding: .utf8) else { return }
        /// encode params
        guard let encodeParamsString = paramsJSONString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        /// push url
        let urlString = "https://\(reportHost)/report/?" + "type=calendar&params=\(encodeParamsString)"
        guard let url = URL(string: urlString) else { return }
        rxRoute.accept(.url(url: url))
        EventDetail.logInfo("do report. url: \(urlString)")
    }

}
