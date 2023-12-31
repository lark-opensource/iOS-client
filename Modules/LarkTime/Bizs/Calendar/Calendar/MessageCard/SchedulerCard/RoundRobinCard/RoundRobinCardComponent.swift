//
//  RoundRobinCardComponent.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/28.
//

import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel

final class RoundRobinCardComponent<C: Context>: ASComponent<RoundRobinCardComponent.Props, EmptyState, EventCardView, C> {

    final class Props: ASComponentProps {
        var isActive: Bool = false
        var title: String?
        var subtitle: String?
        var subtitleClickableName: String?
        var clickableUserID: String?
        var subtitleNameOnClick: ((String?) -> Void)?
        var hostID: String?
        var hostName: String?
        var hostOnClick: ((String?) -> Void)?
        var inviteeName: String?
        var inviteeEmail: String?
        var inviteeEmailOnClick: ((String?) -> Void)?
        var time: String?
        var changeHostAction: (() -> Void)?
        var rescheduleAction: (() -> Void)?
        var cancelAction: (() -> Void)?
        var isForward: Bool = false
        var amIHost: Bool = false
        var amICreator: Bool = false
    }

    private lazy var headerComponent = RoundRobinCardHeaderComponent<C>(props: RoundRobinCardHeaderComponent.Props(), style: ASComponentStyle(), context: nil)

    private lazy var bodyComponent = RoundRobinCardBodyComponent<C>(props: RoundRobinCardBodyComponent.Props(), style: ASComponentStyle(), context: nil)

    override init(props: RoundRobinCardComponent.Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([headerComponent, bodyComponent])
        style.justifyContent = .flexEnd
        style.flexDirection = .column
        style.alignContent = .stretch
        style.alignItems = .stretch
    }

    override func create(_ rect: CGRect) -> EventCardView {
        let view = EventCardView(frame: rect)
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }

    override func willReceiveProps(_ old: RoundRobinCardComponent.Props, _ new: RoundRobinCardComponent.Props) -> Bool {
        headerComponent.props = buildHeaderProps(with: new)
        bodyComponent.props = buildBodyProps(with: new)
        return true
    }
}

extension RoundRobinCardComponent {
    private func buildHeaderProps(with props: RoundRobinCardComponent.Props) -> RoundRobinCardHeaderComponent<C>.Props {
        let headerProps = RoundRobinCardHeaderComponent<C>.Props()
        headerProps.isActive = props.isActive
        headerProps.title = props.title
        headerProps.subtitle = props.subtitle
        headerProps.clickableUserID = props.clickableUserID
        headerProps.subtitleClickableName = props.subtitleClickableName
        headerProps.subtitleNameOnClick = props.subtitleNameOnClick
        return headerProps
    }

    private func buildBodyProps(with props: RoundRobinCardComponent.Props) -> RoundRobinCardBodyComponent<C>.Props {
        let bodyProps = RoundRobinCardBodyComponent<C>.Props()
        bodyProps.isActive = props.isActive
        bodyProps.hostID = props.hostID
        bodyProps.hostName = props.hostName
        bodyProps.inviteeName = props.inviteeName
        bodyProps.inviteeEmail = props.inviteeEmail
        bodyProps.hostOnTapped = props.hostOnClick
        bodyProps.inviteeEmailOnTapped = props.inviteeEmailOnClick
        bodyProps.time = props.time
        bodyProps.changeHostAction = props.changeHostAction
        bodyProps.rescheduleAction = props.rescheduleAction
        bodyProps.cancelAction = props.cancelAction
        bodyProps.isForward = props.isForward
        bodyProps.amIHost = props.amIHost
        bodyProps.amICreator = props.amICreator
        return bodyProps
    }
}
