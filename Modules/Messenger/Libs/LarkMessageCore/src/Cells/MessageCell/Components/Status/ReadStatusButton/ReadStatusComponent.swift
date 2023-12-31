//
//  ReadStatusComponent.swift
//  LarkMessageCore
//
//  Created by Meng on 2019/4/2.
//

import UIKit
import Foundation
import AsyncComponent
import LarkUIKit

public final class ReadStatusComponent<C: AsyncComponent.Context>: ASComponent<ReadStatusComponent.Props, EmptyState, LarkUIKit.ReadStatusButton, C> {

    public final class Props: ASComponentProps {

        public var hitTestEdgeInsets: UIEdgeInsets = .zero

        public var trackColor: UIColor = UIColor.ud.T600

        public var percent: CGFloat = 0.0

        public var tapHandler: ((ReadStatusButton) -> Void)?

    }

    public override func create(_ rect: CGRect) -> ReadStatusButton {
        let statusButton = ReadStatusButton(frame: rect)
        statusButton.hitTestEdgeInsets = UIEdgeInsets(top: -10.0, left: -10.0, bottom: -10.0, right: -10.0)
        statusButton.addTarget(self, action: #selector(didTapped(_:)), for: .touchUpInside)
        return statusButton
    }

    public override func update(view: ReadStatusButton) {
        super.update(view: view)
        view.trackColor = UDMessageColorTheme.imMessageIconRead
        view.defaultColor = UDMessageColorTheme.imMessageIconUnread
        view.hitTestEdgeInsets = props.hitTestEdgeInsets
        view.update(percent: props.percent)
        view.removeTarget(nil, action: #selector(didTapped(_:)), for: .touchUpInside)
        view.addTarget(self, action: #selector(didTapped(_:)), for: .touchUpInside)
    }

    @objc
    private func didTapped(_ sender: ReadStatusButton) {
        props.tapHandler?(sender)
    }

}
