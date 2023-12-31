//
//  EventFeedCardViewModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/8.
//

import LarkContainer
import RxRelay
import RxSwift
import LarkTimeFormatUtils
import CalendarFoundation
import LKLoadable

enum EventFeedCardDataType {
    /// 日程的card数据
    case schedule(ScheduleCardViewModel)

    /// 从subModule中取得的card数据
    case external(EventFeedCardViewMananger)

    /// 空cell，制造card间距
    case separation

    var sortTime: Int64 {
        switch self {
        case .schedule(let viewModel):
            return viewModel.model.sortTime
        case .external(let model):
            return model.cardView.model.sortTime
        case .separation:
            return 0
        }
    }

    static func == (lhs: EventFeedCardDataType, rhs: EventFeedCardDataType) -> Bool {
        switch (lhs, rhs) {
        case (.separation, .separation):
            return true
        case (.external(_), .external(_)):
            return true
        case (.schedule(_), .schedule(_)):
            return true
        default:
            return false
        }
    }
}

class EventFeedCardViewModel {
    private let dataSource: TodayEventDataSourceInterface
    private let cardModule: EventFeedCardModule
    private let relay: BehaviorRelay<Void> = BehaviorRelay.init(value: ())
    private let calendarApi: CalendarRustAPI
    private let todayEventDependency: TodayEventDependency
    private let todayEventService: TodayEventService
    private let userResolver: UserResolver
    weak var viewController: UIViewController?

    // 埋点数据
    private let feedTab: String
    private let feedIsTop: Bool

    // 临时存储card数据
    var scheduleCardModels: [ScheduleCardViewModel] = []
    var eventFeedCards: [EventFeedCardType: [EventFeedCardView]] = [:]

    //计时器，每一秒刷新一次倒计时
    private let timer = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
    var scheduleCardObservable: Observable<Void> {
        return relay.asObservable()
    }
    let disposeBag = DisposeBag()
    var cellModels: [EventFeedCardDataType] = []
    var state: TodayEventDataState = .loading
    private static let maxScheduleCard = 20 // 展示的日程卡片最大数量

    init(dataSource: TodayEventDataSourceInterface,
         todayEventDependency: TodayEventDependency,
         todayEventService: TodayEventService,
         calendarApi: CalendarRustAPI,
         userResolver: UserResolver,
         feedTab: String,
         feedIsTop: Bool) {
        // 注入外部card
        SwiftLoadable.startOnlyOnce(key: "TodayEvent.ByteView.EventCard")
        self.dataSource = dataSource
        self.calendarApi = calendarApi
        self.todayEventDependency = todayEventDependency
        self.todayEventService = todayEventService
        self.userResolver = userResolver
        self.feedTab = feedTab
        self.feedIsTop = feedIsTop
        self.cardModule = EventFeedCardModule(userResolver: userResolver,
                                              trace: EventFeedCardTrace(feedIsTop: feedIsTop, feedTab: feedTab))
        observeData()
        createTimer()
    }

    private func observeData() {
        observeExternalEventCardData()
        observeScheduleCardData()
    }

