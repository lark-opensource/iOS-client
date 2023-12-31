//
//  CalendarDetailViewModel.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/28.
//

import Foundation
import RxSwift
import RxRelay
import LarkContainer
import CalendarFoundation
final class LegacyCalendarDetailViewModel: UserResolverWrapper {
    struct DetailViewData: CalendarDetailViewDataType {
        var title: String
        var creatorName: String
        var description: String
        var isSubscribed: Bool
    }

    enum Input {
        case calendarID(String)
        case token(String)
    }

    enum ToastType {
        case success(String)
        case error(String)
        case loading
        case none
    }

    enum Status {
        case showLoading
        case showRetry
        case showDetail
        case showNoAccess(tip: String)
    }

    let userResolver: UserResolver
    @ScopedInjectedLazy var api: CalendarRustAPI?
    private let bag = DisposeBag()

    var isSubscribed: Bool {
        return calendarWithMember?.calendar.isSubscriber ?? false
    }

    let rxStatus = BehaviorRelay<Status>(value: .showLoading)
    let rxToast = BehaviorRelay<ToastType>(value: .none)
    let rxDetailViewData = PublishRelay<CalendarDetailViewDataType>()
    var calendarID: String?

    private var calendarWithMember: CalendarWithMember?

    private let param: Input
    init(param: Input, userResolver: UserResolver) {
        self.param = param
        self.userResolver = userResolver
    }

    func loadData() {
        rxStatus.accept(.showLoading)

        guard let api = self.api else {
            return
        }

        func fetchCalendar(with id: String) {
            api.fetchCalendar(calendarID: id)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (calendarWithMember) in
                    guard let self = self, let calendarWithMember = calendarWithMember else {
                        self?.rxStatus.accept(.showRetry)
                        return
                    }
                    self.calendarWithMember = calendarWithMember
                    let calendar = calendarWithMember.calendar
                    let isPrimary: Bool
                    if calendar.isPublic || (calendar.selfAccessRole == .owner || calendar.selfAccessRole == .writer || calendar.selfAccessRole == .reader) {
                        self.rxStatus.accept(.showDetail)
                        let data = DetailViewData(title: calendar.summary,
                                                  creatorName: "",
                                                  description: calendar.description_p,
                                                  isSubscribed: calendar.isSubscriber)

                        isPrimary = false
                        self.rxDetailViewData.accept(data)
                    } else {
                        isPrimary = true
                        self.rxStatus.accept(.showNoAccess(tip: I18n.Calendar_SubscribeCalendar_PrivateCalendarCannotBeSubscribed))
                    }
                    CalendarTracer.shared.calDetailView(isSubscribed: calendar.isSubscriber,
                                                        isPrivate: isPrimary,
                                                        calendarID: calendar.serverID)

                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    if err.errorType() == .calendarTypeNotSupportErr {
                        self.rxStatus.accept(.showNoAccess(tip: I18n.Calendar_Onboarding_TypeCalendarDetailsNotSupported))
                    } else if err.errorType() == .calendarIsPrivateErr {
                        self.rxStatus.accept(.showNoAccess(tip: I18n.Calendar_SubscribeCalendar_PrivateCalendarCannotBeSubscribed))
                    } else if err.errorType() == .calendarIsDeletedErr {
                        self.rxStatus.accept(.showNoAccess(tip: I18n.Calendar_Common_CalendarDeleted))
                    } else {
                        self.rxStatus.accept(.showRetry)
                    }
                }).disposed(by: bag)
        }

        switch param {
        case .calendarID(let id):
            fetchCalendar(with: id)
            calendarID = id
        case .token(let token):
            api.getCalendarIDByShareToken(token: token)
                .subscribe(onNext: { [weak self] (id) in
                    fetchCalendar(with: id)
                    self?.calendarID = id
                }).disposed(by: bag)
        }

    }

    func doSubscribe() {
        guard let calendarID = calendarID else { return }
        rxToast.accept(.loading)

        api?.subscribeCalendar(with: calendarID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_: Bool) in
                guard let self = self else { return }
                if let calendarWithMember = self.calendarWithMember {
                    let data = DetailViewData(title: calendarWithMember.calendar.summary,
                                              creatorName: "",
                                              description: calendarWithMember.calendar.description_p,
                                              isSubscribed: true)
                    var calendar = calendarWithMember.calendar
                    calendar.isSubscriber = true
                    self.calendarWithMember?.calendar = calendar

                    self.rxDetailViewData.accept(data)
                    self.rxToast.accept(.success(I18n.Calendar_Calendar_SubscribedToast))
                }
            }) { [weak self] error in
                switch error.errorType() {
                case .exceedMaxVisibleCalNum:
                    self?.rxToast.accept(.error(I18n.Calendar_Detail_TooMuchViewReduce))
                default:
                    self?.rxToast.accept(.error(I18n.Calendar_SubscribeCalendar_OperationFailed))
                }
            }.disposed(by: bag)
    }

}
