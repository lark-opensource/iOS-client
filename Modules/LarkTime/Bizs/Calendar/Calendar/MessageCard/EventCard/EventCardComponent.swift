//
//  EventCardComponent.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/5.
//

import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import RustPB
import UIKit

public struct EventCardUpdatedComponents: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let time = Self(rawValue: 1 << 0)
    public static let rrule = Self(rawValue: 1 << 1)
    public static let location = Self(rawValue: 1 << 2)
    public static let meetingRoom = Self(rawValue: 1 << 3)
    public static let desc = Self(rawValue: 1 << 4)

    public static let none: Self = []
    public static let all: Self = [.time, .rrule, .location, .meetingRoom, .desc]
}

public final class EventCardComponentProps: ASComponentProps {
    // for header
    public var summary: String?
    public var inviteAttributeString: NSAttributedString?
    public var inviterRange: NSRange?
    public var inviterOnTapped: (() -> Void)?
    public var isShowOptional: Bool = false
    public var isShowExternal: Bool = false
    public var isDeleted: Bool = true
    public var isInvalid: Bool = false
    public var sendUserName: String = ""
    public var messageType: Int? = nil
    public var senderUserId: String? = nil
    // for time
    public var time: String?
    public var isShowConflict: Bool = false
    public var conflictText: String?

    // for location
    public var location: String?

    // for meeting room
    public var meetingRooms: String?

    // for repeat
    public var repeatText: String?

    // for attendee
    public var attendeeString: NSAttributedString?
    public var attendeeRangeDict: [NSRange: String] = [:]
    public var outOfRangeText: NSAttributedString?

    // for description
    public var descString: NSAttributedString?
    public var descRangeDict: [NSRange: URL]?

    // for RSVP
    public var rsvpStatus: CalendarEventAttendee.Status = .needsAction
    public var target: Any?
    public var acceptSelector: Selector?
    public var declinSelector: Selector?
    public var tentativeSelector: Selector?
    public var replySelector: (() -> Void)?
    public var replyedBtnRetapSelector: Selector?
    public var ableToAction: Bool = false
    public var showReplyStasus: Bool = false
    public var replyStasusString: String?
    public var userInviteOperatorId: String?
    public var successorUserId: String?
    public var organizerUserId: String?
    public var creatorUserId: String?
    public var rsvpCommentUserName: String?
    public var showRSVPInviterEntry: Bool = false
    // for action
    public var showProfile: ((String) -> Void)?
    public var jumpUrl: ((URL) -> Void)?
    public var tapDetail: (() -> Void)?

    #if !LARK_NO_DEBUG
    // for debug
    public var showDebugInfo: (() -> Void)?
    #endif

    // for padding
    public var needBottomPadding: Bool = true

    // 是否有左右间距
    public var needHorizontalPadding: Bool = false

    // for RichLable
    public var maxWidth: CGFloat = 0

    // for updated
    public var updatedComponents: EventCardUpdatedComponents = .none

    // for webinar
    public var isWebinar = false

    public var relationTag: String?
    
    public var shouldDeleteReply: Bool = false
}

