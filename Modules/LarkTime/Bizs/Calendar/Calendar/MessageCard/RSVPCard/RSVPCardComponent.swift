//
//  RSVPCardComponent.swift
//  Calendar
//
//  Created by pluto on 2023/1/12.
//

import UIKit
import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import LarkModel
import RustPB

public final class RSVPCardComponentProps: ASComponentProps {
    //for header
    public var headerTitle: String?
    
    // for title
    public var summary: String?

    //for time
    public var time: String?
    public var conflictText: String?
    public var isTimeUpdate: Bool = false
    public var isRruleUpdate: Bool = false
    public var richTime: NSAttributedString?
    
    //for repeat
    public var repeatText: String?

    //for location
    public var location: String?

    //for meeting room
    public var meetingRooms: String?


    // for description
    public var descString: String?
    
    // for attendee
    public var attendeeString: NSAttributedString?
    public var attendeeRangeDict: [NSRange: String] = [:]
    public var outOfRangeText: NSAttributedString?
    public var rsvpAllReplyedCountString: String?
    public var eventTotalAttendeeCount: Int64?
    public var needActionCount: Int64?
    public var isAllUserInGroupReplyed: Bool = false
    
    //for join
    public var joinSelector: Selector?
    public var joinTarget: Any?
    public var isJoined: Bool = false
    
    // for RichLable
    public var maxWidth: CGFloat = 0

    // for RSVP
    public var rsvpStatus: CalendarEventAttendee.Status = .needsAction
    public var rsvpTarget: Any?
    public var acceptSelector: Selector?
    public var declinSelector: Selector?
    public var tentativeSelector: Selector?
    public var replyedBtnRetapSelector: Selector?
    public var moreReplyeTappedSelector: Selector?
    
    // for reactionRsvp
    public var reactionRsvpList: [RSVPReactionInfo] = []
    public var userOwnChatterId: String?

    //for action
    public var tapDetail: (() -> Void)?
    public var showProfile: ((String) -> Void)?
    public var didSelectReaction: ((Int) -> Void)?
    public var tapMeetingNotes: (() -> Void)?
    public var didTapReactionMore: ((Int) -> Void)?
    public var calReactionInfo:( (Int) -> [RSVPReactionInfo])?

    #if !LARK_NO_DEBUG
    //for debug
    public var showDebugInfo: (() -> Void)?
    #endif
    
    public var isShowOptional: Bool = false
    public var isShowExternal: Bool = false
    public var isInValid: Bool = false
    public var isUpdated: Bool = false
    public var isAttendeeOverflow: Bool = false
    public var isLocationUpdated: Bool = false
    public var isResourceUpdated: Bool = false
    
    public var cardStatus: EventRSVPCardInfo.EventRSVPCardStatus = .normal

    //for padding
    public var needBottomPadding: Bool = true

    public var relationTag: String?
    
    public var meetingNotes: RSVPCardMeetingNotesData?

}

public struct RSVPCardMeetingNotesData: Equatable {
    var url: String
    var parsedTitle: String?
    var isDeleted: Bool = false

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.url == rhs.url
    }
}

public final class RSVPCardComponent<C: Context>: ASComponent<RSVPCardComponentProps, EmptyState, EventCardView, C> {

