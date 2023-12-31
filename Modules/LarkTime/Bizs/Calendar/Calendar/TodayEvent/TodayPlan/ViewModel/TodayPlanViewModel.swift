//
//  TodayPlanViewModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/8.
//

import LarkContainer
import RxRelay
import RxSwift
import LarkTimeFormatUtils
import EENavigator
import CalendarFoundation

class TodayPlanViewModel {
    private let dataSource: TodayEventDataSourceInterface
    private let todayEventDependency: TodayEventDependency
    private let todayEventService: TodayEventService
    private let userResolver: UserResolver
    private let relay: BehaviorRelay<Void> = BehaviorRelay.init(value: ())
    var todayPlanObservable: Observable<Void> {
        return relay.asObservable()
    }
    var todayPlanModels: [TodayPlanModel] = []
    var state: TodayEventDataState = .loading
    private static let maxTodayPlan = 1000
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver,
         todayEventDependency: TodayEventDependency,
         todayEventService: TodayEventService,
         dataSource: TodayEventDataSourceInterface) {
        self.userResolver = userResolver
        self.dataSource = dataSource
        self.todayEventDependency = todayEventDependency
        self.todayEventService = todayEventService
        observeData()
    }

    private func observeData() {
        let is12HourStyle = self.todayEventService.is12HourStyle
        dataSource.todayPlanObservable
            .map { todayEventData -> [TodayPlanModel] in
                var models: [TodayPlanModel] = []
                var instances = todayEventData.instances
                let todayFeedEvents = todayEventData.todayFeedEvents
                instances.sort(by: { lhs, rhs in
                    // 全天日程优先在前
                    if TodayEventUtils.isAllday(instance: lhs) == TodayEventUtils.isAllday(instance: rhs) {
                        return TodayEventUtils.sortRules(lStartTime: lhs.startTime,
                                                         lServerID: todayFeedEvents[lhs.eventID]?.serverID ?? "",
                                                         lEventID: lhs.eventID,
                                                         rStartTime: rhs.startTime,
                                                         rServerID: todayFeedEvents[rhs.eventID]?.serverID ?? "",
                                                         rEventID: rhs.eventID)
                    } else {
                        // lhs与rhs不相同时，lhs为全天则rhs必定为非全天，所以直接判断lhs是否为全天即可
                        return TodayEventUtils.isAllday(instance: lhs)
                    }
                })
                for instance in instances {
                    guard let event = todayFeedEvents[instance.eventID] else { continue }
                    let model = createModel(instance: instance,
                                            event: event,
                                            preTime: models.last?.startTime.string)
                    models.append(model)
                }
                return models
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] models in
                guard let self = self else { return }
                self.todayPlanModels = Array(models.prefix(Self.maxTodayPlan))
                self.state = .done
                self.relay.accept(())
            }, onError: { error in
                TodayEvent.logError(error.localizedDescription)
            }).disposed(by: disposeBag)

        func createModel(instance: CalendarEventInstance,
                         event: TodayFeedViewEvent,
                         preTime: String?) -> TodayPlanModel {
            let options = Options(is12HourStyle: is12HourStyle, timePrecisionType: .minute)
            let startDate = Date(timeIntervalSince1970: TimeInterval(instance.startTime))
            let endDate =  Date(timeIntervalSince1970: TimeInterval(instance.endTime))
            let startTime: String
            var rangeTime = ""
            var location = ""
            if !TodayEventUtils.isAllday(instance: instance) {
                let calendar = Calendar(identifier: .gregorian)
                // 00:00在今日安排中不算跨天，所以需要减去1s防止被isDate方法判断为跨天
                let isOverOneDay = !calendar.isDate(startDate, inSameDayAs: endDate - 1)
                rangeTime = TodayEventUtils.timeDescription(isOverOneDay: isOverOneDay,
                                                            endDay: instance.endDay,
                                                            startDay: instance.startDay,
                                                            startDate: startDate,
                                                            endDate: endDate,
                                                            currentDate: Date(),
                                                            calendar: calendar,
                                                            with: options)
                startTime = TimeFormatUtils.formatTime(from: startDate.isInToday ? startDate : Calendar.gregorianCalendarWithCurrentTimeZone().startOfDay(for: Date()),
                                                       with: options)
            } else {
                startTime = BundleI18n.Calendar.Lark_Event_AllDayEvent_Label
            }
            event.meetingRooms.joined(separator: ";").forEach { room in
                location.append(room)
            }
            let summary = event.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : event.summary
            let baseModel = TodayEventBaseModel(summary: summary, rangeTime: rangeTime, location: location)
            let detailModel = TodayEventDetailModel(key: event.key,
                                                    calendarID: event.calendarID,
                                                    originalTime: event.originalTime,
                                                    startTime: instance.startTime)
            
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = 18
            return TodayPlanModel(baseModel: baseModel,
                                  detailModel: detailModel,
                                  startTime: NSAttributedString(string: startTime, attributes: [NSAttributedString.Key.paragraphStyle: style]),
                                  calendarType: event.source,
                                  needShowTime: preTime != startTime)
        }
    }

    func cellData(at row: Int) -> TodayPlanModel? {
        if row < todayPlanModels.count {
            return todayPlanModels[row]
        } else {
            return nil
        }
    }

    func jumpToDetail(at row: Int, from vc: UIViewController) {
        guard row < todayPlanModels.count else { return }
        todayEventService.jumpToDetailPage(detailModel: todayPlanModels[row].detailModel, from: vc)
    }
}
