//
//  CalendarDetailCardViewModel.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/17/23.
//

import Foundation
import LarkContainer
import RxSwift
import RxRelay
import UniverseDesignEmpty
import LarkBizAvatar
import EENavigator
import LarkTab

enum CalendarDetailCardViewStatus {
    case loading
    case dataLoaded
    case error(_ error: CalendarError)

    enum CalendarError: Error {
        case fetchError
        case apiError(_ info: ErrorInfo)
    }

    struct ErrorInfo {
        let definedType: UDEmptyType
        let tip: String
    }
}

class CalendarDetailCardViewModel: UserResolverWrapper {

    let rxViewStatus: BehaviorRelay<CalendarDetailCardViewStatus> = .init(value: .loading)
    let rxToastStatus = PublishRelay<ToastStatus>()

    static let defaultAvatar = (avatar: UIImage.cd.image(named: "calendar_default_avatar"), key: "default")

    private(set) var rxHeaderData: BehaviorRelay<CalendarDetailHeaderData?> = .init(value: nil)
    private(set) var rxContentData: BehaviorRelay<CalendarDetailContentData?> = .init(value: nil)

    private var rxCalendarWithMember: BehaviorRelay<CalendarWithMember?> = .init(value: nil)

    @ScopedInjectedLazy var rustAPI: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedProvider var calendarHome: CalendarHome?

    let userResolver: UserResolver

    private(set) var calID: String?
    private(set) var calToken: String?

    private let disposeBag = DisposeBag()

    init(with calID: String, userResolver: UserResolver) {
        self.calID = calID
        self.userResolver = userResolver
        fetchDataWithCalID()
        bindData()
    }

    init(withToken token: String, userResolver: UserResolver) {
        self.calToken = token
        self.userResolver = userResolver
        fetchDataWithToken()
    }

    func reload() {
        if !calID.isEmpty {
            fetchDataWithCalID()
        } else if !calToken.isEmpty {
            fetchDataWithToken()
        } else {
            rxViewStatus.accept(.error(.fetchError))
        }
    }

