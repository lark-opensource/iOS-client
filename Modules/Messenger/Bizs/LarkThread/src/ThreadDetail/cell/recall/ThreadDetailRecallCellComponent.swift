//
//  ThreadDetailRecallCellComponent.swift
//  LarkThread
//
//  Created by shane on 2019/5/28.
//

import UIKit
import Foundation
import RichLabel
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final class ThreadDetailRecallCellComponent: ASComponent<ThreadDetailRecallCellComponent.Props, EmptyState, UIView, ThreadDetailContext> {
    final class Props: ASComponentProps {
        var displayAttributeString: NSAttributedString?
        var displayNameRange: NSRange = NSRange(location: 0, length: 0)
        weak var delegate: LKLabelDelegate?
        var inSelectMode: Bool = false
    }

    private lazy var label: RichLabelComponent<ThreadDetailContext> = {
        let labelProps = RichLabelProps()
        labelProps.numberOfLines = 0
        labelProps.backgroundColor = UIColor.clear

        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = UIColor.clear
        labelStyle.marginLeft = 8
        labelStyle.marginRight = 16
        labelStyle.marginTop = 12
        labelStyle.marginBottom = 20
        return RichLabelComponent<ThreadDetailContext>(props: labelProps, style: labelStyle)
    }()

    private lazy var iconImageCompentent: UIImageViewComponent<ThreadDetailContext> = {
        let imageProps = UIImageViewComponentProps()
        imageProps.setImage = { $0.set(image: Resources.thread_detail_recall) }

        let labelHeight = UIFont.ud.body1.rowHeight

        let imageStyle = ASComponentStyle()
        imageStyle.marginLeft = 24
        imageStyle.marginTop = 14
        imageStyle.width = CSSValue(cgfloat: labelHeight)
        imageStyle.height = imageStyle.width
        imageStyle.flexGrow = 0
        imageStyle.flexShrink = 0
        let imageViewCompentent = UIImageViewComponent<ThreadDetailContext>(props: imageProps, style: imageStyle)

        return imageViewCompentent
    }()

    override init(props: Props, style: ASComponentStyle, context: ThreadDetailContext? = nil) {
        super.init(props: props, style: style, context: context)
        style.backgroundColor = UIColor.clear
        style.alignContent = .stretch
        style.flexDirection = .row

        setSubComponents([iconImageCompentent, label])
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        updateProps(new)
        return true
    }

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func update(view: UIView) {
        super.update(view: view)
        // 多选态消息整个消息屏蔽点击事件，只响应cell层的显示时间和选中事件
        view.isUserInteractionEnabled = (context?.isPreview == true) ? false : !props.inSelectMode
    }

    private func updateProps(_ props: Props) {
        label.props.attributedText = props.displayAttributeString ?? NSAttributedString(string: "")
        label.props.tapableRangeList = [props.displayNameRange]
        label.props.delegate = props.delegate
    }
}
