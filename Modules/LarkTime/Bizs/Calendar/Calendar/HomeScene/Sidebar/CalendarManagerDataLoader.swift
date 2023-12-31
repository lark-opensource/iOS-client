//
//  CalendarManagerDataLoader.swift
//  Calendar
//
//  Created by 白言韬 on 2020/6/19.
//

import Foundation
import RxSwift
import CalendarFoundation
import LarkContainer
import LKCommonsLogging

// 从CalendarLoader拆分出(几乎复制)的日历管理页(侧边栏)相关业务逻辑
final class CalendarManagerDataLoader: UserResolverWrapper {

    var sideBarContent: [[SidebarCellContent]] = []

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    let logger = Logger.log(CalendarManagerDataLoader.self, category: "Calendar.CalendarManagerDataLoader")

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // MARK: - 侧边栏数据源，直接访问sdk
    func fetchSidebarCalendars(userId: String) -> Observable<[[SidebarCellContent]]> {
        let larkCalendars = categorysCalendars(userId: userId)
            .map({ categorysCalendars -> [[SidebarCellContent]] in
                var result = [[SidebarCellContent]]()
                result.append(categorysCalendars.mineCalendars)
                result.append(categorysCalendars.bookedCalendars)
                categorysCalendars.googleCalendars.forEach({ (calendars) in
                    result.append(calendars)
                })
                categorysCalendars.exchangeCalendars.forEach({ (calendars) in
                    result.append(calendars)
                })
                return result
            })

        let localCalendars = Array(LocalCalendarManager
            .getLocalCalendarGroupedVisibility().values
            .map { $0 })
            .map { $0.map { SidebarCellModel(model: $0) } }
            .sorted(by: { (l, r) -> Bool in // 按照source的名称排序
                if let lSourceTitle = l.first?.sourceTitle, let rSourceTitle = r.first?.sourceTitle {
                    return lSourceTitle < rSourceTitle
                }
                return l.isEmpty
            })
            .map { (calendars) -> [SidebarCellContent] in // 按是否可见 和 名称排序
                calendars.sorted(by: { (l, r) -> Bool in
                    if l.isChecked != r.isChecked {
                        return l.isChecked
                    }
                    return l.text < r.text
                })
            }

        let res = Observable.zip(larkCalendars, Observable.just((localCalendars))) { $0 + $1 }
            .do(onNext: {element in
                self.sideBarContent = element
            })
        return res

    }

    func categorysCalendars(userId: String) -> Observable<SideBarCalendars> {

        guard let dependency = self.calendarDependency,
              let calendarManager = self.calendarManager else {
            logger.error("categorysCalendars faild, can not get rust api from larkcontainer")
            return .empty()
        }
        let userTenantId = dependency.currentUser.tenantId
        let eventViewStartTime = calendarManager.eventViewStartTime
        let eventViewEndTime = calendarManager.eventViewEndTime

        return self.categorysCalendarsForCalendarManager(userId: userId).map({ (categorysCalendars) -> SideBarCalendars in
            let myCals = categorysCalendars.mineCalendars.map({ model in
                let isLoading = model.isLoading(eventViewStartTime: eventViewStartTime, eventViewEndTime: eventViewEndTime)
                return SidebarCellModel(calendarDependency: dependency, calendarModel: model, isLoading: isLoading, type: .larkMine, userTenantId: userTenantId)
            })
            let bookedCals = categorysCalendars.bookedCalendars.map({ model in
                let isLoading = model.isLoading(eventViewStartTime: eventViewStartTime, eventViewEndTime: eventViewEndTime)
                return SidebarCellModel(calendarDependency: dependency, calendarModel: model, isLoading: isLoading, type: .larkSubscribe, userTenantId: userTenantId)
            })

            let googleCalendars = categorysCalendars.googleCalendars.map({ (models) -> [SidebarCellContent] in
                return models.map({ model in
                    let isLoading = model.isLoading(eventViewStartTime: eventViewStartTime, eventViewEndTime: eventViewEndTime)
                    return SidebarCellModel(calendarDependency: dependency, calendarModel: model, isLoading: isLoading, type: .google, userTenantId: userTenantId)
                })
            })

            let exchangeCalendars = categorysCalendars.exchangeCalendars.map({ (models) -> [SidebarCellContent] in
                return models.map({ model in
                    let isLoading = model.isLoading(eventViewStartTime: eventViewStartTime, eventViewEndTime: eventViewEndTime)
                    return SidebarCellModel(calendarDependency: dependency, calendarModel: model, isLoading: isLoading, type: .exchange, userTenantId: userTenantId)
                })
            })

            return SideBarCalendars(mycals: myCals, bookedCals: bookedCals, googleCals: googleCalendars, exchangeCals: exchangeCalendars)
        })
    }