    private func fetchDataWithToken() {
        guard let token = calToken else { return }
        rxViewStatus.accept(.loading)
        rustAPI?.getCalendarIDByShareToken(token: token)
            .subscribeForUI { [weak self] calID in
                self?.calID = calID
                self?.fetchDataWithCalID()
                self?.bindData()
            } onError: { [weak self] error in
                self?.rxViewStatus.accept(.error(.fetchError))
                CalendarBiz.detailLogger.info("GET calendarID with token failed \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)
    }

    private func fetchDataWithCalID() {
        guard let calID = calID else { return }
        rxViewStatus.accept(.loading)
        rustAPI?.fetchCalendar(calendarID: calID)
            .subscribeForUI { calendarWithMember in
                guard let calendarWithMember = calendarWithMember else { return }
                self.rxViewStatus.accept(.dataLoaded)
                self.rxCalendarWithMember.accept(calendarWithMember)
            } onError: { error in
                if error.errorType() == .calendarTypeNotSupportErr {
                    self.rxViewStatus.accept(.error(.apiError(.init(definedType: .noSchedule, tip: I18n.Calendar_Onboarding_TypeCalendarDetailsNotSupported))))
                } else if error.errorType() == .calendarIsPrivateErr {
                    self.rxViewStatus.accept(.error(.apiError(.init(definedType: .noPreview, tip: I18n.Calendar_SubscribeCalendar_PrivateCalendarCannotBeSubscribed))))
                } else if error.errorType() == .calendarIsDeletedErr {
                    self.rxViewStatus.accept(.error(.apiError(.init(definedType: .noSchedule, tip: I18n.Calendar_Common_CalendarDeleted))))
                } else {
                    self.rxViewStatus.accept(.error(.fetchError))
                }
            }.disposed(by: disposeBag)
    }

    func jumpToSlideView(from: UIViewController) {
        guard let calendarID = calID,
              let calendarHome = self.calendarHome else { return }
        from.dismiss(animated: true, completion: { [weak self] in
            self?.userResolver.navigator.switchTab(Tab.calendar.url, from: calendarHome, animated: true) { _ in
                calendarHome.jumpToSlideView(calendarID: calendarID, source: nil)
            }
        })
    }

    func doSubscribe() {
        guard let calID = calID else { return }
        rxToastStatus.accept(.loading(info: I18n.Calendar_Bot_Processing, disableUserInteraction: true))
        rustAPI?.subscribeCalendar(with: calID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, var contentData = self.rxContentData.value else { return }
                self.rxToastStatus.accept(.remove)
                self.rxToastStatus.accept(.success(I18n.Calendar_Bot_Subscribed))

                contentData.hasSubscribed = true
                self.calendarManager?.updateRustCalendar()
                self.rxContentData.accept(contentData)
            }) { [weak self] error in
                self?.rxToastStatus.accept(.remove)
                switch error.errorType() {
                case .subscribeCalendarExceedTheUpperLimitErr:
                    self?.rxToastStatus.accept(.failure(I18n.Calendar_SubscribeCalendar_NumLimit))
                case .calendarIsNotPublicErr:
                    self?.rxToastStatus.accept(.failure(I18n.Calendar_SubscribeCalendar_PrivateCalendarCannotBeSubscribed))
                case .exceedMaxVisibleCalNum:
                    self?.rxToastStatus.accept(.failure(I18n.Calendar_SelectCalendar_ViewMax25CalendarsAtTheSameTime))
                default:
                    self?.rxToastStatus.accept(.failure(I18n.Calendar_Toast_SubscriptionFailedMessage))
                }
            }.disposed(by: disposeBag)
    }

    private func bindData() {
        rxCalendarWithMember
            .compactMap { $0 }
            .flatMap { [weak self] calendarWithMember -> Single<CalendarDetailHeaderData?> in
                guard let self = self else { return .just(nil) }
                if let primaryAvatar = calendarWithMember.primaryAvatar {
                    let avatar: CalendarAvatar = .primary(avatarKey: primaryAvatar.key, identifier: primaryAvatar.idendifier)
                    return .just(.init(title: calendarWithMember.calendar.summary, avatarInfo: avatar))
                } else {
                    let imageKey = calendarWithMember.calendar.avatarKey

                    guard !imageKey.isEmpty, let rustAPI = self.rustAPI else {
                        return .just(.init(title: calendarWithMember.calendar.summary, avatarInfo: .normal(avatar: nil)))
                    }

                    return rustAPI
                        .downLoadImage(with: imageKey)
                        .retry(3)
                        .catchErrorJustReturn(nil)
                        .map { path -> CalendarDetailHeaderData? in
                            guard let path = path?.asAbsPath(), let image = try? UIImage.read(from: path) else {
                                CalendarBiz.detailLogger.error("Haven't found any image from the path.")
                                return nil
                            }
                            return .init(title: calendarWithMember.calendar.summary, avatarInfo: .normal(avatar: image, key: imageKey))
                        }.asSingle()
                }
            }
            .compactMap { $0 }
            .bind(to: rxHeaderData)
            .disposed(by: disposeBag)

        rxCalendarWithMember
            .compactMap { calendarWithMember -> CalendarDetailContentData? in
                guard let calendar = calendarWithMember?.calendar,
                      let members = calendarWithMember?.members else { return nil }
                let ownerName = members.first { $0.memberID == calendar.calendarOwnerID }?.displayName ?? ""
                let subscriberNum = Int(calendar.shareInfo.subscriberNum)
                let descriptionStr = calendar.description_p.isEmpty ? I18n.Calendar_Detail_NoDescription : calendar.description_p
                let hasSubscribed = calendar.isSubscriber
                return .init(ownerName: ownerName, subscriberNum: subscriberNum, description: descriptionStr, hasSubscribed: hasSubscribed)
            }
            .bind(to: rxContentData)
            .disposed(by: disposeBag)
    }
}