    // 监听subModules中views数据的变化
    private func observeExternalEventCardData() {
        Observable.merge(cardModule.subModules.values.map { $0.updateObservable })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] cardType in
                guard let self = self else { return }
                if let views = self.cardModule.subModules[cardType]?.cards {
                    self.eventFeedCards[cardType] = views
                    TodayEvent.logInfo("getEventCardSubModules CardType: \(cardType), count: \(views.count)")
                } else {
                    TodayEvent.logWarning("type: \(cardType) has not registered")
                }
                self.createCellModel()
            }, onError: { error in
                TodayEvent.logError(error.localizedDescription)
            }).disposed(by: disposeBag)
    }

    // 监听日程数据的变化
    private func observeScheduleCardData() {
        let options = Options(is12HourStyle: todayEventService.is12HourStyle,
                              timeFormatType: .short,
                              timePrecisionType: .minute,
                              dateStatusType: .relative)
        dataSource.scheduleCardObservable
            .map { todayEventData -> [ScheduleCardViewModel] in
                let instances = todayEventData.instances
                let todayFeedEvents = todayEventData.todayFeedEvents
                var cardModels: [ScheduleCardViewModel] = []
                for instance in instances {
                    guard let event = todayFeedEvents[instance.eventID] else { continue }
                    cardModels.append(createScheduleCardModel(instance: instance,
                                                              event: event,
                                                              options: options))
                }
                cardModels.sort(by: { lhs, rhs in
                    return TodayEventUtils.sortRules(lStartTime: lhs.model.sortTime,
                                                     lServerID: lhs.model.serverID,
                                                     lEventID: lhs.model.eventID,
                                                     rStartTime: rhs.model.sortTime,
                                                     rServerID: rhs.model.serverID,
                                                     rEventID: rhs.model.eventID)
                })
                return cardModels
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] cardModels in
                guard let self = self else { return }
                self.scheduleCardModels = Array(cardModels.prefix(Self.maxScheduleCard))
                self.createCellModel()
            }, onError: { error in
                TodayEvent.logError(error.localizedDescription)
            }).disposed(by: disposeBag)

        func createScheduleCardModel(instance: CalendarEventInstance,
                                     event: TodayFeedViewEvent,
                                     options: Options) -> ScheduleCardViewModel {
            let rangeTime = TimeFormatUtils.formatDateTimeRange(startFrom: Date(timeIntervalSince1970: TimeInterval(instance.startTime)),
                                                                endAt: Date(timeIntervalSince1970: TimeInterval(instance.endTime)),
                                                                with: options)
            var location = ""
            if event.meetingRooms.isEmpty {
                location = event.location.location
            } else {
                event.meetingRooms.joined(separator: ";").forEach { room in
                    location.append(room)
                }
            }
            let baseModel = TodayEventBaseModel(summary: event.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : event.summary,
                                                rangeTime: rangeTime,
                                                location: location)
            let detailMode = TodayEventDetailModel(key: event.key,
                                                   calendarID: event.calendarID,
                                                   originalTime: event.originalTime,
                                                   startTime: instance.startTime)
            let model = ScheduleCardModel(baseModel: baseModel,
                                          detailModel: detailMode,
                                          sortTime: instance.startTime,
                                          cardID: event.serverID,
                                          remainingTime: instance.startTime - Int64(Date().timeIntervalSince1970),
                                          duration: instance.endTime - instance.startTime,
                                          tag: event.relationTag.tagDataItems.isEmpty ? nil: event.relationTag.tagDataItems[0].textVal,
                                          serverID: event.serverID,
                                          eventID: instance.eventID,
                                          startTime: instance.startTime,
                                          btnID: event.isVideoMeetingBtnShow ? event.videoMeeting.uniqueID: nil,
                                          btnModel: createVCBtn(instance: instance, event: event))
            let scheduleCardViewModel = ScheduleCardViewModel(model: model,
                                                              todayEventDependency: todayEventDependency)
            return scheduleCardViewModel
        }
    }

    private func createVCBtn(instance: CalendarEventInstance,
                             event: TodayFeedViewEvent) -> ScheduleCardBtnType {
        if event.videoMeeting.videoMeetingType == .vchat {
            let model = ScheduleCardButtonModel(uniqueId: event.videoMeeting.uniqueID,
                                                key: event.key,
                                                originalTime: instance.originalTime,
                                                startTime: instance.startTime,
                                                endTime: instance.endTime,
                                                displayTitle: event.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : event.summary,
                                                isFromPeople: event.source == .people,
                                                isWebinar: event.category == .webinar,
                                                isWebinarOrganizer: event.organizerCalendarID == event.calendarID,
                                                isWebinarSpeaker: event.selfWebinarAttendeeType == .speaker,
                                                isWebinarAudience: event.selfWebinarAttendeeType == .audience,
                                                videoMeetingType: event.videoMeeting.videoMeetingType,
                                                url: event.videoMeeting.meetingURL,
                                                isExpired: event.videoMeeting.isExpired,
                                                isTop: feedIsTop,
                                                feedTab: feedTab)
            return .vcBtn(model)
        } else {
            let otherMeetingBtnModel = OtherMeetingBtnModel(videoMeeting: event.videoMeeting,
                                                            location: event.location.location,
                                                            description: event.description_p,
                                                            source: event.source)
            let otherMeetingBtnManager = OtherVideoMeetingBtnManager(calendarApi: self.calendarApi,
                                                                     userResolver: userResolver,
                                                                     vc: self.viewController,
                                                                     model: otherMeetingBtnModel,
                                                                     feedTab: self.feedTab,
                                                                     feedIsTop: self.feedIsTop)
            otherMeetingBtnManager.rxShowOtherVCBtn
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.relay.accept(())
                }).disposed(by: disposeBag)
            return .otherBtn(otherMeetingBtnManager)
        }
    }

    private func createCellModel() {
        // 对日程card和subModule中的所有view综合排序
        let views = eventFeedCards.values.flatMap { $0 }
        var models: [EventFeedCardDataType] = views.map({ .external(EventFeedCardViewMananger(cardView: $0)) })
        models += self.scheduleCardModels.map({ .schedule($0) })
        models.sort(by: { $0.sortTime < $1.sortTime })
        // 向数据源中插入空白cell，制造间距
        var newCellModels: [EventFeedCardDataType] = []
        for model in models {
            newCellModels.append(.separation)
            newCellModels.append(model)
        }
        self.cellModels = newCellModels
        self.state = .done
        self.relay.accept(())
    }

    func cellData(at row: Int) -> EventFeedCardDataType? {
        if row < cellModels.count {
            return cellModels[row]
        } else {
            return nil
        }
    }

    func deleteCell(at row: Int) {
        if row < cellModels.count {
            let cell = cellModels[row]
            switch cell {
            case .external(let cellModel):
                TodayEvent.logInfo("removeCard index: \(row), " +
                                   "cardID: \(cellModel.cardView.model.cardID), " +
                                   "cardType: \(cellModel.cardView.model.cardType)")
                cardModule.subModules[cellModel.cardView.model.cardType]?.removeCard(cardID: cellModel.cardView.model.cardID)
            case .schedule(let viewModel):
                TodayEvent.logInfo("removeCard index: \(row), " +
                                   "key: \(viewModel.model.detailModel.key), " +
                                   "calendarID: \(viewModel.model.detailModel.calendarID), " +
                                   "originalTime: \(viewModel.model.detailModel.originalTime), " +
                                   "cardType: event")
                calendarApi.saveCalendarApplicationCloseInstanceRequest(key: viewModel.model.detailModel.key,
                                                                        calendarID: viewModel.model.detailModel.calendarID,
                                                                        originalTime: viewModel.model.detailModel.originalTime,
                                                                        startTime: viewModel.model.startTime)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    if let btnID = viewModel.model.btnID {
                        self.todayEventDependency.removeVCBtn(uniqueId: btnID)
                    }
                    if row < self.cellModels.count {
                        self.cellModels.remove(at: row)
                    }
                    // 一并移除掉前面的空白cell
                    if row - 1 >= 0 && row - 1 < self.cellModels.count {
                        if self.cellModels[row - 1] == .separation {
                            self.cellModels.remove(at: row - 1)
                        }
                    }
                    self.relay.accept(())
                }).disposed(by: disposeBag)
            case .separation:
                break
            }
        }
    }

    private func createTimer() {
        timer.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.cellModels.forEach { model in
                switch model {
                case .schedule(let scheduleCardViewModel):
                    guard scheduleCardViewModel.model.remainingTime > 0 else { return }
                    scheduleCardViewModel.model.remainingTime -= 1
                    if scheduleCardViewModel.model.remainingTime % 60 == 0 {
                        self.relay.accept(())
                    }
                default:
                    break
                }
            }
        }).disposed(by: disposeBag)
    }

    func jumpToDetail(at row: Int, from vc: UIViewController) {
        guard row < cellModels.count else { return }
        let model = cellModels[row]
        switch model {
        case .schedule(let viewModel):
            TodayEvent.logInfo("jumpToDetail calendarID: \(viewModel.model.detailModel.calendarID)")
            todayEventService.jumpToDetailPage(detailModel: viewModel.model.detailModel, from: vc)
        default:
            break
        }
    }

    deinit {
        todayEventDependency.removeAllVCBtn()
    }
}
