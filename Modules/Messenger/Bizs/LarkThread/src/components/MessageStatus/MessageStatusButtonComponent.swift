//
//  MessageStatusButtonComponent.swift
//  LarkThread
//
//  Created by 姚启灏 on 2019/2/19.
//

import UIKit
import Foundation
import AsyncComponent

final class MessageStatusButtonComponent<C: AsyncComponent.Context>: ASComponent<MessageStatusButtonComponent.Props, EmptyState, MessageStatusButton, C> {
    final class Props: ASComponentProps {
        var isFailed: Bool
        var onTapped: MessageStatusButton.TapCallback?

        init(isFailed: Bool) {
            self.isFailed = isFailed
        }
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return MessageStatusButton.sizeToFit(size, iconSize: 16, isFailed: props.isFailed)
    }

    public override func create(_ rect: CGRect) -> MessageStatusButton {
        return MessageStatusButton(frame: rect, iconSize: 16)
    }

    override func update(view: MessageStatusButton) {
        view.update(isFailed: props.isFailed)
        view.onTapped = props.onTapped
        super.update(view: view)
    }
}
