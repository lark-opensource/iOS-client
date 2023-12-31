//
//  SchedulerAppointmentComponent.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/29.
//

import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel

final class SchedulerAppointmentComponent<C: Context>: ASComponent<SchedulerAppointmentComponent.Props, EmptyState, EventCardView, C> {

    final class Props: ASComponentProps {
        var isActive: Bool = false
        var title: String?
        var subtitle: String?
        var isExternal: Bool = false
        var subtitleClickableName: String?
        var clickableUserID: String?
        var subtitleNameOnClick: ((String?) -> Void)?
        var inviteeEmail: String?
        var inviteeEmailOnClick: ((String?) -> Void)?
        var time: String?
        var message: String?
        var messageTitle: String?
        var detailLink: String?
        var actionButtonVisible: Bool = false
        var viewDetailAction: ((String?) -> Void)?
    }

    private lazy var headerComponent = SchedulerAppointmentHeaderComponent<C>(props: SchedulerAppointmentHeaderComponent.Props(), style: ASComponentStyle(), context: nil)

    private lazy var bodyComponent = SchedulerAppointmentBodyComponent<C>(props: SchedulerAppointmentBodyComponent.Props(), style: ASComponentStyle(), context: nil)

    override init(props: SchedulerAppointmentComponent.Props, style: ASComponentStyle, context: C? = nil) {
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

    override func willReceiveProps(_ old: SchedulerAppointmentComponent.Props, _ new: SchedulerAppointmentComponent.Props) -> Bool {
        headerComponent.props = buildHeaderProps(with: new)
        bodyComponent.props = buildBodyProps(with: new)
        return true
    }
}

extension SchedulerAppointmentComponent {
    private func buildHeaderProps(with props: SchedulerAppointmentComponent.Props) -> SchedulerAppointmentHeaderComponent<C>.Props {
        let headerProps = SchedulerAppointmentHeaderComponent<C>.Props()
        headerProps.isActive = props.isActive
        headerProps.title = props.title
        headerProps.subtitle = props.subtitle
        headerProps.isExternal = props.isExternal
        headerProps.clickableUserID = props.clickableUserID
        headerProps.subtitleClickableName = props.subtitleClickableName
        headerProps.subtitleNameOnClick = props.subtitleNameOnClick
        return headerProps
    }

    private func buildBodyProps(with props: SchedulerAppointmentComponent.Props) -> SchedulerAppointmentBodyComponent<C>.Props{
        let bodyProps = SchedulerAppointmentBodyComponent<C>.Props()
        bodyProps.isActive = props.isActive
        bodyProps.inviteeEmail = props.inviteeEmail
        bodyProps.inviteeEmailOnTapped = props.inviteeEmailOnClick
        bodyProps.time = props.time
        bodyProps.message = props.message
        bodyProps.messageTitle = props.messageTitle
        bodyProps.detailLink = props.detailLink
        bodyProps.viewDetailAction = props.viewDetailAction
        bodyProps.actionButtonVisible = props.actionButtonVisible
        return bodyProps
    }
}
