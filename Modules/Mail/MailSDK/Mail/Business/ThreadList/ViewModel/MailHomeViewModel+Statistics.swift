//
//  MailHomeViewModel+Statistics.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/3/23.
//

import Foundation

extension MailHomeViewModel: MailApmHolderAble {}

extension MailHomeViewModel {
    enum MailFirstScreenCostType {
        case createView
        case loadLabel
        case loadThread
    }
    // create view 阶段耗时
    func createViewCostTimeStart() {
        apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams
            .append(MailAPMEvent.FirstScreenLoaded.EndParam.create_view_cost_time(MailTracker.getCurrentTime()))
    }

    func createViewCostTimeEnd() {
        let startTime = getStartTime(MailAPMEvent.FirstScreenLoaded.EndParam.create_view_cost_time(0), type: .createView)
        guard startTime != -1 else {
            return
        }
        if let idx = getParamIndex(.createView) {
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.remove(at: idx)
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams
                .append(MailAPMEvent.FirstScreenLoaded.EndParam.create_view_cost_time(MailTracker.getCurrentTime() - startTime))
        }
    }

    // 加载label list数据阶段耗时
    func loadLabelListCostTimeStart() {
        apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams
            .appendOrUpdate(MailAPMEvent.FirstScreenLoaded.EndParam.load_label_list_cost_time(MailTracker.getCurrentTime()))
    }

    func loadLabelListCostTimeEnd() {
        let startTime = getStartTime(MailAPMEvent.FirstScreenLoaded.EndParam.load_label_list_cost_time(0), type: .loadLabel)
        guard startTime != -1 else {
            return
        }
        if let idx = getParamIndex(.loadLabel) {
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.remove(at: idx)
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams
                .appendOrUpdate(MailAPMEvent.FirstScreenLoaded.EndParam.load_label_list_cost_time(MailTracker.getCurrentTime() - startTime))
        }
    }

    // 加载thread list数据阶段耗时
    func loadThreadListCostTimeStart() {
        apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams
            .appendOrUpdate(MailAPMEvent.FirstScreenLoaded.EndParam.load_thread_list_cost_time(MailTracker.getCurrentTime()))
    }

    func loadThreadListCostTimeEnd() {
        let startTime = getStartTime(MailAPMEvent.FirstScreenLoaded.EndParam.load_thread_list_cost_time(0), type: .loadThread)
        guard startTime != -1 else {
            return
        }
        if let idx = getParamIndex(.loadThread) {
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.remove(at: idx)
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams
                .appendOrUpdate(MailAPMEvent.FirstScreenLoaded.EndParam.load_thread_list_cost_time(MailTracker.getCurrentTime() - startTime))
        }
    }

    private func getStartTime(_ paramType: MailAPMEventParamAble, type: MailFirstScreenCostType) -> Int {
        var startTime = -1
        for endParam in apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams ?? [] {
            if let param = endParam as? MailAPMEvent.FirstScreenLoaded.EndParam {
                switch param {
                case .create_view_cost_time(let time):
                    if paramType.key == param.key, type == .createView {
                        startTime = time
                    }
                case .load_label_list_cost_time(let time):
                    if paramType.key == param.key, type == .loadLabel {
                        startTime = time
                    }
                case .load_thread_list_cost_time(let time):
                    if paramType.key == param.key, type == .loadThread {
                        startTime = time
                    }
                default: break
                }
            }
        }
        return startTime
    }

    func getParamIndex(_ type: MailFirstScreenCostType) -> Int? {
        switch type {
        case .createView:
            for (index, endParam) in (apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams ?? []).enumerated() {
                guard let param = endParam as? MailAPMEvent.FirstScreenLoaded.EndParam else {
                    return nil
                }
                switch param {
                case .create_view_cost_time(_):
                    return index
                default: break
                }
            }
            return nil
        case .loadLabel:
            for (index, endParam) in (apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams ?? []).enumerated() {
                guard let param = endParam as? MailAPMEvent.FirstScreenLoaded.EndParam else {
                    return nil
                }
                switch param {
                case .load_label_list_cost_time(_):
                    return index
                default: break
                }
            }
            return nil
        case .loadThread:
            for (index, endParam) in (apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams ?? []).enumerated() {
                guard let param = endParam as? MailAPMEvent.FirstScreenLoaded.EndParam else {
                    return nil
                }
                switch param {
                case .load_thread_list_cost_time(_):
                    return index
                default: break
                }
            }
            return nil
        }
    }
}
