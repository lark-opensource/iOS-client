//
//  MailHomeController+statistics.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/8/17.
//

import Foundation
import AnimatedTabBar
import LarkNavigation
import RxRelay

enum MailThreadListRefreshListScene: String {
    case unknown
    case switchAccount
    case switchLabel
    case switchFilter
    case markAllRead
    case pullToRefresh
    case forceRefresh // changelog刷新到case
}

public protocol MailFirstScrennDataObservable {
    func firstScreenDataReady() -> BehaviorRelay<Bool>
}

extension MailHomeController: MailFirstScrennDataObservable {
    func firstScreenDataReady() -> BehaviorRelay<Bool> {
        return _firstScreenDataReady
    }

    func firstScreenDataHadLoad() {
        if hasFirstScreenRender {
            return
        }
        hasFirstScreenRender = true
        _firstScreenDataReady.accept(true)
    }
}

extension MailHomeController: MailStateObserver {
    func didMailServiceFirstEntry() {
    }

    func didLeaveMailService() {
    }

    func didEnterMailService() {
        if hasFirstScreenRender, inViewWillAppear {
            viewModel.apmFirstScreenStart()
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            let type = MailAPMEvent.FirstScreenLoaded.EndParam.mode_hot_start
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(type)
            let from_db = viewModel.listViewModel.lastSource
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEvent.FirstScreenLoaded.EndParam.from_db(from_db ? 1 : 0))
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEvent.FirstScreenLoaded.EndParam.create_view_cost_time(0))
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEvent.FirstScreenLoaded.EndParam.load_label_list_cost_time(0))
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEvent.FirstScreenLoaded.EndParam.load_thread_list_cost_time(0))
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.customPostEnd()
        }
    }
}

// MARK: apm metric
extension MailHomeViewModel {
    typealias FirstScreenLoadScene = MailAPMEvent.FirstScreenLoaded.CommonParam

    static var apmHolder = MailAPMEventHolder()

    func apmFirstScreenStart(scene: FirstScreenLoadScene = FirstScreenLoadScene.sence_email_tab) {
        let event = MailAPMEvent.FirstScreenLoaded()
        event.commonParams.append(scene)
        event.markPostStart()
        apmHolder[MailAPMEvent.FirstScreenLoaded.self] = event
    }

    func apmFirstScreenUserLeave(_ hasFirstScreenRender: Bool) {
        apmHolder[MailAPMEvent.FirstScreenLoaded.self]?
            .endParams
            .append(MailAPMEvent.FirstScreenLoaded.EndParam.flag_user_leave(1))
        if hasFirstScreenRender {
            let type = MailAPMEvent.FirstScreenLoaded.EndParam.mode_hot_start
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(type)
        } else {
            let type = MailAPMEvent.FirstScreenLoaded.EndParam.mode_cold_start
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(type)
        }
        let from_db = listViewModel.lastSource
        let source = MailAPMEvent.FirstScreenLoaded.EndParam.from_db(from_db ? 1 : 0)
        apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(source)
    }

    // MARK: thread list apm
    func apmMarkThreadListStart(sence: MailAPMEvent.ThreadListLoaded.CommonParam) {
        let event = MailAPMEvent.ThreadListLoaded()
        if sence == .sence_load_more { // 为了适配多次重复loadmore
            event.isDelayPoseStart = true
        }
        event.commonParams.append(sence)
        event.markPostStart()
        if let apm = apmHolder[MailAPMEvent.ThreadListLoaded.self] { // 为了适配多次重复loadmore
            if apm.commonParams.contains(where: { (temp) -> Bool in
                if let param = temp as? MailAPMEvent.ThreadListLoaded.CommonParam,
                   param == MailAPMEvent.ThreadListLoaded.CommonParam.sence_load_more {
                    return true
                }
                return false
            }) {
                apmHolder[MailAPMEvent.ThreadListLoaded.self]?.abandon()
            }
        }
        let count = MailAPMEvent.ThreadListLoaded.EndParam.list_length(datasource.count)
        event.endParams.append(count)
        let from_db = listViewModel.lastSource
        let source = MailAPMEvent.ThreadListLoaded.EndParam.from_db(from_db ? 1 : 0)
        event.endParams.append(source)
        apmHolder[MailAPMEvent.ThreadListLoaded.self] = event
    }

    func apmMarkThreadListEnd(status: MailAPMEventConstant.CommonParam, error: Error? = nil) {
        guard let event = apmHolder[MailAPMEvent.ThreadListLoaded.self] else {
            return
        }
        let count = MailAPMEvent.ThreadListLoaded.EndParam.list_length(datasource.count)
        event.endParams.appendOrUpdate(count)
        let from_db = listViewModel.lastSource
        let source = MailAPMEvent.ThreadListLoaded.EndParam.from_db(from_db ? 1 : 0)
        event.endParams.appendOrUpdate(source)
        event.endParams.append(MailAPMEvent.ThreadListLoaded.EndParam.label_id(currentLabelId))
        event.endParams.appendError(errorCode: error?.mailErrorCode, errorMessage: error?.getMessage())
        event.endParams.append(status)
        if let apm = apmHolder[MailAPMEvent.ThreadListLoaded.self] { // 为了适配多次重复loadmore
            if apm.commonParams.contains(where: { (temp) -> Bool in
                if let param = temp as? MailAPMEvent.ThreadListLoaded.CommonParam,
                   param == MailAPMEvent.ThreadListLoaded.CommonParam.sence_reload {
                    return true
                }
                return false
            }) {
                MailLogger.info("[mail_thread_apm] sence_reload 上报结束")
            }
        }
        event.postEnd()
    }

    func apmMarkUserleaveIfNeeded(_ hasFirstScreenRender: Bool) {
        if let event = apmHolder[MailAPMEvent.ThreadListLoaded.self] {
            if hasFirstScreenRender {
                let type = MailAPMEvent.FirstScreenLoaded.EndParam.mode_hot_start
                event.endParams.append(type)
            } else {
                let type = MailAPMEvent.FirstScreenLoaded.EndParam.mode_cold_start
                event.endParams.append(type)
            }
            event.endParams.append(MailAPMEventConstant.CommonParam.status_user_leave)
            let count = MailAPMEvent.ThreadListLoaded.EndParam.list_length(datasource.count)
            event.endParams.append(count)
            let from_db = listViewModel.lastSource
            let source = MailAPMEvent.ThreadListLoaded.EndParam.from_db(from_db ? 1 : 0)
            event.endParams.append(source)
            event.postEnd()
        }
    }

    // MARK: thread list apm
    func apmMarkThreadMarkAllReadStart() {
        let event = MailAPMEvent.ThreadMarkAllRead()
        event.markPostStart()
        apmHolder[MailAPMEvent.ThreadMarkAllRead.self] = event
    }

    func apmMarkThreadMarkAllReadEnd(status: MailAPMEventConstant.CommonParam, error: Error? = nil) {
        guard let event = apmHolder[MailAPMEvent.ThreadMarkAllRead.self] else {
            return
        }
        event.endParams.append(status)
        event.endParams.appendError(errorCode: error?.mailErrorCode, errorMessage: error?.getMessage())
        event.postEnd()
    }
}
