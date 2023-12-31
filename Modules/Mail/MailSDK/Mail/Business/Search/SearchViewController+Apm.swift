//
//  SearchViewController+Apm.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/10.
//

import Foundation
import Homeric

enum MailSearchClickType: String {
    case search_request
    case result_click
    case close
    case search_online_mail
}

extension MailSearchViewController {
    func apmMarkSearchStart() {
        let event = MailAPMEvent.Search()
        event.markPostStart()
        apmHolder[MailAPMEvent.Search.self] = event
    }

    func apmMarkSearchEnd(status: MailAPMEventConstant.CommonParam) {
        guard let event = apmHolder[MailAPMEvent.Search.self] else {
            assert(false, "no event started")
            MailAPMMonitorService.offTrack(event: MailAPMEventConstant.EndKey.search,
                                           type: .type_launch_without_start, message: nil)
            return
        }
        event.endParams.append(status)
        event.postEnd()
    }

    func apmMarkSearchLoadMoreStart() {
        let event = MailAPMEvent.SearchLoadMore()
        event.isDelayPoseStart = true // 为了适配多次重复loadmore
        event.markPostStart()
        apmHolder[MailAPMEvent.SearchLoadMore.self] = event
    }

    func apmMarkSearchLoadMoreEnd(status: MailAPMEventConstant.CommonParam) {
        guard let event = apmHolder[MailAPMEvent.SearchLoadMore.self] else {
//            assert(false, "no event started")
            MailAPMMonitorService.offTrack(event: MailAPMEventConstant.EndKey.searchMore,
                                           type: .type_launch_without_start, message: nil)
            return
        }
        event.endParams.append(status)
        event.postEnd()
    }

    func searchActionLog(_ clickType: MailSearchClickType, externalParmas: [String: Any] = [:]) {
        let keyword = self.searchField.text ?? ""
        var additionalParmas: [String: Any] = [:]
        switch clickType {
        case .search_request:
            additionalParmas.updateValue("none", forKey: "target")
            additionalParmas.updateValue(keyword.isLegalForEmail() ? "mail_address" : "key_words", forKey: "mail_search_type")

        case .result_click:
            additionalParmas.updateValue("email_message_list_view", forKey: "target")
            additionalParmas.updateValue("none", forKey: "tag")
            additionalParmas.updateValue("emails", forKey: "result_type")
            additionalParmas.updateValue("single_click_on_item", forKey: "result_click_action")
            additionalParmas.updateValue("accurate", forKey: "query_type")

        case .search_online_mail:
            additionalParmas.updateValue("email_message_list_view", forKey: "target")
            additionalParmas.updateValue("none", forKey: "tag")
            additionalParmas.updateValue("emails", forKey: "result_type")
            additionalParmas.updateValue("single_click_on_item", forKey: "result_click_action")
            additionalParmas.updateValue("accurate", forKey: "query_type")

        case .close:
            additionalParmas.updateValue("none", forKey: "target")
            additionalParmas.updateValue("True", forKey: "is_active")
        }
        var baseParmas: [String: Any] = ["click": clickType.rawValue,
                                         "search_location": "emails",
                                         "query_length": keyword.count,
                                         "query_id": keyword.md5(),
                                         "search_session_id": commonSession,
                                         "request_timestamp": String(Int(Date().timeIntervalSince1970)),
                                         "scene_type": "component",
                                         "enter_type": self.apmEnterType(),
                                         "filter_status": "none"]
        baseParmas.merge(other: additionalParmas)
        baseParmas.merge(other: externalParmas)
        if let search_type = baseParmas["search_type"] as? String, search_type == "EMAIL_SEARCH" {
            if clickType == .result_click {
                MailTracker.log(event: "email_thread_list_click", params: baseParmas)
            } else if clickType == .search_request {
                MailTracker.log(event: "email_search_click", params: baseParmas)
            }
        } else {
            MailTracker.log(event: Homeric.ASL_SEARCH_CLICK, params: baseParmas)
        }
    }

    func searchShowLog(externalParmas: [String: Any] = [:]) {
        let keyword = self.searchField.text ?? ""
        var baseParmas: [String: Any] = ["search_location": "emails",
                                         "query_length": keyword.count,
                                         "query_id": keyword.md5(),
                                         "is_filter": "False",
                                         "filter_status": "none",
                                         "query_type": "accurate",
                                         "search_session_id": commonSession,
                                         "request_timestamp": String(Int(Date().timeIntervalSince1970)),
                                         "scene_type": "component",
                                         "enter_type": self.apmEnterType()]
        baseParmas.merge(other: externalParmas)
        if let search_type = baseParmas["search_type"] as? String, search_type == "EMAIL_SEARCH" {
            MailTracker.log(event: "email_thread_list_view", params: baseParmas)
        } else {
            MailTracker.log(event: Homeric.ASL_SEARCH_SHOW, params: baseParmas)
        }
    }

    func searchIDList() -> [[String: Any]] {
        var list = [[String: Any]]()
        let searchList = self.searchViewModel.allItems().map { $0.viewModel }
        for resultItem in self.searchViewModel.allItems() {
            let item = ["entity_id": resultItem.viewModel.threadId,
                        "result_type": "mail_message",
                        "tag": "",
                        "label_items": resultItem.viewModel.labelItems(),
                        "result_hint_from": resultItem.info.hintFromResult()]
            list.append(item)
        }
        return list
    }

    func apmEnterType() -> String {
        return self.scene == .inMailTab ? "mail_search" : "asl_search"
    }
}
