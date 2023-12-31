//
//  RoundRobinCardHeaderComponent.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/30.
//

import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignCardHeader
import RichLabel

final class RoundRobinCardHeaderComponent<C: Context>:
    ASComponent<RoundRobinCardHeaderComponent.Props, EmptyState, UDCardHeader, C> {

    final class Props: ASComponentProps {
        var isActive: Bool = false
        var title: String?
        var subtitle: String?
        var subtitleClickableName: String?
        var clickableUserID: String?
        var subtitleNameOnClick: ((String?) -> Void)?

        var textColor: UIColor {
            isActive ? UIColor.ud.udtokenMessageCardTextGreen : UIColor.ud.udtokenMessageCardTextNeutral
        }

        var backgroundColor: UDCardHeaderHue {
            isActive ? .green : .neural
        }
    }

    private lazy var titleLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.headline(.fixed)
        props.textColor = UIColor.ud.udtokenMessageCardTextGreen
        props.lineBreakMode = .byTruncatingTail
        props.textAlignment = .left
        props.numberOfLines = 4

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.minHeight = 22
        style.flexShrink = 1
        return UILabelComponent(props: props, style: style)
    }()

    private lazy var subTitleLabel: RichLabelComponent<C> = {
        let props = RichLabelProps()
        props.numberOfLines = 2
        props.lineSpacing = 4

        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginTop = 2
        return RichLabelComponent(props: props, style: style)
    }()

    override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([titleLabel, subTitleLabel])
        style.justifyContent = .flexStart
        style.flexDirection = .column
        style.alignContent = .center
        style.alignItems = .stretch
        style.padding = 12
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        titleLabel.props.text = new.title
        titleLabel.props.textColor = new.textColor
        if let subtitle = new.subtitle, !subtitle.isEmpty {
            subTitleLabel.style.display = .flex
            subTitleLabel.props.delegate = self
            subTitleLabel.props.attributedText = subtitleAttrText(text: subtitle, color: new.textColor)
            subTitleLabel.props.outOfRangeText = subtitleAttrText(text: "\u{2026}", color: new.textColor)  // ...
            if let atName = new.subtitleClickableName, !atName.isEmpty {
                let range = NSString(string: subtitle).range(of: atName)
                subTitleLabel.props.tapableRangeList = [range]
            }
        } else {
            subTitleLabel.style.display = .none
        }
        return true
    }

    override func create(_ rect: CGRect) -> UDCardHeader {
        return UDCardHeader(colorHue: props.backgroundColor)
     }

    override func update(view: UDCardHeader) {
        super.update(view: view)
        view.colorHue = props.backgroundColor
        view.layoutType = .normal
     }

    private func subtitleAttrText(text: String, color: UIColor) -> NSAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.ud.body2(.fixed),
                                                    .foregroundColor: color]
        return NSAttributedString(string: text, attributes: attrs)
    }
}

extension RoundRobinCardHeaderComponent: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel,
                                didSelectText text: String,
                                didSelectRange range: NSRange) -> Bool {
        self.props.subtitleNameOnClick?(self.props.clickableUserID)
        return false
    }
}
