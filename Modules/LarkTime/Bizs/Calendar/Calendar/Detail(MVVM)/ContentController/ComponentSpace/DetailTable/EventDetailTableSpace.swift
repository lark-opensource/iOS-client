//
//  EventDetailTableSpace.swift
//  Calendar
//
//  Created by Rico on 2021/3/16.
//

import Foundation
import UIKit
import CalendarFoundation

// MARK: - Space

final class EventDetailTableSpace: BaseSpace<EventDetailTableManager, EventDetailTableLayoutEngine> {

    init(viewController: UIViewController,
         componentProvider: EventDetailComponentProvider) {

        super.init(manager: EventDetailTableManager(provider: componentProvider),
                   layoutEngine: EventDetailTableLayoutEngine(),
                   viewController: viewController)
    }

    override func loadComponents() {
        let components = manager.generateComponents()
        manager.components = components
        manager.components.forEach { component in
            component.viewController = viewController
        }
    }

    func reloadComponents() {
        loadComponents()
    }
}

// MARK: - Manager
final class EventDetailTableManager: BaseManager {

    let provider: EventDetailComponentProvider

    var videoMeeting: ComponentType?
    var zoomMeeting: ComponentType?
    var videoLive: ComponentType?
    var organizer: ComponentType?
    var attendee: ComponentType?
    var webinarSpeaker: ComponentType?
    var webinarAudience: ComponentType?
    var location: ComponentType?
    var meetingRoom: ComponentType?
    var attachment: ComponentType?
    var description: ComponentType?
    var checkIn: ComponentType?
    var remind: ComponentType?
    var calendar: ComponentType?
    var creator: ComponentType?
    var visibility: ComponentType?
    var freebusy: ComponentType?
    var meetingNotes: ComponentType?

    init(provider: EventDetailComponentProvider) {
        self.provider = provider
        super.init()
    }

    private var detailComponents: [EventDetailComponent] {
        if provider.model.event?.displayType == .undecryptable {
            return [.undecryptableDetail]
        }

        let meetingRoomLimitComponents: [EventDetailComponent] = [
            .videoMeeting,
            .zoomMeeting,
            .videoLive,
            .organizer,
            .attendee,
            .webinarSpeaker,
            .webinarAudience,
            .location,
            .meetingRoom,
            .description,
            .attachment,
            .remind,
            .calendar,
            .creator,
            .visibility,
            .freebusy
        ]

        let normalComponents: [EventDetailComponent] = [
            .conflict,
            .videoMeeting,
            .zoomMeeting,
            .videoLive,
            .meetingRoom,
            .location,
            .organizer,
            .attendee,
            .webinarSpeaker,
            .webinarAudience,
            .meetingNotes,
            .description,
            .attachment,
            .checkIn,
            .remind,
            .calendar,
            .creator,
            .visibility,
            .freebusy
        ]

        return isMeetingRoomLimit ? meetingRoomLimitComponents : normalComponents
    }

    private var componentMap: [EventDetailComponent: ComponentType?] {
        return [
            .videoMeeting: videoMeeting,
            .zoomMeeting: zoomMeeting,
            .videoLive: videoLive,
            .meetingRoom: meetingRoom,
            .location: location,
            .organizer: organizer,
            .attendee: attendee,
            .webinarSpeaker: webinarSpeaker,
            .webinarAudience: webinarAudience,
            .attachment: attachment,
            .description: description,
            .checkIn: checkIn,
            .remind: remind,
            .calendar: calendar,
            .creator: creator,
            .visibility: visibility,
            .freebusy: freebusy,
            .meetingNotes: meetingNotes
        ]
    }

    func generateComponents() -> [ComponentType] {
        var result: [ComponentType?] = []
        for type in detailComponents {
            var component: ComponentType? = componentMap[type] ?? nil
            EventDetail.logDebug("\(type) get from component map")
            if provider.shouldLoadComponent(for: type) {
                if component == nil {
                    // 新建component
                    component = provider.buildComponent(for: type)
                    EventDetail.logDebug("\(type) not exist，now use new component")
                } else {
                    // do nothing
                    EventDetail.logDebug("\(type) exist，now use directly")
                }
            } else {
                if component == nil {
                    EventDetail.logDebug("\(type) not exist，now do nothing")
                    // do nothing
                } else {
                    // 删除
                    EventDetail.logDebug("\(type) exist, now delete")
                    component = nil
                }
            }
            result.append(component)
            EventDetail.logDebug("\(type) set \(String(describing: component))")
            set(component: component, for: type)
        }

        EventDetail.logInfo("""
            Table space load components:
            .videoMeeting: \(videoMeeting != nil),
            .zoomMerting:\(zoomMeeting != nil),
            .videoLive: \(videoLive != nil),
            .meetingRoom: \(meetingRoom != nil),
            .location: \(location != nil),
            .organizer: \(organizer != nil),
            .attendee: \(attendee != nil),
            .webinarSpeaker: \(webinarSpeaker != nil),
            .webinarAudience: \(webinarAudience != nil),
            .attachment: \(attachment != nil),
            .description: \(description != nil),
            .checkIn: \(checkIn != nil),
            .remind: \(remind != nil),
            .calendar: \(calendar != nil),
            .creator: \(creator != nil),
            .visibility: \(visibility != nil),
            .freebusy: \(freebusy != nil),
            .meetingNotes: \(meetingNotes != nil)
            """)

        return result.compactMap { $0 }
    }

    private func set(component: ComponentType?, for type: EventDetailComponent) {
        switch type {
        case .videoMeeting: self.videoMeeting = component
        case .zoomMeeting: self.zoomMeeting = component
        case .videoLive: self.videoLive = component
        case .meetingRoom: self.meetingRoom = component
        case .location: self.location = component
        case .organizer: self.organizer = component
        case .attendee: self.attendee = component
        case .webinarSpeaker: self.webinarSpeaker = component
        case .webinarAudience: self.webinarAudience = component
        case .attachment: self.attachment = component
        case .description: self.description = component
        case .checkIn: self.checkIn = component
        case .remind: self.remind = component
        case .calendar: self.calendar = component
        case .creator: self.creator = component
        case .visibility: self.visibility = component
        case .freebusy: self.freebusy = component
        case .meetingNotes: self.meetingNotes = component
        default: break
        }
    }

    private var isMeetingRoomLimit: Bool {
        switch provider.model {
        case .meetingRoomLimit: return true
        default: return false
        }
    }
}

// MARK: - Layout

final class EventDetailTableLayoutEngine: BaseLayoutEngine<BottomViewSharableKey> {

    override func layout(with views: [UIView]) {
        EventDetail.logInfo("table space layout views. count: \(views.count)")
        guard let stackView = rootView as? UIStackView else {
            assertionFailure()
            return
        }

        views.forEach {
            stackView.addArrangedSubview($0)
        }
    }

    func resolveRootView(_ rootView: UIView?, on componentsView: [UIView]) {
        guard let rootView = rootView else {
            assertionFailure("Could not get root view")
            return
        }
        self.rootView = rootView
        componentsView.forEach {
            $0.removeFromSuperview()
        }
        layout(with: componentsView)
    }
}