    fileprivate func categorysCalendarsForCalendarManager(userId: String) -> Observable<CalendarSidebarModel> {
        guard let rustApi = self.calendarApi else {
            logger.error("categorysCalendarsForCalendarManager faild, can not get rust api from larkcontainer")
            return .empty()
        }
        return rustApi.getUserCalendars().map({ (calendars) -> CalendarSidebarModel in
            let mergedCalendars = calendars.merge(userId: userId, isVisible: KVValues.getExternalCalendarVisible(accountName:))
            var categorysCalendars = mergedCalendars
                .filter { $0.hasSubscribed }
                .classifyCalendars()
            categorysCalendars.sortMineCals()
            categorysCalendars.sortBookedCals()
            categorysCalendars.sortGoogleCals()
            categorysCalendars.sortExchangeCals()
            return categorysCalendars
        }).subscribeOn(rustApi.requestScheduler)
    }
}

fileprivate extension Array where Element == CalendarModel {
    func classifyCalendars() -> CalendarSidebarModel {
        var googleCalendarsMap: [String: Int] = [:]
        var exchangeCalendarMap: [String: Int] = [:]

        let model = CalendarSidebarModel(mineCals: [], bookedCals: [], googleCals: [[CalendarModel]](), exchangeCals: [])
        return self.reduce(model, { (result, model)
            -> CalendarSidebarModel in
            var result = result
            if model.selfAccessRole == .owner {
                if model.type == .google {
                    let index = googleCalendarsMap[model.externalAccountName] ?? result.googleCalendars.count
                    googleCalendarsMap[model.externalAccountName] = index
                    var calendars: [CalendarModel]
                    if index < result.googleCalendars.count {
                        calendars = result.googleCalendars[index]
                        calendars.append(model)
                        result.googleCalendars[index] = calendars
                    } else {
                        calendars = [CalendarModel]()
                        calendars.append(model)
                        result.googleCalendars.append(calendars)
                    }
                } else if model.type == .exchange {
                    let index = exchangeCalendarMap[model.externalAccountName] ?? result.exchangeCalendars.count
                    exchangeCalendarMap[model.externalAccountName] = index
                    var calendars: [CalendarModel]
                    if index < result.exchangeCalendars.count {
                        calendars = result.exchangeCalendars[index]
                        calendars.append(model)
                        result.exchangeCalendars[index] = calendars
                    } else {
                        calendars = [CalendarModel]()
                        calendars.append(model)
                        result.exchangeCalendars.append(calendars)
                    }

                } else {
                    var calendars = result.mineCalendars
                    calendars.append(model)
                    result.mineCalendars = calendars
                }
            } else {
                var calendars = result.bookedCalendars
                calendars.append(model)
                result.bookedCalendars = calendars
            }
            return result
        })
    }

    /// 将google日历和lark日历合并，自己的google日历不合并
    func merge(userId: String, isVisible: ((String) -> Bool)?) -> [CalendarModel] {
        return self.reduce([], { (result, m) -> [CalendarModel] in
            var r = result
            // 过滤本地设置不显示的google日历
            if m.type == .google, !(isVisible?(m.externalAccountName) ?? false) {
                return r
            }

            if m.type == .exchange, !(isVisible?(m.externalAccountName) ?? false) {
                return r
            }

            // 有依附的三方日历, 不显示在侧边栏
            if m.type == .exchange || m.type == .google {
                if !m.isPrimary && !m.userId.isEmpty && !(m.selfAccessRole == .owner) {
                    return r
                }
            }

            r.append(m)
            return r
        })
    }
}