    /// FG外 老版本
    private lazy var oldHeaderComponent = EventCardOldRSVPHeaderComponent<C>(props: EventCardRSVPHeaderComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var oldTimeComponent = EventCardOldRSVPTimeComponent<C>(props: EventCardRSVPTimeComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var oldRepeatComponent = EventCardOldRSVPRepeatComponent<C>(props: EventCardRSVPRepeatComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var oldLocationComponent = EventCardLocationComponent<C>(props: EventCardSimpleCellComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var oldRoomComponent = EventCardRoomsComponent<C>(props: EventCardSimpleCellComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var oldDescComponent = EventCardDescComponent<C>(props: EventCardDescComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var attendeeComponent = EventCardRSVPAttendeesComponent<C>(props: EventCardRSVPAttendeesComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var oldReactionComponent = EventCardOldRSVPReactionComponent<C>(props: EventCardRSVPReactionComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var oldRsvpComponent = EventCardOldRSVPCellComponent<C>(props: EventCardRSVPCellComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var oldClickToViewUpdateComponent = EventCardClickToViewUpdateComponent<C>(props: EventCardClickToViewUpdateComponentProps(), style: ASComponentStyle())
    
    /// FG内 极光风格
    private lazy var headerComponent = EventCardRSVPHeaderComponent<C>(props: EventCardRSVPHeaderComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var timeComponent = EventCardRSVPTimeComponent<C>(props: EventCardRSVPTimeComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var repeatComponent = EventCardRSVPRepeatComponent<C>(props: EventCardRSVPRepeatComponentProps(), style: ASComponentStyle(), context: nil)

    private lazy var locationComponent = EventCardRSVPLocationComponent<C>(props: EventCardRSVPSimpleCellCopmonentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var roomComponent = EventCardRSVPRoomsComponent<C>(props: EventCardRSVPSimpleCellCopmonentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var descComponent = EventCardRSVPDescComponent<C>(props: EventCardDescComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var rsvpComponent = EventCardRSVPCellComponent<C>(props: EventCardRSVPCellComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var needActionReactionInfoComponent = EventCardRSVPReactionInfoComponent<C>(props: EventCardRSVPReactionInfoComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var needActionReactionComponent = EventCardRSVPReactionComponent<C>(props: EventCardRSVPReactionComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var reactionInfoComponent = EventCardRSVPReactionInfoComponent<C>(props: EventCardRSVPReactionInfoComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var reactionComponent = EventCardRSVPReactionComponent<C>(props: EventCardRSVPReactionComponentProps(), style: ASComponentStyle(), context: nil)
    
    private lazy var clickToViewUpdateComponent = EventCardRSVPViewUpdatedComponent<C>(props: EventCardClickToViewUpdateComponentProps(), style: ASComponentStyle())
    
    private lazy var meetingNotesComponent = EventCardMeetingNotesComponent<C>(props: EventCardSimpleCellComponentProps(), style: ASComponentStyle())
    
    private lazy var joinButtonComponent: CalendarButtonComponent<C> = {
        let style = ASComponentStyle()
        style.height = FG.rsvpStyleOpt ? 40 : 32
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

    override public func willReceiveProps(_ old: RSVPCardComponentProps, _ new: RSVPCardComponentProps) -> Bool {
        syncPropsToHeader(props: new)
        syncPropsToSimpleComponent(props: new)
        syncPropsToTime(props: new)
        syncPropsToDescComponent(props: new)
        syncPropsToAttendeeComponent(props: new)
        syncPropsToRSVP(props: new)
        syncPropsToJoin(props: new)
        syncPropsToNeedActionReactionInfo(props: new)
        syncPropsToNeedActionReaction(props: new)
        syncPropsToReactionInfo(props: new)
        syncPropsToReaction(props: new)
        syncPropsToViewUpdate(props: new)
        self.style.paddingBottom = new.needBottomPadding ? 0 : 12
        return true
    }

    private func syncPropsToHeader(props: RSVPCardComponentProps) {
        let headerProps = EventCardRSVPHeaderComponentProps()
        headerProps.headerTitle = props.headerTitle
        headerProps.isShowOptional = props.isShowOptional
        headerProps.isShowExternal = props.isShowExternal
        headerProps.isInValid = props.isInValid
        headerProps.relationTag = props.relationTag
        headerProps.status = props.rsvpStatus
        headerProps.cardStatus = props.cardStatus
        headerProps.maxWidth = CGFloat(self.style.width.value)
        
        headerComponent.props = headerProps
        oldHeaderComponent.props = headerProps
    }
    
    private func syncPropsToTime(props: RSVPCardComponentProps) {
        let timeProps = EventCardRSVPTimeComponentProps()
        timeProps.timeString = props.time
        timeProps.conflictText = props.conflictText
        timeProps.showUpdatedFlag = props.isTimeUpdate
        timeProps.maxWidth = CGFloat(self.style.width.value)
        timeComponent.props = timeProps
        oldTimeComponent.props = timeProps
        
        timeComponent.style.display = props.isUpdated ? .none : .flex
        oldTimeComponent.style.display = props.isUpdated ? .none : .flex
    }
    
    private func syncPropsToSimpleComponent(props: RSVPCardComponentProps) {
        
        let repeatProps = EventCardRSVPRepeatComponentProps()
        repeatProps.text = props.repeatText
        repeatProps.showUpdatedFlag = props.isRruleUpdate
        repeatProps.maxWidth = CGFloat(self.style.width.value)
        
        repeatComponent.props = repeatProps
        oldRepeatComponent.props = repeatProps
        
        repeatComponent.style.display = props.repeatText != nil ? .flex : .none
        oldRepeatComponent.style.display = props.repeatText != nil ? .flex : .none

        let oldLocationProps = EventCardSimpleCellComponentProps()
        oldLocationProps.text = props.location
        oldLocationProps.numberOfLines = 2
        oldLocationProps.marginTop = 12
        oldLocationComponent.props = oldLocationProps
        oldLocationComponent.style.display = props.location != nil ? .flex : .none
        
        
        let locationProps = EventCardRSVPSimpleCellCopmonentProps()
        locationProps.text = props.location
        locationProps.numberOfLines = 2
        locationProps.showUpdatedFlag = props.isLocationUpdated
        locationProps.maxWidth = CGFloat(self.style.width.value)
        locationComponent.props = locationProps
        locationComponent.style.display = props.location != nil ? .flex : .none
        
        let oldRoomProps = EventCardSimpleCellComponentProps()
        oldRoomProps.text = props.meetingRooms
        oldRoomProps.numberOfLines = 2
        oldRoomProps.showUpdatedFlag = props.isResourceUpdated
        oldRoomProps.marginTop = 12
        oldRoomComponent.props = oldRoomProps
        oldRoomComponent.style.display = props.meetingRooms != nil ? .flex : .none
        
        let roomProps = EventCardRSVPSimpleCellCopmonentProps()
        roomProps.text = props.meetingRooms
        roomProps.numberOfLines = 2
        roomProps.showUpdatedFlag = props.isResourceUpdated
        roomProps.maxWidth = CGFloat(self.style.width.value)
        roomComponent.props = roomProps
        roomComponent.style.display = props.meetingRooms != nil ? .flex : .none

        let meetingNotesProps = EventCardSimpleCellComponentProps()
        if let meetingNotes = props.meetingNotes, !meetingNotes.isDeleted {
            if let title = meetingNotes.parsedTitle, !title.isEmpty {
                meetingNotesProps.text = title
                meetingNotesComponent.docIcon.style.display = .flex
            } else {
                meetingNotesComponent.docIcon.style.display = .none
                meetingNotesProps.text = meetingNotes.url
            }
            meetingNotesProps.onTap = props.tapMeetingNotes
            meetingNotesComponent.props = meetingNotesProps
            meetingNotesComponent.style.display = .flex
        } else {
            meetingNotesComponent.style.display = .none
        }

        if !props.isJoined {
            locationComponent.style.display = .none
            roomComponent.style.display = .none
            meetingNotesComponent.style.display = .none

            oldLocationComponent.style.display = .none
            oldRoomComponent.style.display = .none
        }

        if props.isUpdated {
            repeatComponent.style.display = .none
            locationComponent.style.display = .none
            roomComponent.style.display = .none
            meetingNotesComponent.style.display = .none

            oldRepeatComponent.style.display = .none
            oldLocationComponent.style.display = .none
            oldRoomComponent.style.display = .none
        }
    }
    
    private func syncPropsToDescComponent(props: RSVPCardComponentProps) {
        if let descStr = props.descString, !descStr.isEmpty {
            let descProps = EventCardDescComponentProps()
            descProps.text = NSAttributedString(string: descStr, attributes: [.foregroundColor: UIColor.ud.textTitle,
                                                                              .font: UIFont.ud.body2])
            descComponent.props = descProps
            oldDescComponent.props = descProps
            
            descComponent.style.display = .flex
            oldDescComponent.style.display = .flex
        } else {
            descComponent.style.display = .none
            oldDescComponent.style.display = .none
        }
        
        if  props.isUpdated || !props.isJoined {
            descComponent.style.display = .none
            oldDescComponent.style.display = .none
        }
    }
    
    private func syncPropsToAttendeeComponent(props: RSVPCardComponentProps) {
        let attendeeProps = EventCardRSVPAttendeesComponentProps()
        attendeeProps.text = props.attendeeString
        attendeeProps.tapableRangeDic = props.attendeeRangeDict
        attendeeProps.outOfRangeText = props.outOfRangeText
        attendeeProps.maxWidth = props.maxWidth
        attendeeProps.isAttendeeOverflow = props.isAttendeeOverflow
        attendeeProps.isAllUserInGroupReplyed = props.isAllUserInGroupReplyed
        attendeeProps.rsvpAllReplyedCountString = props.rsvpAllReplyedCountString
        attendeeProps.eventTotalAttendeeCount = props.eventTotalAttendeeCount ?? 0
        attendeeProps.didSelectChat = { [weak self] (chatId) in
            self?.props.showProfile?(chatId)
        }
        self.attendeeComponent.props = attendeeProps
        attendeeComponent.style.display = .flex
        if props.isInValid || props.isUpdated || !props.isJoined {
            attendeeComponent.style.display = .none
        }
    }

    private func syncPropsToJoin(props: RSVPCardComponentProps) {
        let joinProps = joinButtonComponent.props
        joinProps.selector = props.joinSelector
        joinProps.target = props.joinTarget

        if props.isJoined {
            joinProps.disableTitle = BundleI18n.Calendar.Calendar_Share_Joined
            joinProps.isEnabled = false
            joinButtonComponent.style.display = .none
            rsvpComponent.style.display = .flex
            oldRsvpComponent.style.display = .flex
        } else {
            joinProps.isEnabled = true
            joinButtonComponent.style.display = .flex
            rsvpComponent.style.display = .none
            oldRsvpComponent.style.display = .none
        }
        
        if props.isUpdated || props.isInValid {
            joinButtonComponent.style.display = .none
            rsvpComponent.style.display = .none
            oldRsvpComponent.style.display = .none
        }

        self.joinButtonComponent.props = joinProps
    }
    
    private func syncPropsToRSVP(props: RSVPCardComponentProps) {
        let rsvpProps = EventCardRSVPCellComponentProps()
        rsvpProps.acceptSelector = props.acceptSelector
        rsvpProps.declinSelector = props.declinSelector
        rsvpProps.tentativeSelector = props.tentativeSelector
        rsvpProps.status = props.rsvpStatus
        rsvpProps.target = props.rsvpTarget
        rsvpProps.replyedBtnRetapSelector = props.replyedBtnRetapSelector
        rsvpProps.moreReplyeTappedSelector = props.moreReplyeTappedSelector

        rsvpComponent.props = rsvpProps
        oldRsvpComponent.props = rsvpProps
        
        if props.isInValid || props.isUpdated {
            rsvpComponent.style.display = .none
            oldRsvpComponent.style.display = .none
        } else {
            rsvpComponent.style.display = .flex
            oldRsvpComponent.style.display = .flex
        }
    }
    
    private func syncPropsToNeedActionReactionInfo(props: RSVPCardComponentProps) {
        if !props.isJoined || props.isUpdated || props.isInValid || props.isAttendeeOverflow {
            needActionReactionInfoComponent.style.display = .none
            return
        }
        
        if let needActionCount = props.needActionCount, needActionCount != 0  {
            let reactionInfoProps = EventCardRSVPReactionInfoComponentProps()
            reactionInfoProps.infoText = I18n.Calendar_Detail_AwaitingNumber(number: needActionCount)
            reactionInfoProps.needTopLine = true
            needActionReactionInfoComponent.props = reactionInfoProps
            needActionReactionInfoComponent.style.display = .flex
        } else {
            needActionReactionInfoComponent.style.display = .none
        }
    }
    
    private func syncPropsToNeedActionReaction(props: RSVPCardComponentProps) {
        // 控制Reaction模块显示
        if !props.isJoined || props.isUpdated || props.isInValid || props.isAttendeeOverflow {
            needActionReactionComponent.style.display = .none
            return
        }
        if let needActionCount = props.needActionCount, needActionCount != 0 {
            let reactionProps = EventCardRSVPReactionComponentProps()
            reactionProps.userOwnChatterId = props.userOwnChatterId
            reactionProps.maxWidth = CGFloat(self.style.width.value)
            reactionProps.rsvpList = props.reactionRsvpList.filter { $0.type == .needsAction }
            reactionProps.forNeedAction = true
            
            reactionProps.didSelectChat = {[weak self] (chatId) in
                self?.props.showProfile?(chatId)
            }
            
            reactionProps.didSelectReaction = {[weak self] (type) in
                self?.props.didSelectReaction?(type.rawValue)
            }
            
            reactionProps.didTapReactionMore = {[weak self] (type) in
                self?.props.didTapReactionMore?(type.rawValue)
            }
            
            needActionReactionComponent.props = reactionProps
            needActionReactionComponent.style.display = .flex
        } else {
            needActionReactionComponent.style.display = .none
        }
    }
    
    private func syncPropsToReactionInfo(props: RSVPCardComponentProps) {
        if !props.isJoined || props.isUpdated || props.isInValid || props.isAttendeeOverflow {
            reactionInfoComponent.style.display = .none
            return
        }
        
        if let eventTotalAttendeeCount = props.eventTotalAttendeeCount,
           let needActionCount = props.needActionCount,
           eventTotalAttendeeCount - needActionCount != 0 {
            let reactionInfoProps = EventCardRSVPReactionInfoComponentProps()
            reactionInfoProps.infoText = I18n.Calendar_Detail_RepliedNumber(number: eventTotalAttendeeCount - needActionCount)
            reactionInfoProps.needTopLine = props.needActionCount == 0
            reactionInfoComponent.props = reactionInfoProps
            reactionInfoComponent.style.display = .flex
        } else {
            reactionInfoComponent.style.display = .none
        }
    }
    
    private func syncPropsToReaction(props: RSVPCardComponentProps) {
        // 控制Reaction模块显示
        if !props.isJoined || props.isUpdated || props.isInValid || props.isAttendeeOverflow {
            reactionComponent.style.display = .none
            oldReactionComponent.style.display = .none
            return
        }
        
        let reactionProps = EventCardRSVPReactionComponentProps()
        reactionProps.maxWidth = CGFloat(self.style.width.value)
        reactionProps.rsvpList = props.reactionRsvpList.filter { $0.type != .needsAction }
        
        reactionProps.didSelectChat = {[weak self] (chatId) in
            self?.props.showProfile?(chatId)
        }
        
        reactionProps.didSelectReaction = {[weak self] (type) in
            self?.props.didSelectReaction?(type.rawValue)
        }
        
        reactionProps.didTapReactionMore = {[weak self] (type) in
            self?.props.didTapReactionMore?(type.rawValue)
        }
        
        reactionComponent.props = reactionProps
        reactionComponent.style.display = .flex
        
        oldReactionComponent.props = reactionProps
        oldReactionComponent.style.display = .flex
    }
    
    private func syncPropsToViewUpdate(props: RSVPCardComponentProps) {
        let updateProps = EventCardClickToViewUpdateComponentProps()
        updateProps.hintText = I18n.Calendar_Bot_ViewUpdatedEventDetails_New
        
        clickToViewUpdateComponent.props = updateProps
        oldClickToViewUpdateComponent.props = updateProps
        
        clickToViewUpdateComponent.style.display = props.isUpdated ? .flex : .none
        oldClickToViewUpdateComponent.style.display = props.isUpdated ? .flex : .none
    }
    
    public override init(props: RSVPCardComponentProps, style: ASComponentStyle, context: C?) {
        super.init(props: props, style: style, context: context)
        style.justifyContent = .flexEnd
        style.flexDirection = .column
        style.alignContent = .stretch
        style.paddingBottom = 12
        style.alignItems = .stretch

        _ = willReceiveProps(props, props)

        if FG.rsvpStyleOpt {
            setSubComponents([
                headerComponent,
                timeComponent,
                repeatComponent,
                roomComponent,
                locationComponent,
                meetingNotesComponent,
                descComponent,
                joinButtonComponent,
                needActionReactionInfoComponent,
                needActionReactionComponent,
                reactionInfoComponent,
                reactionComponent,
                rsvpComponent,
                clickToViewUpdateComponent
                ])
        } else {
            setSubComponents([
                oldHeaderComponent,
                oldTimeComponent,
                oldRepeatComponent,
                oldRoomComponent,
                oldLocationComponent,
                meetingNotesComponent,
                oldDescComponent,
                attendeeComponent,
                oldRsvpComponent,
                joinButtonComponent,
                oldReactionComponent,
                oldClickToViewUpdateComponent
                ])
        }
    }

}
