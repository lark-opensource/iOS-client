//
//  EventEditViewModel+Calendar.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation
import RxSwift
import RxCocoa
import CalendarFoundation

// MARK: Setup Calendar

extension EventEditViewModel {

    var calendarModel: EventEditModelManager<(pre: EventEditCalendar?, current: EventEditCalendar?)>? {
        self.models[EventEditModelType.calendar] as? EventEditModelManager<(pre: EventEditCalendar?, current: EventEditCalendar?)>
    }
    
    // 本地日历
    private static let localCalendar = EventEditCalendar.localCalendar(name: "local calendar")

    private func prepareCreatableCalendars() -> Observable<[CalendarModel]> {
        // 每次拉最新日历数据，因为日历有可能变更/删除
        calendarManager?.updateAllCalendar()
        return calendarApi?.getUserCalendars()
            .retry(3)
            .map { $0.allCreatableCalendars() } ?? .empty()
    }

    private func setupCalendar(withCreatableCalendars creatableCalendars: [CalendarModel], init_completed: @escaping (EventEditCalendar) -> Void) {
        switch input {
        case .editFromLocal:
            availableCalendars = [Self.localCalendar]
            init_completed(Self.localCalendar)
        case .editFrom(let pbEvent, _), .editWebinar(let pbEvent, _):
            let calendars = creatableCalendars
                .filter { $0.serverId == pbEvent.calendarID }
                .map { $0.toEventEditCalendar() }
            guard let curCalendar = calendars.first(where: { $0.id == pbEvent.calendarID }) else {
                assertLog(false, "curCalendar should not be empty")
                availableCalendars = []
                break
            }
            if curCalendar.source == .lark,
               pbEvent.calendarID == pbEvent.organizerCalendarID {
                availableCalendars = creatableCalendars
                    .filter { $0.isOwnerOrWriter() && ($0.type == .other || $0.type == .primary) }
                    .map { $0.toEventEditCalendar() }
            } else {
                availableCalendars = [curCalendar]
            }
            init_completed(curCalendar)
        case .createWithContext, .createWebinar:
            if input.isWebinarScene {
                // webinar 去掉三方日历
                self.availableCalendars = creatableCalendars.filter {
                    $0.isOwnerOrWriter() && !$0.isGoogleCalendar() && !$0.isExchangeCalendar()
                }.map({ $0.toEventEditCalendar() })
            } else {
                self.availableCalendars = creatableCalendars
                    .filter {
                       $0.isOwnerOrWriter()
                    }
                    .map { $0.toEventEditCalendar() }
            }

            if case .createWithContext(let createContext) = input {
                // 如果外部传入默认calendar
                if let calendarID = createContext.calendarID, !calendarID.isEmpty {
                    if let calendar = creatableCalendars
                        .first(where: { $0.serverId == calendarID })
                        .map({ $0.toEventEditCalendar() }) {
                        init_completed(calendar)
                        break
                    } else {
                        EventEdit.logger.error("choose default Calendar failed:\(calendarID)")
                        assertLog(false, "choose default Calendar failed:\(calendarID)")
                    }
                }

                if let chatId = createContext.chatIdForSharing, !chatId.isEmpty {
                    // 会话场景，总是优先选择主日历
                    let primaryCalendar = creatableCalendars
                        .first(where: { $0.isLarkPrimaryCalendar() })
                        .map({ $0.toEventEditCalendar() })
                    if let calendar = primaryCalendar {
                        init_completed(calendar)
                        break
                    } else {
                        assertLog(false, "LarkPrimaryCalendar not found")
                    }
                }
            }

            let availableCalModels = self.availableCalendars.map({ CalendarModelFromPb(pb: $0.getPBModel()) })
            if !availableCalModels.contains(where: \.isVisible) // 无勾选日历 默认取主日历
                || availableCalModels.contains(where: { $0.isVisible && $0.isLarkPrimaryCalendar() }) // 主日历已勾选 取主日历
                || !availableCalModels.contains(where: { $0.isVisible && $0.isOwnerOrWriter() }) { // 没有已勾选的有编辑权限的日历 取主日历
                if let calendar = availableCalModels
                    .first(where: { $0.isLarkPrimaryCalendar() })
                    .map({ $0.toEventEditCalendar() }) {
                    init_completed(calendar)
                } else {
                    // 无主日历情况 报错
                    assertLog(false, "LarkPrimaryCalendar not found")
                    availableCalendars = []
                    break
                }
            } else {
                // 已勾选日历中无主日历情况
                let ownCalenders = availableCalModels.filter { $0.isVisible && $0.selfAccessRole == .owner }.sorted { $0.weight > $1.weight }
                let writableCalendars = availableCalModels.filter { $0.isVisible && $0.selfAccessRole == .writer }.sorted { $0.weight > $1.weight }
                if let calendar = ownCalenders.first(where: { $0.type != .google && $0.type != .exchange })
                    ?? writableCalendars.first(where: { $0.type != .google && $0.type != .exchange })
                    ?? ownCalenders.first
                    ?? writableCalendars.first {
                    // 按照 管理日历（内部）> 管理日历 > 可编辑日历（内部）> 可编辑日历 的顺序选择默认日历
                    init_completed(calendar.toEventEditCalendar())
                } else {
                    assertLog(false, "Invalid Status")
                    availableCalendars = []
                    break
                }
            }
        case .copyWithEvent(let event, _):
            self.availableCalendars = creatableCalendars
                .filter { $0.isOwnerOrWriter() }
                .map({ $0.toEventEditCalendar() })
            if let calendar = self.availableCalendars.first(where: { $0.id == event.calendarID }) {
                // 对原日程所属日历有编辑权限
                init_completed(calendar)
            } else {
                // 对原日程所属日历没有编辑权限
                var calendar: EventEditCalendar?
                switch event.source {
                // 特殊三方日程复制情况【主日历上的三方日历日程】原日程所在三方日历（如果用户有编辑权限）> 用户有编辑权限的对应三方日历（exchange - exchange、google - google）> 用户主日历
                case .exchange:
                    calendar = self.availableCalendars.first(where: { $0.source == .exchange })
                case .google:
                    calendar = self.availableCalendars.first(where: { $0.source == .google })
                @unknown default:
                    break
                }
                if let calendar = calendar {
                    init_completed(calendar)
                } else {
                    // 选取 Lark主日历 进行兜底
                    if let larkPrimaryCalendar = creatableCalendars
                        .first(where: { $0.isLarkPrimaryCalendar() })
                        .map({ $0.toEventEditCalendar() }) {
                        init_completed(larkPrimaryCalendar)
                    } else {
                        // 无主日历情况 报错
                        assertLog(false, "LarkPrimaryCalendar not found")
                        availableCalendars = []
                        break
                    }
                }
            }
        }
    }

