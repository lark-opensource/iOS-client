//
//  SchedulerChangeHostViewModel.swift
//  Calendar
//
//  Created by tuwenbo on 2023/4/3.
//

import Foundation
import RxSwift
import RxRelay
import LarkContainer
import LKCommonsLogging
import RustPB

enum SchedulerChangeHostViewData {
    case loading
    case error
    case data([SchedulerHostDataType])
    case finish(Error?)
}

final class SchedulerChangeHostViewModel: UserResolverWrapper {

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?

    let userResolver: UserResolver

    private let logger = Logger.log(SchedulerChangeHostViewModel.self, category: "CalendarScheduler")

    let rxViewData = BehaviorRelay<SchedulerChangeHostViewData>(value: .loading)

    private var hostStateList: [SchedulerHostState] = []
    private let params: SchedulerChangeHostParamType
    private let disposeBag = DisposeBag()

    init(params: SchedulerChangeHostParamType, userResolver: UserResolver) {
        self.params = params
        self.userResolver = userResolver
    }

    private func transformAvaiableTime(userAvailableTimes: [String: Server.SchedulerAvailableTimes]) {
        hostStateList = userAvailableTimes.map { (userID, times) in
            var isUserAvaiable = false
            let avaiableTimes = times.availableTimes.map { ($0.startTime, $0.endTime) }
            if avaiableTimes.contains(where: { $0 == (self.params.startTime, self.params.endTime) }) {
                isUserAvaiable = true
            }
            return SchedulerHostState(userID: userID, isAvaiable: isUserAvaiable, avaiableTimes: avaiableTimes)
        }
    }

    func loadAvaiableHost() {
        self.rxViewData.accept(.loading)
        guard let calendarApi = self.calendarApi else {
            logger.info("loadAvaiableHost failed, can not get rust api from larkcontainer")
            return
        }
        calendarApi.getSchedulerAvailableTime(schedulerID: self.params.schedulerID, startTime: self.params.startTime, endTime: self.params.endTime)
            .flatMap { [weak self] (resp: Server.GetSchedulerAvailableTimeResponse) -> Observable<[SchedulerHostData]> in
                guard let self = self else { return .empty() }
                self.transformAvaiableTime(userAvailableTimes: resp.userAvailableTimes)
                return self.getChatters(userIDs: Array(resp.userAvailableTimes.keys),
                                        userStateList: self.hostStateList).catchErrorJustReturn([])
            }.subscribeForUI(onNext: {[weak self] hosts in
                guard let self = self else { return }
                self.logger.info("loadAvaiableHost, count: \(hosts.count)")
                if hosts.isEmpty {
                    // 空列表默认为出错
                    self.rxViewData.accept(.error)
                } else {
                    let sortedHosts = self.sortHosts(hosts: hosts)
                    self.rxViewData.accept(.data(sortedHosts))
                }
            }, onError: {[weak self] err in
                guard let self = self else { return }
                self.logger.error("getSchedulerAvailableTime failed: \(err.localizedDescription)")
                self.rxViewData.accept(.error)
            }).disposed(by: disposeBag)
    }

    func getChatters(userIDs: [String], userStateList: [SchedulerHostState]) -> Observable<[SchedulerHostData]> {
        guard let calendarApi = self.calendarApi else {
            logger.info("getChatters failed, can not get rust api from larkcontainer")
            return .just([])
        }
        return calendarApi.getChatters(userIds: userIDs)
            .map {[weak self] chatterMap in
                guard let self = self else { return []}
                self.logger.info("getChatters count: \(chatterMap.count)")
                return userStateList.map { state in
                    if let chatter = chatterMap[state.userID] {
                        return SchedulerHostData(userID: state.userID,
                                                 userName: chatter.localizedName,
                                                 avatarKey: chatter.avatarKey,
                                                 indexKey: chatter.namePinyin,
                                                 isOwner: self.params.creatorID == state.userID,
                                                 isAvailable: state.isAvaiable)
                    } else { return nil}
                }.compactMap { $0 }
            }
    }

    func changeHost(newHosts: [String]) {
        guard let calendarApi = self.calendarApi else {
            logger.info("changeHost failed, can not get rust api from larkcontainer")
            return
        }
        calendarApi.recheduleAppointment(appointmentID: params.appointmentID,
                                         email: params.email,
                                         timeZone: params.timeZone,
                                         startTime: params.startTime,
                                         endTime: params.endTime,
                                         message: params.message,
                                         hostUserIDs: newHosts)
        .subscribeForUI(onNext: { [weak self] _ in
            self?.rxViewData.accept(.finish(nil))
        }, onError: { [weak self] err in
            self?.logger.error("recheduleAppointment failed: \(err.localizedDescription)")
            self?.rxViewData.accept(.finish(err))
        }).disposed(by: disposeBag)
    }

    private func sortHosts(hosts: [SchedulerHostData]) -> [SchedulerHostDataType] {
        let groups = Dictionary(grouping: hosts, by: { $0.isAvailable })
        let avaiables = groups[true] ?? []
        let unavaiables = groups[false] ?? []
        return avaiables.sorted { $0.indexKey < $1.indexKey } + unavaiables.sorted { $0.indexKey < $1.indexKey }
    }

    struct SchedulerHostState {
        let userID: String
        let isAvaiable: Bool
        let avaiableTimes: [(Int64, Int64)]
    }

    struct SchedulerHostData: SchedulerHostDataType {
        var userID: String
        var userName: String
        var avatarKey: String
        var indexKey: String
        var isOwner: Bool
        var isAvailable: Bool
    }
}
