//
//  PinEventShareViewModel.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/24.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import AsyncComponent
import RustPB

public protocol PinEventShareViewModelContext: ViewModelContext {
    func eventTimeDescription(start: Int64,
                              end: Int64,
                              isAllDay: Bool) -> String
}

final class PinEventShareViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PinEventShareViewModelContext>: MessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "PinEventShare"
    }

    public override var contentConfig: ContentConfig? {
        return ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true)
    }

    public var content: EventShareContent {
        return (message.content as? EventShareContent) ?? .init(pb: .init(), messageId: "")
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 370)
    }

    var title: String {
        return content.title.isEmpty ? BundleI18n.LarkChat.Lark_View_ServerNoTitle : content.title
    }

    var icon: UIImage {
        return Resources.pinCalenderTip
    }

    public var displayContent: [ComponentWithContext<C>] {
        let props = UILabelComponentProps()
        props.text = context.eventTimeDescription(start: content.startTime, end: content.endTime, isAllDay: content.isAllDay ?? false)
        props.font = UIFont.systemFont(ofSize: 14)
        props.numberOfLines = 1
        props.textColor = UIColor.ud.N500
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        return [UILabelComponent<C>(props: props, style: style)]
    }
}

extension PageContext: PinEventShareViewModelContext {
    public func eventTimeDescription(start: Int64,
                              end: Int64,
                              isAllDay: Bool) -> String {
        return (try? resolver.resolve(assert: ChatCalendarDependency.self))?.eventTimeDescription(
            start: start, end: end, isAllDay: isAllDay) ?? ""
    }
}