    // setup calendar:
    //   - init `availableCalendars`
    //   - set calendar for eventModel
    func makeCalendarModel() -> EventEditModelManager<(pre: EventEditCalendar?, current: EventEditCalendar?)> {
        let rxModel = BehaviorRelay<(pre: EventEditCalendar?, current: EventEditCalendar?)>(value: (nil, nil))
        let calendar_model = EventEditModelManager(userResolver: self.userResolver,
                                                   identifier: EventEditModelType.calendar.rawValue,
                                                   rxModel: rxModel)
        calendar_model.initMethod = { [weak self, weak calendar_model] observer in
            guard let self = self, let calendar_model = calendar_model else { return }
            self.prepareCreatableCalendars().subscribe(
                onNext: { [weak self, weak calendar_model] calendars in
                    self?.setupCalendar(withCreatableCalendars: calendars) { calendar in
                        calendar_model?.rxModel?.accept((nil, calendar))
                        observer.onCompleted()
                    }
                },
                onError: { [weak self, weak calendar_model] error in
                    // 获取日历失败
                    self?.rxHasGetCalendar.accept(true)
                    calendar_model?.rxModel?.accept((nil, nil))
                    observer.onCompleted()
                    EventEdit.logger.error("prepare calendar failed: \(error)")
                    assertionFailure()
                }
            ).disposed(by: self.disposeBag)
        }
        return calendar_model
    }

}