public final class EventCardComponent<C: Context>: ASComponent<EventCardComponentProps, EmptyState, EventCardView, C> {
    private lazy var headerComponent = EventCardHeaderComponent<C>(props: EventCardHeaderProps(), style: ASComponentStyle(), context: nil)
    private lazy var timeComponent = EventCardTimeComponent<C>(props: EventCardTimeComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var repetaComponent = EventCardRepeatComponent<C>(props: EventCardSimpleCellComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var locationComponent = EventCardLocationComponent<C>(props: EventCardSimpleCellComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var roomComponent = EventCardRoomsComponent<C>(props: EventCardSimpleCellComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var attendeeComponent = EventCardAttendeesComponent<C>(props: EventCardAttendeesComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var descComponent = EventCardDescComponent<C>(props: EventCardDescComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var rsvpComponent = EventCardRSVPComponent<C>(props: EventCardRSVPComponentProps(), style: ASComponentStyle(), context: nil)

    private lazy var replyComponent = EventCardReplyCellComponent<C>(props: EventCardReplyCellComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var clickToViewUpdateComponent = EventCardClickToViewUpdateComponent<C>(props: EventCardClickToViewUpdateComponentProps(), style: ASComponentStyle())

    public override func update(view: EventCardView) {
        super.update(view: view)
        view.backgroundColor = UIColor.ud.bgFloat
        view.onTapped = { [weak self] (_) in
            self?.props.tapDetail?()
        }
        #if !LARK_NO_DEBUG
        view.convenientDebug = { [weak self] in
            self?.props.showDebugInfo?()
        }
        #endif
    }

    override public func willReceiveProps(_ old: EventCardComponentProps, _ new: EventCardComponentProps) -> Bool {
        syncPropsToHeader(props: new)
        syncPropsToTime(props: new)
        syncPropsToSimpleComponent(props: new)
        syncPropsToAttendeeComponent(props: new)
        syncPropsToDescComponent(props: new)
        syncPropsToRSVP(props: new)
        syncPropsToReply(props: new)
        syncPropsToViewUpdate(props: new)
        self.style.paddingBottom = new.needBottomPadding ? 0 : 12
        return true
    }

    private func syncPropsToHeader(props: EventCardComponentProps) {
        let headerProps = EventCardHeaderProps()
        headerProps.summary = props.summary
        headerProps.inviteAttributeString = props.inviteAttributeString
        headerProps.isShowOptional = props.isShowOptional
        headerProps.isShowExternal = props.isShowExternal
        headerProps.isValid = !props.isDeleted
        headerProps.inviterOnTapped = props.inviterOnTapped
        headerProps.inviterRange = props.inviterRange
        headerProps.relationTag = props.relationTag
        headerProps.maxWidth = props.maxWidth
        headerProps.sendUserName = props.sendUserName
        headerProps.senderUserId = props.senderUserId
        headerProps.isWebinar = props.isWebinar
        headerProps.messageType = props.messageType
        self.headerComponent.props = headerProps
    }

    private func syncPropsToTime(props: EventCardComponentProps) {
        let timeProps = EventCardTimeComponentProps()
        timeProps.timeString = props.time
        timeProps.conflictText = props.conflictText
        timeProps.showUpdatedFlag = props.updatedComponents.contains(.time)
        self.timeComponent.props = timeProps

        if props.isInvalid {
            timeComponent.style.display = .none
        }
    }

    private func syncPropsToSimpleComponent(props: EventCardComponentProps) {
        let repeatProps = EventCardSimpleCellComponentProps()
        repeatProps.text = props.repeatText
        repeatProps.showUpdatedFlag = props.updatedComponents.contains(.rrule)
        self.repetaComponent.props = repeatProps
        self.repetaComponent.style.display = props.repeatText != nil ? .flex : .none

        let locationProps = EventCardSimpleCellComponentProps()
        locationProps.text = props.location
        locationProps.showUpdatedFlag = props.updatedComponents.contains(.location)
        self.locationComponent.props = locationProps
        self.locationComponent.style.display = props.location != nil ? .flex : .none

        let roomProps = EventCardSimpleCellComponentProps()
        roomProps.text = props.meetingRooms
        roomProps.showUpdatedFlag = props.updatedComponents.contains(.meetingRoom)
        self.roomComponent.props = roomProps
        self.roomComponent.style.display = props.meetingRooms != nil ? .flex : .none

        if props.isInvalid {
            repetaComponent.style.display = .none
            locationComponent.style.display = .none
            roomComponent.style.display = .none
        }
    }

    private func syncPropsToAttendeeComponent(props: EventCardComponentProps) {
        let attendeeProps = EventCardAttendeesComponentProps()
        attendeeProps.text = props.attendeeString
        attendeeProps.tapableRangeDic = props.attendeeRangeDict
        attendeeProps.outOfRangeText = props.outOfRangeText
        attendeeProps.maxWidth = props.maxWidth
        attendeeProps.didSelectChat = { [weak self] (chatId) in
            self?.props.showProfile?(chatId)
        }
        attendeeProps.isWebinar = props.isWebinar
        self.attendeeComponent.props = attendeeProps
        self.attendeeComponent.style.display = props.attendeeString != nil ? .flex : .none

        if props.isInvalid {
            attendeeComponent.style.display = .none
        }
    }

    private func syncPropsToDescComponent(props: EventCardComponentProps) {
        let descProps = EventCardDescComponentProps()
        descProps.text = props.descString
        descProps.maxWidth = props.maxWidth
        descProps.tapableRangeDic = props.descRangeDict
        descProps.didSelectUrl = { [weak self] (url) in
            self?.props.jumpUrl?(url)
        }
        self.descComponent.props = descProps
        self.descComponent.style.display = props.descString != nil ? .flex : .none

        if props.isInvalid {
            descComponent.style.display = .none
        }
    }

    private func syncPropsToRSVP(props: EventCardComponentProps) {
        let rsvpProps = EventCardRSVPComponentProps()
        rsvpProps.acceptSelector = props.acceptSelector
        rsvpProps.declinSelector = props.declinSelector
        rsvpProps.tentativeSelector = props.tentativeSelector
        rsvpProps.replySelector = props.replySelector
        rsvpProps.status = props.rsvpStatus
        rsvpProps.target = props.target
        rsvpProps.replyedBtnRetapSelector = props.replyedBtnRetapSelector
        rsvpProps.showRSVPInviterEntry = props.showRSVPInviterEntry
        rsvpProps.shouldDeleteReply = props.shouldDeleteReply

        self.rsvpComponent.style.display = (props.ableToAction && !props.showReplyStasus) ? .flex : .none
        self.rsvpComponent.props = rsvpProps

        if props.isInvalid {
            rsvpComponent.style.display = .none
        }
    }

    private func syncPropsToReply(props: EventCardComponentProps) {
        let replyLabelProps = replyComponent.props
        replyLabelProps.text = props.replyStasusString
        replyLabelProps.name = props.rsvpCommentUserName
        let needDisplay = props.showReplyStasus && !(props.replyStasusString?.isEmpty ?? true)
        self.replyComponent.style.display = needDisplay ? .flex : .none
        self.replyComponent.props = replyLabelProps

        if props.isInvalid {
            replyComponent.style.display = .none
        }
    }

    private func syncPropsToViewUpdate(props: EventCardComponentProps) {
        self.clickToViewUpdateComponent.style.display = props.isInvalid ? .flex : .none
    }

    public override init(props: EventCardComponentProps, style: ASComponentStyle, context: C?) {
        super.init(props: props, style: style, context: context)
        style.justifyContent = .flexEnd
        style.flexDirection = .column
        style.alignContent = .stretch
        style.paddingBottom = 12
        style.alignItems = .stretch

        _ = willReceiveProps(props, props)
        setSubComponents([
            headerComponent,
            timeComponent,
            repetaComponent,
            locationComponent,
            roomComponent,
            attendeeComponent,
            descComponent,
            rsvpComponent,
            replyComponent,
            clickToViewUpdateComponent
        ])
    }
}