struct CalendarSidebarModel {
    var mineCalendars: [CalendarModel]
    var bookedCalendars: [CalendarModel]
    var googleCalendars: [[CalendarModel]]
    var exchangeCalendars: [[CalendarModel]]

    init(mineCals: [CalendarModel], bookedCals: [CalendarModel], googleCals: [[CalendarModel]], exchangeCals: [[CalendarModel]]) {
        self.mineCalendars = mineCals
        self.bookedCalendars = bookedCals
        self.googleCalendars = googleCals
        self.exchangeCalendars = exchangeCals
        self.sortMineCals()
    }

    // google日历排序
    mutating func sortGoogleCals() {
        googleCalendars = googleCalendars.map({ (nonSortedModels) -> [CalendarModel] in
            return nonSortedModels.sorted(by: { (l, r) -> Bool in
                // 可见状态相同时，按sdk给的weight排序
                if l.isVisible == r.isVisible {
                    return l.weight > r.weight
                }
                // 否则可见的排前面
                return l.isVisible
            })
        })

        let sorter: (([CalendarModel], [CalendarModel]) -> Bool) = { (l, r) -> Bool in
            return l.first?.weight ?? 0 > r.first?.weight ?? 0
        }
        googleCalendars = googleCalendars.sorted(by: sorter)
    }

    // exchange日历排序
    mutating func sortExchangeCals() {
        exchangeCalendars = exchangeCalendars.map({ (nonSortedModels) -> [CalendarModel] in
            return nonSortedModels.sorted(by: { (l, r) -> Bool in
                // 可见状态相同时，按sdk给的weight排序
                if l.isVisible == r.isVisible {
                    return l.weight > r.weight
                }
                // 否则可见的排前面
                return l.isVisible
            })
        })

        let sorter: (([CalendarModel], [CalendarModel]) -> Bool) = { (l, r) -> Bool in
            return l.first?.weight ?? 0 > r.first?.weight ?? 0
        }
        exchangeCalendars = exchangeCalendars.sorted(by: sorter)
    }

    mutating func sortBookedCals() {
        let sorter: ((CalendarModel, CalendarModel) -> Bool) = { (l, r) -> Bool in
            // 可见状态相同时，按sdk给的weight排序
            if l.isVisible == r.isVisible {
                return l.weight > r.weight
            }
            // 否则可见的排前面
            return l.isVisible
        }
        bookedCalendars = bookedCalendars.sorted(by: sorter)
    }

    /// 对拥有owner权限的日历进行排序
    /// - 具体规则详见 https://docs.bytedance.net/doc/doccn65dctlGJ2Aifv68Ic
    mutating func sortMineCals() {
        let sorter: ((CalendarModel, CalendarModel) -> Bool) = { (l, r) -> Bool in
            // 可见状态相同时，按sdk给的weight排序
            if l.isVisible == r.isVisible {
                return l.weight > r.weight
            }
            // 否则可见的排前面
            return l.isVisible
        }
        mineCalendars = mineCalendars.sorted(by: sorter)
        // lark主日历永远在第一位
        if let index = mineCalendars.firstIndex(where: { $0.isPrimary && !$0.isGoogleCalendar() }) {
            let primaryCalendar = mineCalendars.remove(at: index)
            mineCalendars.insert(primaryCalendar, at: 0)
        }
    }
}
