//
//  ShareCardComponent.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/26.
//

import UIKit
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable

public final class ShareCardComponentProps: ASComponentProps {
    // for header
    public var summary: String?
    public var isShowOptional: Bool = false
    public var isShowExternal: Bool = false
    public var isVaild: Bool = true
    public var target: Any?
    public var inviteMessageSelector: Selector?
    // for time
    public var time: String?
    public var conflictText: String?

    // for location
    public var location: String?

    // for meeting room
    public var meetingRooms: String?

    // for repeat
    public var repeatText: String?

    // for join
    public var joinSelector: Selector?
    public var joinTarget: Any?
    public var isJoined: Bool = false

    // for RSVP
    public var rsvpStatus: CalendarEventAttendee.Status = .needsAction
    public var rsvpTarget: Any?
    public var acceptSelector: Selector?
    public var declinSelector: Selector?
    public var tentativeSelector: Selector?
    public var replyedBtnRetapSelector: Selector?
    public var moreReplyeTappedSelector: Selector?

    public var replyStasusString: String?
    public var userInviteOperatorId: String?
    public var rsvpCommentUserName: String?

    // for action
    public var tapDetail: (() -> Void)?

    #if !LARK_NO_DEBUG
    // for debug
    public var showDebugInfo: (() -> Void)?
    #endif

    // for padding
    public var needBottomPadding: Bool = true

    public var hasReaction: Bool = true

    public var relationTag: String?
}

public final class ShareCardComponent<C: Context>: ASComponent<ShareCardComponentProps, EmptyState, EventCardView, C> {

    private lazy var headerComponent = EventCardHeaderComponent<C>(props: EventCardHeaderProps(), style: ASComponentStyle(), context: nil)
    private lazy var headerComponentV2 = EventCardRSVPHeaderComponent<C>(props: EventCardRSVPHeaderComponentProps(), style: ASComponentStyle(), context: nil)

