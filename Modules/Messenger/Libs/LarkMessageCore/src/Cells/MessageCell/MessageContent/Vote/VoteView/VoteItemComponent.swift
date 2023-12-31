//
//  VoteItemComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/21.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkUIKit

final public class VoteItemComponentProps: ASComponentProps {
    public var title: String = ""
    public var detail: String = ""
    public var isSelected: Bool = false
    public var enable: Bool = true
    public var progressValue: CGFloat = 0.0
    public var voteNumberText: String = ""
    public var progressText: String = ""
    public var maxPickNum: Int = 1
    public var itemProperty: SelectProperty?
    public var onViewClicked: ((SelectProperty?) -> Void)?
}

public final class VoteItemComponent<C: ComponentContext>: ASComponent<VoteItemComponentProps, EmptyState, TappedView, C> {

    public override init(props: VoteItemComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column

        super.init(props: props, style: style, context: context)
        self.updateUI(props: props)
        setSubComponents([header, footer])
    }

    public override func update(view: TappedView) {
        super.update(view: view)

        if let tapped = self.props.onViewClicked {
            view.initEvent(needLongPress: false)
            view.onTapped = { [weak self] _ in
                tapped(self?.props.itemProperty)
            }
        } else {
            view.deinitEvent()
        }
    }

    lazy var header: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .flexStart
        style.justifyContent = .flexStart
        return ASLayoutComponent(style: style, context: context, [checkBox, title, detail])
    }()

    // checkBox
    private lazy var checkBox: LKCheckboxComponent<C> = {
        let props = LKCheckboxComponentProps()
        props.isEnabled = true

        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: 20)
        style.height = CSSValue(cgfloat: 20)
        style.flexShrink = 0
        return LKCheckboxComponent(props: props, style: style)
    }()

    // Title
    private lazy var title: UILabelComponent<C> = {
        let props = UILabelComponentProps()

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexShrink = 0
        return UILabelComponent<C>(props: props, style: style)
    }()

    // Detail
    private lazy var detail: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.numberOfLines = 0

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 8
        return UILabelComponent<C>(props: props, style: style)
    }()

    // Footer
    lazy var footer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        return ASLayoutComponent(style: style, context: context, [descContaier, progress])
    }()

    // progress
    lazy var progress: ProgressComponent<C> = {
        let props = ProgressComponentProps()
        props.backgroundColor = UIColor.ud.lineBorderCard
        props.progressColor = UIColor.ud.primaryContentDefault
        props.height = 4
        let style = ASComponentStyle()
        style.marginTop = 4
        return ProgressComponent(props: props, style: style)
    }()

    // descContaier
    lazy var descContaier: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.marginTop = 4
        style.alignItems = .stretch
        return ASLayoutComponent(style: style, context: context, [voteNumber, percentage])
    }()

    // vote number
    private lazy var voteNumber: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.caption3

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent<C>(props: props, style: style)
    }()

    // percentage
    private lazy var percentage: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.caption3

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 8
        return UILabelComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: VoteItemComponentProps,
                                          _ new: VoteItemComponentProps) -> Bool {
        updateUI(props: new)
        return true
    }

    private func updateUI(props: VoteItemComponentProps) {
        // checkBox
        checkBox.style.display = props.enable ? .flex : .none
        let checkBoxProps = checkBox.props
        checkBoxProps.isSelected = props.isSelected
        checkBoxProps.boxType = props.maxPickNum > 1 ? .multiple : .single
        checkBox.props = checkBoxProps

        title.props.text = props.title
        title.style.marginLeft = props.enable ? 8 : 0
        let textColor: UIColor
        let textFont: UIFont
        if !props.enable, props.isSelected {
            textFont = UIFont.ud.body1
            textColor = UIColor.ud.primaryContentDefault
        } else {
            textFont = UIFont.ud.body2
            textColor = UIColor.ud.textTitle
        }
        title.props.textColor = textColor
        title.props.font = textFont
        detail.props.textColor = textColor
        detail.props.font = textFont

        let textFactory = { (text: String) -> NSAttributedString in
            let paragraph = NSMutableParagraphStyle()
            paragraph.maximumLineHeight = 0
            paragraph.minimumLineHeight = 19
            paragraph.lineSpacing = 3.5
            paragraph.lineHeightMultiple = 0
            let attrStr = NSAttributedString(
                string: text,
                attributes: [
                    .paragraphStyle: paragraph,
                    .font: textFont
                ]
            )
            return attrStr
        }
        title.props.attributedText = textFactory(props.title)
        detail.props.attributedText = textFactory(props.detail)

        // Footer
        voteNumber.props.textColor = textColor
        percentage.props.textColor = textColor

        voteNumber.props.text = props.voteNumberText
        percentage.props.text = props.progressText
        footer.style.display = props.enable ? .none : .flex

        // Progress
        let progressProps = progress.props
        progressProps.value = props.progressValue
        progress.props = progressProps
    }
}
