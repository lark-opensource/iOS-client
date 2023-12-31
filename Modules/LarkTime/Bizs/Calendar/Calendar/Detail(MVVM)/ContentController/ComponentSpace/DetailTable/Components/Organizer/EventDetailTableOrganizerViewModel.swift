//
//  EventDetailTableOrganizerViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/3/30.
//

import UIKit
import Foundation
import LarkContainer
import CalendarFoundation
import LarkCombine
import UniverseDesignColor
import RxSwift

final class EventDetailTableOrganizerViewModel: EventDetailComponentViewModel {

    var model: EventDetailModel { rxModel.value}
    let viewData = CurrentValueSubject<ViewData, Never>(.notDecision)
    let route = PassthroughSubject<Route, Never>()
    var calendar: EventDetail.Calendar?
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var mailContactService: MailContactService?
    @ContextObject(\.rxModel) var rxModel

    override init(context: EventDetailContext, userResolver: UserResolver) {

        super.init(context: context, userResolver: userResolver)
        calendar = calendarManager?.calendar(with: context.rxModel.value.calendarId)

        bindRx()
    }

    private func bindRx() {
        let modelPush: Observable<Bool> = rxModel.map { _ in true }
        let mailParsedPush: Observable<Bool> = mailContactService?.rxDataChanged.map { _ in false } ?? .empty()
        Observable.merge(modelPush, mailParsedPush)
            .subscribe(onNext: { [weak self] loadMailContactParsed in
                guard let self = self else { return }
                self.buildViewData(loadMailContactParsed: loadMailContactParsed)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - ViewData

extension EventDetailTableOrganizerViewModel {

    enum ViewData {
        // 还未决策视图类型
        case notDecision
        // 邮件参与人
        case email(EventDetailTableOrganizerViewDataType)
        // 拿不到参与人
        case cannotGetInfo
        // 正常参与人信息
        case contact(EventDetailTableOrganizerViewDataType)
    }

    private func buildViewData(loadMailContactParsed: Bool = true) {

        if let roomInstance = model.roomLimitInstance {
            let person = roomInstance.pb.resourceContactPerson
            guard roomInstance.pb.hasResourceContactPerson,
                  !person.avatarKey.isEmpty,
                  !person.contactPerson.chatterID.isEmpty else {
                viewData.send(.cannotGetInfo)
                return
            }

            let contact = roomInstance.pb.resourceContactPerson
            let tagString = contact.contactPersonType == .resourceSubscriber ? I18n.Calendar_Takeover_ReservedBy : I18n.Calendar_Detail_Organizer

            let content = ContactViewData(avatar: (contact, nil),
                                   tagStrings: [(tagString, UDColor.primaryContentDefault)],
                                   calendarID: nil)
            viewData.send(.contact(content))
            EventDetail.logInfo("room instance contact: \(contact.contactPerson.chatterID)")
            return
        }

        if showCannotGetInfo() {
            viewData.send(.cannotGetInfo)
            EventDetail.logInfo("contact cannot get info")
            return
        }

        let isMeetingRoom: Bool
        if let calendar = calendarManager?.calendar(with: model.calendarId) {
            isMeetingRoom = (calendar.type == .resources || calendar.type == .googleResource)
        } else {
            isMeetingRoom = false
        }
        let content = isMeetingRoom ? getMeetingRoomContactAttendeeContent() : getDetailContactAttendeeContent(loadMailContactParsed: loadMailContactParsed)
        guard let content = content else { return }
        EventDetail.logInfo("contact: \(showEmail() ? "email" : "contact") \(content.calendarID ?? "" + " " + content.tagStrings.map { $0.tag }.joined(separator: "、"))")
        viewData.send(showEmail() && content.subTitle == nil ? .email(content) : .contact(content))
    }
}

// MARK: - Action

extension EventDetailTableOrganizerViewModel {

    enum Route {
        case profile(calendarId: String, eventTitle: String)
        case profileWithChatterID(_ chatterID: String, eventTitle: String)
    }

    func tap() {

        CalendarTracer.shareInstance.calShowUserCard(actionSource: .eventDetail)
        if let roomInstance = model.roomLimitInstance {
            let chatterID = roomInstance.pb.resourceContactPerson.contactPerson.chatterID
            route.send(.profileWithChatterID(chatterID, eventTitle: ""))
        } else if let event = model.event {

            let currentValue = viewData.value
            if case let .contact(data) = currentValue,
               let contact = data as? ContactViewData,
               let calendarID = contact.calendarID {
                route.send(.profile(calendarId: calendarID, eventTitle: event.dt.displayTitle))
            }
        } else {
            EventDetail.logUnreachableLogic()
            return
        }
    }
}

// MARK: - Private

extension EventDetailTableOrganizerViewModel {

    struct ContactViewData: EventDetailTableOrganizerViewDataType {
        var avatar: (avatar: Avatar, statusImage: UIImage?)
        var tagStrings: [(tag: String, textColor: UIColor)]
        var calendarID: String?
        var subTitle: String?
    }

    private func showCannotGetInfo() -> Bool {

        guard let calendar = model.getCalendar(calendarManager: self.calendarManager),
              calendar.type == .resources || calendar.type == .googleResource else {
            return false
        }

        return meetingRoomContactAttendee().displayName.isEmpty
    }

    private func meetingRoomContactAttendee() -> PBAttendee {
        guard let event = model.event else {
            EventDetail.logUnreachableLogic()
            assertionFailure("")
            return PBAttendee(pb: CalendarEventAttendee())
        }

        //被转让的对象
        if !event.successor.attendeeCalendarID.isEmpty {
            return PBAttendee(pb: event.successor)
        }

        if !event.organizer.displayName.isEmpty {
            return PBAttendee(pb: event.organizer)
        }
        return PBAttendee(pb: event.creator)
    }

    private func showEmail() -> Bool {
        guard let event = model.event else {
            return false
        }
        return event.source == .google || event.source == .exchange
    }

    private func getMeetingRoomContactAttendeeContent() -> ContactViewData? {
        guard let event = model.event else {
            EventDetail.logUnreachableLogic()
            return nil
        }

        let showAttendee = meetingRoomContactAttendee()
        let avatar = showAttendee.avatar

        var tagStrings: [(String, UIColor)] = []
        let hasOrganizer = event.hasOrganizer

        if hasOrganizer {
            tagStrings.append((BundleI18n.Calendar.Calendar_Detail_Organizer, UIColor.ud.primaryContentDefault))
        }
        return ContactViewData(avatar: (avatar, nil),
                               tagStrings: tagStrings,
                               calendarID: showAttendee.attendeeCalendarId)
    }

    private func getDetailContactAttendeeContent(loadMailContactParsed: Bool) -> ContactViewData? {
        guard let event = model.event else {
            EventDetail.logUnreachableLogic()
            return nil
        }

        var tagStrings: [(String, UIColor)] = []
        var eventOwner: PBAttendee
        let hasSuccessor = event.hasSuccessor
        let hasOrganizer = event.hasOrganizer
        let hasCreator = event.hasCreator
        let willEventOwnerAttend: Bool

        // tag 顺序要求:
        // 1. 是否显示组织者/创建者标签
        // 2. 是否显示外部 or 邮件参与人标签
        // 3. 是否显示"不参加"标签
        if hasSuccessor {
            // 先判断是否有继承者，有继承者时优先显示继承者
            eventOwner = PBAttendee(pb: event.successor)
            willEventOwnerAttend = event.willSuccessorAttend
            tagStrings.append((BundleI18n.Calendar.Calendar_Detail_Organizer, UIColor.ud.primaryContentDefault))
        } else if hasOrganizer {
            eventOwner = PBAttendee(pb: event.organizer)
            // 特殊逻辑，服务端bug。生成例外需要时间，所以pb里面的willOrganizerAttend字段不准，要综合看参与人状态考虑
            willEventOwnerAttend = event.willOrganizerAttend || eventOwner.status != .removed
            tagStrings.append((BundleI18n.Calendar.Calendar_Detail_Organizer, UIColor.ud.primaryContentDefault))
        } else if hasCreator {
            eventOwner = PBAttendee(pb: event.creator)
            willEventOwnerAttend = event.willCreatorAttend
            tagStrings.append((BundleI18n.Calendar.Calendar_Detail_Organizer, UIColor.ud.primaryContentDefault))
        } else {
//            EventDetail.logUnreachableLogic()
            eventOwner = PBAttendee(pb: CalendarEventAttendee())
            willEventOwnerAttend = false
        }

        // 判断是否显示外部 or 邮件参与人标签
        if let tag = eventOwner.pb.thirdPartyUser.mailContactType.emailTag, eventOwner.isThirdParty && eventOwner.pb.thirdPartyUser.mailContactType != .normalMail {
            tagStrings.append((tag, UIColor.ud.primaryContentDefault))
        } else if !eventOwner.relationTagStr.isEmpty {
            tagStrings.append(((eventOwner.relationTagStr, UIColor.ud.functionWarningContentDefault)))
        }

        // 判断是否显示"不参加"标签
        if !model.shouldHideAttendees(for: calendar) && !willEventOwnerAttend {
            tagStrings.append((BundleI18n.Calendar.Calendar_Detail_NotAttend, UIColor.ud.textPlaceholder))
        }

        if loadMailContactParsed,
           let mail = eventOwner.mail {
            mailContactService?.loadMailContact(mails: [mail])
        }

        eventOwner.changeNormalMailContactPBIfNeeded(mailContactService)

        return ContactViewData(
            avatar: (eventOwner.avatar, eventOwner.getStatusImage()),
            tagStrings: tagStrings,
            calendarID: eventOwner.toProfileCalendarId,
            subTitle: eventOwner.isMailAttendeeParsed ? eventOwner.mail : nil
        )
    }
}
