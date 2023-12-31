//
//  FlagListMessageCellComponent.swift
//  LarkFlag
//
//  Created by ByteDance on 2022/10/17.
//

import UIKit
import Foundation
import AsyncComponent

final class FlagListMessageCellProps: ASComponentProps {
    // 消息内容
    var contentComponent: ComponentWithContext<FlagListMessageContext>
    init(content: ComponentWithContext<FlagListMessageContext>) {
        self.contentComponent = content
        super.init()
    }
}

final class FlagListMessageCellComponent: ASComponent<FlagListMessageCellProps, EmptyState, UIView, FlagListMessageContext> {

    override init(props: FlagListMessageCellProps, style: ASComponentStyle, context: FlagListMessageContext? = nil) {
        super.init(props: props, style: style)
        self.style.flexDirection = .column
        self.style.alignItems = .stretch
        setSubComponents([contentWrapper])
    }

    lazy var contentWrapper: ASLayoutComponent<FlagListMessageContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        return ASLayoutComponent(style: style, context: context, [])
    }()

    override func willReceiveProps(_ old: FlagListMessageCellProps, _ new: FlagListMessageCellProps) -> Bool {
        contentWrapper.setSubComponents([new.contentComponent])
        return true
    }
}
