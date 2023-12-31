//
//  EventCardNewRSVPCellComponent.swift
//  Calendar
//
//  Created by Hongbin Liang on 11/18/22.
//

import UIKit
import Foundation
import CalendarFoundation
import AsyncComponent
import UniverseDesignIcon
import EEFlexiable

final class RSVPReplyBtnComponentProps: ASComponentProps {
    var text: String?
    var icon: UIImage?
    var target: Any?
    var selector: Selector?
}

final class RSVPReplyedBtnComponent<C: Context>: ASComponent<RSVPReplyBtnComponentProps, EmptyState, UIView, C> {
    private let statusIcon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()

    private let titleLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.font = UIFont.body3
        titleProps.textColor = UIColor.ud.textTitle
        titleProps.text = I18n.Calendar_Detail_Accept
        titleProps.numberOfLines = 1
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 4
        return UILabelComponent(props: titleProps, style: style)
    }()

    private let folderIcon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.downBoldOutlined).renderColor(with: .n2)
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 10.auto()
        style.height = 10.auto()
        style.flexShrink = 0
        style.marginLeft = 4
        return UIImageViewComponent(props: props, style: style)
    }()

    override init(props: RSVPReplyBtnComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style)
        style.flexDirection = .row
        style.alignItems = .center
        setSubComponents([
            statusIcon,
            titleLabel,
            folderIcon
        ])
    }

    override func update(view: UIView) {
        super.update(view: view)
        let titleProps = titleLabel.props
        titleProps.text = props.text
        titleLabel.props = titleProps
        statusIcon.props.setImage = { [weak self] in
            guard let self = self else { return }
            $0.set(image: self.props.icon)
        }
        if let sel = props.selector {
            let tapGesture = UITapGestureRecognizer(target: props.target, action: sel)
            view.gestureRecognizers?.forEach({ (gestures) in
                view.removeGestureRecognizer(gestures)
            })
            view.addGestureRecognizer(tapGesture)
        }
    }
}