    private lazy var timeComponent = EventCardTimeComponent<C>(props: EventCardTimeComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var timeComponentV2 = EventCardRSVPTimeComponent<C>(props: EventCardRSVPTimeComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var repetaComponent = EventCardRepeatComponent<C>(props: EventCardSimpleCellComponentProps(), style: ASComponentStyle(), context: nil)

    private lazy var repetaComponentV2 = EventCardRSVPRepeatComponent<C>(props: EventCardRSVPRepeatComponentProps(), style: ASComponentStyle(), context: nil)
    private lazy var locationComponent = EventCardLocationComponent<C>(props: EventCardSimpleCellComponentProps(), style: ASComponentStyle(), context: nil)

    private lazy var locationComponentV2 = EventCardRSVPLocationComponent<C>(props: EventCardRSVPSimpleCellCopmonentProps(), style: ASComponentStyle(), context: nil)

    private lazy var roomComponent = EventCardRoomsComponent<C>(props: EventCardSimpleCellComponentProps(), style: ASComponentStyle(), context: nil)

    private lazy var roomComponentV2 = EventCardRSVPRoomsComponent<C>(props: EventCardRSVPSimpleCellCopmonentProps(), style: ASComponentStyle(), context: nil)
    private lazy var joinButtonComponent: CalendarButtonComponent<C> = {
        let style = ASComponentStyle()
        style.height = 32
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        style.cornerRadius = 6
        style.marginTop = 12
        style.marginLeft = 12
        style.marginRight = 12
        style.display = .none
        let props = CalendarButtonComponentProps()
        props.font = UIFont.ud.body2
        props.disableTitleColor = UIColor.ud.textPlaceholder
        props.normalTitleColor = UIColor.ud.textTitle
        props.normalTitle = BundleI18n.Calendar.Calendar_Share_Join
        let component = CalendarButtonComponent<C>(props: props, style: style)
        return component
    }()

    private lazy var rsvpComponent = EventCardRSVPComponent<C>(props: EventCardRSVPComponentProps(), style: ASComponentStyle(), context: nil)

    private lazy var rsvpComponentV2 = EventCardRSVPCellComponent<C>(props: EventCardRSVPCellComponentProps(), style: ASComponentStyle(), context: nil)

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

    private func syncPropsToRSVP(props: ShareCardComponentProps) {
        let rsvpProps = EventCardRSVPComponentProps()
        rsvpProps.acceptSelector = props.acceptSelector
        rsvpProps.declinSelector = props.declinSelector
        rsvpProps.tentativeSelector = props.tentativeSelector
        rsvpProps.replySelector = nil
        rsvpProps.replyedBtnRetapSelector = props.replyedBtnRetapSelector
        rsvpProps.status = props.rsvpStatus
        rsvpProps.target = props.rsvpTarget
        rsvpProps.showRSVPInviterEntry = false
        self.rsvpComponent.props = rsvpProps

        let rsvpPropsV2 = EventCardRSVPCellComponentProps()
        rsvpPropsV2.status = props.rsvpStatus
        rsvpPropsV2.target = props.rsvpTarget
        rsvpPropsV2.acceptSelector = props.acceptSelector
        rsvpPropsV2.declinSelector = props.declinSelector
        rsvpPropsV2.tentativeSelector = props.tentativeSelector
        rsvpPropsV2.replyedBtnRetapSelector = props.replyedBtnRetapSelector
        rsvpPropsV2.moreReplyeTappedSelector = props.moreReplyeTappedSelector

        self.rsvpComponentV2.props = rsvpPropsV2
    }

    override public func willReceiveProps(_ old: ShareCardComponentProps, _ new: ShareCardComponentProps) -> Bool {
        syncPropsToHeader(props: new)
        syncPropsToTime(props: new)
        syncPropsToSimpleComponent(props: new)
        syncPropsToJoin(props: new)
        syncPropsToRSVP(props: new)
        self.style.paddingBottom = new.needBottomPadding ? 0 : 12
        return true
    }

    private func syncPropsToHeader(props: ShareCardComponentProps) {
        let headerProps = EventCardHeaderProps()
        headerProps.summary = props.summary
        headerProps.isShowOptional = props.isShowOptional
        headerProps.isShowExternal = props.isShowExternal
        headerProps.isValid = props.isVaild
        headerProps.target = props.target
        headerProps.inviteMessageSelector = props.inviteMessageSelector
        headerProps.relationTag = props.relationTag
        self.headerComponent.props = headerProps

        let headerPropsV2 = EventCardRSVPHeaderComponentProps()
        headerPropsV2.headerTitle = props.summary
        headerPropsV2.isShowOptional = props.isShowOptional
        headerPropsV2.isShowExternal = props.isShowExternal
        headerPropsV2.isInValid = !props.isVaild
        headerPropsV2.relationTag = props.relationTag
        headerPropsV2.status = props.rsvpStatus
        headerPropsV2.maxWidth = CGFloat(self.style.width.value)
        self.headerComponentV2.props = headerPropsV2
    }

    private func syncPropsToTime(props: ShareCardComponentProps) {
        let timeProps = EventCardTimeComponentProps()
        timeProps.timeString = props.time
        timeProps.conflictText = props.conflictText
        self.timeComponent.props = timeProps

        let timePropsV2 = EventCardRSVPTimeComponentProps()
        timePropsV2.timeString = props.time
        timePropsV2.conflictText = props.conflictText
        timePropsV2.maxWidth = CGFloat(self.style.width.value)
        timeComponentV2.props = timePropsV2
    }

    private func syncPropsToSimpleComponent(props: ShareCardComponentProps) {
        let repeatProps = EventCardSimpleCellComponentProps()
        repeatProps.text = props.repeatText
        self.repetaComponent.props = repeatProps
        self.repetaComponent.style.display = props.repeatText != nil ? .flex : .none

        let repeatPropsV2 = EventCardRSVPRepeatComponentProps()
        repeatPropsV2.text = props.repeatText
        repeatPropsV2.maxWidth = CGFloat(self.style.width.value)
        repetaComponentV2.props = repeatPropsV2

        self.repetaComponentV2.style.display = props.repeatText != nil ? .flex : .none

        let locationProps = EventCardSimpleCellComponentProps()
        locationProps.text = props.location
        self.locationComponent.props = locationProps
        self.locationComponent.style.display = props.location != nil ? .flex : .none

        let locationPropsV2 = EventCardRSVPSimpleCellCopmonentProps()
        locationPropsV2.text = props.location
        locationPropsV2.numberOfLines = 2
        locationPropsV2.maxWidth = CGFloat(self.style.width.value)
        locationComponentV2.props = locationPropsV2
        locationComponentV2.style.display = props.location != nil ? .flex : .none

        let roomProps = EventCardSimpleCellComponentProps()
        roomProps.text = props.meetingRooms
        self.roomComponent.props = roomProps
        self.roomComponent.style.display = props.meetingRooms != nil ? .flex : .none

        let roomPropsV2 = EventCardRSVPSimpleCellCopmonentProps()
        roomPropsV2.text = props.meetingRooms
        roomPropsV2.numberOfLines = 2
        roomPropsV2.showUpdatedFlag = false
        roomPropsV2.maxWidth = CGFloat(self.style.width.value)
        roomComponentV2.props = roomPropsV2
        roomComponentV2.style.display = props.meetingRooms != nil ? .flex : .none

    }

    private func syncPropsToJoin(props: ShareCardComponentProps) {
        let joinProps = joinButtonComponent.props
        joinProps.selector = props.joinSelector
        joinProps.target = props.joinTarget

        if !props.isVaild {
            joinProps.disableTitle = BundleI18n.Calendar.Calendar_Share_Expired
            joinProps.isEnabled = false
            joinButtonComponent.style.display = .flex
            rsvpComponent.style.display = .none
            rsvpComponentV2.style.display = .none
        } else if props.isJoined {
            joinProps.disableTitle = BundleI18n.Calendar.Calendar_Share_Joined
            joinProps.isEnabled = false
            joinButtonComponent.style.display = .none
            rsvpComponent.style.display = .flex
            rsvpComponentV2.style.display = .flex
        } else {
            joinProps.isEnabled = true
            joinButtonComponent.style.display = .flex
            rsvpComponent.style.display = .none
            rsvpComponentV2.style.display = .none
        }

        self.joinButtonComponent.props = joinProps
    }

    public override init(props: ShareCardComponentProps, style: ASComponentStyle, context: C?) {
        super.init(props: props, style: style, context: context)
        style.justifyContent = .flexEnd
        style.flexDirection = .column
        style.alignContent = .stretch
        style.paddingBottom = 12
        style.alignItems = .stretch

        _ = willReceiveProps(props, props)

        if FG.shareCardStyleOpt {
            setSubComponents([
                headerComponentV2,
                timeComponentV2,
                repetaComponentV2,
                roomComponentV2,
                locationComponentV2,
                joinButtonComponent,
                rsvpComponentV2
            ])
        } else {
            setSubComponents([
                headerComponent,
                timeComponent,
                repetaComponent,
                roomComponent,
                locationComponent,
                joinButtonComponent,
                rsvpComponent
            ])
        }
    }

}

#if !LARK_NO_DEBUG
extension EventShareBinder: ConvenientDebug {}
#endif
